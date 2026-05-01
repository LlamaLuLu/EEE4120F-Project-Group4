; This is the program given by the EEE4120F team, as the default test-program
; Converting this from binary to assembly was pain. Please buy me a coffee :'(

; 0000 010 000 000000
; R0 <- 1, which shouldn't work 'cause R0 is always 0
LD R0, 0(R2)

; 0000 010 001 000001
; R1 <- 2
LD R1, 1(R2)

; 0010 000 001 010 000
; R2 <- 0 + 2
ADD R2, R0, R1

; 0001 001 010 000000
; Mem[2] <- 2, originally holding the value 3
ST R2, 0(R1)

; 0011 000 001 010 000
; R2 <- 0 - 2
SUB R2, R0, R1

; 0111 000 001 010 000
; bitwise and 0
; R2 <- 0b00 & 0b10
AND R2, R0, R1

; 1000 000 001 010 000
; R2 <- 0b00 | 0b10
OR R2, R0, R1

; 1001 000 001 010 000
; R2 <- (R0<R1) ? 1:0
SLT R2, R0, R1

; 0010 000 000 000 000
; R0 <- 0 + 0
ADD R0, R0, R0

; 1011 000 001 000001
; skip next instruction if 0==2
BEQ R0, R1, 1

; 1100 000 001 000000
; branch to the next instruction if 0!=2 (a.k.a. do nothing)
BNE R0, R1, 0

; 1101 000000000000
; go to the start of the program. Nothing changes about the next iteration
JMP 0

; 0000 000 000 000000
LD R0, 0(R0)

; 0000 000 000 000000
LD R0, 0(R0)

; 0000 000 000 000000
LD R0, 0(R0)
