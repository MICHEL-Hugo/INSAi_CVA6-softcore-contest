//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2024 05:23:32 PM
// Design Name: 
// Module Name: MAC_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

localparam TRANS_ID_BITS = 4;

//Implemented MAC unit is for signed operand A and unsigned operand B
localparam VALID = 1'b1;
localparam READY = 1'b1;

module dummy_FU(
    import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
) 
    input   logic                       clk_i,
    input   logic                       rst_i,
    input   logic                       dummy_FU_valid_i,
    input   logic                       flush_i,
    input   ariane_pkg::fu_data_t       fu_data_i,
    output  riscv::xlen_t               dummy_FU_result_o,
    output  logic                       dummy_FU_valid_o,
    output  logic                       dummy_FU_ready_o,
    output  logic   [TRANS_ID_BITS-1:0] dummy_FU_trans_id_o,
    output  exception_t                 dummy_FU_exception_o
    );
    
    //control signals
    assign dummy_FU_ready_o = READY; //always ready because it is the same than a unit with a unit execution cycle
    assign dummy_FU_exception_o = '0;

    //mulplication
    logic [15:0] mult_d_1, mult_d_2, mult_d_3, mult_d_4; //intermediate registers
    logic [15:0] mult_q_1, mult_q_2, mult_q_3, mult_q_4;
    
    logic mac_valid_1_q, mac_valid_1_d;
    logic   [TRANS_ID_BITS-1:0] trans_id_1_q;
    
    assign mult_d_1 = $signed({fu_data_i.operand_a[1*riscv::XLEN/4-1] & 1'b1, fu_data_i.operand_a[1*riscv::XLEN/4-1:0]}) 
                        * $signed({fu_data_i.operand_b[1*riscv::XLEN/4-1] & 1'b0, fu_data_i.operand_b[1*riscv::XLEN/4-1:0]});
                        
    assign mult_d_2 = $signed({fu_data_i.operand_a[2*riscv::XLEN/4-1] & 1'b1, fu_data_i.operand_a[2*riscv::XLEN/4-1:1*riscv::XLEN/4]}) 
                        * $signed({fu_data_i.operand_b[2*riscv::XLEN/4-1] & 1'b0, fu_data_i.operand_b[2*riscv::XLEN/4-1:1*riscv::XLEN/4]});
                        
    assign mult_d_3 = $signed({fu_data_i.operand_a[3*riscv::XLEN/4-1] & 1'b1, fu_data_i.operand_a[3*riscv::XLEN/4-1:2*riscv::XLEN/4]}) 
                        * $signed({fu_data_i.operand_b[3*riscv::XLEN/4-1] & 1'b0, fu_data_i.operand_b[3*riscv::XLEN/4-1:2*riscv::XLEN/4]});
                        
    assign mult_d_4 = $signed({fu_data_i.operand_a[4*riscv::XLEN/4-1] & 1'b1, fu_data_i.operand_a[4*riscv::XLEN/4-1:3*riscv::XLEN/4]}) 
                        * $signed({fu_data_i.operand_b[4*riscv::XLEN/4-1] & 1'b0, fu_data_i.operand_b[4*riscv::XLEN/4-1:3*riscv::XLEN/4]});
    
    assign mac_valid_1_d = dummy_FU_valid_i && ~flush_i; //result are valid if the unit has been choosen and if the pipeline is not flushed
    
    always_ff @(posedge clk_i or negedge rst_i) begin
    
      if (~rst_i) begin
        mult_q_1 <= 15'd0;
        mult_q_2 <= 15'd0;
        mult_q_3 <= 15'd0;
        mult_q_4 <= 15'd0;
        
        mac_valid_1_q <= ~VALID;
        trans_id_1_q <= '0;
      end 
        
      else begin
        if (mac_valid_1_d == VALID && ~flush_i) begin
            mult_q_1 <= mult_d_1;
            mult_q_2 <= mult_d_2;
            mult_q_3 <= mult_d_3;
            mult_q_4 <= mult_d_4;
            
            mac_valid_1_q <= mac_valid_1_d;
            trans_id_1_q <= fu_data_i.trans_id;
        end 
        
        else begin
            mac_valid_1_q <= ~VALID;
            trans_id_1_q <= '0;
            
            mult_q_1 <= 15'd0;
            mult_q_2 <= 15'd0;
            mult_q_3 <= 15'd0;
            mult_q_4 <= 15'd0;
        end
      end
    end
    
    //mise en place de signaux avertissant que les opérations de multiplications sont terminés
    
    
    //addition stage 1
    logic [16:0] add_q_1, add_q_2; //intermediate registers
    logic [16:0] add_d_1, add_d_2;
    
    logic mac_valid_2_q, mac_valid_2_d;
    logic   [TRANS_ID_BITS-1:0] trans_id_2_q;
    
    
    assign add_d_1 = $signed({mult_q_1[15] & 1'b1, mult_q_1}) + $signed({mult_q_2[15] & 1'b1, mult_q_2});
    assign add_d_2 = $signed({mult_q_3[15] & 1'b1, mult_q_3}) + $signed({mult_q_4[15] & 1'b1, mult_q_4});
    
    assign mac_valid_2_d = mac_valid_1_q && ~flush_i;
    
    always_ff @(posedge clk_i or negedge rst_i) begin
    
      if (~rst_i) begin
        add_q_1 <= 16'd0;
        add_q_2 <= 16'd0;
        
        mac_valid_2_q <= ~VALID;
        trans_id_2_q <= '0;
      end 
      
      else begin
      
        if (mac_valid_2_d == VALID && ~flush_i) begin
            add_q_1 <= add_d_1;
            add_q_2 <= add_d_2;
            
            mac_valid_2_q <= mac_valid_2_d;
            trans_id_2_q <= trans_id_1_q;
        end 
        
        else begin
            mac_valid_2_q <= ~VALID;
            trans_id_2_q <= '0;
            
            add_q_1 <= 16'd0;
            add_q_2 <= 16'd0;
        end
      end
    end
    
    //mise en place de signaux avertissant que les opérations d'addition sont terminés
    
    //addition stage 2
    logic [17:0] add_q_3; //intermediate registers
    logic [17:0] add_d_3;
    
    logic mac_valid_3_q, mac_valid_3_d;
    logic   [TRANS_ID_BITS-1:0] trans_id_3_q;

    
    assign add_d_3 = $signed({add_q_1[16] & 1'b1, add_q_1}) + $signed({add_q_2[15] & 1'b1, add_q_2});
    
    assign mac_valid_3_d = mac_valid_2_q && ~flush_i;
    
    always_ff @(posedge clk_i or negedge rst_i) begin
    
      if (~rst_i) begin
            add_q_3 <= 17'd0;
            
            mac_valid_3_q <= ~VALID;
            trans_id_3_q <= '0;
      end 
      
      else begin
      if (mac_valid_3_d == VALID && ~flush_i) begin
            add_q_3 <= add_d_3;
            
            mac_valid_3_q <= mac_valid_3_d;
            trans_id_3_q <= trans_id_2_q;
        end 
        
        else begin
            mac_valid_3_q <= ~VALID;
            trans_id_3_q <= '0;

            add_q_3 <= 17'd0;
        end
      end
    end
    
    assign dummy_FU_result_o = 32'(signed'(add_q_3));
    assign dummy_FU_valid_o = mac_valid_3_q;
    assign dummy_FU_trans_id_o = trans_id_3_q;
    
    
    
endmodule


