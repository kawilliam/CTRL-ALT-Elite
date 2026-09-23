/*
 * Module: control
 *
 * Description: This module sets the control bits (control path) based on the decoded
 * instruction. Note that this is part of the decode stage but housed in a separate
 * module for better readability, debug and design purposes.
 *
 * Inputs:
 * 1) DWIDTH instruction ins_i
 * 2) 7-bit opcode opcode_i
 * 3) 7-bit funct7 funct7_i
 * 4) 3-bit funct3 funct3_i
 *
 * Outputs:
 * 1) 1-bit PC select pcsel_o
 * 2) 1-bit Immediate select immsel_o
 * 3) 1-bit register write en regwren_o
 * 4) 1-bit rs1 select rs1sel_o
 * 5) 1-bit rs2 select rs2sel_o
 * 6) k-bit ALU select alusel_o
 * 7) 1-bit memory read en memren_o
 * 8) 1-bit memory write en memwren_o
 * 9) 2-bit writeback sel wbsel_o
 */

`include "constants.svh"

module control #(
	parameter int DWIDTH=32
)(
	// inputs
    input logic [DWIDTH-1:0] insn_i,
    input logic [6:0] opcode_i,
    input logic [6:0] funct7_i,
    input logic [2:0] funct3_i,

    // outputs
    output logic pcsel_o,
    output logic immsel_o,
    output logic regwren_o,
    output logic rs1sel_o,
    output logic rs2sel_o,
    output logic memren_o,
    output logic memwren_o,
    output logic [1:0] wbsel_o,
    output logic [3:0] alusel_o
);

assign memren_o = (opcode_i == `I_TYPE_L);
assign memwren_o = (opcode_i == `S_TYPE);
assign immsel_o = !(opcode_i == `R_TYPE);

/* Logic hole 4 (LH4): Complete the control path. This is a key logic module
                       that is crucial for correctness. Pay close attention to
                       this logic.
*/

logic is_jump;
assign is_jump = (opcode_i == `J_TYPE) || (opcode_i == `I_TYPE_JALR);

// PCSel: take the ALU result as the next PC. Unconditional for jal/jalr; for
// branches rv_core ORs this with the ALU's brtaken_o.
assign pcsel_o = is_jump;

// RegWrEn: every format writes rd except stores and branches.
assign regwren_o = (opcode_i == `R_TYPE)       || (opcode_i == `I_TYPE)       ||
                   (opcode_i == `I_TYPE_L)     || (opcode_i == `I_TYPE_JALR)  ||
                   (opcode_i == `U_TYPE_LUI)   || (opcode_i == `U_TYPE_AUIPC) ||
                   (opcode_i == `J_TYPE);

// ASel: 1 -> feed PC into ALU port A instead of rs1 data. Only auipc needs it.
// Branch and jal targets are built from the ALU's own pc_i/imm_i ports so that
// port A/B keep carrying rs1/rs2 for the branch comparator.
assign rs1sel_o = (opcode_i == `U_TYPE_AUIPC);

// BSel: 1 -> feed the immediate into ALU port B instead of rs2 data. R-type
// needs rs2 as an operand; B-type needs rs2 for the comparison.
assign rs2sel_o = !((opcode_i == `R_TYPE) || (opcode_i == `B_TYPE));

  always_comb begin
    case (opcode_i)
      `R_TYPE: begin
        wbsel_o = `WB_ALU;
        case (funct3_i)
          `F3_ADD:    alusel_o = (funct7_i == `F7_SUB) ? `ALU_SUB : `ALU_ADD;
          `F3_SLEFT:  alusel_o = `ALU_SLL;
          `F3_SLT:    alusel_o = `ALU_SLT;
          `F3_SLTU:   alusel_o = `ALU_SLTU;
          `F3_XOR:    alusel_o = `ALU_XOR;
          `F3_SRIGHT: alusel_o = (funct7_i == `F7_SRA) ? `ALU_SRA : `ALU_SRL;
          `F3_OR:     alusel_o = `ALU_OR;
          `F3_AND:    alusel_o = `ALU_AND;
          default:    alusel_o = `ALU_NOP;
        endcase
      end
      // Same ALU decode as R-type, except add/sub is always add (no sub-immediate)
      // and the shift variant still comes from funct7.
      `I_TYPE: begin
        wbsel_o = `WB_ALU;
        case (funct3_i)
          `F3_ADD:    alusel_o = `ALU_ADD;
          `F3_SLEFT:  alusel_o = `ALU_SLL;
          `F3_SLT:    alusel_o = `ALU_SLT;
          `F3_SLTU:   alusel_o = `ALU_SLTU;
          `F3_XOR:    alusel_o = `ALU_XOR;
          `F3_SRIGHT: alusel_o = (funct7_i == `F7_SRA) ? `ALU_SRA : `ALU_SRL;
          `F3_OR:     alusel_o = `ALU_OR;
          `F3_AND:    alusel_o = `ALU_AND;
          default:    alusel_o = `ALU_NOP;
        endcase
      end
      // Loads and stores: ALU computes rs1 + imm as the effective address.
      `I_TYPE_L: begin
        wbsel_o = `WB_MEM;
        alusel_o = `ALU_ADD;
      end
      `S_TYPE: begin
        wbsel_o = `WB_ALU;   // don't care, regwren_o is 0
        alusel_o = `ALU_ADD;
      end
      `B_TYPE: begin
        wbsel_o = `WB_ALU;   // don't care, regwren_o is 0
        alusel_o = `ALU_ADD;
      end
      // Link register gets PC+4; the ALU produces the jump target.
      `I_TYPE_JALR, `J_TYPE: begin
        wbsel_o = `WB_PC4;
        alusel_o = `ALU_ADD;
      end
      `U_TYPE_LUI: begin
        wbsel_o = `WB_IMM;
        alusel_o = `ALU_NOP;
      end
      `U_TYPE_AUIPC: begin
        wbsel_o = `WB_ALU;
        alusel_o = `ALU_ADD;
      end
      default: begin
        wbsel_o = `WB_ALU;
        alusel_o = `ALU_NOP;
      end
    endcase
  end

endmodule : control


