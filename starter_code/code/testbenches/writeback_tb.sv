`include "constants.svh"

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd50
`endif

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif

/*
 * writeback_tb: tests that each wbsel value picks its own source (all four
 * sources hold different values) and that pc + 4 wraps at the top of the
 * address space.
 */
module writeback_tb;

    logic clk = 0;
    logic rst = 1;
    always #1 clk = ~clk;

    localparam int DWIDTH = 32;
    localparam int AWIDTH = 32;

    // Signals for this testbench
    logic [AWIDTH-1:0] pc;         // source for WB_PC+4
    logic [DWIDTH-1:0] alu_res;    // source for WB_ALU
    logic [DWIDTH-1:0] mem_data;   // source for WB_MEM
    logic [DWIDTH-1:0] imm;        // source for WB_IMM
    logic [1:0]        wbsel;      // which source to pick
    logic [DWIDTH-1:0] wb_data;    // picked value

    writeback #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) hut (
        .pc_i(pc),
        .alu_res_i(alu_res),
        .memory_data_i(mem_data),
        .wbsel_i(wbsel),
        .imm_i(imm),
        .writeback_data_o(wb_data)
    );

    typedef struct {
        string       name;
        logic [31:0] pc, alu_res, mem_data, imm;
        logic [1:0]  wbsel;
        logic [31:0] exp_data;
    } test_t;

    test_t tests [$];        // list of all tests
    int number_of_tests;     // set once the list is built

    initial begin
        tests.push_back('{"WB_ALU picks the ALU result",'h0100_0010,  'hAAAA_AAAA,  'hBBBB_BBBB,  'hCCCC_C000,  `WB_ALU,  'hAAAA_AAAA});
        tests.push_back('{"WB_MEM picks the load data", 'h0100_0010,  'hAAAA_AAAA,  'hBBBB_BBBB,  'hCCCC_C000,  `WB_MEM,  'hBBBB_BBBB});
        tests.push_back('{"WB_PC4 picks pc + 4",        'h0100_0010,  'hAAAA_AAAA,  'hBBBB_BBBB,  'hCCCC_C000,  `WB_PC4,  'h0100_0014});
        tests.push_back('{"WB_IMM picks the immediate", 'h0100_0010,  'hAAAA_AAAA,  'hBBBB_BBBB,  'hCCCC_C000,  `WB_IMM,  'hCCCC_C000});
        tests.push_back('{"pc + 4 wraps around to 0",   'hFFFF_FFFC,  'hAAAA_AAAA,  'hBBBB_BBBB,  'hCCCC_C000,  `WB_PC4,  'h0000_0000});

        number_of_tests = tests.size();
    end

    int test_counter = 0;   // index of the next test to apply
    int passes = 0;         // tests whose outputs matched
    int fails  = 0;         // tests whose outputs did not

    always_ff @(posedge clk) begin
        if (rst) begin
            pc       <= '0;
            alu_res  <= '0;
            mem_data <= '0;
            imm      <= '0;
            wbsel    <= '0;
            test_counter <= 0;
        end
        else if (test_counter < number_of_tests) begin
            pc       <= tests[test_counter].pc;
            alu_res  <= tests[test_counter].alu_res;
            mem_data <= tests[test_counter].mem_data;
            imm      <= tests[test_counter].imm;
            wbsel    <= tests[test_counter].wbsel;
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
            if (wb_data === current.exp_data)
                passes++;
            else begin
                fails++;
                $display("  FAIL  %-28s wb_data=%08h (expected %08h)",
                         current.name, wb_data, current.exp_data);
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
        $dumpfile("writeback_tb.vcd");
        $dumpvars(0, writeback_tb);
        $system("date");
    end

endmodule : writeback_tb
