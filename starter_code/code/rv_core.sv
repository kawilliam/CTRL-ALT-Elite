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
    logic jump_branch;

    assign jump_branch = e_brtaken || e_pcsel;
    assign f_pc = jump_branch ? e_res : pc;

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
        .jump_branch_i(jump_branch),
        .pc_o(pc),
        .insn_o()
    );

    // ---------- F/D ---------- //
    // F/D signals
    logic [AWIDTH-1:0] fd_pc;
    logic [DWIDTH-1:0] fd_insn;

    // F/D instantiation
    fd_reg #(
        .AWIDTH(32),
        .DWIDTH(32)
    ) fd_reg1 (
      .clk(clk),
      .rst(reset),
      .insn_i(f_insn),
      .pc_i(pc),
      .flush_i(flush),
      .pc_o(fd_pc),
      .insn_o(fd_insn)
    );

    // ---------- DECODE STAGE ---------- //
    // decode signals
    logic [6:0] d_opcode;
    logic [4:0] d_rd;
    logic [4:0] d_rs1;
    logic [4:0] d_rs2;
    logic [6:0] d_funct7;
    logic [2:0] d_funct3;
    // logic [4:0] d_shamt;
    logic [DWIDTH-1:0] d_imm;
    logic [DWIDTH-1:0] d_insn;
    logic [AWIDTH-1:0] d_pc;

    // assign d_insn = f_insn;
    // assign d_pc = pc;

    // Logic hole 2 (LH2): Please see decode.sv for details on LH2
    // decode instantiation
    decode #(
        .AWIDTH(32),
        .DWIDTH(32)
    ) decode1 (
        .clk(clk),
        .rst(reset),
        .insn_i(fd_insn),
        .pc_i(fd_pc),
        .pc_o(d_pc),
        .insn_o(d_insn),
        .opcode_o(d_opcode),
        .rd_o(d_rd),
        .rs1_o(d_rs1),
        .rs2_o(d_rs2),
        .funct7_o(d_funct7),
        .funct3_o(d_funct3),
     //   .shamt_o(d_shamt),
        .imm_o(d_imm)
    );

    // immediate generator signals
    logic [DWIDTH - 1:0] igen_imm;
    // assign d_shamt = d_imm[4:0];

    // Logic hole 3 (LH3): Please see igen.sv for details on LH3
    // immediate generator instantiation
    igen #(
        .DWIDTH(32)
    ) igen1 (
        .opcode_i(d_opcode),
        .insn_i(d_insn),
        .imm_o(igen_imm)
    );

    assign d_imm = c_immsel ? igen_imm : '0;

    // ---------- D/X ---------- //
    // D/X signals
    logic [AWIDTH-1:0] dx_pc;
    logic [DWIDTH-1:0] dx_imm, dx_rs1data, dx_rs2data;
    logic [6:0] dx_opcode, dx_funct7;
    logic [2:0] dx_funct3;
    logic [4:0] dx_rd, dx_rs1, dx_rs2;

    // D/X instantiation
    dx_reg #(
        .AWIDTH(32),
        .DWIDTH(32)
    ) dx_reg1 (
      .clk(clk),
      .rst(reset),
      .pc_i(d_pc),
      .imm_i(d_imm),
      .rs1data_i(r_rs1data),
      .rs2data_i(r_rs2data),
      .opcode_i(d_opcode),
      .funct3_i(d_funct3),
      .funct7_i(d_funct7),
      .rd_i(d_rd),
      .rs1_i(d_rs1),
      .rs2_i(d_rs2),
      .flush_i(flush),
      .pcsel_i(c_pcsel),
      .immsel_i(c_immsel),
      .regwren_i(c_regwren),
      .rs1sel_i(c_rs1sel),
      .rs2sel_i(c_rs2sel),
      .alusel_i(c_alusel),
      .memren_i(c_memren),
      .memwren_i(c_memwren),
      .wbsel_i(c_wbsel),
      .pc_o(dx_pc),
      .imm_o(dx_imm),
      .rs1data_o(dx_rs1data),
      .rs2data_o(dx_rs2data),
      .opcode_o(dx_opcode),
      .funct3_o(dx_funct3),
      .funct7_o(dx_funct7),
      .rd_o(dx_rd),
      .rs1_o(dx_rs1),
      .rs2_o(dx_rs2),
      .ctrl_reg_o(`D_X)
    );

    // ---------- EXECUTE STAGE --------- //
    // execute signals
    logic [DWIDTH - 1:0] alu_A, alu_B, mux_B, e_res;
    logic e_brtaken;

    // ------ Control Signal Wires (EX) --- //
    wire e_pcsel = `D_X[`PCSEL];
    wire e_rs2sel = `D_X[`RS2SEL];
    wire [3:0] e_alusel = `D_X[`ALUSEL];
    // Logic hole 5 (LH5): Complete the logic to determine the inputs to the ALU
    //                     alu_A, mux_B, alu_B
    assign alu_A = dx_rs1data; /* LH5??? */
    assign mux_B = dx_rs2data; /* LH5??? */
    assign alu_B = e_rs2sel ? dx_imm : dx_rs2data; /* LH5??? */

    // Logic hole 6 (LH6): Please see execute.sv for details on LH6
    // Execute instantiation
    alu #(
      .DWIDTH(DWIDTH),
      .AWIDTH(AWIDTH)
    ) e_alu1 (
      .pc_i(dx_pc),
      .rs1_i(alu_A),
      .rs2_i(alu_B),
      .funct3_i(dx_funct3),
      .funct7_i(dx_funct7),
      .opcode_i(dx_opcode),
      .imm_i(dx_imm),
      .alusel_i(e_alusel),
      .res_o(e_res),
      .brtaken_o(e_brtaken)
    );

    // ---------- X/M ---------- //
    logic [AWIDTH-1:0] xm_pc;
    logic [DWIDTH-1:0] xm_alu_res, xm_rs2data;
    logic [4:0] xm_rsd, xm_rs2;
    logic [2:0] xm_funct3;

    // ---------- MEMORY STAGE ---------- //
    logic insn_en;
    logic [DWIDTH-1:0] m_data_o;
    logic [DWIDTH-1:0] mem_data;

    // ---- Control Signal Wires (MEM) -- //
    wire e_memren = `D_X[`MEMREN];
    wire e_memwren = `D_X[`MEMWREN];

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
        .funct3_i(dx_funct3),
        .memren_i(e_memren),
        .memwren_i(e_memwren),
        .insnen_i(insn_en),
        .insn_o(f_insn),
        .data_o(m_data_o)
    );

    // ---------- M/WB ---------- //
    logic [AWIDTH-1:0] mw_pc;
    logic [DWIDTH-1:0] mw_alu_res, mw_mem_data, mw_imm;
    logic [4:0] mw_rd;

    // ---------- WRITEBACK STAGE ------- //

    // ---- Control Signal Wires (WB) -- //
    wire [1:0] e_wbsel = `D_X[`WBSEL];

    // Logic hole 7 (LH7): Please see writeback.sv for details on LH7
    // write back signals
    logic [DWIDTH-1:0] wb_data;
    // write back instantiation
    // TEST
    writeback #(
      .DWIDTH(DWIDTH),
      .AWIDTH(AWIDTH)
    ) wb_wb1 (
      .pc_i(dx_pc),
      .alu_res_i(e_res),
      .memory_data_i(m_data_o),
      .wbsel_i(e_wbsel),
      .imm_i(dx_imm),
      .writeback_data_o(wb_data)
    );

    // ---------- REGISTER FILE ------- //

    // ---- Control Signal Wires (WB) -- //
    wire e_regwren = `D_X[`REGWREN];

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
      .rd_i(dx_rd),
      .datawb_i(wb_data),
      .regwren_i(e_regwren),
      .rs1data_o(r_rs1data),
      .rs2data_o(r_rs2data)
    );

    // ---------- CONTROL BUS (D/X, X/M, M/WB) ---------- //
    logic [12:0] ctrl_reg [2:0]; // D_X=ctrl_reg[0], X_M=ctrl_reg[1], M_W=ctrl_reg[2]

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

    // This is to get yosys to synthesize the design
    assign busy = (c_regwren || c_memren || c_memwren);

endmodule : rv_core
