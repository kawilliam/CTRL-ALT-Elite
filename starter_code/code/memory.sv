/*
 * Module: memory
 *
 * Description: Word indexed parameterized memory block (usually 32-bit or 64-bit)
 *              Contains read-only instruction memory and read/write data memory
 *
 * Inputs:
 * 1) Clock signal clk
 * 2) Reset signal rst
 * 3) AWIDTh address for instruction pc_i
 * 4) AWIDTH address for data addr_i
 * 5) DWIDTH data to write data_i
 * 6) 3-bit size selector for w, hw, b, funct3_i
 * 7) read enable signal memren_i
 * 8) write enable signal memwren_i
 * 9) instruction enable signal insnen_i
 *
 * Outputs:
 * 1) DWIDTH instruction output insn_o
 * 2) DWIDTH data output data_o
 */

module memory #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32,
    parameter int OWIDTH = 2,
    parameter logic [31:0] BASE_ADDR = 32'h0100_0000
) (
    input  logic clk,
    input  logic rst,
    input  logic [AWIDTH-1:0] pc_i, // instruction address
    input  logic [AWIDTH-1:0] addr_i, // data address
    input  logic [DWIDTH-1:0] data_i, // data to write to memory
    input  logic [2:0] funct3_i,
    input  logic memren_i,
    input  logic memwren_i,
    input  logic insnen_i,
    output logic [DWIDTH-1:0] insn_o,
    output logic [DWIDTH-1:0] data_o
);

    logic [DWIDTH-1:0] mem_to_con_data;
    logic [AWIDTH-1:0] con_to_mem_addr;
    logic [DWIDTH-1:0] con_to_mem_data;
    logic [(DWIDTH/8)-1:0] con_to_mem_bytelane;

    memory_controller #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .OWIDTH($clog2(DWIDTH/8)),
        .BASE_ADDR(32'h0100_0000)
    ) mem_con (
        .rst(rst),
        .addr_i(addr_i),
        .data_i(data_i),
        .mem_data_i(mem_to_con_data),
        .funct3_i(funct3_i),
        .memren_i(memren_i),
        .memwren_i(memwren_i),
        .waddr_o(con_to_mem_addr),
        .wdata_o(con_to_mem_data),
        .rdata_o(data_o),
        .byteen_o(con_to_mem_bytelane)
    );

    main_memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .BASE_ADDR(32'h0100_0000)
    ) ram (
        .clk(clk),
        .rst(rst),
        .pc_i(pc_i),
        .addr_i(con_to_mem_addr),
        .data_i(con_to_mem_data),
        .bytelane_i(con_to_mem_bytelane),
        .memren_i(memren_i),
        .memwren_i(memwren_i),
        .insnen_i(insnen_i),
        .insn_o(insn_o),
        .data_o(mem_to_con_data)
    );

endmodule : memory
