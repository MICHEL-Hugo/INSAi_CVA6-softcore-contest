// 
// Copyright 2021 OpenHW Group
// Copyright 2021 Datum Technology Corporation
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// 
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// 
//     https://solderpad.org/licenses/SHL-2.1/
// 
// Unless required by applicable law or agreed to in writing, any work
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// 


`ifndef __UVMA_OBI_MEMORY_PKG_SV__
`define __UVMA_OBI_MEMORY_PKG_SV__


// Pre-processor macros
`include "uvm_macros.svh"
`include "uvml_hrtbt_macros.sv"
`include "uvma_obi_memory_macros.sv"

// Interfaces / Modules / Checkers
`include "uvma_obi_memory_if.sv"
`include "uvma_obi_memory_assert.sv"
`include "uvma_obi_memory_1p2_assert.sv"
`include "uvma_obi_memory_assert_if_wrp.sv"
`ifdef UVMA_OBI_MEMORY_INC_IF_CHKR
`include "uvma_obi_memory_if_chkr.sv"
`endif


/**
 * Encapsulates all the types needed for an UVM agent capable of driving and/or
 * monitoring Open Bus Interface.
 */
package uvma_obi_memory_pkg;
   
   import uvm_pkg       ::*;
   import uvml_hrtbt_pkg::*;
   import uvml_trn_pkg  ::*;
   import uvml_logs_pkg ::*;
   import uvml_mem_pkg  ::*;
   
   // Constants / Structs / Enums
   `include "uvma_obi_memory_constants.sv"
   `include "uvma_obi_memory_tdefs.sv"
   
   // Objects
   `include "uvma_obi_memory_cfg.sv"
   `include "uvma_obi_memory_cntxt.sv"
   
   // High-level transactions
   `include "uvma_obi_memory_mon_trn.sv"
   `include "uvma_obi_memory_base_seq_item.sv"
   `include "uvma_obi_memory_mstr_seq_item.sv"
   `include "uvma_obi_memory_slv_seq_item.sv"
   
   // Agent componentsmemory_
   `include "uvma_obi_memory_cov_model.sv"
   `include "uvma_obi_memory_drv.sv"
   `include "uvma_obi_memory_mon.sv"
   `include "uvma_obi_memory_sqr.sv"
   `include "uvma_obi_memory_mon_trn_logger.sv"
   `include "uvma_obi_memory_seq_item_logger.sv"
   `include "uvma_obi_memory_agent.sv"
   
   // Sequences
   `include "uvma_obi_memory_seq_lib.sv"
   
   // Misc.
   //`include "uvma_obi_memory_reg_adapter.sv"
   
endpackage : uvma_obi_memory_pkg


`endif // __UVMA_OBI_MEMORY_PKG_SV__
