
// opcode values
`define OP_REG 6'h0 // done
`define OP_ADDI 6'h8 // done
`define OP_ANDI 6'hc // done
`define OP_ORI 6'hd // done
`define OP_XORI 6'he // done
`define OP_BLTZ 6'h1 // done 
`define OP_BEQ 6'h4 // done
`define OP_BNE 6'h5 // done
`define OP_BLEZ 6'h6 // done
`define OP_BGTZ 6'h7 // done
`define OP_SLTI 6'ha // done
`define OP_SLTIU 6'hb // done
`define OP_J 6'h2 // done
`define OP_JAL 6'h3 // done


// Function values
`define FUNC_SLL 6'h0 //done
`define FUNC_SRL 6'h2 // done 
`define FUNC_SRA 6'h3 //done 
`define FUNC_SLLV 6'h4 // done 
`define FUNC_SRLV 6'h6 //done
`define FUNC_SRAV 6'h7 // done
`define FUNC_SYSCALL 6'hc  //done
`define FUNC_ADD 6'h20 // done
`define FUNC_SUB 6'h22 // done
`define FUNC_AND 6'h24 // done
`define FUNC_OR 6'h25 // done
`define FUNC_XOR 6'h26 // done
`define FUNC_NOR 6'h27 // done
`define FUNC_JR 6'h8 // done
`define FUNC_JALR 6'h9 // done
`define FUNC_SLT 6'h2a // done
`define FUNC_SLTU 6'h2b//done

// Miscallenous
`define READ_COMMAND 1'b0 // Memory read command
`define WRITE_COMMAND 1'b1 // Memory write command
`define SYS_exit 32'd1001
 // Syscall number for exit
`define SYS_write 32'd1004
 // Syscall number for print
 