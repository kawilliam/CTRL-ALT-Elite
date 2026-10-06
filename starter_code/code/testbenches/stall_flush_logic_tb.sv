`include "constants.svh"

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd50
`endif

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif

/*
 * stall_flush_logic_tb: tests all four combinations of its two inputs.
 * (hazard and br_jump both high never happens in rv_core, which masks the
 * hazard of a wrong-path instruction, but the outputs must still be defined.)
 */
module stall_flush_logic_tb;

    logic clk = 0;
    logic rst = 1;
    always #1 clk = ~clk;

    // Signals for this testbench
    logic hazard;    // a RAW hazard was found in decode
    logic br_jump;   // a taken branch/jump is redirecting fetch
    logic pc_en;     // PC may advance
    logic stall;     // hold F/D, bubble D/X
    logic flush;     // squash F/D and D/X

    stall_flush_logic hut (
        .hazard_i(hazard),
        .br_jump_i(br_jump),
        .pc_en_o(pc_en),
        .stall_o(stall),
        .flush_o(flush)
    );

    typedef struct {
        string name;
        logic  hazard, br_jump;
        logic  exp_pc_en, exp_stall, exp_flush;
    } test_t;

    test_t tests [$];        // list of all tests
    int number_of_tests;     // set once the list is built

    initial begin
        tests.push_back('{"normal flow",                        0,      0,        1,     0,     0});
        tests.push_back('{"hazard: freeze fetch, bubble",       1,      0,        0,     1,     0});
        tests.push_back('{"redirect: fetch target, squash",     0,      1,        1,     0,     1});
        tests.push_back('{"both: hold PC, flush wins in regs",  1,      1,        0,     1,     1});

        number_of_tests = tests.size();
    end

    int test_counter = 0;   // index of the next test to apply
    int passes = 0;         // tests whose outputs matched
    int fails  = 0;         // tests whose outputs did not

    always_ff @(posedge clk) begin
        if (rst) begin
            hazard  <= 0;
            br_jump <= 0;
            test_counter <= 0;
        end
        else if (test_counter < number_of_tests) begin
            hazard  <= tests[test_counter].hazard;
            br_jump <= tests[test_counter].br_jump;
            test_counter <= test_counter + 1;
        end
        else begin
            $display("=========================================");
            $display("Completed %0d Tests. Simulation Complete!", number_of_tests);
            if (fails == 0)
                $display("Test Passed  (%0d checks)", passes);
            else
                $display("Test Failed  (%0d of %0d checks failed)", fails, number_of_tests);
            $display("=========================================");
            $finish;
        end
    end

    test_t current;   // the test being checked

    always @(negedge clk) begin
        if (!rst && test_counter > 0) begin
            current = tests[test_counter - 1];
            if (pc_en === current.exp_pc_en && stall === current.exp_stall && flush === current.exp_flush)
                passes++;
            else begin
                fails++;
                $display("  FAIL  %-34s pc_en=%0b stall=%0b flush=%0b (expected %0b %0b %0b)",
                         current.name, pc_en, stall, flush,
                         current.exp_pc_en, current.exp_stall, current.exp_flush);
            end
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
        $dumpfile("stall_flush_logic_tb.vcd");
        $dumpvars(0, stall_flush_logic_tb);
        $system("date");
    end

endmodule : stall_flush_logic_tb
