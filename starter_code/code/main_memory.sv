/*
 * Module: main_memory
 *
 * Description: Byte-addressable memory implementation. Supports both read and write.
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) AWIDTH instruction address pc_i
 * 4) AWIDTH data address addr_i
 * 5) DWIDTH data to write to memory data_i
 * 6) DWIDTH/8 wide signal to select the byte of the memory block bytelane_i
 * 7) read enable signal memren_i
 * 8) write enable signal memwren_i
 * 9) instruction enable signal insnen_i
 *
 * Outputs:
 * 1) DWIDTH instruction output insn_o
 * 2) DWIDTH data output data_o
 *
 */

`include "constants.svh"

module main_memory #(
    // parameters
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32,
    parameter int LINECOUNT = 1000,
    parameter logic [31:0] BASE_ADDR = `BASE_ADDR
) (
    // inputs
    input  logic clk,
    input  logic rst,
    input  logic [AWIDTH-1:0] pc_i, // instruction address
    input  logic [AWIDTH-1:0] addr_i,           // address of where to write to memory
    input  logic [DWIDTH-1:0] data_i,           // data to be written to memory
    input  logic [(DWIDTH/8)-1:0] bytelane_i,   // bytelane for 32-bit memory blocks (like RAM)
    input  logic memren_i,                      // read memory enable
    input  logic memwren_i,                     // write memory enable
    input  logic insnen_i,                      // instruction read enable
    // outputs
    output logic [DWIDTH-1:0] insn_o,           // instruction output
    output logic [DWIDTH-1:0] data_o            // read data from memory output
    // ------------------- //
);

    // Synthesis uses a small fixed memory. Simulation keeps MEM_DEPTH.
    `ifdef SYNTHESIS
        localparam int MEM_BYTES = 1024;
    `else
        localparam int MEM_BYTES = `MEM_DEPTH;
    `endif
    localparam int MEM_WORDS = MEM_BYTES / (DWIDTH/8);

    logic [DWIDTH-1:0] main_memory [0:MEM_WORDS-1];

    `ifndef SYNTHESIS
    logic [DWIDTH-1:0] temp_memory [0:LINECOUNT - 1];

    initial begin
        string mem_path;
        if ($value$plusargs("MEM_PATH=%s", mem_path))
            $readmemh(mem_path, temp_memory);
        else
            $fatal(1, "MEM_PATH not provided");
        for (int i = 0; i < MEM_WORDS; i++) begin
            if (i < LINECOUNT) begin
                main_memory[i] = temp_memory[i];
            end
            else begin
                main_memory[i] = '0;
            end
        end
        $display("MEMORY: Loaded program");
    end
    `endif

    //---------- Instruction Load ----------//
    // The range check catches a run-away PC during bring-up. It costs two 32-bit
    // comparisons, an add and an $isunknown on every fetch of every simulation, and
    // addresses are in range by construction once the design is known-good. Compile
    // it only when asked: -DSIM_BOUNDS_CHECK (make ... CPPFLAGS=-DSIM_BOUNDS_CHECK).
    function automatic logic [DWIDTH-1:0] read_insn(input logic [AWIDTH-1:0] addr);
        logic [AWIDTH-1:0] idx;
        idx = (addr - BASE_ADDR) >> 2;
        read_insn = '0;
        if (!rst && insnen_i) begin
            if ((addr >= BASE_ADDR) && (addr + 32'd3 < BASE_ADDR + MEM_BYTES))
                read_insn = main_memory[idx];
            else begin
                read_insn = 32'hDEAD_BEEF;
                `ifdef TRACE_IMEM
                $display("IMEMORY: read @0x%08h out of range (mapped 0x%08h)", addr, idx);
                `endif
            end
        end
    endfunction

    assign insn_o = read_insn(pc_i);

    // Shift byte address from memory controller to word index for memory
    logic [AWIDTH-1:0] address;
    assign address = addr_i >> $clog2(AWIDTH/8);

    //---------- Memory Data Read ----------//
    always_comb begin
        data_o = '0;
        if (rst) begin
            data_o = '0;
        end
        else if (memren_i) begin
            data_o = main_memory[address];
        end
    end

    //---------- Memory Data Write ----------//
    // +: is an "Index Part-Select"; [starting_bit +: width_select]
    always_ff @(posedge clk) begin
        if (memwren_i) begin
            // Manually checking each byte lane
            for (int i = 0; i < (DWIDTH/8); i++) begin
                // This cycles through each byte of the memory block
                // and checks if the byte is enabled (from the controller)
                if (bytelane_i[i]) begin
                    main_memory[address][(i*8) +: 8] <= data_i[(i*8) +: 8];
                end
            end
        end
    end

endmodule : main_memory
