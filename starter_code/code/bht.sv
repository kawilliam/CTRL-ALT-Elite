/*
 * Module: bht
 *
 * Description: TODO: ADD
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) fetch program counter pc_i
 * 4) update enable update_i (a conditional branch is in execute)
 * 5) program counter of that branch update_pc_i
 * 6) its real outcome update_taken_i
 * Outputs:
 * 1) predicted direction taken_o
 */

`include "constants.svh"

module bht #(
    parameter int AWIDTH = 32,
    parameter int INDEX_BITS = 6          // 2^6 = 64 counters
)(
    // inputs
    input logic clk,
    input logic rst,
    input logic [AWIDTH-1:0] pc_i,
    input logic update_i,
    input logic [AWIDTH-1:0] update_pc_i,
    input logic update_taken_i,

    // outputs
    output logic taken_o
);
    localparam int ENTRIES = 1 << INDEX_BITS;

    typedef enum logic [1:0] {
        STRONG_NT = 2'b00,                // strong not taken
        WEAK_NT   = 2'b01,                // weak not taken
        WEAK_T    = 2'b10,                // weak taken
        STRONG_T  = 2'b11                 // strong taken
    } state_t;

    state_t states [ENTRIES];             // state register: one FSM per entry
    logic [INDEX_BITS-1:0] rd_idx;        // entry read by fetch
    logic [INDEX_BITS-1:0] wr_idx;        // entry trained by execute
    state_t cur_state;                    // state of the FSM being trained
    state_t next_state;                   // its next state

    // Entry number for a PC: bits [INDEX_BITS+1:2], i.e. PC[7:2] for 64 entries.
    // PC[1:0] is skipped because instructions are 4 bytes, so every PC ends in 00.
    // PCs 256 bytes apart have the same PC[7:2] and share an entry (no tag).
    // Fetch and execute hold different instructions, so each gets its own index.
    assign rd_idx = pc_i[INDEX_BITS+1:2];          // entry fetch reads
    assign wr_idx = update_pc_i[INDEX_BITS+1:2];   // entry execute trains

    // Output logic: predict taken in the two taken states
    assign taken_o = (states[rd_idx] == WEAK_T) || (states[rd_idx] == STRONG_T);

    // Next-state logic
    assign cur_state = states[wr_idx];
    always_comb begin
        case (cur_state)
            STRONG_NT: next_state = update_taken_i ? WEAK_NT  : STRONG_NT;
            WEAK_NT:   next_state = update_taken_i ? WEAK_T   : STRONG_NT;
            WEAK_T:    next_state = update_taken_i ? STRONG_T : WEAK_NT;
            STRONG_T:  next_state = update_taken_i ? STRONG_T : WEAK_T;
            default:   next_state = STRONG_NT;
        endcase
    end

    // State register: reset to strong not taken, advance when a branch is trained
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < ENTRIES; i++) states[i] <= STRONG_NT;
        end else if (update_i) begin
            states[wr_idx] <= next_state;
        end
    end

endmodule : bht
