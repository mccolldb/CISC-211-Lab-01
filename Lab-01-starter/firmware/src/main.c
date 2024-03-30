/*******************************************************************************
  Main Source File

  Company:
    Microchip Technology Inc.

  File Name:
    main.c

  Summary:
    This file contains the "main" function for a project. It is intended to
    be used as the starting point for CISC-211 Curiosity Nano Board
    programming projects. After initializing the hardware, it will
    go into a 0.5s loop that calls an assembly function specified in a separate
    .s file. It will print the iteration number and the result of the assembly 
    function call to the serial port.
  
    NOTE: PC serial port MUST be set to 115200 rate.

  Description:
    This file contains the "main" function for a project. 
    The "main" function calls cnano_setup() 
       to initialize the state machines of all modules in the system
 *******************************************************************************/


// *****************************************************************************
// *****************************************************************************
// Section: Included Files
// *****************************************************************************
// *****************************************************************************
#include <stdint.h>                     // Defines {u}int{NN}_t
#include <stddef.h>                     // Defines NULL
#include <stdbool.h>                    // Defines true
#include <stdlib.h>                     // Defines EXIT_FAILURE
#include "cnano_support.h"

#define INVALID (-1) 
// *****************************************************************************
// *****************************************************************************
// Section: External Function signatures
// *****************************************************************************
// *****************************************************************************
extern int32_t multFunc(int32_t A, int32_t B, int32_t* product);
extern int32_t multiply(int32_t multiplicand, int32_t multiplier);
extern int32_t multiplyM(int32_t multiplicand, int32_t multiplier);
extern int32_t divideFunc(int32_t num, int32_t denom, int32_t* quot, int32_t* rem);
extern int32_t printFunc(uint32_t value);
extern int32_t shiftFunc();
extern void    setup_FP_COPROC();
extern float   FP_add(float a, float b);

// Lab 12 sort arrays**********************************************************
typedef union mapword {
     int32_t  word;
    uint32_t uword;
     int16_t  half[2];
    uint16_t uhalf[2];
     int8_t   byte[4];
    uint8_t  ubyte[4];
} mapword;
extern mapword whole_words;
extern mapword half_words;
extern mapword byte_words;
#define UNSIGNED 0
#define SIGNED 1
#define BYTES 1
#define HALFS 2
#define WORDS 4

extern int32_t asmSort(mapword* addr, uint32_t is_signed, uint32_t size);
extern int32_t asmSwap(mapword* addr, uint32_t is_signed, uint32_t size);
uint32_t dump_array(mapword* array, uint32_t is_signed, uint32_t size);
uint32_t sort_array(mapword* array, uint32_t is_signed, uint32_t size);

//Lab 11 compare float values**************************************************
// use c-union pass/recv float/addr values as int32_t
typedef union map32 {
    float    fvalue;
    int32_t  ivalue;
    float*   f_ptr;
    int32_t* i_ptr;
} map32;

typedef struct float_parts
{
    float   fvalue;
    int32_t Sign;
    int32_t biasedExp;
    int32_t Exp;
    int32_t Mant;
} float_parts;
extern float_parts f1;
extern float_parts f2;
extern float_parts fMax;
extern int32_t* asmFMax(int32_t f1, int32_t f2);
static float fp[][2]={
     // first, second    # sign  exp mant
    { 0.00f, 0.00f }, // 0 +N 
    { 0.00f, 0.00f }, // 1 N+ 
    {-1.00f, 1.00f }, // 2 -+   0=0  =
    { 1.00f,-1.00f }, // 3 +-   0=0  =
    { 1.00f, 1.00f }, // 4 ++   0=0  =
    {-1.00f,-1.00f }, // 5 --   0=0  =
    { 1.00f, 4.00f }, // 6 ++   0<2  =
    { 1.00f, 0.25f }, // 7 ++   0>-2 =
    { 4.00f, 1.00f }, // 8 ++   2>0  =
    { 0.25f, 1.00f }, // 9 ++  -2<0  =
    { 1.33f, 1.14f }, //10 ++   0=0  +-
    { 1.14f, 1.33f }, //11 ++   0=0  -+
    { 1.14f, 0.00f }, //12 ++   0>-  -+
    { 0.00f,-1.33f }, //11 ++   -<0  -+
};
uint32_t numFloatCases = sizeof(fp)/sizeof(fp[0]);

// *****************************************************************************
// *****************************************************************************
// Section: External variables
// *****************************************************************************
// *****************************************************************************
extern int32_t a_Multiplicand;
extern int32_t a_Multiplicand_Sign;
extern int32_t a_Multiplicand_Abs;
extern int32_t b_Multiplier;
extern int32_t b_Multiplier_Sign;
extern int32_t b_Multiplier_Abs;
extern int32_t init_Product;
extern int32_t final_Product;
extern int32_t rng_Error;
extern int32_t prod_Is_Neg;



// *****************************************************************************
// *****************************************************************************
// Section: Global variables
// *****************************************************************************
// *****************************************************************************
static int32_t tc[][2] = {
    //  Mult-and     Mult-er
    {         29,          5}, // ++
    {        -29,         -5}, // --
    {         29,         -5}, // +-
    {        -29,          5}, // -+
//    {        110,          0}, // +0
//    {        -10,          0}, // -0
//    {          0,        110}, // 0+
//    {          0,        -10}, // 0-
//    {    1000000,         10}, // B+
//    {         10,    1000000}, // +B
//    {    1000000,    1000000}, // BB
//    {    -100000,          5}, // b+
//    {          5,    -100000}, // +b
//    {         77,         11}, // ++ normal case, no errs
};
uint32_t numTestCases = sizeof(tc)/sizeof(tc[0]);




// *****************************************************************************
// *****************************************************************************
// Section: Main Entry Point
// *****************************************************************************
// *****************************************************************************
uint32_t dump_array(mapword* array, uint32_t is_signed, uint32_t size)
{
    cnano_printf("dump_array(%08X,%u,%u)\r\n"
                 "-----------------------\r\n",array,is_signed,size);
    uint32_t key = is_signed + size;
    uint32_t   i = 0;
    switch((is_signed<<3)+size)
    {
        case (UNSIGNED<<3)+BYTES:
            for(i=0; array[i].ubyte[0]!=0; i++)
                cnano_printf("ubytes[%2u]=%6lu = %02X\r\n",i,array[i].ubyte[0], array[i].ubyte[0]);
        break;
        case (SIGNED<<3)+BYTES:
            for(i=0; array[i].byte[0]!=0; i++)
                cnano_printf("sbytes[%2u]=%6ld = %02X\r\n",i,array[i].byte[0], array[i].byte[0]);
        break;
        case (UNSIGNED<<3)+HALFS:
            for(i=0; array[i].uhalf[0]!=0; i++)
                cnano_printf("uhalfs[%2u]=%6lu = %04X\r\n",i,array[i].uhalf[0], array[i].uhalf[0]);
        break;
        case (SIGNED<<3)+HALFS:
            for(i=0; array[i].half[0]!=0; i++)
                cnano_printf("shalfs[%2u]=%6ld = %04X\r\n",i,array[i].half[0], array[i].half[0]);
        break;
        case (UNSIGNED<<3)+WORDS:
            for(i=0; array[i].uword!=0; i++)
                cnano_printf("uwords[%2u]=%6lu = %08X\r\n",i,array[i].uword, array[i].uword);
        break;
        case (SIGNED<<3)+WORDS:
            for(i=0; array[i].word!=0; i++)
                cnano_printf("swords[%2u]=%6ld = %08X\r\n",i,array[i].word, array[i].word);
        break;
        default:
                cnano_printf("unknown key=%lu=%02X-----------------------\r\n",key,key);
    }
    cnano_printf("length=%u-----------------------\r\n",i);
    return i;
}

uint32_t sort_array(mapword* array, uint32_t is_signed, uint32_t size)
{
    /*
    const int32_t zero_detect = -1;
    int32_t  total;
    int32_t swaps;
    int32_t swapped;
    int32_t pass;
    int32_t i;
    for(pass=0,total=0,swaps=1; swaps>0; pass++, total+=swaps )
    {   for(i=0, swaps=0, swapped=0; swapped!=zero_detect; i++, swaps+=swapped)
        {   swapped = asmSwap(&array[i],is_signed,size);
            cnano_printf("asmSwap(&array[%d],%u,%u) --> %d\r\n",i,is_signed,size,swapped);
        }
        cnano_printf("pass=%d, swaps=%d\r\n",pass,++swaps);
    }
    cnano_printf("sort_array(addr,%u,%u): passes=%d, swaps=%d\r\n"
                 "-----------------------\r\n",is_signed, size, pass,total);
    */
    int32_t total = asmSort(array, is_signed, size);
    cnano_printf("sort_array(%08X,%u,%u)--> swaps=%d\r\n"
                 "-----------------------\r\n",array, is_signed, size, total);
    return total;
}


int main(void) // entry point 
{
    int32_t  total=0;
    uint32_t length = 0;
    cnano_setup(PERIOD_2S);
    cnano_printf("\r\n\n\nBubbleSort: Array Addresses\r\n");
    cnano_printf("Whole = %08X\r\n"
                 "Half  = %08X\r\n"
                 "Byte  = %08X\r\n",
            &whole_words, &half_words, &byte_words);

    cnano_printf("\r\nSTART BYTEs-----------------------\r\n");
    length = dump_array(&byte_words, SIGNED,BYTES);
    total  = sort_array(&byte_words, SIGNED,BYTES);
    length = dump_array(&byte_words, SIGNED,BYTES);
    total  = sort_array(&byte_words, UNSIGNED,BYTES);
    length = dump_array(&byte_words, UNSIGNED,BYTES);
    cnano_printf("FINISH BYTEs---length=%u-----------------------\r\n",length);
    
    cnano_printf("\r\nSTART HALFs-----------------------\r\n");
    length = dump_array(&half_words, SIGNED,HALFS);
    total  = sort_array(&half_words, SIGNED,HALFS);
    length = dump_array(&half_words, SIGNED,HALFS);
    total  = sort_array(&half_words, UNSIGNED,HALFS);
    length = dump_array(&half_words, UNSIGNED,HALFS);
    cnano_printf("FINISH HALFs--length=%u---------------------\r\n",length);

    cnano_printf("\r\nSTART WORDs-----------------------\r\n");
    length = dump_array(&whole_words, SIGNED,WORDS);
    total  = sort_array(&whole_words, SIGNED,WORDS);
    length = dump_array(&whole_words, SIGNED,WORDS);
    total  = sort_array(&whole_words, UNSIGNED,WORDS);
    length = dump_array(&whole_words, UNSIGNED,WORDS);
    cnano_printf("FINISH WORDs--length=%u---------------------\r\n",length);

    return (EXIT_FAILURE);
//------------------------------------------------------------------------------    
    int32_t status = INVALID; // initialize output value to known/wrong value
    //int32_t numerator = 17; // denominator starting value
    //int32_t denominator = 5; // should have multiple bits ON and OFF

    //status = shiftFunc();

    cnano_printf("start float testing loop...\r\n");
    //setup_FP_COPROC();
    // use c-casting union pass/recv float/addr values as int32_t
    map32 first;
    map32 second;
    map32 addr;
    
    for (uint32_t count = 0; count < 4/*numFloatCases*/; count++) // test loop
    {
        //float f1 = fp[count][0];
        //float f2 = fp[count][1];
        //float result = FP_add(f1,f2);
        //cnano_printf(
        //        "Test:%2lu FP_add  (%10.5f + %10.5f) --> out(%10.5f) \r\n",
        //        count, f1, f2, result);
        
        first.fvalue = fp[count][0];  // initialize with float
        second.fvalue = fp[count][1]; // initialize with float
        if(count==0) second.ivalue = 0x7FC00000; // NaN pattern
        if(count==1) first .ivalue = 0x7FC00000; // NaN pattern
        addr.i_ptr = asmFMax(first.ivalue,second.ivalue);
        cnano_printf(
                "Test:%2lu asmFMax (%10.5f , %10.5f) --> Max(%10.5f) \r\n",
                count, first.fvalue, second.fvalue, *addr.f_ptr);
        cnano_printf(
                "Test:%2lu  f1=%8.5f=(%ld,2^(%03ld-127)=2^%03ld, %06X=%8ld)\r\n",
                count, f1.fvalue, f1.Sign, f1.biasedExp, f1.Exp, f1.Mant, f1.Mant);
        cnano_printf(
                "Test:%2lu  f2=%8.5f=(%ld,2^(%03ld-127)=2^%03ld, %06X=%8ld)\r\n",
                count, f2.fvalue, f2.Sign, f2.biasedExp, f2.Exp, f2.Mant, f2.Mant);
        cnano_printf(
                "Test:%2lu max=%8.5f=(%ld,2^(%03ld-127)=2^%03ld, %06X=%8ld)\r\n",
                count, fMax.fvalue, fMax.Sign, fMax.biasedExp, fMax.Exp, fMax.Mant,fMax.Mant);

        cnano_printf("\r\n");
        cnano_timerwait();
    }
    cnano_printf("==== FLOAT TESTING COMPLETE =====\r\n\n");
    return (EXIT_FAILURE);


    for (uint32_t count = 0; count < numTestCases; count++) // test loop
    {
        int32_t multiplicand = tc[count][0];
        int32_t multiplier   = tc[count][1];
        status = INVALID;
        int32_t product = 0; // initialize output value to known/wrong value
        status = multFunc(multiplicand, multiplier, &product);
        cnano_printf(
                "Test:%2lu multFunc(%10ld * %10ld) --> out(%10ld) status=%ld\r\n",
                count, multiplicand, multiplier, product, status);
        
        /*...
        product = multiply(multiplicand,multiplier);
        cnano_printf(
                "Test:%2lu multiply(%10ld * %10ld) --> out(%10ld) status=%ld\r\n",
                count, multiplicand, multiplier, product, rng_Error);
        cnano_printf("     Multi-and(%ld->%ld,%ld) Multi-er(%ld->%ld,%ld)",
                a_Multiplicand, a_Multiplicand_Sign, a_Multiplicand_Abs,
                b_Multiplier  , b_Multiplier_Sign  , b_Multiplier_Abs);
        cnano_printf(" Product(%ld,%ld->%ld)\r\n", prod_Is_Neg,init_Product, final_Product);
        
        product = multiplyM(multiplicand,multiplier);
        cnano_printf(
                "Test:%2lu multiplyM(%10ld * %10ld) --> out(%10ld) status=%ld\r\n",
                count, multiplicand, multiplier, product, rng_Error);
        cnano_printf("     Multi-and(%ld->%ld,%ld) Multi-er(%ld->%ld,%ld)",
                a_Multiplicand, a_Multiplicand_Sign, a_Multiplicand_Abs,
                b_Multiplier  , b_Multiplier_Sign  , b_Multiplier_Abs);
        cnano_printf(" Product(%ld,%ld->%ld)\r\n", prod_Is_Neg,init_Product, final_Product);
        ...*/
        
        //status = INVALID;
        //status = printFunc(count);
        //cnano_printf("printFunc -> %ld\r\n",status);
        
        // Call our assembly function defined in file asmFunc.s
        //status = INVALID;
        //int32_t quotient = -1;  // initialize output value to known/wrong value
        //int32_t remainder = -1; // initialize output value to known/wrong value
        //status = divideFunc(numerator, denominator, &quotient, &remainder);

        //cnano_printf(
        //        "Test:%lu  status=%ld in(%ld/%ld) --> out(%ld rem %ld)\r\n",
        //        count, status, numerator, denominator, quotient, remainder);

        //status = INVALID;
        //product = 0; // initialize output value to known/wrong value
        //status = multFunc(numerator, denominator, &product);

        //cnano_printf(
        //        "Test:%lu  status=%ld in(%ld * %ld) --> out(%ld)\r\n\n",
        //        count, status, numerator, denominator, product);

        //numerator++; // change numerator
        cnano_printf("\r\n");
        cnano_timerwait();
    }
    cnano_printf("==== TESTING COMPLETE =====\r\n\n");
    return (EXIT_FAILURE);
}
/*******************************************************************************
 End of File
 */

