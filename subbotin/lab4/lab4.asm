CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:ASTACK
          
CUSTOM_INTERRUPTION PROC far
   	jmp START_CUSTOM_INTERRUPTION
   
   	PSP dw ?
   	KEEP_IP dw 0
   	KEEP_CS dw 0
   	KEEP_SS dw ?
	KEEP_SP dw ?
	KEEP_AX dw ?

   	INTERRUPTION_INDEX dw 1234h
   	TIMER db 'Timers counter: 0000$'              
	INTERRUPTION_STACK dw 200 dup (?)
	END_STACK dw ?
   
START_CUSTOM_INTERRUPTION:
   	mov KEEP_SS,ss
   	mov KEEP_SP,sp
   	mov KEEP_AX,ax

   	mov ax,cs
   	mov ss,ax
   	mov sp, offset END_STACK

   	push bx
   	push cx
   	push dx
   
   	;getting cursor
	mov ah,3h
	mov bh,0h
	int 10h

	push dx ; cursor position (row,column) in dx
   
   	;setting cursor
	mov ah,02h
	mov bh,0h
   	mov dh,02h
   	mov dl,09h
	int 10h
   
   	push si
	push cx
	push ds
   	push bp
   
	mov ax, SEG TIMER
	mov ds,ax
	mov si, offset TIMER
	add si,15 

   	mov cx,4  

INTERRUPTION_LOOP:
   	mov bp,cx
   	mov ah,[si+bp]
	inc ah
	mov [si+bp],ah
	cmp ah,3ah
	jne TIMER_WRITER
	mov ah,30h
	mov [si+bp],ah

   	loop INTERRUPTION_LOOP 
    
TIMER_WRITER:
   	pop bp
   
   	pop ds
   	pop cx
   	pop si
   
   	;write timer
	push es
	push bp
   
	mov ax, SEG TIMER
	mov es,ax
	mov ax, offset TIMER
	mov bp,ax
	mov ah,13h
	mov al,00h
	mov cx,20
	mov bh,0
	int 10h
   
	pop bp
	pop es
   
	;return cursor
	pop dx
	mov ah,02h
	mov bh,0h
	int 10h

	pop dx
	pop cx
	pop bx
   
	mov ax, KEEP_SS
	mov ss,ax
	mov ax, KEEP_AX
	mov sp, KEEP_SP

   	iret
INTERRUPTION_ENDED:
CUSTOM_INTERRUPTION ENDP          

LOAD_FLAG PROC near
   	push ax
   
   	mov PSP,es
   	mov al,es:[81h+1]
   	cmp al,'/'
   	jne LOAD_FLAG_END

   	mov al,es:[81h+2]
   	cmp al,'u'
   	jne LOAD_FLAG_END

   	mov al,es:[81h+3]
   	cmp al,'n'
   	jne LOAD_FLAG_END

   	mov FLAG,1h
  
LOAD_FLAG_END:
   	pop ax
   	ret
LOAD_FLAG ENDP


IS_LOADED PROC near
   	push ax
   	push si
   
    ;by 35h getting interruption's address 
   	mov ah,35h
   	;1ch -- number of interruption
   	mov al,1ch
   	int 21h

   	mov si, offset INTERRUPTION_INDEX
   	sub si, offset CUSTOM_INTERRUPTION
   	mov dx,es:[bx+si]
   	cmp dx, INTERRUPTION_INDEX
   	jne IS_LOADED_END
   	mov FLAG_LOAD,1h

IS_LOADED_END:   
   	pop si
   	pop ax
   	ret
IS_LOADED ENDP


WRITE_STRING PROC near
   	push ax
   	mov ah,09h
   	int 21h
   	pop ax
   	ret
WRITE_STRING ENDP


LOAD_INTERRUPTION PROC near
   	push ax
   	push dx
   
   	;checking if interruption is already loaded
   	call IS_LOADED
   	cmp FLAG_LOAD,1h
   	je CUSTOM_ALREADY_LOADED
   	jmp STARTING_TO_LOAD
   
CUSTOM_ALREADY_LOADED:
   	lea dx, INTERRUPTION_ALREADY_LOADED_SEQ
   	call WRITE_STRING
   	jmp END_LOADED
  
STARTING_TO_LOAD:
   	mov AH,35h
	mov AL,1ch
	int 21h 
	mov KEEP_CS,es
	mov KEEP_IP,bx
   
   	push ds
   	lea dx, CUSTOM_INTERRUPTION
   	mov ax, SEG CUSTOM_INTERRUPTION
   	mov ds,ax
   	mov ah,25h
   	mov al,1ch
   	int 21h
   	pop ds
   	lea dx, INTERRUPTION_JUST_LOADED_SEQ
   	call WRITE_STRING
   
   	lea dx, INTERRUPTION_ENDED
   	mov cl,4h
   	shr dx,cl
   	inc dx
   	mov ax,cs
   	sub ax, PSP
   	add dx,ax
   	xor ax,ax
   	mov ah,31h
   	int 21h
     
END_LOADED:  
   	pop dx
   	pop ax
   	ret
LOAD_INTERRUPTION ENDP


UNLOAD_INTERRUPTION PROC near
   	push ax
   	push si
   
   	call IS_LOADED
   	cmp FLAG_LOAD,1h
   	je START_UNLOAD
   
   	lea dx, INTERRUPTION_NOT_LOADED_SEQ
   	call WRITE_STRING
   	jmp UNLOAD_END
   
START_UNLOAD:
   	cli 
   	push DS
   	mov ah,35h
	mov al,1ch
	int 21h

   	mov si, offset KEEP_IP
	sub si, offset CUSTOM_INTERRUPTION
	mov dx,es:[bx+si]
	mov ax,es:[bx+si+2]
   	mov ds,ax
   	mov ah,25h
   	mov al,1ch
   	int 21h
   	pop ds
   
   	
   	mov ax,es:[bx+si-2]
   	mov es,ax
   	push es
   
   	mov ax,es:[2ch]
   	mov es,ax
   	mov ah,49h
   	int 21h
   
   	pop es
   	mov ah,49h
   	int 21h
   	sti
   
   	lea dx, INTERRUPTION_UNLOADED_SEQ
   	call WRITE_STRING
UNLOAD_END:   
   	pop si
   	pop ax
   	ret
UNLOAD_INTERRUPTION ENDP


Main      PROC  FAR
   	push  DS       
   	xor   AX,AX    
   	push  AX       
   	mov   AX,DATA             
   	mov   DS,AX

   	call LOAD_FLAG
   	cmp FLAG, 1h
   	je IF_UNLOADED
   	call LOAD_INTERRUPTION
   	jmp THE_END
   
IF_UNLOADED:
   	call UNLOAD_INTERRUPTION
   
THE_END:  
   	mov ah,4ch
   	int 21h    
Main      ENDP
CODE      ENDS

ASTACK    SEGMENT  STACK
   DW 200 DUP(?)   
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