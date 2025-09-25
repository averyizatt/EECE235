`default_nettype none
`timescale 1ns/1ps

// module BehaveMinMaxTestBench;
//   reg clk;
//   reg w;
//   reg x;
//   reg y;
//   reg z;
//   wire fMin, fMax;
//   integer i;
    
//   BehaveMinTerm MUT1 (.w(w), .x(x), .y(y), .z(z), .f(fMin));
//   BehaveMaxTerm MUT2 (.w(w), .x(x), .y(y), .z(z), .f(fMax));
  
  
  
//  initial begin
//     $dumpfile("dump.vcd");
//    $dumpvars(1, BehaveMinMaxTestBench);
//     clk = 1;
//     for (i = 0; i < 16; i = i + 1)
//       begin
//       {w, x, y, z} = i;
//       #1;
//    	  $display( w, x, y, z, fMin, fMax);
//              end
//         $finish;
    
//   end

  
// endmodule


//   StructMinTerm MUT1 (.w(w), .x(x), .y(y), .z(z), .f(fMin));
//   StructMaxTerm MUT2 (.w(w), .x(x), .y(y), .z(z), .node1(fMax));
//   TwoInputStructMaxTerm MUT3 (.w(w), .x(x), .y(y), .z(z), .node2(fMax));
//    $display( w, x, y, z, fMin);


module TestDelayedTwoInput;
  reg clk;
  reg w = 0;
  reg x = 0;
  reg y = 0;
  reg z = 0;
  wire fMin, fMax;
  integer i = 0;
  Test1DelayedTwoInputStructMaxTerm MUT3 (.w(w), .x(x), .y(y), .z(z), .node2(fMax)); 
  always #2 clk = ~clk;
  
 initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, TestDelayedTwoInput);
    clk = 1;
    i = 0;
   
    for (i = 0; i < 16; i = i + 1)
      begin
      {w, x, y, z} = i;
      #12;
   	  $display( w, x, y, z, fMax);
             end
        #70 $finish;
 end
endmodule