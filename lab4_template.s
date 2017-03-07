;*-------------------------------------------------------------------
;* Name:    	lab_4_program.s 
;* Purpose: 	A sample style for lab-4
;* Term:		Winter 2014
;*-------------------------------------------------------------------
				THUMB 								; Declare THUMB instruction set 
				AREA 	My_code, CODE, READONLY 	; 
				EXPORT 		__MAIN 					; Label __MAIN is used externally 
				EXPORT 		EINT3_IRQHandler 	; without this the interupt routine will not be found

				ENTRY 

__MAIN

; The following lines are similar to previous labs.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR		; R10 is a  pointer to the base address for the LEDs
				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2
				
		;		MOV 		R9, #0x1388
	;			MOVT		R9,	#0x0147
;				SDIV 		R3, R3, R9
				
				LDR			R3, =ISER0			
				MOV			R2, #0x00200000		; bit 21 is set to 1
				STR			R2, [R3]
				
				LDR			R3, =IO2IntEnf
				MOV			R2, #0x00000400		; bit 10 is set to 1
				STR			R2, [R3]
				
				
				
loopy			BL			RNG
				LSR			R11, #24
				MOV 		R3, R11
				CMP 		R3, #200
				BGT			loopy
				
				ADD			R3, R3, #50
				MOV			R6, R3
				
				
display_loop		
				MOV 		R0, #10
				BL			DELAY
				SUBS 		R6, R6, #10
				CMP			R6, #0
				MOVLT		R6, #0
				MOV			R3, R6
				BL 			DISPLAY_NUM
				TEQ			R6, #0
				BEQ			loopy
				BGT			display_loop
				
			
				
				
				

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number
LOOP 			BL 			RNG  
				B 			LOOP

				
				
		;
		; Your main program can appear here 
		;
				
				
				
;*------------------------------------------------------------------- 
; Subroutine RNG ... Generates a pseudo-Random Number in R11 
;*------------------------------------------------------------------- 
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
RNG 			STMFD		R13!,{R1-R3, R14} 	; Random Number Generator 
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1			; The new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				LDMFD		R13!,{R1-R3, R15}

;*------------------------------------------------------------------- 
; Subroutine DELAY ... Causes a delay of 1ms * R0 times
;*------------------------------------------------------------------- 
; 		aim for better than 10% accuracy
DELAY			STMFD		R13!,{R2, R14}
MultipleDelay		TEQ		R0, #0		; test R0 to see if it's 0 - set Zero flag so you can use BEQ, BNE
		MOV			R2, #0xE4B1
		MOVT		R2, #0x0001
		;MOV			R2, #0x007C
		MUL			R0, R0, R2
	
Loop
	SUBS 		R0, #1 					; Decrement r0 and set the N,Z,C status bits
	BNE 	Loop
exitDelay		LDMFD		R13!,{R2, R15}

; The Interrupt Service Routine MUST be in the startup file for simulation 
;   to work correctly.  Add it where there is the label "EINT3_IRQHandler
;
;*------------------------------------------------------------------- 
; Interrupt Service Routine (ISR) for EINT3_IRQHandler 
;*------------------------------------------------------------------- 
; This ISR handles the interrupt triggered when the INT0 push-button is pressed 
; with the assumption that the interrupt activation is done in the main program
; EINT3_IRQHandler 	
					; STMFD 		... 				; Use this command if you need it  
		; ;
		; ; Code that handles the interrupt 
		; ;
					; LDMFD 		... 				; Use this command if you used STMFD (otherwise use BX LR) 

; ;
; Display the number in R3 onto the 8 LEDs
DISPLAY_NUM		STMFD		R13!,{R1, R2, R3, R4, R14}
				MOV 		R2, #5
				MOV			R4, #0
	
FIRST_FIVE		LSRS		R3, R3, #1
				LSL 	    R4, R4, #1
				ADDCC		R4, R4, #1
				SUBS		R2, R2, #1
				BNE			FIRST_FIVE

				LSL 		R4, R4, #2
				
				STR 		R4, [R10, #0x40]
				
				MOV 		R2, #3
		        MOV			R4, #0
LAST_THREE		TEQ 		R2, #2
				LSLEQ 	    R4, R4, #1
				LSRS		R3, R3, #1
				LSL 	    R4, R4, #1
				ADDCC		R4, R4, #1
				SUBS		R2, R2, #1
				BNE			LAST_THREE
				
				LSL			R4, R4, #28
				
				STR 		R4, [R10, #0x20]
			
; Usefull commaands:  RBIT (reverse bits), BFC (bit field clear), LSR & LSL to shift bits left and right, ORR & AND and EOR for bitwise operations

				LDMFD		R13!,{R1, R2, R3, R4, R15}
				
EINT3_IRQHandler  	STMFD		R13!,{R4, R5, R14}

				MOV		R6, #0
				LDR 	R5, =IO2IntClr
				MOV		R4, #0x400						; bit 10 is set to 1
				STR		R4, [R5]
				
					LDMFD		R13!,{R4, R5, R15}
;*-------------------------------------------------------------------
; Below is a list of useful registers with their respective memory addresses.
;*------------------------------------------------------------------- 
LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002C00C 		; Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002C010 		; Pin Select Register 4 for P2[15:0]
FIO1DIR			EQU		0x2009C020 		; Fast Input Output Direction Register for Port 1 
FIO2DIR			EQU		0x2009C040 		; Fast Input Output Direction Register for Port 2 
FIO1SET			EQU		0x2009C038 		; Fast Input Output Set Register for Port 1 
FIO2SET			EQU		0x2009C058 		; Fast Input Output Set Register for Port 2 
FIO1CLR			EQU		0x2009C03C 		; Fast Input Output Clear Register for Port 1 
FIO2CLR			EQU		0x2009C05C 		; Fast Input Output Clear Register for Port 2 
IO2IntEnf		EQU		0x400280B4		; GPIO Interrupt Enable for port 2 Falling Edge 
ISER0			EQU		0xE000E100		; Interrupt Set-Enable Register 0 

IO2IntClr		EQU		0x400280AC		; Interrupt Port 2 Clear Register

				ALIGN 

				END 
