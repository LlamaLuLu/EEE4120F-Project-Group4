; A program for a mock-mission that the StarCore-2 could do
; Assemble using `assembler.py`
;
; Scenario:
; The StarCore-2 irregularly receives unsigned 4-bit values (in-pins 3:0) representing CubeSat's altitude.
; Due to extreme radiation, there's a lot of noise.
; An odd-parity bit (in-pin 4) is included, and faulty data should be ignored.
; Simultaneously, the StarCore-2 must implement thrust-management:
;   There's a desired altitude for the CubeSat.
;   The StarCore must compare the desired output to the actual altitude,
;   and output the difference (out-pins 15:0) as a signed value.
;   This output goes to the thrusters: positive will accelerate upwards.
;   Since it may be a while until the next altitude reading,
;   the StarCore-2 must decay this output value to prevent too much overshoot.
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

; Load constants
LD R1, 1(R0) ; R1 <= 1
LD R2, 2(R0) ; R2 <= 0b1111 mask
LD R3, 0(R0) ; R3 <= desired altitude

main:
    ; go to next iteration if there's no output
    BEQ R0, R5, main
    ; decay the output
    ADD R5, R5, R6 ; R6 is either +1 or -1, depending on the sign of R5, calculated in the ISR
    ; update the output to the thrusters
    ST R5, 14(R0)
    ; loop the main program
    JMP main
