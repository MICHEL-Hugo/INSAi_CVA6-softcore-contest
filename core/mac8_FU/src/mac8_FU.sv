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
//
// Date   : 11.05.2024
//
// Description : mac8_FU is a SIMD multiply and accumulate (MAC) unit with
// internal accumulator register. It has a fix latency of one cycle. 
// Multiplications are computed on 8 bits value (hence the 8 in its
// name).
//
// mac8_FU performs two main operations : 
//   - MAC8_INIT : initialize the accumulator with operand_a value.
//   - MAC8_ACC  : compute mac on operand_a and operand_b vectors and
//                 add the result to the accumulator register.
// mac8_FU outputs the next value that will be stored in the accumulator.
//
// Following implementation assumes vectors (operand_a, operand_b) of 32 bits
// width. 
// At this moment, only signed vs unsigned multiplications are done. It can be
// be extended by adding a sign-extension stage before multiplications.
//
// TODO : 
// - speculative execution !!! move register writing to commit stage
// - handle overflow 
//   simple solution : raise exception when an overflow occurs
//   increase accumulator size and define lower|upper part ?

module mac8_FU
    import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
) (
    input   logic                       clk_i,
    input   logic                       rst_ni,
    input   logic                       mac8_FU_valid_i,
    input   logic                       flush_i,
    input   ariane_pkg::fu_data_t       fu_data_i,
    output  riscv::xlen_t               mac8_FU_result_o,
    output  logic                       mac8_FU_valid_o,
    output  logic                       mac8_FU_ready_o,
    output  logic   [TRANS_ID_BITS-1:0] mac8_FU_trans_id_o,
    output  exception_t                 mac8_FU_exception_o
    );

    logic [31:0]      accumulator_q, accumulator_d;
    logic [31:0]      cur_res; 
    logic [3:0][15:0] mult_res;
    logic [17:0]      add_res; 
    
	// Multiplication "stage"
    // operand_a elements (bytes) are signed
    // operand_b elements (bytes) are unsigned
	for (genvar i = 0; i < 4; ++i) begin
    	assign mult_res[i] = $signed({fu_data_i.operand_a[(i+1)*8-1], 
				                            fu_data_i.operand_a[(i+1)*8-1 -: 8]}) 
                             * 
							 $signed({1'b0, fu_data_i.operand_b[(i+1)*8-1 -: 8]}); // positive
	end

    // Addition "stage"
	always_comb begin
		add_res = '0;
		for (int i = 0; i < 4; i += 2) begin
			add_res = $signed(add_res) + ($signed(mult_res[i]) + $signed(mult_res[i+1]));
		end
	end
   
    assign cur_res = 32'(signed'(add_res));

	// Calculate accumulator next value
    always_comb begin 
        unique case (fu_data_i.operation)
            MAC8_INIT : 
                accumulator_d = $signed(fu_data_i.operand_a);
            default: //MAC8_ACC falls in this case 
                accumulator_d = $signed(cur_res) + $signed(accumulator_q);
        endcase
        if (~mac8_FU_valid_i) begin
            accumulator_d = accumulator_q;
        end
    end
	
	// Outputs
    assign mac8_FU_result_o    = accumulator_d; 
    assign mac8_FU_valid_o     = mac8_FU_valid_i;
    assign mac8_FU_ready_o     = 1'b1;
    assign mac8_FU_trans_id_o  = fu_data_i.trans_id;
    assign mac8_FU_exception_o = '0;
	
	// Accumulator register
	always_ff @(posedge clk_i or negedge rst_ni) begin
		if (~rst_ni) begin 
			accumulator_q <= '0;
		end else begin 
			accumulator_q <= accumulator_d;
		end
	end
endmodule
