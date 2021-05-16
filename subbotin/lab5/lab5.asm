CODE      SEGMENT
          ASSUME SS:ASTACK, DS:DATA, CS:CODE
          
CUSTOM_INTERRUPTION PROC far
   	jmp START_CUSTOM_INTERRUPTION
INTERRUPTION_DATA:
   	KEEP_IP dw 0
   	KEEP_CS dw 0
      PSP dw 0
      KEEP_AX dw 0
      KEEP_SS dw 0
      KEEP_SP dw 0
      INTERRUPTION_INDEX dw 1234h
      INTER_KEY db 3bh       
	   INTERRUPTION_STACK dw 100h dup (?)


START_CUSTOM_INTERRUPTION:
   	mov KEEP_SS,ss
   	mov KEEP_SP,sp
   	mov KEEP_AX,ax

   	mov ax, seg INTERRUPTION_STACK
   	mov ss,ax
   	mov sp, offset INTERRUPTION_STACK
      add sp, 200h

      push ax
   	push bx
   	push cx
   	push dx
      push si
      push ds
      push bp
      push es


      mov ax, seg INTERRUPTION_DATA
      mov ds, ax
   
   	in al, 60h
      cmp al, INTER_KEY
      je DO_JOB
      pushf
      call dword ptr cs:KEEP_IP
      jmp STR_END 

DO_JOB:
      push ax
      in al, 61h
      mov ah, al

      or al, 80h
      out 61h, al

      xchg ah, al
      out 61h, al

      mov al, 20h
      out 20h, al

      pop ax

WRITE_INTERRUPTION:
      mov ah, 05h
      mov cl, '+'
      xor ch, ch
      int 16h
      or al,al
      jnz DO_SKIP
      jmp STR_END

DO_SKIP:
      mov ax, 0040h
      mov es,ax
      mov ax, es:[1ah]
      mov es:[1ch], ax
      jmp WRITE_INTERRUPTION

STR_END:
      pop es
      pop bp
      pop ds
      pop si
      pop dx
      pop cx
      pop bx
      pop ax

      mov sp, KEEP_SP
      mov ax, KEEP_SS
      mov ss, ax
      mov ax, KEEP_AX
      mov al, 20h
      out 20h, al
      iret

INTERRUPTION_ENDED:
CUSTOM_INTERRUPTION ENDP    

WRITE_STRING PROC near
      push ax
      mov ah,09h
      int 21h
      pop ax
      ret
WRITE_STRING ENDP      

LOAD_FLAG PROC near
   	push ax
      push es

      mov ax, PSP
      mov es, ax
      cmp byte ptr es:[82h], '/'
      jne LOAD_FLAG_END
      cmp byte ptr es:[83h], 'u'
      jne LOAD_FLAG_END
      cmp byte ptr es:[84h], 'n'
      jne LOAD_FLAG_END
      mov FLAG, 1
  
LOAD_FLAG_END:
      pop es
   	pop ax
   	ret
LOAD_FLAG ENDP


IS_LOADED PROC near
   	push ax
   	push si
   
      ;by 35h getting interruption's address 
   	mov ah,35h
   	;09h -- number of interruption
   	mov al,09h
   	int 21h

   	mov si, offset INTERRUPTION_INDEX
   	sub si, offset CUSTOM_INTERRUPTION
   	mov dx,es:[bx+si]
   	cmp dx, 1234h
   	jne IS_LOADED_END
   	mov FLAG_LOAD, 1

IS_LOADED_END:   
   	pop si
   	pop ax
   	ret
IS_LOADED ENDP


LOAD_INTERRUPTION PROC near
   	push ax
      push bx
      push es
   	push dx
      push cx
   
   	mov AH,35h
	   mov AL,09h
	   int 21h 
	   mov KEEP_CS,es
	   mov KEEP_IP,bx
   
   	push ds
   	mov dx, offset CUSTOM_INTERRUPTION
   	mov ax, SEG CUSTOM_INTERRUPTION
   	mov ds, ax
   	mov ah, 25h
   	mov al, 09h
   	int 21h
   	pop ds
   
   	mov dx, offset INTERRUPTION_ENDED
      add dx, 10fh
   	mov cl, 4
   	shr dx, cl
   	inc dx
      xor ax, ax
      mov ah, 31h
      int 21h
      
      pop cx
   	pop dx
      pop es
      pop bx
   	pop ax
   	ret
LOAD_INTERRUPTION ENDP


UNLOAD_INTERRUPTION PROC
      cli
   	push ax
      push bx
      push dx
      push es
   	push si

   	mov ah,35h
	   mov al,09h
	   int 21h

   	mov si, offset KEEP_IP
	   sub si, offset CUSTOM_INTERRUPTION
	   mov dx,es:[bx+si]
	   mov ax,es:[bx+si+2]

      push ds
   	mov ds,ax
   	mov ah,25h
   	mov al,09h
   	int 21h
   	pop ds

   	mov es,es:[bx+si+4]
      push es
   	mov es, es:[2ch]
      mov ah, 49h
      int 21h
      pop es
      mov ah, 49h
      int 21h
   	
   	pop si
      pop es
      pop dx
      pop bx
   	pop ax
      sti
   	ret
UNLOAD_INTERRUPTION ENDP


Main      PROC 
      mov ax, DATA
      mov ds, ax
      mov PSP, es
      call IS_LOADED
      call LOAD_FLAG  
      cmp FLAG, 1
      je UNLOAD
      cmp FLAG_LOAD, 0
      je LOAD
      lea dx, INTERRUPTION_ALREADY_LOADED_SEQ
      call WRITE_STRING
      jmp END_MAIN
UNLOAD:
      cmp FLAG_LOAD, 0
      je NOT_EXIST
      call UNLOAD_INTERRUPTION
      lea dx, INTERRUPTION_UNLOADED_SEQ
      call WRITE_STRING
      jmp END_MAIN

NOT_EXIST:  
      lea dx, INTERRUPTION_NOT_LOADED_SEQ
      call WRITE_STRING
      call END_MAIN

LOAD:
      lea dx, INTERRUPTION_JUST_LOADED_SEQ
      call WRITE_STRING
      call LOAD_INTERRUPTION
END_MAIN:
      xor al, al
      mov ah, 4ch
      int 21h
Main      ENDP
CODE      ENDS

ASTACK    SEGMENT  STACK
   DW 100 DUP(?)   
ASTACK    ENDS

DATA      SEGMENT

   	FLAG_LOAD db 0
   	FLAG db 0

   	INTERRUPTION_JUST_LOADED_SEQ  DB 'Interruption just loaded', 0AH, 0DH,'$'
   	INTERRUPTION_UNLOADED_SEQ  DB 'Interruption just unloaded', 0AH, 0DH,'$'
   	INTERRUPTION_NOT_LOADED_SEQ  DB 'Interruption isnt loaded', 0AH, 0DH,'$'
   	INTERRUPTION_ALREADY_LOADED_SEQ  DB 'Interruption is already loaded', 0AH, 0DH,'$'

DATA      ENDS
          END Main


          