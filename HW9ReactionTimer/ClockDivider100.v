/**********************************************
* This code is used to create a 100 Hz clock
* EECE 235
**********************************************/
module ClockDivider100(clk, clk100);

   input clk;        // FPGA's default clock is at 50 MHz
	output reg clk100;

	// 50 MHz / 100 Hz = 500 k
	parameter new = 50000;
	reg [27:0] counter = 28'b0;
	
	always @(posedge clk)
	  begin
	    counter <= counter + 1; // 28'd1
		 
		 if (counter >= new-1)
		    counter <= 28'b0;
			 
		  // update state. note values really need to change every 200 Hz
		  clk100  <= (counter<(new/2)) ? 1'b1: 1'b0;
	  
	  end


endmodule