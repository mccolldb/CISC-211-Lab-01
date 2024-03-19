/* 
 * File:   cnano_support.c
 * Author: David McColl
 *
 * Created on February 23, 2024, 10:19 AM
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "definitions.h"                // SYS function prototypes
#include "cnano_support.h"

#define USING_HW 1
#define MAX_PRINT_LEN 400

static volatile bool isRTCExpired = false;
static volatile bool isUSARTTxComplete = true;
static uint8_t uartTxBuffer[MAX_PRINT_LEN] = {0};

#if USING_HW
static void rtcEventHandler(
        RTC_TIMER32_INT_MASK intCause, uintptr_t context) {
    if (intCause & RTC_MODE0_INTENSET_CMP0_Msk) {
        isRTCExpired = true;
    }
}

static void usartDmaChannelHandler(
        DMAC_TRANSFER_EVENT event, uintptr_t contextHandle) {
    if (event == DMAC_TRANSFER_EVENT_COMPLETE) {
        isUSARTTxComplete = true;
    }
}
#endif






void cnano_setup(uint32_t period) // init modules, UART, Timer
{
#if USING_HW
    SYS_Initialize(NULL); // Initialize all modules
    // setup UART DMA channel with callback
    DMAC_ChannelCallbackRegister(DMAC_CHANNEL_0, usartDmaChannelHandler, 0);
    // setup RTC timer with callback
    RTC_Timer32CallbackRegister(rtcEventHandler, 0);
    RTC_Timer32Compare0Set(period);
    RTC_Timer32CounterSet(0);
    RTC_Timer32Start();
#else // using the simulator
    isRTCExpired = true;
    isUSARTTxComplete = true;
#endif //SIMULATOR
}

void cnano_printf(const char *__restrict format, ...) {
    va_list args;
    va_start(args, format);
    vsnprintf((char*) uartTxBuffer, MAX_PRINT_LEN, format, args);
    va_end(args);

#if USING_HW 
    isUSARTTxComplete = false;
    DMAC_ChannelTransfer(DMAC_CHANNEL_0, uartTxBuffer, \
            (const void *) &(SERCOM5_REGS->USART_INT.SERCOM_DATA), \
            strlen((const char*) uartTxBuffer));
    // spin here until UART transmission complete 
    while (isUSARTTxComplete == false);
#endif
}

void cnano_timerwait() {
    while (isRTCExpired == false); /* spin until time expires */
    isRTCExpired = false; /* reset flag for next cycle */
}
