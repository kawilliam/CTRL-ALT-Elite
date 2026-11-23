`include "constants.svh"

`include "fuse_detect.sv"

`timescale 1ns/1ps

`ifndef TIMEOUT
  `define TIMEOUT 32'd10000
`endif

`ifndef RESET_CYCLES
  `define RESET_CYCLES 2
`endif

// Golden-model testbench for fuse_detect (Experiment 4, v1 rule).
//
// The DUT is purely combinational: it packs two adjacent words or it does not.
// It never sees a register *value*, so no row here asserts taken / not-taken --
// that decision belongs to execute, where the operands live.
//
// Expectations are computed from the INTENDED operands in each row (pc + 4 + imm),
// never by re-decoding the word the DUT is given. If the test derived its target
// with the DUT's own bit-slicing, a layout bug would cancel on both sides and every
// row would pass.
module fuse_detect_tb;

  logic clk = 0;
  logic rst = 1;
  always #1 clk = ~clk;

  localparam int DWIDTH = 32;
  localparam int AWIDTH = 32;
  localparam logic [31:0] PC = 'h0100_0000;

  localparam logic [6:0] OP_IMM    = 7'b0010_011;   // addi / slti / ...
  localparam logic [6:0] OP_RTYPE  = 7'b0110_011;   // add / sub / ...
  localparam logic [6:0] OP_BRANCH = 7'b1100_011;   // beq / bne / ...

  localparam logic [2:0] F3_ADDI = 3'b000;
  localparam logic [2:0] F3_SLTI = 3'b010;
  localparam logic [2:0] F3_BEQ  = 3'b000;
  localparam logic [2:0] F3_BNE  = 3'b001;
  localparam logic [2:0] F3_BLT  = 3'b100;
  localparam logic [2:0] F3_BGE  = 3'b101;
  localparam logic [2:0] F3_BLTU = 3'b110;

  // Inputs
  logic [DWIDTH-1:0] insn_a_i;
  logic [DWIDTH-1:0] insn_b_i;
  logic [AWIDTH-1:0] pc_i;
  logic              is_insn_i;
  // Outputs
  logic              fused_o;
  logic              stride8_o;
  logic [4:0]        rs2_o;
  logic [2:0]        br_funct3_o;
  logic [AWIDTH-1:0] br_target_o;
  logic [AWIDTH-1:0] br_imm_o;
  logic              t_first_o;

  fuse_detect #(
      .AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH)
  ) dut (
    .insn_a_i(insn_a_i),
    .insn_b_i(insn_b_i),
    .pc_i(pc_i),
    .is_insn_i(is_insn_i),
    .fused_o(fused_o),
    .stride8_o(stride8_o),
    .rs2_o(rs2_o),
    .br_funct3_o(br_funct3_o),
    .br_target_o(br_target_o),
    .br_imm_o(br_imm_o),
    .t_first_o(t_first_o)
  );

  // ---------------------------------------------------------------- encoders
  // I-type, funct3 selectable so slti/andi/xori can be built from the same shape
  function automatic logic [31:0] make_itype(input logic [2:0] funct3,
                                            input logic [4:0] rd,
                                            input logic [4:0] rs1,
                                            input logic [11:0] imm);
    logic [31:0] i = {25'd0, OP_IMM};
    i[14:12] = funct3;
    i[11:7]  = rd;
    i[19:15] = rs1;
    i[31:20] = imm;
    return i;
  endfunction

  function automatic logic [31:0] make_addi(input logic [4:0] rd,
                                            input logic [4:0] rs1,
                                            input logic [11:0] imm);
    return make_itype(F3_ADDI, rd, rs1, imm);
  endfunction

  // R-type, for "word A is add, not addi" rows
  function automatic logic [31:0] make_rtype(input logic [4:0] rd,
                                            input logic [4:0] rs1,
                                            input logic [4:0] rs2);
    logic [31:0] i = {25'd0, OP_RTYPE};
    i[11:7]  = rd;
    i[19:15] = rs1;
    i[24:20] = rs2;
    return i;
  endfunction

  // B-type
  function automatic logic [31:0] make_branch(input logic [2:0] funct3,
                                             input logic [4:0] rs1,
                                             input logic [4:0] rs2,
                                             input logic [12:0] imm);
    logic [31:0] i = {25'd0, OP_BRANCH};
    i[14:12] = funct3;
    i[19:15] = rs1;
    i[24:20] = rs2;
    i[31]    = imm[12];
    i[30:25] = imm[10:5];
    i[11:8]  = imm[4:1];
    i[7]     = imm[11];
    return i;
  endfunction

  // A second base address: no row may pass while pc_i is unread.
  localparam logic [31:0] ALT_PC = 'h0100_0100;

  // -8 exists in two widths -- the 13-bit B-type field that is encoded, and the
  // 32-bit sign-extended value that is compared. Naming both stops an edit from
  // fixing one and silently breaking the other.
  localparam logic [12:0] BR_NEG8 = -13'sd8;   // -8 as encoded in the B immediate
  localparam logic [31:0] NEG8    = -32'sd8;   // -8 sign-extended, as compared
  localparam logic [31:0] FWD8    = 32'd8;

  // ---------------------------------------------------------------- rows
  typedef struct {
    string       name;
    logic [31:0] insn_a;
    logic [31:0] insn_b;
    logic [31:0] pc;
    logic        is_insn;
    logic        exp_fused;
    logic        exp_stride8;
    logic [4:0]  exp_rs2;
    logic [2:0]  exp_funct3;
    logic [31:0] exp_target;
    logic [31:0] exp_imm;
    logic        exp_t_first;  // defaults to 0 for the reject rows
  } test_t;

  test_t tests [$];
  int    number_of_tests;

  initial begin
    // ---- rejections (contract table rows 1-7) -----------------------------
    tests.push_back('{
      "is_insn=0: perfect pair, all outputs zero",
      make_addi(5'd1, 5'd1, 12'hFFF), make_branch(F3_BNE, 5'd1, 5'd0, BR_NEG8), PC, 1'b0,
      1'b0, 1'b0, 5'd0, 3'd0, 32'd0, 32'd0, 1'b0
    });

    tests.push_back('{
      "word A is add (R-type): reject",
      make_rtype(5'd1, 5'd2, 5'd3), make_branch(F3_BNE, 5'd1, 5'd0, BR_NEG8), PC, 1'b1,
      1'b0, 1'b0, 5'd0, 3'd0, 32'd0, 32'd0, 1'b0
    });

    tests.push_back('{
      "word A is slti (funct3=010): reject",
      make_itype(F3_SLTI, 5'd1, 5'd1, 12'hFFF), make_branch(F3_BNE, 5'd1, 5'd0, BR_NEG8), PC, 1'b1,
      1'b0, 1'b0, 5'd0, 3'd0, 32'd0, 32'd0, 1'b0
    });

    tests.push_back('{
      "word A addi rd=x0: reject",
      make_addi(5'd0, 5'd1, 12'hFFF), make_branch(F3_BNE, 5'd0, 5'd0, BR_NEG8), PC, 1'b1,
      1'b0, 1'b0, 5'd0, 3'd0, 32'd0, 32'd0, 1'b0
    });

    tests.push_back('{
      "word B is add, not a branch: reject",
      make_addi(5'd1, 5'd1, 12'hFFF), make_rtype(5'd2, 5'd1, 5'd3), PC, 1'b1,
      1'b0, 1'b0, 5'd0, 3'd0, 32'd0, 32'd0, 1'b0
    });

    tests.push_back('{
      "word B branch funct3=010 (invalid): reject",
      make_addi(5'd1, 5'd1, 12'hFFF), make_branch(3'b010, 5'd1, 5'd0, BR_NEG8), PC, 1'b1,
      1'b0, 1'b0, 5'd0, 3'd0, 32'd0, 32'd0, 1'b0
    });

    tests.push_back('{
      "branch rs1 != addi rd: reject",
      make_addi(5'd1, 5'd1, 12'hFFF), make_branch(F3_BNE, 5'd4, 5'd0, BR_NEG8), PC, 1'b1,
      1'b0, 1'b0, 5'd0, 3'd0, 32'd0, 32'd0, 1'b0
    });

    // ---- acceptances ------------------------------------------------------
    tests.push_back('{
      "accept addi x1,x1,-1 / bne x1,x0,-8",
      make_addi(5'd1, 5'd1, 12'hFFF), make_branch(F3_BNE, 5'd1, 5'd0, BR_NEG8), PC, 1'b1,
      1'b1, 1'b1, 5'd0, F3_BNE, PC + 32'd4 + NEG8, NEG8, 1'b1
    });

    tests.push_back('{
      "accept same, blt x1,x5,-8",
      make_addi(5'd1, 5'd1, 12'hFFF), make_branch(F3_BLT, 5'd1, 5'd5, BR_NEG8), PC, 1'b1,
      1'b1, 1'b1, 5'd5, F3_BLT, PC + 32'd4 + NEG8, NEG8, 1'b1
    });

    tests.push_back('{
      "accept forward branch +8: target is pc+4+8",
      make_addi(5'd1, 5'd1, 12'd1), make_branch(F3_BNE, 5'd1, 5'd0, 13'd8), PC, 1'b1,
      1'b1, 1'b1, 5'd0, F3_BNE, PC + 32'd4 + FWD8, FWD8, 1'b1
    });

    tests.push_back('{
      "accept at a second pc (0x0100_0100), backward",
      make_addi(5'd1, 5'd1, 12'hFFF), make_branch(F3_BNE, 5'd1, 5'd0, BR_NEG8), ALT_PC, 1'b1,
      1'b1, 1'b1, 5'd0, F3_BNE, ALT_PC + 32'd4 + NEG8, NEG8, 1'b1
    });

    tests.push_back('{
      "accept addi x7,x3,+4 / bne x7,x0,-8 (rs1 != rd)",
      make_addi(5'd7, 5'd3, 12'd4), make_branch(F3_BNE, 5'd7, 5'd0, BR_NEG8), PC, 1'b1,
      1'b1, 1'b1, 5'd0, F3_BNE, PC + 32'd4 + NEG8, NEG8, 1'b1
    });

    // ---- v2: the mirrored form -------------------------------------------
    tests.push_back('{
      "v2 accept mirrored: addi x1,x1,-1 / bge x5,x1,-8",
      make_addi(5'd1, 5'd1, 12'hFFF), make_branch(F3_BGE, 5'd5, 5'd1, BR_NEG8), PC, 1'b1,
      1'b1, 1'b1, 5'd5, F3_BGE, PC + 32'd4 + NEG8, NEG8, 1'b0
    });

    tests.push_back('{
      "v2 accept mirrored, second pc",
      make_addi(5'd7, 5'd7, 12'd4), make_branch(F3_BLTU, 5'd9, 5'd7, BR_NEG8), ALT_PC, 1'b1,
      1'b1, 1'b1, 5'd9, F3_BLTU, ALT_PC + 32'd4 + NEG8, NEG8, 1'b0
    });

    tests.push_back('{
      "v2 both operands match: rs1 form wins",
      make_addi(5'd5, 5'd5, 12'hFFF), make_branch(F3_BEQ, 5'd5, 5'd5, BR_NEG8), PC, 1'b1,
      1'b1, 1'b1, 5'd5, F3_BEQ, PC + 32'd4 + NEG8, NEG8, 1'b1
    });

    tests.push_back('{
      "v2 reject neither operand matches",
      make_addi(5'd1, 5'd1, 12'hFFF), make_branch(F3_BLT, 5'd2, 5'd3, BR_NEG8), PC, 1'b1,
      1'b0, 1'b0, 5'd0, 3'd0, 32'd0, 32'd0, 1'b0
    });

    // Counted here, as the last statement of the block that fills the table.
    // A separate initial block would race with this one: if it ran first,
    // number_of_tests would be 0, the driver would skip to the summary and the
    // run would report "Test Passed (0 checks)" -- green, having tested nothing.
    number_of_tests = tests.size();
    if (number_of_tests == 0) begin
      $display("FATAL: no test rows were queued");
      $fatal(1);
    end
  end

  int test_counter = 0;
  int passes = 0;
  int fails  = 0;

  // drive on the rising edge
  always_ff @(posedge clk) begin
    if (rst) begin
      test_counter <= 0;
    end else if (test_counter < number_of_tests) begin
      insn_a_i  <= tests[test_counter].insn_a;
      insn_b_i  <= tests[test_counter].insn_b;
      pc_i      <= tests[test_counter].pc;
      is_insn_i <= tests[test_counter].is_insn;
      test_counter <= test_counter + 1;
    end else begin
      $display("Completed %0d Tests. Simulation Complete!", number_of_tests);
      if (fails == 0)
        $display("Test Passed  (%0d checks)", passes);
      else
        $display("Test Failed  (%0d of %0d checks failed)", fails, number_of_tests);
      $finish;
    end
  end

  // compare on the falling edge; case equality so an X is a failure, not a pass
  test_t current;
  always @(negedge clk) begin
    if (!rst && test_counter > 0) begin
      current = tests[test_counter - 1];
      if (fused_o      === current.exp_fused
       && stride8_o    === current.exp_stride8
       && rs2_o        === current.exp_rs2
       && br_funct3_o  === current.exp_funct3
       && br_target_o  === current.exp_target
       && br_imm_o     === current.exp_imm
       && t_first_o    === current.exp_t_first)
        passes++;
      else begin
        fails++;
        $display("  FAIL  %-42s", current.name);
        $display("        fused=%0b/%0b stride8=%0b/%0b rs2=%0d/%0d funct3=%03b/%03b target=%08h/%08h imm=%08h/%08h",
                 fused_o, current.exp_fused, stride8_o, current.exp_stride8,
                 rs2_o, current.exp_rs2, br_funct3_o, current.exp_funct3,
                 br_target_o, current.exp_target, br_imm_o, current.exp_imm);
      end
    end
  end

  integer counter = 0;
  always_ff @(posedge clk) begin
    counter <= counter + 1;
    if (counter < `RESET_CYCLES) rst <= 1;
    else                         rst <= 0;
    if (counter >= `TIMEOUT) begin
      $display("========== Simulation TIMEOUT!!! ==========");
      $finish;
    end
  end

  initial begin
    $dumpfile("fuse_detect_tb.vcd");
    $dumpvars(0, fuse_detect_tb);
  end

endmodule: fuse_detect_tb
