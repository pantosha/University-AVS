LOCALS
.model small
.stack 100h
.386
.const
	cError				db			00h
	cAdd				db			'+'
	cSub				db			'-'
	cMul				db			'*'
	cDiv				db			'/'
	cEsc				db			27
	cEndString			db			'$'
.data
	function			dw			00h
	sMenu				db 			'Add - [+], Sub - [-], Mul - [*], Div - [/], Exit - [ESC]', '$'
	sChooseOperation	db			0Dh, 0Ah, 'Choose operation: ', '$'
	sError				db			0Dh, 0Ah,'Error', '$'
	sDigitA				db			0Dh, 0Ah, 'Number A: ', '$'
	sDigitB				db			0Dh, 0Ah, 'Number B: ', '$'
	sOut 				db			0Dh, 0Ah, 'Answer: ', '$'
	buffer				db			05h, 7 dup (?)
.code
start:
	mov AX, @data
	mov DS, AX	
@@main_cycle:
	call draw_menu
	call choose_operation
	cmp AL, cError
	je @@error
	mov function, AX
	lea DX, sDigitA
	call get_number
	mov BX, AX
	lea DX, sDigitB
	call get_number
	xchg AX, BX
	call DS:[function]
	lea DX, sOut
	call print
	call num2Str
	call getch
	jmp @@main_cycle
@@error:
	call error_msg
	jmp @@main_cycle
@@exit:
	call exit

;-------------------------------------------------
; String in. In DI pointer at the begin of buffer.
;-------------------------------------------------
get_number proc
; Input:
;	DX - string for print to console
; Output:
;	AX - number
	push BX
	pushf
	call print
	lea DX, buffer
	mov AH, 0Ah
	int 21h
; Transform string to number
	lea SI, buffer
	xor BX, BX
	inc SI
	mov BL, byte ptr DS:[SI]
	inc SI
; Put 00h in the end of string
	mov byte ptr [SI + BX], 00h
	call str2Num
	popf
	pop BX
	ret
endp

;------------------------------------------------------
; Convert number to string and print.
;------------------------------------------------------
num2Str proc
; Input:
; 	AX - number for convert
	push BX DX
	test AX, AX
	jns @@not_signed
    mov BX, AX
    mov AH, 02h
	mov DL, '-'
    int 21h
    mov AX, BX
	neg AX
@@not_signed:
	xor CX, CX
	mov BX, 0Ah
@@cycle:
	xor DX, DX
	div BX
	push DX
    inc CX
	test AX, AX
    jnz @@cycle
	mov AH, 02h
@@output:
	pop DX
	add DL, '0'
	int 21h
	loop @@output
	pop DX BX
	ret
endp

;-----------------------------
; Convert string to number.
;-----------------------------
str2Num proc
; Input:
; 	SI - null-terminated string
; Output:
; 	AX - converted number
	push BX SI
	pushf
	xor AX, AX
	xor BX, BX
	cld ; reset DF to null
	lodsb
	push AX
	cmp AL, '+'
	je @@convert
	cmp AL, '-'
	je @@convert
	dec SI
@@convert:
	lodsb 
	sub AL, '0'
	cmp AL, 9d
	ja @@not_digit
	imul BX, 10d
	add BX, AX
	jmp @@convert
@@not_digit:
	mov AX, BX
	pop BX
	cmp BX, '-'
	jne @@return
	neg AX
@@return:
	popf
	pop SI BX
	ret
endp

;--------------------
; Draw Menu.
;--------------------
draw_menu proc
	push AX DX
	mov AX, 0003h
	int 10h
	lea DX, sMenu
	call print
	pop DX AX
	ret
endp

;--------------------
; Choose Operation
;--------------------
choose_operation proc
; Input:
;	nothing
; Output:
;	AX - NULL or function
	push DX
	lea DX, sChooseOperation
	call print
	call getch
@@add:
	cmp AL, cAdd
	jne @@sub
	mov AX, offset add_emul
	jmp @@return
@@sub:
	cmp AL, cSub
	jne @@imul
	mov AX, offset sub_emul
	jmp @@return
@@imul:
	cmp AL, cMul
	jne @@idiv
	mov AX, offset imul_emul
	jmp @@return
@@idiv:
	cmp AL, cDiv
	jne @@exit
	mov AX, offset idiv_emul
	jmp @@return
@@exit:
	cmp AL, cEsc
	jne @@error
	call exit
	jmp @@return
@@error:
	mov AL, cError
@@return:
	pop DX
	ret
endp

;-------------------------------------
; Read character to AL
;-------------------------------------
getch proc
    mov AH, 01
    int 21h
    ret
endp

;--------------------
; Print string
;--------------------
print proc
; In DX - string
	push AX
	mov AH, 9h
	int 21h
	pop AX
	ret
endp

;------------------------------------------
; Second version of "Summator", not tested
;------------------------------------------
;proc 
;mov cx, 1
;add_loop:
;mov ax, a
;mov bx, b
;and ax, cx
;and bx, cx
;mov si, ax
;and si, bx
;mov di, ax
;xor di, bx
;mov ax, dx
;and dx, di
;xor ax, di
;or dx, si
;or res, ax
;shl dx, 1
;shl cx, 1
;jnz add_loop
;endp

proc add_emul
; Input:
;	AX - number B
;	BX - number A
; Output:
;	AX = AX + BX
	push BX CX DX BP
	xor BP, BP
	mov DI, AX
	mov SI, BX
	xor DX, DX
	mov CX, 16
@@cycle:
	mov AX, DI
	mov BX, SI
	
	and AL, 1
	and BL, 1
	mov BH, AL
	xor AL, BL ; AL - partial sum
	and BH, BL ; BH - partial carry
	mov AH, AL
	xor AL, DL ; DL - previous carry, current sum
	and AH, DL
	or AH, BH
	mov DL, AH ; DL - new carry
	
	xor BX, BX
	mov BL, AL
	or BP, BX
	ror BP, 1
	ror DI, 1
	ror SI, 1
loop @@cycle
	mov AX, BP
	pop BP DX CX BX
	ret
endp

proc sub_emul
; Input:
;	AX - number B
;	BX - number A
; Output:
;	AX = AX - BX
	not BX
	inc BX
	call add_emul
	ret
endp

proc imul_emul
; Input:
;	AX - number B
;	BX - number A
; Output:
;	AX = AX * BX
	imul BX
	ret
endp

proc idiv_emul
; Input:
;	AX - number B
;	BX - number A
; Output:
;	AX = AX / BX
	push DX
	cwd
	idiv BX
	pop DX
	ret
endp

error_msg proc
; Input:
;	AX - error code
	pushf
    mov AH, 9
    lea DX, sError
    int 21h
	popf
    ret
endp

;-------------------------------------
; Exit to DOS
;-------------------------------------
exit proc
    mov     AH, 4Ch
    int     21h
	ret
endp
end start