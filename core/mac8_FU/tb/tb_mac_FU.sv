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
       /*
        * NOTE : This testbench doesn't take into account 
        * input silencing. (mac8_FU_valid_i ^ fu_data_i)
        */
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
    
    // Monitor outputs
    always @(posedge clk_i) begin
        $display("Result: %d, Valid: %b, Ready: %b", mac8_FU_result_o, mac8_FU_valid_o, mac8_FU_ready_o);
    end

endmodule


