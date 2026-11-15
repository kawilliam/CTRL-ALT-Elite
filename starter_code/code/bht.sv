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
    localparam int TAG_BITS = 8;

    typedef enum logic [1:0] {
        STRONG_NT = 2'b00,                // strong not taken
        WEAK_NT   = 2'b01,                // weak not taken
        WEAK_T    = 2'b10,                // weak taken
        STRONG_T  = 2'b11                 // strong taken
    } state_t;

    logic [TAG_BITS-1:0] tags [ENTRIES];  // upper PC bits of the stored PC
    logic valid [ENTRIES];                // entry has been written
    state_t states [ENTRIES];             // state register: one FSM per entry
    logic [INDEX_BITS-1:0] rd_idx;        // entry read by fetch
    logic [INDEX_BITS-1:0] wr_idx;        // entry trained by execute
    state_t cur_state;                    // state of the FSM being trained
    state_t next_state;                   // its next state
    logic tag_match;

    // Entry number for a PC: bits [INDEX_BITS+1:2], i.e. PC[7:2] for 64 entries.
    // PC[1:0] is skipped because instructions are 4 bytes, so every PC ends in 00.
    // PCs 256 bytes apart have the same PC[7:2] and share an entry (no tag).
    // Fetch and execute hold different instructions, so each gets its own index.
    assign rd_idx = pc_i[INDEX_BITS+1:2];          // entry fetch reads
    assign wr_idx = update_pc_i[INDEX_BITS+1:2];   // entry execute trains
    
    
    assign tag_match = valid[rd_idx] && (tags[rd_idx] == pc_i[INDEX_BITS+2 +: TAG_BITS]);

    // Output logic: predict taken in the two taken states
    // Predict taken only if the entry belongs to this PC AND its counter says taken
    assign taken_o = tag_match && ((states[rd_idx] == WEAK_T) || (states[rd_idx] == STRONG_T));

    // Next-state logic
    assign cur_state = states[wr_idx];

    // Does the entry being trained belong to this branch?
    logic wr_tag_match;
    assign wr_tag_match = valid[wr_idx] &&
                          (tags[wr_idx] == update_pc_i[INDEX_BITS+2 +: TAG_BITS]);
    always_comb begin
        if (!wr_tag_match) begin
            // Different branch owns this entry: start cold and apply only
            // this branch's outcome, instead of evolving a counter that
            // was trained by someone else.
            next_state = update_taken_i ? WEAK_NT : STRONG_NT;
        end else begin
        case (cur_state)
            STRONG_NT: next_state = update_taken_i ? WEAK_NT  : STRONG_NT;
            WEAK_NT:   next_state = update_taken_i ? WEAK_T   : STRONG_NT;
            WEAK_T:    next_state = update_taken_i ? STRONG_T : WEAK_NT;
            STRONG_T:  next_state = update_taken_i ? STRONG_T : WEAK_T;
            default:   next_state = STRONG_NT;
        endcase
        end
    end

    // State register: reset to strong not taken, advance when a branch is trained
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < ENTRIES; i++) begin
                states[i] <= STRONG_NT;
                valid[i]  <= 1'b0;
            end
        end else if (update_i) begin
            states[wr_idx] <= next_state;
            tags[wr_idx]   <= update_pc_i[INDEX_BITS+2 +: TAG_BITS];
            valid[wr_idx]  <= 1'b1;
        end
    end

endmodule : bht
