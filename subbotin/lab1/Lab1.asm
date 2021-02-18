
TESTPC		SEGMENT
			ASSUME	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
			ORG		100H
START:		JMP		BEGIN
;ДАННЫЕ

PC_STR 		db 		'Type: PC',0DH,0AH,'$'
PC_XT_STR   db 		'Type: PC/XT',0DH,0AH,'$'
AT_STR 		db 		'Type: AT',0DH,0AH,'$'
PS2_30_STR 	db 		'Type: PS2 model 30',0DH,0AH,'$'
PS2_80_STR  db 		'Type: PS2 model 80',0DH,0AH,'$'
PSjr_STR 	db 		'Type: PSjr',0DH,0AH,'$'
PC_Conv_STR db 		'Type: PC Convertible',0DH,0AH,'$'
MS_DOS_VERSION db 	'MS DOS Version:   .  ',0DH,0AH,'$'
OEM 		db 		'OEM:   ',0DH,0AH,'$'
NUMBER 		db 		'Serial number:                        $'

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
TYPE_IBM_PC 	PROC		near
			mov		ax,0F000h
			mov		es,ax
			mov		al,es:[0FFFEh]

			cmp		al,0FFh
			je 		PC

			cmp		al,0FEh
			je 		PC_XT
			cmp		al,0FBh
			je 		PC_XT

			cmp		al,0FCh
			je  	AT

			cmp  	al,0FAh
			je 		PS2_30

			cmp 	al,0F8h
			je 		PS2_80

			cmp 	al,0FDh
			je 		PSjr

			cmp 	al,0F9h
			je 		PC_Conv

PC:
			mov 	dx,offset PC_STR
			jmp 	write_type
PC_XT:
 			mov 	dx,offset PC_XT_STR
 			jmp 	write_type
AT:
			mov 	dx,offset AT_STR
			jmp 	write_type
PS2_30:
			mov 	dx,offset PS2_30_STR
			jmp 	write_type
PS2_80:
			mov 	dx,offset PS2_80_STR
			jmp 	write_type
PSjr:
			mov 	dx,offset PSjr_STR
			jmp 	write_type
PC_Conv:
			mov 	dx,offset PC_Conv_STR

write_type:
			mov 	AH,09h
   			int 	21h

   			ret
TYPE_IBM_PC		ENDP
;--------------------------------
OS_VERSION 		PROC 		near
			mov		ah,30h
			int 	21h

			push ax
			mov 	si, offset MS_DOS_VERSION
			add 	si,17  ;подвинемся на место первой цифры версии в выводе
			call 	BYTE_TO_DEC ; переводим число al в десятичное и сохраняем в память куда указывает si
			pop ax

			mov 	al, ah
   			add 	si, 3; чуть подвинем указатель
			call 	BYTE_TO_DEC
			mov 	dx, offset MS_DOS_VERSION
			
			mov 	AH,09h
   			int 	21h

   			mov 	si, offset OEM
			add 	si, 5
			mov 	al, bh
			call 	BYTE_TO_DEC
			mov 	dx, offset OEM

			mov 	AH,09h
   			int 	21h

   			mov 	di, offset NUMBER
			add 	di, 20
			mov 	ax, cx
			call 	WRD_TO_HEX ; уже занесли число в память.
			sub     di,2

			mov 	al, bl
			call 	BYTE_TO_HEX
			mov 	[di], ax
			mov 	dx, offset NUMBER

			mov 	AH,09h
   			int 	21h

   			ret
OS_VERSION	    ENDP


; КОД
BEGIN:
   			call TYPE_IBM_PC
   			call OS_VERSION


;Выход в DOS
			xor		AL,AL
			mov		AH,4Ch
			int		21H
TESTPC		ENDS
			END 	START 		;конец модуля, START - точка входа


























