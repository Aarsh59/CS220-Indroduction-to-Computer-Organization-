`include "defs.vh"
module Processor(input clk, output halt, input reset, output reg [7:0]
pc, input [31:0] ins, output [31:0] io_reg1, output [31:0] io_reg2,
output [31:0] io_reg3, output [31:0] io_reg4);

// ──────────────────────────────────────────────
// FSM states
// ──────────────────────────────────────────────
localparam S_IF_EX = 1'b0;  // Stage 1: fetch + execute
localparam S_WB    = 1'b1;  // Stage 2: write back

reg state;

// ──────────────────────────────────────────────
// Stage 1 (IF/EX) — combinatorial decode from live ins
// ──────────────────────────────────────────────
wire [5:0]  opcode       = ins[31:26];
wire [4:0]  src1_addr    = ins[25:21];
wire [4:0]  src2_addr    = ins[20:16];
wire [4:0]  dest_addr    = (opcode == `OP_REG) ? ins[15:11] : ins[20:16];
wire [4:0]  shift_amount = ins[10:6];
wire [5:0]  func         = ins[5:0];
wire [15:0] imm          = ins[15:0];

wire [31:0] src1, src2;
wire [31:0] alu_src2 = (opcode == `OP_REG) ? src2 : {{16{imm[15]}}, imm};
wire [31:0] ex_result;
wire        ex_valid;

// ──────────────────────────────────────────────
// WB pipeline registers — loaded at end of S_IF_EX
// ──────────────────────────────────────────────
reg [4:0]  wb_dest_addr;
reg [31:0] wb_dest_data;
reg        wb_dest_valid;
reg [5:0]  wb_opcode;
reg [5:0]  wb_func;
reg [31:0] wb_src1;
reg [31:0] wb_src2;

// ──────────────────────────────────────────────
// RF: write only in S_WB state using wb_* regs
// ──────────────────────────────────────────────
wire rf_write_en = (state == S_WB) && wb_dest_valid;
RegisterFile rf (
    src1_addr, src2_addr, src1, src2,
    wb_dest_addr, wb_dest_data, rf_write_en, clk
);

// ──────────────────────────────────────────────
// ALU: runs in S_IF_EX
// ──────────────────────────────────────────────
ALU alu (src1, alu_src2, shift_amount, opcode, func, ex_result, ex_valid);

// ──────────────────────────────────────────────
// I/O regs
// ──────────────────────────────────────────────
reg [31:0] io_reg [0:3];
reg [1:0]  io_reg_index;
assign io_reg1 = io_reg[0];
assign io_reg2 = io_reg[1];
assign io_reg3 = io_reg[2];
assign io_reg4 = io_reg[3];

// ──────────────────────────────────────────────
// halt: asserted in S_WB when exit syscall is in WB stage
// ──────────────────────────────────────────────
assign halt = (state == S_WB) &&
              (wb_opcode == `OP_REG) &&
              (wb_func   == `FUNC_SYSCALL) &&
              (wb_src1   == `SYS_exit);

// ──────────────────────────────────────────────
// FSM + datapath
// ──────────────────────────────────────────────
always @(posedge clk) begin
    if (reset) begin
        state          <= S_IF_EX;
        pc             <= 8'b0;
        io_reg_index   <= 2'b0;
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

            S_IF_EX: begin
                // Latch EX results for WB next cycle
                wb_dest_addr  <= dest_addr;
                wb_dest_data  <= ex_result;
                wb_dest_valid <= ex_valid;
                wb_opcode     <= opcode;
                wb_func       <= func;
                wb_src1       <= src1;
                wb_src2       <= src2;
                state         <= S_WB;
            end

            S_WB: begin
                // RF write happens automatically via rf_write_en
                // Handle syscall write io_reg
                if ((wb_opcode == `OP_REG) &&
                    (wb_func   == `FUNC_SYSCALL) &&
                    (wb_src1   == `SYS_write)) begin
                    io_reg[io_reg_index] <= wb_src2;
                    io_reg_index         <= io_reg_index + 1;
                end

                // Advance PC unless halting
                if (!halt)
                    pc <= pc + 1;

                state <= S_IF_EX;
            end

        endcase
    end
end

endmodule