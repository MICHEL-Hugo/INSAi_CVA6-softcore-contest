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
// Description : mac8_FU testbench
// NOTE : This testbench doesn't take into account 
// input silencing. (mac8_FU_valid_i ^ fu_data_i)

`define ENABLE_insAI_EXTENSION

`timescale 1ns / 1ps

module tb_mac8_FU 
import ariane_pkg::*;
();

    // Parameters
    localparam CLK_PERIOD = 10; // Clock period in ns
    
    // Inputs
    logic clk_i = '0;
    logic rst_ni;
    logic mac8_FU_valid_i;
    ariane_pkg::fu_data_t fu_data_i;
    
    // Outputs
    logic [31:0] mac8_FU_result_o;
    logic mac8_FU_valid_o;
    logic mac8_FU_ready_o;
    logic [TRANS_ID_BITS-1:0] mac8_FU_trans_id_o;
    exception_t mac8_FU_exception_o;
    
    // Instantiate the DUT
    mac8_FU dut (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .mac8_FU_valid_i(mac8_FU_valid_i),
        .fu_data_i(fu_data_i),
        .mac8_FU_result_o(mac8_FU_result_o),
        .mac8_FU_valid_o(mac8_FU_valid_o),
        .mac8_FU_ready_o(mac8_FU_ready_o),
        .mac8_FU_trans_id_o(mac8_FU_trans_id_o),
        .mac8_FU_exception_o(mac8_FU_exception_o)
    );
    
    // Clock generation
    always #((CLK_PERIOD)/2) clk_i = ~clk_i;

    // Reset generation
    initial begin
        rst_ni = 1'b0;
        #(CLK_PERIOD);
        rst_ni = 1'b1;
    end
    
    // Test stimulus
    initial begin
        @(posedge clk_i);
        
        // Apply test vectors
        fu_data_i = '0; 
        fu_data_i.operand_a = 'h55667788;
        fu_data_i.operand_b = 'h11223344;
       
        
        #(CLK_PERIOD);
        fu_data_i.operation = MAC8_INIT;
        mac8_FU_valid_i = 1'b1;
        
        #(4*CLK_PERIOD);
        mac8_FU_valid_i = 1'b0;
        
        #(2*CLK_PERIOD);
        mac8_FU_valid_i = 1'b1;
        fu_data_i.operation = MAC8_ACC;
        
        #(CLK_PERIOD);
        mac8_FU_valid_i = 1'b0;
        #(CLK_PERIOD);
        mac8_FU_valid_i = 1'b1;

        #(4*CLK_PERIOD);
        mac8_FU_valid_i = 1'b0;
                
        // Add delay for simulation stability
        #100;
        
        // End of simulation
        $finish;
    end

endmodule


