/*
 * Module: igen
 *
 * Description: Immediate value generator
 */
/*
 * Module: igen
 *
 * Description: Immediate value generator
 *
 * Inputs:
 * 1) opcode opcode_i
 * 2) input instruction insn_i
 * Outputs:
 * 2) 32-bit immediate value imm_o
 */
`include "constants.svh"
module igen #(
    parameter int DWIDTH=32
    )(
    input logic [6:0] opcode_i,
    input logic [DWIDTH-1:0] insn_i,
    output logic [DWIDTH-1:0] imm_o
);

  // Logic hole 3: Complete the immediate value generator
  always_comb begin
    case (opcode_i)
      `I_TYPE_L: begin
        imm_o = {{20{insn_i[31]}}, `ITYPE_IMM};
      end
      `I_TYPE_JALR: begin
        imm_o = {{20{insn_i[31]}}, `ITYPE_IMM};
      end
      // For slli/srli/srai the low 5 bits of this are already the shamt field.
      `I_TYPE: begin
        imm_o = {{20{insn_i[31]}}, `ITYPE_IMM};
      end
      `S_TYPE: begin
        imm_o = {{20{insn_i[31]}}, `STYPE_IMM};
      end
      // B/J immediates encode a 2-byte-aligned offset, so bit 0 is an implicit 0.
      `B_TYPE: begin
        imm_o = {{19{insn_i[31]}}, `BTYPE_IMM, 1'b0};
      end
      // U-type already sits in the upper 20 bits; no sign extension needed.
      `U_TYPE_LUI, `U_TYPE_AUIPC: begin
        imm_o = `UTYPE_IMM;
      end
      `J_TYPE: begin
        imm_o = {{11{insn_i[31]}}, `JTYPE_IMM, 1'b0};
      end
      default: begin
        imm_o = '0;
      end
    endcase
  end

endmodule : igen
