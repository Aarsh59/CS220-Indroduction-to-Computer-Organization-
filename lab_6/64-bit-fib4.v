module fib64 (input [6:0] n , input reset , input clk , output reg [31:0] fib_low ,output reg [31:0] fib_high ,output reg [6:0] cycles , output reg done);

reg[31:0] f1_low ; 
reg [31:0] f2_low ; 
reg[31:0] f1_high ; 
reg [31:0] f2_high ; 
wire [31:0] f3_low ; 
wire [31:0] f3_high;
 
wire carry ;
reg carry_low ;
 
wire carry_high ;  

adder32 ad_low (
    .a(f1_low),
    .b(f2_low),
    .cin(1'b0),
    .sum(f3_low),
    .carry(carry)
);
adder32 ad_high (
    .a(f1_high),
    .b(f2_high),
    .cin(carry_low),
    .sum(f3_high),
    .carry(carry_high)
);
always @ (posedge clk or posedge reset) begin
    if(reset) begin
    f1_low<=32'd1;
    f2_low<=32'd1;
    f1_high<=32'd0;
    f2_high<=32'd0;

   
    done<=1'b0;
    cycles<=7'd0;
    fib_low<=32'd0;
    fib_high<=32'd0;
    end
    else if(!done) begin
        if(n<=7'd2) begin
            fib_low<=32'd1;
            fib_high<=32'd0;
            cycles<=7'd0;
            done<=1'b1;
        end
        else begin
        if(cycles==7'd0)begin
            carry_low<=carry;
            fib_low<=f3_low;
            f1_low<=f2_low;
            f2_low<=f3_low;
            cycles<=cycles+7'd1;
        end
        else if (cycles==n-2) begin
             fib_high<=f3_high;
            f1_high<=f2_high;
            f2_high<=f3_high;
            cycles<=cycles+7'd1;
            done<=1'b1;
        end
        else begin
            carry_low<=carry;
            fib_low<=f3_low;
            f1_low<=f2_low;
            f2_low<=f3_low;
            fib_high<=f3_high;
            f1_high<=f2_high;
            f2_high<=f3_high;
            cycles<=cycles+7'd1;

        end

           
           
          
            


        end

    end



end


endmodule