`ifndef CPU_DEFS_VH
`define CPU_DEFS_VH

// widths
`define XLEN        16
`define REG_ADDR_W  3

// opcodes (instr[15:12])
`define OP_RTYPE 4'b0000
`define OP_ADDI  4'b0001
`define OP_LW    4'b0010
`define OP_SW    4'b0011
`define OP_BEQ   4'b0100
`define OP_BNE   4'b0101
`define OP_J     4'b0110
`define OP_JAL   4'b0111

// R-type funct (instr[2:0])
`define FUN_ADD 3'b000
`define FUN_SUB 3'b001
`define FUN_AND 3'b010
`define FUN_OR  3'b011
`define FUN_MUL 3'b100
`define FUN_DIV 3'b101
`define FUN_JR  3'b110
`define FUN_NOP 3'b111

// ALU control (4-bit)
`define ALU_ADD  4'h0
`define ALU_SUB  4'h1
`define ALU_AND  4'h2
`define ALU_OR   4'h3
`define ALU_MUL  4'h4
`define ALU_DIV  4'h5
`define ALU_SLT  4'h6
`define ALU_PASS 4'hF

// >>> NEW: clean NOP/HALT encodings
`define INSTR_NOP  16'h0007   // OP_RTYPE + FUN_NOP
`define INSTR_HALT 16'hFFFF

`endif
