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


 riscv-opc.h
# MATCH_MAC8="#define MATCH_MAC8 0x200000b"
# MASK_MAC8="#define MASK_MAC8  0xfe00707f"

MATCH_MAC8_ACC="#define MATCH_MAC8_ACC 0xb"
MASK_MAC8_ACC="#define MASK_MAC8_ACC 0xfe00707f"
MATCH_MAC8_INIT="#define MATCH_MAC8_INIT 0x200b"
MASK_MAC8_INIT="#define MASK_MAC8_INIT 0xfe00707f"
MATCH_MIX="#define MATCH_MIX 0x200c"
MASK_MIX="#define MASK_MIX  0xfe00707f"


DECLARE_INSN_MAC8_ACC="DECLARE_INSN(mac8_acc, MATCH_MAC8_ACC	, MASK_MAC8_ACC)"
DECLARE_INSN_MAC8_INIT="DECLARE_INSN(mac8_init, MATCH_MAC8_INIT	, MASK_MAC8_INIT)"
DECLARE_INSN_MIX="DECLARE_INSN(mix, MATCH_MIX	, MASK_MIX)"

# riscv-opc.c


MAC8_ACC_OPCODE="{\"mac8_acc\",         0, INSN_CLASS_I, \"d,s,t\",     MATCH_MAC8_ACC, MASK_MAC8_ACC,    match_opcode, 0 },"
MAC8_INIT_OPCODE="{\"mac8_init\",         0, INSN_CLASS_I, \"d,s,t\",     MATCH_MAC8_INIT, MASK_MAC8_INIT,    match_opcode, 0 },"
MIX_OPCODE="{\"mix\",         0, INSN_CLASS_I, \"d,s,t\",     MATCH_MIX, MASK_MIX,    match_opcode, 0 },"

echo "[insAI] adding mac8_acc and mac8_init instruction support...";

grep  -w "MASK_MAC8_ACC\|MASK_MAC8_INIT\|MASK_MIX"  $riscv_opc_h 1>/dev/null 2>&1;
if [ $? -eq 1 ]; then
	sed -i '/#define RISCV_ENCODING_H/,/#endif \/\* RISCV_ENCODING_H/  s/^\/\* Instruction.*$/&\n\n'        \
        "$HEADER\n$MATCH_MAC8_ACC\n$MASK_MAC8_ACC\n$MATCH_MAC8_INIT\n$MASK_MAC8_INIT\n$MATCH_MIX\n$MASK_MIX\n"'\n/i' $riscv_opc_h 
	sed -i '/#ifdef DECLARE_INSN/, /#endif \/\* DECLARE_INSN \*\// s/#endif \/\* DECLARE_INSN \*\//'        \
        "$HEADER\n$DECLARE_INSN_MAC8_ACC\n$DECLARE_INSN_MAC8_INIT\n$DECLARE_INSN_MIX\n\n"'&/i' $riscv_opc_h 
else
	echo "[insAI] mac8_init or mac8_acc is already present in $riscv_opc_h"
fi	

grep  -w "mac8_acc\|mac8_init" $riscv_opc_c 1>/dev/null 2>&1
if [ $? -eq 1 ]; then
	sed -i '/riscv_opcodes/,/^};/ s/^\/\* Terminate/'"$HEADER\n$MAC8_ACC_OPCODE\n$MAC8_INIT_OPCODE\n$MIX_OPCODE\n"'\n&/i' $riscv_opc_c  
else
	echo "[insAI] mac8_init or mac8_acc or mix instructions is already present in $riscv_opc_c"
fi


