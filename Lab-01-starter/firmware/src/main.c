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
    As an added bonus, it will toggle the LED on each iteration
    to provide feedback that the code is actually running.
  
    NOTE: PC serial port MUST be set to 115200 rate.

  Description:
    This file contains the "main" function for a project.  The
    "main" function calls the "SYS_Initialize" function to initialize the state
    machines of all modules in the system
 *******************************************************************************/


// *****************************************************************************
// *****************************************************************************
// Section: Included Files
// *****************************************************************************
// *****************************************************************************

#include <stdio.h>
#include <stddef.h>                     // Defines NULL
#include <stdbool.h>                    // Defines true
#include <stdlib.h>                     // Defines EXIT_FAILURE
#include <string.h>
#include <malloc.h>
#include "definitions.h"                // SYS function prototypes

// Curiosity nano board support
void cnano_setup();
void cnano_printf(const char *format, ...);
void cnano_timerwait();

// static char * pass = "pass";
// static char * fail = "fail";

// VB COMMENT:
// The ARM calling convention permits the use of up to 4 registers, r0-r3
// to pass data into a function. Only one value can be returned to the 
// C caller. The assembly language routine stores the return value
// in r0. The C compiler will automatically use it as the function's return
// value.
//
// Function signature
extern int32_t asmFunc(int32_t num, int32_t denom, int32_t* quot, int32_t* rem);
extern int32_t multFunc(int32_t A, int32_t B, int32_t*product);
extern int32_t printFunc();

// *****************************************************************************
// *****************************************************************************
// Section: Main Entry Point
// *****************************************************************************
// *****************************************************************************

int main(void) // entry point 
{
    cnano_setup();
    int32_t status = -1;
    int32_t numerator = 17; /* starting value */
    int32_t denominator = 3;

    for (uint32_t count = 0; count < 10; count++) // test loop
    {
        status = printFunc();
        cnano_printf("printFunc -> %ld\r\n",status);
        
        // Call our assembly function defined in file asmFunc.s
        int32_t quotient = -1;
        int32_t remainder = -1;
        status = asmFunc(numerator, denominator, &quotient, &remainder);

        cnano_printf(
                "Test:%lu  status=%ld in(%ld/%ld) --> out(%ld rem %ld)\r\n\n",
                count, status, numerator, denominator, quotient, remainder);

        int32_t product = 0;
        status = multFunc(numerator, denominator, &product);

        cnano_printf(
                "Test:%lu  status=%ld in(%ld * %ld) --> out(%ld)\r\n\n",
                count, status, numerator, denominator, product);

        numerator++; // change numerator
        LED0_Toggle(); // Toggle the LED to show we're running a new test case
        cnano_timerwait();
    }
    cnano_printf("==== TESTING COMPLETE =====\r\n\n");
    return ( EXIT_FAILURE);
}
/*******************************************************************************
 End of File
 */

