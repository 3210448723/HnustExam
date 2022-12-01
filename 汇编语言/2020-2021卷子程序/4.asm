data segment
	org 100H
	array label byte
	val1 dw 3,6,9,1234H,-5
	val2 db 5,'ABCDE'
	len=$-val2
	array2 db 3 dup(1,4,7)
data ends
code    segment
    assume  cs:code,ds:data
start:    
	mov ax,data
	mov ds,ax
	mov al,array+2
	sub al,val2
	mov ax,val1+4
	mov bx,len
	add ax,bx

	mov   ah,4ch          	 ;程序终止并退出  
	int   21h
code    ends
	end   start