module mul (
    input  [31:0] a,
    input  [31:0] b,
    input         reset,
    input         clk,
    output reg [31:0] p_low,
    output reg [31:0] p_hi,
    output reg        done
);

reg  [31:0] counter;
wire [31:0] abs_b;
wire [31:0] abs_a ; 
wire        result_sign;
assign abs_a  = a[31] ? (~a+1):a;
assign abs_b = b[31] ? (~b + 1) : b;
assign result_sign = a[31] ^ b[31];

wire [31:0] temp_low;
wire [31:0] temp_hi;
wire carry_unused;

adder64 ad (
    .a_low(p_low),
    .a_hi(p_hi),
    .b_low(abs_a),
    .b_hi(32'd0),
    .sum_low(temp_low),
    .sum_hi(temp_hi),
    .carry(carry_unused)
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        done    <= 1'b0;
        counter <= 32'd0;
        p_low   <= 32'd0;
        p_hi    <= 32'd0;
    end
    else if (!done) begin
        if (counter == abs_b) begin
            if (result_sign) begin
                {p_hi, p_low} <= (~{p_hi, p_low}) + 1;
            end
            done <= 1'b1;
        end
        else begin
            counter <= counter + 1;
            p_low   <= temp_low;
            p_hi    <= temp_hi;
        end
    end
end

endmodule
