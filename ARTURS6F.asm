;arthur shamarim
IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------
	messeage db 13, 10, 'to exit press ESC 								  white keys: TAB-\   black keys: a-;', 10, 13, '$'
	key_number db 14
	black_key_number db 13
	note dw 4559, 4063, 3620, 3416, 3043, 2712, 2415, 2279, 2031, 1810, 1708, 1522, 1356, 1208	;divisors for the frequancys we need (1193182 / note)
	black_note dw 4303, 3833, 3224, 2872, 2559, 2152, 1915, 1612, 1436, 1279	;divisors for the frequancys of black notes
	key_x_coords dw ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?	;the starting coords of every white note
	black_keys_drawStatus db 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1	;1 - to draw a black note in this place. 0 - skip to the next
	blackKey_x_coords dw ?, ?, ?, ?, ?, ?, ?, ?, ?, ?			;the starting coords of every black note
	note_sequence db 0, 8, 14, 24, 22, 18, 14, 8, 0, 8, 14, 24, 14, 18, 22, 24, 26, 24, 22, 18, 14	;sequence of offsets of each key that we will use in the intro
CODESEG
proc DelayLoop		;makes delay
    push cx
    push dx
    mov cx, 200
outer_loop:
    mov dx, 500
inner_loop:
    nop				;doesnt do anything, just takes time to complete
    dec dx
    jnz inner_loop
    dec cx
    jnz outer_loop
    pop dx
    pop cx
    ret
endp DelayLoop
proc bg				;draws the grey background (a different procedure because we dont want the time delay)
	push bp
	mov bp, sp
	push 8				;settings for drawing
	push 122
	push 08h
	push 292
	push 72
	call rec
ending_bg:					;ending of the procedure
	mov sp, bp				;clear the stack
	pop bp
	ret
endp bg
proc piano_keys		;draws 14 white keys of the piano
	push bp
	mov bp, sp
	push 10		;set the x postion
	push 120	;set the y postion
	push 0Fh	;set the color
	push 15		;set the width of the rectangle
	push 70		;set the height of the rectangle
	mov cl, [key_number]
	mov di, offset key_x_coords
print_PkeysLoop:			;loop of  drawing 16 keys of the piano
	mov ax, [word ptr bp-2]	;saving the starting position of each white key
	mov [di], ax
	add di, 2
	mov [key_number], cl	;saving the times the loop has been executed
	call rec				;draws a rectangle
	add [word ptr bp-2], 21	;adding to the current x position 21 pixels and drawing a new one
	xor ch, ch
	mov cl, [key_number]	;update the times the loop were executed
	loop print_PkeysLoop
outro2:						;ending of the procedure
	mov sp, bp				;clear the stack
	pop bp
	ret
endp piano_keys
proc black_keys		;draws the black keys in a pattern of: key key space key key key space key key space key key key
	push bp
	mov bp, sp
	push 23		;set the x postion
	push 121	;set the y postion
	push 0F6h	;set the color
	push 10		;set the width of the rectangle
	push 45		;set the height of the rectangle
	mov cl, [black_key_number]
	mov di, offset blackKey_x_coords
	mov si, offset black_keys_drawStatus
print_BlackKeysLoop:
	mov al, [si]
	cmp al, 0
	je skip_note
	inc si
	mov ax, [word ptr bp-2]		;saving the starting position of each black key
	mov [di], ax
	add di, 2
	mov [black_key_number], cl	;saving the times the loop has been executed
	call rec					;draws a rectangle
	add [word ptr bp-2], 21		;adding to the current x position 21 pixels and drawing a new one
	xor ch, ch
	mov cl, [black_key_number]	;update the times the loop were executed
	loop print_BlackKeysLoop
	jmp outro3
skip_note:						;skip drawing the note
	add [word ptr bp-2], 21     
    inc si
    loop print_BlackKeysLoop
outro3:						;ending of the procedure
	mov sp, bp				;clear the stack
	pop bp
	ret
endp black_keys
proc rec			;draws a rectangle with the given atributes: pos x, pos y, color, width, height
	push bp
	mov bp, sp
	mov cx, [bp+12]		;get the x postion
	mov ax, cx			;save the x position in ax
	add ax, [bp+6]		;add to it the width to calculate the final x position
	push ax				;save the result in stack
	mov dx, [bp+10]		;get the y postion
	mov ax, dx			;save the y position in ax
	add ax, [bp+4]		;add to it the height to calculate the final y position
	push ax				;save the result in stack
	mov ax, [bp+8]		;get the color
	mov ah, 0Ch			;number of the int 10 write graphic pixel in the coordinate
Wloop:					;the external loop
	mov dx, [bp+10]
Hloop:					;the internal loop
	int 10h				;print pixel
	inc dx				;going down by 1 pixel				
	cmp dx, [bp-4]		;if we didnt got to the end of the rectangle's collumn - loop
	jne Hloop
	inc cx				;going right by 1 pixel
	cmp cx, [bp-2]		;if we didnt got to the end of the rectangle's row - loop
	jne Wloop
outro:					;ending of the procedure
	add sp, 4
	pop bp
	ret
endp rec
proc closeSpeaker	;close the speaker
	push ax
	in al, 61h		;getting the present status of port 61 and save it in al
	and al, 11111100b	;turn off the fisrt two bytes 
	out 61h, al		;retrun the status to port 61
	pop ax
	ret
endp closeSpeaker
proc openSpeaker	;open the speaker
    push bp
    mov bp, sp
    push ax
    in al, 61h
    or al, 00000011b	;turn on the first two bytes
    out 61h, al
    mov al, 0B6h	;settings for PIT (טיימר חומרתי לתזמון מדויק)
    out 43h, al		;setting pit to channel 2, mode 3 which will give us sound from the speaker
	mov ax, [bp+4]  ;getting the frequancy of the note we need from the stack
    out 42h, al     ;loading the lower bytes of the divisor
    mov al, ah
    out 42h, al     ;loading the upper bytes of the divisor
    pop ax
    mov sp, bp
    pop bp
    ret 2
endp openSpeaker
proc intro			;plays a song
	push bp
	mov bp, sp
	mov cx, 21		;number of notes in the song
	mov si, offset note_sequence
	xor bh, bh
introLoop:
	push cx				;to not lose them while running the code
	push si
    mov bl, [si]		;bx contain the value of each note_sequence number
    push [note + bx]	;push the note
    call openSpeaker	;play it
	push [key_x_coords + bx]	;settings for drawing a pressed key
	push 120
	push 0Ch
	push 15
	push 70
	call rec			  ;coloring the key
	mov [black_key_number], 13
	call black_keys       ;recoloring the black keys because the white one covered it
    call DelayLoop		  ;delay to recognize each note
    call closeSpeaker	  ;close the speaker
	mov [word ptr bp-10], 0Fh	;setting the color to white to recolor the key back
	call rec			  ;coloring the key
	add sp, 10			  ;clean stack
	mov [black_key_number], 13
	call black_keys		  ;recoloring the black keys because the white one covered it
    call DelayLoop
	pop si				  ;getting back our registers
	pop cx
    inc si				  ;going for the next number in the sequence
    dec cx
	jz end_introLoop	  ;if cx = 0, end the loop
	jmp introLoop		  
end_introLoop:
	mov sp, bp			  ;clean the stack
	pop bp
    ret
endp intro
start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------
	mov ax, 13h		
	int 10h		;set graphic mode
	call bg
	call piano_keys
	call black_keys
	call intro
	mov dx, offset messeage ;print header
	mov ah, 9h
	int 21h
Continue:
	in al, 64h ; Read keyboard status port
	cmp al, 10b ; Data in buffer ?
	je Continue ; Wait until data available
    in al, 60h            ;read the scancode of the key on the keyboard
	cmp al, 01h           ;if the key is ESC - end the program
	jne Continue_2
    jmp exit_graphic
Continue_2:
    mov cx, 13
    mov si, 0             ;si is the index in two lists key_x_coords and note
    mov bl, 0Fh           ;the scancode of TAB
CheckKeys:				  ;the loop which will check if the key we input is from TAB to "]"
    cmp al, bl            ;if the scancode match the input - this key is pressed
	jne CheckKeys_2
    jmp Press_key
CheckKeys_2:
    mov ah, bl
    add ah, 80h           ;scancodes of releasing the key are: scancode of pressing the key + 80h
    cmp al, ah			  ;if the scancode match the input - this key is released
	jne CheckKeys_3
    jmp Release_key
CheckKeys_3:
    add si, 2             ;next key = next note 
    inc bl                ;next scancode
    loop CheckKeys
	cmp al, 2Bh           ;exeption for "\" because his scancode dont go as the default pattern, therefore, we check him separtely
    mov si, 26
    je Press_key
    cmp al, 0ABh          ;scancode of releasing "\"
    je Release_key
    mov cx, 10            ;now we are checking the black keys
    mov si, 0
    mov bl, 1Eh           ;scancode of A
CheckBlackKeys:
    cmp al, bl
	jne CheckBlackKeys_2
    jmp Press_black
CheckBlackKeys_2:
    mov ah, bl
    add ah, 80h
    cmp al, ah
	jne CheckBlackKeys_3
    jmp Release_black
CheckBlackKeys_3:
    add si, 2
    inc bl
    loop CheckBlackKeys
    jmp Continue          ;if its none of them: waiting for another input
Press_key:
	push [key_x_coords + si]	;settings for drawing
	push 120
	push 0Ch
	push 15
	push 70
	push [note + si]	  ;set notes divisor
	call openSpeaker	  ;open the speaker
	call rec			  ;coloring the key
	mov [black_key_number], 13
	call black_keys       ;recoloring the black keys because the white one covered it
	jmp Continue
Release_key:
	push [key_x_coords + si]	;settings for drawing
	push 120
	push 0Fh
	push 15
	push 70
	call closeSpeaker	  ;close the speaker
	call rec
	mov [black_key_number], 13
	call black_keys		  ;recoloring the black keys because the white one covered it
	jmp Continue
Press_black:
    push [blackKey_x_coords + si] ;settings for drawing
	push 121
    push 0Ch
	push 10
	push 45
    push [black_note + si]
    call openSpeaker	  ;open the speaker
    call rec
    jmp Continue
Release_black:
    push [blackKey_x_coords + si] ;settings for drawing
	push 121
    push 0F6h
	push 10
	push 45
    call closeSpeaker	  ;close the speaker
    call rec
    jmp Continue
exit_graphic:
	mov ax, 3
	int 10h
exit:
	mov ax, 4C00h
	int 21h
END start