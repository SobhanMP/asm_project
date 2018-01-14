len	EQU	90
area	EQU	8100
IFSIZE	EQU	64800
wx	EQU	7
wy	EQU	7
wa	EQU	39
__data	segment	'data'
	
;file stuff
	handle	dw	?
	head	db	"farbfeld"
		db	0,0,0,0,0,0,0,0
	ifname	db	"C:\SL.FF", 0
	ofname	db	"C:\TEST.FF",	0

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

	obuf	db	100	dup('$')
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

	mov	cx,	area
	lea	di,	cip
	lea	si,	pic
	ml10:	call	fuck
		add	di,	8
		add	si,	8
		loop	ml10

	call write

	;retur dos 2 style
fin:	mov	ax,	4c00h
	int	21h
main	endp

fuck	proc	near
	push	ax

	mov	ax,	[si + 0]
	mov	[di + 0],	ax
	mov	ax,	[si + 2]
	mov	[di + 2],	ax
	mov	ax,	[si + 4]
	mov	[di + 4],	ax
	mov	ax,	[si + 6]
	mov	[di + 6],	ax

	pop	ax
	ret
fuck	endp

min	proc	near
	mov	bp,	sp
	push	0FFFFh
	push	0FFFFh
	push	0FFFFh
	push	0FFFFh
	mov	cx,	wy
	mov	bx,	0
	min10:	push	cx
			mov	cx,	wx
		min20:		
				mov	ax,	[si + bx]
				cmp	ax,	[bp]
				jg	s10	
				mov	[si + bx],	ax
		s10:		mov	ax,	[si + bx + 2]
				cmp	ax,	[bp]
				jg	s20	
				mov	[si + bx + 2],	ax
		s20:		mov	ax,	[si + bx + 4]
				cmp	ax,	[bp]
				jg	s30	
				mov	[si + bx + 4],	ax
		s30:		
				add	bx,	6
				loop	min20
			add	bx,	len
			sub	bx,	cx
		pop	cx
		loop	min10

	mov	ax,	[bp]
	mov	es:[di],	ax
	mov	ax,	[bp + 2]
	mov	es:[di],	ax
	mov	ax,	[bp + 4]
	mov	es:[di],	ax
	mov	ax,	[bp + 6]
	mov	es:[di],	ax
	
	sub	sp,	8
	ret
min	endp

max	proc	near
	mov	bp,	sp
	push	0
	push	0
	push	0
	push	0FFFFh
	mov	cx,	wy
	mov	bx,	0
	min10:	push	cx
			mov	cx,	wx
		min20:		
				mov	ax,	[si + bx]
				cmp	ax,	[bp]
				jl	s10	
				mov	[si + bx],	ax
		s10:		mov	ax,	[si + bx + 2]
				cmp	ax,	[bp]
				jl	s20	
				mov	[si + bx + 2],	ax
		s20:		mov	ax,	[si + bx + 4]
				cmp	ax,	[bp]
				jl	s30	
				mov	[si + bx + 4],	ax
		s30:		
				add	bx,	6
				loop	min20
			add	bx,	len
			sub	bx,	cx
		pop	cx
		loop	min10

	mov	ax,	[bp]
	mov	es:[di],	ax
	mov	ax,	[bp + 2]
	mov	es:[di],	ax
	mov	ax,	[bp + 4]
	mov	es:[di],	ax
	mov	ax,	[bp + 6]
	mov	es:[di],	ax
	
	sub	sp,	8
	ret
max	endp

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
	;write header
	mov	handle,	ax
	mov	bx,	ax;handle
	mov	cx,	16
	lea	dx,	head
	mov	ah,	40h
	int	21h
	jb	wer20
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
	;skip the header
	lea	dx,	head
	mov	cx,	16;8 farbfeld,4width,4height
	mov	ah,	3fh
	int	21h
	jb	lerr1
	; call	print
	;read
	mov	bx,	handle
	mov	ah,	3fh
	mov	cx,	IFSIZE
	lea	dx,	pic
	int	21h
	jb	lerr2
	mov	ah,	09h
	lea	dx,	msg_load_read_start
	int	21h


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
