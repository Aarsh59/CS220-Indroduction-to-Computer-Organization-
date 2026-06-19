module fib (input [5:0] n , input reset ,input clk , output reg [31:0] fibn , output reg done);

reg [5:0] counter ; 
reg [31:0] f1 ; 
reg [31:0] f2 ; 
wire [31:0] f3 ; 
wire unused ; 
addsub as1 (f2,f1,1'b0,f3,unused);
always @ (posedge clk or posedge reset) begin

if(reset==1'b1) begin
f1<=32'd1;
f2<=32'd1;
counter<=32'd2;
done<=1'b0;

end

else if(!done) begin
if(counter==n) begin
fibn<=f2;
done<=1'b1;
end
else begin
if(n==6'b000001) begin
fibn<=32'd1;
done<=1'b1;
end
else if(n==6'b000010) begin
fibn<=32'd1;
done<=1'b1;
end
else begin
counter<=counter+6'b000001;
f1<=f2;
f2<=f3;
end

end





end










end




endmodule
