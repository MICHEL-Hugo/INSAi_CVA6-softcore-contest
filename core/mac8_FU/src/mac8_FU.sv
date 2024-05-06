//Implemented MAC unit is for signed operand A and unsigned operand B
localparam VALID = 1'b1;
localparam READY = 1'b1;

(* use_dsp = "simd" *)
module mac8_FU
    import ariane_pkg::*;
	import riscv::XLEN;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
) (
    input   logic                       clk_i,
    input   logic                       rst_ni,
    input   logic                      mac8_FU_valid_i,
    input   logic                       flush_i,
    input   ariane_pkg::fu_data_t       fu_data_i,
    output  riscv::xlen_t              mac8_FU_result_o,
    output  logic                      mac8_FU_valid_o,
    output  logic                      mac8_FU_ready_o,
    output  logic   [TRANS_ID_BITS-1:0] mac8_FU_trans_id_o,
    output  exception_t                mac8_FU_exception_o
    );

    logic [3:0][15:0] mult_res;
    logic [17:0]      add_res; 
    
	// Multiplication stage
	for (genvar i = 0; i < 4; ++i) begin
    	assign mult_res[i] = $signed({fu_data_i.operand_a[(i+1)*XLEN/4-1], 
				                            fu_data_i.operand_a[(i+1)*XLEN/4-1:i*XLEN/4]}) 
                             * 
							 $signed({1'b0, fu_data_i.operand_b[(i+1)*XLEN/4-1:i*XLEN/4]});
	end

    // Addition stage
	always_comb begin
		add_res = '0;
		for (int i = 0; i < 4; ++i) begin
			add_res = $signed(add_res) + $signed(mult_res[i]);
		end
	end
    
	// Outputs
    assign mac8_FU_result_o    = 32'(signed'(add_res)); //sign extended result
    assign mac8_FU_valid_o     = mac8_FU_valid_i;
    assign mac8_FU_ready_o     = READY; 
    assign mac8_FU_trans_id_o  = fu_data_i.trans_id;
    assign mac8_FU_exception_o = '0;
    
endmodule
