`timescale 1ns/1ps
module spi_master_v2_clkdiv_tb;

	// DUT接口宣告
	reg clk;
	reg rst_n;
	reg start;
	reg [7:0] data_in;
	reg [3:0] data_len;
	reg [1:0] cs_sel;
	
	wire busy;
	wire done;
	wire [7:0] data_out;
	wire sclk;
	wire mosi;
	reg miso;
	wire [3:0] cs_n;
	
	//測試資料
	reg [7:0] test_data [0:2];
	integer i;
	
	//初始化miso, 避免初期為x
	initial miso = 1'b1;
	
	// DUT實例化
	spi_master_v2_clkdiv uut(
		.clk(clk),
		.rst_n(rst_n),
		.start(start),
		.data_in(data_in),
		.data_len(data_len),
		.cs_sel(cs_sel),
		.busy(busy),
		.done(done),
		.data_out(data_out),
		.sclk(sclk),
		.mosi(mosi),
		.miso(miso),
		.cs_n(cs_n)
	);

	//產生clock
	initial clk = 0;
	always #5 clk = ~clk;  // 100MHz clock
	
	//模擬slave回應:給固定值避免miso是x
	always @(negedge sclk) begin
		miso <= 1'b1;  // or toggle with miso <= ~miso;
	end

	//主測試流程
	initial begin
		$display("=== SPI Master V2 with Clock Divider Testbench ===");
		
		//初始值
		rst_n = 0;
		start = 0;
		data_in = 8'h00;
		data_len = 3;  //傳送三個Byte
		cs_sel = 2'd1;  //選擇CS[1]
		i = 0;
		
		//測試資料
		test_data[0] = 8'hA5;
		test_data[1] = 8'h3C;
      test_data[2] = 8'h7E;

      // Reset
		#20;
		rst_n = 1;
		
		//開始傳送
		#20;
		data_in = test_data[0];
		start = 1;
		#10;
		start = 0;
		
		//傳送接下來的Byte(在LOAD時更新data_in)
		forever begin
			@(posedge clk);
			if (busy && uut.state == 2'b01) begin  //在LOAD狀態時
				if (i < data_len - 1) begin
					i = i + 1;
					data_in = test_data[i];
				end
			end
			if (done) begin
			   #1;
				$display("[PASS] DONE! data_out = %h", data_out);
				$finish;
				$monitor("Time=%0t, done=%b, data_out=%h", $time, done, data_out);
			end
		end
	end
endmodule
		