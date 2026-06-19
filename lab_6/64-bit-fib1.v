module fib64 (input [6:0] n , input reset , input clk , output reg [31:0] fib_low ,output reg [31:0] fib_high ,output reg [6:0] cycles , output reg done);

reg[63:0] f1 ; 
reg [63:0] f2 ; 
reg[6:0] counter ; 
wire [63:0] f3 ; 
wire carry ; 
adder64 ad (
    .a(f1),
    .b(f2),
    .cin(1'b0),
    .sum(f3),
    .carry(carry)
);
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        f1<=64'd1;
        f2<=64'd1;
        counter<=7'd2;
        cycles<=7'd0;
        done<=1'b0;
        fib_high<=32'd0;
        fib_low<=32'd0;

    end
    else if (!done) begin
            if(n==7'd1) begin
                fib_low<=32'd1;
                fib_high<=32'd0;
                done<=1'b1;
                cycles<=7'd0;
            end
            else if (n==7'd2) begin
                   fib_low<=32'd1;
                fib_high<=32'd0;
                done<=1'b1;
                cycles<=7'd0;
            end
            else begin

                fib_high<= f2[63:32];
                fib_low <= f2[31:0];
                f1<=f2 ; 
                f2<=f3 ; 
                counter<=counter+7'd1;
                
                if(counter==n) begin
                    done<=1'b1;
                    cycles<=counter-7'd2;

                    
                end
               

            end

    end




end


endmodule