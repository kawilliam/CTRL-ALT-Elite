/*
 * Module: decode
 *
 * Description: Decode stage
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) insn_iruction ins_i
 * 4) program counter pc_i
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide insn_iruction output insn_o
 * 3) 5-bit wide destination register ID rd_o
 * 4) 5-bit wide source 1 register ID rs1_o
 * 5) 5-bit wide source 2 register ID rs2_o
 * 6) 7-bit wide funct7 funct7_o
 * 7) 3-bit wide funct3 funct3_o
 * 8) 32-bit wide immediate imm_o
 * 9) 5-bit wide shift amount shamt_o
 * 10) 7-bit width opcode_o
 */

`include "constants.svh"

module decode #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
)(
	// inputs
	input logic clk,
	input logic rst,
	input logic [DWIDTH - 1:0] insn_i,
	input logic [AWIDTH - 1:0] pc_i,

  // outputs
  output logic [AWIDTH-1:0] pc_o,
  output logic [DWIDTH-1:0] insn_o,
  output logic [6:0] opcode_o,
  output logic [4:0] rd_o,
  output logic [4:0] rs1_o,
  output logic [4:0] rs2_o,
  output logic [6:0] funct7_o,
  output logic [2:0] funct3_o,
  output logic [4:0] shamt_o,
  output logic [DWIDTH-1:0] imm_o
);
    always_comb begin
        pc_o = pc_i;
        insn_o = insn_i;
        opcode_o = `OPCODE;
        funct3_o = `FUNCT3;
        // Destination register rd for R-type, I-type, U-type,
        // and J-type instructions.
        rd_o = (`OPCODE != `S_TYPE && `OPCODE != `B_TYPE) ? insn_i[11:7] : 5'd0;
        // Logic hole 2 (LH2): Determine the assignment of source register operands
        //               rs1_o and rs2_o.
        // Source register rs1 for R-type, I-type, S-type, B-type instructions.
        rs1_o = /* LH2???? */
        // Source registter rs2 for R-type, S-type, B-type instructions.
        rs2_o = /* LH2???? */

        // FUNCT7 for R-type and I-type shift (slli, srli, srai) instructions.
        funct7_o = `FUNCT7;
    end

endmodule : decode
