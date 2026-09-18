/*
 * Module: memory controller
 *
 * Description: Byte-addressable memory controller. Masks data
                to/from pipeline and data  to/from memory.
 *
 * Inputs:
 * 1) Reset signal rst
 * 2) AWIDTH raw address for data memory read/write addr_i
 * 3) DWIDTH data to write data_i
 * 4) DWIDTH data to mask mem_data_i
 * 5) byte mask for w, hw, b, funct3_i
 * 6) read enable signal memren_i
 * 7) write enable signal memwren_i
 * 8) AWIDTH address word algined for data memory write waddr_o
 * 9) DWIDTH data write to memory, byte spliced and extended wdata_o
 *10) DWIDTH data read from memory, spliced and extended rdata_o
 *11) DWIDTH/8 signal to select byte lane byteen_o
 *
 * Outputs:
 * 1) AWIDTH address output waddr_o
 * 2) DWIDTH data output data_o
 */

`include "constants.svh"

module memory_controller #(
    // parameters
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32,
    parameter int OWIDTH = 2,
    parameter logic [AWIDTH-1:0] BASE_ADDR = 32'h0100_0000
 ) (
    input  logic rst,
    // raw address for memory reads and writes
    input  logic [AWIDTH-1:0] addr_i,
    // raw data to write to memory
    input  logic [DWIDTH-1:0] data_i,
    // raw data read from memory
    input  logic [DWIDTH-1:0] mem_data_i,
    // for determining size of memory reads/writes
    input  logic [2:0] funct3_i,
    // memory read enable signal
    input  logic memren_i,
    // memory write enable signal
    input  logic memwren_i,
    // data address
    output logic [AWIDTH-1:0] waddr_o,
    // spliced data to write to memory
    output logic [DWIDTH-1:0] wdata_o,
    // masked data
    output logic [DWIDTH-1:0] rdata_o,
    // byte enabled signal for choosing the correct byte lane in ram
    output logic [(DWIDTH/8)-1:0] byteen_o

 );

    //---------- Word algined address ----------//
    logic [AWIDTH-1:0] address;
    assign address = (addr_i - BASE_ADDR);
    assign waddr_o = {address[AWIDTH-1:OWIDTH], {OWIDTH{1'b0}}};


    //---------- Byte offset for data input/output ----------//
    logic [OWIDTH-1:0] byte_offset;
    assign byte_offset = address[OWIDTH-1:0];

    //---------- Data Read ----------//
    logic [DWIDTH-1:0] shifted_data;
    always_comb begin
        shifted_data = '0;
        rdata_o = '0;
        if (rst) begin
            rdata_o = '0;
        end
        else if (memren_i) begin
            shifted_data = (mem_data_i >> (byte_offset * 8));
            case (funct3_i)
                `F3_LB  : rdata_o =
                          {{(DWIDTH-8){shifted_data[7]}}, shifted_data[7:0]};
                `F3_LBU : rdata_o = {{(DWIDTH-8){1'b0}}, shifted_data[7:0]};
                `F3_LH  : rdata_o =
                          {{(DWIDTH-16){shifted_data[15]}}, shifted_data[15:0]};
                `F3_LHU : rdata_o = {{(DWIDTH-16){1'b0}}, shifted_data[15:0]};
                default : rdata_o = shifted_data;
            endcase
        end
    end

    //---------- Data Write ----------//
    always_comb begin
        byteen_o = '0;
        wdata_o = '0;
        if (memwren_i) begin
            case (funct3_i)
                // Store byte.
                `F3_SB : begin
                    wdata_o = {(DWIDTH/8){data_i[7:0]}};
                    byteen_o = {{(DWIDTH/8-1){1'b0}}, 1'b1} << byte_offset;
                end
                // Store halfword.
                `F3_SH : begin
                    wdata_o = {(DWIDTH/16){data_i[15:0]}};
                    byteen_o = {{(DWIDTH/8-2){1'b0}}, 2'b11} << byte_offset;
                end
                // Store word.
                `F3_SW : begin
                    wdata_o = {(DWIDTH/32){data_i[31:0]}};
                    byteen_o = {{(DWIDTH/8-4){1'b0}}, 4'b1111} << byte_offset;
                end
                default : ;
            endcase
        end
    end
endmodule : memory_controller
