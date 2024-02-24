/*** asmFunc.s   ***/

#include <xc.h>
 
# Tell the assembler that what follows is in instruction memory    
.text
.align

# Tell the assembler to allow both 16b and 32b extended Thumb instructions
.syntax unified

    
/********************************************************************
function name: asmFunc  calculates num/den & sets quoiitent & remainder
useage:  status = asmFunc ( num, dem, &quotient, &remainder)
           R0               R0   R1     R2        R3
     
where:
     status = 0 (no error) | -1 (error)
     num   : integer numerator
     den   : integer denominator
     quotiet : address for returning quotient
     rem     : address for returning remainder
     output: the integer value returned to the C function
         
********************************************************************/    
.global asmFunc
.type asmFunc,%function
asmFunc: /* int status = asmFunc (num=R0, dem=R1, &quotient=R2->R4, &remainder=R3->R5)*/

    # save the caller's registers, as required by the ARM calling convention
    push {r4-r11,LR}
    mov r4,r2  /* save quotient address */
    mov r5,r3  /* save remainder address */
    mov r2,0   /* initialise quotient counter */
 check:
    SUBS r0,r1   /* subtract one denom from numer & set flags */
    BLT done      /* numer gone negative */
    ADD R2,R2,1  /* increment quotient counter */
    B check;

 done: 
    ADD R0,R1     /* make remainder positive */
    STR R2,[R4]   /* save quotient counter in address provided */
    STR R0,[R5]   /* save remainder in address provided */
    mov r0,0      /* set return status to 'no error' */
    # restore the caller's registers, as required by the ARM calling convention
    pop {r4-r11,PC}
    
.global multFunc
.type multFunc,%function
multFunc: /* int status = multFunc(int A=r0, int B=r1, int* C=r2) R3=product accumulator */
    push {r4-r11,LR}
    mov r3,0      /* initialize accumulator */
    mov r4,1      /* initialize bit flag mask */
multloop:
    TST R0,R4     /* Z=1 if lobit of shifted A clear */
    ADDNE r3,r3,r1 /* if Z==0 add copy of shifted B into accum  */
    LSL R1,R1,1    /* double B  */
    LSR R0,R0,1    /* halve A */
    CMP R0,0       /* check if done */
    BNE multloop   /* loop if A not yet zero */
    STR R3,[R2]    /* save completed product accumulator to provided address */
    mov R0,0       /* return good status */
    pop {r4-r11,PC}
    
/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           




