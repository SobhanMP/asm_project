_stack	segment	stack	'stack'
	dw	1000	dup(?)
_stack	ends

__data	segment	'data'
;let's go with grey scale
;let's assume our filters use a 7 * 7 window


	pr	dw	4096	dup(0)
	pg	dw	4096	dup(0)
	pb	dw	4096	dup(0)


	outr	dw	4096	dup(0)
	outg	dw	4096	dup(0)
	outb	dw	4096	dup(0)
	count	dw	4096

	ir	dw	49	dup(1)
	ig	dw	49	dup(1)
	ib	dw	49	dup(1)


	len	dw	49
	x	dw	7
	y	dw	7

	px	dw	64
	py	dw	64
;file stuff
	handle	dw	?
	fname	db	"C:\lenna.ff", 0
	;my big buffer
	mbb	db	8,	?,	9	dup('$')

__data	ends

__code	segment	'code'

	assume	cs:__code,	ds:__data,	ss:_stack
main	proc

start:
	mov	ax,	__data
	mov	ds,	ax
	mov	es,	ax;for movs

	lea	ax,	pr
	mov	cx,	count

	ml10:	call	lbuff
		;call	fucking_kernel
		inc	ax
		loop	ml10

		;retur dos 2 style
	mov	ax,	4c00h
	int	21h
main	endp


lbuff	proc	near;start at ax
	push	ax
	push	bx
	push	cx
	push	dx

	push	di
	push	si

	lea	di,	ir
	mov	si,	ax

	cld

	mov	dl,	4;color counter

	buff:	mov	bx,	y;row counter
		buff10:
			mov	cx,	x
			rep	movsw;copy one row

			add	si,	px;next row in input
			sub	si,	x

			dec	bx
			cmp	bx,	0
			jne	buff10

		add	ax,	4096
		mov	si,	ax

		dec	dl
		cmp	dl,	0
		jne	buff

	pop	si
	pop	di

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
lbuff	endp

;this loads the picture
load	proc	near
	push	ax
	push	bx
	push	cx
	push	dx

	push	di
	push	si
	;read file
	lea	dx,	fname
	mov	al,	0;read
	mov	ah,	3dh;
	int	21h
	; FIXME HANDLE OPENNING ERRORS
	;store file handle for later usage
	mov	bx,	ax
	;skipe the header
	mov	cx,	16;8 farbfeld,4width,4height
	mov	ah,	3fh
	int	21h
	;read
	mov	ah,	3fh
	mov	cx,	4096


	lea	di,	pr
	relo:	push	cx
		mov	cx,	8
		lea	dx,	mbb
		int	21h

		lea	si,	mbb
		movsw;r
		add	di,	4094
		movsw;g
		add	di,	4094
		movsw;b
		add	di,	4094
		movsw;a

		sub	di,	4096
		sub	di,	4096
		sub	di,	4096

		pop	cx
		loop	relo

	;close file
	mov	bx,	HANDLE
	mov	ax,	3eh
	int	21h

	pop	si
	pop	di

	pop	dx
	pop	cx
	pop	bx
	pop	ax

	ret
load	endp

__code	ends

end	start
