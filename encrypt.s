global _start
section .data
	src_text: db 	"Some plain text 4 test (Aa !@#$%^&*({})"
	text_len: equ $-src_text
	key: db 	"Some test key (Aa !@!%$!@%*&@!%!#%&^!!@^({})"
	key_len: equ $-key
	printCount: dw 95
	endl: db 0,10
section .text
_start:
	mov eax,4
	mov ebx,1
	mov ecx,src_text
	mov edx,text_len
	int 0x80
	mov eax,4
	mov ebx,1
	mov ecx,endl
	mov edx,2
	int 0x80

;*****************
;TEST OPENING FILE
;*****************
section .data
	filename: db "text.txt",0
	error_msg: db "ERROR OPENING FILE",10,0
	error_msg_len: equ $-error_msg
	read_msg: db "ERROR READING FROM FILE",10,0
	read_len: equ $-read_msg
	succesfull_msg: db "OK",10,0
	succesfull_len: equ $-succesfull_msg
section .bss
	descriptor: resb 4
	buffer: resb 4096
section .text
	mov eax,5		;open
	mov ebx,filename	;filename
	mov ecx,0		;read only
	int 0x80
	test eax,eax
	js open_error		;Error, if eax<0
	mov eax,4
	mov ebx,1
	mov ecx,succesfull_msg
	mov edx,succesfull_len
	int 0x80
	mov [descriptor],eax	;file descriptor in descriptor
	mov ebx,eax		;ebx - file descriptor
	mov eax,3		;read from file
	mov ecx,buffer		;read to buffer
	mov edx,4096		;read 4096 bytes
	int 0x80
	test eax,eax
	js read_error		;error, if eax<0
	mov edx,eax		;edx - count of readed bytes
	mov eax,4
	mov ebx,1
	mov ecx,buffer
	int 0x80
	mov eax,6		;close file
	mov ebx,[descriptor]	;ebx- descriptor
	int 0x80
	mov eax,1
	mov ebx,0
	int 0x80
open_error:
	mov eax,4
	mov ebx,1
	mov ecx,error_msg
	mov edx,error_msg_len
	int 0x80
	mov eax,1
	mov ebx,0
	int 0x80
read_error:
	mov eax,4
	mov ebx,1
	mov ecx,read_msg
	mov edx,read_len
	int 0x80
	mov eax,1
	mov ebx,0
	int 0x80
;*****************

	call encrypt
	mov eax,4
	mov ebx,1
	mov ecx,src_text
	mov edx,text_len
	int 0x80
	mov eax,4
	mov ebx,1
	mov ecx,endl
	mov edx,2
	int 0x80
	call decrypt
	mov eax,4
	mov ebx,1
	mov ecx,src_text
	mov edx,text_len
	int 0x80
	mov eax,4
	mov ebx,1
	mov ecx,endl
	mov edx,2
	int 0x80
	mov eax,1
	mov ebx,0
	int 0x80

;encrypt inputs:
; key - address of key string in memory
; key_len - count of bytes in key
; src_text - address of plain text string in memory
; text_len - count of bytes in plain text
encrypt:
._start:
	push eax
	push ebx
	push ecx
	push edx
	mov ebx,key_len ;bx - lenght of key
	xor ecx,ecx ;ecx - pos of current char in text(start from 0)
._loop:
	xor edx,edx
	mov ax,cx ;DX:AX = CX (in AX) (AX=CX=pos of cur char in text)
	div bx ;dx - pos of char in key for encoding
	push ebx
	xor bh,bh
	mov bl,byte[src_text+ecx] ;bl - 'original' char
	add bl,byte[key+edx] ;bx - new encoded symbol(without mod(95))
	sub bl,64
	xor dx,dx
	mov ax,bx ;DX:AX = BX (in AX)
	div word[printCount] ;encoded symbol with mod(95) in DX(dh=0,dl=char) (printCount == 95)
	pop ebx
	add dl,byte' '
	mov byte[src_text+ecx],dl
	inc ecx
	cmp ecx,text_len
	jl ._loop
pop edx
pop ecx
pop ebx
pop eax
ret

;decrypt inputs:
; key - address of key string in memory
; key_len - count of bytes in key
; src_text - address of encoded text string in memory
; text_len - count of bytes in encoded text
decrypt:
._start:
	push eax
	push ebx
	push ecx
	push edx
	mov ebx,key_len ;bx - lenght of key
	xor ecx,ecx ;ecx-pos of curr char in text(start from 0)
._loop:
	xor edx,edx
	mov ax,cx ;DX:AX = CX (in AX) (AX=CX=pos of cur char in text)
	div bx ;edx - pos of char in key for encoding
	push ebx
	xor ebx,ebx
	mov bl,byte[src_text+ecx] ;bl - encrypted char in text
	cmp bl,byte[key+edx] ; compare encrypted symbol and key symbol
	jge ._greater ;if (text[i] >= key[i]) continue;
	add bl,95
._greater:
	sub bl,byte[key+edx]
	add bl,byte' ' ;bl - decoded symbol? (yep)
	mov dl,bl
	pop ebx
	mov byte[src_text+ecx],dl ;writing decoded symbol in src_text
	inc ecx
	cmp ecx,text_len
	jl ._loop
pop edx
pop ecx
pop ebx
pop eax
ret