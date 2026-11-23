// fuse_detect -- STUB. All outputs tied low.
//
// This exists only to give the golden-model testbench something to fail against:
// the accept rows must fail while every reject row passes, which proves the TB
// distinguishes fused from not-fused instead of passing vacuously.
//
// Replace the body with the v1 implementation from the contract in
// docs/experiments.md (Experiment 4). Ports are fixed by the contract and must
// not change: every variant branch shares this interface so the same TB runs
// unmodified on all of them.
`include "constants.svh"

module fuse_detect #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32
) (
    // input
    input  logic [DWIDTH-1:0] insn_a_i,
    input  logic [DWIDTH-1:0] insn_b_i,
    input  logic [AWIDTH-1:0] pc_i,
    input  logic              is_insn_i,
    // output
    output logic              fused_o,
    output logic              stride8_o,
    output logic [4:0]        rs2_o,
    output logic [2:0]        br_funct3_o,
    output logic [AWIDTH-1:0] br_target_o,
    output logic [AWIDTH-1:0] br_imm_o,
    output logic t_first_o          // 1 = t compares as rs1, 0 = t compares as rs2
);
    // fields of addi
    logic [6:0] opcode_a;
    logic [2:0] funct3_a;
    logic [4:0] rd_a;
    assign opcode_a = insn_a_i[6:0];
    assign funct3_a = insn_a_i[14:12];
    assign rd_a = insn_a_i[11:7];

    // fields of branch
    logic [6:0] opcode_b;
    logic [2:0] funct3_b;
    logic [4:0] rs1_b;
    logic [4:0] rs2_b;
    logic [12:0] imm_b;
    logic [AWIDTH-1:0] imm_b_ext;
    assign opcode_b = insn_b_i[6:0];
    assign funct3_b = insn_b_i[14:12];
    assign rs1_b = insn_b_i[19:15];
    assign rs2_b = insn_b_i[24:20];
    assign imm_b = {insn_b_i[31], insn_b_i[7], insn_b_i[30:25], insn_b_i[11:8], 1'b0};
    assign imm_b_ext = {{(AWIDTH-13){insn_b_i[31]}}, imm_b};



    // v2: either operand position may hold the addi's result. Only two register
    // reads are available, and in both forms the branch's *other* operand is that
    // result rather than a third read -- which is why the rd == operand rule is
    // load-bearing and cannot be relaxed further.
    logic rs1_match, rs2_match;
    assign rs1_match = (rs1_b == rd_a);   // v1 form: t is the branch's rs1
    assign rs2_match = (rs2_b == rd_a);   // mirrored: t is the branch's rs2

    assign fused_o = is_insn_i
                    && (opcode_a == `I_TYPE)
                    && (funct3_a == `F3_ADD)
                    && (rd_a != 5'd0)
                    && (opcode_b == `B_TYPE)
                    && (funct3_b != 3'b010)
                    && (funct3_b != 3'b011)
                    && (rs1_match || rs2_match);
    assign stride8_o = fused_o;
    // rs1_match wins when both match (beq x5,x5), so the both-match row has one answer
    assign rs2_o = fused_o ? (rs1_match ? rs2_b : rs1_b) : 5'd0;
    assign t_first_o = fused_o ? rs1_match : 1'b0;
    assign br_funct3_o = fused_o ? funct3_b : 3'd0;
    assign br_target_o = fused_o ? (pc_i + 32'd4 + imm_b_ext) : '0;
    assign br_imm_o = fused_o ? imm_b_ext : '0;

endmodule: fuse_detect
