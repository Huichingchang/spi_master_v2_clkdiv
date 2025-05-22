`timescale 1ns/1ps
module spi_master_v2_clkdiv #(
	parameter DATA_WIDTH = 8,
	parameter MAX_CS = 4,
	parameter CS_SEL_WIDTH = 2
)(
	input clk,
	input rst_n,
	
	input start,
	input [DATA_WIDTH-1:0] data_in,
	input [3:0] data_len,
	input [CS_SEL_WIDTH-1:0] cs_sel,
	
	output reg busy,
	output reg done,
	output reg [DATA_WIDTH-1:0] data_out,
	
	output reg sclk,
	output reg mosi,
	input miso,
	output reg [MAX_CS-1:0] cs_n
);

	// Clock divider instance
	wire sclk_en;
	clk_divider #(8) u_clk_div(
		.clk(clk),
		.rst_n(rst_n),
		.clk_out(sclk_en)
	);
	
	// FSM
	localparam IDLE = 2'b00;
	localparam LOAD = 2'b01;
	localparam SHIFT = 2'b10;
	localparam FINISH = 2'b11;
	
	reg [1:0] state, next_state;
	reg [DATA_WIDTH-1:0] shift_reg;
	reg [2:0] bit_cnt;
	reg [3:0] byte_cnt;
	
	// CS控制
	integer i;
	always @(*) begin
		for (i = 0; i < MAX_CS; i = i + 1)
			cs_n[i] = 1'b1;	
		if (busy)
			cs_n[cs_sel] = 1'b0;		
	end
	
	// FSM狀態轉移
	always @(*) begin
		next_state = state;
		case (state)
			IDLE: if (start) next_state = LOAD;
			LOAD: next_state = SHIFT;
			SHIFT: if (bit_cnt == DATA_WIDTH-1 && sclk_en)
						next_state = (byte_cnt == data_len - 1) ? FINISH : LOAD;
			FINISH: next_state = IDLE;	
		endcase
	end
	
	// 主邏輯
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			state <= IDLE;
			shift_reg <= 0;
			bit_cnt <= 0;
			byte_cnt <= 0;
			busy <= 0;
			done <= 0;
			sclk <= 0;
			mosi <= 0;
	end else begin
		state <= next_state;
			
		case (state)
			IDLE: begin
				busy <= 0;
				done <= 0;
				mosi <= 0;
				sclk <= 0;
			end
			LOAD: begin
				shift_reg <= data_in;
				bit_cnt <=0;
				busy <= 1;
			end
			SHIFT: begin
				if (sclk_en) begin
					sclk <= ~sclk;
					if (sclk == 0) begin
						mosi <= shift_reg[DATA_WIDTH-1];
						shift_reg <= {shift_reg[DATA_WIDTH-2:0], miso};
						bit_cnt <= bit_cnt + 1;
					end
				end
			end
			FINISH: begin
				done <= 1;
				busy <= 0;
				sclk <= 0;
				data_out <= shift_reg;
				byte_cnt <= 0;
			end
			
		endcase
		
		// Byte計數
		if (state == SHIFT && bit_cnt == DATA_WIDTH-1 && sclk_en && sclk == 0)
			byte_cnt <= byte_cnt + 1;
		end
	end
endmodule