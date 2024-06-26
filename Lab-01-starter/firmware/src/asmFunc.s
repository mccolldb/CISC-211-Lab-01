/*** asmFunc.s   ***/

#include <xc.h>
.include "Fixed_point_macros.inc" 
// Lab 12 Sorting sized Values**************************************************
.data
.align 4
.global whole_words,half_words,byte_words
whole_words: .word 0xFFFF8002, 0xFFFF8001, 0x00007000, 0x00003300 
             .word 0x00004000, 0x00004001, 0x00004005, 0x00000000

half_words:  .word 0x11118002, 0x22228001, 0x33337000, 0x44440330
             .word 0x55554000, 0x66664001, 0x77774005, 0x88880000

byte_words:  .word 0x11111182, 0x22222281, 0x33333370, 0x44444433
             .word 0x55555550, 0x66666641, 0x77777785, 0x88888800 
    
.text
.syntax unified //allow both 16b and 32b extended Thumb2 instructions
.align
.EQU UNSIGNED, 0
.EQU   SIGNED, 1
.EQU   BYTES,  1
.EQU   HALFS,  2
.EQU   WORDS,  4
.EQU ZERO_DETECT, -1
.global asmSort
.type asmSort,%function
asmSort:// int32 count = asmSort(int32* addr, uint32 signed, uint32 size)
        //         R0                    R0           R1=0,1   R2=1,2,4
    push {r4-r11,LR} /* save the caller's registers */
    MOV R3,R0       // save array base addr
    MOV R5,0        // init total swap counter
next_outer:
    MOV R4,R3       // reset array addr to base addr
    MOV R6,0        // reset pass swaps
next_inner:
    MOV R0,R4        // get addr array[i]
    BL  asmSwap      // call swap (note: R1, R2 same as passed in)
    CMP R0,ZERO_DETECT
    BEQ end_inner
    ADD R6,R0        // accumulate swaps this pass
    ADD R4,4         // point addr to next 32bit word
    B   next_inner
end_inner:
    CBZ R6, set_sort_return  // no new swaps -- we are done sorting
    ADD R5,R6        // accum total swaps
    b next_outer
    
set_sort_return:
    MOV R0,R5        // set return value = total swaps
    pop  {r4-r11,PC} /* save the caller's registers */

.global asmSwap
.type asmSwap,%function
asmSwap:// uint32 swapped = asmSwap(int32* addr, uint32 signed, uint32 size) 
        //         R0=0,1                  R0           R1=0,1   R2=1,2,4
	// note: R1,R2 used but not changed  -- R0 is retrun value 
    push {r4-r11,LR} /* save the caller's registers */
    MOV R6,ZERO_DETECT    // default return value
check_8bit:
    CMP R2,BYTES        // check size
    BNE check_16bit
    CMP R1,SIGNED        // select signed/unsigned load
    LDRSBEQ R4,[R0]
    LDRSBEQ R5,[R0,4]
    LDRBNE R4,[R0]
    LDRBNE R5,[R0,4]
    CBZ R4,set_swap_return
    CBZ R5,set_swap_return
    CMP R4,R5        // check if first > second
    STRBGT R5,[R0]   // write back in reverse order
    STRBGT R4,[R0,4]
    MOVGT R6,1       // mark as swapped
    MOVLE R6,0       // else no swap
    B set_swap_return
    
check_16bit:
    CMP R2,HALFS      // check size
    BNE check_32bit
    CMP R1,SIGNED      // select signed/unsigned load
    LDRSHEQ R4,[R0]
    LDRSHEQ R5,[R0,4]
    LDRHNE R4,[R0]
    LDRHNE R5,[R0,4]
    CBZ R4,set_swap_return
    CBZ R5,set_swap_return
    CMP R4,R5
    STRHGT R5,[R0]
    STRHGT R4,[R0,4]
    MOVGT R6,1
    MOVLE R6,0
    B set_swap_return
    
check_32bit:
    LDR R4,[R0]
    LDR R5,[R0,4]
    CBZ R4,set_swap_return
    CBZ R5,set_swap_return
    CMP R1,SIGNED
    BNE unsigned_compare
    CMP R4,R5
    STRGT R5,[R0]
    STRGT R4,[R0,4]
    MOVGT R6,1
    MOVLE R6,0
    B set_swap_return
unsigned_compare:
    CMP R4,R5
    STRHI R5,[R0]
    STRHI R4,[R0,4]
    MOVHI R6,1
    MOVLS R6,0
    B set_swap_return
    
set_swap_return:
    MOV R0,R6  // set return value
    pop  {r4-r11,PC} /* save the caller's registers */

// Lab 11 Comparing Float Values***********************************************
.data
.align 4
// structure offsets...
.EQU FLOAT_OFF,	    0x0
.EQU SIGN_OFF,	    0x4
.EQU BIASED_OFF,    0x8
.EQU EXP_OFF,	    0xC
.EQU MANT_OFF,	    0x10
.global f1,f2,fMax
f1:	     .word 0,0,0,0,0
f2:	     .word 0,0,0,0,0
fMax:	     .word 0,0,0,0,0
NaN_struct:  .word 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF
  
# Tell the assembler that what follows is in instruction memory    
.text
.syntax unified //allow both 16b and 32b extended Thumb2 instructions
.align

.global asmFMax
.type asmFMax,%function
asmFMax:
    /* float* max=R0 = asmFMax(float f1=R0, float f2=R1)* fMax=R2, addr=R3 */
    push {r4-r11,LR} /* save the caller's registers */
    /* save inputs & initialize output values */
    /* Note: initialize to NaN_struct so easy to see values being filled */
    mov r5,R0   // save R0,R1 inputs while initing structs
    mov r6,R1
    LDR R0,=NaN_struct     // R0= addr(copy from struct)
    
    LDR R1,=f1             // R1= addr(copy  to  struct)
    bl copy_struct         // init f1 struct
    STR R5,[R1,FLOAT_OFF]  // fill f1.fvalue
 
    LDR R1,=f2             // R1= addr(copy to struct)
    bl copy_struct         // init f2 struct
    STR R6,[R1,FLOAT_OFF]  // fill f2.fvalue
 
    LDR R1,=fMax           // R1= addr(copy to struct)
    bl copy_struct         // init fMax struct
   
    /* analyze the two floating point values */
    LDR R0,=f1             // R0= struct to extract
    BL  extract_parts
    LDR R0,=f2             // R0= struct to extract
    BL  extract_parts
    
check_NaN: // check if either is NaN => copy to fMax
    .EQU NaN,0x7FC00000
    LDR R5,=NaN
    
    LDR R0,=f1            // R0= addr(copy from struct)
    LDR R1,[R0,FLOAT_OFF] // read value
    CMP R1,R5             // check
    BEQ return_fMax
    
    LDR R0,=f2            // R0= addr(copy from struct)
    LDR R1,[R0,FLOAT_OFF] // read value
    CMP R1,R5             // check
    BEQ return_fMax
    
    LDR R0,=f1   // setup base pointers - common forech check            
    LDR R1,=f2           

check_sign:
    LDR R2,[R0,SIGN_OFF]
    LDR R3,[R1,SIGN_OFF]
    CMP R2,R3
    BEQ check_exp // signs same
    CMP R2,0      // signs differ, 
    LDREQ R0,=f1  // f1.sign is positive => choose f1
    LDRNE R0,=f2  // f1.sign is negative => choose f2
    b return_fMax

check_exp:
    LDR R2,[R0,BIASED_OFF]
    LDR R3,[R1,BIASED_OFF]
    CMP R2,R3
    BEQ check_mant // exps same
    LDRGE R0,=f1   // f1.exp>f2.exp => choose f1
    LDRLT R0,=f2   // f1.exp<f2.exp => choose f2
    b return_fMax

check_mant:
    LDR R2,[R0,MANT_OFF]
    LDR R3,[R1,MANT_OFF]
    CMP R2,R3
    LDRGE R0,=f1  // f1.mant>=f2.mant => choose f1
    LDRLT R0,=f2  // f1.mant< f2.mant => choose f2
    b return_fMax
    
return_fMax:// expect R0 = addr(copy from struct)
    LDR R1,=fMax     // R1 = addr(copy  to  struct)
    bl  copy_struct
    LDR R0,=fMax    // return address of fMax
    pop {r4-r11,PC} /* restore the caller's registers */

// local function
extract_parts: // void  extract_parts(struct float_parts*=R0)
    // R0-R3 unchanged,R0=float value R4=field value, R5=struct base addr, R6=Mask
    push {R4-R6,LR} /* save the caller's registers */
    MOV R5,R0             // R5 = base of structure
    LDR R0,[R5,FLOAT_OFF] // R4 = value of float
    LSR R4,R0,31          // R4 = field bits; get sign bit
    STR R4,[R5,SIGN_OFF]  // save sign bit
    
    LSR R4,R0,23          // shift out mantissa
    AND R4,0xFF           // mask 8 bit exp field
    STR R4,[R5,BIASED_OFF]// save biased exp
    SUB R4,127            // unbias
    STR R4,[R5,EXP_OFF]   // save exp
    
    LDR R6,=0x007FFFFF   // mantissa mask bits
    AND R4,R0,R6         // and-out non-mantissa bits
    STR R4,[R5,MANT_OFF] // save mant
    pop {R4-R6,PC} /* restore the caller's registers */

// local function
copy_struct: // R0= from_struct addr, R1 = to_struct addr
    push {r4,LR} /* save the caller's registers */    
    LDR R4,[R0,FLOAT_OFF]  // read
    STR R4,[R1,FLOAT_OFF]  // write
    LDR R4,[R0,SIGN_OFF]
    STR R4,[R1,SIGN_OFF]
    LDR R4,[R0,BIASED_OFF]
    STR R4,[R1,BIASED_OFF]
    LDR R4,[R0,EXP_OFF]
    STR R4,[R1,EXP_OFF]
    LDR R4,[R0,MANT_OFF]
    STR R4,[R1,MANT_OFF]
    pop {r4,PC} /* restore the caller's registers */
	

 // Multiply Lab -- three versions*********************************************
.data
.align 4
.global rng_Error, a_Multiplicand, a_Multiplicand_Sign, a_Multiplicand_Abs
.global b_Multiplier, b_Multiplier_Sign, b_Multiplier_Abs, prod_Is_Neg
.global init_Product, final_Product
a_Multiplicand:      .word 0
a_Multiplicand_Sign: .word 0 
a_Multiplicand_Abs:  .word 0 
b_Multiplier:        .word 0
b_Multiplier_Sign:   .word 0 
b_Multiplier_Abs:    .word 0 
rng_Error:           .word 0
init_Product:        .word 0 
final_Product:       .word 0 
prod_Is_Neg:         .word 0
	 
.text
.syntax unified //allow both 16b and 32b extended Thumb2 instructions
.align
.EQU MAX16, 0x00007FFF
.EQU MIN16, 0xFFFF8000
.global multiply
.type multiply,%function
/*int32_t product=R0 = multiply(int32_t multiplicand=R0, int32_t multiplier=R1) */
/* temporary: R3 = LDR/STR address; r2= LDR/STR value r4=neg sign counter */
multiply: 
    push {r4-r11,LR} /* save the caller's registers */
    /* initialize output values */
    LDR r2,=0   // default to no error
    LDR r3,=rng_Error
    STR r2,[r3]
    
    LDR r2,=0xFFFFFFFF  //signal value for unset values
    LDR r3,= a_Multiplicand
    STR r0,[r3]
    LDR r3,=a_Multiplicand_Sign
    STR r2,[r3]
    LDR r3,=a_Multiplicand_Abs
    STR r2,[r3]
    
    LDR r3,= b_Multiplier
    STR r1,[r3]
    LDR r3,=b_Multiplier_Sign
    STR r2,[r3]
    LDR r3,=b_Multiplier_Abs
    STR r2,[r3]
    

    LDR r3,=prod_Is_Neg
    STR r2,[r3]
    LDR r3,=init_Product
    STR r2,[r3]
    LDR r3,=final_Product
    STR r2,[r3]
    
    /* check range of both values >MAX16 | <MIN16 */
    LDR r2,=MAX16
    CMP r0,r2
    BGT range_error
    CMP r1,r2
    BGT range_error
    LDR r2,=MIN16
    CMP r0,r2
    BLT range_error
    CMP r1,r2
    BLT range_error

    /* save signs & abs of both values & set prod_Is_Neg*/
    mov r4,0           // init neg sign counter = 0
    /* process multi-and in R0 */
    mov r2,r0, LSR 31  // extract sign bit
    LDR r3,=a_Multiplicand_Sign
    STR r2,[r3]        // save sign bit
    CMP r2,1           // if signbit==1
    NEGEQ r0,r0        //     make abs value
    ADDEQ r4,r4,1      //     inc neg count
    LDR r3,=a_Multiplicand_Abs
    STR r0,[r3]        // save abs value

    /* process multi-er in R1 */
    mov r2,r1, LSR 31  // extract sign bit
    LDR r3,=b_Multiplier_Sign
    STR r2,[r3]        // save sign bit
    CMP r2,1           // if signbit==1
    NEGEQ r1,r1        //     make abs value
    ADDEQ r4,r4,1      //     inc neg count
    LDR r3,=b_Multiplier_Abs
    STR r1,[r3]        // save abs value
    
    AND r4,r4,1        // get LSB of neg counter
    LDR r3,=prod_Is_Neg
    STR r4,[r3]        // save prod_Is_Neg flag
    
    /* multiply abs values --> init_product */
    LDR R0,=a_Multiplicand_Abs
    LDR r0,[r0]
    ldr r1,=b_Multiplier_Abs
    ldr r1,[r1]
    ldr r2,=init_Product
    BL multFunc   
    
    /* check prod_Is_Neg --> final_Product */
    ldr r0,=init_Product
    ldr r0,[r0]
    ldr r1,=prod_Is_Neg
    ldr r1,[r1]
    CMP r1,1
    NEGEQ r0,r0
    ldr r3,=final_Product
    STR r0,[r3]
    b set_return
    
range_error:
    mov r2,1
    LDR r3,=rng_Error
    STR r2,[r3]
    /* fall thru */
set_return:
    LDR r0,=final_Product  /* retrieve return value */
    LDR r0,[r0]
    pop {r4-r11,PC} /* restore the caller's registers & return */

/* int status = multFunc(int A=r0, int B=r1, int* C=r2) R3=accumulator */    
.global multFunc
.type multFunc,%function
multFunc: 
    //push {LR}  /* save caller state & LR */
    mov r3,0      /* initialize accumulator */
1:
    TST R0,1        /* Z=1 if lobit of shifted A clear */
    ADDNE r3,r3,r1  /* if Z==0 add copy of shifted B into accum  */
    LSL  R1,R1,1    /* double B  */
    LSRS R0,R0,1    /* halve A */
    BNE 1b          /* loop if A not yet zero */
    STR R3,[R2]     /* save completed accumulator to provided address */
    mov R0,0        /* return good status */
    //pop {PC}      /* restore caller state & LR->PC */ 
    MOV PC,LR       /* return to caller */

.macro READ value,address
    LDR \value,=\address
    LDR \value,[\value]
.endm
.macro WRITE value,temp,address
    LDR \temp,=\address
    STR \value,[\temp]
.endm
.macro IF left,rel,right,target
    CMP \left,\right
    B\rel \target
.endm
.macro SPLIT value,count,sign,abs  // uses R2,R3 as scratch
    /* process value in \value */
    mov R2,\value, LSR 31  // extract sign bit
    WRITE R2,R3,\sign      // save sign bit
    CMP R2,1               // if signbit==1
    NEGEQ \value,\value    //     make abs value
    ADDEQ \count,\count,1  //     inc neg count
    WRITE \value,R3,\abs   // save abs value
.endm
    
.macro multMacro A,B,P
    mov \P,0      /* initialize accumulator */
1:
    TST \A,1        /* Z=1 if lobit of shifted A clear */
    ADDNE \P,\P,\B  /* if Z==0 add copy of shifted B into accum  */
    LSL  \B,\B,1    /* double B  */
    LSRS \A,\A,1    /* halve A */
    BNE 1b          /* loop if A not yet zero */
.endm

.global multiplyM
.type multiplyM,%function
/*int32_t product=R0 = multiply(int32_t multiplicand=R0, int32_t multiplier=R1) */
/* temporary: R2= LDR/STR value; R3 = LDR/STR address;  r4=neg sign counter */
multiplyM: 
    push {r4,LR} /* save the caller's R4 */
    /* initialize output values */
    LDR r2,=0   // default to no error
    WRITE r2,r3,rng_Error
    LDR r2,=0xFFFFFFFF  //signal value for unset values
    WRITE R0,R3, a_Multiplicand
    WRITE R2,R3, a_Multiplicand_Sign
    WRITE R2,R3, a_Multiplicand_Abs
    WRITE R1,R3, b_Multiplier
    WRITE R2,R3, b_Multiplier_Sign
    WRITE R2,R3, b_Multiplier_Abs    
    WRITE R2,R3, prod_Is_Neg
    WRITE R2,R3, init_Product
    WRITE R2,R3, final_Product
    
    /* check range of both values >MAX16 | <MIN16 */
    LDR R2,=MAX16
    IF R0,GT,R2,2f
    IF R1,GT,R2,2f
    LDR R2,=MIN16
    IF R0,LT,R2,2f
    IF R1,LT,R2,2f

    /* save signs & abs of both values & set prod_Is_Neg*/
    MOV   R4,0           // init neg sign counter = 0
    SPLIT R0,R4,a_Multiplicand_Sign,a_Multiplicand_Abs
    SPLIT R1,R4,b_Multiplier_Sign,b_Multiplier_Abs
    AND   R4,R4,1        // get LSB of neg counter
    WRITE R4,R3,prod_Is_Neg // save prod_Is_Neg flag
    
    /* call to multiply abs values --> init_product */
    READ R0,a_Multiplicand_Abs
    READ R1,b_Multiplier_Abs
    multMacro R0,R1,R2  /* uses local label 1 */
    WRITE R2,R3,init_Product
    
    /* check prod_Is_Neg --> final_Product */
    READ R0,init_Product
    READ R1,prod_Is_Neg
    CMP r1,1      // if prod_Is_Neg
    NEGEQ r0,r0   //    NEG init_product
    WRITE R0,R3,final_Product
    b 1f
2:  // range_error
    MOV   R2,1    // set error flag
    WRITE R2,R3,rng_Error
    /* fall thru */
1:  // set_return
    READ R0,final_Product  /* retrieve return value */
    pop {r4,PC} /* restore the caller's registers & return */
    
/*===========================================================================*/
 /* function: asmMain
 *    inputs:   r0: contains packed value to be multiplied
 *                  using shift-and-add algorithm
 *           where: MSB 16bits is signed multiplicand (a)
 *                  LSB 16bits is signed multiplier (b)
 *    outputs:  r0: final product: sign-corrected product
 *                  of the two unpacked A and B input values
 */  
.global asmMain
.type asmMain,%function
/* int product =asmMain(packed value) */
/*       R0                    R0     Temp=R1,R2,R3*/
asmMain:
    push {r4-r11,LR} /* save the caller's registers */
 /* Step 1: call asmUnpack ->  a_Multiplicand, b_Multiplier */
 /* void asmUnpack(int value, int* a_addr, int* b_addr)         */
    MOV R0,R0  // packed value already  in R0
    LDR R1,=a_Multiplicand
    LDR R2,=b_Multiplier
    BL  asmUnpack
    
/* Step 2a: call asmAbs for the multiplicand (A). */
/* int32 abs = asmAbs(int value,int* abs_addr,int* sign_addr)         */
    LDR R0,=a_Multiplicand
    LDR R0,[R0]
    LDR R1,=a_Multiplicand_Abs
    LDR R2,=a_Multiplicand_Sign
    BL asmAbs

/* Step 2b: call asmAbs for the multiplier (B). */
/* int32 abs = asmAbs(int value,int* abs_addr,int* sign_addr)         */
    LDR R0,=b_Multiplier
    LDR R0,[R0]
    LDR R1,=b_Multiplier_Abs
    LDR R2,=b_Multiplier_Sign
    BL asmAbs

/* Step 3: call asmMult. */ 
/* int32 product = asmMult(int a,int b)   */
    LDR R0,=a_Multiplicand_Abs
    LDR R0,[R0]
    LDR R1,=b_Multiplier_Abs
    LDR R1,[R1]
    BL asmMult
/* store the output value returned in r0 to mem location init_Product. */
    LDR R3,=init_Product  // save init_product
    STR R0,[R3]
    
/* Step 4: call asmFixSign. */
/* int32 product = asmFixSign(int init,int a_sign,int b_sign)   */
    MOV R0, R0  // R0 already contains init_product
    LDR R1,=a_Multiplicand_Sign
    LDR R1,[R1]
    LDR R2,=b_Multiplier_Sign
    LDR R2,[R2]
    BL asmFixSign
 /* Store the value returned in r0 to mem location  final_Product. */
    LDR R3,=final_Product
    STR R0,[R3]
 /* Step 5:  Return to caller.*/
    // R0 already contains final_product
    pop {r4-r11,PC} /* restore the caller's registers & return */
 
    
 /* function: asmUnpack
 *    inputs:   r0: contains the packed value. 
 *                  MSB 16bits is signed multiplicand (a)
 *                  LSB 16bits is signed multiplier (b)
 *              r1: address where to store unpacked, 
 *                  sign-extended 32 bit a value
 *              r2: address where to store unpacked, 
 *                  sign-extended 32 bit b value
 *    outputs:  r0: No return value
 *              memory: 
 *                  1) store unpacked A value in location
 *                     specified by r1
 *                  2) store unpacked B value in location
 *                     specified by r2
 */
.global asmUnpack
.type asmUnpack,%function
/* void asmUnpack(int value,int* a_addr, int* b_addr)         */
/*                    R0         R1           R2         R3=temp */
asmUnpack: 
    push {r4-r11,LR} /* save the caller's registers */
    // TO DO    
    pop {r4-r11,PC} /* restore the caller's registers & return */
 
/* function: asmAbs
 *    inputs:   r0: contains signed value
 *              r1: address where to store absolute value
 *              r2: address where to store sign bit:
 *                  0 = "+", 1 = "-"
 *    outputs:  r0: Absolute value of r0 input. Same value
 *                  as stored to location given in r1
 *              memory: 
 *                  1) store absolute value in location
 *                     given by r1
 *                  2) store sign bit in location 
 *                     given by r2
 */
.global asmAbs
.type asmAbs,%function
/* int32 abs = asmAbs(int value,int* abs_addr,int* sign_addr)         */
/*        R0              R0         R1            R2         R3=temp */
asmAbs: 
    push {r4-r11,LR} /* save the caller's registers */
    mov R3,R0, LSR 31  // extract sign bit
    STR R2,[R2]        // save sign bit
    CMP R1,1           // if signbit==1
    NEGEQ R0,R0        //     make abs value
    STR R0,[R1] /* save abs */
    pop {r4-r11,PC} /* restore the caller's registers & return */
    
/* function: asmMult
 *    inputs:   r0: contains abs value of multiplicand (a)
 *              r1: contains abs value of multiplier (b)
 *    outputs:  r0: initial product: r0 * r1
 */ 
.global asmMult
.type asmMult,%function
/* int32 product = asmMult(int a,int b)   */
/*        R0               R0    R1       */
asmMult:
    push {r4-r11,LR} /* save the caller's registers */
    // TO DO    
    pop {r4-r11,PC} /* restore the caller's registers & return */
 
 /* function: asmFixSign
 *    inputs:   r0: initial product from previous step: 
 *              (abs value of A) * (abs value of B)
 *              r1: sign bit of originally unpacked value
 *                  of A
 *              r2: sign bit of originally unpacked value
 *                  of B
 *    outputs:  r0: final product:
 *                  sign-corrected version of initial product
 */ 
.global asmFixSign
.type asmFixSign,%function
/* int32 product = asmFixSign(int init,int a_sign,int b_sign)   */
/*        R0                      R0       R1         R2        */
asmFixSign:
    push {r4-r11,LR} /* save the caller's registers */
    // TO DO    
    pop {r4-r11,PC} /* restore the caller's registers & return */


/********************************************************************
function name: divideFunc  calculates num/den & sets quoiitent & remainder
useage:  status = divideFunc ( num, dem, &quotient, &remainder)
           R0                   R0   R1     R2        R3
     
where:
     status = 0 (no error) | -1 (error)
     num   : integer numerator
     den   : integer denominator
     quotiet : address for returning quotient
     rem     : address for returning remainder
     output: the integer value returned to the C function
         
********************************************************************/  
/*int status = divideFunc(num=R0, dem=R1, &quotient=R2->R4, &remainder=R3->R5)*/
.global divideFunc
.type divideFunc,%function
divideFunc: 
    push {r4-r11,LR} /* save the caller's registers */
    mov r4,r2  /* save quotient address */
    mov r5,r3  /* save remainder address */
    mov r2,0   /* initialise quotient counter */
 check:
    SUBS r0,r1   /* subtract one denom from numer & set flags */
    BLT done     /* numerator gone negative */
    ADD R2,R2,1  /* increment quotient counter */
    B check;

 done: 
    ADD R0,R1       /* make remainder positive */
    STR R2,[R4]     /* save quotient counter in address provided */
    STR R0,[R5]     /* save remainder in address provided */
    mov r0,0        /* set return status to 'no error' */
    pop {r4-r11,PC} /* restore the caller's registers */
    


/* external function definition  *********************************************/
.global cnano_printf
.type cnano_printf,%function
    
.global printFunc
.type printFunc,%function
printFunc:
    push {r4-r11,LR} /* save regs I may disturb */
    mov R1,5  /* put data into working regs */
    mov R2,7
    mov R3,8
    push {r0-r3}   // save my working regs before calling
    mov R1,R0      // r0 = first passed in parameter, second to printf
    LDR R0, =format1
    BLX cnano_printf  // call may change R0-R3
    pop {r0-r3}    // restore my working regs after call
    /* do more work - check regs restored */
    mov R0,0       /* return good status */
    pop {r4-r11,PC} /* restore callers registers */
format1: .asciz "Hello Assembly passed = %ld\r\n"    

  /* a function to try out various shift instructions  ************************/
.align 4
.global shiftFunc
.type shiftFunc,%function
shiftFunc:
    push {r4-r11,LR} /* save regs I may disturb */
    
    LDR r0,=0x00100011 // load shift_input value
    mov r1,r0,ASR 16   // mov & shift upper 16 bits
    SXTH r2,r0         // sign extent lower 16 bits
    mul r3,r2,r1       // std mul (r1*r2-> r3)
    SMULTB r4,R0,R0    // signed MUL (R0-Top * r0-Bot -> r4)
    
    mov R0,-1               // fill R0 (so can see bits change)
    PKHTB R0,r2,r1,ASR 16   // Pack higher16 r2->top16, r1>>16->bot16
    PKHBT R0,r2,r1,LSL 16   // Pack lower16  r2->bot16, r1<<16->top16
    
    /* test fixed point pseudo instructions */
    mov r0,0            // Fzero
    mov r1,100
    ADDFI r2, r0, r1    // invoke macro r2_F = r0_F + r1_I == 100.000
    ADDFF r3, r2, r2    //              r3_F = R2_F + R2_F == 200.000
    mov  r1,5
    MULFI r4, r2, r1    //              r4_F = r2_F * r1_I == 500.000
    MULFF r5, r2, r3    //              r5_F =

    mov r2, 5
    ADD r1, r2, 3    /* ADD immediate */
    SUB r2, r1, 3    /* SUB immediate */
    UADD16  r3,r2,r1 /* Unsigned dual 16bit adds */
    SSUB8   r3,r2,r1 /*   signed quad  8bit sub  */
    
    LDR R0, =0x00010123 /* load a 32 bit value */
    SSAT r2, 16, r0  /*   signed saturation to 16 bits copy */
    LSR R0,R3,1
    LSL R3,R0,1
    ROR R3,R3,2
    RRX R2,R3
    CLZ r0,r3         /* count leading zeros ... */
    pop {r4-r11,PC} /* restore callers registers */

 /* a function to try out various floating poing coprocessor instructions *****/
.global setup_FP_COPROC
.type setup_FP_COPROC,%function
setup_FP_COPROC:
    LDR.W R0, =0xE000ED88   // CPACR is located at address 0xE000ED88
    LDR R1, [R0]            // Read CPACR
    ORR R1, R1, (0xF << 20) // Set bits 20-23 to enable CP10 and CP11 coprocessors
    STR R1, [R0]            // Write back the modified
    LDR R1, [R0]            // Read CPACR
    MOV PC,LR               // return to caller

.global FP_add
.type FP_add,%function
FP_add: // inputs s0,s1 --> output s0
    VADD.F32 s0,s0,s1
    MOV PC,LR          // return to caller
/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           




