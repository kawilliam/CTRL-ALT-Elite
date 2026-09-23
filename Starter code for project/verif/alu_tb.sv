/*
 * Testbench: alu_tb
 *
 * Checks the ALU and branch-taken logic (LH6), including the edge cases that
 * a random-operand testbench is unlikely to hit: signed vs unsigned compare,
 * arithmetic vs logical right shift, shift-amount masking to 5 bits, and the
 * PC-relative target calculation used by branches, jal and jalr.
 */
`include "constants.svh"
// The `alu` module lives in execute.sv, so Verilator's -y module search cannot
// find it by name. Include it explicitly, the same way template_tb.sv does.
`include "execute.sv"

`timescale 1ns/1ps

module alu_tb;

    localparam int DWIDTH = 32;
    localparam int AWIDTH = 32;

    logic [AWIDTH-1:0] pc;
    logic [DWIDTH-1:0] rs1, rs2, imm, res;
    logic [2:0]        funct3;
    logic [6:0]        funct7, opcode;
    logic [3:0]        alusel;
    logic              brtaken;

    alu #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) hut (
        .pc_i(pc),
        .rs1_i(rs1),
        .rs2_i(rs2),
        .funct3_i(funct3),
        .funct7_i(funct7),
        .opcode_i(opcode),
        .imm_i(imm),
        .alusel_i(alusel),
        .res_o(res),
        .brtaken_o(brtaken)
    );

    int pass_count = 0;
    int fail_count = 0;

    // Drive an ALU operation with opcode = R_TYPE (plain arithmetic path).
    task automatic chk_alu(input logic [3:0]  sel,
                           input logic [31:0] a,
                           input logic [31:0] b,
                           input logic [31:0] expected,
                           input string       label);
        begin
            opcode = `R_TYPE; funct3 = '0; funct7 = '0;
            pc = '0; imm = '0;
            alusel = sel; rs1 = a; rs2 = b;
            #1;
            if (res === expected) pass_count++;
            else begin
                fail_count++;
                $display("  FAIL %-22s a=%08h b=%08h got=%08h want=%08h",
                         label, a, b, res, expected);
            end
        end
    endtask

    // Drive a target-address calculation (branch / jal / jalr).
    task automatic chk_target(input logic [6:0]  op,
                              input logic [31:0] pc_in,
                              input logic [31:0] a,
                              input logic [31:0] imm_in,
                              input logic [31:0] expected,
                              input string       label);
        begin
            opcode = op; funct3 = '0; funct7 = '0;
            alusel = `ALU_ADD;
            pc = pc_in; rs1 = a; rs2 = imm_in; imm = imm_in;
            #1;
            if (res === expected) pass_count++;
            else begin
                fail_count++;
                $display("  FAIL %-22s pc=%08h imm=%08h got=%08h want=%08h",
                         label, pc_in, imm_in, res, expected);
            end
        end
    endtask

    // Drive the branch comparator.
    task automatic chk_br(input logic [2:0]  f3,
                          input logic [31:0] a,
                          input logic [31:0] b,
                          input logic        expected,
                          input string       label);
        begin
            opcode = `B_TYPE; funct3 = f3; funct7 = '0;
            alusel = `ALU_ADD; pc = '0; imm = '0;
            rs1 = a; rs2 = b;
            #1;
            if (brtaken === expected) pass_count++;
            else begin
                fail_count++;
                $display("  FAIL %-22s a=%08h b=%08h got=%0b want=%0b",
                         label, a, b, brtaken, expected);
            end
        end
    endtask

    initial begin
        $display("=========== alu_tb (LH6) ===========");

        // ---------- arithmetic ----------
        chk_alu(`ALU_ADD, 32'd5, 32'd3, 32'd8, "add 5+3");
        chk_alu(`ALU_ADD, 32'hffffffff, 32'd1, 32'd0, "add -1+1 wraps");
        chk_alu(`ALU_ADD, 32'h7fffffff, 32'd1, 32'h80000000, "add overflow wraps");
        chk_alu(`ALU_SUB, 32'd3, 32'd5, 32'hfffffffe, "sub 3-5 = -2");
        chk_alu(`ALU_SUB, 32'd0, 32'd0, 32'd0, "sub 0-0");

        // ---------- logical ----------
        chk_alu(`ALU_AND, 32'hff00ff00, 32'h0f0f0f0f, 32'h0f000f00, "and");
        chk_alu(`ALU_OR,  32'hff00ff00, 32'h0f0f0f0f, 32'hff0fff0f, "or");
        chk_alu(`ALU_XOR, 32'hff00ff00, 32'h0f0f0f0f, 32'hf00ff00f, "xor");

        // ---------- shifts ----------
        chk_alu(`ALU_SLL, 32'd1, 32'd31, 32'h80000000, "sll 1<<31");
        chk_alu(`ALU_SLL, 32'hdeadbeef, 32'd0, 32'hdeadbeef, "sll by 0");
        // shift amount must use only the low 5 bits (32 -> shift by 0)
        chk_alu(`ALU_SLL, 32'h00000001, 32'd32, 32'h00000001, "sll masks to 5 bits");
        chk_alu(`ALU_SRL, 32'h80000000, 32'd1, 32'h40000000, "srl logical");
        chk_alu(`ALU_SRL, 32'hffffffff, 32'd28, 32'h0000000f, "srl fills zeros");
        chk_alu(`ALU_SRA, 32'h80000000, 32'd1, 32'hc0000000, "sra sign-extends");
        chk_alu(`ALU_SRA, 32'hffffffff, 32'd4, 32'hffffffff, "sra of -1 is -1");
        chk_alu(`ALU_SRA, 32'h40000000, 32'd1, 32'h20000000, "sra of positive");

        // ---------- comparisons: signed vs unsigned differ here ----------
        chk_alu(`ALU_SLT,  32'hffffffff, 32'd1, 32'd1, "slt -1 < 1");
        chk_alu(`ALU_SLT,  32'd1, 32'hffffffff, 32'd0, "slt 1 < -1 false");
        chk_alu(`ALU_SLT,  32'd5, 32'd5, 32'd0, "slt equal");
        chk_alu(`ALU_SLTU, 32'hffffffff, 32'd1, 32'd0, "sltu 0xffffffff < 1 false");
        chk_alu(`ALU_SLTU, 32'd1, 32'hffffffff, 32'd1, "sltu 1 < 0xffffffff");

        // ---------- target calculation ----------
        // branch/jal targets are PC-relative and must ignore rs1
        chk_target(`B_TYPE, 32'h01000010, 32'hdeadbeef, 32'd16,
                   32'h01000020, "branch target pc+16");
        chk_target(`B_TYPE, 32'h01000098, 32'hdeadbeef, 32'hffffffe8,
                   32'h01000080, "branch target pc-24");
        chk_target(`J_TYPE, 32'h01000030, 32'hdeadbeef, 32'd24,
                   32'h01000048, "jal target pc+24");
        // jalr is rs1-relative and must clear bit 0
        chk_target(`I_TYPE_JALR, 32'hdeadbeef, 32'h01000000, 32'd4,
                   32'h01000004, "jalr rs1+4");
        chk_target(`I_TYPE_JALR, 32'hdeadbeef, 32'h01000003, 32'd0,
                   32'h01000002, "jalr clears bit 0");

        // ---------- branch comparator ----------
        chk_br(`F3_BEQ,  32'd7, 32'd7, 1'b1, "beq equal");
        chk_br(`F3_BEQ,  32'd7, 32'd8, 1'b0, "beq not equal");
        chk_br(`F3_BNE,  32'd7, 32'd8, 1'b1, "bne differ");
        chk_br(`F3_BNE,  32'd7, 32'd7, 1'b0, "bne equal");
        chk_br(`F3_BLT,  32'hffffffff, 32'd1, 1'b1, "blt -1 < 1");
        chk_br(`F3_BLT,  32'd1, 32'hffffffff, 1'b0, "blt 1 < -1 false");
        chk_br(`F3_BLT,  32'd5, 32'd5, 1'b0, "blt equal false");
        chk_br(`F3_BGE,  32'd1, 32'hffffffff, 1'b1, "bge 1 >= -1");
        chk_br(`F3_BGE,  32'd5, 32'd5, 1'b1, "bge equal true");
        chk_br(`F3_BGE,  32'hffffffff, 32'd1, 1'b0, "bge -1 >= 1 false");
        chk_br(`F3_BLTU, 32'd1, 32'hffffffff, 1'b1, "bltu 1 < max");
        chk_br(`F3_BLTU, 32'hffffffff, 32'd1, 1'b0, "bltu max < 1 false");
        chk_br(`F3_BGEU, 32'hffffffff, 32'd1, 1'b1, "bgeu max >= 1");
        chk_br(`F3_BGEU, 32'd5, 32'd5, 1'b1, "bgeu equal true");
        chk_br(`F3_BGEU, 32'd1, 32'hffffffff, 1'b0, "bgeu 1 >= max false");

        // a non-branch opcode must never assert brtaken
        opcode = `R_TYPE; funct3 = `F3_BEQ; rs1 = 32'd7; rs2 = 32'd7; #1;
        if (brtaken === 1'b0) pass_count++;
        else begin
            fail_count++;
            $display("  FAIL brtaken asserted on non-branch opcode");
        end

        $display("alu_tb: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("ALU_TB: ALL PASS");
        else                 $display("ALU_TB: FAILURES");
        $finish;
    end

endmodule : alu_tb
