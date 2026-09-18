/*
 * Good practice to define constants and refer to them in the
 * design files. An example of some constants are provided to you
 * as a starting point
 *
 */
`ifndef CONSTANTS_SVH_
`define CONSTANTS_SVH_

parameter logic [31:0] ZERO = 32'd0;

/*
 * Define constants as required...
 */

// NOP
`define NOP 32'h00000013

// Control pipeline bus
`define PCSEL 0
`define IMMSEL 1
`define REGWREN 2
`define RS1SEL 3
`define RS2SEL 4
`define MEMREN 5
`define MEMWREN 6
`define WBSEL 8:7
`define ALUSEL 12:9

`define D_X ctrl_reg[0]
`define X_M ctrl_reg[1]
`define M_W ctrl_reg[2]

 // Opcode constants
`define R_TYPE       7'b0110011
`define I_TYPE       7'b0010011
`define I_TYPE_L     7'b0000011
`define I_TYPE_JALR  7'b1100111
`define S_TYPE       7'b0100011
`define B_TYPE       7'b1100011
`define J_TYPE       7'b1101111
`define U_TYPE_LUI   7'b0110111
`define U_TYPE_AUIPC 7'b0010111

// Reuseable instruction constants
`define OPCODE insn_i[6:0]
`define FUNCT7 insn_i[31:25]
`define FUNCT3 insn_i[14:12]

// funct3 constants for R-type and I-type instructions
`define F3_ADD 3'h0
`define F3_XOR 3'h4
`define F3_OR  3'h6
`define F3_AND 3'h7
`define F3_SLEFT 3'h1
`define F3_SRIGHT 3'h5
`define F3_SLT 3'h2
`define F3_SLTU 3'h3

 // funct3 constants for I-type Load instructions
 `define F3_LB 3'h0
 `define F3_LH 3'h1
 `define F3_LW 3'h2
 `define F3_LBU 3'h4
 `define F3_LHU 3'h5

 // funct3 constants for S-type instructions
 `define F3_SB 3'h0
 `define F3_SH 3'h1
 `define F3_SW 3'h2

 // funct3 constants for B-type instructions
 `define F3_BEQ 3'h0
 `define F3_BNE 3'h1
 `define F3_BLT 3'h4
 `define F3_BGE 3'h5
 `define F3_BLTU 3'h6
 `define F3_BGEU 3'h7

 // funct7 constants for J-type and I-type instructions
 `define F7_ADD 7'h00
 `define F7_SUB 7'h20
 `define F7_SLL 7'h00
 `define F7_SRL 7'h00
 `define F7_SRA 7'h20

// constants for immediate field bit extraction
`define ITYPE_IMM insn_i[31:20]
`define STYPE_IMM {insn_i[31:25], insn_i[11:7]}
`define BTYPE_IMM {insn_i[31], insn_i[7], insn_i[30:25], insn_i[11:8]}
`define UTYPE_IMM {insn_i[31:12], 12'b0}
`define JTYPE_IMM {insn_i[31], insn_i[19:12], insn_i[20], insn_i[30:21]}
`define SHAMT_IMM insn_i[24:20]

// ALU ops constants
`define ALU_ADD 4'b0000
`define ALU_SUB 4'b0001
`define ALU_AND 4'b0010
`define ALU_OR  4'b0011
`define ALU_XOR 4'b0100
`define ALU_SLL 4'b0101
`define ALU_SRL 4'b0110
`define ALU_SRA 4'b0111
`define ALU_SLT 4'b1000
`define ALU_SLTU 4'b1001
`define ALU_NOP 4'b1111

// Write Back Constants
`define WB_ALU 2'b00
`define WB_MEM 2'b01
`define WB_PC4 2'b10
`define WB_IMM 2'b11

`endif
