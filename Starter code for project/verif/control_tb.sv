/*
 * Testbench: control_tb
 *
 * Checks the control path (LH4): one expected control word per instruction
 * format, plus the funct3/funct7 ALU decode for R-type and I-type.
 *
 * The two subtle requirements this pins down:
 *   - rs2sel must be 0 for B-type, because the ALU's rs1_i/rs2_i ports feed
 *     the branch comparator and therefore must carry rs1/rs2, not the imm.
 *   - rs1sel selects PC only for auipc; branch and jal targets are built from
 *     the ALU's own pc_i/imm_i ports instead.
 */
`include "constants.svh"

`timescale 1ns/1ps

module control_tb;

    localparam int DWIDTH = 32;

    logic [DWIDTH-1:0] insn;
    logic [6:0]        opcode, funct7;
    logic [2:0]        funct3;
    logic              pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
    logic [1:0]        wbsel;
    logic [3:0]        alusel;

    control #(.DWIDTH(DWIDTH)) hut (
        .insn_i(insn),
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

    int pass_count = 0;
    int fail_count = 0;

    task automatic chk(input string label,
                       input logic exp_pcsel,   input logic exp_regwren,
                       input logic exp_rs1sel,  input logic exp_rs2sel,
                       input logic exp_memren,  input logic exp_memwren,
                       input logic [1:0] exp_wbsel);
        begin
            #1;
            if (pcsel   === exp_pcsel   && regwren === exp_regwren &&
                rs1sel  === exp_rs1sel  && rs2sel  === exp_rs2sel  &&
                memren  === exp_memren  && memwren === exp_memwren &&
                wbsel   === exp_wbsel) begin
                pass_count++;
            end
            else begin
                fail_count++;
                $display("  FAIL %-10s pcsel=%0b/%0b regwr=%0b/%0b rs1sel=%0b/%0b rs2sel=%0b/%0b memr=%0b/%0b memw=%0b/%0b wbsel=%02b/%02b (got/want)",
                         label, pcsel, exp_pcsel, regwren, exp_regwren,
                         rs1sel, exp_rs1sel, rs2sel, exp_rs2sel,
                         memren, exp_memren, memwren, exp_memwren,
                         wbsel, exp_wbsel);
            end
        end
    endtask

    task automatic chk_alusel(input logic [6:0] op,
                              input logic [2:0] f3,
                              input logic [6:0] f7,
                              input logic [3:0] expected,
                              input string      label);
        begin
            opcode = op; funct3 = f3; funct7 = f7; insn = '0;
            #1;
            if (alusel === expected) pass_count++;
            else begin
                fail_count++;
                $display("  FAIL %-12s alusel got=%04b want=%04b",
                         label, alusel, expected);
            end
        end
    endtask

    initial begin
        $display("=========== control_tb (LH4) ===========");
        insn = '0; funct3 = '0; funct7 = '0;

        //                      pcsel regwr rs1sel rs2sel memr memw wbsel
        opcode = `R_TYPE;
        chk("R_TYPE",            1'b0, 1'b1, 1'b0,  1'b0,  1'b0, 1'b0, `WB_ALU);

        opcode = `I_TYPE;
        chk("I_TYPE",            1'b0, 1'b1, 1'b0,  1'b1,  1'b0, 1'b0, `WB_ALU);

        opcode = `I_TYPE_L;
        chk("I_TYPE_L",          1'b0, 1'b1, 1'b0,  1'b1,  1'b1, 1'b0, `WB_MEM);

        opcode = `S_TYPE;
        chk("S_TYPE",            1'b0, 1'b0, 1'b0,  1'b1,  1'b0, 1'b1, `WB_ALU);

        // rs2sel must stay 0 so the branch comparator sees rs2
        opcode = `B_TYPE;
        chk("B_TYPE",            1'b0, 1'b0, 1'b0,  1'b0,  1'b0, 1'b0, `WB_ALU);

        opcode = `J_TYPE;
        chk("J_TYPE",            1'b1, 1'b1, 1'b0,  1'b1,  1'b0, 1'b0, `WB_PC4);

        opcode = `I_TYPE_JALR;
        chk("JALR",              1'b1, 1'b1, 1'b0,  1'b1,  1'b0, 1'b0, `WB_PC4);

        opcode = `U_TYPE_LUI;
        chk("LUI",               1'b0, 1'b1, 1'b0,  1'b1,  1'b0, 1'b0, `WB_IMM);

        // auipc is the only format that routes PC into ALU port A
        opcode = `U_TYPE_AUIPC;
        chk("AUIPC",             1'b0, 1'b1, 1'b1,  1'b1,  1'b0, 1'b0, `WB_ALU);

        // ---------- R-type ALU decode ----------
        chk_alusel(`R_TYPE, `F3_ADD,    `F7_ADD, `ALU_ADD,  "add");
        chk_alusel(`R_TYPE, `F3_ADD,    `F7_SUB, `ALU_SUB,  "sub");
        chk_alusel(`R_TYPE, `F3_SLEFT,  `F7_SLL, `ALU_SLL,  "sll");
        chk_alusel(`R_TYPE, `F3_SLT,    7'h00,   `ALU_SLT,  "slt");
        chk_alusel(`R_TYPE, `F3_SLTU,   7'h00,   `ALU_SLTU, "sltu");
        chk_alusel(`R_TYPE, `F3_XOR,    7'h00,   `ALU_XOR,  "xor");
        chk_alusel(`R_TYPE, `F3_SRIGHT, `F7_SRL, `ALU_SRL,  "srl");
        chk_alusel(`R_TYPE, `F3_SRIGHT, `F7_SRA, `ALU_SRA,  "sra");
        chk_alusel(`R_TYPE, `F3_OR,     7'h00,   `ALU_OR,   "or");
        chk_alusel(`R_TYPE, `F3_AND,    7'h00,   `ALU_AND,  "and");

        // ---------- I-type ALU decode ----------
        chk_alusel(`I_TYPE, `F3_ADD,    7'h00,   `ALU_ADD,  "addi");
        // funct7=0x20 with F3_ADD is NOT subi -- addi must stay add
        chk_alusel(`I_TYPE, `F3_ADD,    `F7_SUB, `ALU_ADD,  "addi not sub");
        chk_alusel(`I_TYPE, `F3_SLT,    7'h00,   `ALU_SLT,  "slti");
        chk_alusel(`I_TYPE, `F3_SLTU,   7'h00,   `ALU_SLTU, "sltiu");
        chk_alusel(`I_TYPE, `F3_XOR,    7'h00,   `ALU_XOR,  "xori");
        chk_alusel(`I_TYPE, `F3_OR,     7'h00,   `ALU_OR,   "ori");
        chk_alusel(`I_TYPE, `F3_AND,    7'h00,   `ALU_AND,  "andi");
        chk_alusel(`I_TYPE, `F3_SLEFT,  `F7_SLL, `ALU_SLL,  "slli");
        chk_alusel(`I_TYPE, `F3_SRIGHT, `F7_SRL, `ALU_SRL,  "srli");
        chk_alusel(`I_TYPE, `F3_SRIGHT, `F7_SRA, `ALU_SRA,  "srai");

        // ---------- address calculation uses ADD ----------
        chk_alusel(`I_TYPE_L, `F3_LW, 7'h00, `ALU_ADD, "lw addr");
        chk_alusel(`S_TYPE,   `F3_SW, 7'h00, `ALU_ADD, "sw addr");
        chk_alusel(`B_TYPE,   `F3_BEQ,7'h00, `ALU_ADD, "branch target");

        $display("control_tb: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("CONTROL_TB: ALL PASS");
        else                 $display("CONTROL_TB: FAILURES");
        $finish;
    end

endmodule : control_tb
