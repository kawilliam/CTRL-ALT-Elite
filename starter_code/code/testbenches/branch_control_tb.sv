`include "constants.svh"

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd50
`endif

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif

/*
 * branch_control_tb: tests the comparator that produces breq (rs1 == rs2)
 * and brlt (rs1 < rs2). Signed corners (sign mix, both negative,
 * INT_MIN/INT_MAX), unsigned corners, an invalid funct3, and a non-branch
 * opcode (both flags must be 0).
 */
module branch_control_tb;

    logic clk = 0;
    logic rst = 1;
    always #1 clk = ~clk;

    localparam int DWIDTH = 32;

    // Signals for this testbench
    logic [6:0]        opcode;     // instruction type
    logic [2:0]        funct3;     // branch condition
    logic [DWIDTH-1:0] rs1, rs2;   // operands
    logic              breq;       // rs1 == rs2
    logic              brlt;       // rs1 < rs2

    branch_control #(
        .DWIDTH(DWIDTH)
    ) hut (
        .opcode_i(opcode),
        .funct3_i(funct3),
        .rs1_i(rs1),
        .rs2_i(rs2),
        .breq_o(breq),
        .brlt_o(brlt)
    );

    typedef struct {
        string       name;
        logic [6:0]  opcode;
        logic [2:0]  funct3;
        logic [31:0] rs1, rs2;
        logic        exp_eq, exp_lt;
    } test_t;

    test_t tests [$];        // list of all tests
    int number_of_tests;     // set once the list is built

    initial begin
        tests.push_back('{"equal",                        `B_TYPE,  `F3_BEQ,   7,           7,           1,   0});
        tests.push_back('{"not equal, 7 < 8",             `B_TYPE,  `F3_BNE,   7,           8,           0,   1});
        tests.push_back('{"signed: -1 < 1",               `B_TYPE,  `F3_BLT,   'hFFFFFFFF,  1,           0,   1});
        tests.push_back('{"signed: 1 < -1 is false",      `B_TYPE,  `F3_BLT,   1,           'hFFFFFFFF,  0,   0});
        tests.push_back('{"signed: -2 < -1",              `B_TYPE,  `F3_BGE,   'hFFFFFFFE,  'hFFFFFFFF,  0,   1});
        tests.push_back('{"signed: INT_MIN < INT_MAX",    `B_TYPE,  `F3_BLT,   'h80000000,  'h7FFFFFFF,  0,   1});
        tests.push_back('{"unsigned: 1 < 0xFFFFFFFF",     `B_TYPE,  `F3_BLTU,  1,           'hFFFFFFFF,  0,   1});
        tests.push_back('{"unsigned: 0x80000000 > 1",     `B_TYPE,  `F3_BGEU,  'h80000000,  1,           0,   0});
        tests.push_back('{"invalid funct3 uses signed",   `B_TYPE,  3'd2,      'hFFFFFFFF,  1,           0,   1});
        tests.push_back('{"non-branch opcode gives 0, 0", `R_TYPE,  `F3_BEQ,   7,           7,           0,   0});

        number_of_tests = tests.size();
    end

    int test_counter = 0;   // index of the next test to apply
    int passes = 0;         // tests whose outputs matched
    int fails  = 0;         // tests whose outputs did not

    always_ff @(posedge clk) begin
        if (rst) begin
            opcode <= '0;
            funct3 <= '0;
            rs1    <= '0;
            rs2    <= '0;
            test_counter <= 0;
        end
        else if (test_counter < number_of_tests) begin
            opcode <= tests[test_counter].opcode;
            funct3 <= tests[test_counter].funct3;
            rs1    <= tests[test_counter].rs1;
            rs2    <= tests[test_counter].rs2;
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
            if (breq === current.exp_eq && brlt === current.exp_lt)
                passes++;
            else begin
                fails++;
                $display("  FAIL  %-30s breq=%0b (expected %0b)  brlt=%0b (expected %0b)",
                         current.name, breq, current.exp_eq, brlt, current.exp_lt);
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
        $dumpfile("branch_control_tb.vcd");
        $dumpvars(0, branch_control_tb);
        $system("date");
    end

endmodule : branch_control_tb
