`include "constants.svh"

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd100
`endif

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif

/*
 * control_tb: tests every control signal for every opcode, the ALU select
 * for every R-type and I-type funct3, the funct7 cases (sub, sra, srai, and
 * addi with a negative immediate, which must stay an add), and an unknown opcode.
 */
module control_tb;

    logic clk = 0;
    logic rst = 1;
    always #1 clk = ~clk;

    localparam int DWIDTH = 32;

    // Signals for this testbench
    logic [6:0] opcode;     // instruction type
    logic [2:0] funct3;     // operation (R/I-type)
    logic [6:0] funct7;     // sub / sra select
    logic       pcsel;      // jump: next PC comes from the ALU
    logic       immsel;     // instruction has an immediate
    logic       regwren;    // writes rd
    logic       rs1sel;     // ALU port A select (always rs1)
    logic       rs2sel;     // ALU port B: 0 = rs2, 1 = immediate
    logic       memren;     // reads memory (load)
    logic       memwren;    // writes memory (store)
    logic [1:0] wbsel;      // write-back source: ALU, memory, pc+4, immediate
    logic [3:0] alusel;     // ALU operation

    control #(
        .DWIDTH(DWIDTH)
    ) hut (
        .insn_i('0),
        .opcode_i(opcode),
        .funct7_i(funct7),
        .funct3_i(funct3),
        .pcsel_o(pcsel),
        .immsel_o(immsel),
        .regwren_o(regwren),
        .rs1sel_o(rs1sel),
        .rs2sel_o(rs2sel),
        .memren_o(memren),
        .memwren_o(memwren),
        .wbsel_o(wbsel),
        .alusel_o(alusel)
    );

    typedef struct {
        string      name;
        logic [6:0] opcode;
        logic [2:0] funct3;
        logic [6:0] funct7;
        logic       pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
        logic [1:0] wbsel;
        logic [3:0] alusel;
    } test_t;

    test_t tests [$];        // list of all tests
    int number_of_tests;     // set once the list is built

    initial begin
        // R-type: every funct3, then the two funct7 = 0x20 cases
        tests.push_back('{"R-type add",                 `R_TYPE,       `F3_ADD,     0,        0,    0,  1, 0, 0,    0,  0,  `WB_ALU, `ALU_ADD});
        tests.push_back('{"R-type sll",                 `R_TYPE,       `F3_SLEFT,   0,        0,    0,  1, 0, 0,    0,  0,  `WB_ALU, `ALU_SLL});
        tests.push_back('{"R-type slt",                 `R_TYPE,       `F3_SLT,     0,        0,    0,  1, 0, 0,    0,  0,  `WB_ALU, `ALU_SLT});
        tests.push_back('{"R-type sltu",                `R_TYPE,       `F3_SLTU,    0,        0,    0,  1, 0, 0,    0,  0,  `WB_ALU, `ALU_SLTU});
        tests.push_back('{"R-type xor",                 `R_TYPE,       `F3_XOR,     0,        0,    0,  1, 0, 0,    0,  0,  `WB_ALU, `ALU_XOR});
        tests.push_back('{"R-type srl",                 `R_TYPE,       `F3_SRIGHT,  0,        0,    0,  1, 0, 0,    0,  0,  `WB_ALU, `ALU_SRL});
        tests.push_back('{"R-type or",                  `R_TYPE,       `F3_OR,      0,        0,    0,  1, 0, 0,    0,  0,  `WB_ALU, `ALU_OR});
        tests.push_back('{"R-type and",                 `R_TYPE,       `F3_AND,     0,        0,    0,  1, 0, 0,    0,  0,  `WB_ALU, `ALU_AND});
        tests.push_back('{"R-type sub (funct7 0x20)",   `R_TYPE,       `F3_ADD,     `F7_SUB,  0,    0,  1, 0, 0,    0,  0,  `WB_ALU, `ALU_SUB});
        tests.push_back('{"R-type sra (funct7 0x20)",   `R_TYPE,       `F3_SRIGHT,  `F7_SRA,  0,    0,  1, 0, 0,    0,  0,  `WB_ALU, `ALU_SRA});

        // I-type: every funct3, srai, and addi whose imm[11:5] = 0x20
        tests.push_back('{"I-type addi",                `I_TYPE,       `F3_ADD,     0,        0,    1,  1, 0, 1,    0,  0,  `WB_ALU, `ALU_ADD});
        tests.push_back('{"I-type slli",                `I_TYPE,       `F3_SLEFT,   0,        0,    1,  1, 0, 1,    0,  0,  `WB_ALU, `ALU_SLL});
        tests.push_back('{"I-type slti",                `I_TYPE,       `F3_SLT,     0,        0,    1,  1, 0, 1,    0,  0,  `WB_ALU, `ALU_SLT});
        tests.push_back('{"I-type sltiu",               `I_TYPE,       `F3_SLTU,    0,        0,    1,  1, 0, 1,    0,  0,  `WB_ALU, `ALU_SLTU});
        tests.push_back('{"I-type xori",                `I_TYPE,       `F3_XOR,     0,        0,    1,  1, 0, 1,    0,  0,  `WB_ALU, `ALU_XOR});
        tests.push_back('{"I-type srli",                `I_TYPE,       `F3_SRIGHT,  0,        0,    1,  1, 0, 1,    0,  0,  `WB_ALU, `ALU_SRL});
        tests.push_back('{"I-type ori",                 `I_TYPE,       `F3_OR,      0,        0,    1,  1, 0, 1,    0,  0,  `WB_ALU, `ALU_OR});
        tests.push_back('{"I-type andi",                `I_TYPE,       `F3_AND,     0,        0,    1,  1, 0, 1,    0,  0,  `WB_ALU, `ALU_AND});
        tests.push_back('{"I-type srai (funct7 0x20)",  `I_TYPE,       `F3_SRIGHT,  `F7_SRA,  0,    1,  1, 0, 1,    0,  0,  `WB_ALU, `ALU_SRA});
        tests.push_back('{"addi negative imm stays add",`I_TYPE,       `F3_ADD,     `F7_SUB,  0,    1,  1, 0, 1,    0,  0,  `WB_ALU, `ALU_ADD});

        // Other opcodes
        tests.push_back('{"load",                       `I_TYPE_L,     `F3_LW,      0,        0,    1,  1, 0, 1,    1,  0,  `WB_MEM, `ALU_ADD});
        tests.push_back('{"store",                      `S_TYPE,       `F3_SW,      0,        0,    1,  0, 0, 1,    0,  1,  `WB_ALU, `ALU_ADD});
        tests.push_back('{"branch (rs2 on port B)",     `B_TYPE,       `F3_BEQ,     0,        0,    1,  0, 0, 0,    0,  0,  `WB_ALU, `ALU_ADD});
        tests.push_back('{"jal",                        `J_TYPE,       0,           0,        1,    1,  1, 0, 1,    0,  0,  `WB_PC4, `ALU_ADD});
        tests.push_back('{"jalr",                       `I_TYPE_JALR,  0,           0,        1,    1,  1, 0, 1,    0,  0,  `WB_PC4, `ALU_ADD});
        tests.push_back('{"lui",                        `U_TYPE_LUI,   0,           0,        0,    1,  1, 0, 1,    0,  0,  `WB_IMM, `ALU_NOP});
        tests.push_back('{"auipc",                      `U_TYPE_AUIPC, 0,           0,        0,    1,  1, 0, 1,    0,  0,  `WB_ALU, `ALU_ADD});

        // Invalid: unknown opcode writes nothing
        tests.push_back('{"unknown opcode is a nop",    7'b1110011,    0,           0,        0,    1,  0, 0, 1,    0,  0,  `WB_ALU, `ALU_NOP});

        number_of_tests = tests.size();
    end

    int test_counter = 0;   // index of the next test to apply
    int passes = 0;         // tests whose outputs matched
    int fails  = 0;         // tests whose outputs did not

    always_ff @(posedge clk) begin
        if (rst) begin
            opcode <= '0;
            funct3 <= '0;
            funct7 <= '0;
            test_counter <= 0;
        end
        else if (test_counter < number_of_tests) begin
            opcode <= tests[test_counter].opcode;
            funct3 <= tests[test_counter].funct3;
            funct7 <= tests[test_counter].funct7;
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
            if (pcsel   === current.pcsel   && immsel  === current.immsel  && regwren === current.regwren && rs1sel  === current.rs1sel  &&
                rs2sel  === current.rs2sel  && memren  === current.memren  && memwren === current.memwren && wbsel   === current.wbsel   &&
                alusel  === current.alusel)
                passes++;
            else begin
                fails++;
                $display("  FAIL  %-28s pcsel imm wr a1 b mrd mwr wbsel alusel", current.name);
                $display("          got:                         %0b     %0b   %0b  %0b  %0b %0b   %0b   %2b    %4b",
                         pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren, wbsel, alusel);
                $display("          expected:                    %0b     %0b   %0b  %0b  %0b %0b   %0b   %2b    %4b",
                         current.pcsel, current.immsel, current.regwren, current.rs1sel, current.rs2sel, current.memren, current.memwren, current.wbsel, current.alusel);
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
        $dumpfile("control_tb.vcd");
        $dumpvars(0, control_tb);
        $system("date");
    end

endmodule : control_tb
