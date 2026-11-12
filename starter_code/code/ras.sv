/*
 * Module: ras
 *
 * Description: Stores the return addresses of called functions and predicts when they will be used
 *
 * Inputs:
 * 1) system clock clk
 * 2) reset rst
 * 3) push enable signal push_en_i
 * 4) push address push_a_i
 * 5) pop enable signal pop_en_i
 * 6) restore enable signal rstr_en_i
 * 7) restore enable pointer rstr_ptr_i
 * Outputs:
 * 1) predicted target address target_o
 * 2) empty stack signal em_flag_o
 */


`include "constants.svh"

module pre_decode 
#(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
)(
// inputs 
input logic clk,
input logic rst,
input logic push_en_i,
input logic [AWIDTH-1:0] push_a_i,
input logic pop_en_i,
input logic rstr_en_i,
input logic [] rstr_ptr_i,

// outputs
output logic [AWIDTH-1:0] target_o,
output logic em_flag_o
);

endmodule : ras
