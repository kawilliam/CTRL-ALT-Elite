`include "constants.svh"

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd50
`endif

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif

/*
 * pipeline_regs_tb: tests the four pipeline registers F/D, D/X, X/M and
 * M/WB; reset, normal pass-through, stall (F/D holds, D/X becomes a bubble),
 * flush (F/D and D/X become bubbles).
 * Each row's reset is applied on the falling edge, half a cycle after its
 * other inputs, so the row before it is checked before an asynchronous
 * reset clears the registers.
 */
module pipeline_blocks_tb;

    logic clk = 0;
    logic rst = 1;
    always #1 clk = ~clk;

    localparam int DWIDTH = 32;
    localparam int AWIDTH = 32;
    localparam logic [63:0] FD_BUBBLE = {32'd0, `NOP};   // F/D bubble: pc 0 and a nop

    // D/X control-bit patterns. Bit i is set in pattern j when bit j of (i+1)
    // is set, so across these four patterns every control bit has its own
    // on/off sequence: if two control wires were swapped, the outputs differ.
    localparam logic [12:0] CTRL_PATTERNS [4] = '{13'h1555, 13'h0666, 13'h1878, 13'h1F80};

    // Signals for this testbench
    logic p_rst;    // reset for all four registers
    logic stall;    // F/D hold, D/X bubble
    logic flush;    // F/D and D/X bubble

    // F/D:  {pc, insn}
    logic [63:0]  fd_in,  fd_out;
    // D/X:  {pc, imm, rs1 data, rs2 data, opcode, funct3, funct7, rd, rs1, rs2, control}
    logic [172:0] dx_in,  dx_out;
    // X/M:  {pc, rs2 data, funct3, rd, rs2, alu result, control, imm}
    logic [153:0] xm_in,  xm_out;
    // M/WB: {pc, alu result, memory data, rd, imm, control}
    logic [145:0] mw_in,  mw_out;
    // D/X control inputs, connected through the bit positions named in constants.svh
    wire  [12:0]  ctrl = dx_in[12:0];

    fd_reg #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) fd (
        .clk(clk), .rst(p_rst), .flush_i(flush), .stall_i(stall),
        .pc_i(fd_in[63:32]),  .insn_i(fd_in[31:0]),
        .pc_o(fd_out[63:32]), .insn_o(fd_out[31:0]));

    dx_reg #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) dx (
        .clk(clk), .rst(p_rst), .flush_i(flush), .stall_i(stall),
        .pc_i(dx_in[172:141]),     .imm_i(dx_in[140:109]),    .rs1data_i(dx_in[108:77]),
        .rs2data_i(dx_in[76:45]),  .opcode_i(dx_in[44:38]),   .funct3_i(dx_in[37:35]),
        .funct7_i(dx_in[34:28]),   .rd_i(dx_in[27:23]),       .rs1_i(dx_in[22:18]),
        .rs2_i(dx_in[17:13]),
        .pcsel_i(ctrl[`PCSEL]),    .immsel_i(ctrl[`IMMSEL]),  .regwren_i(ctrl[`REGWREN]),
        .rs1sel_i(ctrl[`RS1SEL]),  .rs2sel_i(ctrl[`RS2SEL]),  .memren_i(ctrl[`MEMREN]),
        .memwren_i(ctrl[`MEMWREN]),.wbsel_i(ctrl[`WBSEL]),    .alusel_i(ctrl[`ALUSEL]),
        .pc_o(dx_out[172:141]),    .imm_o(dx_out[140:109]),   .rs1data_o(dx_out[108:77]),
        .rs2data_o(dx_out[76:45]), .opcode_o(dx_out[44:38]),  .funct3_o(dx_out[37:35]),
        .funct7_o(dx_out[34:28]),  .rd_o(dx_out[27:23]),      .rs1_o(dx_out[22:18]),
        .rs2_o(dx_out[17:13]),     .ctrl_reg_o(dx_out[12:0]));

    xm_reg #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) xm (
        .clk(clk), .rst(p_rst),
        .pc_i(xm_in[153:122]),  .rs2data_i(xm_in[121:90]),  .funct3_i(xm_in[89:87]),
        .rd_i(xm_in[86:82]),    .rs2_i(xm_in[81:77]),       .alu_res_i(xm_in[76:45]),
        .ctrl_reg_i(xm_in[44:32]), .imm_i(xm_in[31:0]),
        .pc_o(xm_out[153:122]), .rs2data_o(xm_out[121:90]), .funct3_o(xm_out[89:87]),
        .rd_o(xm_out[86:82]),   .rs2_o(xm_out[81:77]),      .alu_res_o(xm_out[76:45]),
        .ctrl_reg_o(xm_out[44:32]), .imm_o(xm_out[31:0]));

    mwb_reg #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) mw (
        .clk(clk), .rst(p_rst),
        .pc_i(mw_in[145:114]),  .alu_res_i(mw_in[113:82]),  .mdata_i(mw_in[81:50]),
        .rd_i(mw_in[49:45]),    .imm_i(mw_in[44:13]),       .ctrl_reg_i(mw_in[12:0]),
        .pc_o(mw_out[145:114]), .alu_res_o(mw_out[113:82]), .mdata_o(mw_out[81:50]),
        .rd_o(mw_out[49:45]),   .imm_o(mw_out[44:13]),      .ctrl_reg_o(mw_out[12:0]));

    // ------------------------------------------------------------------
    // The tests: each row holds the controls and what each register should do
    // ------------------------------------------------------------------
    typedef enum {PASS, HOLD, BUBBLE} expect_e;

    typedef struct {
        string   name;
        logic    rst, stall, flush;
        expect_e fd, dx, xm_mw;     // expected behaviour of F/D, D/X, and X/M + M/WB
    } test_t;

    test_t tests [$];        // list of all tests
    int number_of_tests;     // set once the list is built

    initial begin
        tests.push_back('{"reset clears everything",          1,  0,    0,      BUBBLE, BUBBLE, BUBBLE});
        tests.push_back('{"pass-through",                     0,  0,    0,      PASS,   PASS,   PASS});
        tests.push_back('{"pass-through",                     0,  0,    0,      PASS,   PASS,   PASS});
        tests.push_back('{"pass-through",                     0,  0,    0,      PASS,   PASS,   PASS});
        tests.push_back('{"stall: F/D holds, D/X bubbles",    0,  1,    0,      HOLD,   BUBBLE, PASS});
        tests.push_back('{"flush: F/D and D/X bubble",        0,  0,    1,      BUBBLE, BUBBLE, PASS});
        tests.push_back('{"pass-through (real contents)",     0,  0,    0,      PASS,   PASS,   PASS});
        tests.push_back('{"flush+stall: squash, not hold",    0,  1,    1,      BUBBLE, BUBBLE, PASS});
        tests.push_back('{"pass-through (real contents)",     0,  0,    0,      PASS,   PASS,   PASS});
        tests.push_back('{"reset+stall: reset wins",          1,  1,    0,      BUBBLE, BUBBLE, BUBBLE});

        number_of_tests = tests.size();
    end

    always_ff @(negedge clk) begin
        if (rst)
            p_rst <= 1;
        else if (test_counter >= 1 && test_counter <= number_of_tests)
            p_rst <= tests[test_counter - 1].rst;
        else
            p_rst <= 0;
    end

    // ------------------------------------------------------------------
    // Stimulus: on each rising edge, drive the next row's controls and new
    // random data. One extra idle cycle at the end lets the last row be
    // clocked in and checked.
    // ------------------------------------------------------------------
    int test_counter = 0;   // index of the next test to apply
    int passes = 0;         // checks that matched
    int fails  = 0;         // checks that did not

    always_ff @(posedge clk) begin
        if (rst) begin
            stall <= 0;
            flush <= 0;
            fd_in <= '0;
            dx_in <= '0;
            xm_in <= '0;
            mw_in <= '0;
            test_counter <= 0;
        end
        else if (test_counter <= number_of_tests) begin
            if (test_counter < number_of_tests) begin
                stall <= tests[test_counter].stall;
                flush <= tests[test_counter].flush;
            end
            else begin
                stall <= 0;
                flush <= 0;
            end
            fd_in <= {$urandom, $urandom};
            dx_in <= {160'({$urandom, $urandom, $urandom, $urandom, $urandom}),
                      CTRL_PATTERNS[test_counter % 4]};
            xm_in <= 154'({$urandom, $urandom, $urandom, $urandom, $urandom});
            mw_in <= 146'({$urandom, $urandom, $urandom, $urandom, $urandom});
            test_counter <= test_counter + 1;
        end
        else begin
            $display("=========================================");
            $display("Completed %0d Tests. Simulation Complete!", number_of_tests);
            if (fails == 0)
                $display("Test Passed  (%0d checks)", passes);
            else
                $display("Test Failed  (%0d of %0d checks failed)", fails, passes + fails);
            $display("=========================================");
            $finish;
        end
    end

    // ------------------------------------------------------------------
    // Check: on each falling edge, check the row the registers just clocked
    // in (tests[test_counter - 2]). The expected values come from copies
    // saved on the previous falling edge: the inputs that were then waiting
    // to be clocked in, and the register contents before that edge.
    // ------------------------------------------------------------------
    logic [63:0]  fd_in_before, fd_out_before;   // saved one cycle earlier
    logic [172:0] dx_in_before;
    logic [153:0] xm_in_before;
    logic [145:0] mw_in_before;
    logic [63:0]  exp_fd;                        // expected outputs for this row
    logic [172:0] exp_dx;
    logic [299:0] exp_xm_mw;
    test_t        current;                       // the test being checked

    always @(negedge clk) begin
        if (!rst) begin
            if (test_counter >= 2) begin
                current = tests[test_counter - 2];

                if (current.fd == PASS)       exp_fd = fd_in_before;
                else if (current.fd == HOLD)  exp_fd = fd_out_before;
                else                          exp_fd = FD_BUBBLE;

                if (current.dx == PASS)       exp_dx = dx_in_before;
                else                          exp_dx = '0;

                if (current.xm_mw == PASS)    exp_xm_mw = {xm_in_before, mw_in_before};
                else                          exp_xm_mw = '0;

                if (fd_out === exp_fd) passes++;
                else begin
                    fails++;
                    $display("  FAIL  %-32s F/D  = %0h (expected %0h)", current.name, fd_out, exp_fd);
                end
                if (dx_out === exp_dx) passes++;
                else begin
                    fails++;
                    $display("  FAIL  %-32s D/X  = %0h (expected %0h)", current.name, dx_out, exp_dx);
                end
                if ({xm_out, mw_out} === exp_xm_mw) passes++;
                else begin
                    fails++;
                    $display("  FAIL  %-32s X/M, M/WB = %0h (expected %0h)", current.name, {xm_out, mw_out}, exp_xm_mw);
                end
            end

            // Save for the next falling edge
            fd_in_before  = fd_in;
            fd_out_before = fd_out;
            dx_in_before  = dx_in;
            xm_in_before  = xm_in;
            mw_in_before  = mw_in;
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
        $dumpfile("pipeline_regs_tb.vcd");
        $dumpvars(0, pipeline_regs_tb);
        $system("date");
    end

endmodule : pipeline_blocks_tb
