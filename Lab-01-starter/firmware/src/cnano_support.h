/* ***********************************************************************/
/** header for support functions for Curiosity Nano board

  @File Name
    cnano_support.h

  @Summary
    support functions for Curiosity Nano board.

  @Description
    define function prototypes and constants for cnano support
 */

#ifndef _CNANO_SUPPORT_H    /* Guard against multiple inclusion */
#define _CNANO_SUPPORT_H
/* Section: Included Files                                                 */

/* Provide C++ Compatibility */
#ifdef __cplusplus
extern "C" {
#endif
    ///Section: Timer Period Constants
    #define PERIOD_500MS                            512
    #define PERIOD_1S                               1024
    #define PERIOD_2S                               2048
    #define PERIOD_4S                               4096

    // Section: Data Types

    // Section: Interface Functions
    // Curiosity Nano board support 
    void cnano_setup(uint32_t period);
    void cnano_printf(const char *format, ...);
    void cnano_timerwait();

/* Provide C++ Compatibility */
#ifdef __cplusplus
}
#endif

#endif /* _CNANO_SUPPORT_H */

