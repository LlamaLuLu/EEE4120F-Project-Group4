; When a new altitude value is available, and interrupt is triggered,
; asking the StarCore-2 to handle the new value.
;
; Data memory:
;   0x0: desired altitude
;   0x1: value 1
;   0x2: 0b1111 bit mask
;   0x3: reserved as temporary storage for output thrust
;
; Register usage:
;   R0: always 0
;   R1: value 1
;   R2: parity iterating variable / 0b1111 bit mask
;   R3: desired altitude
;   R4: latest altitude measurement
;   R5: shifted altitude measurement / output value
;   R6: parity count / decay direction
;   R7: intermediate holder

; load the new value
LD R4, 15(R0) ; read the digital input pins
; disable thrusters, because the interrupt will take a while
ST R0, 14(R0)
; save the current output value, and duplicate the measured altitude
ST R5, 3(R0)
ADD R5, R4, R0 ; MOV the altitude into R5

; check for parity
ADD R6, R1, R0 ; MOV the value 1 into R6
AND R7, R5, R1 ; extract bit 0
BEQ R7, R0, 1 ; ignore next instruction if the 0th bit is 0
INV R6, R6 ; invert R6 to indicate an odd number of bits
next_bit:
    SHR R5, R5, R1 ; shift 1 bit to the right
    AND R7, R5, R1 ; extract new bit 0
    BEQ R7, R0, 1 ; ignore next instruction if the new 0th bit is 0
    INV R6, R6 ; invert R6 to indicate an odd/even number of bits
    SHR R2, R2, R1 ; shift the mask 1 bit right, to decrement the counter
    BNE R2, R0, next_bit ; repeat for next bit if we haven't checked all 5 bits
LD R2, 2(R0) ; R2 <= 0b1111 mask, revert the changes done to R2
AND R6, R6, R1 ; extract last bit 0
BEQ R6, R0, valid_measurement ; branch to valid_measurement if there's an odd number of bits

; ignore the new measurement
invalid_measurement:
    ; load back the output thrust
    LD R5, 3(R0)

; determine the direction of decay
determine_decay:
    ADD R6, R1, R0 ; MOV the value 1 into R6 (technically already true), which assumes decay is +1
    SHR R7, R5, R2 ; shift R5 15 bits to the right, to get the last bit: the sign bit
    BNE R7, R0, 1 ; skip the next instruction if the thrust output is negative
    SUB R6, R0, R1 ; set the decay as -1
    ST R5, 14(R0) ; update the output to the thrusters
    RETI ; end the interrupt service routine

; deal with new valid altitude measurement
valid_measurement:
    AND R5, R4, R2 ; remove the parity bit and any other garbage, and put this in R5
    SUB R5, R3, R5 ; set R5 to the difference between the setpoint and measured value
    JMP determine_decay ; determine the decary the end the ISR