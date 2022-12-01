data segment
	info db 'ERROR$'
data ends

code    segment
    assume  cs:code,ds:data
start:    
	mov ax,data
	mov ds,ax

	mov ah,1
	int 21H
	
	cmp al,'0'
	jl error

	cmp al,'9'
	jle num

	cmp al,'A'
	jl error

	cmp al,'Z'
	jle lower

	cmp al,'a'
	jl error

	cmp al,'z'
	jle upper

	jmp error

lower:
	add al,20H
	MOV DL,AL
	mov ah,2
	int 21H
	jmp ended
upper:
	sub al,20H
	MOV DL,AL
	mov ah,2
	int 21H
	jmp ended

num:
	mov dl,al
	mov ah,2
	int 21h
	jmp ended

error:
	lea dx,info
	mov ah,9
	int 21h

ended:
	mov   ah,4ch          	 ;程序终止并退出  
	int   21h
code    ends
	end   start