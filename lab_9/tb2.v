`timescale 1ns/1ps

module tb2;
reg clk;
reg reset;
reg done_storing;
reg [7:0] ins_addr;
reg [31:0] ins;
reg done_copying_io_regs;
reg [31:0] input_value;
reg input_valid;

wire done;
wire [31:0] out_reg1;
wire [31:0] out_reg2;
wire [31:0] out_reg3;
wire [31:0] out_reg4;
wire [31:0] total_cycles;
wire [31:0] proc_cycles;
wire io_stall;
wire [2:0] io_reg_index;
wire waiting_for_input;

integer watchdog_cycles;

task send_input_word;
    input [31:0] value;
    begin
        wait(waiting_for_input == 1'b1);
        @(negedge clk);
        input_value = value;
        input_valid = 1'b1;
        wait(waiting_for_input == 1'b0);
        @(negedge clk);
        input_valid = 1'b0;
        input_value = 32'd0;
    end
endtask

Computer uut (
    .reset(reset),
    .ins_addr(ins_addr),
    .ins(ins),
    .clk(clk),
    .done_storing(done_storing),
    .done_copying_io_regs(done_copying_io_regs),
    .input_value(input_value),
    .input_valid(input_valid),
    .done(done),
    .out_reg1(out_reg1),
    .out_reg2(out_reg2),
    .out_reg3(out_reg3),
    .out_reg4(out_reg4),
    .total_cycles(total_cycles),
    .proc_cycles(proc_cycles),
    .io_stall(io_stall),
    .io_reg_index(io_reg_index),
    .waiting_for_input(waiting_for_input)
);

always #5 clk = ~clk;

always @(posedge clk) begin
    done_copying_io_regs <= 1'b0;

    if (io_stall) begin
        done_copying_io_regs <= 1'b1;
    end

    if (done) begin
        $display("Program completed.");
        $display("Inputs supplied: x=%0d, y=%0d", 12, 30);
        if (io_reg_index >= 1) $display("Printed z = %0d", $signed(out_reg1));
        if (io_reg_index >= 2) $display("out_reg2 = %0d", $signed(out_reg2));
        if (io_reg_index >= 3) $display("out_reg3 = %0d", $signed(out_reg3));
        if (io_reg_index >= 4) $display("out_reg4 = %0d", $signed(out_reg4));
        $display("Total cycles     = %0d", total_cycles);
        $display("Processor cycles = %0d", proc_cycles);
        $finish;
    end
end

initial begin
    clk = 1'b0;
    reset = 1'b1;
    done_storing = 1'b0;
    ins_addr = 8'd0;
    ins = 32'd0;
    done_copying_io_regs = 1'b0;
    input_value = 32'd0;
    input_valid = 1'b0;
    #12;
    reset = 1'b0;

    // addi $1, $0, 1003
    ins_addr = 8'd0; ins = 32'h200103EB; #10;
    // syscall $1, $2
    ins_addr = 8'd1; ins = 32'h0022000C; #10;
    // syscall $1, $3
    ins_addr = 8'd2; ins = 32'h0023000C; #10;
    // add $4, $2, $3
    ins_addr = 8'd3; ins = 32'h00432020; #10;
    // addi $1, $0, 1004
    ins_addr = 8'd4; ins = 32'h200103EC; #10;
    // syscall $1, $4
    ins_addr = 8'd5; ins = 32'h0024000C; #10;
    // addi $1, $0, 1001
    ins_addr = 8'd6; ins = 32'h200103E9; #10;
    // syscall $1, $0
    ins_addr = 8'd7; ins = 32'h0020000C; #10;

    ins_addr = 8'd0;
    ins = 32'd0;
    done_storing = 1'b1;
end

initial begin
    wait(done_storing == 1'b1);
    send_input_word(32'd12);
    send_input_word(32'd30);
end

initial begin
    watchdog_cycles = 0;
    wait(done_storing == 1'b1);
    while (!done && watchdog_cycles < 300) begin
        @(posedge clk);
        watchdog_cycles = watchdog_cycles + 1;
    end

    if (!done) begin
        $display("TIMEOUT after %0d cycles", watchdog_cycles);
        $display("waiting_for_input=%0b io_stall=%0b io_reg_index=%0d", waiting_for_input, io_stall, io_reg_index);
        $finish;
    end
end

endmodule
