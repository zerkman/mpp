;---------------------------------------------------------------------
;	Multipalette routine.
;	by Zerkman / Sector One
;	mode 3: 416x276, CPU based, displays 48+6 colors per scanline
;		with overscan and non-uniform repartition of color changes.
;---------------------------------------------------------------------

; Copyright (c) 2012-2025 Francois Galea <fgalea at free.fr>
; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; the COPYING file or http://www.wtfpl.net/ for more details.

nops	macro	1
	rept	\1/2
	or.l	d0,d0
	endr
	rept	\1%2
	nop
	endr
	endm

; Plugin header.
m3_begin:
	dc.w	416			; width
	dc.w	276			; height
	dc.w	48			; colors per scanline
	dc.w	48			; stored colors per scanline
	dc.w	230			; physical screen line size in bytes
	dc.w	99 			; timer A data
	dc.w	1			; flags: 1 call to nextshift
m3_pal:	dc.l	0			; palette address
	bra.w	m3_init
	bra.w	m3_palette_unpack
m3_tab:	bra.w	m3_timera1


; Palette unpacking.
; a0: destination unpacked palette
; a5: get_color function
; d5-d7/a4-a6 : reserved for get_color function
m3_palette_unpack:
	move	#276-1,d2		; line counter
m3_pu_newline:
	moveq	#47,d1			; 48 colors per line
m3_pu_newcol:
	jsr	(a5)
	move	d0,(a0)+
	dbra	d1,m3_pu_newcol
	dbra	d2,m3_pu_newline
	rts

; Init routine.
m3_init:
	move.b	#2,$ffff820a.w
	clr.b	$ffff8260.w

	rts

m3_timera1:

; HBL=33
	move.l	a7,usp
	move.l	m3_pal(pc),a0
	lea	$ffff8240.w,a1
	lea	$ffff820a.w,a2
	lea	$ffff8260.w,a3
	lea	$ffff824c.w,a7
	moveq	#0,d0
	nops	44
	movem.l	(a0)+,d1-d5
	movem.l	d1-d5,(a7)

; Generic top border opening
	move.b	d0,(a2)	; LineCycles=488
	nops	2
	move	a2,(a2)	; LineCycles=504 - L16:16


	rept	228
	move	a3,(a3)		; LineCycles = 0 -> 8
	move.b	d0,(a3)		; LineCycles = 8 -> 16
	movem.l	(a0)+,d2-d7/a4-a5	; 19
	movem.l	d2-d7/a4-a5,(a1)	; 18
	movem.l	(a0)+,d0-d7/a4-a6	; 25
	movem.l	d0-d7,(a1)		; 18
	movem.l	a4-a6,(a1)		; 8
	moveq	#0,d0		; LineCycles = 368 -> 372
	move.b	d0,(a2)		; LineCycles = 372 -> 380
	move	a2,(a2)		; LineCycles = 380 -> 388
	movem.l	(a0)+,d1-d5	; 13
	move	a3,(a3)		; LineCycles = 440 -> 448
	nop
	move.b	d0,(a3)		; LineCycles = 452 -> 460
	movem.l	d1-d5,(a7)	; 12
	nop
	endr

	move	a3,(a3)		; LineCycles = 0 -> 8
	move.b	d0,(a3)		; LineCycles = 8 -> 16
	movem.l	(a0)+,d2-d7/a4-a5	; 19
	movem.l	d2-d7/a4-a5,(a1)	; 18
	movem.l	(a0)+,d0-d7/a4-a6	; 25
	movem.l	d0-d7,(a1)		; 18
	movem.l	a4-a6,(a1)		; 8
	moveq	#0,d0		; LineCycles = 368 -> 372
	move.b	d0,(a2)		; LineCycles = 372 -> 380
	move	a2,(a2)		; LineCycles = 380 -> 388
	movem.l	(a0)+,d1-d5	; 13
	move	a3,(a3)		; LineCycles = 440 -> 448
	nop
	move.b	d0,(a3)		; LineCycles = 452 -> 460
	move.b	d0,(a2)
	movem.l	d1-d3,(a7)	; 8
	move	a2,(a2)
	nop

	rept	44
	move	a3,(a3)		; LineCycles = 0 -> 8
	move.b	d0,(a3)		; LineCycles = 8 -> 16
	movem.l	(a0)+,d2-d7/a4-a5	; 19
	movem.l	d2-d7/a4-a5,(a1)	; 18
	movem.l	(a0)+,d0-d7/a4-a6	; 25
	movem.l	d0-d7,(a1)		; 18
	movem.l	a4-a6,(a1)		; 8
	moveq	#0,d0		; LineCycles = 368 -> 372
	move.b	d0,(a2)		; LineCycles = 372 -> 380
	move	a2,(a2)		; LineCycles = 380 -> 388
	movem.l	(a0)+,d1-d5	; 13
	move	a3,(a3)		; LineCycles = 440 -> 448
	nop
	move.b	d0,(a3)		; LineCycles = 452 -> 460
	movem.l	d1-d5,(a7)	; 12
	nop
	endr

	move	a3,(a3)		; LineCycles = 0 -> 8
	move.b	d0,(a3)		; LineCycles = 8 -> 16
	movem.l	(a0)+,d2-d7/a4-a5	; 19
	movem.l	d2-d7/a4-a5,(a1)	; 18
	movem.l	(a0)+,d0-d7/a4-a6	; 25
	movem.l	d0-d7,(a1)		; 18
	movem.l	a4-a6,(a1)		; 8
	moveq	#0,d0		; LineCycles = 368 -> 372
	move.b	d0,(a2)		; LineCycles = 372 -> 380
	move	a2,(a2)		; LineCycles = 380 -> 388
	movem.l	(a0)+,d1-d5	; 13
	move	a3,(a3)		; LineCycles = 440 -> 448
	nop
	move.b	d0,(a3)		; LineCycles = 452 -> 460
	move.b	d0,(a2)
	movem.l	d1-d3,(a7)	; 8
	move	a2,(a2)
	nop

	move	a3,(a3)		; LineCycles = 0 -> 8
	move.b	d0,(a3)		; LineCycles = 8 -> 16
	movem.l	(a0)+,d2-d7/a4-a5	; 19
	movem.l	d2-d7/a4-a5,(a1)	; 18
	movem.l	(a0)+,d0-d7/a4-a6	; 25
	movem.l	d0-d7,(a1)		; 18
	movem.l	a4-a6,(a1)		; 8
	moveq	#0,d0		; LineCycles = 368 -> 372
	move.b	d0,(a2)		; LineCycles = 372 -> 380
	move	a2,(a2)		; LineCycles = 380 -> 388
	movem.l	(a0)+,d1-d5	; 13
	move	a3,(a3)		; LineCycles = 440 -> 448
	nop
	move.b	d0,(a3)		; LineCycles = 452 -> 460
	movem.l	d1-d5,(a7)	; 12
	nop

	move	a3,(a3)		; LineCycles = 0 -> 8
	move.b	d0,(a3)		; LineCycles = 8 -> 16
	movem.l	(a0)+,d2-d7/a4-a5	; 19
	movem.l	d2-d7/a4-a5,(a1)	; 18
	movem.l	(a0)+,d0-d7/a4-a6	; 25
	movem.l	d0-d7,(a1)		; 18
	movem.l	a4-a6,(a1)		; 8
	moveq	#0,d0		; LineCycles = 368 -> 372
	move.b	d0,(a2)		; LineCycles = 372 -> 380
	move	a2,(a2)		; LineCycles = 380 -> 388
	nops	4
	rept	3
	clr.l	(a1)+
	endr
	move	a3,(a3)		; LineCycles = 440 -> 448
	nop
	move.b	d0,(a3)		; LineCycles = 452 -> 460

	rept	5
	clr.l	(a1)+
	endr

	move.l	usp,a7
	move	#$2300,sr
	rts
