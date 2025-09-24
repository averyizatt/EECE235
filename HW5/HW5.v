// Code your design here


module MinTerm(w, x, y, z, f);
  input w;
  input x;
  input y;
  input z;
  output f;
  
  assign f = (~w & x & y & ~z) | (w & x & ~y &z) | (~x & y & z);
  
    
endmodule




module MaxTerm(w, x, y, z, f);
  input w;
  input x;
  input y;
  input z;
  output f;
  
  assign f = (~w & x & y & ~z) | (w & x & ~y &z) | (~x & y & z);
  
    
endmodule