.include "m2560def.inc"
.include "macros.asm"
.include "Keypad.asm"

.def digit = r30
.def digitCount = r31
.def temp = r17
.def counter = r20
////////////////////
// USED REGISTERS //
////////////////////
//r1, r3, r4, r5, r6, r8, r9, r16, r17, r20, r18, r19, r22, r23, r24, r25
.dseg
SecondCounter: .byte 2	; Two - byte counter for counting seconds.
TempCounter0: .byte 2	; Temporary counter. Used to determine if one second has passed
TempCounter1: .byte 2	
PushButton: .db 1
Phase: .db 1
RandomNumber: .byte 2		; storage for the 'random' number
ADCValue: .byte 1
printStatus: .byte 1	; 1 = string printed, 0 = string not printed
numberOfDigit: .byte 1	; some are unused. reserved 'for future development'
makeshiftDebounce:		.byte 1
password:		.byte 4
difficulty: .byte 1

.cseg
///////////////////////
// INTERRUPT VECTORS //
///////////////////////
.org 0
	jmp RESET
.org INT0addr					;PB0(Reset Button)
	jmp RESET
.org INT1addr					;PB1
	jmp EXT_INT1
.org OVF2addr
	jmp Timer2OVF
.org OVF1addr
	jmp Timer1OVF
.org OVF0addr					; Jump to the interrupt handler for
	jmp Timer0OVF				; Timer0 overflow....
.org 0x3A
	jmp ADC_Complete
.org OVF3addr
	jmp Timer3OVF
							
/////////////
// STRINGS //
/////////////
startScreen:	.db "2121 16S1", 1, "Safe Cracker", 0, 0			;string constants 
startCountdown: .db 1, "Starting in ", 0							;store in code memory
resetPot:		.db "Reset POT to 0   ", 0, 0, 0					;'arguments' for the printf function
findPot:		.db "Find POT Pos    ", 0, 0						;assembly can screw itself in the butt
remaining:		.db 1, "Remaining: ", 0, 0							;broken
scanNumber:		.db "Position Found!  ", 1, "Scan For Number.", 0,0	;dead
foundKey:		.db "Enter Code        ", 0	,0
gComplete:		.db "Game Complete    ", 1, "You Win!        ", 0,0
gFail:			.db "Game Over        ", 1, "You Lose!      ", 0

/////////////////
// ISR for PB1 //
/////////////////
EXT_INT1:
	push temp
	in temp, SREG
	push temp
	inc r5						;checks if r5 = 0
	dec r5						;since cpi doesn't work on r5
	brne EXT_INT1_DONE
DO_SOMETHING:
	ldi temp, 1					;stores the value in temp
	sts PushButton, temp		;stores the value in data memory (since button is only used to start the game, no debouncing is required)
	lds temp, TempCounter0		;get 'random number'
	sts RandomNumber, temp		;store low bits
	lds temp, TempCounter0+1	;gets the high byte of the temporary counter for timer0
	andi temp, 0b00000011		;isolates first two bits of the high byte since pot limit is 3FF
	sts RandomNumber+1, temp	;store high bits
EXT_INT1_DONE:
	pop temp					;epilogue
	out SREG, temp				;restores registers
	pop temp
	reti
/////////////////
// ISR for TMR3//
/////////////////
;this ISR is for strobe lights only
Timer3OVF:
	push temp					;stores conflicting registers
	in temp, SREG
	push temp
	push r18
	ldi temp, 255				;checks if its game complete screen
	cp temp, r5					
	brne whenItsOver			;its the time i fall in love~ again
	in temp, PORTA
	ldi r18, 0b00001111			;toggles strobe light every 250ms. 2 Hz.
	eor temp, r18
	out PORTA, temp
whenItsOver:					;this ISR is for strobe lights only
	pop r18
	pop temp
	out SREG, temp
	pop temp
	reti
/////////////////
// ISR for TMR2//
/////////////////
Timer2OVF:
	push temp					;stores conflicting registers
	in temp, SREG
	push temp
	push r18
	push YH
	push YL
	inc r6						;256*256/16MHz = 4ms per Timer2OVF
	brvc notOverflow			;256*4ms ~ 1second
	ldi temp, 1
	cp temp, r5
	breq show
	ldi temp, 2
	cp temp, r5
	breq show
	rjmp dontShow				;checks if its the correct phases(2 and 3), do nothing otherwise
show:
	adcMacro					;triggers ADC conversion
	call ledIndicator2			;calls ledIndicator2 electric boogaloo 
	rjmp notOverflow			;min ADC 0b0000010100 max ADC 0b1111101000
dontShow:
	clr temp
notOverflow:
	pop YL
	pop YH
	pop r18
	pop temp
	out SREG, temp
	pop temp
	reti
/////////////////
// ISR for TMR1//
/////////////////
Timer1OVF:
	push temp
	in temp, SREG
	push temp			; Prologue starts.
	push r18
	push r19
	push r20
	push r25
	push r24
	push YH				; Save all conflict registers in the prologue.
	push YL
	keypad				;calls keypad macro
	cp r3, r10			;is right key being pressed?
	brne wrongKey
stillPressed:
	lds temp, numberOfDigit	;checks if its phas3 4 or 5
	cpi temp, 3
	breq p5
	rjmp p4
p5:							;no motor for this phase and shorter pressing time
	inc r1
	ldi temp, 50
	cp r1, temp
	brne End2			;under minimum pressing time
	breq converge
p4:
	ser temp
	andi temp, (1<<4)		;turns on motor
	out PORTE, temp
	inc r1
	brvc End2			;under minimum pressing time (min is 1sec)
converge:
	clr r1
	inc r2
	ldi temp, 4					;right button has been pressed for at least 1 second, move on to next phase
	mov r5, temp
	lds temp, TempCounter0		;get 'random number'
	sts RandomNumber, temp		;store low bits
	lds temp, TempCounter0+1	;gets the high byte of the temporary counter for timer0
	andi temp, 0b00000011		;isolates first two bits of the high byte since pot limit is 3FF
	sts RandomNumber+1, temp	;store high bits
	rjmp End

difficultyChange:
	inc r1
	brvc End2			;key must be held for at least 1 sec
	clr r18
	mov temp, r3
	cpi temp, 3
	breq easyMode
	cpi temp, 7
	breq mediumMode
	cpi temp, 11
	breq hardMode
	cpi temp, 15
	breq hellMode
easyMode:	subi r18, -5 ;20 sec
mediumMode:	subi r18, -5 ;15 sec
hardMode:	subi r18, -5 ;10 sec
hellMode:	subi r18, -5 ;5 sec
	sts difficulty, r18	 ;store amount in a variable in data memory
	clr digit
	do_lcd_command 0b10001110
	do_lcd_digits r18	 ;display difficulty in top right screen
	rjmp End
wrongKey:
	ldi temp, 0
	cp r5, temp
	breq difficultyChange ;difficultyChange was implemented after all this shit
	clr r1				  ;an oversight, that is why the structure looks ridiculous
	out PORTE, r1		  ;turns off motor if wrong key
End:
	clr digit			  
	out PORTE, digit	   ;turns off motor if after 1 sec
End2:
	pop YL
	pop YH
	pop r24			; Epilogue starts;
	pop r25			; Restore all conflict registers from the stack. 
	pop r20
	pop r19
	pop r18
	pop temp
	out SREG, temp
	pop temp
	reti	
/////////////////
// ISR for TMR0//
/////////////////	
Timer0OVF:
	push temp
	in temp, SREG
	push temp				;Prologue starts.
	push YH					;Save all conflict registers in the prologue.
	push YL
	push r25
	push r24				;Prologue ends.
	lds r24, TempCounter0	;Load the value of the temporary counter.
	lds r25, TempCounter0+1
	adiw r25:r24, 1  		;Increase the temporary counter by one.
	cpi r24, low(7812)		;Check if (r25:r24) = 7812
	ldi temp, high(7812)	;7812 = 10^6/128
	cpc r25, temp			
	breq  Second
	jmp NotSecond
Second:
	clear TempCounter0		;Resets temporary counter
	clr temp				;checks current game phase
	cp r5, temp				;jumps to appropriate place
	breq PHASEONE
	inc temp
	cp r5, temp
	breq PHASETWO
	inc temp
	cp r5, temp
	brne phaseFourCheck
	rjmp PHASETHREE
phaseFourCheck:
	inc temp
	cp r5, temp
	brne phaseFiveCheck
	rjmp PHASEFOUR
phaseFiveCheck:
	inc temp
	cp r5, temp
	brne gameOverCheck
	rjmp PHASEFIVE
gameOverCheck:
	ldi temp, 255 
	cp r5, temp
	breq GAMEOVER1
GAMEOVER0:
	printfMacro gFail
	rjmp NotSecond
GAMEOVER1:
	printfMacro gComplete
	rjmp NotSecond

	
///////////////////
// Initial Screen//
///////////////////
PHASEONE:
	lds temp, PushButton
	cpi temp, 1 
	breq PHASEONE_EQUAL
	jmp NotSecond
PHASEONE_EQUAL:
	mov temp, counter
	subi temp, -'0'
	printfMacro startCountdown
	do_lcd_rdata temp
	rjmp COUNTDOWN
////////////////////
// Reset Pot Phase//
////////////////////
PHASETWO:
	ldi temp, 30
	mov r8, temp				;registers to store the random numbers
	clr r9						;
	printfMacro resetPot
	printfMacro remaining
	do_lcd_digits counter
	do_lcd_data ' '
	cp r3, r4
	brlo notLower
	rjmp PHASETWOEND
notLower:
	rjmp COUNTDOWN
////////////////////
// Find Pot Phase //
////////////////////
PHASETHREE:
	printfMacro findPot
	printfMacro remaining
	do_lcd_digits counter
	cp r3, r4
	brlo STILLPHASETHREE
	rjmp PHASETHREEEND
STILLPHASETHREE:
	rjmp COUNTDOWN
////////////////////
// Scan Keys Phase//
////////////////////
PHASEFOUR:
	printfMacro scanNumber
	rjmp NotSecond

PHASEFIVE:
	clr r3
	clr r4
	inc r4
	inc r4
	lds temp, numberOfDigit
	cpi temp, 3
	breq PHASESIX
	ldi ZH, high(PASSWORD<<1)
	ldi ZL, low(PASSWORD<<1)
	add ZL, temp
	adc ZH, r3
	st Z, r10
	inc temp
	sts numberOfDigit, temp
	clr r1
	clr r2
	cpi temp, 3
	brne NOTTHREEKEYSYET
	rjmp PHASEFIVE
NOTTHREEKEYSYET:
	ldi temp, 1
	mov r5, temp
	lds counter, difficulty
	rjmp getRNG

PHASESIX:
	clr temp
	printfMacro foundKey
	;sts makeshiftDebounce, r2
	ldi ZH, high(PASSWORD<<1)
	ldi ZL, low(PASSWORD<<1)
	add ZL, r2
	adc ZH, temp
	ld r10, Z
	do_lcd_command 0b11000000
	;inc temp
	;out PORTC, r2
	cp temp, r2
	breq noStar		;5, 7, 8
	inc temp
	cp temp, r2
	breq oneStar
	inc temp
	cp temp, r2
	breq twoStar
	inc temp
	;cp temp, r2
	;breq threeStar
	ldi temp, 255
	mov r5, temp
threeStar:
	do_lcd_data '*'
twoStar:
	do_lcd_data '*'
oneStar:
	do_lcd_data '*'
noStar:
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	rjmp NotSecond

COUNTDOWN:
	dec counter
	cpi counter, -1
	breq COUNTFINISH
	rjmp notSecond
COUNTFINISH:
	ldi temp, 1
	cp r5, temp
	brne GAMEOVERCHECK1
	ldi temp, 254
	mov r5, temp
	rjmp NotSecond
GAMEOVERCHECK1:
	ldi temp, 2
	cp r5, temp
	brne NOTGAMEOVER
	ldi temp, 254
	mov r5, temp
	rjmp NotSecond
NOTGAMEOVER:
	rjmp setCounter

PHASETHREEEND:
	inc r5
	clr temp
	out PORTC, temp
	out PORTG, temp
	rjmp NotSecond
PHASETWOEND:
	clr r3
	out PORTC, r3
	out PORTG, r3
	inc r4
	inc r4
setCounter:
	clr temp
	out PORTG, temp
	out PORTC, temp
	clear PushButton
	inc r5
	ldi temp, 1
	cp r5, temp
	brne resetCounter
	lds counter, difficulty
resetCounter:
	inc temp
	cp r5, temp
	brne notSecond
getRng:
	lds r8, RandomNumber
	lds r9, RandomNumber+1
	ldi temp, 10
	ldi digit, 0
	cp r8, temp
	cpc r9, digit
	brsh noAdjustments
	add r8, temp
noAdjustments:
	mov temp, r8
	andi temp, 0b00001111
	mov r10, temp			;r10 = random val for keypad
NotSecond:
	; Store the new value of the temporary counter.
	sts TempCounter0, r24
	sts TempCounter0+1, r25
EndIF:
	pop r24			; Epilogue starts;
	pop r25			; Restore all conflict registers from the stack. 
	pop YL
	pop YH
	pop temp
	out SREG, temp
	pop temp
	reti			; Return from the interrupt.

//////////////////
// ADC COMPLETE //
//////////////////
ADC_Complete:
	push r18
	in r18, SREG
	push r18
	lds r22, ADCL		;stores adc value in r23:r22
	lds r23, ADCH
	pop r18
	out SREG, r18
	pop r18
	reti
///////////
// RESET //
///////////	
RESET:
	clearAll
	ldi temp, 20
	sts difficulty, temp
	clr r2
	clear numberOfDigit
	clr r8
	clr r9
	ldi r22, 0xFF
	ldi r23, 0xFF
	clear pushButton
	clr r5					;special register to store current game state
	clr r4					;counter for pot timing
	inc r4
	inc r4
	clr r3					;counter for pot timing
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

	ser r16
	out DDRE, r16
	out DDRG, r16
	out DDRC, r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTC, r16
	out PORTG, r16
	LCDInit
	printfMacro startScreen
////////////////////////
// I/O Initialization //
////////////////////////
initPushbuttons:
	ldi temp, (2 << ISC10 | 2 << ISC00)  	; set INT0 as fallingsts
	sts EICRA, temp 						; edge triggered interrupt
	ldi temp, (1 << INT0 | 1 << INT1)
	out EIMSK, temp
initKeypad:
	ldi temp, 0b11110000					;PB7:4/PB3:0 (Out/In)
	sts DDRL, temp
/////////////////
// 8bit Timers //
/////////////////
initTimer0:
	clear TempCounter0		; Initialize the temporary counter to 0 
	clear SecondCounter		; Initialize the second counter to 0
	ldi temp, 0b00000000
	out TCCR0A, temp
	ldi temp, 0b00000001
	out TCCR0B, temp		; Prescaling value=8
	ldi temp,  1<<TOIE0		; = 128 microseconds   
	sts TIMSK0, temp		; T/C0 interrupt enable 
initTimer2:
	clr r6
	ldi temp, 0b00000000
	sts TCCR2A, temp
	ldi temp, 0b00000100	; Prescaling value = 256
	sts TCCR2B, temp
	ldi temp, 1<<TOIE2
	sts TIMSK2, temp
/////////////////
// 16bit Timers//
/////////////////
initTimer1:
	ldi temp, 0b00000000
	sts TCCR1A, temp
	ldi temp, 0b00000001	;No prescaling
	sts TCCR1B, temp		;4ms per OVF
	ldi temp, 1<<TOIE1
	sts TIMSK1, temp

initTimer3:
	ldi temp, 0b00000000
	sts TCCR3A, temp
	ldi temp, 0b00000011	;No prescaling
	sts TCCR3B, temp		;250ms per OVF
	ldi temp, 1<<TOIE3
	sts TIMSK3, temp
	sei
	ldi counter, 3

halt:
	rjmp halt	;nothing in the main loop 

.include "functions.asm"
.include "lcd.asm"
