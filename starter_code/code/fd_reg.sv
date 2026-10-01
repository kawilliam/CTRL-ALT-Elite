/*
 * Module: fd_reg
 *
 * Description: F/D stage pipeline register
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) instruction insn_i
 * 4) program counter pc_i
 * 5) flush signal flush_i
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide instruction insn_o
 */

 `include "constants.svh"

module fd_reg #(
  parameter int DWIDTH=32,
  parameter int AWIDTH=32
)(
    // inputs
    input logic clk,
    input logic rst,
    input logic [DWIDTH-1:0] insn_i,
    input logic [AWIDTH-1:0] pc_i,
    input logic flush_i,
    input logic stall_i,

  // outputs
  output logic [AWIDTH-1:0] pc_o,
  output logic [DWIDTH-1:0] insn_o
);
  always_ff @(posedge clk) begin
    if (rst || flush_i) begin
      pc_o <= '0;
      insn_o <= `NOP;
    end else if (!stall_i) begin
      pc_o <= pc_i;
      insn_o <= insn_i;
    end
  end

endmodule : fd_reg