.macro keypad
; col = r17
; row = r18
; temp1 = r19
; temp2 = r20
; rmask = r24
; cmask = r25
initKeypadClear:
	clr digit
initKeypad:
    ldi r25, 0xEF			; initial column mask
    ldi r17, 0                 ; initial column
	clr r19
	clr r20
	;debounce check
	;cpi debounceFlag, 1		; if the button is still debouncing, ignore the keypad
	;breq initKeypad	
	;ldi debounceFlag, 1		; otherwise set the flag now to init the debounce
	
colloop:
    cpi r17, 4
    brne padCont    ; If all keys are scanned, repeat. UPD: button was released
	rjmp End
padCont:
    sts PORTL, r25        ; Otherwise, scan a column.

	ldi r19, 0x1
delay:
	dec r19
	brne delay

    lds r19, PINL         ; Read PORTL
    andi r19, 0x0F     ; Get the keypad output value
    cpi r19, 0xF          ; Check if any row is low
    breq nextcol            ; if not - switch to next column

                            ; If yes, find which row is low
    ldi r24, 0x01       ; initialize for row check
    clr r18
; and going into the row loop
rowloop:
    cpi r18, 4              ; is row already 4?
    breq nextcol            ; the row scan is over - next column
    mov r20, r19
    and r20, r24			; check un-masked bit
    breq convert            ; if bit is clear, the key is pressed
    inc r18                 ; else move to the next row
    lsl r24
    jmp rowloop
    
nextcol:                    ; if row scan is over
    lsl r25
    inc r17                 ; increase r17 value
    jmp colloop            ; go to the next r17umn
     
convert:
	cpi digit, 1			; button has not been released yet
	breq stillPressed			; don't use it, scan again
    mov r19, r18          ; otherwise we have a number 1-9
    lsl r19					;r19*2
	lsl r19
    ;add r19, r18			;r19*2 + r19 = r19*3
	;cpi r17, 0				
	;brne addRow
	;inc r17
addRow:	
	add r19, r17          ;r19 = row*3 + r17
    mov r3, r19
	;dec r3
	ldi digit, 1
.endmacro