`timescale 1ns/1ps

module tb3;
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

integer print_count;
integer watchdog_cycles;
reg prev_io_stall;

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
    prev_io_stall <= io_stall;
    done_copying_io_regs <= 1'b0;

    if (io_stall && !prev_io_stall) begin
        $display("out%0d = %0d", print_count,     $signed(out_reg1));
        $display("out%0d = %0d", print_count + 1, $signed(out_reg2));
        $display("out%0d = %0d", print_count + 2, $signed(out_reg3));
        $display("out%0d = %0d", print_count + 3, $signed(out_reg4));
        print_count = print_count + 4;
        done_copying_io_regs <= 1'b1;
    end

    if (done) begin
        $display("Program completed.");
        $display("Inputs supplied: x=%0d, N=%0d", 10, 6);
        if (io_reg_index >= 1) $display("out%0d = %0d", print_count,     $signed(out_reg1));
        if (io_reg_index >= 2) $display("out%0d = %0d", print_count + 1, $signed(out_reg2));
        if (io_reg_index >= 3) $display("out%0d = %0d", print_count + 2, $signed(out_reg3));
        if (io_reg_index >= 4) $display("out%0d = %0d", print_count + 3, $signed(out_reg4));
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
    print_count = 1;
    prev_io_stall = 1'b0;

    #12;
    reset = 1'b0;

    // addi $1, $0, 1003
    ins_addr = 8'd0;  ins = 32'h200103EB; #10;
    // syscall $1, $2   ; input x
    ins_addr = 8'd1;  ins = 32'h0022000C; #10;
    // syscall $1, $3   ; input N
    ins_addr = 8'd2;  ins = 32'h0023000C; #10;
    // addi $4, $0, 0   ; i = 0
    ins_addr = 8'd3;  ins = 32'h20040000; #10;
    // addi $6, $0, 1004
    ins_addr = 8'd4;  ins = 32'h200603EC; #10;
    // slt $5, $4, $3
    ins_addr = 8'd5;  ins = 32'h0083282A; #10;
    // beq $5, $0, +18
    ins_addr = 8'd6;  ins = 32'h10A00012; #10;
    // andi $7, $4, 1
    ins_addr = 8'd7;  ins = 32'h30870001; #10;
    // bne $7, $0, +7
    ins_addr = 8'd8;  ins = 32'h14E00007; #10;
    // addi $8, $2, 0
    ins_addr = 8'd9;  ins = 32'h20480000; #10;
    // addi $9, $4, 0
    ins_addr = 8'd10; ins = 32'h20890000; #10;
    // jal 23
    ins_addr = 8'd11; ins = 32'h0C000017; #10;
    // add $2, $2, $10
    ins_addr = 8'd12; ins = 32'h004A1020; #10;
    // syscall $6, $2
    ins_addr = 8'd13; ins = 32'h00C2000C; #10;
    // addi $4, $4, 1
    ins_addr = 8'd14; ins = 32'h20840001; #10;
    // j 5
    ins_addr = 8'd15; ins = 32'h08000005; #10;
    // addi $8, $2, 0
    ins_addr = 8'd16; ins = 32'h20480000; #10;
    // addi $9, $4, 0
    ins_addr = 8'd17; ins = 32'h20890000; #10;
    // jal 23
    ins_addr = 8'd18; ins = 32'h0C000017; #10;
    // sub $2, $2, $10
    ins_addr = 8'd19; ins = 32'h004A1022; #10;
    // syscall $6, $2
    ins_addr = 8'd20; ins = 32'h00C2000C; #10;
    // addi $4, $4, 1
    ins_addr = 8'd21; ins = 32'h20840001; #10;
    // j 5
    ins_addr = 8'd22; ins = 32'h08000005; #10;
    // add $10, $8, $9
    ins_addr = 8'd23; ins = 32'h01095020; #10;
    // jr $31
    ins_addr = 8'd24; ins = 32'h03E00008; #10;
    // addi $6, $0, 1001
    ins_addr = 8'd25; ins = 32'h200603E9; #10;
    // syscall $6, $0
    ins_addr = 8'd26; ins = 32'h00C0000C; #10;

    ins_addr = 8'd0;
    ins = 32'd0;
    done_storing = 1'b1;
end

initial begin
    wait(done_storing == 1'b1);
    send_input_word(32'd10);
    send_input_word(32'd6);
end

initial begin
    watchdog_cycles = 0;
    wait(done_storing == 1'b1);
    while (!done && watchdog_cycles < 1200) begin
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
