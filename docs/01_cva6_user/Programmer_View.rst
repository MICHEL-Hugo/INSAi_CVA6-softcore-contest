﻿..
   Copyright (c) 2023 OpenHW Group
   Copyright (c) 2023 Thales DIS design services SAS

   SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

.. Level 1
   =======

   Level 2
   -------

   Level 3
   ~~~~~~~

   Level 4
   ^^^^^^^

.. _cva6_programmers_view:

Programmer’s View
=================
RISC-V specifications allow many variations. This chapter provides more details about RISC-V variants available for the programmer.

RISC-V Extensions
-----------------
.. csv-table::
   :widths: auto
   :align: left
   :header: "Extension", "Optional", "RV32","RV64"

   "I- RV32i Base Integer Instruction Set",                             "No","✓","✓"
   "A - Atomic Instructions",                                           "Yes","✓","✓"
   "Zb* - Bit-Manipulation",                                            "Yes","✓","✓"
   "C - Compressed Instructions ",                                      "Yes","✓","✓"
   "Zcb - Code Size Reduction",                                         "Yes","✓","✓"
   "D - Double precsision floating-point",                              "Yes","✗ ","✓"
   "F - Single precsision floating-point",                              "Yes","✓","✓"
   "M - Integer Multiply/Divide",                                       "No","✓","✓"
   "Zicount - Performance Counters",                                    "Yes","✓","✓"
   "Zicsr - Control and Status Register Instructions",                  "No","✓","✓"
   "Zifencei - Instruction-Fetch Fence",                                "No","✓","✓"
   "Zicond - Integer Conditional Operations(Ratification pending)",     "Yes","✓","✓"



RISC-V Privileges
-----------------
.. csv-table::
   :widths: auto
   :align: left
   :header: "Mode"

   "M - Machine"
   "S - Supervior"
   "U - User"


Note: The addition of the H Extension is in the process. After that, HS, VS, and VU modes will also be available.


RISC-V Virtual Memory
---------------------
CV32A6 supports the RISC-V **Sv32** virtual memory when the ``MMUEn`` parameter is set to 1 (and ``Xlen`` is set to 32).

CV64A6 supports the RISC-V **Sv39** virtual memory when the ``MMUEn`` parameter is set to 1 (and ``Xlen`` is set to 64).

By default, CV32A6 and CV64A6 are in RISC-V **Bare** mode. **Sv32** or **Sv39** are enabled by writing 1 to ``satp[0]`` register bit.

When the ``MMUEn`` parameter is set to 0, CV32A6 and CV64A6 are always in RISC-V **Bare** mode; ``satp[0]`` remains at 0 and writes to this register are ignored.

Notes for the integrator:

* The virtual memory is implemented by a memory management unit (MMU) that accelerates the translation from virtual memory addresses (as handled by the core) to physical memory addresses. The MMU integrates translation lookaside buffers (TLB) and a hardware page table walker (PTW). The number of instruction and data TLB entries are configured with ``InstrTlbEntries`` and ``DataTlbEntries``.

* The CV32A6 MMU will evolve with a microarchitectural optimization featuring two levels of TLB: level 1 TBL (sized by ``InstrTlbEntries`` and ``DataTlbEntries``) and a shared level 2 TLB. This optimization remains to be implemented in CV64A6. The optimization has no consequences on the programmer's view.

* The addition of the hypervisor support will come with **Sv39x4** virtual memory that is not yet documented here.

Memory Alignment
----------------
CVA6 **does not support non-aligned** memory accesses.

Harts
-----
CVA6 features a **single hart**, i.e. a single hardware thread.

Therefore the words *hart* and *core* have the same meaning in this guide.

