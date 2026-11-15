/*
 * Module: btb
 *
 * Description: TODO: ADD
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) fetch program counter pc_i
 * 4) write enable update_i
 * 5) program counter to store update_pc_i
 * 6) its real target update_target_i
 * Outputs:
 * 1) tag match hit_o
 * 2) stored target target_o (only meaningful when hit_o)
 */

`include "constants.svh"

module btb #(
    parameter int AWIDTH = 32,
    parameter int INDEX_BITS = 6          // 2^6 = 64 entries
)(
    // inputs
    input logic clk,
    input logic rst,
    input logic [AWIDTH-1:0] pc_i,
    input logic update_i,
    input logic [AWIDTH-1:0] update_pc_i,
    input logic [AWIDTH-1:0] update_target_i,

    // outputs
    output logic hit_o,
    output logic [AWIDTH-1:0] target_o
);
    localparam int ENTRIES = 1 << INDEX_BITS;
    localparam int TAG_BITS = AWIDTH - INDEX_BITS - 2;

    logic valid [ENTRIES];                // entry has been written
    logic [TAG_BITS-1:0] tags [ENTRIES];  // upper PC bits of the stored PC
    logic [AWIDTH-1:0] targets [ENTRIES]; // where that PC went
    logic [INDEX_BITS-1:0] rd_idx;        // entry read by fetch
    logic [INDEX_BITS-1:0] wr_idx;        // entry written by execute

    assign rd_idx = pc_i[INDEX_BITS+1:2];
    assign wr_idx = update_pc_i[INDEX_BITS+1:2];
    assign hit_o = valid[rd_idx] && (tags[rd_idx] == pc_i[AWIDTH-1:INDEX_BITS+2]);
    assign target_o = targets[rd_idx];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < ENTRIES; i++) valid[i] <= 1'b0;
        end else if (update_i) begin
            valid[wr_idx] <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (update_i) begin
            tags[wr_idx] <= update_pc_i[AWIDTH-1:INDEX_BITS+2];
            targets[wr_idx] <= update_target_i;
        end
    end

endmodule : btb
