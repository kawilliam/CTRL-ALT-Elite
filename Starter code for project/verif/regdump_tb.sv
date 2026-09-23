/*
 * Testbench: regdump_tb
 *
 * Runs a whole program on rv_core and prints the architectural register file
 * when the ecall is reached. Used to check the pipeline_tests programs, which
 * top_tb cannot grade: top_tb only passes when x1 == 1, and none of those
 * programs ever set x1 to 1 (5-stage-pipeline sets it to 10), so they report
 * "Test Failed" no matter how the core behaves.
 *
 * The program is selected at run time:
 *   ./Vregdump_tb +MEM_PATH=<path to .x>
 */
`include "constants.svh"
// rv_core instantiates `alu`, which lives in execute.sv under a different name,
// so Verilator's -y module search cannot find it. Include it explicitly.
`include "execute.sv"

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd4000
`endif

module regdump_tb;

    logic clk = 0;
    logic rst = 1;
    always #1 clk = ~clk;

    rv_core #(.AWIDTH(32), .DWIDTH(32)) hut (
        .clk(clk),
        .reset(rst),
        .busy()
    );

    int counter  = 0;
    bit finished = 0;

    always_ff @(posedge clk) begin
        counter <= counter + 1;
        if (counter < 2) rst <= 1;
        else             rst <= 0;
        if (counter >= `TIMEOUT) begin
            $display("REGDUMP_TIMEOUT");
            $finish;
        end
    end

    // In this single-cycle core every earlier instruction has already written
    // back by the time ecall is the instruction being fetched, so the register
    // file is settled here.
    always_ff @(negedge clk) begin
        if (!rst && !finished && hut.f_insn == 32'h00000073) begin
            finished <= 1;
            $display("REGDUMP_BEGIN cycles=%0d", counter);
            for (int i = 0; i < 8; i++) begin
                $display("x%0d=%08h", i, hut.register_file1.x[i]);
            end
            $display("REGDUMP_END");
            $finish;
        end
    end

endmodule : regdump_tb
