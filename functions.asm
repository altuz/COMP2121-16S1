///////////////////////////////////////////////////////////
//ledIndicator2 - electric boogaloo////////////////////////
//New more compact version/////////////////////////////////
///////////////////////////////////////////////////////////
ledIndicator2:
	push temp			;push stuff
	in temp, SREG
	push temp			
	push r21
	mov r11, r22			;dont change main adc count
	mov r12, r23			;just in case
	ldi temp, 0
	ldi r21, 0
withinBounds:
	cp r8, r11
	cpc r9, r12
	breq epilogue
	brlo getDown			;if ADC lower than target, count up
	brsh getUp				;else count down
getDown:
	clc						;clear carry
	dec r11					
	sbc r12, r21
	inc temp
	cpi temp, 49			; >= 49 
	brsh dimAF				; way out of range dude
	rjmp withinBounds		;keep doing this until equilibrium
getUp:
	inc r11
	adc r12, r21
	inc temp
	cpi temp, 49
	brsh dimAF
	rjmp withinBounds		;keep doing this until equilibrium
epilogue:
	cpi temp, 17
	brlo shitIsLitFam		;finds appropriate range
	cpi temp, 33
	brlo kindaLit
	cpi temp, 49
	brlo kindaDim
kindaLit:					;light my some of my shit up fam
	clr temp
	ser r21
	clr r3
	out PORTC, temp
	out PORTG, r21
	rjmp endOfParty
kindaDim:					;bottom 8 led
	ser temp
	clr r21
	clr r3
	out PORTC, temp
	out PORTG, r21
	rjmp endOfParty
shitIsLitFam:				;light my shit up fam
	ser temp
	ser r21
	inc r3
	out PORTC, temp
	out PORTG, r21
	rjmp endOfParty
dimAF:						;where the party at man
	clr temp
	clr r21
	clr r3
	out PORTC, temp
	out PORTG, r21
	rjmp endOfParty
endOfParty:					
	pop r21
	pop temp
	out SREG, temp
	pop temp
	ret
/////////////////////////////////////////////////////
//printf function////////////////////////////////////
//prints out a string to the LCD/////////////////////
/////////////////////////////////////////////////////
printf:
	push r17
	in r17, SREG
	push r17
	push r18
	do_lcd_command 0b10000000 ;always start from top
LOOP:
	lpm r18, Z+		;Z must be loaded beforehand
	cpi r18, 1		;1 = go new line
	brlo STOP		;0 = stop
	breq NEWLINE
	do_lcd_rdata r18
	;out PORTC, r18
	rjmp LOOP
NEWLINE:
	do_lcd_command 0b11000000
	rjmp LOOP
STOP:
	pop r18
	pop r17
	out SREG, r17
	pop r17
	ret

/*
//ledIndicator
//checks if pot is within range
//now defunct
ledIndicator:
	push temp
	in temp, SREG
	push temp
	push r21
upperBounds:
	ldi temp, 25
	clr r21
	add temp, r8
	adc r21, r9
	cp r22, temp
	cpc r23, r21
	brlo within48
	brsh outOfRange
within48:
	mov r21, r9
	mov temp, r8
	subi temp, 24
	sbci r21, 0
	cp  r22, temp
	cpc r23, r21
	brsh middleBounds
	brlo outOfRange
middleBounds:
	ldi temp, 17
	clr r21
	add temp, r8
	adc r21, r9
	cp r22, temp
	cpc r23, r21
	brlo within32
	brsh bottomLED
within32:
	mov r21, r9
	mov temp, r8
	subi temp, 16
	sbci r21, 0
	cp  r22, temp
	cpc r23, r21
	brsh lowerBounds
	brlo bottomLED
lowerBounds:
	ldi temp, 9
	clr r21
	add temp, r8
	adc r21, r9
	cp r22, temp
	cpc r23, r21
	brlo within16
	brsh topLED
within16:
	mov r21, r9
	mov temp, r8
	subi temp, 8
	sbci r21, 0
	cp  r22, temp
	cpc r23, r21
	brsh allLED
	brlo topLED
topLED:
	clr temp
	ser r21
	clr r3
	rjmp endOfFunction
bottomLED:
	ser temp
	clr r21
	clr r3
	rjmp endOfFunction
allLED:
	ser temp
	ser r21
	inc r3
	rjmp endOfFunction
outOfRange:
	clr temp
	mov temp, r9
	clr r21
	clr r3
	rjmp endOfFunction
endOfFunction:
	out PORTC, temp
	out PORTG, r21
	pop r21
	pop temp
	out SREG, temp
	pop temp
	ret*/