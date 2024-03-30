; ----------------------------------------------------------------------------
; Name:       Lab_2_Gia_Style_program.s
; Purpose:    Blink LED 28 according to MORSE pattern of a string
; ----------------------------------------------------------------------------*/

                    THUMB                                           ; declare that we are using the THUMB instruction set
                    AREA            My_code, CODE, READONLY         ; define this as a code area
                    EXPORT          __MAIN                          ; make __MAIN viewable externally
                    ENTRY                                           ; define the access point

__MAIN

; turn off all LEDs
                    ; building the base memory address for the LEDs
                    MOV              R2, #0xC000                    ; move 0xC000 into R2
                    MOV              R4, #0x0                       ; init R4 register to 0 to build address
                    MOVT             R4, #0x2009                    ; assign 0x20090000 into R4
                    ADD              R4, R4, R2                     ; add 0xC000 to R4 to get 0x2009C000

                    ; turn off port 2 LEDS
                    MOV             R3, #0x0000007C                 ; instruction to turn off port 2 LEDs
                    STR             R3, [R4, #0x40]                 ; implement

                    ; turn off port 1 LEDS
                    MOV             R3, #0xB0000000                 ; instruction to turn off port 1 LEDs
                    STR             R3, [R4, #0x20]                 ; implement  

; get the string
RESET_LUT           LDR             R5, =INPUT_LUT

; process the next character, R0 will hold it
NEXT_CHAR           MOV             R0, #0x0                        ; clear R0 to 0
                    LDRB            R0, [R5], #0x1                  ; place the next character into R0 by loading the value at which R5 "points" to, then post-offset R5
                    CBNZ            R0, LINK_CHAR_2_MORSE           ; if we are not at the end of the string, convert the character to it's morse equivalent
                    ; we have reached the end of the string
                    MOV             R0, #4                          ; move 7 into R0 to indicate a long delay
                    BL              LED_OFF                         ; turn the LED off
                    B               RESET_LUT                       ; blink the string again

; link to CHAR_2_MORSE
LINK_CHAR_2_MORSE   BL              CHAR_2_MORSE                    

; determine if the LED should be on or off next according to the character's morse pattern
; R2 will be used to extract the next instruction
DETERMINE_BLINK     MOV             R2, #0x0                        ; clear R2 to 0
                    MOVT            R2, #0x8000                     ; set the 31st bit to zero
                    AND             R2, R2, R1                      ; determine if the LED should be on by extracting the MSB
                    LSL             R1, #1                          ; prepare R1 for the next blink
                    MOV             R0, #1                          ; store the instruction to output 1 1 dot delay in r0
                    CBZ             R2, LINK_LED_OFF                ; if R2 is zero, turn the LED off by branching to the link instruction

LINK_LED_ON         BL              LED_ON                          ; if R2 is not zero, link to the LED_ON subroutine
                    B               NEXT                            ; upon return, begin processing the next character

LINK_LED_OFF        BL              LED_OFF                         ; take the PC to the LED_OFF subroutine
                             
NEXT                CBZ             R1, NEXT_CHAR_DELAY             ; if R1 is zero, process the next character
                    B               DETERMINE_BLINK                 ; otherwise, determine the next blink of the current character

; output a delay equivalent to 3 dots before processing the next character
NEXT_CHAR_DELAY     MOV             R0, #2                          ; move 2 into R0 to indicate a 3 dot longer delay
                    BL              LED_OFF                         ; turn the LED off
                    B               NEXT_CHAR                       ; branch to process the next character of the string

; get the Morse code pattern of the character
CHAR_2_MORSE        STMFD           R13!,{R14}                      ; preserve the return address
                    MOV             R1, #0x0                        ; clear R1 to zero
                    MOV             R1, #0x2                        ; store 2 in R1
                    SUB             R0, #0x41                       ; subtract 0x41 from the chracter to get it's number in the Morse LUT
                    MUL             R0, R1                          ; each character's Morse is 32 bits, thus, we must calculate the "offset" to get the character's address in the Morse LUT
                    ADR             R1, MORSE_LUT                   ; store the address of the Morse LUT in r1
                    LDRH            R1, [R1, R0]                    ; store the character's Morse pattern in R1 using the offset we computed earlier
                    CLZ             R0, R1                          ; count the leading zeroes of the Morse pattern, R1
                    LSL             R1, R0                          ; get rid of leading zeroes in R1
                    LDMFD           R13!,{R15}                      ; set the PC to the line after the line which called this subroutine

; turn the LED on
LED_ON              push            {R0, R3, LR}                    ; preserve the registers we are modifying
                    MOV             R3, #0xA0000000                 ; store the instruction to turn LED 28 on in R3
                    STR             R3, [R4, #0x20]                 ; turn LED 28 on
                    BL              DELAY_VALUE                     ; link to the delay
                    LDMFD           R13!, {R0, R3, LR}              ; reset the registers we modified to their original values
                    BX              LR                              ; set the PC to the line after the line which called this subroutine

; turn the LED off
LED_OFF             push            {R0, R3, LR}                    ; preserve the registers we are modifying,
                    STR             R3, [R4, #0x20]                 ; turn LED 28 off
                    BL              DELAY_VALUE                     ; link to the delay
                    pop             {R0, R3, LR}                    ; reset the registers we modified to their original values
                    BX              LR                              ; set the PC to the line after the line which called this subroutine

; get the delay value
DELAY_VALUE         STMFD           R13!, {R2}                      ; preserve the registers we are modifying
                    MOV             R2, #0x2C2A                     ; set the lower half of the counter, R2
                    MOVT            R2, #0x000A                     ; set the upper half of the counter, R2          
                    MUL             R2, R2, R0                      ; store the total delay value in R2 by multiplying it by R0                
DELAY               ; begin the delay  
                    SUBS            R2, #0x1                        ; decrement the delay counter
                    BGT             DELAY                           ; continue decreasing the delay counter until it reaches zero
                    LDMFD           R13!, {R2}                      ; reset the registers we modified to their original values      
                    BX              LR                              ; set the PC to the line after the line which called this subroutine

; define the string
                    ALIGN                                           ; ensure the address the INPUT LUT data is stored in are multiples of 8
INPUT_LUT           DCB             "BANGS", 0                      ; INPUT_LUT "points" to the declared data, each character is 8 bits

; define the Morse LUT
                    ALIGN                                           ; ensure the address the INPUT LUT data is stored in are multiples of 16
MORSE_LUT
                    DCW             0x17, 0x1D5, 0x75D, 0x75        ; A, B, C, D
                    DCW             0x1, 0x15D, 0x1DD, 0x55         ; E, F, G, H
                    DCW             0x5, 0x1777, 0x1D7, 0x175       ; I, J, K, L
                    DCW             0x77, 0x1D, 0x777, 0x5DD        ; M, N, O, P
                    DCW             0x1DD7, 0x5D, 0x15, 0x7         ; Q, R, S, T
                    DCW             0x57, 0x157, 0x177, 0x757       ; U, V, W, X
                    DCW             0x1D77, 0x775                   ; Y, Z

                    END  