`define OP_REG 6'h0 // done
`define OP_ADDI 6'h8 // done
`define OP_ANDI 6'hc // done
`define OP_ORI 6'hd // done
`define OP_XORI 6'he // done
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
`define READ_COMMAND 1'b0 // Memory read command
`define WRITE_COMMAND 1'b1 // Memory write command
`define SYS_exit 32'd1001
 // Syscall number for exit
`define SYS_write 32'd1004
 // Syscall number for print
 