/*
 * Module: alu
 *
 * Description: ALU implementation for execute stage.
 *
 * Inputs:
 * 1) 32-bit PC pc_i
 * 2) 32-bit rs1 data rs1_i
 * 3) 32-bit rs2 data rs2_i
 * 4) 3-bit funct3 funct3_i
 * 5) 7-bit funct7 funct7_i
 *
 * Outputs:
 * 1) 32-bit result of ALU res_o
 * 2) 1-bit branch taken signal brtaken_o
 */

 // WHY IS THE FILE CALLED execute.sv....

`include "constants.svh"

module alu #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
)(
    input logic [AWIDTH-1:0] pc_i,
    input logic [DWIDTH-1:0] rs1_i,
    input logic [DWIDTH-1:0] rs2_i,
    input logic [2:0] funct3_i,
    input logic [6:0] funct7_i,
    input logic [6:0] opcode_i,
    input logic [DWIDTH-1:0] imm_i,
    input logic [3:0] alusel_i,
    output logic [DWIDTH-1:0] res_o,
    output logic brtaken_o
);
    // Signals for branch control signals
    logic breq, brlt;

    /*
     * Instantiation of branch control module
     * This made more sense to me, so we instantiated it here.
     */
    branch_control #(
        .DWIDTH(DWIDTH)
    ) bc (
        .opcode_i(opcode_i),
        .funct3_i(funct3_i),
        .rs1_i(rs1_i),
        .rs2_i(rs2_i),
        .breq_o(breq),
        .brlt_o(brlt)
    );

    // Combinational procedural block for branch control
    always_comb begin
        brtaken_o = 1'b0;
        if (opcode_i == `B_TYPE) begin
            // branch_control already picked signed vs unsigned from funct3,
            // so brlt is the correct comparison for both blt and bltu.
            case (funct3_i)
                `F3_BEQ:  brtaken_o = breq;
                `F3_BNE:  brtaken_o = !breq;
                `F3_BLT:  brtaken_o = brlt;
                `F3_BLTU: brtaken_o = brlt;
                `F3_BGE:  brtaken_o = !brlt;
                `F3_BGEU: brtaken_o = !brlt;
                default:  brtaken_o = 1'b0;
            endcase
        end
    end

    /*
     * Combinational procedural block for alu operations
     */
    always_comb begin
        case (alusel_i)
            // For branch, jal, and jalr instructions calculate new PC
            `ALU_ADD: begin
                if (opcode_i == `B_TYPE || opcode_i == `J_TYPE)
                    // Target is PC-relative. Taken from pc_i/imm_i directly so
                    // that ports A/B stay free to carry rs1/rs2 for the compare.
                    res_o = pc_i + imm_i;
                else if (opcode_i == `I_TYPE_JALR)
                    // jalr clears bit 0 of the computed target per the spec.
                    res_o = (rs1_i + imm_i) & ~32'd1;
                else
                    res_o = rs1_i + rs2_i;
            end
            `ALU_SUB: res_o = rs1_i - rs2_i;
            `ALU_AND: res_o = rs1_i & rs2_i;
            `ALU_OR:  res_o = rs1_i | rs2_i;
            `ALU_XOR: res_o = rs1_i ^ rs2_i;
            // Shift amount is the low 5 bits: rs2 data for R-type, shamt for I-type.
            `ALU_SLL: res_o = rs1_i << rs2_i[4:0];
            `ALU_SRL: res_o = rs1_i >> rs2_i[4:0];
            `ALU_SRA: res_o = $signed(rs1_i) >>> rs2_i[4:0];
            `ALU_SLT:  res_o = ($signed(rs1_i) < $signed(rs2_i)) ? 32'd1 : 32'd0;
            `ALU_SLTU: res_o = (rs1_i < rs2_i) ? 32'd1 : 32'd0;
            default: res_o = '0;
        endcase
    end
endmodule : alu
