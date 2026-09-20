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
    parameter logic [31:0] BASE_ADDR = 32'h01000000
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

    // Word-addressable memory
    localparam int MEM_BYTES = `MEM_DEPTH;
    localparam int MEM_WORDS = MEM_BYTES / (DWIDTH/8);

    logic [DWIDTH-1:0] main_memory [0:MEM_WORDS-1];

    // Temporary memory for loading program
    logic [DWIDTH-1:0] temp_memory [0:LINECOUNT - 1];

    // Initialization of memory from program
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

    //---------- Instruction Load ----------//
    logic [AWIDTH-1:0] program_counter;
    assign program_counter = (pc_i - BASE_ADDR) >> 2;

    // READ ONLY
    always_comb begin
        insn_o = '0;
        if (rst) begin
            insn_o = '0;
        end
        else if (insnen_i) begin
            if ($isunknown(pc_i)) begin
                insn_o = '0;
            end
            else if ((pc_i >= BASE_ADDR) &&
                     (pc_i + 32'd3 < BASE_ADDR + MEM_BYTES)) begin
                insn_o = main_memory[program_counter];
            end
            else begin
                insn_o = 32'hDEAD_BEEF;
                $display("IMEMORY: 00B read @0x%08h (mapped 0x%08h)",
                         pc_i, program_counter);
            end
        end
    end

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
            if ($isunknown(address)) begin
                data_o = '0;
            end
            else begin
                data_o = main_memory[address];
            end
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
