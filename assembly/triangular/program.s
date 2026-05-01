; A program to compute triangular numbers
; https://en.wikipedia.org/wiki/Triangular_number
; Assemble using `assembler.py`
;
; Input data memory state
;   Word 0: 1
;   Word 1: [number of words to output]
; Output data memory state
;   Word 0: First triangular number (1)
;   Word 1: Second triangular number (3)
;   Word i: (i+1)th triangular number

    ; load 16'd1 from memory. R7 will always hold 1.
    LD R7, 0(R0)
    ; load word count to output from memory. R6 will always hold this.
    LD R6, 2(R0)

next_triangular_number:
    ; R2 is the 1-based loop counter
    ADD R2, R2, R7
    ; R3 accumulates R2, this is the triangular number
    ADD R3, R3, R2

    ; multiply the loop counter by 2 to convert to an address to write to
    ; as memory is addressed by the number of bytes in our implementation
    SHL R4, R2, R7
    ; store the triangular number at -2(R4) - offset is needed as counter is 1-based
    ST R3, -2(R4)

    ; do a slightly suboptimal branch logic to use the SLT instruction
    SLT R5, R2, R6
    ; loop until we've outputted the expected number of triangular numbers
    BEQ R5, R7, next_triangular_number

    ; done: spin indefinitely
loop_label:
    JMP loop_label
