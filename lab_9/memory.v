`include "defs.vh"
module Memory(input write_enable, input clk, input [1:0]
command, input [7:0] address, input [31:0] word_in, output
[31:0] word_out);
reg [31:0] Mem [0:255];
assign word_out = ((command == `READ_COMMAND) ||
                   (command == `SUB_WORD_COMMAND)) ? Mem[address]
: 32'd0;
always @ (posedge clk) begin
if (((command == `WRITE_COMMAND) ||
     (command == `SUB_WORD_COMMAND)) &&
(write_enable == 1'b1)) begin
    Mem[address]<=word_in;
end
end
endmodule
