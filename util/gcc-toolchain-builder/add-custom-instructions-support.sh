#!/bin/sh

# Objective: 
# - add mac8 instruction to the toolchain
# - add mix instruction to the toolchain as well

# Prerequisites:
# grep
# sed

HEADER="\/* Custom : insAI*\/"

# To be Modified files : 
riscv_opc_c="./src/binutils-gdb/opcodes/riscv-opc.c"
riscv_opc_h="./src/binutils-gdb/include/opcode/riscv-opc.h"

# riscv-opc.h
MATCH_MAC8="#define MATCH_MAC8 0x200000b"
MASK_MAC8="#define MASK_MAC8  0xfe00707f"
DECLARE_INSN="DECLARE_INSN(mac8, MATCH_MAC8	, MASK_MAC8)"

MATCH_MIX="#define MATCH_MIX 0x200c"
MASK_MIX="#define MASK_MIX  0x707f"
DECLARE_INSN="DECLARE_INSN(mix, MATCH_MIX	, MASK_MIX)"

# riscv-opc.c
MAC8_OPCODE="{\"mac8\",         0, INSN_CLASS_I, \"d,s,t\",     MATCH_MAC8, MASK_MAC8,    match_opcode, 0 },"
MAC8_OPCODE="{\"mix\",         0, INSN_CLASS_S, \"d,s,t\",     MATCH_MIX, MASK_MIX,    match_opcode, 0 },"

echo "[insAI] adding mac8 instruction support...";

grep  -w mac8  $riscv_opc_h 1>/dev/null 2>&1;
if [ $? -eq 1 ]; then
	sed -i '/#define RISCV_ENCODING_H/,/#endif \/\* RISCV_ENCODING_H/  s/^\/\* Instruction.*$/&\n\n'"$HEADER\n$MATCH_MAC8\n$MASK_MAC8\n"'\n/i' $riscv_opc_h 
	sed -i '/#ifdef DECLARE_INSN/, /#endif \/\* DECLARE_INSN \*\// s/#endif \/\* DECLARE_INSN \*\//'"$HEADER\n$DECLARE_INSN\n\n"'&/i' $riscv_opc_h 
else
	echo "[insAI] mac8 instruction is already present in $riscv_opc_h"
fi	

grep  -w mac8 $riscv_opc_c 1>/dev/null 2>&1
if [ $? -eq 1 ]; then
	sed -i '/riscv_opcodes/,/^};/ s/^\/\* Terminate/'"$HEADER\n$MAC8_OPCODE\n"'\n&/i' $riscv_opc_c  
else
	echo "[insAI] mac8 instruction is already present in $riscv_opc_c"
fi

grep  -w mix  $riscv_opc_h 1>/dev/null 2>&1;
if [ $? -eq 1 ]; then
	sed -i '/#define RISCV_ENCODING_H/,/#endif \/\* RISCV_ENCODING_H/  s/^\/\* Instruction.*$/&\n\n'"$HEADER\n$MATCH_mix\n$MASK_mix\n"'\n/i' $riscv_opc_h 
	sed -i '/#ifdef DECLARE_INSN/, /#endif \/\* DECLARE_INSN \*\// s/#endif \/\* DECLARE_INSN \*\//'"$HEADER\n$DECLARE_INSN\n\n"'&/i' $riscv_opc_h 
else
	echo "[insAI] mix instruction is already present in $riscv_opc_h"
fi	

grep  -w mix $riscv_opc_c 1>/dev/null 2>&1
if [ $? -eq 1 ]; then
	sed -i '/riscv_opcodes/,/^};/ s/^\/\* Terminate/'"$HEADER\n$mix_OPCODE\n"'\n&/i' $riscv_opc_c  
else
	echo "[insAI] mix instruction is already present in $riscv_opc_c"
fi