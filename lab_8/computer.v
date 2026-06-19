`include "defs.vh"
module Computer(input reset, input [7:0] ins_addr, input
[31:0] ins, input clk, input done_storing,input done_copying_io_regs, output reg done,
output [31:0] out_reg1, output [31:0] out_reg2, output
[31:0] out_reg3, output [31:0] out_reg4, output [31:0]
total_cycles, output [31:0] proc_cycles , output io_stall , output [2:0] io_reg_index);
wire [7:0] pc;
 // Output of Processor
wire [31:0] ins_fetched;
 // Output of Memory
wire ins_mem_command; // Input to Memory
reg [31:0] counter_total; // Counts total_cycles
reg [31:0] counter_proc; // Counts proc_cycles
wire halt;
 // Output of Processor
 Memory mem(~reset & ~done_storing, clk,
ins_mem_command, done_storing ? pc : ins_addr, ins,
ins_fetched);
Processor proc(clk, halt, ~done_storing, pc,
ins_fetched, out_reg1, out_reg2, out_reg3, out_reg4,done_copying_io_regs,io_reg_index,io_stall);
assign total_cycles = counter_total;
assign proc_cycles = counter_proc;
assign ins_mem_command = done_storing ?
`READ_COMMAND : `WRITE_COMMAND;
always @(posedge clk) begin
if (reset) begin
counter_total <= 32'b0;
counter_proc <= 32'b0;
done <= 1'b0;
end
else begin
done <= halt ; 
counter_total <= ~halt ? counter_total + 32'd1 : counter_total;
counter_proc <= (done_storing & ~halt) ? counter_proc + 32'd1 : counter_proc;
end
end
endmodule