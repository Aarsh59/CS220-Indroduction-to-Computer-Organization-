`include "defs.vh"
module Computer(input reset, input [7:0] ins_addr, input
[31:0] ins, input clk, input done_storing,input done_copying_io_regs,input [31:0] input_value ,input input_valid, output reg done,
output [31:0] out_reg1, output [31:0] out_reg2, output
[31:0] out_reg3, output [31:0] out_reg4, output [31:0]
total_cycles, output [31:0] proc_cycles , output io_stall , output [2:0] io_reg_index , output waiting_for_input);
wire [7:0] pc;
wire [31:0] mem_word_out;
wire [7:0] data_addr;
wire data_addr_valid;
wire [1:0] data_mem_command;
wire [31:0] store_value;
wire [1:0] mem_command;
wire [7:0] mem_address;
wire [31:0] mem_word_in;
reg [31:0] counter_total; // Counts total_cycles
reg [31:0] counter_proc; // Counts proc_cycles
wire halt;
Memory mem(~reset & (~done_storing | data_addr_valid), clk,
mem_command, mem_address, mem_word_in,
mem_word_out);
Processor proc(clk, halt, ~done_storing, pc,
mem_word_out, input_value , input_valid, mem_word_out, out_reg1, out_reg2, out_reg3, out_reg4,
done_copying_io_regs, io_reg_index, io_stall, waiting_for_input, data_addr, data_addr_valid,
data_mem_command, store_value);
assign total_cycles = counter_total;
assign proc_cycles = counter_proc;
assign mem_command = done_storing ?
                     (data_addr_valid ? data_mem_command : `READ_COMMAND) :
                     `WRITE_COMMAND;
assign mem_address = done_storing ?
                     (data_addr_valid ? data_addr : pc) :
                     ins_addr;
assign mem_word_in = done_storing ? store_value : ins;
always @(posedge clk) begin
if (reset) begin
counter_total <= 32'b0;
counter_proc <= 32'b0;
done <= 1'b0;
end
else begin
done <= halt|done ; 
counter_total <= ~done ? counter_total + 32'd1 : counter_total;
counter_proc <= (done_storing & ~done) ? counter_proc + 32'd1 : counter_proc;
end
end
endmodule
