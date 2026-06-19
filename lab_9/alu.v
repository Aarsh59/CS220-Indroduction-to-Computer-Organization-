`include "defs.vh"
module ALU (input [31:0] src1, input [31:0] src2, input [4:0]
shift_amount, input [5:0] opcode, input [5:0] func , input [7:0] pc,input [31:0] branch_offset , input [4:0] rt , output [31:0] dest,
output dest_valid , output [31:0] branch_target , output branch_taken);
reg [31:0] result;
reg result_valid;
reg [31:0] branch_target_reg;
reg branch_taken_reg;
assign branch_target = branch_target_reg;
assign branch_taken = branch_taken_reg;
assign dest = result;
assign dest_valid = result_valid;
always @(*) begin
    result            = 32'b0;
    result_valid      = 1'b0;
    branch_target_reg = 32'b0;
    branch_taken_reg  = 1'b0;
    case (opcode)
        `OP_REG: begin
            case (func)
                `FUNC_SLL: begin
                    result = src2 << shift_amount;
                    result_valid = 1'b1;
                end
                `FUNC_SRL: begin
                    result = src2 >> shift_amount;
                    result_valid = 1'b1;
                end
                `FUNC_SRA: begin
                    result = $signed(src2) >>> shift_amount;
                    result_valid = 1'b1;
                end
                `FUNC_SLLV: begin
                    result = src2 << src1[4:0];
                    result_valid = 1'b1;
                end
                `FUNC_SRLV: begin
                    result = src2 >> src1[4:0];
                    result_valid = 1'b1;
                end
                `FUNC_SRAV: begin
                    result = $signed(src2) >>> src1[4:0];
                    result_valid = 1'b1;
                end
                `FUNC_ADD: begin
                    result = src1 + src2;
                    result_valid = 1'b1;
                end
                `FUNC_SUB: begin
                    result = src1 - src2;
                    result_valid = 1'b1;
                end
                `FUNC_AND: begin
                    result = src1 & src2;
                    result_valid = 1'b1;
                end
                `FUNC_OR: begin
                    result = src1 | src2;
                    result_valid = 1'b1;
                end
                `FUNC_XOR: begin
                    result = src1 ^ src2;
                    result_valid = 1'b1;
                end
                `FUNC_NOR: begin
                    result = ~(src1 | src2);
                    result_valid = 1'b1;
                end
                `FUNC_SYSCALL: begin
                    result_valid = 1'b0;
                end
                `FUNC_JR: begin
                    branch_target_reg = src1;
                    branch_taken_reg  = 1'b1;
                    result_valid      = 1'b0;
                end
                `FUNC_JALR: begin
                    branch_target_reg = 32'b0;
                    branch_taken_reg  = 1'b1;
                    result            = pc + 1;
                    result_valid      = 1'b1;
                end
                `FUNC_SLT: begin
                    result       = ($signed(src1) < $signed(src2)) ? 32'd1 : 32'd0;
                    result_valid = 1'b1;
                end
                `FUNC_SLTU: begin
                    result       = (src1 < src2) ? 32'd1 : 32'd0;
                    result_valid = 1'b1;
                end
            endcase
        end
        `OP_ADDI: begin
            result       = src1 + src2;
            result_valid = 1'b1;
        end
        `OP_ANDI: begin
            result       = src1 & src2;
            result_valid = 1'b1;
        end
        `OP_ORI: begin
            result       = src1 | src2;
            result_valid = 1'b1;
        end
        `OP_XORI: begin
            result       = src1 ^ src2;
            result_valid = 1'b1;
        end
        `OP_SLTI: begin
            result       = ($signed(src1) < $signed(src2)) ? 32'd1 : 32'd0;
            result_valid = 1'b1;
        end
        `OP_SLTIU: begin
            result       = (src1 < src2) ? 32'd1 : 32'd0;
            result_valid = 1'b1;
        end
        `OP_LW,
        `OP_LB,
        `OP_LBU,
        `OP_LH,
        `OP_LHU: begin
            result       = src1 + branch_offset;
            result_valid = 1'b1;
        end
        `OP_SW,
        `OP_SB,
        `OP_SH: begin
            result       = src1 + branch_offset;
            result_valid = 1'b0;
        end
        
        `OP_BLTZ: begin
            branch_target_reg = pc+1 + branch_offset;
            result_valid      = 1'b0;
            if (rt == 5'd0) begin
                // bltz
                branch_taken_reg = ($signed(src1) < $signed(32'b0)) ? 1'b1 : 1'b0;
            end
            else if (rt == 5'd1) begin
                // bgez
                branch_taken_reg = ($signed(src1) >= $signed(32'b0)) ? 1'b1 : 1'b0;
            end
        end
        `OP_BEQ: begin
            branch_target_reg = pc+1 + branch_offset;
            branch_taken_reg  = (src1 == src2) ? 1'b1 : 1'b0;
            result_valid      = 1'b0;
        end
        `OP_BNE: begin
            branch_target_reg = pc+1 + branch_offset;
            branch_taken_reg  = (src1 != src2) ? 1'b1 : 1'b0;
            result_valid      = 1'b0;
        end
        `OP_BLEZ: begin
            branch_target_reg = pc+1 + branch_offset;
            branch_taken_reg  = ($signed(src1) <= $signed(32'b0)) ? 1'b1 : 1'b0;
            result_valid      = 1'b0;
        end
        `OP_BGTZ: begin
            branch_target_reg = pc+1 + branch_offset;
            branch_taken_reg  = ($signed(src1) > $signed(32'b0)) ? 1'b1 : 1'b0;
            result_valid      = 1'b0;
        end
        `OP_J: begin
            branch_target_reg = branch_offset;
            branch_taken_reg  = 1'b1;
            result_valid      = 1'b0;
        end
        `OP_JAL: begin
            branch_target_reg = 32'b0;
            branch_taken_reg  = 1'b1;
            result            = pc + 1;
            result_valid      = 1'b1;
        end
        `OP_LUI: begin
            result       = src2 << 16;
            result_valid = 1'b1;
        end
        
    endcase
end
endmodule