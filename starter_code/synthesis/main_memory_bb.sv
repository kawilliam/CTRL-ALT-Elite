/*
 * Module: main_memory  --  SYNTHESIS BLACKBOX
 *
 * Same name, parameters and ports as code/main_memory.sv, with no body.
 *
 * Why this file exists: the real main_memory is the instruction/data array
 * (LINECOUNT words). Elaborated into the netlist it becomes tens of thousands of
 * flip-flops, and the reported critical path is the array's read path -- a memory
 * artefact, not logic. Every timing number produced that way is meaningless for
 * the processor. synthesis.ys reads THIS file instead, so rv_core is synthesised
 * with a blackbox where the memory sits, and the reported fmax belongs to the
 * pipeline.
 *
 * Keep the ports in sync with code/main_memory.sv. A port added there and not
 * here is a hierarchy error (which is the failure you want: loud, not silent).
 */
module main_memory #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32,
    parameter int LINECOUNT = 1000,
    parameter logic [31:0] BASE_ADDR = 32'h0100_0000
) (
    // inputs
    input  logic clk,
    input  logic rst,
    input  logic [AWIDTH-1:0] pc_i,
    input  logic [AWIDTH-1:0] pc2_i,
    input  logic [AWIDTH-1:0] addr_i,
    input  logic [DWIDTH-1:0] data_i,
    input  logic [(DWIDTH/8)-1:0] bytelane_i,
    input  logic memren_i,
    input  logic memwren_i,
    input  logic insnen_i,
    // outputs
    output logic [DWIDTH-1:0] insn_o,
    output logic [DWIDTH-1:0] insn2_o,
    output logic [DWIDTH-1:0] data_o
);
    // no body: hierarchy treats this as a blackbox
endmodule : main_memory
