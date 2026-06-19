`timescale 1ns/1ps

module tb_program3;
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

task load_ins;
    input [7:0] addr;
    input [31:0] value;
    begin
        ins_addr = addr;
        ins = value;
        #10;
    end
endtask

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

    if (done) begin
        if (io_reg_index >= 1) $display("Program 3 output x = %0d", $signed(out_reg1));
        if (io_reg_index >= 2) $display("Extra output 2 = %0d", $signed(out_reg2));
        if (io_reg_index >= 3) $display("Extra output 3 = %0d", $signed(out_reg3));
        if (io_reg_index >= 4) $display("Extra output 4 = %0d", $signed(out_reg4));
        $display("Input supplied: n=%0d", 10);
        $display("Expected x = 55");
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

    load_ins(8'd0,  32'h201D0400); // addi $29,$0,1024
    load_ins(8'd1,  32'h200103EB); // addi $1,$0,1003
    load_ins(8'd2,  32'h0022000C); // syscall $1,$2
    load_ins(8'd3,  32'h04400004); // bltz $2,neg
    load_ins(8'd4,  32'h0C00000C); // jal  sum
    load_ins(8'd5,  32'h200603EC); // addi $6,$0,1004
    load_ins(8'd6,  32'h00C2000C); // syscall $6,$2
    load_ins(8'd7,  32'h08000019); // j    exit
    load_ins(8'd8,  32'h2002FFFF); // addi $2,$0,-1
    load_ins(8'd9,  32'h200603EC); // addi $6,$0,1004
    load_ins(8'd10, 32'h00C2000C); // syscall $6,$2
    load_ins(8'd11, 32'h08000019); // j    exit
    load_ins(8'd12, 32'h23BDFFF8); // addi $29,$29,-8
    load_ins(8'd13, 32'hAFBF0004); // sw   $31,4($29)
    load_ins(8'd14, 32'hAFA20000); // sw   $2,0($29)
    load_ins(8'd15, 32'h10400005); // beq  $2,$0,base
    load_ins(8'd16, 32'h2042FFFF); // addi $2,$2,-1
    load_ins(8'd17, 32'h0C00000C); // jal  sum
    load_ins(8'd18, 32'h8FA30000); // lw   $3,0($29)
    load_ins(8'd19, 32'h00431020); // add  $2,$2,$3
    load_ins(8'd20, 32'h08000016); // j    epilogue
    load_ins(8'd21, 32'h20020000); // addi $2,$0,0
    load_ins(8'd22, 32'h8FBF0004); // lw   $31,4($29)
    load_ins(8'd23, 32'h23BD0008); // addi $29,$29,8
    load_ins(8'd24, 32'h03E00008); // jr   $31
    load_ins(8'd25, 32'h200103E9); // addi $1,$0,1001
    load_ins(8'd26, 32'h0020000C); // syscall $1,$0

    ins_addr = 8'd0;
    ins = 32'd0;
    done_storing = 1'b1;
end

initial begin
    wait(done_storing == 1'b1);
    send_input_word(32'd10);
end

initial begin
    watchdog_cycles = 0;
    wait(done_storing == 1'b1);
    while (!done && watchdog_cycles < 2500) begin
        @(posedge clk);
        watchdog_cycles = watchdog_cycles + 1;
    end

    if (!done) begin
        $display("TIMEOUT after %0d cycles", watchdog_cycles);
        $finish;
    end
end

endmodule
