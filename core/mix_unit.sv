
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26/04/2024 05:08:34 PM
// Design Name: 
// Module Name: mix_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Implemented MIX unit is used to mitigate the lack of an unaligned load word by taking a four bytes word out of two aligned (in memory) word.
// 
// Dependencies: non
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//localparam VALID = 1'b1;
//localparam READY = 1'b1;

module mix_unit
    import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
) (
    input   logic                       clk_i,
    input   logic                       rst_ni,
    input   logic                      mix_unit_valid_i,
    input   logic                       flush_i,
    input   ariane_pkg::fu_data_t       fu_data_i,
    output  riscv::xlen_t              mix_unit_result_o,
    output  logic                      mix_unit_valid_o,
    output  logic                      mix_unit_ready_o,
    output  logic   [TRANS_ID_BITS-1:0] mix_unit_trans_id_o,
    output  exception_t                mix_unit_exception_o
    );
    
    //control signals
    assign mix_unit_ready_o = READY; //always ready
    assign mix_unit_exception_o = '0;

    logic   mix_unit_valid_d, mix_unit_valid_q;
    logic   [TRANS_ID_BITS-1:0] trans_id_q, trans_id_d;

    riscv::xlen_t result_d, result_q;

    assign mix_unit_valid_d = mix_unit_valid_i;
    assign trans_id_d = fu_data_i.trans_id;
    assign mix_unit_valid_o = ~flush_i & mix_unit_valid_q;
    assign mix_unit_trans_id_o = trans_id_q;



    assign result_d = 32'((fu_data_i.operand_a >> 16) | (fu_data_i.operand_b << 16));

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
        result_q <= '0;
        trans_id_q <= '0;
        mix_unit_valid_q <= ~VALID;
        end else begin
            mix_unit_valid_q <= mix_unit_valid_d;
            result_q <= result_d;
            trans_id_q <= trans_id_d;
        end
    end

    assign mix_unit_result_o = result_q;



    
endmodule