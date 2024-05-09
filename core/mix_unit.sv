//localparam VALID = 1'b1;
//localparam READY = 1'b1;
// one cycle mix_unit 

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
    // a4 a3 a2 a1 b4 b3 b2 b1
    // b2b1a4a3
    assign mix_unit_result_o    = {fu_data_i.operand_b[15:0], fu_data_i.operand_a[31:16]};
    assign mix_unit_valid_o     = mix_unit_valid_i;
    assign mix_unit_ready_o     = 1'b1; //always ready
    assign mix_unit_trans_id_o  = fu_data_i.trans_id;
    assign mix_unit_exception_o = '0;

endmodule
