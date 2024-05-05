#ifndef __INSAI_MAC__
#define __INSAI_MAC__

#include <stddef.h>   // Required for : size_t
#include <stdint.h>   // Required for : uint32_t
	
#define MAC8(res, in, wgt)                                                     \
		do {                                                                   \
			asm volatile (                                                     \
				"mac8 %[z], %[x], %[y]\n\t"                                    \
				: [z] "=&r"((res))                                             \
				: [x] "r"((wgt)), [y] "r"((in))                                \
			);                                                                 \
		} while (0)

#define MAC8_16(res_array, in_array, wgt_array)                                \
		do {                                                                   \
			asm volatile (                                                     \
			  "mac8 %[z1], %[x1], %[y1]\n\t " "mac8 %[z2], %[x2], %[y2]\n\t "  \
			  "mac8 %[z3], %[x3], %[y3]\n\t " "mac8 %[z4], %[x4], %[y4]\n\t "  \
			 :  [z1] "=&r"((res_array)[0]), [z2] "=&r"((res_array)[1]),        \
				[z3] "=&r"((res_array)[2]), [z4] "=&r"((res_array)[3])         \
			 :  [x1] "r"((wgt_array)[0]), [y1] "r"((in_array)[0]),             \
				[x2] "r"((wgt_array)[1]), [y2] "r"((in_array)[1]),             \
				[x3] "r"((wgt_array)[2]), [y3] "r"((in_array)[2]),             \
				[x4] "r"((wgt_array)[3]), [y4] "r"((in_array)[3])              \
			);                                                                 \
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

			count *= 8; // part of word in the next word 
						// [8, 16, 24] bits
			
			c_word >>= count; // logical right shift
			n_word <<= count; // logical left  shift
			
			return (c_word | n_word);
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

			// count *= 8; // 8 bits
			
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
