`include "constants.svh"

`include "frontend_pkg.sv"

`include "pre_decode.sv"

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd10000
`endif 

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif


module pre_decode_tb;
  import frontend_pkg::*;

  logic clk = 0;
  logic rst = 1;
  always #1 clk = ~clk;

  localparam int DWIDTH = 32;
  localparam int AWIDTH = 32;
  localparam logic [31:0] PC = 'h0100_0000;
  localparam logic [31:0] RA = 'h0100_0004;
  localparam logic [6:0] OP_JAL_NEIGHBOUR = 7'b1101110; // JAL is 1101111
  localparam logic [6:0] OP_SYSTEM        = 7'b1110011;  // ecall / ebreak

  // Signals

  // Inputs
  logic [DWIDTH-1:0] insn_i;
  logic [AWIDTH-1:0] pc_i;
  logic              is_insn_i;
  // Outputs
  logic [AWIDTH-1:0] target_o;
  logic [AWIDTH-1:0] ra_o;
  cfi_t              cfit_o;
  logic              is_call_o;
  logic              is_ret_o;
  logic              is_redir_o;

  pre_decode #(
      .AWIDTH(32),
      .DWIDTH(32)
  ) hut (
    .insn_i(insn_i),
    .pc_i(pc_i),
    .is_insn_i(is_insn_i),
    .target_o(target_o),
    .ra_o(ra_o),
    .cfit_o(cfit_o),
    .is_call_o(is_call_o),
    .is_ret_o(is_ret_o),
    .is_redir_o(is_redir_o)
  );

  typedef struct {
    string             name;
    logic [DWIDTH-1:0] insn_i;
    logic [AWIDTH-1:0] pc_i;
    logic              is_insn_i;
    logic [AWIDTH-1:0] exp_target_o;
    logic [AWIDTH-1:0] exp_ra_o;
    cfi_t              exp_cfit_o;
    logic              exp_is_call_o;
    logic              exp_is_ret_o;
    logic              exp_is_redir_o;
  } test_t;

  // J-type
  function automatic logic [31:0] make_jal(input logic [4:0] rd, input logic [31:0] imm);
    logic [31:0] i = {25'd0, `J_TYPE};
    i[11:7] = rd;
    i[31] = imm[20];
    i[30:21] = imm[10:1];
    i[20] = imm[11];
    i[19:12] = imm[19:12];
    return i;
  endfunction

  // I-type
  function automatic logic [31:0] make_jalr(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm);
    logic [31:0] i = {25'd0, `I_TYPE_JALR};
    i[11:7] = rd;
    i[19:15] = rs1;
    i[31:20] = imm;
    return i;
  endfunction

  // B-type
  function automatic logic [31:0] make_branch(input logic [2:0] funct3, input logic [4:0] rs1, input logic [4:0] rs2, input logic [31:0] imm);
    logic [31:0] i = {25'd0, `B_TYPE};
    i[14:12] = funct3;
    i[19:15] = rs1;
    i[24:20] = rs2;
    i[31] = imm[12];
    i[30:25] = imm[10:5];
    i[11:8] = imm[4:1];
    i[7] = imm[11];
    return i;
  endfunction

  function automatic logic [31:0] with_opcode(input logic [31:0] word, input logic [6:0] op);
    return {word[31:7], op};
  endfunction
  
  test_t tests [$];
  int number_of_tests;

  initial begin
    // Valid Instructions
    tests.push_back('{
      "JAL but is_insn=0: all zero",
      make_jal(5'd1, 32'd8), PC, 1'b0,
      32'd0, 32'd0, CFI_NONE, 1'b0, 1'b0, 1'b0
    });

    tests.push_back('{
      "JALR but is_insn=0: all zero",
      make_jalr(5'd0, 5'd1, 12'd0), PC, 1'b0,
      32'd0, 32'd0, CFI_NONE, 1'b0, 1'b0, 1'b0
    });

    tests.push_back('{
      "NOP but is_insn=0: all zero",
      'h0000_0013, PC, 1'b0,
      32'd0, 32'd0, CFI_NONE, 1'b0, 1'b0, 1'b0
    });

    tests.push_back('{
      "BEQ but is_insn=0: all zero",
      make_branch(`F3_BEQ, 5'd6, 5'd7, 32'd8), PC, 1'b0,
      32'd0, 32'd0, CFI_NONE, 1'b0, 1'b0, 1'b0
    });

    // Non-CFI Instructions
    tests.push_back('{
      "NOP",
      'h0000_0013, PC, 1'b1,
      32'd0, RA, CFI_NONE, 1'b0, 1'b0, 1'b0
      });

    tests.push_back('{
      "add x1, x2, x3",
      'h0031_00B3, PC, 1'b1,
      32'd0, RA, CFI_NONE, 1'b0, 1'b0, 1'b0
      });

    tests.push_back('{
      "lw x1, 0(x2)",
      'h0001_2083, PC, 1'b1,
      32'd0, RA, CFI_NONE, 1'b0, 1'b0, 1'b0
      });

    tests.push_back('{
      "all ones",
      'hFFFF_FFFF, PC, 1'b1,
      32'd0, RA, CFI_NONE, 1'b0, 1'b0, 1'b0
      });

    tests.push_back('{
      "all zeros",
      'h0000_0000, PC, 1'b1,
      32'd0, RA, CFI_NONE, 1'b0, 1'b0, 1'b0
      });

    // JAL Target Calculation
    tests.push_back('{
      "JAL x5, +2048",
      make_jal(5'd5, 32'd2048), PC, 1'b1,
      PC + 32'd2048, RA, CFI_JAL, 1'b1, 1'b0, 1'b1
      });
    
    tests.push_back('{
      "JAL x1, -8",
      make_jal(5'd1, -32'd8), PC, 1'b1,
      PC - 32'd8, RA, CFI_JAL, 1'b1, 1'b0, 1'b1
      });

    tests.push_back('{
      "JAL x1, -1048576",
      make_jal(5'd1, -32'd1048576), PC, 1'b1,
      PC - 32'd1048576, RA, CFI_JAL, 1'b1, 1'b0, 1'b1
      });

    tests.push_back('{
      "JAL x0, +8",
      make_jal(5'd0, 32'd8), PC, 1'b1,
      PC + 32'd8, RA, CFI_JAL, 1'b0, 1'b0, 1'b1
      });

    tests.push_back('{
      "JAL x0, 0",
      make_jal(5'd0, 32'd0), PC, 1'b1,
      PC, RA, CFI_JAL, 1'b0, 1'b0, 1'b1
      });

    tests.push_back('{
      "JAL x6, +8 at high pc",
      make_jal(5'd6, 32'd8), 'h0100_0100, 1'b1,
      'h0100_0100 + 32'd8, 'h0100_0100 + 32'd4, CFI_JAL, 1'b0, 1'b0, 1'b1
      });

    tests.push_back('{
      "JAL x2, +8",
      make_jal(5'd2, 32'd8), PC, 1'b1,
      PC + 32'd8, RA, CFI_JAL, 1'b0, 1'b0, 1'b1
      });

    tests.push_back('{
      "JAL x0, +8 at FFFF_FFFC",
      make_jal(5'd0, 32'd8), 'hFFFF_FFFC, 1'b1,
      'h0000_0004, 'h0000_0000, CFI_JAL, 1'b0, 1'b0, 1'b1
      });

    // JALR Instructions
    tests.push_back('{
      "JALR x0, 0(x1)",
      make_jalr(5'd0, 5'd1, 12'd0), PC, 1'b1,
      32'd0, RA, CFI_JALR, 1'b0, 1'b1, 1'b0
      });

    tests.push_back('{
      "JALR x0, 0(x5)",
      make_jalr(5'd0, 5'd5, 12'd0), PC, 1'b1,
      32'd0, RA, CFI_JALR, 1'b0, 1'b1, 1'b0
      });

    tests.push_back('{
      "JALR x0, 0(x6)",
      make_jalr(5'd0, 5'd6, 12'd0), PC, 1'b1,
      32'd0, RA, CFI_JALR, 1'b0, 1'b0, 1'b0
      });

    tests.push_back('{
      "JALR x1, 4(x6)",
      make_jalr(5'd1, 5'd6, 12'd4), PC, 1'b1,
      32'd0, RA, CFI_JALR, 1'b1, 1'b0, 1'b0
      });

    tests.push_back('{
      "JALR x5, 4(x6)",
      make_jalr(5'd5, 5'd6, 12'd4), PC, 1'b1,
      32'd0, RA, CFI_JALR, 1'b1, 1'b0, 1'b0
      });

    // Branch Instructions
    tests.push_back('{
      "BEQ x6, x7, +8",
      make_branch(`F3_BEQ, 5'd6, 5'd7, 32'd8), PC, 1'b1,
      PC + 32'd8, RA, CFI_BRANCH, 1'b0, 1'b0, 1'b0
    });

    tests.push_back('{
      "BNE x6, x7, -8",
      make_branch(`F3_BNE, 5'd6, 5'd7, -32'd8), PC, 1'b1,
      PC - 32'd8, RA, CFI_BRANCH, 1'b0, 1'b0, 1'b0
    });

    tests.push_back('{
      "BLT x6, x7, 0",
      make_branch(`F3_BLT, 5'd6, 5'd7, 32'd0), PC, 1'b1,
      PC, RA, CFI_BRANCH, 1'b0, 1'b0, 1'b0
    });

    // Reserved encodings
    tests.push_back('{
      "Neighbour to jal insn",
      with_opcode(make_jal(5'd1, 32'd8), OP_JAL_NEIGHBOUR), PC, 1'b1,
      32'd0, RA, CFI_NONE, 1'b0, 1'b0, 1'b0
      });

    tests.push_back('{
      "ecall",
      with_opcode(32'h0, OP_SYSTEM), PC, 1'b1,
      32'd0, RA, CFI_NONE, 1'b0, 1'b0, 1'b0
      });


    number_of_tests = tests.size();

  end

  int test_counter = 0;
  int passes = 0;
  int fails = 0;

  always_ff @(posedge clk) begin
    if (rst) begin
      insn_i      <= '0;
      pc_i        <= '0;
      is_insn_i   <= '0;
      test_counter <= 0;
    end
    else if (test_counter < number_of_tests) begin
      insn_i <= tests[test_counter].insn_i;
      pc_i <= tests[test_counter].pc_i;
      is_insn_i <= tests[test_counter].is_insn_i;
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

  // On each falling edge, compare the predecode outputs with the test
  test_t current;
  always @(negedge clk) begin
      if (!rst && test_counter > 0) begin
          current = tests[test_counter - 1];
          if (target_o === current.exp_target_o 
              && ra_o === current.exp_ra_o 
              && cfit_o === current.exp_cfit_o 
              && is_call_o === current.exp_is_call_o 
              && is_ret_o === current.exp_is_ret_o 
              && is_redir_o === current.exp_is_redir_o)
              passes++;
          else begin
              fails++;
              $display("  FAIL  %-34s target_o=%08h (expected %08h)  ra_o=%08h (expected %08h) cfit_o=%0b (expected %0b) is_call_o=%0b (expected %0b) is_ret_o=%0b (expected %0b) is_redir_o=%0b (expected %0b)",
                        current.name, target_o, current.exp_target_o, ra_o, current.exp_ra_o, cfit_o, current.exp_cfit_o, is_call_o, current.exp_is_call_o, is_ret_o, current.exp_is_ret_o, is_redir_o, current.exp_is_redir_o);
          end
      end
  end

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

  initial begin
    $dumpfile("pre_decode_tb.vcd");
    $dumpvars(0, pre_decode_tb);
    $system("date");
  end

endmodule: pre_decode_tb
