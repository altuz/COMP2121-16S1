//adcMacro
//triggers ADC read
.macro adcMacro
	ldi r18, (1<<REFS0)|(0<<ADLAR)|(0<<MUX0)
	sts ADMUX, r18
	ldi r18, (1<<MUX5);|(1<<ADTS2)
	sts ADCSRB, r18
	ldi r18, (1<<ADEN)|(1<<ADSC)|(1<<ADIE)|(5<<ADPS0);|(1<<ADATE)
	sts ADCSRA, r18
.endmacro

//printfMacro
//loads Z with a memory address of a string and call the printf functions
//push and pop Z in case it clashes
.macro printfMacro
	push ZL
	push ZH
	ldi ZL, low(@0<<1)
	ldi ZH, high(@0<<1)
	call printf
	pop ZH
	pop ZL
.endmacro

.macro clearAll
	clr r1
	clr r2
	clr r3
	clr r4
	clr r5
	clr r6
	clr r7
	clr r8
	clr r9
	clr r10
	clr r11
	clr r12
	clr r13
	clr r14
	clr r15
	clr r16
	clr r17
	clr r18
	clr r19
	clr r20
	clr r21
	clr r22
	clr r23
	clr r24
	clr r25
	clr r26
	clr r27
	clr r28
	clr r29
	clr r30
	clr r31
.endmacro

//LCDInit
//initialize LCD
.macro LCDInit
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink
.endmacro

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro

.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro do_lcd_rdata
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro clear
	ldi YL, low(@0)		; load the memory address to Y 
	ldi YH, high(@0)     
	clr temp
	st Y+, temp			; clear the two bytes at @0 in SRAM
	st Y, temp                
.endmacro

.macro lcd_set
	sbi PORTA, @0
.endmacro

.macro lcd_clr
	cbi PORTA, @0
.endmacro

//macro to display integer with multiple digits
.macro do_lcd_digits
	push digitCount
	push digit
	clr digit
	clr digitCount
	mov temp, @0			; temp is given number
	rcall convert_digits	; call a function
	pop digit
	pop digitCount
.endmacro

