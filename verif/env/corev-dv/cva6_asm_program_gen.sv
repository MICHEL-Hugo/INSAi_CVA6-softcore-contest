/*
 * Copyright 2018 Google LLC
 * Copyright 2020 Andes Technology Co., Ltd.
 * Copyright 2020 OpenHW Group
 * Copyright 2022 Thales DIS design services SAS
 *
 * Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
 *
 * You may obtain a copy of the License at
 *      https://solderpad.org/licenses/
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


`ifndef __CVA6_ASM_PROGRAM_GEN_SV__
`define __CVA6_ASM_PROGRAM_GEN_SV__

//-----------------------------------------------------------------------------------------
// CVA6 assembly program generator - extension of the RISC-V assembly program generator.
//
// Overrides gen_program_header() and gen_test_done()
//-----------------------------------------------------------------------------------------

class cva6_asm_program_gen_c extends riscv_asm_program_gen;

   cva6_instr_sequence_c                cva6_main_program[NUM_HARTS];
   cva6_instr_gen_config_c              cfg_cva6;                 // Configuration class handle

   `uvm_object_utils(cva6_asm_program_gen_c)

   function new (string name = "");
      super.new(name);
   endfunction

  // This is the main function to generate all sections of the program.
  virtual function void gen_program();
    instr_stream.delete();
    // Generate program header
    `DV_CHECK_FATAL($cast(cfg_cva6, cfg), "Could not cast cfg into cfg_cva6")
    gen_program_header();
    for (int hart = 0; hart < cfg_cva6.num_of_harts; hart++) begin
      string sub_program_name[$];
      instr_stream.push_back($sformatf("h%0d_start:", hart));
      if (!cfg_cva6.bare_program_mode) begin
        setup_misa();
        // Create all page tables
        create_page_table(hart);
        // Setup privileged mode registers and enter target privileged mode
        pre_enter_privileged_mode(hart);
      end
      // Init section
      gen_init_section(hart);
      // If PMP is supported, we want to generate the associated trap handlers and the test_done
      // section at the start of the program so we can allow access through the pmpcfg0 CSR
      if (support_pmp) begin
        gen_trap_handlers(hart);
        // Ecall handler
        gen_ecall_handler(hart);
        // Instruction fault handler
        gen_instr_fault_handler(hart);
        // Load fault handler
        gen_load_fault_handler(hart);
        // Store fault handler
        gen_store_fault_handler(hart);
        gen_test_done();
      end
      // Generate sub program
      gen_sub_program(hart, sub_program[hart], sub_program_name, cfg_cva6.num_of_sub_program);
      // Generate main program
      cva6_main_program[hart] = cva6_instr_sequence_c::type_id::create(get_label("cva6_main", hart));
      cva6_main_program[hart].instr_cnt = cfg_cva6.main_program_instr_cnt;
      cva6_main_program[hart].is_debug_program = 0;
      cva6_main_program[hart].label_name = cva6_main_program[hart].get_name();
      generate_directed_instr_stream(.hart(hart),
                                     .label(cva6_main_program[hart].label_name),
                                     .original_instr_cnt(cva6_main_program[hart].instr_cnt),
                                     .min_insert_cnt(1),
                                     .instr_stream(cva6_main_program[hart].directed_instr));
      cva6_main_program[hart].cfg_cva6 = cfg_cva6;
      `DV_CHECK_RANDOMIZE_FATAL(cva6_main_program[hart])
      cva6_main_program[hart].gen_instr(.is_main_program(1), .no_branch(cfg_cva6.no_branch_jump));
      // Setup jump instruction among main program and sub programs
      gen_callstack(cva6_main_program[hart], sub_program[hart], sub_program_name,
                    cfg_cva6.num_of_sub_program);
      `uvm_info(`gfn, "Generating callstack...done", UVM_LOW)
      cva6_main_program[hart].post_process_instr();
      `uvm_info(`gfn, "Post-processing main program...done", UVM_LOW)
      cva6_main_program[hart].generate_unsupported_instr_stream();
      `uvm_info(`gfn, "Generating main program instruction stream...done", UVM_LOW)
      instr_stream = {instr_stream, cva6_main_program[hart].instr_string_list};
      // If PMP is supported, need to jump from end of main program to test_done section at the end
      // of main_program, as the test_done will have moved to the beginning of the program
      instr_stream = {instr_stream, $sformatf("%sj test_done", indent)};
      // Test done section
      // If PMP isn't supported, generate this in the normal location
      if (hart == 0 & !support_pmp) begin
        gen_test_done();
      end
      // Shuffle the sub programs and insert to the instruction stream
      insert_sub_program(sub_program[hart], instr_stream);
      `uvm_info(`gfn, "Inserting sub-programs...done", UVM_LOW)
      `uvm_info(`gfn, "Main/sub program generation...done", UVM_LOW)
      // Program end
      gen_program_end(hart);
      if (!cfg_cva6.bare_program_mode) begin
        if (!riscv_instr_pkg::support_pmp) begin
          // Privileged mode switch routine
          gen_privileged_mode_switch_routine(hart);
        end
        // Generate debug rom section
        if (riscv_instr_pkg::support_debug_mode) begin
          gen_debug_rom(hart);
        end
      end
      gen_section({hart_prefix(hart), "instr_end"}, {"nop"});
    end
    for (int hart = 0; hart < cfg_cva6.num_of_harts; hart++) begin
      // Starting point of data section
      gen_data_page_begin(hart);
      if(!cfg_cva6.no_data_page) begin
        // User data section
        gen_data_page(hart);
        // AMO memory region
        if ((hart == 0) && (RV32A inside {supported_isa})) begin
          gen_data_page(hart, .amo(1));
        end
      end
      // Stack section
      gen_stack_section(hart);
      if (!cfg_cva6.bare_program_mode) begin
        // Generate kernel program/data/stack section
        gen_kernel_sections(hart);
      end
      // Page table
      if (!cfg_cva6.bare_program_mode) begin
        gen_page_table_section(hart);
      end
    end
  endfunction

   virtual function void gen_program_header();
      string str[$];
      cva6_instr_gen_config_c cfg_cva6;
      `DV_CHECK_FATAL($cast(cfg_cva6, cfg), "Could not cast cfg into cfg_cva6")
      if (cfg_cva6.enable_x_extension) begin //used for cvxif custom test
         instr_stream.push_back(".include \"x_extn_user_define.h\"");
      end
      instr_stream.push_back(".include \"user_define.h\"");
      instr_stream.push_back(".globl _start");
      instr_stream.push_back(".section .text");
      if (cfg_cva6.disable_compressed_instr) begin
         instr_stream.push_back(".option norvc;");
      end
      str = {"csrr x5, mhartid"};
      for (int hart = 0; hart < cfg_cva6.num_of_harts; hart++) begin
         str = {str, $sformatf("li x6, %0d", hart),
                     $sformatf("beq x5, x6, %0df", hart)};
      end
      gen_section("_start", str);
      for (int hart = 0; hart < cfg_cva6.num_of_harts; hart++) begin
         instr_stream.push_back($sformatf("%0d: j h%0d_start", hart, hart));
      end
   endfunction

  // Generate the interrupt and trap handler for different privileged mode.
  // The trap handler checks the xCAUSE to determine the type of the exception and jumps to
  // corresponding exeception handling routine.
  virtual function void gen_trap_handler_section(int hart,
                                                 string mode,
                                                 privileged_reg_t cause, privileged_reg_t tvec,
                                                 privileged_reg_t tval, privileged_reg_t epc,
                                                 privileged_reg_t scratch, privileged_reg_t status,
                                                 privileged_reg_t ie, privileged_reg_t ip);
    bit is_interrupt = 'b1;
    string tvec_name;
    string instr[$];
    if (cfg_cva6.mtvec_mode == VECTORED) begin
      gen_interrupt_vector_table(hart, mode, status, cause, ie, ip, scratch, instr);
    end else begin
      // Push user mode GPR to kernel stack before executing exception handling, this is to avoid
      // exception handling routine modify user program state unexpectedly
      push_gpr_to_kernel_stack(status, scratch, cfg_cva6.mstatus_mprv, cfg_cva6.sp, cfg_cva6.tp, instr);
      // Checking xStatus can be optional if ISS (like spike) has different implementation of
      // certain fields compared with the RTL processor.
      if (cfg_cva6.check_xstatus) begin
        instr = {instr, $sformatf("csrr x%0d, 0x%0x # %0s", cfg_cva6.gpr[0], status, status.name())};
      end
      instr = {instr,
               // Use scratch CSR to save a GPR value
               // Check if the exception is caused by an interrupt, if yes, jump to interrupt
               // handler Interrupt is indicated by xCause[XLEN-1]
               $sformatf("csrr x%0d, 0x%0x # %0s", cfg_cva6.gpr[0], cause, cause.name()),
               $sformatf("srli x%0d, x%0d, %0d", cfg_cva6.gpr[0], cfg_cva6.gpr[0], XLEN-1),
               $sformatf("bne x%0d, x0, %0s%0smode_intr_handler",
                         cfg_cva6.gpr[0], hart_prefix(hart), mode)};
    end
    // The trap handler will occupy one 4KB page, it will be allocated one entry in the page table
    // with a specific privileged mode.
    if (SATP_MODE != BARE) begin
      instr_stream.push_back(".align 12");
    end else begin
      instr_stream.push_back($sformatf(".align %d", cfg_cva6.tvec_alignment));
    end
    tvec_name = tvec.name();
    gen_section(get_label($sformatf("%0s_handler", tvec_name.tolower()), hart), instr);
    // Exception handler
    instr = {};
    if (cfg_cva6.mtvec_mode == VECTORED) begin
      push_gpr_to_kernel_stack(status, scratch, cfg_cva6.mstatus_mprv, cfg_cva6.sp, cfg_cva6.tp, instr);
    end
    gen_signature_handshake(instr, CORE_STATUS, HANDLING_EXCEPTION);
    instr = {instr,
             // The trap is caused by an exception, read back xCAUSE, xEPC to see if these
             // CSR values are set properly. The checking is done by comparing against the log
             // generated by ISA simulator (spike).
             $sformatf("csrr x%0d, 0x%0x # %0s", cfg_cva6.gpr[0], epc, epc.name()),
             $sformatf("csrr x%0d, 0x%0x # %0s", cfg_cva6.gpr[0], cause, cause.name()),
             // Breakpoint
             $sformatf("li x%0d, 0x%0x # BREAKPOINT", cfg_cva6.gpr[1], BREAKPOINT),
             $sformatf("beq x%0d, x%0d, %0sebreak_handler",
                       cfg_cva6.gpr[0], cfg_cva6.gpr[1], hart_prefix(hart)),
             // Check if it's an ECALL exception. Jump to ECALL exception handler
             $sformatf("li x%0d, 0x%0x # ECALL_UMODE", cfg_cva6.gpr[1], ECALL_UMODE),
             $sformatf("beq x%0d, x%0d, %0secall_handler",
                       cfg_cva6.gpr[0], cfg_cva6.gpr[1], hart_prefix(hart)),
             $sformatf("li x%0d, 0x%0x # ECALL_SMODE", cfg_cva6.gpr[1], ECALL_SMODE),
             $sformatf("beq x%0d, x%0d, %0secall_handler",
                       cfg_cva6.gpr[0], cfg_cva6.gpr[1], hart_prefix(hart)),
             $sformatf("li x%0d, 0x%0x # ECALL_MMODE", cfg.gpr[1], ECALL_MMODE),
             $sformatf("beq x%0d, x%0d, %0secall_handler",
                       cfg.gpr[0], cfg.gpr[1], hart_prefix(hart)),
             // Page table fault or access fault conditions
             $sformatf("li x%0d, 0x%0x", cfg.gpr[1], INSTRUCTION_ACCESS_FAULT),
             $sformatf("beq x%0d, x%0d, %0sinstr_fault_handler",
                       cfg.gpr[0], cfg.gpr[1], hart_prefix(hart)),
             $sformatf("li x%0d, 0x%0x", cfg.gpr[1], LOAD_ACCESS_FAULT),
             $sformatf("beq x%0d, x%0d, %0sload_fault_handler",
                       cfg.gpr[0], cfg.gpr[1], hart_prefix(hart)),
             $sformatf("li x%0d, 0x%0x", cfg.gpr[1], STORE_AMO_ACCESS_FAULT),
             $sformatf("beq x%0d, x%0d, %0sstore_fault_handler",
                       cfg.gpr[0], cfg.gpr[1], hart_prefix(hart)),
             $sformatf("li x%0d, 0x%0x", cfg.gpr[1], INSTRUCTION_PAGE_FAULT),
             $sformatf("beq x%0d, x%0d, %0spt_instr_fault_handler",
                       cfg.gpr[0], cfg.gpr[1], hart_prefix(hart)),
             $sformatf("li x%0d, 0x%0x", cfg.gpr[1], LOAD_PAGE_FAULT),
             $sformatf("beq x%0d, x%0d, %0spt_load_fault_handler",
                       cfg.gpr[0], cfg.gpr[1], hart_prefix(hart)),
             $sformatf("li x%0d, 0x%0x", cfg.gpr[1], STORE_AMO_PAGE_FAULT),
             $sformatf("beq x%0d, x%0d, %0spt_store_fault_handler",
                       cfg.gpr[0], cfg.gpr[1], hart_prefix(hart)),
             // Illegal instruction exception
             $sformatf("li x%0d, 0x%0x # ILLEGAL_INSTRUCTION", cfg.gpr[1], ILLEGAL_INSTRUCTION),
             $sformatf("beq x%0d, x%0d, %0sillegal_instr_handler",
                       cfg.gpr[0], cfg.gpr[1], hart_prefix(hart)),
             // Instruction Address misaligned exception
             $sformatf("li x%0d, 0x%0x # INSTR ADDR MISALIGNED", cfg.gpr[1], INSTRUCTION_ADDRESS_MISALIGNED),
             $sformatf("beq x%0d, x%0d, %0sinstr_misaligned_handler",
                       cfg.gpr[0], cfg.gpr[1], hart_prefix(hart)),
             // Load Address misaligned exception
             $sformatf("li x%0d, 0x%0x # LOAD ADDR MISALIGNED", cfg.gpr[1], LOAD_ADDRESS_MISALIGNED),
             $sformatf("beq x%0d, x%0d, %0sload_misaligned_handler",
                       cfg.gpr[0], cfg.gpr[1], hart_prefix(hart)),
             // Store Address misaligned exception
             $sformatf("li x%0d, 0x%0x # STORE ADDR MISALIGNED", cfg.gpr[1], STORE_AMO_ADDRESS_MISALIGNED),
             $sformatf("beq x%0d, x%0d, %0sstore_misaligned_handler",
                       cfg.gpr[0], cfg.gpr[1], hart_prefix(hart)),
             // Skip checking tval for illegal instruction as it's implementation specific
             $sformatf("csrr x%0d, 0x%0x # %0s", cfg.gpr[1], tval, tval.name()),
             "1: jal x1, test_done "
           };
    gen_section(get_label($sformatf("%0smode_exception_handler", mode), hart), instr);
  endfunction

  // Trap handling routine
  virtual function void gen_all_trap_handler(int hart);
    string instr[$];
    // If PMP isn't supported, generate the relevant trap handler sections as per usual
    if (!support_pmp) begin
      gen_trap_handlers(hart);
      // Ecall handler
      gen_ecall_handler(hart);
      // Instruction fault handler
      gen_instr_fault_handler(hart);
      // Load fault handler
      gen_load_fault_handler(hart);
      // Store fault handler
      gen_store_fault_handler(hart);
    end
    // Ebreak handler
    gen_ebreak_handler(hart);
    // Illegal instruction handler
    gen_illegal_instr_handler(hart);
    // Instruction page fault handler
    gen_pt_instr_fault_handler(hart);
    // Load page fault handler
    gen_pt_load_fault_handler(hart);
    // Store page fault handler
    gen_pt_store_fault_handler(hart);
    // Instruction Address Misaligned handler
    gen_instr_misaligned_handler(hart);
    // Load Address Misaligned handler
    gen_load_misaligned_handler(hart);
    // Store Address Misaligned handler
    gen_store_misaligned_handler(hart);
    // Generate page table fault handling routine
    // Page table fault is always handled in machine mode, as virtual address translation may be
    // broken when page fault happens.
    gen_signature_handshake(instr, CORE_STATUS, HANDLING_EXCEPTION);
    if(page_table_list != null) begin
      page_table_list.gen_page_fault_handling_routine(instr);
    end else begin
      instr.push_back("nop");
    end
    gen_section(get_label("pt_fault_handler", hart), instr);
  endfunction

  // Helper function to generate the proper sequence of handshake instructions
  // to signal the testbench (see riscv_signature_pkg.sv)
  function void gen_signature_handshake(ref string instr[$],
                                        input signature_type_t signature_type,
                                        core_status_t core_status = INITIALIZED,
                                        test_result_t test_result = TEST_FAIL,
                                        privileged_reg_t csr = MSCRATCH,
                                        string addr_label = "");
    if (cfg.require_signature_addr) begin
      string str[$];
      str = {$sformatf("li x%0d, 0x%0h", cfg.gpr[1], cfg.signature_addr)};
      instr = {instr, str};
      case (signature_type)
        // A single data word is written to the signature address.
        // Bits [7:0] contain the signature_type of CORE_STATUS, and the upper
        // XLEN-8 bits contain the core_status_t data.
        CORE_STATUS: begin
          str = {$sformatf("li x%0d, 0x%0h", cfg.gpr[0], core_status),
                 $sformatf("slli x%0d, x%0d, 8", cfg.gpr[0], cfg.gpr[0]),
                 $sformatf("addi x%0d, x%0d, 0x%0h", cfg.gpr[0],
                           cfg.gpr[0], signature_type),
                 $sformatf("sw x%0d, 0(x%0d)", cfg.gpr[0], cfg.gpr[1])};
          instr = {instr, str};
        end
        // A single data word is written to the signature address.
        // Bits [7:0] contain the signature_type of TEST_RESULT, and the upper
        // XLEN-8 bits contain the test_result_t data.
        TEST_RESULT: begin
          str = {$sformatf("li x%0d, 0x%0h", cfg.gpr[0], test_result),
                 $sformatf("slli x%0d, x%0d, 8", cfg.gpr[0], cfg.gpr[0]),
                 $sformatf("addi x%0d, x%0d, 0x%0h", cfg.gpr[0],
                           cfg.gpr[0], signature_type),
                 $sformatf("sw x%0d, 0(x%0d)", cfg.gpr[0], cfg.gpr[1])};
          instr = {instr, str};
        end
        // The first write to the signature address contains just the
        // signature_type of WRITE_GPR.
        // It is followed by 32 consecutive writes to the signature address,
        // each writing the data contained in one GPR, starting from x0 as the
        // first write, and ending with x31 as the 32nd write.
        WRITE_GPR: begin
          str = {$sformatf("li x%0d, 0x%0h", cfg.gpr[0], signature_type),
                 $sformatf("sw x%0d, 0(x%0d)", cfg.gpr[0], cfg.gpr[1])};
          instr = {instr, str};
          for(int i = 0; i < 32; i++) begin
            str = {$sformatf("sw x%0x, 0(x%0d)", i, cfg.gpr[1])};
            instr = {instr, str};
          end
        end
        // The first write to the signature address contains the
        // signature_type of WRITE_CSR in bits [7:0], and the CSR address in
        // the upper XLEN-8 bits.
        // It is followed by a second write to the signature address,
        // containing the data stored in the specified CSR.
        WRITE_CSR: begin
          if (!(csr inside {implemented_csr})) begin
            return;
          end
          str = {$sformatf("li x%0d, 0x%0h", cfg.gpr[0], csr),
                 $sformatf("slli x%0d, x%0d, 8", cfg.gpr[0], cfg.gpr[0]),
                 $sformatf("addi x%0d, x%0d, 0x%0h", cfg.gpr[0],
                           cfg.gpr[0], signature_type),
                 $sformatf("sw x%0d, 0(x%0d)", cfg.gpr[0], cfg.gpr[1]),
                 $sformatf("csrr x%0d, 0x%0h", cfg.gpr[0], csr),
                 $sformatf("sw x%0d, 0(x%0d)", cfg.gpr[0], cfg.gpr[1])};
          instr = {instr, str};
        end
        default: begin
          `uvm_fatal(`gfn, "signature_type is not defined")
        end
      endcase
    end
 endfunction

  // Illegal instruction trap handler
  virtual function void gen_illegal_instr_handler(int hart);
    string instr[$];
    string str = format_string("illegal_instr_handler_incr_mepc2:", LABEL_STR_LEN);
    gen_signature_handshake(instr, CORE_STATUS, LOAD_FAULT_EXCEPTION);
    gen_signature_handshake(.instr(instr), .signature_type(WRITE_CSR), .csr(MCAUSE));
    instr = {instr,
            $sformatf("csrr  x%0d, mepc", cfg.gpr[0]),
            $sformatf("lbu  x%0d, 0(x%0d)", cfg.gpr[3],cfg.gpr[0]),
            $sformatf("li  x%0d, 0x3", cfg.gpr[2]),
            $sformatf("and  x%0d, x%0d, x%0d", cfg.gpr[3], cfg.gpr[3], cfg.gpr[2]),
            $sformatf("bne  x%0d, x%0d, illegal_instr_handler_incr_mepc2", cfg.gpr[3], cfg.gpr[2]),
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            str,
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            $sformatf("csrw  mepc, x%0d", cfg.gpr[0])
    };
    pop_gpr_from_kernel_stack(MSTATUS, MSCRATCH, cfg.mstatus_mprv, cfg.sp, cfg.tp, instr);
    instr.push_back("mret");
    gen_section(get_label("illegal_instr_handler", hart), instr);
  endfunction

  // ECALL trap handler
  virtual function void gen_ecall_handler(int hart);
    string instr[$];
    string str = format_string("ecall_handler_incr_mepc2:", LABEL_STR_LEN);
    gen_signature_handshake(instr, CORE_STATUS, LOAD_FAULT_EXCEPTION);
    gen_signature_handshake(.instr(instr), .signature_type(WRITE_CSR), .csr(MCAUSE));
    instr = {instr,
            $sformatf("csrr  x%0d, mepc", cfg.gpr[0]),
            $sformatf("lbu  x%0d, 0(x%0d)", cfg.gpr[3],cfg.gpr[0]),
            $sformatf("li  x%0d, 0x3", cfg.gpr[2]),
            $sformatf("and  x%0d, x%0d, x%0d", cfg.gpr[3], cfg.gpr[3], cfg.gpr[2]),
            $sformatf("bne  x%0d, x%0d, ecall_handler_incr_mepc2", cfg.gpr[3], cfg.gpr[2]),
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            str,
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            $sformatf("csrw  mepc, x%0d", cfg.gpr[0])
    };
    pop_gpr_from_kernel_stack(MSTATUS, MSCRATCH, cfg.mstatus_mprv, cfg.sp, cfg.tp, instr);
    instr.push_back("mret");
    gen_section(get_label("ecall_handler", hart), instr);
  endfunction

  // TODO: handshake correct csr based on delegation
  virtual function void gen_instr_fault_handler(int hart);
    string instr[$];
    string str = format_string("instr_fault_handler_incr_mepc2:", LABEL_STR_LEN);
    gen_signature_handshake(instr, CORE_STATUS, LOAD_FAULT_EXCEPTION);
    gen_signature_handshake(.instr(instr), .signature_type(WRITE_CSR), .csr(MCAUSE));
    instr = {instr,
            $sformatf("csrr  x%0d, mepc", cfg.gpr[0]),
            $sformatf("lbu  x%0d, 0(x%0d)", cfg.gpr[3],cfg.gpr[0]),
            $sformatf("li  x%0d, 0x3", cfg.gpr[2]),
            $sformatf("and  x%0d, x%0d, x%0d", cfg.gpr[3], cfg.gpr[3], cfg.gpr[2]),
            $sformatf("bne  x%0d, x%0d, instr_fault_handler_incr_mepc2", cfg.gpr[3], cfg.gpr[2]),
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            str,
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            $sformatf("csrw  mepc, x%0d", cfg.gpr[0])
    };
    pop_gpr_from_kernel_stack(MSTATUS, MSCRATCH, cfg.mstatus_mprv, cfg.sp, cfg.tp, instr);
    instr.push_back("mret");
    gen_section(get_label("instr_fault_handler", hart), instr);
  endfunction

  // TODO: handshake correct csr based on delegation
  virtual function void gen_load_fault_handler(int hart);
    string instr[$];
    string str = format_string("load_fault_handler_incr_mepc2:", LABEL_STR_LEN);
    gen_signature_handshake(instr, CORE_STATUS, LOAD_FAULT_EXCEPTION);
    gen_signature_handshake(.instr(instr), .signature_type(WRITE_CSR), .csr(MCAUSE));
    instr = {instr,
            $sformatf("csrr  x%0d, mepc", cfg.gpr[0]),
            $sformatf("lbu  x%0d, 0(x%0d)", cfg.gpr[3],cfg.gpr[0]),
            $sformatf("li  x%0d, 0x3", cfg.gpr[2]),
            $sformatf("and  x%0d, x%0d, x%0d", cfg.gpr[3], cfg.gpr[3], cfg.gpr[2]),
            $sformatf("bne  x%0d, x%0d, load_fault_handler_incr_mepc2", cfg.gpr[3], cfg.gpr[2]),
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            str,
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            $sformatf("csrw  mepc, x%0d", cfg.gpr[0])
    };
    pop_gpr_from_kernel_stack(MSTATUS, MSCRATCH, cfg.mstatus_mprv, cfg.sp, cfg.tp, instr);
    instr.push_back("mret");
    gen_section(get_label("load_fault_handler", hart), instr);
  endfunction

  // TODO: handshake correct csr based on delegation
  virtual function void gen_store_fault_handler(int hart);
    string instr[$];
    string str = format_string("store_fault_handler_incr_mepc2:", LABEL_STR_LEN);
    gen_signature_handshake(instr, CORE_STATUS, LOAD_FAULT_EXCEPTION);
    gen_signature_handshake(.instr(instr), .signature_type(WRITE_CSR), .csr(MCAUSE));
    instr = {instr,
            $sformatf("csrr  x%0d, mepc", cfg.gpr[0]),
            $sformatf("lbu  x%0d, 0(x%0d)", cfg.gpr[3],cfg.gpr[0]),
            $sformatf("li  x%0d, 0x3", cfg.gpr[2]),
            $sformatf("and  x%0d, x%0d, x%0d", cfg.gpr[3], cfg.gpr[3], cfg.gpr[2]),
            $sformatf("bne  x%0d, x%0d, store_fault_handler_incr_mepc2", cfg.gpr[3], cfg.gpr[2]),
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            str,
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            $sformatf("csrw  mepc, x%0d", cfg.gpr[0])
    };
    pop_gpr_from_kernel_stack(MSTATUS, MSCRATCH, cfg.mstatus_mprv, cfg.sp, cfg.tp, instr);
    instr.push_back("mret");
    gen_section(get_label("store_fault_handler", hart), instr);
  endfunction

  virtual function void gen_pt_instr_fault_handler(int hart);
    string instr[$];
    string str = format_string("pt_instr_fault_handler_incr_mepc2:", LABEL_STR_LEN);
    gen_signature_handshake(instr, CORE_STATUS, LOAD_FAULT_EXCEPTION);
    gen_signature_handshake(.instr(instr), .signature_type(WRITE_CSR), .csr(MCAUSE));
    instr = {instr,
            $sformatf("csrr  x%0d, mepc", cfg.gpr[0]),
            $sformatf("lbu  x%0d, 0(x%0d)", cfg.gpr[3],cfg.gpr[0]),
            $sformatf("li  x%0d, 0x3", cfg.gpr[2]),
            $sformatf("and  x%0d, x%0d, x%0d", cfg.gpr[3], cfg.gpr[3], cfg.gpr[2]),
            $sformatf("bne  x%0d, x%0d, pt_instr_fault_handler_incr_mepc2", cfg.gpr[3], cfg.gpr[2]),
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            str,
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            $sformatf("csrw  mepc, x%0d", cfg.gpr[0])
    };
    pop_gpr_from_kernel_stack(MSTATUS, MSCRATCH, cfg.mstatus_mprv, cfg.sp, cfg.tp, instr);
    instr.push_back("mret");
    gen_section(get_label("pt_instr_fault_handler", hart), instr);
  endfunction

  virtual function void gen_pt_load_fault_handler(int hart);
    string instr[$];
    string str = format_string("pt_load_fault_handler_incr_mepc2:", LABEL_STR_LEN);
    gen_signature_handshake(instr, CORE_STATUS, LOAD_FAULT_EXCEPTION);
    gen_signature_handshake(.instr(instr), .signature_type(WRITE_CSR), .csr(MCAUSE));
    instr = {instr,
            $sformatf("csrr  x%0d, mepc", cfg.gpr[0]),
            $sformatf("lbu  x%0d, 0(x%0d)", cfg.gpr[3],cfg.gpr[0]),
            $sformatf("li  x%0d, 0x3", cfg.gpr[2]),
            $sformatf("and  x%0d, x%0d, x%0d", cfg.gpr[3], cfg.gpr[3], cfg.gpr[2]),
            $sformatf("bne  x%0d, x%0d, pt_load_fault_handler_incr_mepc2", cfg.gpr[3], cfg.gpr[2]),
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            str,
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            $sformatf("csrw  mepc, x%0d", cfg.gpr[0])
    };
    pop_gpr_from_kernel_stack(MSTATUS, MSCRATCH, cfg.mstatus_mprv, cfg.sp, cfg.tp, instr);
    instr.push_back("mret");
    gen_section(get_label("pt_load_fault_handler", hart), instr);
  endfunction

  virtual function void gen_pt_store_fault_handler(int hart);
    string instr[$];
    string str = format_string("pt_store_fault_handler_incr_mepc2:", LABEL_STR_LEN);
    gen_signature_handshake(instr, CORE_STATUS, LOAD_FAULT_EXCEPTION);
    gen_signature_handshake(.instr(instr), .signature_type(WRITE_CSR), .csr(MCAUSE));
    instr = {instr,
            $sformatf("csrr  x%0d, mepc", cfg.gpr[0]),
            $sformatf("lbu  x%0d, 0(x%0d)", cfg.gpr[3],cfg.gpr[0]),
            $sformatf("li  x%0d, 0x3", cfg.gpr[2]),
            $sformatf("and  x%0d, x%0d, x%0d", cfg.gpr[3], cfg.gpr[3], cfg.gpr[2]),
            $sformatf("bne  x%0d, x%0d, pt_store_fault_handler_incr_mepc2", cfg.gpr[3], cfg.gpr[2]),
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            str,
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            $sformatf("csrw  mepc, x%0d", cfg.gpr[0])
    };
    pop_gpr_from_kernel_stack(MSTATUS, MSCRATCH, cfg.mstatus_mprv, cfg.sp, cfg.tp, instr);
    instr.push_back("mret");
    gen_section(get_label("pt_store_fault_handler", hart), instr);
  endfunction

  virtual function void gen_load_misaligned_handler(int hart);
    string instr[$];
    string str = format_string("load_misaligned_handler_incr_mepc2:", LABEL_STR_LEN);
    gen_signature_handshake(instr, CORE_STATUS, LOAD_FAULT_EXCEPTION);
    gen_signature_handshake(.instr(instr), .signature_type(WRITE_CSR), .csr(MCAUSE));
    instr = {instr,
            $sformatf("csrr  x%0d, mepc", cfg.gpr[0]),
            $sformatf("lbu  x%0d, 0(x%0d)", cfg.gpr[3],cfg.gpr[0]),
            $sformatf("li  x%0d, 0x3", cfg.gpr[2]),
            $sformatf("and  x%0d, x%0d, x%0d", cfg.gpr[3], cfg.gpr[3], cfg.gpr[2]),
            $sformatf("bne  x%0d, x%0d, load_misaligned_handler_incr_mepc2", cfg.gpr[3], cfg.gpr[2]),
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            str,
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            $sformatf("csrw  mepc, x%0d", cfg.gpr[0])
    };
    pop_gpr_from_kernel_stack(MSTATUS, MSCRATCH, cfg.mstatus_mprv, cfg.sp, cfg.tp, instr);
    instr.push_back("mret");
    gen_section(get_label("load_misaligned_handler", hart), instr);
  endfunction

  virtual function void gen_store_misaligned_handler(int hart);
    string instr[$];
    string str = format_string("store_misaligned_handler_incr_mepc2:", LABEL_STR_LEN);
    gen_signature_handshake(instr, CORE_STATUS, LOAD_FAULT_EXCEPTION);
    gen_signature_handshake(.instr(instr), .signature_type(WRITE_CSR), .csr(MCAUSE));
    instr = {instr,
            $sformatf("csrr  x%0d, mepc", cfg.gpr[0]),
            $sformatf("lbu  x%0d, 0(x%0d)", cfg.gpr[3],cfg.gpr[0]),
            $sformatf("li  x%0d, 0x3", cfg.gpr[2]),
            $sformatf("and  x%0d, x%0d, x%0d", cfg.gpr[3], cfg.gpr[3], cfg.gpr[2]),
            $sformatf("bne  x%0d, x%0d, store_misaligned_handler_incr_mepc2", cfg.gpr[3], cfg.gpr[2]),
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            str,
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            $sformatf("csrw  mepc, x%0d", cfg.gpr[0])
    };
    pop_gpr_from_kernel_stack(MSTATUS, MSCRATCH, cfg.mstatus_mprv, cfg.sp, cfg.tp, instr);
    instr.push_back("mret");
    gen_section(get_label("store_misaligned_handler", hart), instr);
  endfunction

  virtual function void gen_instr_misaligned_handler(int hart);
    string instr[$];
    string str = format_string("instr_misaligned_handler_incr_mepc2:", LABEL_STR_LEN);
    gen_signature_handshake(instr, CORE_STATUS, LOAD_FAULT_EXCEPTION);
    gen_signature_handshake(.instr(instr), .signature_type(WRITE_CSR), .csr(MCAUSE));
    instr = {instr,
            $sformatf("csrr  x%0d, mepc", cfg.gpr[0]),
            $sformatf("lbu  x%0d, 0(x%0d)", cfg.gpr[3],cfg.gpr[0]),
            $sformatf("li  x%0d, 0x3", cfg.gpr[2]),
            $sformatf("and  x%0d, x%0d, x%0d", cfg.gpr[3], cfg.gpr[3], cfg.gpr[2]),
            $sformatf("bne  x%0d, x%0d, instr_misaligned_handler_incr_mepc2", cfg.gpr[3], cfg.gpr[2]),
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            str,
            $sformatf("addi  x%0d, x%0d, 2", cfg.gpr[0], cfg.gpr[0]),
            $sformatf("csrw  mepc, x%0d", cfg.gpr[0])
    };
    pop_gpr_from_kernel_stack(MSTATUS, MSCRATCH, cfg.mstatus_mprv, cfg.sp, cfg.tp, instr);
    instr.push_back("mret");
    gen_section(get_label("instr_misaligned_handler", hart), instr);
  endfunction

   virtual function void gen_test_done();
      string str = format_string("test_done:", LABEL_STR_LEN);
      instr_stream.push_back(str);
      instr_stream.push_back({indent, "li gp, 1"});
      instr_stream.push_back({indent, "sw gp, tohost, t5"});
      instr_stream.push_back({indent, "wfi"});
   endfunction

endclass : cva6_asm_program_gen_c

`endif // __CVA6_ASM_PROGRAM_GEN_SV__
