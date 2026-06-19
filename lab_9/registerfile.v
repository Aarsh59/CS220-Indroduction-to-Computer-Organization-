module RegisterFile (input [4:0] read_addr1, input [4:0]
read_addr2, output [31:0] read_data1, output [31:0]
read_data2, input [4:0] write_addr, input [31:0] write_data,
input write_enable, input clk);
reg [31:0] regfile [0:31];
integer i;
initial begin
  regfile[0] = 0;
end


assign read_data1 = regfile[read_addr1];
assign read_data2 = regfile[read_addr2];
always @ (negedge clk) begin
if (write_enable && (write_addr != 0)) begin
    regfile[write_addr]<=write_data;
end
end
endmodule