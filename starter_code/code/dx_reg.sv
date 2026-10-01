/*
 * Module: dx_reg
 *
 * Description: D/X stage pipeline register
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) program counter pc_i
 * 4) immediate imm_i
 * 5) register1 data rs1data_i
 * 6) register2 data rs2data_i
 * 7) opcode opcode_i
 * 8) function3 funct3_i
 * 9) function7 funct7_i
 * 10) registerd address rd_i
 * 11) register1 address rs1_i
 * 12) register2 address rs2_i
 * 13) flush signal flush_i
 * 14) PC select pcsel_i
 * 15) Immediate select immsel_i
 * 16) register write en regwren_o
 * 17) register1 select rs1sel_i
 * 18) register2 select rs2sel_i
 * 19) ALU select alusel_i
 * 20) memory read en memren_i
 * 21) memory write en memwren_i
 * 22) writeback sel wbsel_i
 * Outputs:
 * 1) program counter pc_o
 * 2) immediate imm_o
 * 3) register1 data rs1data_o
 * 4) register2 data rs2data_o
 * 5) opcode opcode_o
 * 6) function3 funct3_o
 * 7) function7 funct7_o
 * 8) registerd address rd_o
 * 9) register1 address rs1_o
 * 10) register2 address rs2_o
 * 11) control register ctrl_reg_o
 */

 `include "constants.svh"

module dx_reg #(
  parameter int DWIDTH=32,
  parameter int AWIDTH=32
)(
    // inputs
        input logic clk,
        input logic rst,
        input logic [AWIDTH-1:0] pc_i,
        input logic [DWIDTH-1:0] imm_i,
        input logic [DWIDTH-1:0] rs1data_i,
        input logic [DWIDTH-1:0] rs2data_i,
        input logic [6:0] opcode_i,
        input logic [2:0] funct3_i,
        input logic [6:0] funct7_i,
        input logic [4:0] rd_i,
        input logic [4:0] rs1_i,
        input logic [4:0] rs2_i,
        input logic flush_i,
        input logic stall_i,
        input logic pcsel_i, // This is to determine whether to use PC + 4 or Jump
        input logic immsel_i, // Whether to use imm or reg val
        input logic regwren_i, // Reg write enable - whther to write to reg file
        input logic rs1sel_i, // ALU port A: 0 = rs1 register
        input logic rs2sel_i, // ALU port B: 0 = rs2 register, 1 = immediate
        input logic [3:0] alusel_i, // Value drives operation done by ALU
        input logic memren_i, // Whether to read from memory
        input logic memwren_i, // Whether to write to memory
        input logic [1:0] wbsel_i, // What to write to reg file - ALU res, mem data, pc+4, or imm

  // outputs
  output logic [AWIDTH-1:0] pc_o,
  output logic [DWIDTH-1:0] imm_o,
  output logic [DWIDTH-1:0] rs1data_o,
  output logic [DWIDTH-1:0] rs2data_o,
  output logic [6:0] opcode_o,
  output logic [2:0] funct3_o,
  output logic [6:0] funct7_o,
  output logic [4:0] rd_o,
  output logic [4:0] rs1_o,
  output logic [4:0] rs2_o,
  output logic [12:0] ctrl_reg_o
);
  always_ff @(posedge clk) begin
    if (rst || flush_i || stall_i) begin
      pc_o <= '0;
      imm_o <= '0;
      rs1data_o <= '0;
      rs2data_o <= '0;
      opcode_o <= '0;
      funct3_o <= '0;
      funct7_o <= '0;
      rd_o <= '0;
      rs1_o <= '0;
      rs2_o <= '0;
      ctrl_reg_o <= '0;
    end else begin
      pc_o <= pc_i;
      imm_o <= imm_i;
      rs1data_o <= rs1data_i;
      rs2data_o <= rs2data_i;
      opcode_o <= opcode_i;
      funct3_o <= funct3_i;
      funct7_o <= funct7_i;
      rd_o <= rd_i;
      rs1_o <= rs1_i;
      rs2_o <= rs2_i;
      ctrl_reg_o <= {alusel_i, wbsel_i, memwren_i, memren_i, rs2sel_i, rs1sel_i, regwren_i, immsel_i, pcsel_i};
    end
  end

endmodule : dx_reg