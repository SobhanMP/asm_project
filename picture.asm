ILEN	EQU	10
ISIZE	EQU	100
DSIZE	EQU	200
NSIZE	EQU	198
IFSIZE	EQU	400
RSIZE	EQU	800
OLEN	EQU	7
OSIZE	EQU	49
__data	segment	'data'
;let's go with grey scale
;let's assume our filters use a 7 * 7 window

	counter dw 0
	count	dw	ISIZE
	pr	dw	ISIZE	dup(0)
	pg	dw	ISIZE	dup(0)
	pb	dw	ISIZE	dup(0)




	r	dw	?
	g	dw	?
	b	dw	?

	len	dw	OSIZE
	x	dw	OLEN
	y	dw	OLEN

	px	dw	ILEN
	py	dw	ILEN
;file stuff
	handle	dw	?
	head	db	"farbfeld"
		db	0,0,0,ILEN,0,0,0,ILEN
	fname	db	"C:\small_lenna.ff", 0
	aname	db	"C:\test.ff",	0
	fread	db	"finished reading yahooo!!",	 10,	13,	'$'
	;my big buffer
	mbb	db	IFSIZE	dup(?)
	obuf	db	100	dup('$')
	buffer db	32,	?,	32	dup(0), 	 10,	13,	'$'
		db	100 dup('$')

__data	ends

_stack	segment	stack	'stack'
	dw	32000	dup('$')
_stack	ends

__code	segment	'code'

	assume	cs:__code,	ds:__data,	ss:_stack
main	proc

start:
	mov	ax,	__data
	mov	ds,	ax
	mov	es,	ax;for movs


	call load
	mov	ah,	09h
	lea	dx,	fread
	int	21h



	mov	cx,	count
	lea	di,	mbb
	lea	si,	pr
	ml10:	call	fuck
		add	di,	8
		add	si,	2

		loop	ml10
	call write
	;retur dos 2 style
	mov	ax,	4c00h
	int	21h
main	endp

fuck	proc	near
	push	ax
	mov	ax,	[si + 0]
	mov	[di + 0],	ax
	mov	ax,	[si + DSIZE]
	mov	[di + 2],	ax
	mov	ax,	[si + DSIZE + DSIZE]
	mov	[di + 4],	ax
	mov	ax,	-1
	mov	[di + 6],	ax

	pop	ax
	ret
fuck	endp

write	proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	;create a new file
	mov	ah,	3ch
	mov	cx,	0
	lea	dx,	aname
	int	21h
	;write header
	mov	bx,	ax;handle
	mov	cx,	16
	lea	dx,	head
	mov	ah,	40h
	int	21h
	;write picture
	mov	ah,	40h
	mov	cx,	RSIZE
	lea	dx,	mbb
	int	21h
	;close file
	mov	ah,	3eh
	int	21h
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
write	endp

; lbuff	proc	near;start at ax
; 	push	ax
; 	push	bx
; 	push	cx
; 	push	dx

; 	push	di
; 	push	si

; 	lea	di,	ir
; 	mov	si,	ax

; 	cld

; 	mov	dl,	3;color counter

; 	buff:	mov	bx,	y;row counter
; 		buff10:
; 			mov	cx,	x
; 			rep	movsw;copy one row

; 			add	si,	px;next row in input
; 			sub	si,	x

; 			dec	bx
; 			cmp	bx,	0
; 			jne	buff10

; 		add	ax,	ISIZE
; 		mov	si,	ax

; 		dec	dl
; 		cmp	dl,	0
; 		jne	buff

; 	pop	si
; 	pop	di

; 	pop	dx
; 	pop	cx
; 	pop	bx
; 	pop	ax
; 	ret
; lbuff	endp

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
	lea	dx,	mbb
	; FIXME HANDLE OPENNING ERRORS
	;store file handle for later usage
	mov	bx,	ax
	;skipe the header
	mov	cx,	16;8 farbfeld,4width,4height
	mov	ah,	3fh
	int	21h

	lea	dx,	mbb
	;read
	mov	ah,	3fh
	mov	cx,	RSIZE
	lea	dx,	mbb
	int	21h

	mov	ah,	09h
	lea	dx,	fread
	int	21h
	lea	si,	mbb
	lea	di,	pr
	mov	cx,	ISIZE
	mov	bx,	10
	mov	ax,	0
	bread:	
		movsw;r
		add	di,	NSIZE
		movsw;g
		add	di,	NSIZE
		movsw;b
		add	si,	2;skipp alpha
		sub	di,	DSIZE
		sub	di,	DSIZE

		inc	ax
		cmp	ax,	100
		jne	nopr
			mov	ax,	cx
			call print
			mov	ax,	0
	nopr:	loop	bread
	;close file
	mov	bx,	HANDLE
	mov	ah,	3eh
	int	21h
	lea	dx,	mbb

	mov	ah,	09h
	lea	dx,	fread
	int	21h

	pop	si
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
