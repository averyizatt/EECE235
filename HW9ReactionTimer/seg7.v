/*************************************************************
* This code corresponds to Figure 5.63
* Description: 2-digit Binary Coded Decimal File
* Note: Update to be consistent with our truth table
* EECE 235
*************************************************************/
module seg7 (bcd, leds);
	input [3:0] bcd;
	output reg [6:0] leds;

	always @(bcd)
	begin
		case (bcd) //this case statement assumes active high
			0: leds = 7'b0111111;
			1: leds = 7'b0000110;
			2: leds = 7'b1011011;
			3: leds = 7'b1001111;
			4: leds = 7'b1100110;
			5: leds = 7'b1101101;
			6: leds = 7'b1111101;
			7: leds = 7'b0000111;
			8: leds = 7'b1111111;
			9: leds = 7'b1101111;
			default: leds = 7'bx;
		endcase
		

	
	end

		
endmodule 