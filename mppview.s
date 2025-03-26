;---------------------------------------------------------------------
;	Plugin-based multipalette picture viewer.
;	by Zerkman / Sector One
;---------------------------------------------------------------------

; Copyright (c) 2012-2025 Francois Galea <fgalea at free.fr>
; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; the COPYING file or http://www.wtfpl.net/ for more details.

dta_reserved			equ	0
dta_attrib			equ	21
dta_time			equ	22
dta_date			equ	24
dta_length			equ	26
dta_fname			equ	30

fa_rdonly			equ	$01
fa_hidden			equ	$02
fa_system			equ	$04
fa_volume			equ	$08
fa_dir				equ	$10
fa_archive			equ	$20

	text

	pea	mpp_init(pc)
	move	#38,-(sp)	; Supexec
	trap	#14
	addq.l	#6,sp
	move	mch(pc),d0	; 0:ST, 1:STe, 2:MSTe, -1:unsupported
	bmi	unsup_machine_error

	move	#47,-(sp)	; Fgetdta
	trap	#1
	addq.l	#2,sp
	move.l	d0,a6		; dta

	move.l	a6,a0
	moveq	#0,d0
	move.b	(a0)+,d0	; command line length
	beq.s	scandir		; if empty command line, scan the current dir

	clr.b	(a0,d0.w)	; zero byte at end of command line
	bsr	mpploadnview
	bra	bye

scandir:
	move	#fa_rdonly|fa_archive,-(sp)
	pea	fspec(pc)
	move	#78,-(sp)	; Fsfirst
	trap	#1
	addq.l	#8,sp

fileloop:
	tst	d0
	bne	bye

	lea	dta_fname(a6),a0
	move.l	a6,-(sp)
	bsr	mpploadnview
	move.l	(sp)+,a6

	move	#79,-(sp)	; Fsnext
	trap	#1
	addq.l	#2,sp
	bra	fileloop

bye:
	clr	-(sp)
	trap	#1

fspec:	dc.b	"*.MPP",0
	even

; Reads a MPP file and display it
; a0: (i) file name
mpploadnview:
	move.l	a0,a5		; remember the file name
	clr	-(sp)		; read mode
	move.l	a0,-(sp)
	move	#61,-(sp)	; Fopen
	trap	#1
	addq.l	#8,sp

	move	d0,d6		; file handle
	bmi	read_file_error

	lea	img,a3
	move.l	a3,-(sp)
	pea	imgbuf-img	; max read size
	move	d6,-(sp)	; file handle
	move	#63,-(sp)	; Fread
	trap	#1
	lea	12(sp),sp

	move	d6,-(sp)
	move	#62,-(sp)	; Fclose
	trap	#1
	addq.l	#4,sp

	lea	imgbuf,a1
	move.l	a3,a0
	bsr	mpp_decode
	bne	cant_view_ste_warn

; Run main loop
	pea	mainsup(pc)
	move	#38,-(sp)	; Supexec
	trap	#14
	addq.l	#6,sp

	rts


unsup_machine_error:
	lea	unsup_error_txt(pc),a0
	bsr.s	_cconws
	bra.s	end

cant_view_ste_warn:
	lea	cant_view_ste_txt1(pc),a0
	bsr.s	_cconws
	move.l	a5,a0
	bsr.s	_cconws
	lea	cant_view_ste_txt2(pc),a0
	bsr.s	_cconws
	bra.s	presskey
	rts

read_file_error:
	lea	open_error_txt1(pc),a0
	bsr.s	_cconws
	move.l	a5,a0
	bsr.s	_cconws
	lea	open_error_txt2(pc),a0
	bsr.s	_cconws

end:
	bsr.s	presskey
	clr	-(sp)
	trap	#1

presskey:
	lea	presskey_txt(pc),a0
	bsr.s	_cconws

	move.w	#7,-(sp)	; Crawcin
	trap	#1
	addq.l	#2,sp
	rts

_cconws:
	move.l	a0,-(sp)
	move	#9,-(sp)	; Cconws
	trap	#1
	addq.l	#6,sp
	rts


; Main routine, supervisor mode
mainsup:
	move.l	$462.w,d0	; _vbclock
vs:	cmp.l	$462.w,d0
	beq.s	vs

	move	#$2700,sr

; Setup VBL, timers & co.
	lea	-128(sp),sp
	move.l	sp,a0
	move.l	usp,a1
	move.l	a1,(a0)+
	cmp	#2,mch		; MSte ?
	bne.s	msnm
	move	$ffff8e20.w,(a0)+
	clr.b	$ffff8e21.w
msnm:	move.l	$ffff8200.w,(a0)+
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
	addq.l	#1,a0
	movem.l $ffff8240.w,d1-d7/a1
	movem.l d1-d7/a1,(a0)

	move.l	sp,vecptr

	lea	imgbuf,a1
	bsr	mpp_setup_img

	move	#$2300,sr

; Main loop that just waits for a press on space bar
main_loop:
	move.b	$fffffc02.w,d0
	cmp.b	#$39,d0
	bne.s	main_loop

	move	#$2700,sr
	clr.b	$fffffa19.w

	move.l	vecptr,sp

	move.l	sp,a0
	move.l	(a0)+,a1
	move.l	a1,usp
	cmp	#2,mch		; MSte ?
	bne.s	enm
	move	(a0)+,$ffff8e20.w
enm:	move.l	(a0)+,$ffff8200.w
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
	addq.l	#1,a0
	movem.l (a0)+,d1-d7/a1
	movem.l d1-d7/a1,$ffff8240.w

	move	#$2300,sr

	lea	128(sp),sp
	rts


open_error_txt1:
	dc.b	"Could not find file '",0
open_error_txt2:
	dc.b	"'.",$d,$a,0
cant_view_ste_txt1:
	dc.b	"The file '",0
cant_view_ste_txt2:
	dc.b	"' cannot be viewed (STe only).",$d,$a,0
unsup_error_txt:
	dc.b	"This program only works on ST, STe and Mega STe.",$d,$a,0
presskey_txt:
	dc.b	"Press any key.",$d,$a,0
	even

	include	"mppdec.s"

	bss
z:
vecptr:	ds.l	1
img:	ds.b	200000
imgbuf:	ds.b	mppstrsize+2*(230*276+254)+2*(276*48*2)
