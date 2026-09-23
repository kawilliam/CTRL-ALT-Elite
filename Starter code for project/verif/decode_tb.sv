/*
 * Testbench: decode_tb
 *
 * Checks register-operand extraction (LH2) and the writeback mux (LH7).
 *
 * Formats that do not read a register must report register 0, otherwise the
 * stage-2 hazard logic will see phantom dependencies: lui/auipc/jal have no
 * rs1, and everything except R/S/B has no rs2.
 */
`include "constants.svh"

`timescale 1ns/1ps

module decode_tb;

    localparam int DWIDTH = 32;
    localparam int AWIDTH = 32;

    logic clk = 0;
    logic rst = 0;

    // ---------------- decode (LH2) ----------------
    logic [DWIDTH-1:0] insn;
    logic [AWIDTH-1:0] pc_in;
    logic [AWIDTH-1:0] pc_out;
    logic [DWIDTH-1:0] insn_out;
    logic [6:0]        opcode, funct7;
    logic [4:0]        rd, rs1, rs2, shamt;
    logic [2:0]        funct3;
    logic [DWIDTH-1:0] dec_imm;

    decode #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) hut (
        .clk(clk), .rst(rst),
        .insn_i(insn), .pc_i(pc_in),
        .pc_o(pc_out), .insn_o(insn_out),
        .opcode_o(opcode), .rd_o(rd), .rs1_o(rs1), .rs2_o(rs2),
        .funct7_o(funct7), .funct3_o(funct3),
        .shamt_o(shamt), .imm_o(dec_imm)
    );

    // ---------------- writeback (LH7) ----------------
    logic [AWIDTH-1:0] wb_pc;
    logic [DWIDTH-1:0] wb_alu, wb_mem, wb_imm, wb_out;
    logic [1:0]        wbsel;

    writeback #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) wb_hut (
        .pc_i(wb_pc),
        .alu_res_i(wb_alu),
        .memory_data_i(wb_mem),
        .wbsel_i(wbsel),
        .imm_i(wb_imm),
        .writeback_data_o(wb_out)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic chk_regs(input logic [31:0] i,
                            input logic [4:0]  exp_rd,
                            input logic [4:0]  exp_rs1,
                            input logic [4:0]  exp_rs2,
                            input string       label);
        begin
            insn = i; pc_in = 32'h01000000;
            #1;
            if (rd === exp_rd && rs1 === exp_rs1 && rs2 === exp_rs2) begin
                pass_count++;
            end
            else begin
                fail_count++;
                $display("  FAIL %-18s insn=%08h rd=%0d/%0d rs1=%0d/%0d rs2=%0d/%0d (got/want)",
                         label, i, rd, exp_rd, rs1, exp_rs1, rs2, exp_rs2);
            end
        end
    endtask

    task automatic chk_wb(input logic [1:0]  sel,
                          input logic [31:0] expected,
                          input string       label);
        begin
            wbsel = sel;
            #1;
            if (wb_out === expected) pass_count++;
            else begin
                fail_count++;
                $display("  FAIL %-18s got=%08h want=%08h", label, wb_out, expected);
            end
        end
    endtask

    initial begin
        $display("=========== decode_tb (LH2) + writeback (LH7) ===========");

        // add x15,x14,x15 : reads rs1 and rs2, writes rd
        chk_regs(32'h00f707b3, 5'd15, 5'd14, 5'd15, "add x15,x14,x15");
        // addi x2,x2,-32 : no rs2
        chk_regs(32'hfe010113, 5'd2,  5'd2,  5'd0,  "addi x2,x2,-32");
        // lw x14,12(x2) : no rs2
        chk_regs(32'h00c12703, 5'd14, 5'd2,  5'd0,  "lw x14,12(x2)");
        // sw x1,28(x2) : no rd, reads rs1 and rs2
        chk_regs(32'h00112e23, 5'd0,  5'd2,  5'd1,  "sw x1,28(x2)");
        // bne x14,x15 : no rd, reads rs1 and rs2
        chk_regs(32'h00f71863, 5'd0,  5'd14, 5'd15, "bne x14,x15");
        // lui x1 : no source registers at all
        chk_regs(32'hff0100b7, 5'd1,  5'd0,  5'd0,  "lui x1");
        // auipc x10 : no source registers (PC comes via the ALU mux)
        chk_regs(32'h00002517, 5'd10, 5'd0,  5'd0,  "auipc x10");
        // jal x1 : no source registers
        chk_regs(32'h018000ef, 5'd1,  5'd0,  5'd0,  "jal x1");
        // jalr x0,0(x1) : reads rs1 only
        chk_regs(32'h00008067, 5'd0,  5'd1,  5'd0,  "jalr x0,0(x1)");

        // ---------------- writeback mux ----------------
        wb_pc  = 32'h01000010;
        wb_alu = 32'haaaaaaaa;
        wb_mem = 32'hbbbbbbbb;
        wb_imm = 32'hcccccccc;
        chk_wb(`WB_ALU, 32'haaaaaaaa, "wbsel=ALU");
        chk_wb(`WB_MEM, 32'hbbbbbbbb, "wbsel=MEM");
        chk_wb(`WB_PC4, 32'h01000014, "wbsel=PC+4");
        chk_wb(`WB_IMM, 32'hcccccccc, "wbsel=IMM");

        $display("decode_tb: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("DECODE_TB: ALL PASS");
        else                 $display("DECODE_TB: FAILURES");
        $finish;
    end

endmodule : decode_tb
