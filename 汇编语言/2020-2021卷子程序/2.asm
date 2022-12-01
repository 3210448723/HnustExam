code    segment
    assume  cs:code
start:    
	mov ax,1234H
	mov bx,0abcdH
	add ax,bx
	mov ax,1234H
	sub ax,bx
	mov   ah,4ch          	 ;程序终止并退出  
	int   21h
code    ends
	end   start