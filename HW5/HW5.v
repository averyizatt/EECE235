`timescale 1ns/1ps
`default_nettype none


// module BehaveMinTerm(w, x, y, z, f);
//   input w;
//   input x;
//   input y;
//   input z;
//   output f;
  
//   assign f = (~w & x & y & ~z) | (w & x & ~y &z) | (~x & y & z);
  
    
// endmodule


// module BehaveMaxTerm(w, x, y, z, f);
//   input w;
//   input x;
//   input y;
//   input z;
//   output f;
  
//   assign f = (y | z) & (x | y) & (x | z) & (~w | ~x | ~y) & (w | ~x | ~z);
  
    
// endmodule

// module StructMinTerm(w, x, y, z, f);
//   input w;
//   input x;
//   input y;
//   input z;
//   output f;
  
//   wire notW, notY, notZ, notX;
//   wire and1, and2, and3;
  
//   not w1(notW, w);
//   not y1(notY, y);
//   not z1(notZ, z);
//   not x1(notX, x);
  
//   and a1(and1, notW, x, y, notZ);
//   and b1(and2, w, x, notY, z);
//   and c1(and3, notX, z, y);
  
//   or or1(f, and1, and2, and3);
  
// endmodule
  

// module StructMaxTerm(w, x, y, z, node1);
//   input w;
//   input x;
//   input y;
//   input z;
//   output node1;
 
  
//   wire notW, notX, notY, notZ;
//   wire m1, m2, m3, m4, m5;
  
//   not nw1(notW, w);
//   not ny1(notY, y);
//   not nz1(notZ, z);
//   not nx1(notX, x);
  
  
//   or or1(m1, x, y);
//   or or2(m2, y, z);
//   or or3(m3, x, z);
//   or or4(m4, notY, notW, notX);
//   or or5(m5, notZ, notX, w);
  
//   and g_and(node1, m1, m2, m3, m4, m5);
  
// endmodule
  

// module TwoInputStructMaxTerm(w, x, y, z, node2);
//   input w;
//   input x;
//   input y;
//   input z;
//   output node2;
 
  
//   wire notW, notX, notY, notZ;
//   wire m1, m2, m3, m4, m5, m6, m7;
//   wire a1_and, b1_and, c1_and;
  
//   not nw1(notW, w);
//   not ny1(notY, y);
//   not nz1(notZ, z);
//   not nx1(notX, x);
  
  
//   or or1(m1, x, y);
//   or or2(m2, y, z);
//   or or3(m3, x, z);
//   or or4(m4, notX, notW);
//   or or5(m5, m4, notY);
//   or or6(m6, w, notX);
//   or or7(m7, notZ, m6);
  
//   and a_and(a1_and, m1, m2);
//   and b_and(b1_and, m3, a1_and);
//   and c_and(c1_and, m5, b1_and);
//   and d_and(node2, m7, c1_and);
  
// endmodule
  

module Test1DelayedTwoInputStructMaxTerm(w, x, y, z, node2);
  input w;
  input x;
  input y;
  input z;
  output node2;
 
  
  wire notW, notX, notY, notZ;
  wire m1, m2, m3, m4, m5, m6, m7;
  wire a1_and, b1_and, c1_and;
  
  not nw1(notW, w);
  not ny1(notY, y);
  not nz1(notZ, z);
  not nx1(notX, x);
  
  
  or #2 or1(m1, x, y);
  or #2 or2(m2, y, z);
  or #2 or3(m3, x, z);
  or #2 or4(m4, notX, notW);
  or #2 or5(m5, m4, notY);
  or #2 or6(m6, w, notX);
  or #2 or7(m7, notZ, m6);
  
  and #2 a_and(a1_and, m1, m2);
  and #2 b_and(b1_and, m3, a1_and);
  and #2 c_and(c1_and, m5, b1_and);
  and #2 d_and(node2, m7, c1_and);
  
endmodule
 