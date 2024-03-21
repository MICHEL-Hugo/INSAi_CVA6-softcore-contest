//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: tous le monde
// 
// Create Date: 03/20/2024 05:23:32 PM
// Design Name: 
// Module Name: 
// Project Name: PIR
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// Test de l'unité de mac dans le cv32a6
// 
//////////////////////////////////////////////////////////////////////////////////

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h> //ajoute int8_t et uint8_t
#include <decode.h>

#define NB_LOOP 4

int32_t * Kernel_Val_Ptr;

int8_t Kernel_Val = {23, 56, 29, 35, -34, 45, -34, 56, 0, 3, 4, 67, -3, -127, -34, 12};
uint8_t Image_Val = {34, 255, 76, 23, 23, 0, 0, 0, 56, 22, 35, 44, 43, 78, 123, 145};

int32_t * Kernel_Val_Ptr = &Kernel_Val;
uint32_t * Image_Val_Ptr = &Image_Val;




//---------------------------Fonction MAC utilisant la nouvelle instruction-----------------------------
int32_t Multiple_Accumulate_Test_Instr( uint32_t * ImagePtr, int32_t * KernelPtr){
    int result;
    asm volatile(
        "/*instruction here */": "=r" (result) :  [a5] "r"(*ImagePtr), [a3] "r"(*KernelPtr) :
    );
    return result;
}




//--------------------------Fonction MAC classique (OG)-----------------------------------
int32_t Multiple_Accumulate_OG( uint8_t * ImagePtr, int8_t * KernelPtr){
    //vérifier s'il n'y a pas de pb d'allignement
    int result;
    for(i=0, i++, i<3){
        result = &(ImagePtr + 8*i) * &(KernelPtr + 8*i) + result;
    }
    return result;
}


//----------------------------MAIN-------------------------------------------------
int main(void)
{
    for (i=0; i++; i<(NB_LOOP-1))
    {
        printf("Theorical result = %d \n",  Multiple_Accumucate_OG( Kernel_Val_Ptr + 32*i, Image_Val_Ptr + 32*i))
        printf("Practical result = %d \n", Multiple_Accumulate_Test_Instr( Kernel_Val_Ptr + 32*i, Image_Val_Ptr + 32*i))
    }
    
    return(0);
}