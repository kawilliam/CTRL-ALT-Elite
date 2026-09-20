/*
 * Module: writeback
 *
 * Description: Write-back control stage implementation
 *
 * Inputs:
 * 1) PC pc_i
 * 2) result from alu alu_res_i
 * 3) data from memory memory_data_i
 * 4) data to select for write-back wbsel_i
 * 5) branch taken signal brtaken_i
 *
 * Outputs:
 * 1) DWIDTH wide write back data write_data_o
 */
`include "constants.svh"

 module writeback #(
     parameter int DWIDTH=32,
     parameter int AWIDTH=32
 )(
     input logic [AWIDTH-1:0] pc_i,
     input logic [DWIDTH-1:0] alu_res_i,
     input logic [DWIDTH-1:0] memory_data_i,
     input logic [1:0] wbsel_i,
     input logic [DWIDTH-1:0] imm_i,
     output logic [DWIDTH-1:0] writeback_data_o
 );
    /* Logic hole 7 (LH7): Determine the data to write-back to register file based on
                           wbsel control signal
    */
    always_comb begin
        // Muxing the source of writeback data.
        writeback_data_o = /* LH7??? */
    end

endmodule : writeback
