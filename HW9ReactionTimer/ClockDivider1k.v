/**********************************************
* This code is used to create a 100 Hz clock
* EECE 235
**********************************************/
module ClockDivider1k(clk, clk1k);

   input clk;        // FPGA's default clock is at 50 MHz
	output reg clk1k;

	// 50 MHz / 100 Hz = 500 k
	parameter new = 500000;
	reg [27:0] counter = 28'b0;
	
	always @(posedge clk) begin
    counter <= (counter == new-1) ? 28'd0 : counter + 28'd1;
    clk1k   <= (counter < (new>>1)) ? 1'b1 : 1'b0; // 
  end


endmodule