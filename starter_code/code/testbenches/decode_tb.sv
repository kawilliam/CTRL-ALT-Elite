`include "constants.svh"

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd50
`endif

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif

/*
 * decode_tb: tests field extraction, pc/insn pass-through, and which
 * register fields each instruction format actually uses.
 *
 * Every instruction applied has the same bit fields [rd = 1, rs1 = 2,
 * rs2 = 3, funct3 = 5, funct7 = 0x20] only the opcode changes
 */
module decode_tb;

    logic clk = 0;
    logic rst = 1;
    always #1 clk = ~clk;

    localparam int DWIDTH = 32;
    localparam int AWIDTH = 32;

    // Signals for this testbench
    logic [DWIDTH-1:0] insn;      // instruction in
    logic [AWIDTH-1:0] pc;        // pc in
    logic [AWIDTH-1:0] pc_o;      // pc out
    logic [DWIDTH-1:0] insn_o;    // instruction out
    logic [6:0]        opcode;    // decoded fields
    logic [2:0]        funct3;
    logic [6:0]        funct7;
    logic [4:0]        rd, rs1, rs2;

    decode #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) hut (
        .clk(clk),
        .rst(rst),
        .insn_i(insn),
        .pc_i(pc),
        .pc_o(pc_o),
        .insn_o(insn_o),
        .opcode_o(opcode),
        .rd_o(rd),
        .rs1_o(rs1),
        .rs2_o(rs2),
        .funct7_o(funct7),
        .funct3_o(funct3),
        .imm_o()
    );

    typedef struct {
        string      name;
        logic [6:0] opcode;
        logic [4:0] exp_rd, exp_rs1, exp_rs2;
    } test_t;

    test_t tests [$];
    int number_of_tests;

    initial begin
        // All instruction types
        tests.push_back('{"R-type uses rd, rs1, rs2",  `R_TYPE,        1,  2,   3});
        tests.push_back('{"I-type has no rs2",         `I_TYPE,        1,  2,   0});
        tests.push_back('{"load has no rs2",           `I_TYPE_L,      1,  2,   0});
        tests.push_back('{"jalr has no rs2",           `I_TYPE_JALR,   1,  2,   0});
        tests.push_back('{"store has no rd",           `S_TYPE,        0,  2,   3});
        tests.push_back('{"branch has no rd",          `B_TYPE,        0,  2,   3});
        tests.push_back('{"lui has no rs1, rs2",       `U_TYPE_LUI,    1,  0,   0});
        tests.push_back('{"auipc has no rs1, rs2",     `U_TYPE_AUIPC,  1,  0,   0});
        tests.push_back('{"jal has no rs1, rs2",       `J_TYPE,        1,  0,   0});

        // Invalid instruction type
        tests.push_back('{"unknown opcode: no rs2",    7'b1110011,     1,  2,   0});

        number_of_tests = tests.size();
    end

    int test_counter = 0;   // index of the next test to apply
    int passes = 0;         // tests whose outputs matched
    int fails  = 0;         // tests whose outputs did not

    always_ff @(posedge clk) begin
        if (rst) begin
            insn <= '0;
            pc   <= '0;
            test_counter <= 0;
        end
        else if (test_counter < number_of_tests) begin
            insn <= {7'h20, 5'd3, 5'd2, 3'd5, 5'd1, tests[test_counter].opcode};
            pc   <= 'h0100_0000 + 4 * test_counter;
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

    // ------------------------------------------------------------------
    // Check: on each falling edge, compare the outputs with the test
    // applied at the rising edge before it. test_counter was already
    // advanced on that edge, so that test is tests[test_counter - 1].
    // ------------------------------------------------------------------
    test_t current;   // the test being checked

    always @(negedge clk) begin
        if (!rst && test_counter > 0) begin
            current = tests[test_counter - 1];
            if (rd === current.exp_rd && rs1 === current.exp_rs1 && rs2 === current.exp_rs2 &&
                opcode === current.opcode && funct3 === 3'd5 && funct7 === 7'h20 &&
                pc_o === pc && insn_o === insn)
                passes++;
            else begin
                fails++;
                $display("  FAIL  %-26s rd=%0d rs1=%0d rs2=%0d (expected %0d %0d %0d)  opcode=%07b funct3=%0d funct7=%02h  pc_o=%08h insn_o=%08h",
                         current.name, rd, rs1, rs2, current.exp_rd, current.exp_rs1, current.exp_rs2,
                         opcode, funct3, funct7, pc_o, insn_o);
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
        $dumpfile("decode_tb.vcd");
        $dumpvars(0, decode_tb);
        $system("date");
    end

endmodule : decode_tb
