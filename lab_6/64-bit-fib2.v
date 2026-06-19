module fib64 (input [6:0] n , input reset , input clk , output reg [31:0] fib_low ,output reg [31:0] fib_high ,output reg [7:0] cycles , output reg done);

reg[31:0] f1_low ; 
reg [31:0] f2_low ; 
reg[31:0] f1_high ; 
reg [31:0] f2_high ; 
reg[6:0] counter ; 
wire carry ;
wire  [31:0] a_in ; 
wire [31:0] b_in ;
wire [31:0] sum_in ;
wire cin ; 
reg carry_low ;
reg state ; 
assign a_in = (state == 1'b0) ? f1_low  : f1_high;
assign b_in = (state == 1'b0) ? f2_low  : f2_high;
assign cin  = (state == 1'b0) ? 1'b0 : carry_low;
adder32 ad (
    .a(a_in),
    .b(b_in),
    .cin(cin),
    .sum(sum_in),
    .carry(carry)
);
always @ (posedge clk or posedge reset) begin
    if(reset) begin
    f1_low<=32'd1;
    f2_low<=32'd1;
    f1_high<=32'd0;
    f2_high<=32'd0;
    counter<=7'd2;
    state<=1'b0;
    done<=1'b0;
    cycles<=8'd0;
    fib_low<=32'd0;
    fib_high<=32'd0;
    end
    else if(!done) begin
        if(n<=7'd2) begin
            fib_low<=32'd1;
            fib_high<=32'd0;
            cycles<=8'd0;
            done<=1'b1;
        end
        else begin


            if(state==1'b0) begin
                 carry_low <= carry;  
                fib_low<=sum_in;
                f1_low<=f2_low;
                f2_low<=sum_in;
                cycles<=cycles + 8'd1;
                state<=1'b1;
            end
            else begin
                fib_high<=sum_in;
                f1_high<=f2_high;
                f2_high<=sum_in;
                cycles<=cycles + 8'd1;
                 counter<=counter+7'd1;
                state<=1'b0;
                  if(counter==n-1) begin
                done<=1'b1;
                end
            end
           
          
            


        end

    end



end


endmodule