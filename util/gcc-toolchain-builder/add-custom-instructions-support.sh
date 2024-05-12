# Copyright 2023-2024 INSA Toulouse.
# Copyright and related rights are licensed under the Solderpad Hardware
# License, Version 0.51 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
# or agreed to in writing, software, hardware and materials distributed under
# this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
# Authors: Nell PARTY,              INSA Toulouse
#          Hugo MICHEL,             INSA Toulouse
#          Achille CAUTE,           INSA Toulouse 
#          Diskouna J. GNANGUESSIM, INSA Toulouse
#
# Date   : 11.05.2024
#
# Description : shell script that adds following instructions to GNU RISCV toolchain :
#                - mac8_init, mac8_acc
#                - mix.
#               It uses a simple find/replace scheme .              
#            
# Prerequisites:
#                - grep
#                - sed

#!/bin/sh

HEADER="\/* Custom : insAI*\/"

# To be Modified files : 
# TEST WHETHER THESES FILES EXIST OR NOT
riscv_opc_c="./src/binutils-gdb/opcodes/riscv-opc.c"
riscv_opc_h="./src/binutils-gdb/include/opcode/riscv-opc.h"

# riscv-opc.h
#  mac8_init
MATCH_MAC8_INIT="#define MATCH_MAC8_INIT 0x200b"
MASK_MAC8_INIT="#define MASK_MAC8_INIT 0xfe00707f"
DECLARE_INSN_MAC8_INIT="DECLARE_INSN(mac8_init, MATCH_MAC8_INIT, MASK_MAC8_INIT)"
#  mac8_acc
MATCH_MAC8_ACC="#define MATCH_MAC8_ACC 0xb"
MASK_MAC8_ACC="#define MASK_MAC8_ACC 0xfe00707f"
DECLARE_INSN_MAC8_ACC="DECLARE_INSN(mac8_acc, MATCH_MAC8_ACC, MASK_MAC8_ACC)"
#  mix
MATCH_MIX="#define MATCH_MIX 0x100b"
MASK_MIX="#define MASK_MIX  0xfe00707f"
DECLARE_INSN_MIX="DECLARE_INSN(mix, MATCH_MIX, MASK_MIX)"

# riscv-opc.c
#  mac8_init
MAC8_INIT_OPCODE="{\"mac8_init\",         0, INSN_CLASS_I, \"d,s,t\",     MATCH_MAC8_INIT, MASK_MAC8_INIT,    match_opcode, 0 },"
#  mac8_acc
MAC8_ACC_OPCODE="{\"mac8_acc\",         0, INSN_CLASS_I, \"d,s,t\",     MATCH_MAC8_ACC, MASK_MAC8_ACC,    match_opcode, 0 },"
#  mix
MIX_OPCODE="{\"mix\",         0, INSN_CLASS_I, \"d,s,t\",     MATCH_MIX, MASK_MIX,    match_opcode, 0 },"

echo "[insAI] adding mac8_acc and mac8_init instruction support...";


grep  -w "MASK_MAC8_ACC\|MASK_MAC8_INIT"  $riscv_opc_h 1>/dev/null 2>&1;
if [ $? -eq 1 ]; then
    sed -i '/#define RISCV_ENCODING_H/, /#endif \/\* RISCV_ENCODING_H/  s/^\/\* Instruction.*$/&\n\n'"$HEADER\n$MATCH_MAC8_ACC\n$MASK_MAC8_ACC\n$MATCH_MAC8_INIT\n$MASK_MAC8_INIT\n"'\n/i' $riscv_opc_h 
	sed -i '/#ifdef DECLARE_INSN/, /#endif \/\* DECLARE_INSN \*\// s/#endif \/\* DECLARE_INSN \*\//'"$HEADER\n$DECLARE_INSN_MAC8_ACC\n$DECLARE_INSN_MAC8_INIT\n\n"'&/i' $riscv_opc_h 
else
	echo "[insAI] mac8_init or mac8_acc is already present in $riscv_opc_h"
fi	

grep  -w "mac8_acc\|mac8_init" $riscv_opc_c 1>/dev/null 2>&1;
if [ $? -eq 1 ]; then
	sed -i '/riscv_opcodes/, /^};/ s/^\/\* Terminate/'"$HEADER\n$MAC8_ACC_OPCODE\n$MAC8_INIT_OPCODE\n"'\n&/i' $riscv_opc_c  
else
	echo "[insAI] mac8_init or mac8_acc instruction is already present in $riscv_opc_c"
fi

echo "[insAI] adding mix instruction support...";

grep  -w mix  $riscv_opc_h 1>/dev/null 2>&1;
if [ $? -eq 1 ]; then
	sed -i '/#define RISCV_ENCODING_H/, /#endif \/\* RISCV_ENCODING_H/  s/^\/\* Instruction.*$/&\n\n'"$HEADER\n$MATCH_MIX\n$MASK_MIX\n"'\n/i' $riscv_opc_h 
	sed -i '/#ifdef DECLARE_INSN/, /#endif \/\* DECLARE_INSN \*\// s/#endif \/\* DECLARE_INSN \*\//'"$HEADER\n$DECLARE_INSN_MIX\n\n"'&/i' $riscv_opc_h 
else
	echo "[insAI] mix instruction is already present in $riscv_opc_h"
fi	

grep  -w mix $riscv_opc_c 1>/dev/null 2>&1
if [ $? -eq 1 ]; then
	sed -i '/riscv_opcodes/,/^};/ s/^\/\* Terminate/'"$HEADER\n$MIX_OPCODE\n"'\n&/i' $riscv_opc_c  
else
	echo "[insAI] mix instruction is already present in $riscv_opc_c"
fi
