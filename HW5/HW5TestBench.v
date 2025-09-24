// Code your testbench here
// or browse Examples
// Code your testbench here
// or browse Examples
module MinMaxTestBench;
  reg clk;
  
  reg w;
  reg x;
  reg y;
  reg z;
 
  wire fMin, fMax;
  
  integer i;
  
    
 MinTerm MUT1 (.w(w), .x(x), .y(y), .z(z), .f(fMin));
 MaxTerm MUT2 (.w(w), .x(x), .y(y), .z(z), .f(fMax));
  
  
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1, MinMaxTestBench);
    clk = 1;
    
    
    for (i = 0; i < 16; i = i + 1) begin
      {w, x, y, z} = i;
    		#1;
    $display( w, x, y, z, fMin, fMax);
             end
        $finish;
    
  end

  
endmodule