`timescale 1ns/1ps
module tb_computer;
reg clk;
reg reset;
reg done_storing;
reg [7:0] ins_addr;
reg [31:0] ins;
reg done_copying_io_regs;
wire done;
wire [31:0] out_reg1;
wire [31:0] out_reg2;
wire [31:0] out_reg3;
wire [31:0] out_reg4;
wire [31:0] total_cycles;
wire [31:0] proc_cycles;
wire io_stall;
wire [2:0] io_reg_index;

Computer uut(
    .reset(reset),
    .ins_addr(ins_addr),
    .ins(ins),
    .clk(clk),
    .done_storing(done_storing),
    .done_copying_io_regs(done_copying_io_regs),
    .done(done),
    .out_reg1(out_reg1),
    .out_reg2(out_reg2),
    .out_reg3(out_reg3),
    .out_reg4(out_reg4),
    .total_cycles(total_cycles),
    .proc_cycles(proc_cycles),
    .io_stall(io_stall),
    .io_reg_index(io_reg_index)
);

always #5 clk = ~clk;

integer print_count;

initial begin
    clk = 0;
    reset = 1;
    done_storing = 0;
    done_copying_io_regs = 0;
    ins_addr = 0;
    ins = 0;
    print_count = 1;

    #7 reset = 0;

    // addi $1, $0, 10    → x = 10
    ins_addr = 8'd0;  ins = 32'h2001000A; #10;
    // addi $2, $0, 0     → i = 0
    ins_addr = 8'd1;  ins = 32'h20020000; #10;
    // addi $3, $0, 30    → N = 30
    ins_addr = 8'd2;  ins = 32'h2003001E; #10;
    // addi $6, $0, 1004  → syscall print number
    ins_addr = 8'd3;  ins = 32'h200603EC; #10;
    // pc=4: slt $4, $2, $3
    ins_addr = 8'd4;  ins = 32'h0043202A; #10;
    // pc=5: beq $4, $0, +4
    ins_addr = 8'd5;  ins = 32'h10800004; #10;
    // pc=6: add $1, $1, $2
    ins_addr = 8'd6;  ins = 32'h00220820; #10;
    // pc=7: syscall $6, $1
    ins_addr = 8'd7;  ins = 32'h00C1000C; #10;
    // pc=8: addi $2, $2, 1
    ins_addr = 8'd8;  ins = 32'h20420001; #10;
    // pc=9: beq $0, $0, -6
    ins_addr = 8'd9;  ins = 32'h1000FFFA; #10;
    // pc=10: addi $6, $0, 1001
    ins_addr = 8'd10; ins = 32'h200603E9; #10;
    // pc=11: syscall $6, $0
    ins_addr = 8'd11; ins = 32'h00C0000C; #10;

    done_storing = 1;

   forever begin
    @(posedge clk);

    if (io_stall) begin
        // wait one cycle for signals to settle
        @(posedge clk);
        
        $display("── STALL: printing batch ──");
        $display("out%0d = %0d", print_count,   $signed(out_reg1));
        $display("out%0d = %0d", print_count+1, $signed(out_reg2));
        $display("out%0d = %0d", print_count+2, $signed(out_reg3));
        $display("out%0d = %0d", print_count+3, $signed(out_reg4));
        print_count = print_count + 4;

        done_copying_io_regs = 1;
        #10;
        done_copying_io_regs = 0;

        // wait for io_stall to go low before continuing
        wait(io_stall == 0);
        @(posedge clk);
    end

    if (done) begin
        $display("── DONE: printing residual, io_reg_index=%0d ──", io_reg_index);
        if (io_reg_index >= 1) $display("out%0d = %0d", print_count,   $signed(out_reg1));
        if (io_reg_index >= 2) $display("out%0d = %0d", print_count+1, $signed(out_reg2));
        if (io_reg_index >= 3) $display("out%0d = %0d", print_count+2, $signed(out_reg3));
        if (io_reg_index >= 4) $display("out%0d = %0d", print_count+3, $signed(out_reg4));

        $display("Total cycles     = %0d", total_cycles);
        $display("Processor cycles = %0d", proc_cycles);
        $finish;
    end
end
end
endmodule