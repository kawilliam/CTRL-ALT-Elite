/*
 * Module: fetch
 *
 * Description: Fetch stage
 *
 */
`include "constants.svh"

module fetch #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32,
    parameter int BASEADDR=`BASE_ADDR
    )(
	// inputs
	input logic clk,
	input logic rst,
  input logic [AWIDTH - 1:0] next_pc_i,
  input logic pc_en_i,
  input logic jump_branch_i,
	// outputs	
	output logic [AWIDTH - 1:0] pc_o,
  output logic [DWIDTH - 1:0] insn_o
);

    logic [AWIDTH - 1:0] pc;
    assign pc_o = (rst) ? '0 : pc;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= BASEADDR;
        end
        else if (pc_en_i) begin
            if (jump_branch_i) begin
                pc <= next_pc_i;
            end
            else begin
                pc <= next_pc_i + 32'd4;
            end
        end
    end

endmodule : fetch
				

