`include "constants.svh"

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd50
`endif

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif

/*
 * igen_tb: tests every immediate format at its sign/range limits, the
 * scattered bits that are easiest to wire wrong (B-type imm[11] comes from
 * insn[7], J-type imm[11] from insn[20]), and an unknown opcode.
 */
module igen_tb;

    logic clk = 0;
    logic rst = 1;
    always #1 clk = ~clk;

    localparam int DWIDTH = 32;

    // Signals for this testbench
    logic [6:0]        opcode;   // selects the immediate format
    logic [DWIDTH-1:0] insn;     // instruction
    logic [DWIDTH-1:0] imm;      // sign-extended immediate

    igen #(
        .DWIDTH(DWIDTH)
    ) hut (
        .opcode_i(opcode),
        .insn_i(insn),
        .imm_o(imm)
    );

    typedef struct {
        string       name;
        logic [31:0] insn;
        logic [31:0] exp_imm;
    } test_t;

    test_t tests [$];
    int number_of_tests;

    initial begin
        //                name                          instruction    expected imm     assembly
        tests.push_back('{"I-type -1",                  32'hFFF08093,  'hFFFFFFFF});   // addi x1,x1,-1
        tests.push_back('{"I-type +2047 (max)",         32'h7FF08093,  'h000007FF});   // addi x1,x1,2047
        tests.push_back('{"load -2048 (min)",           32'h8000A083,  'hFFFFF800});   // lw x1,-2048(x1)
        tests.push_back('{"jalr +4",                    32'h004080E7,  'h00000004});   // jalr x1,4(x1)
        tests.push_back('{"S-type -4 (split field)",    32'hFE112E23,  'hFFFFFFFC});   // sw x1,-4(x2)
        tests.push_back('{"S-type +0x7E1",              32'h7E1120A3,  'h000007E1});   // sw x1,2017(x2)
        tests.push_back('{"B-type -4096 (min)",         32'h80110063,  'hFFFFF000});   // beq x2,x1,-4096
        tests.push_back('{"B-type +4094 (max)",         32'h7E110FE3,  'h00000FFE});   // beq x2,x1,+4094
        tests.push_back('{"B-type only imm[11] set",    32'h001100E3,  'h00000800});   // beq x2,x1,+2048
        tests.push_back('{"lui: low 12 bits are 0",     32'hFFFFF0B7,  'hFFFFF000});   // lui x1,0xfffff
        tests.push_back('{"auipc",                      32'h12345097,  'h12345000});   // auipc x1,0x12345
        tests.push_back('{"J-type -2",                  32'hFFFFF0EF,  'hFFFFFFFE});   // jal x1,-2
        tests.push_back('{"J-type only imm[11] set",    32'h001000EF,  'h00000800});   // jal x1,+2048
        tests.push_back('{"J-type +0xFFFFE (max)",      32'h7FFFF0EF,  'h000FFFFE});   // jal x1,+1048574
        tests.push_back('{"unknown opcode gives 0",     32'hFFFFFFF3,  'h00000000});   // system/csr: no imm

        number_of_tests = tests.size();
    end


    int test_counter = 0;
    int passes = 0;
    int fails  = 0;

    always_ff @(posedge clk) begin
        if (rst) begin
            insn   <= '0;
            opcode <= '0;
            test_counter <= 0;
        end
        else if (test_counter < number_of_tests) begin
            insn   <= tests[test_counter].insn;
            opcode <= tests[test_counter].insn[6:0];
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

    test_t current;
    always @(negedge clk) begin
        if (!rst && test_counter > 0) begin
            current = tests[test_counter - 1];
            if (imm === current.exp_imm)
                passes++;
            else begin
                fails++;
                $display("  FAIL  %-26s insn=%08h  imm=%08h (expected %08h)",
                         current.name, current.insn, imm, current.exp_imm);
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
        $dumpfile("igen_tb.vcd");
        $dumpvars(0, igen_tb);
        $system("date");
    end

endmodule : igen_tb
