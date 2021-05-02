AStack    SEGMENT  STACK
          DW 128 DUP(?)   
AStack    ENDS

DATA  SEGMENT 
   FILE_1 db 'FILE1.OVL', 0 
   FILE_2 db 'FILE2.OVL', 0
   prog dw 0
   data_mem db 43 dup(0)
   POS_CL db 128 dup(0) 
   ovls_addr dd 0             
   KEEP_PSP dw 0


   eof db 13, 10, '$'
   MEMORY_N7 db 'Destroyed memory block',13,10,'$'
   MEMORY_N8 db 'Not enough memory for running function',13,10,'$'
   MEMORY_N9 db 'Incorrect memorys address',13,10,'$'
   
   ERROR_N1  db 'Wrong functions number',13,10,'$'
   ERROR_N2  db 'File was not found',13,10,'$'
   ERROR_N5  db 'Disk error',13,10,'$'
   ERROR_N8  db 'Disk has not enough free memory space',13,10,'$'
   ERROR_N10 db 'Wrong string enviroment',13,10,'$'
   ERROR_N11 db 'Incorrect format',13,10,'$'
   
   END_N0 db 'Normal ending',13,10,'$'
   END_N1 db 'Ending by ctrl-break',13,10,'$'
   END_N2 db 'Ending by device error',13,10,'$'
   END_N3 db 'Ending by 31h function',13,10,'$'

   ALLOCATE_SUC_STR db 'memory allocated successfully', 13, 10, '$'
   FILE_ERROR_STR db 'File not found', 13, 10, '$'
   ROUTE_ERROR_STR db 'Route not found', 13, 10, '$'

   end_data db 0
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE,DS:DATA,SS:AStack

WRITE_STRING PROC
   push ax
   mov ah, 09h
   int 21h
   pop ax
   ret
WRITE_STRING ENDP

FREE_MEMORY PROC
   push ax
   push bx
   push cx
   push dx

   mov ax, offset end_data
   mov bx, offset END_APP
   add bx, ax
   shr bx, 1
   shr bx, 1
   shr bx, 1
   shr bx, 1
   add bx, 2bh
   mov ah, 4ah
   int 21h

   jnc END_FREE_MEMORY
   
   lea dx, MEMORY_N7
   cmp ax, 7
   je WRITE_MEMORY_COMMENT
   lea dx, MEMORY_N8
   cmp ax, 8
   je WRITE_MEMORY_COMMENT
   lea dx, MEMORY_N9
   cmp ax, 9
   je WRITE_MEMORY_COMMENT
   jmp END_FREE_MEMORY
   
WRITE_MEMORY_COMMENT:
   mov ah, 09h
   int 21h
   
END_FREE_MEMORY: 
   pop dx
   pop cx  
   pop bx
   pop ax
   ret
FREE_MEMORY ENDP

SET_FULL_FILENAME PROC NEAR
   push ax
   push bx
   push cx
   push dx
   push di
   push si
   push es

   mov prog, dx
   
   mov ax, KEEP_PSP
   mov es, ax
   mov es, es:[2ch]
   mov bx, 0
   
FIND_SMTH:
   inc bx
   cmp byte ptr es:[bx-1], 0
   jne FIND_SMTH
   cmp byte ptr es:[bx+1], 0
   jne FIND_SMTH

   add bx, 2
   mov di, 0

FIND_LOOP:
   mov dl, es:[bx]
   mov byte ptr [POS_CL + di], dl
   inc di
   inc bx
   cmp dl, 0
   je END_LOOP
   cmp dl, '\'
   jne FIND_LOOP
   mov cx, di
   jmp FIND_LOOP
END_LOOP:
   mov di, cx
   mov si, prog

LOOP_2:
   mov dl, byte ptr[si]
   mov byte ptr [POS_CL + di], dl
   inc di
   inc si
   cmp dl, 0
   jne LOOP_2

   pop es
   pop si
   pop di
   pop dx
   pop cx
   pop bx
   pop ax
   ret
SET_FULL_FILENAME ENDP

DEPLOY_ANOTHER_PROGRAM PROC NEAR
   push ax
   push bx
   push cx
   push dx
   push ds
   push es  

   mov ax, DATA
   mov es, ax
   mov bx, offset ovls_addr
   mov dx, offset POS_CL
   mov ax, 4b03h
   int 21h 
   
   jnc COME_OVER

   err_1:
   cmp ax, 1
   jne err_2
   mov dx, offset ERROR_N1
   call WRITE_STRING
   jmp DEPLOY_END

   err_2:
   cmp ax, 2
   jne err_5
   mov dx, offset ERROR_N2
   call WRITE_STRING
   jmp DEPLOY_END

   err_5:
   cmp ax, 5
   jne err_8
   mov dx, offset ERROR_N5
   call WRITE_STRING
   jmp DEPLOY_END

   err_8:
   cmp ax, 8
   jne err_10
   mov dx, offset ERROR_N8
   call WRITE_STRING
   jmp DEPLOY_END

   err_10:
   cmp ax, 10
   jne err_11
   mov dx, offset ERROR_N10
   call WRITE_STRING
   jmp DEPLOY_END

   err_11:
   cmp ax, 11
   mov dx, offset ERROR_N11
   call WRITE_STRING
   jmp DEPLOY_END

   COME_OVER:
   mov dx, offset END_N0
   call WRITE_STRING
   
   mov ax, word ptr ovls_addr
   mov es, ax
   mov word ptr ovls_addr, 0
   mov word ptr ovls_addr + 2, ax

   call ovls_addr
   mov es, ax
   mov ah, 49h
   int 21h

   DEPLOY_END:
   pop es
   pop ds
   pop dx
   pop cx
   pop bx
   pop ax
   ret
DEPLOY_ANOTHER_PROGRAM ENDP

ALLOCATE_MEMORY PROC
   push ax
   push bx
   push cx
   push dx

   push dx
   mov dx, offset data_mem
   mov ah, 1ah
   int 21h
   pop dx
   mov cx, 0
   mov ah, 4eh
   int 21h

   jnc ALLOCATE_SUCCESS

   cmp ax, 2
   je ROUTE_ERR
   mov dx, offset FILE_ERROR_STR
   call WRITE_STRING
   jmp ALLOCATE_END

ROUTE_ERR:
   cmp ax, 3
   mov dx, offset ROUTE_ERROR_STR
   call WRITE_STRING
   jmp ALLOCATE_END


ALLOCATE_SUCCESS:
   push di
   mov di, offset data_mem
   mov bx, [di + 1ah]
   mov ax, [di + 1ch]
   pop di
   push cx
   mov cl, 4
   shr bx, cl
   mov cl, 12
   shl ax, cl
   pop cx
   add bx, ax
   add bx, 1
   mov ah, 48h
   int 21h
   mov word ptr ovls_addr, ax
   mov dx, offset ALLOCATE_SUC_STR
   call WRITE_STRING

ALLOCATE_END:
   pop dx
   pop cx
   pop bx
   pop ax
   ret
ALLOCATE_MEMORY ENDP

START_OVL PROC
   push dx
   call SET_FULL_FILENAME
   mov dx, offset POS_CL
   call ALLOCATE_MEMORY
   call DEPLOY_ANOTHER_PROGRAM
   pop dx
   ret
START_OVL ENDP

Main PROC FAR
   push ds
   xor   ax, ax
   push  ax
   mov   ax, DATA
   mov   ds, ax
   mov KEEP_PSP, es
   call FREE_MEMORY
   mov dx, offset FILE_1
   call START_OVL
   mov dx, offset eof
   call WRITE_STRING
   mov dx, offset FILE_2
   call START_OVL
   
VERY_END:
   xor al,al
   mov ah,4ch
   int 21h
Main ENDP
END_APP:
CODE ENDS
      END Main