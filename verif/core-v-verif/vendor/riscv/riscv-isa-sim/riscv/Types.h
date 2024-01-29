#pragma once

#include <fesvr/htif.h>
#include <vector>
#include <map>
#include <string>
#include <memory>
#include <thread>
#include <sys/types.h>
#include "Params.h"

typedef struct {
   uint64_t                 nret_id;
   uint64_t                 cycle_cnt;
   uint64_t                 order;
   uint64_t                 insn;
   uint8_t                  trap;
   uint64_t                 cause;
   uint8_t                  halt;
   uint8_t                  intr;
   uint32_t                 mode;
   uint32_t                 ixl;
   uint32_t                 dbg;
   uint32_t                 dbg_mode;
   uint64_t                 nmip;

   uint64_t                 insn_interrupt;
   uint64_t                 insn_interrupt_id;
   uint64_t                 insn_bus_fault;
   uint64_t                 insn_nmi_store_fault;
   uint64_t                 insn_nmi_load_fault;

   uint64_t                 pc_rdata;
   uint64_t                 pc_wdata;

   uint64_t                 rs1_addr;
   uint64_t                 rs1_rdata;

   uint64_t                 rs2_addr;
   uint64_t                 rs2_rdata;

   uint64_t                 rs3_addr;
   uint64_t                 rs3_rdata;

   uint64_t                 rd1_addr;
   uint64_t                 rd1_wdata;

   uint64_t                 rd2_addr;
   uint64_t                 rd2_wdata;

   uint64_t                 mem_addr;
   uint64_t                 mem_rdata;
   uint64_t                 mem_rmask;
   uint64_t                 mem_wdata;
   uint64_t                 mem_wmask;

} st_rvfi;

