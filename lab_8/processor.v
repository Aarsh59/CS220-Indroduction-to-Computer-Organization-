`include "defs.vh"
module Processor(input clk, output halt, input reset, output reg [7:0]
pc, input [31:0] ins, output [31:0] io_reg1, output [31:0] io_reg2,
output [31:0] io_reg3, output [31:0] io_reg4,input copied_io_regs , output reg [2:0]io_reg_index , output reg io_stall);

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
wire [7:0]  next_pc;
wire [15:0] imm;
wire [31:0] alu_src2;
wire [25:0] jump_target;
wire [31:0] branch_offset;
wire [31:0] branch_target;
wire        branch_taken;

reg [31:0] io_reg [0:3];
reg        fetched;

// state register
localparam STATE_FETCH     = 2'd0;
localparam STATE_EXECUTE   = 2'd1;
localparam STATE_WRITEBACK = 2'd2;
reg [1:0] state;

// ──────────────────────────────────────────────
// S0 → S1 inter-state registers
// ──────────────────────────────────────────────
reg [5:0]  s1_opcode;
reg [5:0]  s1_func;
reg [4:0]  s1_shift_amount;
reg [4:0]  s1_dest_addr;
reg [31:0] s1_src1;
reg [31:0] s1_src2;
reg [31:0] s1_alu_src2;
reg [7:0]  s1_pc;
reg [31:0] s1_branch_offset;
reg [4:0]  s1_rt;

// ──────────────────────────────────────────────
// S1 → S2 inter-state registers
// ──────────────────────────────────────────────
reg [4:0]  wb_dest_addr;
reg [31:0] wb_dest_data;
reg        wb_dest_valid;
reg [5:0]  wb_opcode;
reg [5:0]  wb_func;
reg [31:0] wb_src1;
reg [31:0] wb_src2;
reg        wb_branch_taken;   // ← new
reg [7:0]  wb_branch_target;  // ← new

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
// RegisterFile
// ──────────────────────────────────────────────
RegisterFile rf (
    src1_addr, src2_addr, src1, src2,
    wb_dest_addr, wb_dest_data,
    wb_dest_valid & fetched & (state == STATE_WRITEBACK),
    clk
);

// ──────────────────────────────────────────────
// ALU
// ──────────────────────────────────────────────
ALU alu (
    s1_src1, s1_alu_src2,
    s1_shift_amount,
    s1_opcode, s1_func,
    s1_pc,
    s1_branch_offset,
    s1_rt,
    s1_dest_data, s1_dest_valid,
    branch_target, branch_taken
);

// ──────────────────────────────────────────────
// Decode
// ──────────────────────────────────────────────
assign opcode        = ins[31:26];
assign src1_addr     = ins[25:21];
assign src2_addr     = ins[20:16];
assign dest_addr     = (opcode == `OP_REG) ? ins[15:11] : ins[20:16];
assign shift_amount  = ins[10:6];
assign func          = ins[5:0];
assign imm           = ins[15:0];
assign jump_target   = ins[25:0];
assign branch_offset = (opcode == `OP_J || opcode == `OP_JAL) ?
                       {6'b0, jump_target} :
                       {{16{imm[15]}}, imm};
assign alu_src2 = (opcode == `OP_REG)    ? src2 :
                  (opcode == `OP_ADDI)   ? {{16{imm[15]}}, imm} :
                  (opcode == `OP_SLTI)   ? {{16{imm[15]}}, imm} :
                  (opcode == `OP_SLTIU)  ? {{16{imm[15]}}, imm} :
                  // branch instructions need regfile[rt] as src2
                  (opcode == `OP_BEQ)    ? src2 :
                  (opcode == `OP_BNE)    ? src2 :
                  {16'b0, imm};          // andi, ori, xori

// ──────────────────────────────────────────────
// actual_branch_target - processor overrides for jal/jalr
// ──────────────────────────────────────────────
wire [7:0] actual_branch_target;
assign actual_branch_target =
    (s1_opcode == `OP_JAL)                          ? s1_branch_offset[7:0] :
    (s1_opcode == `OP_REG && s1_func == `FUNC_JALR) ? s1_src1[7:0] :
    branch_target[7:0];

// ──────────────────────────────────────────────
// next_pc - now uses wb_ latched values
// ──────────────────────────────────────────────
assign next_pc = (fetched & ~halt) ?
                 (wb_branch_taken ? wb_branch_target : pc + 1) :
                 8'b0;

// ──────────────────────────────────────────────
// halt
// ──────────────────────────────────────────────
assign halt = (reset | ~fetched) ? 1'b0 :
              ((state == STATE_EXECUTE) &&
               (s1_opcode == `OP_REG) &&
               (s1_func   == `FUNC_SYSCALL) &&
               (s1_src1   == `SYS_exit)) ? 1'b1 : 1'b0;

// ──────────────────────────────────────────────
// Main FSM
// ──────────────────────────────────────────────
always @(posedge clk) begin
    if (reset) begin
        pc               <= 8'b0;
        io_reg_index     <= 3'b0;
        fetched          <= 1'b0;
        state            <= STATE_FETCH;
        s1_opcode        <= 6'b0;
        s1_func          <= 6'b0;
        s1_shift_amount  <= 5'b0;
        s1_dest_addr     <= 5'b0;
        s1_src1          <= 32'b0;
        s1_src2          <= 32'b0;
        s1_alu_src2      <= 32'b0;
        s1_pc            <= 8'b0;
        s1_branch_offset <= 32'b0;
        s1_rt            <= 5'b0;
        wb_dest_addr     <= 5'b0;
        wb_dest_data     <= 32'b0;
        wb_dest_valid    <= 1'b0;
        wb_opcode        <= 6'b0;
        wb_func          <= 6'b0;
        wb_src1          <= 32'b0;
        wb_src2          <= 32'b0;
        wb_branch_taken  <= 1'b0;   // ← new
        wb_branch_target <= 8'b0;   // ← new
        io_stall         <= 1'b0;
    end
    else if (io_stall == 1'b1) begin
        if (copied_io_regs == 1'b1) begin
            io_stall     <= 1'b0;
            io_reg_index <= 3'b0;
        end
    end
    else if (copied_io_regs == 1'b0 && ~halt) begin
        case (state)
            STATE_FETCH: begin
                s1_opcode        <= opcode;
                s1_func          <= func;
                s1_shift_amount  <= shift_amount;
                s1_dest_addr     <= dest_addr;
                s1_src1          <= src1;
                s1_src2          <= src2;
                s1_alu_src2      <= alu_src2;
                s1_pc            <= pc;
                s1_branch_offset <= branch_offset;
                s1_rt            <= src2_addr;
                fetched          <= 1'b1;
                state            <= STATE_EXECUTE;
            end

            STATE_EXECUTE: begin
                wb_dest_addr  <= ((s1_opcode == `OP_JAL) ||
                                  (s1_opcode == `OP_REG && s1_func == `FUNC_JALR)) ?
                                  5'd31 : s1_dest_addr;
                wb_dest_data  <= s1_dest_data;
                wb_dest_valid <= s1_dest_valid;
                wb_opcode     <= s1_opcode;
                wb_func       <= s1_func;
                wb_src1       <= s1_src1;
                wb_src2       <= s1_src2;
                wb_branch_taken  <= branch_taken;        // ← new
                wb_branch_target <= actual_branch_target; // ← new

                if ((s1_opcode == `OP_REG) &&
                    (s1_func   == `FUNC_SYSCALL) &&
                    (s1_src1   == `SYS_write)) begin
                    if (io_reg_index == 3'd4) begin
                        io_stall <= 1'b1;
                        io_reg_index<=3'b0;
                    end
                    else begin
                        io_reg_index         <= io_reg_index + 1;
                        io_reg[io_reg_index] <= s1_src2;
                        state <= STATE_WRITEBACK;
                    end
                end
                else begin
                    state <= STATE_WRITEBACK;
                end
            end

            STATE_WRITEBACK: begin
                pc    <= next_pc;
                state <= STATE_FETCH;
            end
        endcase
    end
end

endmodule
