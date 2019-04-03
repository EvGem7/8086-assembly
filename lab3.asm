.MODEL small

BUFFER_SIZE equ 0FFh
MAX_ARRAY_SIZE equ 80h; in the worst case (one digit numbers with one space char as a separator), array size will be BUFFER_SIZE / 2
MAX_DIGITS equ 5; 16bit number has max 5 decimal digits
MIN_NEGATIVE equ 8000h

.DATA
	buffer db BUFFER_SIZE dup (?)
	array dw MAX_ARRAY_SIZE dup (0)
	array_size dw 0
	sizes db MAX_ARRAY_SIZE dup (0)

	START_PROGRAM db "Program started!", 0Dh, 0Ah, '$'
	ENTER_MSG db "Enter numbers:", 0Dh, 0Ah, '$'
	NEW_LINE db 0Dh, 0Ah, '$'

	ZERO db "0$"
	SIGN db "-$"

ends

.STACK 100h

.CODE
exit MACRO
	mov ax, 4Ch
	int 21h
exit ENDM

START:
	mov ax, @data
	mov ds, ax
	mov es, ax

	lea dx, START_PROGRAM
	call print

	lea dx, ENTER_MSG
	call print
	push offset buffer
	push BUFFER_SIZE
	call input

	lea si, buffer

	buffer_loop:
	cmp [si], '$'
	je buffer_loop_exit
		mov al, [si]
		call check_digit

		cmp ah, 0
		je buffer_loop_end
			call parse_number

			cmp dx, 0
			jne buffer_loop_end
				call add_to_array

	buffer_loop_end:
	inc si
	jmp buffer_loop
	buffer_loop_exit:

	xor al, al; max size
	xor bx, bx; index
	mov cx, array_size
	xor si, si; max index
	max_loop:
		cmp al, sizes[bx]
		jae max_loop_end
			mov al, sizes[bx]
			mov si, bx
	max_loop_end:
	inc bx
	loop max_loop
	
	shl si, 1
	mov ax, array[si]
	call print_num

	exit
	
print_num PROC; parameter - ax
	push dx
	push cx
	push bx
	
	cmp ax, 0
	jne print_num_not_zero
		lea dx, ZERO
		call print
		jmp print_num_end
	print_num_not_zero:
	
	cmp ax, MIN_NEGATIVE
	jb print_num_positive
		mov cx, ax; cx is temp
		xor ax, ax
		sub ax, cx
		
		lea dx, SIGN
		call print
	print_num_positive:
	
	xor cx, cx
	mov bx, 0Ah
	print_num_loop:
		xor dx, dx; it fixes overflow (WTF???)
		div bx
		add dx, '0'
		push dx
		inc cx
	cmp ax, 0
	jne print_num_loop
	
	LAST_LOOP:
		mov ah, 6
		pop dx
		int 21h
	loop LAST_LOOP
	
	print_num_end:
	pop bx
	pop cx
	pop dx
	ret
print_num ENDP

add_to_array PROC; parameter - ax
	push di
	push cx

	mov cx, array_size
	cmp cx, 0
	je add_to_array_loop_exit

	xor di, di
	add_to_array_loop:
		cmp ax, array[di]
		jne add_to_array_loop_end
			shr di, 1
			inc sizes[di]
			shl di, 1
			jmp add_to_array_loop_exit
	add_to_array_loop_end:
	add di, 2
	loop add_to_array_loop
	add_to_array_loop_exit:

	cmp cx, 0
	jne add_to_array_end
		mov di, array_size
		inc sizes[di]
		shl di, 1
		mov array[di], ax
		inc array_size

	add_to_array_end:
	pop cx
	pop di
	ret
add_to_array ENDP

parse_number PROC; move str to si. result will be moved to ax. if dx is set to 1 then number is not parsed
	push cx
	push bx

	xor dx, dx; dx contains sign. 1:(-), 0:(+)

	cmp [si], '-'
	jne parse_number_no_sign
		mov dx, 1
		inc si

		mov al, [si]
		call check_digit
		cmp ah, 0
		je parse_number_not_parsed
	parse_number_no_sign:

	xor cx, cx; count digits in cx
	parse_number_check_loop:
		mov al, [si]

		cmp al, '-'
		je parse_number_not_parsed

		call check_digit
		cmp ah, 0
		je parse_number_check_loop_exit
			inc cx
			inc si
			jmp parse_number_check_loop
	parse_number_check_loop_exit:

	dec si; move to last digit

	cmp cx, MAX_DIGITS
	ja parse_number_not_parsed

	push dx
	push si
	xor ax, ax
	mov bx, 1; multiplication coefficient
	parse_number_loop:
		push ax; for multiplication
		xor ax, ax
		mov al, [si]
		sub al, '0'
		mul bx
		cmp dx, 0
		je parse_number_success
			add sp, 2
			jmp parse_number_with_carry
		parse_number_success:
		mov dx, ax
		pop ax

		push ax; for multiplication
		push dx
		mov ax, bx
		mov bx, 0Ah
		mul bx
		mov bx, ax
		pop dx
		pop ax

		add ax, dx
		jnc parse_number_no_carry
		parse_number_with_carry:
			pop si
			add sp, 2
			jmp parse_number_not_parsed
		parse_number_no_carry:
		dec si
	loop parse_number_loop
	pop si
	pop dx

	cmp dx, 0
	je parse_number_end
		mov cx, ax; cx is temp
		xor ax, ax
		sub ax, cx
		xor dx, dx
		jmp parse_number_end

	parse_number_not_parsed:
	mov dx, 1
	jmp parse_number_end

	parse_number_end:
	pop bx
	pop cx
	ret
parse_number ENDP


check_digit PROC; move your parameter into al. result will be moved to ah. 1 - digit, 0 - not digit
	cmp al, '-'
	je check_digit_true

	cmp al, '0'
	jae check_digit_above_zero
	jb check_digit_false

	check_digit_above_zero:
		cmp al, '9'
		jbe check_digit_true
		ja check_digit_false

	check_digit_false:
		xor ah, ah
		ret

	check_digit_true:
		mov ah, 1
		ret
check_digit ENDP

print PROC; move to dx address of a string
	push ax

	xor al, al
	mov ah, 09h
	int 21h

	pop ax
	ret
print ENDP

input PROC; push str then size (size is byte)
	push ax
	push bx
	push cx
	push dx
	push bp
	mov bp, sp
	str equ bp+0Eh
	size equ bp+0Ch

	mov ah, 0Ah
	xor al, al
	mov dx, str
	mov bx, str
	mov cx, size; cx - temp
	mov [bx], cl
	int 21h

	mov cl, [bx+1]; read chars amount
	xor ch, ch
	INPUT_LOOP:   ; move string
		mov al, [bx+2]; al - temp
		mov [bx], al
		inc bx
	loop INPUT_LOOP
	mov [bx], '$'

	lea dx, NEW_LINE
	call print

	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	ret
input ENDP

end start