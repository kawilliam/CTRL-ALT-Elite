/*
 * Module: xm_reg
 *
 * Description: X/M stage pipeline register
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) program counter pc_i
 * 4) register2 data rs2data_i
 * 5) function3 funct3_i
 * 6) registerd address rd_i
 * 7) register2 address rs2_i
 * 8) alu result alu_res_i
 * 9) control register ctrl_reg_i
 * Outputs:
 * 1) program counter pc_o
 * 2) register2 data rs2data_o
 * 3) function3 funct3_o
 * 4) registerd address rd_o
 * 5) register2 address rs2_o
 * 6) alu result alu_res_o
 * 7) control register ctrl_reg_o
 */

  `include "constants.svh"

module xm_reg #(
  parameter int DWIDTH=32,
  parameter int AWIDTH=32
)(
   // inputs
      input logic clk,
      input logic rst,
      input logic [AWIDTH-1:0] pc_i,
      input logic [DWIDTH-1:0] rs2data_i,
      input logic [2:0] funct3_i,
      input logic [4:0] rd_i,
      input logic [4:0] rs2_i,
      input logic [DWIDTH-1:0] alu_res_i,
      input logic [12:0] ctrl_reg_i,
      input logic [DWIDTH-1:0] imm_i,

  // outputs
  output logic [AWIDTH-1:0] pc_o,
  output logic [DWIDTH-1:0] rs2data_o,
  output logic [2:0] funct3_o,
  output logic [4:0] rd_o,
  output logic [4:0] rs2_o,
  output logic [DWIDTH-1:0] alu_res_o,
  output logic [12:0] ctrl_reg_o,
  output logic [DWIDTH-1:0] imm_o
);
  always_ff @(posedge clk) begin
    if (rst) begin
      pc_o <= '0;
      rs2data_o <= '0;
      funct3_o <= '0;
      rd_o <= '0;
      rs2_o <= '0;
      alu_res_o <= '0;
      ctrl_reg_o <= '0;
      imm_o <= '0;
    end else begin
      pc_o <= pc_i;
      rs2data_o <= rs2data_i;
      funct3_o <= funct3_i;
      rd_o <= rd_i;
      rs2_o <= rs2_i;
      alu_res_o <= alu_res_i;
      ctrl_reg_o <= ctrl_reg_i;
      imm_o <= imm_i;
    end
  end

endmodule : xm_reg
