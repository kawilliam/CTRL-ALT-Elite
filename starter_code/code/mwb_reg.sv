/*
 * Module: mwb_reg
 *
 * Description: M/WB stage pipeline register
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) program counter pc_i
 * 4) alu result alu_res_i
 * 5) Memory data mdata_i
 * 6) registerd address rd_i
 * 7) Memory imm imm_i
 * 8) control register ctrl_reg_i
 * Outputs:
 * 1) program counter pc_o
 * 2) alu result alu_res_o
 * 3) Memory data mdata_o
 * 4) registerd address rd_o
 * 5) Memory imm imm_o
 * 6) control register ctrl_reg_o
 */

 `include "constants.svh"

module mwb_reg #(
parameter int DWIDTH=32,
parameter int AWIDTH=32
)(
   // inputs
      input logic clk,
      input logic rst,
      input logic [AWIDTH-1:0] pc_i,
      input logic [DWIDTH-1:0] alu_res_i,
      input logic [DWIDTH-1:0] mdata_i,
      input logic [4:0] rd_i,
      input logic [DWIDTH-1:0] imm_i,
      input logic [12:0] ctrl_reg_i,

  // outputs
  output logic [AWIDTH-1:0] pc_o,
  output logic [DWIDTH-1:0] alu_res_o,
  output logic [DWIDTH-1:0] mdata_o,
  output logic [4:0] rd_o,
  output logic [DWIDTH-1:0] imm_o,
  output logic [12:0] ctrl_reg_o
);
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      pc_o <= '0;
      alu_res_o <= '0;
      mdata_o <= '0;
      imm_o <= '0;
      rd_o <= '0;
      ctrl_reg_o <= '0;
    end else begin
      pc_o <= pc_i;
      alu_res_o <= alu_res_i;
      mdata_o <= mdata_i;
      imm_o <= imm_i;
      rd_o <= rd_i;
      ctrl_reg_o <= ctrl_reg_i;
    end
  end

endmodule : mwb_reg