#ifndef __INSAI_MAC__
#define __INSAI_MAC__

#include <stddef.h>   // Required for : size_t
#include <stdint.h>   // Required for : uint32_t
#include <string.h>   // Required for : memcpy  

#define MAC8_ACC(result, inputs, weights)                                  \
    do {                                                                   \
      asm volatile (                                                       \
        "mac8_acc %[z], %[x], %[y]\n\t"                                    \
        : [z] "=&r"((result))                                              \
        : [x] "r"((weights)), [y] "r"((inputs))                            \
      );                                                                   \
    } while (0)                                               

#define MAC8_INIT(accumulator0)                                            \
    do {                                                                   \
      asm volatile (                                                       \
        "mac8_init %[z], %[x], x0\n\t"                                     \
        : [z] "=&r"((accumulator0))                                        \
        : [x] "r"((accumulator0))                                          \
      );                                                                   \
    } while (0)

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

#define MIX(unaligned_word, current_word, next_word)                       \
    do {                                                                   \
      asm volatile (                                                       \
        "mix %[z], %[x], %[y]\n\t"                                         \
        : [z] "=&r"((unaligned_word))                                      \
        : [x] "r"((current_word)), [y] "r"((next_word))                    \
      );                                                                   \
    } while (0)                                               

/* 
 * packs up to 4 bytes from src address into 32 bits word 
 */
static inline uint32_t mac_pack32(const void*  __restrict src, size_t bytes_count)
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
      uint32_t n_word = *((uint32_t*)n_word_addr); //load next    word, BOF!!?
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
      return (array[0] << (8 * 0)) | (array[1] << (8 * 1)) | (array[2] << (8 * 2)); 
    }
    case 1 : {
         __attribute__((fallthrough)); 
    }
    default:
      return *(uint8_t*)src;
    }
}
#endif // __INSAI_MAC__
