`include "constants.svh"

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd50
`endif

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif

/*
 * fetch_tb: tests the program counter, wired the way rv_core wires it
 * (next_pc = jump ? target : pc). Reset, sequential +4, holding while
 * pc_en = 0, a jump loading its target exactly, a jump ignored while the
 * PC is held, and reset in the middle of a run.
 */
module fetch_tb;

    logic clk = 0;
    logic rst = 1;
    always #1 clk = ~clk;

    localparam int DWIDTH = 32;
    localparam int AWIDTH = 32;
    localparam logic [31:0] BASE = 'h0100_0000;   // PC after reset
    localparam logic [31:0] T1   = 'h0100_0100;   // jump targets
    localparam logic [31:0] T2   = 'h0100_0200;

    // Signals for this testbench
    logic f_rst;    // fetch reset
    logic pc_en;    // PC may advance
    logic jump;     // load the target instead of pc + 4
    logic [AWIDTH-1:0] target;   // jump target
    logic [AWIDTH-1:0] pc;       // pc_o

    fetch #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .BASEADDR(BASE)
    ) hut (
        .clk(clk),
        .rst(f_rst),
        .next_pc_i(jump ? target : pc), // same as rv_core
        .pc_en_i(pc_en),
        .jump_branch_i(jump),
        .pc_o(pc),
        .insn_o()
    );

    typedef struct {
        string       name;
        logic        rst, pc_en, jump;
        logic [31:0] target;
        logic [31:0] exp_pc;
    } test_t;

    test_t tests [$];        // list of all tests
    int number_of_tests;     // set once the list is built

    initial begin
        //                name                                  rst pc_en jump target  expected pc_o
        tests.push_back('{"pc_o is 0 during reset",             1,  1,    0,   0,      0});
        tests.push_back('{"PC starts at BASE after reset",      0,  1,    0,   0,      BASE});
        tests.push_back('{"sequential: +4",                     0,  1,    0,   0,      BASE + 4});
        tests.push_back('{"sequential: +4 again",               0,  0,    0,   0,      BASE + 8});
        tests.push_back('{"pc_en=0 (row above) held the PC",    0,  1,    0,   0,      BASE + 8});
        tests.push_back('{"advances again",                     0,  1,    1,   T1,     BASE + 12});
        tests.push_back('{"jump loaded the target, not +4",     0,  1,    0,   0,      T1});
        tests.push_back('{"sequential after the jump",          0,  0,    1,   T2,     T1 + 4});
        tests.push_back('{"jump ignored while pc_en=0",         0,  1,    0,   0,      T1 + 4});
        tests.push_back('{"reset mid-run: pc_o is 0 at once",   1,  1,    0,   0,      0});
        tests.push_back('{"reset mid-run: PC back to BASE",     0,  1,    0,   0,      BASE});

        number_of_tests = tests.size();
    end

    int test_counter = 0;   // index of the next test to apply
    int passes = 0;         // tests whose outputs matched
    int fails  = 0;         // tests whose outputs did not

    always_ff @(posedge clk) begin
        if (rst) begin
            f_rst  <= 1;
            pc_en  <= 1;
            jump   <= 0;
            target <= '0;
            test_counter <= 0;
        end
        else if (test_counter < number_of_tests) begin
            f_rst  <= tests[test_counter].rst;
            pc_en  <= tests[test_counter].pc_en;
            jump   <= tests[test_counter].jump;
            target <= tests[test_counter].target;
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
            if (pc === current.exp_pc)
                passes++;
            else begin
                fails++;
                $display("  FAIL  %-34s pc_o=%08h (expected %08h)", current.name, pc, current.exp_pc);
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
        $dumpfile("fetch_tb.vcd");
        $dumpvars(0, fetch_tb);
        $system("date");
    end

endmodule : fetch_tb
