/*
 * Module: stall_flush_logic
 *
 * Description: Stall and flush logic
 *
 * Inputs:
 * 1) hazard_i
 * 2) br_jump_i
 * Outputs:
 * 1) pc_en_o -- Signal to determine whether to stall fetch
 * 2) stall_o -- Signal to determine whether to stall pipeline
 * 3) flush_o -- Signal to determine whether to flush pipeline
 */


// Stall Logic Module
module stall_flush_logic (
   input logic hazard_i,
   input logic br_jump_i,
   output logic pc_en_o,
   output logic stall_o,
   output logic flush_o
);
  // To be filled in Stage 2
endmodule: stall_flush_logic
