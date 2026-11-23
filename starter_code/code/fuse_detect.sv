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
    output logic [AWIDTH-1:0] br_imm_o
);

  assign fused_o     = 1'b0;
  assign stride8_o   = 1'b0;
  assign rs2_o       = 5'd0;
  assign br_funct3_o = 3'd0;
  assign br_target_o = '0;
  assign br_imm_o    = '0;

endmodule: fuse_detect
