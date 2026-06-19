`include "defs.vh"
module Processor(input clk, output halt, input reset, output reg [7:0]
pc, input [31:0] ins, output [31:0] io_reg1, output [31:0] io_reg2,
output [31:0] io_reg3, output [31:0] io_reg4);

// ──────────────────────────────────────────────
// Original wires - used in STATE_FETCH
// ──────────────────────────────────────────────
wire [5:0]  opcode;
wire [5:0]  func;
wire [4:0]  shift_amount;
wire [4:0]  src1_addr;
wire [4:0]  src2_addr;
wire [31:0] src1;
wire [31:0] src2;
wire [4:0]  dest_addr;
wire [31:0] dest_data;
wire        dest_data_valid;
wire [7:0]  next_pc;
wire [15:0] imm;
wire [31:0] alu_src2;

reg [31:0] io_reg [0:3];
reg [1:0]  io_reg_index;
reg        fetched;

// state register
localparam STATE_FETCH     = 2'd0;
localparam STATE_EXECUTE   = 2'd1;
localparam STATE_WRITEBACK = 2'd2;
reg [1:0] state;

// ──────────────────────────────────────────────
// S0 → S1 inter-state registers
// latched at end of STATE_FETCH
// ──────────────────────────────────────────────
reg [5:0]  s1_opcode;
reg [5:0]  s1_func;
reg [4:0]  s1_shift_amount;
reg [4:0]  s1_dest_addr;
reg [31:0] s1_src1;
reg [31:0] s1_src2;
reg [31:0] s1_alu_src2;

// ──────────────────────────────────────────────
// S1 → S2 inter-state registers
// latched at end of STATE_EXECUTE
// ──────────────────────────────────────────────
reg [4:0]  wb_dest_addr;
reg [31:0] wb_dest_data;
reg        wb_dest_valid;
reg [5:0]  wb_opcode;
reg [5:0]  wb_func;
reg [31:0] wb_src1;
reg [31:0] wb_src2;

// ──────────────────────────────────────────────
// ALU wires for STATE_EXECUTE
// ──────────────────────────────────────────────
wire [31:0] s1_dest_data;
wire        s1_dest_valid;

assign io_reg1 = io_reg[0];
assign io_reg2 = io_reg[1];
assign io_reg3 = io_reg[2];
assign io_reg4 = io_reg[3];

// ──────────────────────────────────────────────
// RegisterFile - write happens in STATE_WRITEBACK
// using wb_ registers
// ──────────────────────────────────────────────
RegisterFile rf (
    src1_addr, src2_addr, src1, src2,
    wb_dest_addr, wb_dest_data,
    wb_dest_valid & fetched & (state == STATE_WRITEBACK),
    clk
);

// ──────────────────────────────────────────────
// ALU - uses s1_ registers in STATE_EXECUTE
// ──────────────────────────────────────────────
ALU alu (
    s1_src1, s1_alu_src2,
    s1_shift_amount,
    s1_opcode, s1_func,
    s1_dest_data, s1_dest_valid
);

// ──────────────────────────────────────────────
// Decode - used in STATE_FETCH
// ──────────────────────────────────────────────
assign opcode       = ins[31:26];
assign src1_addr    = ins[25:21];
assign src2_addr    = ins[20:16];
assign dest_addr    = (opcode == `OP_REG) ? ins[15:11] : ins[20:16];
assign shift_amount = ins[10:6];
assign func         = ins[5:0];
assign imm          = ins[15:0];
assign alu_src2     = (opcode == `OP_REG) ? src2 :
                      (opcode == `OP_ADDI) ? {{16{imm[15]}}, imm} :
                      {16'b0, imm};

// ──────────────────────────────────────────────
// next_pc - only advance in STATE_WRITEBACK
// ──────────────────────────────────────────────
assign next_pc = (fetched & ~halt) ? pc + 1 : 8'b0;

// ──────────────────────────────────────────────
// halt - detected in STATE_EXECUTE using wb_
// ──────────────────────────────────────────────
assign halt = (reset | ~fetched) ? 1'b0 :
              ((state == STATE_EXECUTE) &&
               (s1_opcode == `OP_REG) &&
               (s1_func   == `FUNC_SYSCALL) &&
               (s1_src1   == `SYS_exit)) ? 1'b1 : 1'b0;

// ──────────────────────────────────────────────
// Main FSM - posedge clk
// ──────────────────────────────────────────────
always @(posedge clk) begin
    if (reset) begin
        pc            <= 8'b0;
        io_reg_index  <= 2'b0;
        fetched       <= 1'b0;
        state         <= STATE_FETCH;
        // clear inter-state registers
        s1_opcode      <= 6'b0;
        s1_func        <= 6'b0;
        s1_shift_amount<= 5'b0;
        s1_dest_addr   <= 5'b0;
        s1_src1        <= 32'b0;
        s1_src2        <= 32'b0;
        s1_alu_src2    <= 32'b0;
        wb_dest_addr   <= 5'b0;
        wb_dest_data   <= 32'b0;
        wb_dest_valid  <= 1'b0;
        wb_opcode      <= 6'b0;
        wb_func        <= 6'b0;
        wb_src1        <= 32'b0;
        wb_src2        <= 32'b0;
    end
    else begin
        case (state)
            STATE_FETCH: begin
                // latch decoded instruction and RF reads
                // into s1_ registers for next cycle
                s1_opcode       <= opcode;
                s1_func         <= func;
                s1_shift_amount <= shift_amount;
                s1_dest_addr    <= dest_addr;
                s1_src1         <= src1;
                s1_src2         <= src2;
                s1_alu_src2     <= alu_src2;
                fetched         <= 1'b1;
                state           <= STATE_EXECUTE;
            end

            STATE_EXECUTE: begin
                // latch ALU results into wb_ registers
                // for writeback next cycle
                // also handle syscall write here
                wb_dest_addr  <= s1_dest_addr;
                wb_dest_data  <= s1_dest_data;
                wb_dest_valid <= s1_dest_valid;
                wb_opcode     <= s1_opcode;
                wb_func       <= s1_func;
                wb_src1       <= s1_src1;
                wb_src2       <= s1_src2;
                // syscall write handled here
                if ((s1_opcode == `OP_REG) &&
                    (s1_func   == `FUNC_SYSCALL) &&
                    (s1_src1   == `SYS_write)) begin
                    io_reg_index          <= io_reg_index + 1;
                    io_reg[io_reg_index]  <= s1_src2;
                end
                state <= STATE_WRITEBACK;
            end

            STATE_WRITEBACK: begin
                // RF write happens via RegisterFile
                // write_enable combinationally
                // advance PC here
                pc    <= next_pc;
                state <= STATE_FETCH;
            end
        endcase
    end
end

endmodule