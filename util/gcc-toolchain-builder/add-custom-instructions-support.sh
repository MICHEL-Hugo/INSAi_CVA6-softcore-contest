#!/bin/sh

# Prerequisites:
# sed

# TODO: 
# - add mac8 instruction to the toolchain
# - test custom instructions after building the toolchain

# To be Modified files : 
riscv_opc_c="./src/binutils-gdb/opcodes/riscv-opc.c"
riscv_opc_h="./src/binutils-gdb/include/opcode/riscv-opc.h"

# riscv-opc.h
HEADER="\/* Custom : insAI*\/"
MATCH_MAC8="#define MATCH_MAC8 0x200000b"
MASK_MAC8="#define MASK_MAC8  0xfe00707f"
DECLARE_INSN="DECLARE_INSN(mac8, MATCH_MAC8	, MASK_MAC8)"

MAC8_OPCODE="{\"mac8\",         0, INSN_CLASS_I, \"d,s,t\",     MATCH_MAC8, MASK_MAC8,    match_opcode, 0 },"

echo "[insAI] adding mac8 instruction support...";
# find riscv_opcodes[]  array
# the array is enclosed between two braces ending with a semi-colon
# {[^;};
#grep mac8  $riscv_opc_c #2>/dev/null
#grep -i mac8  $riscv_opc_h #2>/dev/null
#TODO : check before replace
sed -i '/riscv_opcodes/,/^};/ s/^\/\* Terminate/'"$HEADER\n$MAC8_OPCODE\n"'\n&/i' $riscv_opc_c  
sed -i '/#define RISCV_ENCODING_H/,/#endif \/\* RISCV_ENCODING_H/  s/^\/\* Instruction.*$/&\n\n'"$HEADER\n$MATCH_MAC8\n$MASK_MAC8\n"'\n/i' $riscv_opc_h 
sed -i '/#ifdef DECLARE_INSN/, /#endif \/\* DECLARE_INSN \*\// s/#endif \/\* DECLARE_INSN \*\//'"$HEADER\n$DECLARE_INSN\n\n"'&/i' $riscv_opc_h 
