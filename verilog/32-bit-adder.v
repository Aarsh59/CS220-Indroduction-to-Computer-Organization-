module addsub (input [31:0] a , input [31:0] b , input sub , output [31:0] sum , output sign  );

wire [32:0] cout ; 
wire [31:0] neg ;
assign cout[0] = sub ;  
assign neg = b^{32{sub}};
genvar i ;
generate for(i = 0 ; i<32 ; i=i+1) begin : ripple

    fulladder fa (a[i],neg[i],cout[i],sum[i],cout[i+1]);
  end
endgenerate
assign sign = sum[31];





endmodule

