.macro ADDFF sum, a, b
    ADD \sum, \a, \b
.endm
    
.macro ADDFI sum, a, b
    ADD \sum, \a, \b, LSL 16
.endm

 .macro MULFF prod, a, b
    MUL \prod, \a , \b
    MOV \prod, \prod, ASR 16
 .endm

 .macro MULFI prod, a, b
    MUL \prod, \a, \b
 .endm


