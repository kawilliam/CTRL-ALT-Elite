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
      /* LH3??? */
      end
      `I_TYPE_JALR: begin
      /* LH3??? */
      end
      `I_TYPE: begin
      /* LH3??? */
      end
      `S_TYPE: begin
      /* LH3??? */
      end
      `B_TYPE: begin
      /* LH3??? */
      end
      `U_TYPE_LUI, `U_TYPE_AUIPC: begin
      /* LH3??? */
      end
      `U_TYPE_AUIPC: begin
      /* LH3??? */
      end
      `J_TYPE: begin
      /* LH3??? */
      end
      /* LH3??? */
    endcase
  end

endmodule : igen
