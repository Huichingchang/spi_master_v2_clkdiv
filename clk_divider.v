`timescale 1ns/1ps
module clk_divider #(
	parameter DIV_FACTOR = 4  // Divider by 4 by default
)(
	input clk,
	input rst_n,
	output reg clk_out
);
	reg [$clog2(DIV_FACTOR)-1:0] count;
	
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			count <= 0;
			clk_out <= 0;
		end else begin
			if (count == DIV_FACTOR/2 - 1) begin
				count <= 0;
				clk_out <= ~clk_out;
		   end else begin
				count <= count + 1;
			end
		end
	end
endmodule