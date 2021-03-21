TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN
; Data                 
ACCESSIBLE_MEMORY db 0DH,0AH,'Size of accessible memory:        $'
EXTENDED_MEMORY db 0DH,0AH,'Size of extended memory:       $'
STR_BYTE db ' byte $'
ADDRESS_PSP db 0DH,0AH,'PSP address:       ',0DH,0AH,'$'
STR_SIZE db 'Size of peace in bytes:        ',0DH,0AH,'$'
SEQUENCE db 'Sequence of chars: $'

; Procedures
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
   push BX
   mov BH,AH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
   push CX
   push DX
   xor AH,AH
   xor DX,DX
   mov CX,10
loop_bd:
   div CX
   or DL,30h
   mov [SI],DL
   dec SI
   xor DX,DX
   cmp AX,10
   jae loop_bd
   cmp AL,00h
   je end_l
   or AL,30h
   mov [SI],AL
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP
;-------------------------------
WRITE_STRING PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
WRITE_STRING ENDP

;-------------------------------

WRITE_MEMORY_SIZE PROC
;save registers
   push ax
   push bx
   push cx
   push dx
   push si
   
	mov bx,10h
	mul bx
	mov bx,0ah
	xor cx,cx

division:
	div bx
	push dx
	inc cx
	xor dx,dx
	cmp ax,0h
	jnz division
   
write_symbol:
	pop dx
	or dl,30h
	mov [si], dl
	inc si
	loop write_symbol
   
   pop si
   pop dx
   pop cx
   pop bx
   pop ax
	ret
WRITE_MEMORY_SIZE ENDP

;-------------------------------

MCB PROC
;save registers
   push ax
   push bx
   push cx
   push dx
   push si
   
   mov ah,52h
   int 21h
   mov ax,es:[bx-2]
   mov es,ax
   xor cx,cx

	inc cx
MCB_PARAGRAPH:
   push cx

	xor ah,ah
	mov al,es:[0]
	push ax
	mov ax,es:[1]
	lea di, ADDRESS_PSP
	add di, 19
	call WRD_TO_HEX
	lea dx, ADDRESS_PSP
	call WRITE_STRING

	mov ax,es:[3]	
	lea si,STR_SIZE
	add si, 24
	call WRITE_MEMORY_SIZE
	lea dx,STR_SIZE
	call WRITE_STRING

	xor dx, dx
	lea dx , SEQUENCE 
	call WRITE_STRING

	mov cx,8
	xor di,di
   
write_char:
	mov dl,es:[di+8]
	mov ah,02h
	int 21h
	inc di
	loop write_char
	
	mov ax,es:[3]	
	mov bx,es
	add bx,ax
	inc bx
	mov es,bx
	pop ax
	pop cx
	inc cx
	cmp al,5Ah
	je the_end
	cmp al,4Dh 
	jne the_end
	jmp MCB_PARAGRAPH

	the_end:
   pop si
   pop dx
   pop cx
   pop bx
   pop ax
	ret
MCB ENDP

FREE_UNUSED_MEMORY PROC
   push ax
   push bx
   push cx
   push dx
   
   lea ax, very_end
   mov bx,10h
   xor dx,dx
   div bx
   inc ax
   mov bx,ax
   add bx,5h
   mov al,0
   mov ah,4AH
   int 21h
   
   pop dx
   pop cx
   pop bx
   pop ax

   ret
FREE_UNUSED_MEMORY ENDP


; Code
BEGIN:
   ;accessible memory
	mov ah,4ah
	mov bx,0ffffh
	int 21h
   mov ax,bx
   lea si, ACCESSIBLE_MEMORY
   add si, 29 ;offset for a number
   call WRITE_MEMORY_SIZE
   lea dx, ACCESSIBLE_MEMORY
   call WRITE_STRING

   lea dx,STR_BYTE
   call WRITE_STRING

   call FREE_UNUSED_MEMORY

   ; extended memory
   mov  AL,30h
   out 70h,AL
   in AL,71h
   mov BL,AL
   mov AL,31h
   out 70h,AL
   in AL,71h
   
	mov bh,al
	mov ax,bx
	lea si,EXTENDED_MEMORY
	add si, 27
	call WRITE_MEMORY_SIZE
	lea dx,EXTENDED_MEMORY
	call WRITE_STRING

	lea dx,STR_BYTE
   call WRITE_STRING

   ;MCB staff
   call MCB

   xor AL,AL
   mov AH,4Ch
   int 21H
very_end:
TESTPC ENDS
END START