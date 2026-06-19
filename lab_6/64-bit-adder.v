module adder64 (input [63:0] a , input [63:0] b , input cin , output [63:0] sum , output carry);
wire [64:0] cout ; 
assign cout[0] = cin ; 
genvar i ; 
generate
for(i = 0 ; i<64 ; i = i+1) begin : ripple
fulladder fa (a[i],b[i],cout[i],sum[i],cout[i+1]);
end
endgenerate
assign carry = cout[64];


endmodule