`timescale 1ns/1ps
module tb_computer;
reg clk;
reg reset;
reg done_storing;
reg [7:0] ins_addr;
reg [31:0] ins;
wire done;
wire [31:0] out_reg1;
wire [31:0] out_reg2;
wire [31:0] out_reg3;
wire [31:0] out_reg4;
wire [31:0] total_cycles;
wire [31:0] proc_cycles;

Computer uut(
    reset, ins_addr, ins, clk, done_storing,
    done, out_reg1, out_reg2, out_reg3, out_reg4,
    total_cycles, proc_cycles
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;
    done_storing = 0;
    ins_addr = 0;
    ins = 0;

    #7 reset = 0;

    // addi $1, $0, -15       → a = $1
    ins_addr = 8'd0;  ins = 32'h2001FFF1; #10;
    // addi $2, $0, -40       → b = $2
    ins_addr = 8'd1;  ins = 32'h2002FFD8; #10;
    // addi $5, $0, 5         → x = $5
    ins_addr = 8'd2;  ins = 32'h20050005; #10;

    // add $3, $1, $2         → c = a+b → $3
    ins_addr = 8'd3;  ins = 32'h00221820; #10;
    // sub $4, $1, $2         → d = a-b → $4
    ins_addr = 8'd4;  ins = 32'h00222022; #10;

    // print c
    // addi $6, $0, 1004
    ins_addr = 8'd5;  ins = 32'h200603EC; #10;
    // syscall $6, $3
    ins_addr = 8'd6;  ins = 32'h00C3000C; #10;

    // print d
    // syscall $6, $4
    ins_addr = 8'd7;  ins = 32'h00C4000C; #10;

    // c = ((a & b) | (a ^ b)) & ~(c | d)
    // and $7, $1, $2         → $7 = a & b
    ins_addr = 8'd8;  ins = 32'h00223824; #10;
    // xor $8, $1, $2         → $8 = a ^ b
    ins_addr = 8'd9;  ins = 32'h00224026; #10;
    // or  $7, $7, $8         → $7 = (a&b)|(a^b)
    ins_addr = 8'd10; ins = 32'h00E83825; #10;
    // or  $9, $3, $4         → $9 = c | d
    ins_addr = 8'd11; ins = 32'h00644825; #10;
    // nor $9, $9, $0         → $9 = ~(c|d)
    ins_addr = 8'd12; ins = 32'h01204827; #10;
    // and $3, $7, $9         → c = result → $3
    ins_addr = 8'd13; ins = 32'h00E91824; #10;

    // d = ((a & 0xabcd) ^ 0xcafe) & (c | 0xdead)
    // andi $8, $1, 0xabcd    → $8 = a & 0xabcd
    ins_addr = 8'd14; ins = 32'h3028ABCD; #10;
    // xori $8, $8, 0xcafe    → $8 = $8 ^ 0xcafe
    ins_addr = 8'd15; ins = 32'h3908CAFE; #10;
    // ori  $9, $3, 0xdead    → $9 = c | 0xdead
    ins_addr = 8'd16; ins = 32'h3469DEAD; #10;
    // and  $4, $8, $9        → d = result → $4
    ins_addr = 8'd17; ins = 32'h01092024; #10;

    // print d
    // syscall $6, $4
    ins_addr = 8'd18; ins = 32'h00C4000C; #10;

    // c = (((a >> x) << 10) << x) ^ ((d >> 10) | (x >> 2))
    // srav $7, $1, $5        → $7 = a >> x (arithmetic)
    // srav rd,rt,rs: 000000 rs rt rd 00000 000111
    // rs=$5, rt=$1, rd=$7
    // 000000 00101 00001 00111 00000 000111
    // = (5<<21)|(1<<16)|(7<<11)|7
    // = 0x00A13807
    ins_addr = 8'd19; ins = 32'h00A13807; #10;

    // sll $7, $7, 10         → $7 = $7 << 10
    // sll rd,rt,shamt: 000000 00000 rt rd shamt 000000
    // rt=$7, rd=$7, shamt=10
    // = (0<<21)|(7<<16)|(7<<11)|(10<<6)|0
    // = 0x00070000|0x00003800|0x00000280
    // = 0x00073A80
    ins_addr = 8'd20; ins = 32'h00073A80; #10;

    // sllv $3, $7, $5        → $3 = $7 << x
    // sllv rd,rt,rs: 000000 rs rt rd 00000 000100
    // rs=$5, rt=$7, rd=$3
    // = (5<<21)|(7<<16)|(3<<11)|4
    // = 0x00A71804
    ins_addr = 8'd21; ins = 32'h00A71804; #10;

    // srl $8, $4, 10         → $8 = d >> 10
    // srl rd,rt,shamt: 000000 00000 rt rd shamt 000010
    // rt=$4, rd=$8, shamt=10
    // = (0<<21)|(4<<16)|(8<<11)|(10<<6)|2
    // = 0x00040000|0x00004000|0x00000280|2
    // = 0x00044282
    ins_addr = 8'd22; ins = 32'h00044282; #10;

    // srl $9, $5, 2          → $9 = x >> 2
    // rt=$5, rd=$9, shamt=2
    // = (0<<21)|(5<<16)|(9<<11)|(2<<6)|2
    // = 0x00050000|0x00004800|0x00000080|2
    // = 0x00054882
    ins_addr = 8'd23; ins = 32'h00054882; #10;

    // or $8, $8, $9          → $8 = (d>>10)|(x>>2)
    // or rd,rs,rt: 000000 rs rt rd 00000 100101
    // rs=$8, rt=$9, rd=$8
    // = (8<<21)|(9<<16)|(8<<11)|0x25
    // = 0x01094025
    ins_addr = 8'd24; ins = 32'h01094025; #10;

    // xor $3, $3, $8         → c = result → $3
    // xor rd,rs,rt: 000000 rs rt rd 00000 100110
    // rs=$3, rt=$8, rd=$3
    // = (3<<21)|(8<<16)|(3<<11)|0x26
    // = 0x00681826
    ins_addr = 8'd25; ins = 32'h00681826; #10;

    // print c
    // syscall $6, $3
    ins_addr = 8'd26; ins = 32'h00C3000C; #10;

    // exit
    // addi $6, $0, 1001
    ins_addr = 8'd27; ins = 32'h200603E9; #10;
    // syscall $6, $0
    ins_addr = 8'd28; ins = 32'h00C0000C; #10;

    done_storing = 1;

    wait(done);

    $display("Output register1 (c=a+b)   = %d", $signed(out_reg1));
    $display("Output register2 (d=a-b)   = %d", $signed(out_reg2));
    $display("Output register3 (d final) = %d", $signed(out_reg3));
    $display("Output register4 (c final) = %d", $signed(out_reg4));
    $display("Total cycles               = %d", total_cycles);
    $display("Processor cycles           = %d", proc_cycles);

    if ($signed(out_reg1) == -55    &&
        $signed(out_reg2) == 25     &&
        $signed(out_reg3) == 16429  &&
        $signed(out_reg4) == -32751)
        $display("TEST PASSED");
    else
        $display("TEST FAILED");

    $finish;
end
endmodule