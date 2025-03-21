;---------------------------------------------------------------------
;	Multipalette routine.
;	by Zerkman / Sector One
;	mode 2: 320x200, blitter based, displays 56 colors per scanline
;		with uniform repartition of color change positions.
;---------------------------------------------------------------------

; Copyright (c) 2012-2025 Francois Galea <fgalea at free.fr>
; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; the COPYING file or http://www.wtfpl.net/ for more details.

; Plugin header.
m2_begin:
	dc.w	320			; width
	dc.w	200			; height
	dc.w	64			; colors per scanline
	dc.w	54			; stored colors per scanline
	dc.w	160			; physical screen line size in bytes
	dc.w	189			; timer A data
	dc.w	flag_steonly+4		; STe only + 4 calls to nextshift
m2_pal:	dc.l	0			; palette address
	bra.w	m2_init
	bra.w	m2_palette_unpack
m2_tab:	bra.w	m2_timera1


; Palette unpacking.
; a0: destination unpacked palette
; a5: get_color function
; d5-d7/a4-a6 : reserved for get_color function
m2_palette_unpack:
	move	#200-1,d2		; line counter
m2_pu_newline:
	clr	(a0)+			; set color 0 to black
	moveq	#54,d1			; 56 colors per line, -2 always black
m2_pu_newcol:
	cmp	#7,d1
	bne.s	m2_pu_no48
	clr	(a0)+			; set color 48 to black
	subq	#1,d1			; next color

m2_pu_no48:
	jsr	(a5)
	move	d0,(a0)+
	dbra	d1,m2_pu_newcol

	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	dbra	d2,m2_pu_newline
	rts


; Init routine.
m2_init:
	move.b	#2,$ffff820a.w
	clr.b	$ffff8260.w

	move	#2,$ffff8a20.w		; source X increment
	move	#2,$ffff8a22.w		; source Y increment
	move	#-1,$ffff8a28.w	; Endmask 1 (first write of a line)
	move	#-1,$ffff8a2a.w	; Endmask 2 (all other writes of a line)
	move	#-1,$ffff8a2c.w	; Endmask 3 (last write of a line)
	move	#2,$ffff8a2e.w		; destination X increment
	move	#-30,$ffff8a30.w	; destination Y increment
	move	#16,$ffff8a36.w	; words per line in bit-block
	move.b	#2,$ffff8a3a.w		; halftone operation (2=source)
	move.b	#3,$ffff8a3b.w		; logical operation (3=source)
	move.b	#0,$ffff8a3d.w		; skew

	move	mch(pc),d0
	cmp	#2,d0			; Mega STE?
	bne.s	m2iste
	move	#$4e71,m2_stetm		; replace one or.l with nop to adapt to blitter timing
m2iste:
	rts

m2_timera1:
	move.l	m2_pal(pc),$ffff8a24.w	; source address register
	move.l	#$ffff8240,$ffff8a32.w	; destination address register
m2_stetm:
	rept	27
	or.l	d0,d0
	endr
	nop
	move	#200*4,$ffff8a38.w	; y count (HBL=62, LineCycles=428)
	move.b	#$c0,$ffff8a3c.w	; line number register = busy, hog bus
	rts
