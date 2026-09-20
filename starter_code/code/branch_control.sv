/*
 * Module: branch_control
 *
 * Description: Branch control logic. Only sets the branch control bits based on the
 * branch instruction
 *
 * Inputs:
 * 1) 7-bit instruction opcode opcode_i
 * 2) 3-bit funct3 funct3_i
 * 3) 32-bit rs1 data rs1_i
 * 4) 32-bit rs2 data rs2_i
 *
 * Outputs:
 * 1) 1-bit operands are equal signal breq_o
 * 2) 1-bit rs1 < rs2 signal brlt_o
 */
`include "constants.svh"

 module branch_control #(
    parameter int DWIDTH=32
)(
    // inputs
    input logic [6:0] opcode_i,
    input logic [2:0] funct3_i,
    input logic [DWIDTH-1:0] rs1_i,
    input logic [DWIDTH-1:0] rs2_i,
    // outputs
    output logic breq_o,
    output logic brlt_o
);

    always_comb begin
        // Check for branch type instruction
        if (opcode_i == `B_TYPE) begin
            // BrEq = 1 if rs1 and rs2 are equal, otherwise its zero, BrUn is irrelavant
            breq_o = (rs1_i == rs2_i) ? 1'b1 : 1'b0;
            // Check for Brach Unsigned instructions (funct3), this is the BrUn signal
            if (funct3_i == `F3_BLTU || funct3_i == `F3_BGEU) begin
                // BrLt = 1 if rs1 < rs2, otherwise its zero (greater than or equal, doesn't matter)
                brlt_o = (rs1_i < rs2_i) ? 1'b1 : 1'b0;
            end
            else begin
                // For signed comparison, compare signed bit first, if equal check next bits
                brlt_o = (rs1_i[31] > rs2_i[31]) ? 1'b1 :
                    (rs1_i[31] < rs2_i[31]) ? 1'b0 :
                    (rs1_i[30:0] < rs2_i[30:0]) ? 1'b1 : 1'b0;
            end
        end
        // Default control signal outputs for non-branch instructions
        else begin
            breq_o = 1'b0;
            brlt_o = 1'b0;
        end
    end

endmodule : branch_control
