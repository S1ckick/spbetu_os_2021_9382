ovl2 SEGMENT
   ASSUME CS:ovl2, DS:NOTHING, SS:NOTHING
   MAIN PROC FAR
      push ax
      push dx
      push ds
      push di
      
      mov ax, cs
      mov ds, ax
      mov di, offset ovl
      add di, 23
      call WRD_TO_HEX
      mov dx, offset ovl
      call WRITE_STRING
      
      pop di
      pop ds
      pop dx
      pop ax
      retf
   MAIN ENDP

   ovl db 13, 10, "OVL2 address:          ", 13, 10, '$'

   WRITE_STRING PROC 
      push dx
      push ax
      mov ah, 09h
      int 21h
      pop ax
      pop dx
      ret
   WRITE_STRING ENDP


   TETR_TO_HEX PROC 
      and al, 0fh
      cmp al, 09
      jbe next
      add al, 07
   next:
      add al, 30h
      ret
   TETR_TO_HEX ENDP


   BYTE_TO_HEX PROC    
      push  cx
      mov   ah, al
      call  TETR_TO_HEX
      xchg  al, ah
      mov   cl, 4
      shr   al, cl
      call  TETR_TO_HEX    
      pop   cx             
      ret
   BYTE_TO_HEX ENDP


   WRD_TO_HEX PROC  
      push  bx
      mov   bh, ah
      call  BYTE_TO_HEX
      mov   [di], ah
      dec   di
      mov   [di], al
      dec   di
      mov   al, bh
      xor   ah, ah
      call  BYTE_TO_HEX
      mov   [di], ah
      dec   di
      mov   [di], al
      pop   bx
      ret
   WRD_TO_HEX ENDP
ovl2 ENDS
END MAIN
