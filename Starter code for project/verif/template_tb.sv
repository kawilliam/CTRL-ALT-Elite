`include "constants.svh"
`include "execute.sv" // required for this testbench example

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd50
`endif

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif

module template_tb;

   logic clk = 0;
   logic rst = 1;
   always #1 clk = ~clk;

   localparam int DWIDTH = 32;
   localparam int AWIDTH = 32;

   /* 
    * Instantiate your DUT/HUT (device/hardware under test)
    * This could be the whole design (top module), or a stage/module/sub-module of your design.
    * To help isolate functionality issues, instantiate and test each module separately.
    */

    /*
     * In the following sequential block include logic to test parts of or the whole device.
     * Some ideas:
     *  * Test for program completion and that a specific value has been written to a specific register.
        * Test on each cycle that certain signals match expected values (C1: f_pc == BASE_ADDR, C2: f_pc == BASE_ADDR + 32'd4...etc)
        * Test functionality: i.e., are you jumping/branching when you are expecting to, are you writing to the correct address (or byte of that address) in memory.
        * Test edge cases for branching, jumping, arithmetic, etc.
     * Below is ONE EXAMPLE of a test bench that is testing an arithmetic edge case.
     * This is just a skeleton to get you started and to give you some ideas, it is by no means exhaustive.
     */
    
    // Some signals for this testbench.
    logic [DWIDTH-1:0] rs1, rs2, result;
    logic [6:0]        opcode;
    logic [3:0]        alusel;

    // Only testing R-Type Arithmetic
    assign opcode = `R_TYPE;

    alu #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) hut (
        .pc_i(),
        .rs1_i(rs1),
        .rs2_i(rs2),
        .funct3_i(),
        .funct7_i(),
        .opcode_i(opcode),
        .imm_i(),
        .alusel_i(alusel),
        .res_o(result),
        .brtaken_o()
    );

    int number_of_tests = 10;
    int test_counter = 0; 
    
    always_ff @(posedge clk) begin
        if (rst) begin
            alusel <= '0;
            rs1 <= '0;
            rs2 <= '0;
            test_counter <= 0;
        end
        else if (test_counter < number_of_tests) begin
            alusel <= 4'($urandom_range(9, 0));
            rs1 <= $urandom();
            rs2 <= $urandom();
            test_counter <= test_counter + 1;
        end
        else begin
            $display("=========================================");
            $display("Completed %0d Tests. Simulation Complete!", number_of_tests);
            $display("=========================================");
            $finish;
        end
    end

    /* 
     * This block is to stop infinite loops, if you you see "SIMULATION TIMEOUT" it means either:
     *      1) The number of cycles before timeout is too few to capture the full length of your program.
     *      2) There is a flaw in your logic or execution causing an infinite loop. [THIS IS MOST LIKELY]
     */
    integer counter = 0;
    always_ff @(posedge clk) begin
        counter <= counter + 1;
        if (counter < `RESET_CYCLES) begin
            rst <= 1;
        end else begin
            rst <= 0;
        end
        if (counter >= `TIMEOUT) begin
            $display("========== Simulation TIMEOUT!!! ==========");
            $finish;
        end
    end

    // Dump commands to produce waveform files.
    initial begin
      $dumpfile("template_tb.vcd");
      $dumpvars(0, template_tb);
      $system("date");
   end

    /*
     * Failing your own tests is a normal part of design and verification.
     * Learn to read waveforms, it helps, not only in determining functional correctness but also TIMING!!!
     * Provided for you in wf_signals are a few template files of preloaded signals to help get you started.
     * Sometimes you will need to compare an execution diagram to your waveforms, you might have the correct values but at the wrong time.
     * Plan and think about what should happen with your design, write pseudo code for your test bench, and learn to translate it to HDL.
     * Learning to do this is a skill that requires practice that will go a long way to help you with this project (especially as your design becomes more complex).
     */

endmodule : template_tb
