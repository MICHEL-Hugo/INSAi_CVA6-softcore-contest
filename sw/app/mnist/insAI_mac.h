// Copyright 2023-2024 INSA Toulouse.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Authors: Nell PARTY,              INSA Toulouse
//          Hugo MICHEL,             INSA Toulouse
//          Achille CAUTE,           INSA Toulouse 
//          Diskouna J. GNANGUESSIM, INSA Toulouse
//
// Date   : 11.05.2024
//
// Description : mac8_FU and mix_unit hardware abstraction layer. It consists of wrappers
// around mac8_FU and mix_unit asm instructions. It also contains a function for quick 
// operands loading (mack_pack32).
//
#ifndef __INSAI_MAC__
#define __INSAI_MAC__

#include <stddef.h>   // Required for : size_t
#include <stdint.h>   // Required for : int32_t, uint32_t, uintptr_t

/*
 * MAC8_INIT : - initialize the accumulator register with value0
 *
 * value0    : type : scalar (int32_t)
 *             width: 32 bits
 *             elmt : 32 bits signed value      
 * Note      : value0 may be an rvalue
 */
#define MAC8_INIT(value0)                                                  \
    do {                                                                   \
      int32_t accumulator0 = value0;                                       \
      asm volatile (                                                       \
        "mac8_init %[z], %[x], x0\n\t"                                     \
        : [z] "=&r"((accumulator0))                                        \
        : [x] "r"((accumulator0))                                          \
      );                                                                   \
    } while (0)

/*
 * MAC8_ACC : - compute mac on inputs and weights
 *            - add the result to the accumulator register
 *            - "return" the sum in result
 *
 * inputs   : type : vector (uint32_t)
 *            width: 4 * 8 = 32 bits
 *            elmt : 8 bits unsigned value 
 * weights  : type : vector (uint32_t)
 *            width: 4 * 8 = 32 bits
 *            elmt : 8 bits signed value
 * result   : type : scalar (int32_t)
 *            width: 32 bits
 *            elmt : 32 bits signed value
 */
#define MAC8_ACC(result, inputs, weights)                                  \
    do {                                                                   \
      asm volatile (                                                       \
        "mac8_acc %[z], %[x], %[y]\n\t"                                    \
        : [z] "=&r"((result))                                              \
        : [x] "r"((weights)), [y] "r"((inputs))                            \
      );                                                                   \
    } while (0)                               

/*
 * MAC8_16_ACC  : - compute mac on inputs_array and weights_array
 *                - add the result to the accumulator register
 *                - "return" the sum in result
 *
 * inputs_array : type : vector (uint32_t[4])
 *                width: 16 * 8 = 128 bits
 *                elmt : 8 bits unsigned value 
 * weights_array: type : vector (uint32_t[4])
 *                width: 16 * 8 = 128 bits
 *                elmt : 8 bits signed value
 * result       : type : scalar (int32_t)
 *                width: 32 bits
 *                elmt : 32 bits signed value
 */
#define MAC8_16_ACC(result, inputs_array, weights_array)                   \
    do {                                                                   \
      asm volatile (                                                       \
        "mac8_acc %[z1], %[x1], %[y1]\n\tmac8_acc %[z2], %[x2], %[y2]\n\t" \
        "mac8_acc %[z3], %[x3], %[y3]\n\tmac8_acc %[z4], %[x4], %[y4]\n\t" \
       :  [z1] "=&r"((result)), [z2] "=&r"((result)),                      \
          [z3] "=&r"((result)), [z4] "=&r"((result))                       \
       :  [x1] "r"((weights_array)[0]), [y1] "r"((inputs_array)[0]),       \
          [x2] "r"((weights_array)[1]), [y2] "r"((inputs_array)[1]),       \
          [x3] "r"((weights_array)[2]), [y3] "r"((inputs_array)[2]),       \
          [x4] "r"((weights_array)[3]), [y4] "r"((inputs_array)[3])        \
      );                                                                   \
    } while (0)

/* MIX            : compress this snippet of code 
 *                    {
 *                      //count : 0, 1, 2 or 3
 *                      current_word >>= 8 * count; // logical right shift
 *                      next_word    <<= 8 * count; // logical left  shift
 *                      unaligned_word = (current_word | next_word);
 *                    } 
 *                  into one instruction: 
 *                     {
 *                      MIX (unaligned_word, current_word, next_word)
 *                     }
 * current_word   : type : vector (uint32_t)
 *                  width: 4 * 8 = 32 bits
 *                  elmt : 8 bits signed (resp. unsigned) value
 * next_word      : type : vector (uint32_t)
 *                  width: 4 * 8 = 32 bits
 *                  elmt : 8 bits signed (resp. unsigned) value
 * unaligned_word : type : vector (uint32_t)
 *                  width: 4 * 8 = 32 bits
 *                  elmt : 8 bits signed (resp. unsigned) value
 *
 * Note : At this moment, only count = 2 is supported by the hardware
 * TODO : create LOAD_UNALIGNED macro or rename MIX -> MIX_2
 */
#define MIX(unaligned_word, current_word, next_word)                       \
    do {                                                                   \
      asm volatile (                                                       \
        "mix %[z], %[x], %[y]\n\t"                                         \
        : [z] "=&r"((unaligned_word))                                      \
        : [x] "r"((current_word)), [y] "r"((next_word))                    \
      );                                                                   \
    } while (0)                                               

/*  
 * mac_pack32 : - pack up to 4 bytes from src address into 32 bits word 
 *              - return the new word
 *
 * src        : start address
 * bytes_count: number of bytes to pack
 * return     : type : vector (uint32_t)
 *              width: 4 * 8 = 32 bits
 *              elmt : 8 bits signed/unsigned
 *
 * Notes      : bytes_count should be less than 4. We only pack the first
 *              byte when bytes_count is 0 or greater than 4.
 *
 *              The same result can be achieved with memcpy. 
 *              memcpy uses 4 "lbu" to load contiguous memories: not efficient
 *              we can leverage lw (load word, a word is 32 bits) to produce 
 *              faster code.
 *              mac_pack32 uses 1 lw when the @src is 4 bytes aligned and 
 *              2 "lw" + mix otherwise with little overhead (test + branch)
 *
 *              -> these overhead can result in a loop invariant code when 
 *              use in a loop with iteration step multiple of 4.That's our
 *              case (step = 16/4) 
 *              -> @src is usually 4 bytes aligned.
 */
static inline uint32_t 
mac_pack32(const void*  __restrict src, size_t bytes_count)
{
    switch(bytes_count) {
    case 4 : { 
      int count  = (int)((uintptr_t)src & 0x3); 

      if (count == 0) {  /* The word is 4Bytes aligned */
          return *(uint32_t*)src;
      }
      /* Handle unaligned word */
      uintptr_t c_word_addr = (uintptr_t)src & ~0x3;
      uintptr_t n_word_addr = c_word_addr +  4;
      
      uint32_t c_word = *((uint32_t*)c_word_addr); //load current word
      uint32_t n_word = *((uint32_t*)n_word_addr); //load next    word
      uint32_t unaligned_word;
      MIX(unaligned_word, c_word, n_word);
      return unaligned_word;
    }
    case 2 : {
      int count  = (int)((uintptr_t)src & 0x1); 

      if (count == 0) {  /* The half-word is 2Bytes aligned */
          return *(uint16_t*)src;
      }
      /* Handle unaligned half-word */
      uintptr_t c_half_word_addr = (uintptr_t)src & ~0x1;
      uintptr_t n_half_word_addr = c_half_word_addr +  2;
      
      uint16_t c_half_word = *((uint16_t*)c_half_word_addr);
      uint16_t n_half_word = *((uint16_t*)n_half_word_addr); // BOF !!?
      
      c_half_word >>= 8; // logical right shift
      n_half_word <<= 8; // logical left  shift
      
      return (c_half_word | n_half_word);
    }
    case 3 : {
      const uint8_t* array = (const uint8_t*)src;
      return (array[0] << (8*0)) | (array[1] << (8*1)) | (array[2] << (8*2)); 
    }
    case 1 : {
         __attribute__((fallthrough)); 
    }
    default:
      return *(uint8_t*)src;
    }
}
#endif // __INSAI_MAC__
