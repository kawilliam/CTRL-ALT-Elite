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
    logic [AWIDTH-1:0] f_pc;          // next-PC input to fetch
    logic [AWIDTH-1:0] pc;            // current PC
    logic [DWIDTH-1:0] f_insn;        // instruction read from memory
    logic pc_en;                      // PC enable
    logic stall;                      // stall signal
    logic flush;                      // squash signal
    logic hazard;                     // hazard detection
    logic jump_branch;                // taken branch or jump

    logic [AWIDTH-1:0] fd_pc;         // fd pipelined pc
    logic [DWIDTH-1:0] fd_insn;       // fd pipelined instruction

    logic [6:0] d_opcode;             // opcode
    logic [4:0] d_rd;                 // destination register
    logic [4:0] d_rs1;                // source register 1
    logic [4:0] d_rs2;                // source register 2
    logic [6:0] d_funct7;             // funct7 field
    logic [2:0] d_funct3;             // funct3 field
    logic [DWIDTH-1:0] d_imm;         // immediate
    logic [DWIDTH-1:0] d_insn;        // instruction to decode
    logic [AWIDTH-1:0] d_pc;          // PC to decode
    logic [DWIDTH-1:0] igen_imm;      // immediate

    logic [AWIDTH-1:0] dx_pc;         // dx pipelined PC
    logic [DWIDTH-1:0] dx_imm;        // dx pipelined immediate
    logic [DWIDTH-1:0] dx_rs1data;    // dx pipelined rs1 value
    logic [DWIDTH-1:0] dx_rs2data;    // dx pipelined rs2 value
    logic [6:0] dx_opcode;            // dx pipelined opcode
    logic [6:0] dx_funct7;            // dx pipelined funct7 field
    logic [2:0] dx_funct3;            // dx pipelined funct3 field
    logic [4:0] dx_rd;                // dx pipelined destination register
    logic [4:0] dx_rs1;               // dx pipelined source register 1
    logic [4:0] dx_rs2;               // dx pipelined source register 2

    logic [DWIDTH-1:0] alu_A;         // ALU operand A (rs1)
    logic [DWIDTH-1:0] alu_B;         // ALU operand B (s2 or immediate)
    logic [DWIDTH-1:0] e_res;         // ALU result
    logic e_brtaken;                  // branch condition
    wire e_pcsel;                     // jump select
    wire e_rs2sel;                    // ALU operand B immediate
    wire [3:0] e_alusel;              // ALU operation
    wire [1:0] xm_wbsel;              // writeback source
    wire [DWIDTH-1:0] xm_wdata;       // writeback data
    wire mx_rs1;                      // forward rs1 from memory stage
    wire wx_rs1;                      // forward rs1 from writeback
    wire mx_rs2;                      // forward rs2 from memory stage
    wire wx_rs2;                      // forward rs2 from writeback
    wire [DWIDTH-1:0] fwd_rs1;        // rs1 value after forwarding
    wire [DWIDTH-1:0] fwd_rs2;        // rs2 value after forwarding

    logic [AWIDTH-1:0] xm_pc;         // xm pipelined PC
    logic [DWIDTH-1:0] xm_alu_res;    // xm pipelined ALU result
    logic [DWIDTH-1:0] xm_rs2data;    // xm pipelined store data
    logic [DWIDTH-1:0] xm_imm;        // xm pipelined immediate
    logic [4:0] xm_rd;                // xm pipelined rd
    logic [4:0] xm_rs2;               // xm pipelined rs2
    logic [2:0] xm_funct3;            // xm pipelined funct 3

    logic insn_en;                    // instruction read enable
    logic [DWIDTH-1:0] m_data_o;      // load data
    logic [DWIDTH-1:0] mem_data;      // store data after WM forwarding
    wire mem_memren;                  // memory load enable
    wire mem_memwren;                 // memory store enable
    wire wm_rs2;                      // forward store data from writeback

    logic [AWIDTH-1:0] mw_pc;         // mw pipelined PC
    logic [DWIDTH-1:0] mw_alu_res;    // mw pipelined ALU result
    logic [DWIDTH-1:0] mw_mem_data;   // mw pipelined load data
    logic [DWIDTH-1:0] mw_imm;        // mw pipelined immediate
    logic [4:0] mw_rd;                // mw pipelined rd

    wire [1:0] mem_wbsel;             // writeback select
    wire mem_regwren;                 // write rd enable
    logic [DWIDTH-1:0] wb_data;       // rd data

    logic [DWIDTH-1:0] r_rs1data;     // rs1 data
    logic [DWIDTH-1:0] r_rs2data;     // rs2 data

    logic [12:0] ctrl_reg [2:0];      // control data propogated through pipeline (D_X, X_M, M_W)
    wire hazard_load;                 // hazard load

    wire c_pcsel;                     // control pc signal
    wire c_immsel;                    // control immediate select
    wire c_regwren;                   // control rd write
    wire c_rs1sel;                    // control ALU operand A
    wire c_rs2sel;                    // control ALU operand B
    wire c_memren;                    // control load
    wire c_memwren;                   // control store
    wire [1:0] c_wbsel;               // control writeback source
    wire [3:0] c_alusel;              // control ALU operation

    assign jump_branch = e_brtaken || e_pcsel;
    assign f_pc = jump_branch ? e_res : pc;

    // stall and flush logic instantiation
    // For stage 1, you do not need to modify this
    stall_flush_logic stall_flush (
        .hazard_i(hazard),
        .br_jump_i(jump_branch),
        .pc_en_o(pc_en),
        .stall_o(stall),
        .flush_o(flush)
    );

    // fetch instantiation
    fetch #(
        .AWIDTH(32),
        .DWIDTH(32),
        .BASEADDR(`BASE_ADDR)
    ) fetch1 (
        .clk(clk),
        .rst(reset),
        .next_pc_i(f_pc),
        .pc_en_i(pc_en),
        .jump_branch_i(jump_branch),
        .pc_o(pc),
        .insn_o()
    );

    // ---------- F/D ---------- //
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
      .stall_i(stall),
      .pc_o(fd_pc),
      .insn_o(fd_insn)
    );

    // ---------- DECODE STAGE ---------- //

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
        .imm_o()
    );

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
      .stall_i(stall),
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
    // ------ Control Signal Wires (EX) --- //
    assign e_pcsel = `D_X[`PCSEL];
    assign e_rs2sel = `D_X[`RS2SEL];
    assign e_alusel = `D_X[`ALUSEL];
    // Logic hole 5 (LH5): Complete the logic to determine the inputs to the ALU
    //                     alu_A, mux_B, alu_B
    // Memory-stage bypass must forward the value that instruction will write.
    // lui writes its immediate, and jal/jalr write pc+4. The ALU result is neither.
    assign xm_wbsel = `X_M[`WBSEL];
    assign xm_wdata =
        (xm_wbsel == `WB_IMM) ? xm_imm :
        (xm_wbsel == `WB_PC4) ? xm_pc + 32'd4 :
        xm_alu_res;
    assign mx_rs1 = `X_M[`REGWREN] && (xm_rd != 5'd0) && (xm_rd == dx_rs1) && !`X_M[`MEMREN];
    assign wx_rs1 = `M_W[`REGWREN] && (mw_rd != 5'd0) && (mw_rd == dx_rs1);
    assign mx_rs2 = `X_M[`REGWREN] && (xm_rd != 5'd0) && (xm_rd == dx_rs2) && !`X_M[`MEMREN];
    assign wx_rs2 = `M_W[`REGWREN] && (mw_rd != 5'd0) && (mw_rd == dx_rs2);
    assign fwd_rs1 = mx_rs1 ? xm_wdata : wx_rs1 ? wb_data : dx_rs1data;
    assign fwd_rs2 = mx_rs2 ? xm_wdata : wx_rs2 ? wb_data : dx_rs2data;
    assign alu_A = fwd_rs1;
    assign alu_B = e_rs2sel ? dx_imm : fwd_rs2;

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
    // X/M instantiation
    xm_reg #(
      .DWIDTH(32),
      .AWIDTH(32)
    ) xm_reg1 (
      .clk(clk),
      .rst(reset),
      .pc_i(dx_pc),
      .rs2data_i(fwd_rs2),
      .funct3_i(dx_funct3),
      .rd_i(dx_rd),
      .rs2_i(dx_rs2),
      .alu_res_i(e_res),
      .ctrl_reg_i(`D_X),
      .imm_i(dx_imm),
      .pc_o(xm_pc),
      .rs2data_o(xm_rs2data),
      .funct3_o(xm_funct3),
      .rd_o(xm_rd),
      .rs2_o(xm_rs2),
      .alu_res_o(xm_alu_res),
      .ctrl_reg_o(`X_M),
      .imm_o(xm_imm)
    );

    // ---------- MEMORY STAGE ---------- //
    // ---- Control Signal Wires (MEM) -- //
    assign mem_memren = `X_M[`MEMREN];
    assign mem_memwren = `X_M[`MEMWREN];

    // Read instruction from memory only if no reset.
    assign insn_en = 1'b1;
    // Added forwarding
    assign wm_rs2 = `M_W[`REGWREN] && (mw_rd != 5'd0) && (mw_rd == xm_rs2);
    assign mem_data = wm_rs2 ? wb_data : xm_rs2data;
    
    // Memory instantiation
    memory #(
        .AWIDTH(32),
        .DWIDTH(32),
        .OWIDTH(2),
        .BASE_ADDR(`BASE_ADDR)
        ) memory1 (
        .clk(clk),
        .rst(reset),
        .pc_i(pc),
        .addr_i(xm_alu_res),
        .data_i(mem_data),
        .funct3_i(xm_funct3),
        .memren_i(mem_memren),
        .memwren_i(mem_memwren),
        .insnen_i(insn_en),
        .insn_o(f_insn),
        .data_o(m_data_o)
    );

    // ---------- M/WB ---------- //
    // M/WB instantiation
    mwb_reg #(
        .DWIDTH(32),
        .AWIDTH(32)
        ) mwb_reg1 (
        .clk(clk),
        .rst(reset),
        .pc_i(xm_pc),
        .alu_res_i(xm_alu_res),
        .mdata_i(m_data_o),
        .rd_i(xm_rd),
        .imm_i(xm_imm),
        .ctrl_reg_i(`X_M),
        .pc_o(mw_pc),
        .alu_res_o(mw_alu_res),
        .mdata_o(mw_mem_data),
        .rd_o(mw_rd),
        .imm_o(mw_imm),
        .ctrl_reg_o(`M_W)
    );

    // ---------- WRITEBACK STAGE ------- //

    // ---- Control Signal Wires (WB) -- //
    assign mem_wbsel = `M_W[`WBSEL];
    assign mem_regwren = `M_W[`REGWREN];

    // Logic hole 7 (LH7): Please see writeback.sv for details on LH7
    // write back instantiation
    writeback #(
      .DWIDTH(DWIDTH),
      .AWIDTH(AWIDTH)
    ) wb_wb1 (
      .pc_i(mw_pc),
      .alu_res_i(mw_alu_res),
      .memory_data_i(mw_mem_data),
      .wbsel_i(mem_wbsel),
      .imm_i(mw_imm),
      .writeback_data_o(wb_data)
    );

    // ---------- REGISTER FILE ------- //

    // ---- Control Signal Wires (WB) -- //
    

    // Register file instantiation
    register_file #(
      .DWIDTH(DWIDTH)
    ) register_file1 (
      .clk(clk),
      .rst(reset),
      .rs1_i(d_rs1),
      .rs2_i(d_rs2),
      .rd_i(mw_rd),
      .datawb_i(wb_data),
      .regwren_i(mem_regwren),
      .rs1data_o(r_rs1data),
      .rs2data_o(r_rs2data)
    );

    // ---------- CONTROL BUS (D/X, X/M, M/WB) ---------- //
    // D_X=ctrl_reg[0], X_M=ctrl_reg[1], M_W=ctrl_reg[2]

    // --------- Hazards ---------- //
    assign hazard_load = `D_X[`MEMREN] && (dx_rd != 5'd0) && ((dx_rd == d_rs1) || (dx_rd == d_rs2 && d_opcode != `S_TYPE));
    // wire hazard_x = `D_X[`REGWREN] && (dx_rd != 5'd0) && ((dx_rd == d_rs1) || (dx_rd == d_rs2));
    // wire hazard_m = `X_M[`REGWREN] && (xm_rd != 5'd0) && ((xm_rd == d_rs1) || (xm_rd == d_rs2));
    // wire hazard_w = `M_W[`REGWREN] && (mw_rd != 5'd0) && ((mw_rd == d_rs1) || (mw_rd == d_rs2));

    // assign hazard = (hazard_x || hazard_m || hazard_w) && !jump_branch;
    assign hazard = hazard_load && !jump_branch;

    // ---------- CONTROL --------------- //
    // Logic hole 4 (LH4): Please see control.sv for details on LH4
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
