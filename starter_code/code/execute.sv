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
        if (opcode_i == `B_TYPE) begin
            case (funct3_i)
                /* LH6: Complete the branch control logic to determine brtaken_o */
                `F3_BEQ: brtaken_o = /* LH6??? */;
                `F3_BNE: brtaken_o = /* LH6??? */;
                `F3_BLT: brtaken_o = /* LH6??? */;
                `F3_BLTU: brtaken_o = /* LH6??? */;
                `F3_BGE: brtaken_o = /* LH6??? */
                `F3_BGEU: brtaken_o = /* LH6??? */
            endcase
        end
        /* LH6??? */
    end

    /*
     * Combinational procedural block for alu operations
     */
    always_comb begin
        case (alusel_i)
            // For branch, jal, and jalr instructions calculate new PC
            `ALU_ADD: res_o = /* LH6??? */
            `ALU_SUB: res_o = /* LH6??? */
            `ALU_AND: res_o = /* LH6??? */
            `ALU_OR:  res_o = /* LH6??? */
            `ALU_XOR: res_o = /* LH6??? */
            `ALU_SLL: res_o = /* LH6??? */
            `ALU_SRL: res_o = /* LH6??? */
            `ALU_SRA: res_o = /* LH6??? */
            `ALU_SLT:  res_o = /* LH6??? */
            `ALU_SLTU: res_o = /* LH6??? */
            default: /* LH6??? */
        endcase
    end
endmodule : alu
