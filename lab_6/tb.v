`timescale 1ns/1ps

module fib64_tb;

reg clk;
reg reset;
reg [6:0] n;

wire [31:0] fib_low;
wire [31:0] fib_high;
wire [6:0] cycles;
wire done;

fib64 uut (
    .n(n),
    .reset(reset),
    .clk(clk),
    .fib_low(fib_low),
    .fib_high(fib_high),
    .cycles(cycles),
    .done(done)
);

always #5 clk = ~clk;

initial begin

    clk = 0;
    reset = 1;
    n = 7'd48;   // choose a value where fib_high is non-zero

    #10;
    reset = 0;

    wait(done);

    $display("----------------------------");
    $display("n        = %d", n);
    $display("fib_high = %d", fib_high);
    $display("fib_low  = %d", fib_low);
    $display("fib      = %d", {fib_high, fib_low});
    $display("cycles   = %d", cycles);
    $display("----------------------------");

    $finish;

end

endmodule