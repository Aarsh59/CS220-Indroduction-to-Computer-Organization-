`timescale 1ns/1ps

module tb_program1;
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
reg prev_io_stall;

task load_ins;
    input [7:0] addr;
    input [31:0] value;
    begin
        ins_addr = addr;
        ins = value;
        #10;
    end
endtask

task emit_char;
    input [31:0] value;
    begin
        $write("%c", value[7:0]);
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
        emit_char(out_reg1);
        emit_char(out_reg2);
        emit_char(out_reg3);
        emit_char(out_reg4);
        done_copying_io_regs <= 1'b1;
    end

    if (done) begin
        if (io_reg_index >= 1) emit_char(out_reg1);
        if (io_reg_index >= 2) emit_char(out_reg2);
        if (io_reg_index >= 3) emit_char(out_reg3);
        if (io_reg_index >= 4) emit_char(out_reg4);
        $display("");
        $display("Program 1 completed.");
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
    prev_io_stall = 1'b0;

    #12;
    reset = 1'b0;

    load_ins(8'd0,  32'h20020200); // addi $2,$0,512
    load_ins(8'd1,  32'h3C034865); // lui  $3,0x4865
    load_ins(8'd2,  32'h34636C6C); // ori  $3,$3,0x6c6c
    load_ins(8'd3,  32'hAC430000); // sw   $3,0($2)
    load_ins(8'd4,  32'h3C046F20); // lui  $4,0x6f20
    load_ins(8'd5,  32'h3484576F); // ori  $4,$4,0x576f
    load_ins(8'd6,  32'hAC440004); // sw   $4,4($2)
    load_ins(8'd7,  32'h3C05726C); // lui  $5,0x726c
    load_ins(8'd8,  32'h34A56421); // ori  $5,$5,0x6421
    load_ins(8'd9,  32'hAC450008); // sw   $5,8($2)
    load_ins(8'd10, 32'h2006000A); // addi $6,$0,10
    load_ins(8'd11, 32'hA046000C); // sb   $6,12($2)
    load_ins(8'd12, 32'h200103EC); // addi $1,$0,1004
    load_ins(8'd13, 32'h20070000); // addi $7,$0,0
    load_ins(8'd14, 32'h28E8000D); // slti $8,$7,13
    load_ins(8'd15, 32'h11000005); // beq  $8,$0,end
    load_ins(8'd16, 32'h00474820); // add  $9,$2,$7
    load_ins(8'd17, 32'h912A0000); // lbu  $10,0($9)
    load_ins(8'd18, 32'h002A000C); // syscall $1,$10
    load_ins(8'd19, 32'h20E70001); // addi $7,$7,1
    load_ins(8'd20, 32'h0800000E); // j    loop
    load_ins(8'd21, 32'h200103E9); // addi $1,$0,1001
    load_ins(8'd22, 32'h0020000C); // syscall $1,$0

    ins_addr = 8'd0;
    ins = 32'd0;
    done_storing = 1'b1;
end

initial begin
    watchdog_cycles = 0;
    wait(done_storing == 1'b1);
    while (!done && watchdog_cycles < 800) begin
        @(posedge clk);
        watchdog_cycles = watchdog_cycles + 1;
    end

    if (!done) begin
        $display("TIMEOUT after %0d cycles", watchdog_cycles);
        $finish;
    end
end

endmodule
