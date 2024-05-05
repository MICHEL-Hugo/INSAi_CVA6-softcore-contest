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

#endif // __INSAI_MAC__
