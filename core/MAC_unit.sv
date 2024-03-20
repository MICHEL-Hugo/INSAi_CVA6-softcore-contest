`timescale 1ns / 1ps
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


//riscv::xlen_t declaration
package riscv;

    localparam XLEN = 32;
    typedef logic [XLEN-1:0] xlen_t;
    
endpackage

module MAC_unit(
//    import ariane_pkg::*;
//#(
//    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
//) 
    input   logic           clk_i,
    input   logic           rst_i,
    input   riscv::xlen_t   operand_a_i, //Kernel (signed)
    input   riscv::xlen_t   operand_b_i, //Image (unsigned)
    output  riscv::xlen_t   result_o
    );
    
    //mulplication
    logic [15:0] mult_o_1, mult_o_2, mult_o_3, mult_o_4; //intermediate registers
    
    always_ff @(posedge clk_i or negedge rst_i) begin
    
      if (~rst_i) begin
        mult_o_1 <= '0;
        //result_o <= '0; ON NE SAIT PAS A VOIR ENSEMBLE (JOHN, le dieu ultime du CVA6)
      end 
      
      else begin
      
        mult_o_1 <= $signed({operand_a_i[1*riscv::XLEN/4-1] & 1'b1, operand_a_i[1*riscv::XLEN/4-1:0]}) 
                        * $signed({operand_b_i[1*riscv::XLEN/4-1] & 1'b0, operand_b_i[1*riscv::XLEN/4-1:0]});
        //les assign variable = value n'étant pas acceptés nous avons mis des '<='
      end
    end
    
    always_ff @(posedge clk_i or negedge rst_i) begin
    
      if (~rst_i) begin
        mult_o_2 <= '0;
        //result_o <= '0; ON NE SAIT PAS A VOIR ENSEMBLE (JOHN, le dieu ultime du CVA6)
      end 
      
      else begin
      
        mult_o_2 <= $signed({operand_a_i[2*riscv::XLEN/4-1] & 1'b1, operand_a_i[2*riscv::XLEN/4-1:1*riscv::XLEN/4]}) 
                        * $signed({operand_b_i[2*riscv::XLEN/4-1] & 1'b0, operand_b_i[2*riscv::XLEN/4-1:1*riscv::XLEN/4]});
     
        //les assign variable = value n'étant pas acceptés nous avons mis des '<='
      end
    end
    
    always_ff @(posedge clk_i or negedge rst_i) begin
    
      if (~rst_i) begin
        mult_o_3 <= '0;
        //result_o <= '0; ON NE SAIT PAS A VOIR ENSEMBLE (JOHN, le dieu ultime du CVA6)
      end 
      
      else begin
        
        mult_o_3 <= $signed({operand_a_i[3*riscv::XLEN/4-1] & 1'b1, operand_a_i[3*riscv::XLEN/4-1:2*riscv::XLEN/4]}) 
                        * $signed({operand_b_i[3*riscv::XLEN/4-1] & 1'b0, operand_b_i[3*riscv::XLEN/4-1:2*riscv::XLEN/4]});
                        
        //les assign variable = value n'étant pas acceptés nous avons mis des '<='
      end
    end
    
    always_ff @(posedge clk_i or negedge rst_i) begin
    
      if (~rst_i) begin
        mult_o_4 <= '0;
        //result_o <= '0; ON NE SAIT PAS A VOIR ENSEMBLE (JOHN, le dieu ultime du CVA6)
      end 
      
      else begin
        mult_o_4 <= $signed({operand_a_i[4*riscv::XLEN/4-1] & 1'b1, operand_a_i[4*riscv::XLEN/4-1:3*riscv::XLEN/4]}) 
                        * $signed({operand_b_i[4*riscv::XLEN/4-1] & 1'b0, operand_b_i[4*riscv::XLEN/4-1:3*riscv::XLEN/4]});
                        
        //les assign variable = value n'étant pas acceptés nous avons mis des '<='
      end
    end
    
    //mise en place de signaux avertissant que les opérations de multiplications sont terminés
    
    
    //addition stage 1
    logic [16:0] add_o_1, add_o_2; //intermediate registers
    
    always_ff @(posedge clk_i or negedge rst_i) begin
    
      if (~rst_i) begin
        add_o_1 <= '0;
        //result_o <= '0; ON NE SAIT PAS A VOIR ENSEMBLE (JOHN, le dieu ultime du CVA6)
      end 
      
      else begin
        add_o_1 <= $signed({mult_o_1[15] & 1'b1, mult_o_1}) + $signed({mult_o_2[15] & 1'b1, mult_o_2});          
        //les assign variable = value n'étant pas acceptés nous avons mis des '<='
      end
    end
    
    always_ff @(posedge clk_i or negedge rst_i) begin
    
      if (~rst_i) begin
        add_o_2 <= '0;
        //result_o <= '0; ON NE SAIT PAS A VOIR ENSEMBLE (JOHN, le dieu ultime du CVA6)
      end 
      
      else begin
        add_o_2 <= $signed({mult_o_3[15] & 1'b1, mult_o_3}) + $signed({mult_o_4[15] & 1'b1, mult_o_4});             
        //les assign variable = value n'étant pas acceptés nous avons mis des '<='
      end
    end
    
    //mise en place de signaux avertissant que les opérations d'addition sont terminés
    
    //addition stage 2
    logic [17:0] add_o_3; //intermediate registers
    
    always_ff @(posedge clk_i or negedge rst_i) begin
    
      if (~rst_i) begin
        add_o_3 <= '0;
        //result_o <= '0; ON NE SAIT PAS A VOIR ENSEMBLE (JOHN, le dieu ultime du CVA6)
      end 
      
      else begin
        add_o_3 <= $signed({add_o_1[16] & 1'b1, add_o_1}) + $signed({add_o_2[15] & 1'b1, add_o_2}); ;         
        //les assign variable = value n'étant pas acceptés nous avons mis des '<='
      end
    end
    
    assign result_o = 32'(signed'(add_o_3));
    
    
    
endmodule


