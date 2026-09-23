/*
 * Testbench: igen_tb
 *
 * Checks the immediate generator (LH3) against real instruction encodings
 * taken from the objdump listings in verif/tests/. Every expected value was
 * derived from the RISC-V spec by hand; the branch/jump vectors are further
 * cross-checked against the target addresses printed by objdump, e.g.
 *   1000098: fe5214e3  bne x4,x5,1000080   ->  0x1000080 - 0x1000098 = -24
 */
`include "constants.svh"

`timescale 1ns/1ps

module igen_tb;

    localparam int DWIDTH = 32;

    logic [6:0]        opcode;
    logic [DWIDTH-1:0] insn;
    logic [DWIDTH-1:0] imm;

    igen #(.DWIDTH(DWIDTH)) hut (
        .opcode_i(opcode),
        .insn_i(insn),
        .imm_o(imm)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic chk(input logic [31:0] i,
                       input logic [31:0] expected,
                       input string       label);
        begin
            insn   = i;
            opcode = i[6:0];
            #1;
            if (imm === expected) begin
                pass_count++;
            end
            else begin
                fail_count++;
                $display("  FAIL %-20s insn=%08h got=%08h want=%08h",
                         label, i, imm, expected);
            end
        end
    endtask

    initial begin
        $display("=========== igen_tb (LH3) ===========");

        // ---- I-type arithmetic: 12-bit sign-extended ----
        chk(32'hfe010113, 32'hffffffe0, "addi -32");
        chk(32'h02010113, 32'h00000020, "addi +32");
        chk(32'h00300793, 32'h00000003, "addi +3");
        chk(32'h0000af13, 32'h00000000, "slti 0");

        // ---- I-type shifts: low 5 bits must equal shamt ----
        chk(32'h00119193, 32'h00000001, "slli shamt=1");
        chk(32'h4010df13, 32'h00000401, "srai shamt=1");

        // ---- I-type loads ----
        chk(32'h00c12703, 32'h0000000c, "lw +12");
        chk(32'h01c12083, 32'h0000001c, "lw +28");

        // ---- jalr ----
        chk(32'h00008067, 32'h00000000, "jalr 0");

        // ---- S-type: imm split across [31:25] and [11:7] ----
        chk(32'h00112e23, 32'h0000001c, "sw +28");
        chk(32'h00f12623, 32'h0000000c, "sw +12");
        chk(32'h00012223, 32'h00000004, "sw +4");

        // ---- B-type: 13-bit, bit 0 implicit 0 ----
        chk(32'h00f71863, 32'h00000010, "bne +16");
        chk(32'hfe5214e3, 32'hffffffe8, "bne -24");
        chk(32'h1bdf1463, 32'h000001a8, "bne +424");

        // ---- U-type: upper 20 bits, no sign extension ----
        chk(32'hff0100b7, 32'hff010000, "lui 0xff010");
        chk(32'h00002517, 32'h00002000, "auipc 0x2");
        chk(32'hffffe517, 32'hffffe000, "auipc 0xffffe");

        // ---- J-type: 21-bit, bit 0 implicit 0 ----
        chk(32'h018000ef, 32'h00000018, "jal +24");
        chk(32'h00c0006f, 32'h0000000c, "jal +12");

        $display("igen_tb: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("IGEN_TB: ALL PASS");
        else                 $display("IGEN_TB: FAILURES");
        $finish;
    end

endmodule : igen_tb
