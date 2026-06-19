module adder32 (input [31:0] a , input [31:0] b , input cin , output [31:0] sum , output carry);
wire [32:0] cout ; 
assign cout[0] = cin ; 
genvar i ; 
generate
for(i = 0 ; i<32 ; i = i+1) begin : ripple
fulladder fa (a[i],b[i],cout[i],sum[i],cout[i+1]);
end
endgenerate
assign carry = cout[32];


endmodule