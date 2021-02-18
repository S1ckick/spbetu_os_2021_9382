
TESTPC		SEGMENT
			ASSUME	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
			ORG		100H
START:		JMP		BEGIN
;ДАННЫЕ

LOCKED_MEMORY_ADDRESS db 'Locked memory address:     h',0DH,0AH,'$'
ENVIRONMENT_ADDRESS   db 'Environment address:     h',0DH,0AH,'$'
TAIL_COMMAND_LINE	  db 'Tail of command line:                  ',0DH,0AH,'$'
CONTAINER			  db 'Environment scope content:                ',0DH,0AH,'$'
PATH 				  db 'Modules Path:                             ',0DH,0AH,'$'
EMPTY_TAIL            db 'Tail is empty!',0DH,0AH,'$'
END_STRING            db 0DH,0AH, '$'


;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX		PROC		near
			and		AL,0Fh
			cmp		AL,09
			jbe		NEXT
			add		AL,07
NEXT:		add		AL,30h
			ret
TETR_TO_HEX		ENDP
;--------------------------------
BYTE_TO_HEX		PROC		near
;байт в AL переводится в два символа шестн. числа в AX
			push	CX
			mov		AH,AL
			call 	TETR_TO_HEX
			xchg	AL,AH
			mov		CL,4
			shr		AL,CL
			call	TETR_TO_HEX ; в AL старшая цифра
			pop		CX          ; в AH младшая
			ret
BYTE_TO_HEX		ENDP
;--------------------------------
WRD_TO_HEX		PROC		near
;перевод в 16 сс 16-ти разрядного числа
;в AX - число, DI - адрес последнего символа
			push	BX
			mov 	BH,AH
			call 	BYTE_TO_HEX
			mov		[DI],AH
			dec		DI
			mov		[DI],AL
			dec		DI
			mov		AL,BH
			call	BYTE_TO_HEX
			mov		[DI],AH
			dec		DI
			mov		[DI],AL
			pop		BX
			ret
WRD_TO_HEX	ENDP
;--------------------------------
BYTE_TO_DEC		PROC		near
;перевод в 10сс, SI - адрес поля младшей цифры
			push	CX
			push	DX
			xor		AH,AH
			xor		DX,DX
			mov		CX,10
loop_bd:	div		CX
			or      DL,30h
			mov		[SI],DL
			dec     SI
			xor 	DX,DX
			cmp 	AX,10
			jae		loop_bd
			cmp		AL,00h
			je 		end_l
			or 		AL,30h
			mov		[SI],AL
end_l:		pop		DX
			pop		CX
			ret
BYTE_TO_DEC		ENDP
;--------------------------------

PSP_LOCKED_MEMORY proc near
   	mov ax, ds:[02h] ; берем сегментный адрес недоступной памяти
   	mov di, offset LOCKED_MEMORY_ADDRESS
   	add di, 26
   	call WRD_TO_HEX
   	mov dx, offset LOCKED_MEMORY_ADDRESS
   	mov AH, 09h
   	int 21h
   	ret
PSP_LOCKED_MEMORY ENDP

PSP_ENVIRONMENT_ADDRESS proc near
	mov ax, ds:[2Ch] ; берем значение сегментного адреса среды
   	mov di, offset ENVIRONMENT_ADDRESS 
   	add di, 24
   	call WRD_TO_HEX
   	mov dx, offset ENVIRONMENT_ADDRESS 
   	mov AH, 09h
   	int 21h
   	ret
PSP_ENVIRONMENT_ADDRESS ENDP

PSP_TAIL proc near   
    xor cx, cx
	mov cl, ds :[80h] ; кладем в cl число символов в хвосте командной строки
	mov si, offset TAIL_COMMAND_LINE
	add si, 23
    cmp cl, 0h ; сравниваем количество символов в хвосте с нулем
    je empty_tail_jmp ; если хвост пуст
    ; выполняем если есть символы
	xor di, di
	xor ax, ax
read_tail: 
	mov al, ds : [81h+di]
    inc di
    mov [si], al
	inc si
	loop read_tail ; выполняется столько раз, сколько значение ecx, а оно у нас равно cl
	mov dx, offset TAIL_COMMAND_LINE
	jmp end_tail
empty_tail_jmp:
	mov dx, offset EMPTY_TAIL ; выводим информацию о том, что в хвосте нет элементов
end_tail: 
    mov AH, 09h
    int 21h
    ret
PSP_TAIL ENDP

PSP_CONTAINER PROC near
   mov dx, offset CONTAINER
   mov AH, 09h
   int 21h

   xor di,di
   mov ds, ds:[2Ch] ; получаем сегментный адрес среды

read_line:
	cmp byte ptr [di], 00h
	jz end_line
	mov dl, [di]
	mov ah, 02h ; выводим
	int 21h
	jmp find_end
end_line:
    cmp byte ptr [di+1],00h
    jz find_end
    push ds

    mov cx, cs
	mov ds, cx
	mov dx, offset END_STRING
	mov AH, 09h
    int 21h

	pop ds
find_end:
	inc di
	cmp word ptr [di], 0001h 
	jne read_line ; если не нашли 0001h, значит еще рано для маршрута загруженной программы

	;получаем маршрут загруженной программы
	push ds
	mov ax, cs
	mov ds, ax
	mov dx, offset PATH
	mov AH, 09h ; выводим 'Modules Path: '
    int 21h

	pop ds
	add di, 2 ; пропускаем 0001h и начинаем считывать путь
loop_path:
	cmp byte ptr [di], 00h
	jz end_of_path
	mov dl, [di]
	mov ah, 02h
	int 21h
	inc di
	jmp loop_path
end_of_path:
	ret
PSP_CONTAINER ENDP


; КОД
BEGIN:
   			call PSP_LOCKED_MEMORY
   			call PSP_ENVIRONMENT_ADDRESS
   			call PSP_TAIL
   			call PSP_CONTAINER

;Выход в DOS
			xor		AL,AL
			mov		AH,4Ch
			int		21H
TESTPC		ENDS
			END 	START 		;конец модуля, START - точка входа


























