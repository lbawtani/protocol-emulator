module async_fifo #(
    parameter int depth = 16,
    parameter int width = 1
) (
    input logic wr_clk,
    input logic wr_rst_n,
    input logic wr_en,
    input logic [width-1:0] din,

    input logic rd_clk,
    input logic rd_rst_n,
    input logic rd_en,

    output logic full,
    output logic empty,
    output logic [width-1:0] dout
);

    localparam int ADDR_WIDTH = $clog2(depth);
    localparam int PTR_WIDTH = ADDR_WIDTH + 1;
    localparam logic [PTR_WIDTH-1:0] FULL_MASK = 2'b11 << (PTR_WIDTH - 2);

    if (depth < 2 || (depth & (depth - 1)) != 0) begin : g_depth_check
        $error("async_fifo depth must be a power of 2 and at least 2");
    end

    logic [1:0] wr_rst_sync;
    logic [1:0] rd_rst_sync;
    logic wr_rst_n_s;
    logic rd_rst_n_s;

    logic rd_en_int;
    logic wr_en_int;

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] wr_ptr_next;
    logic [PTR_WIDTH-1:0] gray_wr_ptr;
    logic [PTR_WIDTH-1:0] gray_wr_ptr_next;

    logic [PTR_WIDTH-1:0] rd_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr_next;
    logic [PTR_WIDTH-1:0] gray_rd_ptr;
    logic [PTR_WIDTH-1:0] gray_rd_ptr_next;

    logic [PTR_WIDTH-1:0] gray_wr_ptr1;
    logic [PTR_WIDTH-1:0] gray_wr_ptr2;
    logic [PTR_WIDTH-1:0] gray_rd_ptr1;
    logic [PTR_WIDTH-1:0] gray_rd_ptr2;

    logic [width-1:0] internal_d [0:depth-1];

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_rst_sync <= 2'b00;
        end else begin
            wr_rst_sync <= {wr_rst_sync[0], 1'b1};
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_rst_sync <= 2'b00;
        end else begin
            rd_rst_sync <= {rd_rst_sync[0], 1'b1};
        end
    end

    assign wr_rst_n_s = wr_rst_sync[1];
    assign rd_rst_n_s = rd_rst_sync[1];

    assign rd_en_int = rd_en && !empty;
    assign wr_en_int = wr_en && !full;

    assign wr_ptr_next = wr_en_int ? wr_ptr + 1'b1 : wr_ptr;
    assign rd_ptr_next = rd_en_int ? rd_ptr + 1'b1 : rd_ptr;

    assign gray_wr_ptr_next = (wr_ptr_next >> 1) ^ wr_ptr_next;
    assign gray_rd_ptr_next = (rd_ptr_next >> 1) ^ rd_ptr_next;

    always_ff @(posedge wr_clk or negedge wr_rst_n_s) begin
        if (!wr_rst_n_s) begin
            wr_ptr <= '0;
            gray_wr_ptr <= '0;
        end else begin
            wr_ptr <= wr_ptr_next;
            gray_wr_ptr <= gray_wr_ptr_next;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n_s) begin
        if (!rd_rst_n_s) begin
            rd_ptr <= '0;
            gray_rd_ptr <= '0;
        end else begin
            rd_ptr <= rd_ptr_next;
            gray_rd_ptr <= gray_rd_ptr_next;
        end
    end

    always_ff @(posedge wr_clk) begin
        if (wr_en_int) begin
            internal_d[wr_ptr[ADDR_WIDTH-1:0]] <= din;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n_s) begin
        if (!rd_rst_n_s) begin
            dout <= '0;
        end else if (rd_en_int) begin
            dout <= internal_d[rd_ptr[ADDR_WIDTH-1:0]];
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n_s) begin
        if (!rd_rst_n_s) begin
            gray_wr_ptr1 <= '0;
            gray_wr_ptr2 <= '0;
        end else begin
            gray_wr_ptr1 <= gray_wr_ptr;
            gray_wr_ptr2 <= gray_wr_ptr1;
        end
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n_s) begin
        if (!wr_rst_n_s) begin
            gray_rd_ptr1 <= '0;
            gray_rd_ptr2 <= '0;
        end else begin
            gray_rd_ptr1 <= gray_rd_ptr;
            gray_rd_ptr2 <= gray_rd_ptr1;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n_s) begin
        if (!rd_rst_n_s) begin
            empty <= 1'b1;
        end else begin
            empty <= (gray_rd_ptr_next == gray_wr_ptr2);
        end
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n_s) begin
        if (!wr_rst_n_s) begin
            full <= 1'b0;
        end else begin
            full <= (gray_wr_ptr_next == (gray_rd_ptr2 ^ FULL_MASK));
        end
    end

endmodule
