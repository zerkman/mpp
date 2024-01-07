;---------------------------------------------------------------------
;	Decoder and display code for Plugin-based multipalette picture (MPP) format.
;	by Zerkman / Sector One
;---------------------------------------------------------------------

; Copyright (c) 2012-2024 Francois Galea <fgalea at free.fr>
; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; the COPYING file or http://www.wtfpl.net/ for more details.

; plugin structure entry offsets
plug_width			equ	0
plug_height			equ	2
plug_colors_per_scanline	equ	4
plug_stored_colors_per_scanline	equ	6
plug_line_size			equ	8
plug_timera_data		equ	10
plug_flags			equ	12
plug_pal_adr			equ	14
plug_init			equ	18
plug_palette_unpack		equ	22
plug_timera			equ	26

flag_steonly			equ	$1

; MPP viewer structure
	rsreset
plug	rs.l	1
picp0	rs.l	1
picp1	rs.l	1
palp0	rs.l	1
palp1	rs.l	1
dbifg	rs.b	1	; double image flag
dbpfg	rs.b	1	; double palette flag
mppstrsize	rs.b	1

; Initialize MPP viewer
mpp_init:
	bsr	get_machine_type
	move	d0,mch
	rts

; Decode a MPP file
; a0: (i) file address
; a1: (i) address of MPP stucture initialized with necessary pointers
mpp_decode:
	move.l	a0,a3		; store header address
	move.l	a0,a4		; source stream pointer
	addq.l	#8,a4
	add.l	(a4)+,a4	; extra header info, to be skipped

	moveq	#0,d0
	move.b	3(a3),d0	; mode
	add	d0,d0
	lea	plugins(pc),a6
	add	(a6,d0.w),a6	; plugin header address
	move.l	a6,plug(a1)

	move	plug_flags(a6),d0
	and	#flag_steonly,d0
	beq.s	mlvf0
	tst.b	$1fe.w		; test if STe only and machine == ST
	bne.s	mlvf0
	illegal
mlvf0:

	move.b	4(a3),d0	; flags
	moveq	#9,d5		; size of palette entry in bits
	btst	#0,d0		; STE palette ?
	beq.s	noste
	addq	#3,d5
noste:	btst	#1,d0		; extra palette bit ?
	sne	dbpfg(a1)	; dbpfg
	beq.s	noxtra
	addq	#3,d5
noxtra:

	move.l	palp0(a1),a0	; palp0
	bsr	dcpal

	move.l	picp0(a1),a0	; picp0
	bsr	dcimg

	btst	#2,4(a3)	; double image ?
	sne	dbifg(a1)	; dbifg
	beq.s	nord2n

; Read second image
	st	dbpfg(a1)	; dbpfg
	move.l	palp1(a1),a0	; palp1
	bsr	dcpal
	move.l	picp1(a1),a0	; picp1
	bsr	dcimg

nord2n:
	move	mch(pc),d0	; test if machine == ST
	bne.s	mlvnst
	btst	#2,4(a3)	; double image ?
	bne	noxtr2
	cmp	#9,d5		; 12-bit mode on ST ?
	beq	noxtr2

; Handle 12-bit (STe) mode on the ST.
	st	dbpfg(a1)	; dbpfg
	move.l	palp0(a1),a0	; palp0, source palette
	move	plug_colors_per_scanline(a6),d3
	subq	#1,d3

	move.l	palp1(a1),a2	; palp1, destination palette

	move	plug_height(a6),d1
	subq	#1,d1		; height counter
seblln:	move	d3,d2		; line color counter
sebl0:	move	(a0),d0
	move	d0,(a2)

	lsl.w	#4,d0
	moveq	#3-1,d5		; bit counter
sebl1:	rol.w	#4,d0
	moveq	#$f,d6
	and	d0,d6		; isolate component
	eor	d6,d0		; clear component
	or.b	etoe1(pc,d6),d0	; component + 1
	dbra	d5,sebl1

	btst	#0,d1		; even or odd line ?
	beq.s	sebl3
	move	d0,(a0)
	bra.s	sebl4

sebl3:	move	d0,(a2)
sebl4:	addq.l	#2,a0
	addq.l	#2,a2
	dbra	d2,sebl0
	dbra	d1,seblln

	bra.s	noxtr2


mlvnst:	btst	#1,4(a3)	; extra bit ?
	beq.s	noxtr2

; Handle extra bit palette
	move.l	palp0(a1),a0	; palp0
	move	plug_colors_per_scanline(a6),d3
	subq	#1,d3

	move.l	palp1(a1),a2	; palp1, destination palette

	move	plug_height(a6),d1
	subq	#1,d1		; height counter
exblln:	move	d3,d2		; line color counter
exbl0:	move	(a0),d0
	move	d0,(a2)
	move	d0,d4
	rol	#4,d4
	and	#7,d4		; isolate the 3 extra bits
	moveq	#3-1,d5		; bit counter
exbl1:	lsr	#1,d4		; test bit
	bcc.s	exbl2
	moveq	#$f,d6
	and	d0,d6		; isolate last component
	and	#$fff0,d0
	or.b	etoe1(pc,d6),d0	; component + 1
exbl2:	ror	#4,d0		; switch to next component
	dbra	d5,exbl1
	ror	#4,d0
	btst	#0,d1		; even or odd line ?
	beq.s	exbl3
	move	d0,(a0)
	bra.s	exbl4

; table to add 1 to STE color components
etoe1:	dc.b	8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5, 6, 7, 15

exbl3:	move	d0,(a2)
exbl4:	addq.l	#2,a0
	addq.l	#2,a2
	dbra	d2,exbl0
	dbra	d1,exblln

noxtr2:
	rts


; Generic function to get a color from a stream with variable number of bits.
; d5: number of bits to read
; d6: available bits in buffer
; d7: bit buffer
; a4: stream pointer
; d0: (o) read value
get_color:
	sub	d5,d6		; enough bits in bit buffer ?
	bpl.s	gcl_getbits

	swap	d7
	move	(a4)+,d7
	add	#16,d6

gcl_getbits:
	move.l	d7,d0
	lsr.l	d6,d0
	rts


; Decode palette from file
; d5: (io) number of bits per palette entry
; a0: (io) Pointer to destination palette block
; a3: (io) Image file header address
; a4: (io) current position in file stream
; a6: (io) Image plugin address
dcpal:
; Unpack palette
	move.l	a0,a2		; save destination block address
	moveq	#0,d7		; bit buffer
	moveq	#0,d6		; bit counter
	lea	get_color(pc),a5; color
	jsr	plug_palette_unpack(a6)

	btst	#0,4(a3)	; ste palette ?
	bne.s	nostp

; Convert 9-bit palette entries to ST format
	move.l	a0,d3		; end of decoded palette
	sub.l	a2,d3		; number of palette entries*2
	lsr.l	#1,d3		; number of palette entries
	subq	#1,d3		; palette entry counter
stplp:	move	(a2),d0
	move	d0,d1
	lsl	#2,d1
	and	#$700,d1	; red component
	move	d0,d2
	lsl	#1,d2
	and	#$070,d2	; green component
	or	d2,d1
	and	#$007,d0	; blue component
	or	d0,d1
	move	d1,(a2)+
	dbra	d3,stplp
nostp:
	rts

; Decode image data
; a0: (io) Pointer to destination image block
; a3: (io) Image file header address
; a4: (io) current position in file stream
; a6: (io) Image plugin address
dcimg:
	move	plug_line_size(a6),d4
	move	plug_width(a6),d3
	lsr	#1,d3		; source width in bytes
	sub	d3,d4		; line offset
	lsr	#1,d3
	subq	#1,d3		; words per line counter
	move	plug_height(a6),d1
	subq	#1,d1
dcil1:	move	d3,d0
dcil0:	move	(a4)+,(a0)+
	dbra	d0,dcil0
	add	d4,a0
	dbra	d1,dcil1

	rts

; Setup image for display
; a1: (io) address of MPP stucture
mpp_setup_img:
	lea	mppstr(pc),a0
	move.l	a1,(a0)

	move.l	plug(a1),a0
	move.l	palp0(a1),plug_pal_adr(a0)
	lea	tad+2(pc),a2
	move	plug_timera_data(a0),(a2)

	jsr	plug_init(a0)

	lea	mpp_hbl(pc),a0
	move.l	a0,$68.w

	lea	mpp_vbl(pc),a0		; Launch VBL
	move.l	a0,$70.w		;

	lea	mpp_timer_a(pc),a0
	move.l	a0,$134.w
	bset    #5,$fffffa07.w
	bset    #5,$fffffa13.w

	rts


mpp_vbl:
	clr.b	$fffffa19.w
tad:	move.b	#100,$fffffa1f.w
	move.b	#$4,$fffffa19.w

	clr.l	$ffff8240.w
	clr.l	$ffff8244.w
	clr.l	$ffff8248.w
	clr.l	$ffff824c.w
	clr.l	$ffff8250.w
	clr.l	$ffff8254.w
	clr.l	$ffff8258.w
	clr.l	$ffff825c.w

mpp_hbl:
	rte

mpp_timer_a:
	clr.b	$fffffa19.w
	bclr.b	#5,$fffffa0f.w
	movem.l	d0-a6,-(sp)
	move.l	mppstr(pc),a0
	move.l	plug(a0),a0
	jsr	plug_timera(a0)
	bsr	next_pic

	movem.l	(sp)+,d0-a6
	rte

next_pic:
	lea	flick(pc),a0
	move	(a0),d2
	bchg	#2,d2
	move	d2,(a0)
	move	d2,d3
	move.l	mppstr(pc),a0
	and.b	dbifg(a0),d3
	move.l	picp0(a0,d3.w),d0	; picp0 or picp1
	sub.l	#$a0,d0			; fix address to first hw line
	and.b	dbpfg(a0),d2
	move.l	palp0(a0,d2.w),d1	; palp0 or palp1

	move.l	d0,d2
	lsr	#8,d0
	move.l	d0,$ffff8200.w
	move	mch(pc),d0
	beq.s	npnste
	move.b	d2,$ffff820d.w
npnste:
	move.l	plug(a0),a0
	move.l	d1,plug_pal_adr(a0)
	rts

; Retrieve the machine type.
; d0: (o) 0:ST, 1:STe, 2:MSTe, -1:unsupported (Falcon/TT/...)
get_machine_type:
	move.l	#'_MCH',d6
	bsr	get_cookie

	cmp.l	#-1,d0		; no cookie jar or no cookie found
	beq.s	gmtst

	swap	d0
	tst	d0		; ST ?
	beq.s	gmtst
	cmp	#2,d0		; machine type
	bpl.s	gmtuns		; TT and Falcon are unsupported
	btst	#20,d0		; MSte ?
	beq.s	gmtste
	moveq	#2,d0		; MSTe
	rts
gmtste:	moveq	#1,d0		; STe
	rts
gmtst:	moveq	#0,d0		; ST
	rts
gmtuns:	moveq	#-1,d0		; unsupported
	rts

get_cookie:
	move.l	$5a0.w,d0	; _p_cookies
	beq.s	gcknf
	move.l	d0,a0
gcknx:	move.l	(a0)+,d0	; cookie name
	beq.s	gcknf
	cmp.l	d6,d0
	beq.s	gckf
	addq.l	#4,a0
	bra.s	gcknx
gckf:	move.l	(a0)+,d0	; cookie value
	rts
gcknf:	moveq	#-1,d0
	rts


plugins:
	dc.w	mode0-plugins, mode1-plugins, mode2-plugins, mode3-plugins

mode0:	include	"mode0.s"
mode1:	include	"mode1.s"
mode2:	include	"mode2.s"
mode3:	include	"mode3.s"

mch:	ds.w	1		; machine type
flick:	ds.w	1		; flick flag
mppstr:	ds.l	1		; current MPP stucture
