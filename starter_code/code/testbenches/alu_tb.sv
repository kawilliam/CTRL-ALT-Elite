`include "constants.svh"
`include "execute.sv" // alu lives in execute.sv

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd100
`endif

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif

/*
 * alu_tb: tests every ALU operation and corner case (overflow, shift amount
 * > 31, signed vs unsigned), the address forms of ALU_ADD (pc + imm, jalr),
 * the branch-taken decision for every branch type, and invalid inputs.
 */
module alu_tb;

    logic clk = 0;
    logic rst = 1;
    always #1 clk = ~clk;

    localparam int DWIDTH = 32;
    localparam int AWIDTH = 32;
    localparam logic [31:0] PC = 'h0100_0000;   // setting initial pc_i to this for every test

    // Signals for this testbench
    logic [AWIDTH-1:0] pc;         // pc_i
    logic [DWIDTH-1:0] rs1, rs2;   // operands
    logic [DWIDTH-1:0] imm;        // immediate
    logic [6:0]        opcode;     // instruction type
    logic [2:0]        funct3;     // branch condition
    logic [3:0]        alusel;     // which operation to perform
    logic [DWIDTH-1:0] result;     // ALU result
    logic              brtaken;    // branch decision

    alu #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) hut (
        .pc_i(pc),
        .rs1_i(rs1),
        .rs2_i(rs2),
        .funct3_i(funct3),
        .funct7_i(7'd0),
        .opcode_i(opcode),
        .imm_i(imm),
        .alusel_i(alusel),
        .res_o(result),
        .brtaken_o(brtaken)
    );

    // Define all of our test
    typedef struct {
        string       name;          // label
        logic [3:0]  alusel;        // module input
        logic [6:0]  opcode;        // module input
        logic [2:0]  funct3;        // module input
        logic [31:0] rs1, rs2, imm; // module input
        logic [31:0] exp_result;    // expected result
        logic        exp_taken;     // expected br taken
    } test_t;

    test_t tests [$];
    int number_of_tests;

    initial begin
        // Arithmetic and logic (no branching)
        tests.push_back('{"ADD",                            `ALU_ADD,  `R_TYPE,       0,      5,           3,           0,       8,               0});
        tests.push_back('{"ADD overflow wraps around",      `ALU_ADD,  `R_TYPE,       0,      'h7FFFFFFF,  1,           0,       'h80000000,      0});
        tests.push_back('{"ADDI adds imm, ignores rs2",     `ALU_ADD,  `I_TYPE,       0,      10,          999,         -3,      7,               0});
        tests.push_back('{"load/store address = rs1 + imm", `ALU_ADD,  `S_TYPE,       0,      'h01080000,  999,         -4,      'h0107FFFC,      0});
        tests.push_back('{"jal target = pc + imm",          `ALU_ADD,  `J_TYPE,       0,      999,         999,         'h10,    'h01000010,      0});
        tests.push_back('{"auipc = pc + imm",               `ALU_ADD,  `U_TYPE_AUIPC, 0,      999,         999,         'h1000,  'h01001000,      0});
        tests.push_back('{"jalr target clears bit 0",       `ALU_ADD,  `I_TYPE_JALR,  0,      'h01000003,  999,         4,       'h01000006,      0});
        tests.push_back('{"SUB gives a negative result",    `ALU_SUB,  `R_TYPE,       0,      3,           5,           0,       'hFFFFFFFE,      0});
        tests.push_back('{"AND",                            `ALU_AND,  `R_TYPE,       0,      'hF0F0F0F0,  'hFF00FF00,  0,       'hF000F000,      0});
        tests.push_back('{"OR",                             `ALU_OR,   `R_TYPE,       0,      'hF0F0F0F0,  'hFF00FF00,  0,       'hFFF0FFF0,      0});
        tests.push_back('{"XOR",                            `ALU_XOR,  `R_TYPE,       0,      'hF0F0F0F0,  'hFF00FF00,  0,       'h0FF00FF0,      0});
        tests.push_back('{"SLL by 31",                      `ALU_SLL,  `R_TYPE,       0,      1,           31,          0,       'h80000000,      0});
        tests.push_back('{"SLL uses only rs2[4:0] (33->1)", `ALU_SLL,  `R_TYPE,       0,      1,           33,          0,       2,               0});
        tests.push_back('{"SRL fills with 0",               `ALU_SRL,  `R_TYPE,       0,      'h80000000,  31,          0,       1,               0});
        tests.push_back('{"SRA fills with the sign bit",    `ALU_SRA,  `R_TYPE,       0,      'h80000000,  31,          0,       'hFFFFFFFF,      0});
        tests.push_back('{"SLT signed: -1 < 1",             `ALU_SLT,  `R_TYPE,       0,      'hFFFFFFFF,  1,           0,       1,               0});
        tests.push_back('{"SLTU unsigned: 0xFFFFFFFF > 1",  `ALU_SLTU, `R_TYPE,       0,      'hFFFFFFFF,  1,           0,       0,               0});
        tests.push_back('{"unused select (10) gives 0",     4'd10,     `R_TYPE,       0,      'hDEADBEEF,  1,           1,       0,               0});
        tests.push_back('{"ALU_NOP gives 0",                `ALU_NOP,  `R_TYPE,       0,      'hDEADBEEF,  1,           1,       0,               0});

        // Branches: alu result is pc + imm = PC + 'h20
        tests.push_back('{"BEQ  5 == 5: taken",             `ALU_ADD,  `B_TYPE,       `F3_BEQ,   5,           5,           'h20,    'h01000020,      1});
        tests.push_back('{"BEQ  5 != 6: not taken",         `ALU_ADD,  `B_TYPE,       `F3_BEQ,   5,           6,           'h20,    'h01000020,      0});
        tests.push_back('{"BNE  5 != 6: taken",             `ALU_ADD,  `B_TYPE,       `F3_BNE,   5,           6,           'h20,    'h01000020,      1});
        tests.push_back('{"BNE  5 == 5: not taken",         `ALU_ADD,  `B_TYPE,       `F3_BNE,   5,           5,           'h20,    'h01000020,      0});
        tests.push_back('{"BLT  -1 < 1 (signed): taken",    `ALU_ADD,  `B_TYPE,       `F3_BLT,   'hFFFFFFFF,  1,           'h20,    'h01000020,      1});
        tests.push_back('{"BLT  5 < 5: not taken",          `ALU_ADD,  `B_TYPE,       `F3_BLT,   5,           5,           'h20,    'h01000020,      0});
        tests.push_back('{"BGE  1 >= -1 (signed): taken",   `ALU_ADD,  `B_TYPE,       `F3_BGE,   1,           'hFFFFFFFF,  'h20,    'h01000020,      1});
        tests.push_back('{"BGE  5 >= 5: taken",             `ALU_ADD,  `B_TYPE,       `F3_BGE,   5,           5,           'h20,    'h01000020,      1});
        tests.push_back('{"BGE  -1 >= 1: not taken",        `ALU_ADD,  `B_TYPE,       `F3_BGE,   'hFFFFFFFF,  1,           'h20,    'h01000020,      0});
        tests.push_back('{"BLTU 1 < 0xFFFFFFFF: taken",     `ALU_ADD,  `B_TYPE,       `F3_BLTU,  1,           'hFFFFFFFF,  'h20,    'h01000020,      1});
        tests.push_back('{"BLTU 0xFFFFFFFF < 1: not taken", `ALU_ADD,  `B_TYPE,       `F3_BLTU,  'hFFFFFFFF,  1,           'h20,    'h01000020,      0});
        tests.push_back('{"BGEU 0xFFFFFFFF >= 1: taken",    `ALU_ADD,  `B_TYPE,       `F3_BGEU,  'hFFFFFFFF,  1,           'h20,    'h01000020,      1});
        tests.push_back('{"BGEU 5 >= 5: taken",             `ALU_ADD,  `B_TYPE,       `F3_BGEU,  5,           5,           'h20,    'h01000020,      1});
        tests.push_back('{"BGEU 1 >= 0xFFFFFFFF: not taken",`ALU_ADD,  `B_TYPE,       `F3_BGEU,  1,           'hFFFFFFFF,  'h20,    'h01000020,      0});

        // Invalid inputs
        tests.push_back('{"invalid branch funct3 = 2",      `ALU_ADD,  `B_TYPE,       3'd2,      5,           5,           'h20,    'h01000020,      0});
        tests.push_back('{"invalid branch funct3 = 3",      `ALU_ADD,  `B_TYPE,       3'd3,      5,           5,           'h20,    'h01000020,      0});
        tests.push_back('{"R-type with BEQ bits: no branch",`ALU_ADD,  `R_TYPE,       `F3_BEQ,   5,           5,           0,       10,              0});

        number_of_tests = tests.size();
    end


    int test_counter = 0;   // index of test
    int passes = 0;         // count passed test
    int fails  = 0;         // count failed test

    always_ff @(posedge clk) begin
        if (rst) begin
            pc     <= PC;
            alusel <= '0;
            opcode <= '0;
            funct3 <= '0;
            rs1    <= '0;
            rs2    <= '0;
            imm    <= '0;
            test_counter <= 0;
        end
        else if (test_counter < number_of_tests) begin
            alusel <= tests[test_counter].alusel;
            opcode <= tests[test_counter].opcode;
            funct3 <= tests[test_counter].funct3;
            rs1    <= tests[test_counter].rs1;
            rs2    <= tests[test_counter].rs2;
            imm    <= tests[test_counter].imm;
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

    // On each falling edge, compare the ALU outputs with the test
    test_t current;
    always @(negedge clk) begin
        if (!rst && test_counter > 0) begin
            current = tests[test_counter - 1];
            if (result === current.exp_result && brtaken === current.exp_taken)
                passes++;
            else begin
                fails++;
                $display("  FAIL  %-34s result=%08h (expected %08h)  brtaken=%0b (expected %0b)",
                         current.name, result, current.exp_result, brtaken, current.exp_taken);
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
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);
        $system("date");
    end

endmodule : alu_tb
