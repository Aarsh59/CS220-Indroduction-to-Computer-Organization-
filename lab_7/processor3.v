`include "defs.vh"
module Processor(input clk, output halt, input reset, output reg [7:0]
pc, input [31:0] ins, output [31:0] io_reg1, output [31:0] io_reg2,
output [31:0] io_reg3, output [31:0] io_reg4);

// ──────────────────────────────────────────────
// FSM states
// ──────────────────────────────────────────────
localparam S0 = 2'd0;  // Fetch + Decode + RF Read
localparam S1 = 2'd1;  // ALU + Syscall
localparam S2 = 2'd2;  // Write Back

reg [1:0] state;

// ──────────────────────────────────────────────
// S0 pipeline registers (loaded at end of S0)
// ──────────────────────────────────────────────
reg [5:0]  s1_opcode;
reg [5:0]  s1_func;
reg [4:0]  s1_shift_amount;
reg [4:0]  s1_dest_addr;
reg [31:0] s1_src1;       // RF read result
reg [31:0] s1_src2;       // RF read result
reg [31:0] s1_alu_src2;   // src2 or sign-extended imm

// ──────────────────────────────────────────────
// S1 pipeline registers (loaded at end of S1)
// ──────────────────────────────────────────────
reg [4:0]  wb_dest_addr;
reg [31:0] wb_dest_data;
reg        wb_dest_valid;
reg [5:0]  wb_opcode;
reg [5:0]  wb_func;
reg [31:0] wb_src1;       // syscall number
reg [31:0] wb_src2;       // syscall write arg

// ──────────────────────────────────────────────
// S0 combinatorial decode (live from ins)
// ──────────────────────────────────────────────
wire [5:0]  opcode       = ins[31:26];
wire [4:0]  src1_addr    = ins[25:21];
wire [4:0]  src2_addr    = ins[20:16];
wire [4:0]  dest_addr    = (opcode == `OP_REG) ? ins[15:11] : ins[20:16];
wire [4:0]  shift_amount = ins[10:6];
wire [5:0]  func         = ins[5:0];
wire [15:0] imm          = ins[15:0];

// ──────────────────────────────────────────────
// RF: read in S0, write in S2
// ──────────────────────────────────────────────
wire [31:0] src1, src2;
wire rf_write_en = (state == S2) && wb_dest_valid;

RegisterFile rf (
    src1_addr, src2_addr, src1, src2,
    wb_dest_addr, wb_dest_data, rf_write_en, clk
);

// ──────────────────────────────────────────────
// ALU: runs in S1 using s1_* pipeline registers
// ──────────────────────────────────────────────
wire [31:0] ex_result;
wire        ex_valid;
ALU alu (s1_src1, s1_alu_src2, s1_shift_amount, s1_opcode, s1_func, ex_result, ex_valid);

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
// halt: asserted in S2 when exit syscall reaches WB
// ──────────────────────────────────────────────
assign halt = (state == S2) &&
              (wb_opcode == `OP_REG) &&
              (wb_func   == `FUNC_SYSCALL) &&
              (wb_src1   == `SYS_exit);

// ──────────────────────────────────────────────
// FSM
// ──────────────────────────────────────────────
always @(posedge clk) begin
    if (reset) begin
        state          <= S0;
        pc             <= 8'b0;
        io_reg_index   <= 2'b0;
        // clear S0→S1 regs
        s1_opcode      <= 6'b0;
        s1_func        <= 6'b0;
        s1_shift_amount<= 5'b0;
        s1_dest_addr   <= 5'b0;
        s1_src1        <= 32'b0;
        s1_src2        <= 32'b0;
        s1_alu_src2    <= 32'b0;
        // clear S1→S2 regs
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

            S0: begin
                // RF read is combinatorial (src1, src2 valid this cycle)
                // Latch decoded fields + RF values into S1 pipeline regs
                s1_opcode       <= opcode;
                s1_func         <= func;
                s1_shift_amount <= shift_amount;
                s1_dest_addr    <= dest_addr;
                s1_src1         <= src1;
                s1_src2         <= src2;
                s1_alu_src2     <= (opcode == `OP_REG) ? src2 : {{16{imm[15]}}, imm};
                state           <= S1;
            end

            S1: begin
                // ALU result is combinatorial from s1_* regs
                // Latch into WB pipeline regs
                wb_dest_addr  <= s1_dest_addr;
                wb_dest_data  <= ex_result;
                wb_dest_valid <= ex_valid;
                wb_opcode     <= s1_opcode;
                wb_func       <= s1_func;
                wb_src1       <= s1_src1;   // syscall number
                wb_src2       <= s1_src2;   // syscall write arg
                state         <= S2;
            end

            S2: begin
                // RF write happens via rf_write_en (combinatorial, uses wb_*)
                // Handle syscall write
                if ((wb_opcode == `OP_REG) &&
                    (wb_func   == `FUNC_SYSCALL) &&
                    (wb_src1   == `SYS_write)) begin
                    io_reg[io_reg_index] <= wb_src2;
                    io_reg_index         <= io_reg_index + 1;
                end

                // Advance PC unless halting
                if (!halt)
                    pc <= pc + 1;

                state <= S0;
            end

        endcase
    end
end

endmodule