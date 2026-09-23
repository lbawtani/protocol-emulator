module sync_fifo #(
    parameter int depth = 16,
    parameter int width = 1
) (
    input logic clk,
    input logic rst_n,
    input logic wr_en,
    input logic [width-1:0] din,
    input logic rd_en,

    output logic full,
    output logic empty,
    output logic [width-1:0] dout
);

    localparam int ADDR_WIDTH = $clog2(depth);
    localparam int PTR_WIDTH = ADDR_WIDTH + 1;

    if (depth < 2 || (depth & (depth - 1)) != 0) begin : g_depth_check
        $error("sync_fifo depth must be a power of 2 and at least 2");
    end

    logic rd_en_int;
    logic wr_en_int;

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;

    logic [width-1:0] internal_d [0:depth-1];

    assign empty = (wr_ptr == rd_ptr);
    assign full = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) && (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]);

    assign rd_en_int = rd_en && !empty;
    assign wr_en_int = wr_en && !full;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en_int) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= '0;
            dout <= '0;
        end else if (rd_en_int) begin
            rd_ptr <= rd_ptr + 1'b1;
            dout <= internal_d[rd_ptr[ADDR_WIDTH-1:0]];
        end
    end

    always_ff @(posedge clk) begin
        if (wr_en_int) begin
            internal_d[wr_ptr[ADDR_WIDTH-1:0]] <= din;
        end
    end

endmodule
