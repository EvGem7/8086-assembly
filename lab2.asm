.MODEL small

BUFFER_SIZE equ 200
STRING_SIZE equ 66; 200 / 3

.DATA    
    buffer db BUFFER_SIZE dup (?)
    source dw (0)
    replaceable dw (0)
    replacement dw (0)
    s_size db (0)
    r_able_size db (0)
    r_ment_size db (0)
    
    START_PROGRAM db "Progam started!", 13, 10, '$'
    SOURCE_INPUT db "Enter the source string:", 13, 10, '$'
    REPLACEABLE_INPUT db "What string do you want to replace?", 13, 10, '$'
    REPLACEMENT_INPUT db "Which string do you want to replace this one with?", 13, 10, '$'
    NEW_LINE db 13, 10, '$'
    SIZES_NOT_EQUAL_MSG db "Sizes of replaceable and replacement strings must be equal", 13, 10, '$'
    
ends

offset_print_string macro string
    mov ah, 09h
    mov dx, offset string
    int 21h
endm

input_string macro string, size
    mov ah, 0Ah; preparing for input
    mov dx, string
    mov bx, dx
    mov [bx], STRING_SIZE
    dec [bx]
    int 21h
    
    offset_print_string NEW_LINE
    
    add string, 2; move string pointer to the start of the string
    
    inc bx; get string size
    mov bl, [bx]
    mov size, bl
    
    xor bh, bh; move bx to the end of the string
    add bx, string
    
    mov [bx], 13; add specific output chars
    inc bx
    mov [bx], 10
    inc bx
    mov [bx], '$'
endm

print_string macro string
    mov ah, 09h
    mov dx, string
    int 21h
endm

.CODE
    mov ax, @data
    mov ds, ax
    mov source, offset buffer
    mov replaceable, offset buffer + STRING_SIZE
    mov replacement, offset buffer + STRING_SIZE + STRING_SIZE
    
    offset_print_string START_PROGRAM
 
    offset_print_string SOURCE_INPUT
    input_string source, s_size
    
    offset_print_string REPLACEABLE_INPUT
    input_string replaceable, r_able_size
    
    offset_print_string REPLACEMENT_INPUT
    input_string replacement, r_ment_size
    
    mov al, r_able_size
    mov ah, r_ment_size
    cmp al, ah 
    jne sizes_not_equal
    
    mov cl, s_size
    xor ch, ch
    mov bx, source     
    source_loop:
        mov ax, cx; save cx state
        
        xor cx, cx
        mov cl, r_able_size
        cmpsb bx, replaceable
        je found_equal 
        loop source_loop
    
exit:
    mov ax, 4Ch; exit
    int 21h
    
sizes_not_equal:
    offset_print_string SIZES_NOT_EQUAL_MSG
    jmp exit
    
found_equal:
            
ends   