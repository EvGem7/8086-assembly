.MODEL small

.STACK 100h

.DATA
	search_mask db 50 dup (0)
	args_msg db "Specify arguments!$"
	not_found_msg db "File not found!$"
	new_line db 0Dh, 0Ah, '$'
	dta_buff db 80h dup (?)
.CODE

exit MACRO exit_code
	mov ah, 4Ch
	mov al, exit_code
	int 21h
exit ENDM

start:
	mov di, 80h
	mov cl, [di]    ; read cmd line size
	xor ch, ch
	cmp cx, 0
	je no_args
	inc di          ; skip byte with size
	mov al, ' '
	repe scasb      ; skip spaces

	cmp [di - 1], ' '
	jne if_0
	no_args:
		mov ax, @data
		mov ds, ax
		lea dx, args_msg
		call println
		exit 1
	if_0:

	inc cx    ; return to first byte of arg and save its state to stack
	push cx
	dec di
	push di
	
	repne scasb
	cmp [di - 1], ' '
	jne if_1
		inc cx
	if_1:
	pop si
	pop ax
	sub ax, cx
	mov cx, ax

	mov ax, @data
	mov es, ax
	lea di, search_mask
	rep movsb
	
	mov ds, ax            ; move data segment into ds
	
	lea dx, dta_buff
	mov ah, 1Ah
	int 21h

	xor cx, cx
	lea dx, search_mask
	mov ah, 4Eh
	int 21h
	jnc found
		lea dx, not_found_msg
		call println
		exit 0
	found:
		name_offset equ 1Eh
		lea di, dta_buff + name_offset
		xor al, al
		mov cx, -1
		repne scasb
		mov [di - 1], '$'
		lea dx, dta_buff + name_offset
		call println

		mov ah, 4Fh
		int 21h
		jnc found
	exit 0

println PROC
	mov ah, 09h
	int 21h
	push dx
	lea dx, new_line
	mov ah, 09h
	int 21h
	pop dx
	ret
println ENDP

end start