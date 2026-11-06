/*
 * Module: pre_decode
 *
 * Description: Decode in the IF stage that simplifies the work of the 
 *              main decoder by computing branch/jump targets and
 *              classifies control flow instructions, and also does
 *              call/return classification and calculates the ra
 *
 * Inputs:
 * 1) instruction insn_i
 * 2) program counter pc_i
 * 3) valid instruction signal is_insn_i
 * Outputs:
 * 1) target address target_o
 * 2) return address ra_o
 * 3) control flow instruction type cfit_o
 * 4) valid signal for call is_call_o
 * 5) valid signal for return is_ret_o
 * 6) valid signal for redirect is_redir_o
 */

 `include "constants.svh"

module pre_decode 
   import frontend_pkg::*;
#(
   parameter int DWIDTH=32,
   parameter int AWIDTH=32
   )(
   // inputs
   input logic [DWIDTH-1:0] insn_i,
   input logic [AWIDTH-1:0] pc_i,
   input logic is_insn_i,

   // outputs
   output logic [AWIDTH-1:0] target_o,
   output logic [AWIDTH-1:0] ra_o,
   output cfi_t cfit_o, 
   output logic is_call_o,
   output logic is_ret_o,
   output logic is_redir_o
);
      always_comb begin
         target_o = 32'd0;
         ra_o = 32'd0;
         cfit_o = CFI_NONE;
         is_call_o = 1'd0;
         is_ret_o = 1'd0;
         is_redir_o = 1'd0;
         if (is_insn_i) begin
            ra_o = pc_i + 32'd4;
            case (`OPCODE)
               `I_TYPE_JALR: begin
                  cfit_o = CFI_JALR;
                  is_call_o = (insn_i[11:7] inside {5'd1, 5'd5}) ? 1'd1 : 1'd0;
                  is_ret_o = (insn_i[11:7] == 5'd0 && insn_i[19:15] inside {5'd1, 5'd5}) ? 1'd1 : 1'd0;
               end
               `J_TYPE: begin
                  target_o = pc_i + {{11{insn_i[31]}},`JTYPE_IMM,1'd0};
                  cfit_o = CFI_JAL;
                  is_call_o = (insn_i[11:7] inside {5'd1, 5'd5}) ? 1'd1 : 1'd0;
                  is_redir_o = 1'd1;
               end
               `B_TYPE: begin
                  target_o = pc_i + {{19{insn_i[31]}},`BTYPE_IMM, 1'd0};
                  cfit_o = CFI_BRANCH;
               end
               default: ;
            endcase
         end
      end

endmodule : pre_decode
