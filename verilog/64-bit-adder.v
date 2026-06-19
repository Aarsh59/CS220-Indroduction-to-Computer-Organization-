module adder64 (
    input  [31:0] a_low,
    input  [31:0] a_hi,
    input  [31:0] b_low,
    input  [31:0] b_hi,
    output [31:0] sum_low,
    output [31:0] sum_hi,
    output        carry
);

wire carry1;
wire carry2;


add ad1 (
    .a(a_low),
    .b(b_low),
    .sub(1'b0),
    .sum(sum_low),
    .sign(carry1)
);


add ad2 (
    .a(a_hi),
    .b(b_hi),
    .sub(carry1),
    .sum(sum_hi),
    .sign(carry2)
);

assign carry = carry2;

endmodule
