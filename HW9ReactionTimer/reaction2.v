module reaction2(Clock, state, myFLAG, LEDn, Digit1, Digit0, Digit2);
	input Clock; //clock at 1k Hz
	input [1:0]  state;
	output reg myFLAG;
	output wire [9:0] LEDn; // Sending back info on the LED pattern
	output wire [9:0] Digit2, Digit1, Digit0; // Sending back info from seg7
	
	
	reg [9:0] myLED;
	reg [6:0] myBCD2, myBCD1, myBCD0;
	reg [9:0] k;
	reg [9:0] myRand;
	
	
	always @(posedge Clock)
		begin
			if (state == 0) // idle (0.00)
				begin
					myLED[9:0] <= 0; // leds are all off in idle
					myBCD1 <= 0; //HEX1
 					myBCD0 <= 0; //HEX0
					myBCD2 <= 0; //HEX2

					
					k <= 0;
					myRand <= myRand + 11; 
				
				end
			else if (state == 1) // delay
				begin
					myLED[9:0] <= 10'b1000000000;
					
					myBCD1 <= 0; 
 					myBCD0 <= 0; 
					myBCD2 <= 0; 

					
					myRand <= myRand;
					k <= k + 1;
					
					if (k > myRand%1000) 
							myFLAG <= 1;
					else
							myFLAG <=0;
				end
			
		else if (state == 2) // timing
					begin
					  myLED[9:0] <= 10'b1111111111;
					  myFLAG <= 0;
					  k <= 0;

					  // ripple BCD counters: ms - thousandths (BCD0), hundredths (BCD1), tenths (BCD2)
					  if (myBCD0 == 4'd9) begin
						 myBCD0 <= 0;
						 if (myBCD1 == 4'd9) begin
							myBCD1 <= 0;
							if (myBCD2 == 4'd9) begin
							  myBCD2 <= 0;        
							end else begin
							  myBCD2 <= myBCD2 + 1;
							end
						 end else begin
							myBCD1 <= myBCD1 + 1;
						 end
					  end else begin
						 myBCD0 <= myBCD0 + 1;
					  end
					end
			
			else if (state == 3) // display
				begin
				   myLED[9:0] <= 10'b1010101010;
					myBCD0 <= myBCD0;
					myBCD1 <= myBCD1;
					myBCD2 <= myBCD2;

					myFLAG <= 0;
					k <= 0;
					myRand <= myRand;
				
				end
			
			else // something has gone wrong
			   begin
					myLED[9:0] <= 10'b1111100000;
					myBCD0 <= 8;
					myBCD1 <= 8;
					myBCD2 <= 8;
					myFLAG <= 0;
					k <= 0;
					myRand <= myRand;
					
				end
			
		end
	
	
	assign LEDn = myLED;
	
	//instantiate my seg7 modules
	seg7 seg1(myBCD1, Digit1);
	seg7 seg2(myBCD0, Digit0);
	seg7 seg3(myBCD2, Digit2);
	seg7 seg0(4'd0, Digit3);       

	


endmodule 