;convert -depth 8 -resize 200x200 lenna.png gray:input
;convert -depth 8 -size 200x200 gray:input output.png

len	EQU	10
area	EQU	100
IFSIZE	EQU	100
wx	EQU	3
wy	EQU	3
wa	EQU	9
wm	EQU 	4
__data	segment	'data'

;file stuff
	handle	dw	?
	ifname	db	"C:\I", 0
	ofname	db	"C:\O"
	ofc	db	"0"
		db	0

	window	db	wa	dup(0)
	fread	db	"finished reading yahooo!!",	 10,	13,	'$'
	msg_load_start	db	"starting reading",	10,	13,	'$'
	msg_load_end	db	"finished reading",	10,	13,	'$'
	msg_load_head	db	"skipped the header",	10,	13,	'$'
	msg_load_read_start	db	"starting reading",	10,	13,	'$'
	msg_load_read	db	"finihsed loading into the buffer",10,	13,	'$'
	msg_load_open	db	"openned the file",	10,	13,	'$'
	msg_write_start	db	"starting writing",  10,	13,	'$'
	msg_write_end	db	"finished writing",  10,	13,	'$'
	msg_error_load_open	db "could not open file",	10,	13,	'$'
	msg_error_load_read	db "could not read header of file",	10,	13,	'$'
	msg_error_write_create	db	"could not create file",	10,	13,	'$'
	msg_error_write_header	db	"could not write header",	10,	13,	'$'
	msg_error_write_image	db	"could not write image",	10,	13,	'$'
	msg_error_write_close	db	"could	not close image",	10,	13,	'$'
	;	10,	13,	'$'
	fcount	dw	2
	func	dw	mean,	median

	buffer	db	100	dup('$')
	pic	db	IFSIZE	dup(2)
__data	ends

_output	segment	'data'
	cip	db	IFSIZE	dup(3)
_output	ends

_stack	segment	stack	'stack'
	dw	32000	dup('$')
_stack	ends

__code	segment	'code'

	assume	cs:__code,	ds:__data,	ss:_stack,	es:_output
main	proc

start:
	mov	ax,	__data
	mov	ds,	ax
	mov	ax,	_output
	mov	es,	ax

	call load

	mov	ah,	09h
	lea	dx,	msg_load_end
	int	21h

	mov	bx,	0
	mov	cx,	fcount

	ml5:
		mov	dx,	func[bx]
		add	bx,	2
		push	bx
		push	cx
		push	dx

		mov	cx,	area
		lea	di,	cip
		lea	si,	pic
		ml10:
			call	pwin
			call	dx

			mov	es:[di],	al
			inc	di
			inc	si

			loop	ml10

		call write
		;change name
		mov	al,	ofc
		inc	al
		mov	ofc,	al

	pop	dx
	pop	cx
	pop	bx
	mov	ax,	cx
	call	print
	loop	ml5


	;retur dos 2 style
fin:	mov	ax,	4c00h
	int	21h
main	endp

iden	proc	near
	mov	al,	window
	ret
iden	endp

;populate window
pwin	proc	near
	push	bx
	push	cx

	mov	bx,	0
	mov	cx,	wy

	win10:	push	cx
			mov	cx,	wx
		win20:
				mov	al,	[si + bx]
				mov	window[bx],	al
				inc	bx
				loop	win20
		add	bx,	len
		sub	bx,	wx
		pop	cx
		loop	win10

	pop	cx
	pop	bx

	ret
pwin	endp

sum	proc	near
	push	bx
	push	cx
	push	dx

	mov	bx,	0
	mov	ax,	0
	mov	dx,	0

	sum10:	mov	dl,	window[bx]
		add	ax,	dx
		inc	bx
		cmp	bx,	wa
		jne	sum10

	pop	dx
	pop	cx
	pop	bx

	ret
sum	endp

min	proc	near
	push	bx

	mov	al,	-1
	mov	bx,	0
	min10:
		cmp	bx,	wm
		je	mins
		cmp	al,	window[bx]
		jle	mins
		mov	al,	window[bx]
	mins:	inc	bx
		cmp	bx,	wa
		jne	min10
	pop	bx
	ret
min	endp

mean	proc	near
	push	bx
	push	dx

	call	sum
	xor	dx,	dx
	mov	bx,	wa
	div	bx

	pop	dx
	pop	bx

	ret
mean	endp

wsort	proc	near
	push	di
	push	si

	mov	di,	0
	mov	si,	0
	mov	bx,	0
	xor	ah,	ah
	mov	al,	window
	ws5:
		mov	si,	di
		ws10:	cmp	al,	window[si]
			jle	wss
			mov	al,	window[si]
			mov	bx,	si
		wss:	inc	si
			cmp	si,	wa
			jne	ws10
		mov	dl,	window[di]
		mov	window[bx],	dl
		mov	window[di],	al
		inc	di
		cmp	di,	wa
		jne	ws5

	pop	si
	pop	di

	ret
wsort	endp

median	proc	near
	call	wsort
	mov	al,	window[wm]
	ret
median	endp

write	proc	near
	push	ax
	push	bx
	push	cx
	push	dx

	mov	ah,	09h
	lea	dx,	msg_write_start
	int	21h

	;create a new file
	mov	ah,	3ch
	mov	cx,	0
	lea	dx,	ofname
	int	21h
	jb	wer10
	mov	handle,	ax
	mov	bx,	ax;handle
	;write picture
	mov	ah,	40h
	mov	cx,	IFSIZE
	lea	dx,	pic
	int	21h
	jb	wer30
	;close file
	mov	ah,	3eh
	int	21h
	jb	wer40
	mov	ah,	09h
	lea	dx,	msg_write_end
	int	21h

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

	wer10:	lea	dx,	msg_error_write_create
		jmp	write_print_error
	wer20:	lea	dx,	msg_error_write_header
		jmp	write_print_error
	wer30:lea	dx,	msg_error_write_image
		jmp	write_print_error
	wer40:lea	dx,	msg_error_write_close
		jmp	write_print_error
	write_print_error:
		call	print
		mov	ah,	09h
		int	21h
	jmp	fin
write	endp

;this loads the picture
load	proc	near
	push	ax
	push	bx
	push	cx
	push	dx

	push	di
	push	si
	; call print
	;read file
	lea	dx,	ifname
	mov	al,	0;read
	mov	ah,	3dh;
	int	21h
	jb	lerr0
	; call print
	mov	handle,	ax
	mov	bx,	ax
	mov	ah,	3fh
	mov	cx,	IFSIZE
	lea	dx,	pic
	int	21h
	jb	lerr2

	mov	ah,	09h
	lea	dx,	msg_load_read
	int	21h
	;close
	mov	bx,	handle
	mov	ah,	3eh
	int	21h
	jmp	owari
	lerr0:
		call	print
		mov	ah,	09h
		lea	dx,	msg_error_load_open
		int	21h
		jmp	fin
	lerr1:	call	print
		mov	ah,	09h
		lea	dx,	msg_error_load_read
		int	21h
		jmp	fin
	lerr2:	call	print
		mov	ah,	09h
		lea	dx,	msg_error_load_read
		lea	dx,	msg_error_load_read
		int	21h
		jmp	fin
owari:	pop	si
	pop	di

	pop	dx
	pop	cx
	pop	bx
	pop	ax

	ret
load	endp

print	proc	near;print ax
	;save registers we are going to use
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	;prepare for saving
	mov	bx,	10
	mov	di,	31
	mov	cx,	ax
	conv:	mov	dx,	0
		div	bx
		;store the remainder's character
		add	dl,	'0'
		mov	buffer[2 + di],	dl
		;fix ax to be the number it's supposed to be
		dec	di

		;end of loop condition
		cmp	ax,	0
		jne	conv

	;since di + 1 + buffer points to the beginning of the string
	;and there is a $ sign at the end we can use this
	inc	di
	lea	dx,	buffer[2 + di]
	mov	ah,	09H
	int	21h
	;restor old flags
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax

	ret
print	endp
__code	ends

end	start
