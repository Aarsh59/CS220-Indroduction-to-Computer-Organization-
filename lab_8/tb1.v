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
integer timeout;

initial begin

    clk = 0;
    reset = 1;
    done_storing = 0;
    done_copying_io_regs = 0;
    ins_addr = 0;
    ins = 0;
    print_count = 1;

    #7 reset = 0;

    ins_addr = 8'd0;  ins = 32'h2001000A; #10;
    ins_addr = 8'd1;  ins = 32'h20020000; #10;
    ins_addr = 8'd2;  ins = 32'h2003001E; #10;
    ins_addr = 8'd3;  ins = 32'h200603EC; #10;
    ins_addr = 8'd4;  ins = 32'h0043202A; #10;
    ins_addr = 8'd5;  ins = 32'h10800012; #10;
    ins_addr = 8'd6;  ins = 32'h30450001; #10;
    ins_addr = 8'd7;  ins = 32'h14A00007; #10;
    ins_addr = 8'd8;  ins = 32'h20280000; #10;
    ins_addr = 8'd9;  ins = 32'h20490000; #10;
    ins_addr = 8'd10; ins = 32'h0C000016; #10;
    ins_addr = 8'd11; ins = 32'h002A0820; #10;
    ins_addr = 8'd12; ins = 32'h00C1000C; #10;
    ins_addr = 8'd13; ins = 32'h20420001; #10;
    ins_addr = 8'd14; ins = 32'h08000004; #10;
    ins_addr = 8'd15; ins = 32'h20280000; #10;
    ins_addr = 8'd16; ins = 32'h20490000; #10;
    ins_addr = 8'd17; ins = 32'h0C000016; #10;
    ins_addr = 8'd18; ins = 32'h002A0822; #10;
    ins_addr = 8'd19; ins = 32'h00C1000C; #10;
    ins_addr = 8'd20; ins = 32'h20420001; #10;
    ins_addr = 8'd21; ins = 32'h08000004; #10;
    ins_addr = 8'd22; ins = 32'h01095020; #10;
    ins_addr = 8'd23; ins = 32'h03E00008; #10;
    ins_addr = 8'd24; ins = 32'h200603E9; #10;
    ins_addr = 8'd25; ins = 32'h00C0000C; #10;

    done_storing = 1;

    forever begin
    @(posedge clk);


 if (io_stall) begin
    $display("out%0d = %0d", print_count,   $signed(out_reg1));
    $display("out%0d = %0d", print_count+1, $signed(out_reg2));
    $display("out%0d = %0d", print_count+2, $signed(out_reg3));
    $display("out%0d = %0d", print_count+3, $signed(out_reg4));
    print_count = print_count + 4;

    #20;                         // wait 2 full cycles
    done_copying_io_regs = 1;    // assert
    #20;                         // hold for 2 cycles
    done_copying_io_regs = 0;    // deassert

    // wait for stall to clear
    timeout = 0;
    while (io_stall == 1 && timeout < 500) begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    if (timeout >= 500) begin
        $display("TIMEOUT!");
        $finish;
    end
end

    if (done) begin
        $display("── DONE io_reg_index=%0d ──", io_reg_index);
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
