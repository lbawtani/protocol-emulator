module UART #(
	parameter int RATIO_WIDTH = 16
) (
	input logic clk,
	input logic rst_n,
	input logic [RATIO_WIDTH-1:0] clk_ratio,
	input logic en,
	input logic rx_serial,

	output logic [15:0] tx_parallel,
	output logic valid
);

logic [15:0] accumulator;
logic [7:0] shiftReg;
logic [RATIO_WIDTH-1:0] clkCount;
logic [2:0] bitIndex;
logic byteCount;
logic serialBuffer;
logic serialR;

typedef enum logic [1:0] {
	IDLE,
	START,
	RECEIVE,
	STOP
} sel;

sel select;

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		serialBuffer <= 1'b1;
		serialR <= 1'b1;
	end else begin
		serialBuffer <= rx_serial;
		serialR <= serialBuffer;
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		select <= IDLE;
		clkCount <= '0;
		bitIndex <= '0;
		shiftReg <= '0;
		accumulator <= '0;
		byteCount <= 1'b0;
		valid <= 1'b0;
	end else begin
		valid <= 1'b0;

		unique case (select)
			IDLE: begin
				clkCount <= '0;
				bitIndex <= '0;
				if (!en) begin
					byteCount <= 1'b0;
				end else if (!serialR) begin
					select <= START;
				end
			end

			START: begin
				if (clkCount == (clk_ratio >> 1) - 1'b1) begin
					clkCount <= '0;
					if (!serialR) begin
						select <= RECEIVE;
					end else begin
						select <= IDLE;
					end
				end else begin
					clkCount <= clkCount + 1'b1;
				end
			end

			RECEIVE: begin
				if (clkCount == clk_ratio - 1'b1) begin
					clkCount <= '0;
					shiftReg <= {serialR, shiftReg[7:1]};
					if (bitIndex == 3'd7) begin
						select <= STOP;
					end else begin
						bitIndex <= bitIndex + 1'b1;
					end
				end else begin
					clkCount <= clkCount + 1'b1;
				end
			end

			STOP: begin
				if (clkCount == clk_ratio - 1'b1) begin
					clkCount <= '0;
					select <= IDLE;
					if (serialR) begin
						accumulator <= {accumulator[7:0], shiftReg};
						byteCount <= ~byteCount;
						valid <= byteCount;
					end else begin
						byteCount <= 1'b0;
					end
				end else begin
					clkCount <= clkCount + 1'b1;
				end
			end
		endcase
	end
end

assign tx_parallel = accumulator;

endmodule
