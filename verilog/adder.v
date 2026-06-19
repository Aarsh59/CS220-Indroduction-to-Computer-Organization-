module add (input [31:0] a , input [31:0] b , input sub , output [31:0] sum , output sign  );

wire [32:0] cout ; 
assign cout[0] = sub ;  
genvar i ;
generate for(i = 0 ; i<32 ; i=i+1) begin : ripple

    fulladder fa (a[i],b[i],cout[i],sum[i],cout[i+1]);
  end
endgenerate
assign sign = cout[32];





endmodule