// Copyright 2023-2024 INSA Toulouse.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Authors: Nell PARTY,              INSA Toulouse
//          Hugo MICHEL,             INSA Toulouse
//          Achille CAUTE,           INSA Toulouse 
//          Diskouna J. GNANGUESSIM, INSA Toulouse
/
// Date   : 11.05.2024
//
// Description : mix_unit 

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

    assign mix_unit_result_o    = ((fu_data_i.operand_a >> 16) |  (fu_data_i.operand_b << 16));
    assign mix_unit_valid_o     = mix_unit_valid_i;
    assign mix_unit_ready_o     = 1'b1; //always ready
    assign mix_unit_trans_id_o  = fu_data_i.trans_id;
    assign mix_unit_exception_o = '0;   //no exception

endmodule
