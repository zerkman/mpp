;---------------------------------------------------------------------
;	Example program to display an MPP image from memory using the mppdec library
;	by Zerkman / Sector One
;---------------------------------------------------------------------

; Copyright (c) 2012-2025 Francois Galea <fgalea at free.fr>
; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; the COPYING file or http://www.wtfpl.net/ for more details.

	opt	p=68000

nlines:	equ	276
lnsize:	equ	230

	section	text

	clr.l	-(sp)
	move	#32,-(sp)	; Super
	trap	#1
	addq.l	#6,sp
	move.l	d0,-(sp)

	lea	-128(sp),sp
	move.l	sp,a0
	movem.l $ffff8240.w,d1-d7/a1
	movem.l d1-d7/a1,(a0)
	add	#32,a0
	move.l	$ffff8200.w,(a0)+
	move.b	$ffff820a.w,(a0)+
	move.b	$ffff8260.w,(a0)+
	move.l	$68.w,(a0)+
	move.l	$70.w,(a0)+
	move.l	$134.w,(a0)+
	move.b	$fffffa07.w,(a0)+
	move.b	$fffffa09.w,(a0)+
	move.b	$fffffa13.w,(a0)+
	move.b	$fffffa15.w,(a0)+
	move.b	$fffffa17.w,(a0)+

	move.l	sp,savesp

	bsr	mpp_init

; *** Decode the MPP file
	lea	imgbuf,a1
	lea	image(pc),a0
	bsr	mpp_decode

; *** Display image
	bsr	mpp_setup_img

; Main loop that just waits for a press on space bar
main_loop:
	move.b	$fffffc02.w,d0
	cmp.b	#$39,d0
	bne.s	main_loop

exit:
	move	#$2700,sr

	move.l	savesp,sp

	move.l	sp,a0
	movem.l (a0)+,d1-d7/a1
	movem.l d1-d7/a1,$ffff8240.w
	move.l	(a0)+,$ffff8200.w
	move.b	(a0)+,$ffff820a.w
	move.b	(a0)+,$ffff8260.w
	move.l	(a0)+,$68.w
	move.l	(a0)+,$70.w
	move.l	(a0)+,$134.w
	move.b	(a0)+,$fffffa07.w
	move.b	(a0)+,$fffffa09.w
	move.b	(a0)+,$fffffa13.w
	move.b	(a0)+,$fffffa15.w
	move.b	(a0)+,$fffffa17.w

	move	#$2300,sr

	lea	128(sp),sp

	move	#32,-(sp)
	trap	#1
	addq.l	#6,sp

	clr	-(sp)
	trap	#1


	include	"mppdec.s"

	section	data
image:	incbin	"image.mpp"

	section	bss
savesp:	ds.l	1
imgbuf:	ds.b	mppstrsize+2*(lnsize*nlines+254)+2*(nlines*48*2)
