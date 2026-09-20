/*
 * Module: rv_core
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

`include "constants.svh"

module rv_core #(
  parameter int AWIDTH = 32,
  parameter int DWIDTH = 32
)(
  input logic clk,
  input logic reset,
  output logic busy
);

    // ---------- FETCH STAGE ----------- //
    // Logic hole 1 (LH1) : In fetch, determining next PC on a jump/branch
    //               that will feed into jump_branch_i port in fetch module.
    //               No changes are necessary in fetch logic (fetch.sv)
    // fetch signals
    logic [AWIDTH-1:0] f_pc, pc;
    logic [DWIDTH-1:0] f_insn;
    logic pc_en;
    logic stall, flush;

    // stall and flush logic instantiation
    // For stage 1, you do not need to modify this
    stall_flush_logic stall_flush (
        .hazard_i(1'b0),
        .br_jump_i(jump_branch),
        .pc_en_o(pc_en),
        .stall_o(stall),
        .flush_o(flush)
    );

    // fetch instantiation
    fetch #(
        .AWIDTH(32),
        .DWIDTH(32),
        .BASEADDR(32'h01000000)
    ) fetch1 (
        .clk(clk),
        .rst(reset),
        .next_pc_i(f_pc),
        .pc_en_i(1'b1),
        .jump_branch_i(/*LH1???*/),
        .pc_o(pc),
        .insn_o()
    );

    // ---------- DECODE STAGE ---------- //
    // decode signals
    logic [6:0] d_opcode;
    logic [4:0] d_rd;
    logic [4:0] d_rs1;
    logic [4:0] d_rs2;
    logic [6:0] d_funct7;
    logic [2:0] d_funct3;
    logic [4:0] d_shamt;
    logic [DWIDTH-1:0] d_imm;
    logic [DWIDTH-1:0] d_insn;
    logic [AWIDTH-1:0] d_pc;

    assign d_insn = f_insn;
    assign d_pc = pc;

    // Logic hole 2 (LH2): Please see decode.sv for details on LH2
    // decode instantiation
    decode #(
        .AWIDTH(32),
        .DWIDTH(32)
    ) decode1 (
        .clk(clk),
        .rst(reset),
        .insn_i(d_insn),
        .pc_i(d_pc),
        .pc_o(),
        .insn_o(),
        .opcode_o(d_opcode),
        .rd_o(d_rd),
        .rs1_o(d_rs1),
        .rs2_o(d_rs2),
        .funct7_o(d_funct7),
        .funct3_o(d_funct3),
        .shamt_o(d_shamt),
        .imm_o(d_imm)
    );

    // immediate generator signals
    logic [DWIDTH - 1:0] igen_imm;
    assign d_imm = igen_imm;
    assign d_shamt = igen_imm[4:0];

    // Logic hole 3 (LH3): Please see igen.sv for details on LH3
    // immediate generator instantiation
    igen #(
        .DWIDTH(32)
    ) igen1 (
        .opcode_i(d_opcode),
        .insn_i(d_insn),
        .imm_o(igen_imm)
    );

    // ---------- CONTROL --------------- //
    // Logic hole 4 (LH4): Please see control.sv for details on LH4
    // control signals
    wire c_pcsel;
    wire c_immsel;
    wire c_regwren;
    wire c_rs1sel;
    wire c_rs2sel;
    wire c_memren;
    wire c_memwren;
    wire [1:0] c_wbsel;
    wire [3:0] c_alusel;
    // control instantiation
    control #(
        .DWIDTH(32)
    ) control1 (
        .insn_i(d_insn),
        .opcode_i(d_opcode),
        .funct7_i(d_funct7),
        .funct3_i(d_funct3),
        .pcsel_o(c_pcsel),
        .immsel_o(c_immsel),
        .regwren_o(c_regwren),
        .rs1sel_o(c_rs1sel),
        .rs2sel_o(c_rs2sel),
        .memren_o(c_memren),
        .memwren_o(c_memwren),
        .wbsel_o(c_wbsel),
        .alusel_o(c_alusel)
    );

    // ---------- EXECUTE STAGE --------- //
    // execute signals
    logic [DWIDTH - 1:0] alu_A, alu_B, mux_B, e_res;
    logic e_brtaken;

    // Logic hole 5 (LH5): Complete the logic to determine the inputs to the ALU
    //                     alu_A, mux_B, alu_B

    assign alu_A = /* LH5??? */
    assign mux_B = /* LH5??? */
    assign alu_B = /* LH5??? */

    // Logic hole 6 (LH6): Please see execute.sv for details on LH6
    // Execute instantiation
    alu #(
      .DWIDTH(DWIDTH),
      .AWIDTH(AWIDTH)
    ) e_alu1 (
      .pc_i(d_pc),
      .rs1_i(alu_A),
      .rs2_i(alu_B),
      .funct3_i(d_funct3),
      .funct7_i(d_funct7),
      .opcode_i(d_opcode),
      .imm_i(d_imm),
      .alusel_i(c_alusel),
      .res_o(e_res),
      .brtaken_o(e_brtaken)
    );

    // ---------- MEMORY STAGE ---------- //
    logic insn_en;
    logic [DWIDTH-1:0] m_data_o;
    logic [DWIDTH-1:0] mem_data;

    // Read instruction from memory only if no reset.
    assign insn_en = 1'b1;
    assign mem_data = mux_B;

    // Memory instantiation
    memory #(
        .AWIDTH(32),
        .DWIDTH(32),
        .OWIDTH(2),
        .BASE_ADDR(32'h01000000)
        ) memory1 (
        .clk(clk),
        .rst(reset),
        .pc_i(pc),
        .addr_i(e_res),
        .data_i(mem_data),
        .funct3_i(d_funct3),
        .memren_i(c_memren),
        .memwren_i(c_memwren),
        .insnen_i(insn_en),
        .insn_o(f_insn),
        .data_o(m_data_o)
    );

    // ---------- WRITEBACK STAGE ------- //
    // Logic hole 7 (LH7): Please see writeback.sv for details on LH7
    // write back signals
    logic [DWIDTH-1:0] wb_data;
    // write back instantiation
    writeback #(
      .DWIDTH(DWIDTH),
      .AWIDTH(AWIDTH)
    ) wb_wb1 (
      .pc_i(d_pc),
      .alu_res_i(e_res),
      .memory_data_i(m_data_o),
      .wbsel_i(c_wbsel),
      .imm_i(d_imm),
      .writeback_data_o(wb_data)
    );

    // ---------- REGISTER FILE ------- //
    // register file signals
    logic [DWIDTH - 1:0] r_rs1data, r_rs2data;
    // Register file instantiation
    register_file #(
      .DWIDTH(DWIDTH)
    ) register_file1 (
      .clk(clk),
      .rst(reset),
      .rs1_i(d_rs1),
      .rs2_i(d_rs2),
      .rd_i(d_rd),
      .datawb_i(wb_data),
      .regwren_i(c_regwren),
      .rs1data_o(r_rs1data),
      .rs2data_o(r_rs2data)
    );

    // This is to get yosys to synthesize the design
    assign busy = (c_regwren || c_memren || c_memwren);

endmodule : rv_core
