`include "constants.svh"

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd10000
`endif

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif


module rv_official_tb;

   logic clk = 0;
   logic rst = 1;
   always #1 clk = ~clk;

   localparam int DWIDTH = 32;
   localparam int AWIDTH = 32;

   rv_core #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH)
   ) hut (
      .clk(clk),
      .reset(rst)
   );

   
reg is_program = 0;
   
logic [DWIDTH-1:0] first_test_register, second_test_register;

assign first_test_register  = hut.register_file1.x[3];
assign second_test_register = hut.register_file1.x[3];

   // Latency counters to delay checks until instructions reach Writeback
   int ecall_delay_cnt    = 0;
   int program_delay_cnt  = 0;
   localparam int PIPELINE_CYCLES = 5; // Adjust based on your pipeline depth

   always_ff @(negedge clk) begin
      // --- ECALL TRIGGER & DELAY ---
      if (hut.f_insn == 32'h00000073 && ecall_delay_cnt == 0) begin
         ecall_delay_cnt <= PIPELINE_CYCLES;
      end else if (ecall_delay_cnt > 1) begin
         ecall_delay_cnt <= ecall_delay_cnt - 1;
      end else if (ecall_delay_cnt == 1) begin
         ecall_delay_cnt <= 0;
         $display("========== Simulation Completed! ==========");
         if (first_test_register == 1) begin
            $display("Test Passed");
            print_metrics(); // Call the function to print metrics
         end else begin
            $display("Test Failed");
         end
         $display("========== Terminating Simulation due to ecall ==========");
         $finish;
      end

      // --- RET PROGRAM TRIGGER & DELAY ---
      if (hut.f_insn == 32'h00008067) is_program <= 1;

      if (is_program && (hut.register_file1.x[2] == 32'h01000000 + `MEM_DEPTH) && program_delay_cnt == 0) begin
         program_delay_cnt <= PIPELINE_CYCLES;
      end else if (program_delay_cnt > 1) begin
         program_delay_cnt <= program_delay_cnt - 1;
      end else if (program_delay_cnt == 1) begin
         program_delay_cnt <= 0;
         $display("========== Simulation Completed! ==========");
         if (second_test_register == 1) begin
            $display("Test Passed");
            print_metrics(); // Call the function to print metrics
         end else begin
            $display("Test Failed");
         end
         $display("========== Terminating Simulation due to program completion ==========");
         $finish;
      end
   end

   // Borrowed from clockgen.sv
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

   `ifdef HAS_STALL_SIGNAL
   `define GET_STALL (hut.stall)
   `else
      `define GET_STALL (0)
   `endif  
   `ifdef HAS_FLUSH_SIGNAL
      `define GET_FLUSH (hut.flush)
   `else
      `define GET_FLUSH (0)
   `endif

   int total_cycles = 0;
   int insn_exe = 0;
   int stalls = 0;
   int squashes = 0;
   real cpi = 0.0;

initial begin
      $dumpfile("top_tb.vcd");
      $dumpvars(0, top_tb);
      $system("date");
      wait (!rst);
      forever begin
         @(posedge clk);

         total_cycles++;
         if (hut.flush) begin
            squashes++;
         end
         else if (hut.stall) begin
            stalls++;
         end
         if (hut.wb_wb1.pc_i != '0) begin
            insn_exe++;
         end
      end
   end

   function automatic void print_metrics();

      // Calculate CPI after cycle sync
      if ((total_cycles - stalls - squashes) > 0) begin
         cpi = real'(total_cycles) / real'(insn_exe);
      end else begin
         cpi = 0.0;
      end

      $display("\n===========================================");
      $display("       PIPELINE PERFORMANCE METRICS       ");
      $display("===========================================");
      $display("Total Cycles : %0d", total_cycles);
      $display("Stalls       : %0d", stalls);
      $display("Squashes     : %0d", squashes);
      $display("Final CPI    : %0.2f", cpi);
      $display("===========================================\n");
   endfunction
endmodule: rv_official_tb

