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

static int32_t tc[][2] = {
    //  Mult-and     Mult-er
    {         29,          5}, // ++
    {        -29,         -5}, // --
    {         29,         -5}, // +-
    {        -29,          5}, // -+
    {        110,          0}, // +0
    {        -10,          0}, // -0
    {          0,        110}, // 0+
    {          0,        -10}, // 0-
    {    1000000,         10}, // B+
    {         10,    1000000}, // +B
    {    1000000,    1000000}, // BB
    {    -100000,          5}, // b+
    {          5,    -100000}, // +b
    {         77,         11}, // ++ normal case, no errs
};
uint32_t numTestCases = sizeof(tc)/sizeof(tc[0]);
// *****************************************************************************
// *****************************************************************************
// Section: Main Entry Point
// *****************************************************************************
// *****************************************************************************
int main(void) // entry point 
{
    cnano_setup(PERIOD_2S);
    int32_t status = INVALID; // initialize output value to known/wrong value
    //int32_t numerator = 17; // denominator starting value
    //int32_t denominator = 5; // should have multiple bits ON and OFF

    //status = shiftFunc();
    cnano_printf("start testing loop...\r\n");
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
    return ( EXIT_FAILURE);
}
/*******************************************************************************
 End of File
 */

