_hdr_value_at_percentile:               ; @hdr_value_at_percentile
	.cfi_startproc
; %bb.0:
	ldr	x8, [x0, #88]
	cbz	x8, LBB34_23
; %bb.1:
	mov	x9, #4636737291354636288        ; =0x4059000000000000
	fmov	d1, x9
	fminnm	d2, d0, d1
	fdiv	d1, d2, d1
	scvtf	d2, x8
	fmov	d3, #0.50000000
	fmadd	d1, d1, d2, d3
	fmov	d3, #1.00000000
	fcmp	d1, d3
	b.ge	LBB34_3
; %bb.2:
	mov	w8, #1                          ; =0x1
	b	LBB34_5
LBB34_3:
	fcmp	d1, d2
	b.ge	LBB34_5
; %bb.4:
	fcvtzs	x8, d1
LBB34_5:
	cmp	x8, #1
	csinc	x8, x8, xzr, gt
	ldr	x11, [x0, #96]
	ldr	w10, [x0, #80]
	ldr	w14, [x0, #64]
	cbnz	w14, LBB34_24
; %bb.6:
	mov	w9, #4                          ; =0x4
	sdiv	w9, w10, w9
	lsl	w13, w9, #2
	cmp	w13, #1
	b.lt	LBB34_13
; %bb.7:
	mov	x9, #0                          ; =0x0
	mov	x15, #0                         ; =0x0
	mov	x14, x11
LBB34_8:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB34_11 Depth 2
	add	x12, x11, x9, lsl #3
	ldp	q1, q2, [x12]
	add.2d	v1, v2, v1
	addp.2d	d1, v1
	fmov	x12, d1
	add	x12, x12, x15
	cmp	x12, x8
	b.hs	LBB34_10
LBB34_9:                                ;   in Loop: Header=BB34_8 Depth=1
	add	x9, x9, #4
	add	x14, x14, #32
	mov	x15, x12
	cmp	w13, w9
	b.gt	LBB34_8
	b	LBB34_14
LBB34_10:                               ;   in Loop: Header=BB34_8 Depth=1
	mov	x16, #0                         ; =0x0
	mov	x17, x14
	mov	x12, x15
LBB34_11:                               ;   Parent Loop BB34_8 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	x15, [x17], #8
	add	x12, x15, x12
	cmp	x12, x8
	b.ge	LBB34_19
; %bb.12:                               ;   in Loop: Header=BB34_11 Depth=2
	sub	x16, x16, #1
	cmn	x16, #4
	b.ne	LBB34_11
	b	LBB34_9
LBB34_13:
	mov	w9, #0                          ; =0x0
	mov	x12, #0                         ; =0x0
LBB34_14:
	cmp	w9, w10
	b.ge	LBB34_18
; %bb.15:
	add	x11, x11, w9, uxtw #3
LBB34_16:                               ; =>This Inner Loop Header: Depth=1
	ldr	x13, [x11], #8
	add	x12, x13, x12
	cmp	x12, x8
	b.ge	LBB34_20
; %bb.17:                               ;   in Loop: Header=BB34_16 Depth=1
	add	w9, w9, #1
	cmp	w10, w9
	b.gt	LBB34_16
LBB34_18:
	mov	x15, #0                         ; =0x0
	b	LBB34_21
LBB34_19:
	sub	w9, w9, w16
LBB34_20:
	ldp	w8, w10, [x0, #24]
	lsr	w8, w9, w8
	mov	w11, #2147483647                ; =0x7fffffff
	add	w11, w10, w11
	and	w9, w11, w9
	subs	w11, w8, #1
	csel	w11, wzr, w11, lo
	cmp	w8, #0
	csel	w8, wzr, w10, eq
	add	w8, w9, w8
	ldr	w9, [x0, #16]
	sxtw	x8, w8
	add	w9, w11, w9
	lsl	x15, x8, x9
LBB34_21:
	ldr	x8, [x0, #32]
	orr	x8, x8, x15
	clz	x8, x8
	ldr	w9, [x0, #24]
	add	w10, w9, w8
	mvn	w8, w10
	asr	x9, x15, x8
	sxtw	x11, w9
	lsl	x8, x11, x8
	fcmp	d0, #0.0
	b.eq	LBB34_23
; %bb.22:
	mov	w11, #63                        ; =0x3f
	sub	w10, w11, w10
	ldr	w11, [x0, #40]
	cmp	w11, w9
	cinc	w9, w10, le
	mov	w10, #1                         ; =0x1
	lsl	x9, x10, x9
	eor	x10, x9, #0x7fffffffffffffff
	add	x9, x8, x9
	sub	x9, x9, #1
	mov	x11, #9223372036854775807       ; =0x7fffffffffffffff
	cmp	x8, x10
	csel	x8, x11, x9, gt
LBB34_23:
	mov	x0, x8
	ret
LBB34_24:
	cmp	w10, #1
	b.lt	LBB34_18
; %bb.25:
	mov	x12, #0                         ; =0x0
	mov	w9, #0                          ; =0x0
	neg	w13, w10
	neg	w14, w14
	sxtw	x14, w14
LBB34_26:                               ; =>This Inner Loop Header: Depth=1
	cmp	w14, w10
	csel	w15, wzr, w13, lt
	cmp	w14, #0
	csel	w15, w10, w15, lt
	add	x15, x14, w15, sxtw
	ldr	x15, [x11, x15, lsl #3]
	add	x12, x15, x12
	cmp	x12, x8
	b.ge	LBB34_20
; %bb.27:                               ;   in Loop: Header=BB34_26 Depth=1
	mov	x15, #0                         ; =0x0
	add	w9, w9, #1
	add	x14, x14, #1
	cmp	w10, w9
	b.ne	LBB34_26
	b	LBB34_21
	.cfi_endproc

_hdr_value_at_percentiles:              ; @hdr_value_at_percentiles
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #240
	stp	x28, x27, [sp, #144]            ; 16-byte Folded Spill
	stp	x26, x25, [sp, #160]            ; 16-byte Folded Spill
	stp	x24, x23, [sp, #176]            ; 16-byte Folded Spill
	stp	x22, x21, [sp, #192]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #208]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #224]            ; 16-byte Folded Spill
	add	x29, sp, #224
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset w23, -56
	.cfi_offset w24, -64
	.cfi_offset w25, -72
	.cfi_offset w26, -80
	.cfi_offset w27, -88
	.cfi_offset w28, -96
	mov	x19, x0
	mov	w0, #22                         ; =0x16
	cbz	x1, LBB35_38
; %bb.1:
	mov	x20, x2
	cbz	x2, LBB35_38
; %bb.2:
	mov	x22, x3
	ldr	x8, [x19, #88]
	cbz	x8, LBB35_39
; %bb.3:
	mov	x21, x1
	cbz	x22, LBB35_10
; %bb.4:
	scvtf	d0, x8
	mov	x9, #4636737291354636288        ; =0x4059000000000000
	fmov	d1, x9
	fmov	d2, #0.50000000
	fmov	d3, #1.00000000
	mov	x9, x21
	mov	x10, x20
	mov	x11, x22
LBB35_5:                                ; =>This Inner Loop Header: Depth=1
	ldr	d4, [x9]
	fminnm	d4, d4, d1
	fdiv	d4, d4, d1
	fmadd	d4, d4, d0, d2
	fcmp	d4, d3
	b.ge	LBB35_7
; %bb.6:                                ;   in Loop: Header=BB35_5 Depth=1
	mov	w12, #1                         ; =0x1
	b	LBB35_9
LBB35_7:                                ;   in Loop: Header=BB35_5 Depth=1
	fcmp	d4, d0
	mov	x12, x8
	b.ge	LBB35_9
; %bb.8:                                ;   in Loop: Header=BB35_5 Depth=1
	fcvtzs	x12, d4
LBB35_9:                                ;   in Loop: Header=BB35_5 Depth=1
	str	x12, [x10], #8
	add	x9, x9, #8
	subs	x11, x11, #1
	b.ne	LBB35_5
LBB35_10:
	ldr	w8, [x19, #64]
	cbnz	w8, LBB35_41
; %bb.11:
	mov	w27, #0                         ; =0x0
	mov	x25, #0                         ; =0x0
	ldr	x23, [x19, #96]
	ldr	w8, [x19, #80]
	str	x8, [sp]                        ; 8-byte Folded Spill
	mov	x24, #0                         ; =0x0
	cmp	w8, #8
	b.lt	LBB35_23
; %bb.12:
	cbz	x22, LBB35_23
; %bb.13:
	mov	x28, #0                         ; =0x0
	mov	x24, #0                         ; =0x0
	mov	x25, #0                         ; =0x0
	mov	w8, #8                          ; =0x8
	mov	w26, #2147483647                ; =0x7fffffff
LBB35_14:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB35_16 Depth 2
                                        ;       Child Loop BB35_17 Depth 3
	mov	x27, x8
	add	x8, x23, x28, lsl #3
	ldp	q0, q1, [x8, #32]
	ldp	q2, q3, [x8]
	add.2d	v1, v3, v1
	add.2d	v0, v2, v0
	add.2d	v0, v0, v1
	addp.2d	d0, v0
	fmov	x8, d0
	ldr	x9, [x20, x24, lsl #3]
	add	x8, x8, x25
	cmp	x8, x9
	str	x28, [sp, #8]                   ; 8-byte Folded Spill
	b.ge	LBB35_16
; %bb.15:                               ;   in Loop: Header=BB35_14 Depth=1
	mov	x25, x8
	b	LBB35_21
LBB35_16:                               ;   Parent Loop BB35_14 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB35_17 Depth 3
	ldr	x8, [x23, x28, lsl #3]
	add	x25, x8, x25
	cmp	x24, x22
	b.hs	LBB35_20
LBB35_17:                               ;   Parent Loop BB35_14 Depth=1
                                        ;     Parent Loop BB35_16 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	ldr	x8, [x20, x24, lsl #3]
	cmp	x25, x8
	b.lt	LBB35_20
; %bb.18:                               ;   in Loop: Header=BB35_17 Depth=3
	ldr	d0, [x21, x24, lsl #3]
	ldp	w8, w9, [x19, #24]
	lsr	w8, w28, w8
	add	w10, w9, w26
	and	w10, w10, w28
	subs	w11, w8, #1
	csel	w11, wzr, w11, lo
	cmp	w8, #0
	csel	w8, wzr, w9, eq
	add	w8, w10, w8
	ldr	w9, [x19, #16]
	sxtw	x8, w8
	add	w9, w11, w9
	lsl	x1, x8, x9
	mov	x0, x19
	bl	_percentile_bound
	str	x0, [x20, x24, lsl #3]
	add	x24, x24, #1
	cmp	x22, x24
	b.ne	LBB35_17
; %bb.19:                               ;   in Loop: Header=BB35_16 Depth=2
	mov	x24, x22
LBB35_20:                               ;   in Loop: Header=BB35_16 Depth=2
	add	x28, x28, #1
	cmp	x28, x27
	b.ne	LBB35_16
LBB35_21:                               ;   in Loop: Header=BB35_14 Depth=1
	add	x8, x27, #8
	ldp	x9, x28, [sp]                   ; 16-byte Folded Reload
	cmp	x8, x9
	b.hi	LBB35_23
; %bb.22:                               ;   in Loop: Header=BB35_14 Depth=1
	add	x28, x28, #8
	cmp	x24, x22
	b.lo	LBB35_14
LBB35_23:
	ldr	x8, [sp]                        ; 8-byte Folded Reload
	cmp	w27, w8
	b.ge	LBB35_31
; %bb.24:
	cmp	x24, x22
	b.hs	LBB35_31
; %bb.25:
	ldr	x8, [sp]                        ; 8-byte Folded Reload
	sxtw	x26, w8
	mov	w28, #2147483647                ; =0x7fffffff
	mov	w27, w27
LBB35_26:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB35_27 Depth 2
	ldr	x8, [x23, x27, lsl #3]
	add	x25, x8, x25
LBB35_27:                               ;   Parent Loop BB35_26 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	x8, [x20, x24, lsl #3]
	cmp	x25, x8
	b.lt	LBB35_29
; %bb.28:                               ;   in Loop: Header=BB35_27 Depth=2
	ldr	d0, [x21, x24, lsl #3]
	ldp	w8, w9, [x19, #24]
	lsr	w8, w27, w8
	add	w10, w9, w28
	and	w10, w10, w27
	subs	w11, w8, #1
	csel	w11, wzr, w11, lo
	cmp	w8, #0
	csel	w8, wzr, w9, eq
	add	w8, w10, w8
	ldr	w9, [x19, #16]
	sxtw	x8, w8
	add	w9, w11, w9
	lsl	x1, x8, x9
	mov	x0, x19
	bl	_percentile_bound
	str	x0, [x20, x24, lsl #3]
	add	x24, x24, #1
	cmp	x24, x22
	b.lo	LBB35_27
LBB35_29:                               ;   in Loop: Header=BB35_26 Depth=1
	add	x27, x27, #1
	cmp	x27, x26
	b.ge	LBB35_31
; %bb.30:                               ;   in Loop: Header=BB35_26 Depth=1
	cmp	x24, x22
	b.lo	LBB35_26
LBB35_31:
	subs	x8, x22, x24
	b.ls	LBB35_37
; %bb.32:
	add	x9, x20, x24, lsl #3
	mov	x10, #-1                        ; =0xffffffffffffffff
	add	x11, x21, x24, lsl #3
LBB35_33:                               ; =>This Inner Loop Header: Depth=1
	ldr	d0, [x11]
	fcmp	d0, #0.0
	b.ne	LBB35_35
; %bb.34:                               ;   in Loop: Header=BB35_33 Depth=1
	mov	x12, #0                         ; =0x0
	b	LBB35_36
LBB35_35:                               ;   in Loop: Header=BB35_33 Depth=1
	ldr	x12, [x19, #32]
	clz	x12, x12
	ldr	w13, [x19, #24]
	ldr	w14, [x19, #40]
	cmp	w14, #1
	cset	w14, lt
	add	w12, w13, w12
	sub	w12, w14, w12
	add	w12, w12, #63
	lsl	x12, x10, x12
	mvn	x12, x12
LBB35_36:                               ;   in Loop: Header=BB35_33 Depth=1
	str	x12, [x9], #8
	add	x11, x11, #8
	subs	x8, x8, #1
	b.ne	LBB35_33
LBB35_37:
	mov	w0, #0                          ; =0x0
LBB35_38:
	ldp	x29, x30, [sp, #224]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #208]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #192]            ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #176]            ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #160]            ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #144]            ; 16-byte Folded Reload
	add	sp, sp, #240
	ret
LBB35_39:
	cbz	x22, LBB35_37
; %bb.40:
	lsl	x1, x22, #3
	mov	x0, x20
	bl	_bzero
	b	LBB35_37
LBB35_41:
	str	x19, [sp, #16]
	mov	w8, #-1                         ; =0xffffffff
	str	w8, [sp, #24]
	ldr	x8, [x19, #88]
	str	x8, [sp, #32]
	movi.2d	v0, #0000000000000000
	stur	q0, [sp, #40]
	stur	q0, [sp, #56]
	stp	xzr, xzr, [sp, #88]
Lloh14:
	adrp	x8, _all_values_iter_next@PAGE
Lloh15:
	add	x8, x8, _all_values_iter_next@PAGEOFF
	str	x8, [sp, #136]
	add	x0, sp, #16
	bl	_all_values_iter_next
	mov	x24, #0                         ; =0x0
	cbz	x22, LBB35_31
; %bb.42:
	cbz	w0, LBB35_31
; %bb.43:
	mov	x24, #0                         ; =0x0
	mov	x25, #0                         ; =0x0
LBB35_44:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB35_45 Depth 2
	ldr	x8, [sp, #40]
	ldr	x23, [sp, #56]
	add	x25, x8, x25
LBB35_45:                               ;   Parent Loop BB35_44 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	x8, [x20, x24, lsl #3]
	cmp	x25, x8
	b.lt	LBB35_47
; %bb.46:                               ;   in Loop: Header=BB35_45 Depth=2
	ldr	d0, [x21, x24, lsl #3]
	mov	x0, x19
	mov	x1, x23
	bl	_percentile_bound
	str	x0, [x20, x24, lsl #3]
	add	x24, x24, #1
	cmp	x24, x22
	b.lo	LBB35_45
LBB35_47:                               ;   in Loop: Header=BB35_44 Depth=1
	ldr	x8, [sp, #136]
	add	x0, sp, #16
	blr	x8
	cmp	x24, x22
	b.hs	LBB35_31
; %bb.48:                               ;   in Loop: Header=BB35_44 Depth=1
	tbnz	w0, #0, LBB35_44
	b	LBB35_31
	.loh AdrpAdd	Lloh14, Lloh15
	.cfi_endproc

_percentile_bound:                      ; @percentile_bound
	.cfi_startproc
; %bb.0:
	mov	x8, x0
	ldr	x9, [x0, #32]
	orr	x9, x9, x1
	clz	x9, x9
	ldr	w10, [x0, #24]
	add	w10, w10, w9
	mvn	w11, w10
	asr	x9, x1, x11
	sxtw	x12, w9
	lsl	x0, x12, x11
	fcmp	d0, #0.0
	b.ne	LBB36_2
; %bb.1:
	ret
LBB36_2:
	mov	w11, #63                        ; =0x3f
	sub	w10, w11, w10
	ldr	w8, [x8, #40]
	cmp	w8, w9
	cinc	w8, w10, le
	mov	w9, #1                          ; =0x1
	lsl	x8, x9, x8
	eor	x9, x8, #0x7fffffffffffffff
	add	x8, x0, x8
	sub	x8, x8, #1
	mov	x10, #9223372036854775807       ; =0x7fffffffffffffff
	cmp	x0, x9
	csel	x0, x10, x8, gt
	ret
	.cfi_endproc

_hdr_iter_percentile_init:              ; @hdr_iter_percentile_init
	.cfi_startproc
; %bb.0:
	str	x1, [x0]
	mov	w8, #-1                         ; =0xffffffff
	str	w8, [x0, #8]
	ldr	x8, [x1, #88]
	str	x8, [x0, #16]
	movi.2d	v0, #0000000000000000
	stur	q0, [x0, #40]
	stur	q0, [x0, #24]
	stp	xzr, xzr, [x0, #72]
	strb	wzr, [x0, #88]
	str	w2, [x0, #92]
	stp	xzr, xzr, [x0, #96]
Lloh22:
	adrp	x8, _percentile_iter_next@PAGE
Lloh23:
	add	x8, x8, _percentile_iter_next@PAGEOFF
	str	x8, [x0, #120]
	ret
	.loh AdrpAdd	Lloh22, Lloh23
	.cfi_endproc

_percentile_iter_next:                  ; @percentile_iter_next
	.cfi_startproc
; %bb.0:
	stp	d9, d8, [sp, #-48]!             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #16]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #32]             ; 16-byte Folded Spill
	add	x29, sp, #32
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset b8, -40
	.cfi_offset b9, -48
	mov	x19, x0
	ldr	x8, [x0, #32]
	ldr	x9, [x0, #16]
	cmp	x8, x9
	b.ge	LBB45_10
; %bb.1:
	ldr	w8, [x19, #8]
	cmn	w8, #1
	b.ne	LBB45_4
; %bb.2:
	ldr	x8, [x19]
	ldr	w8, [x8, #80]
	tbnz	w8, #31, LBB45_11
; %bb.3:
	mov	x0, x19
	bl	_move_next
LBB45_4:
	mov	x20, #4636737291354636288       ; =0x4059000000000000
LBB45_5:                                ; =>This Inner Loop Header: Depth=1
	ldr	x8, [x19]
	ldp	x10, x9, [x19, #24]
	cbz	x10, LBB45_7
; %bb.6:                                ;   in Loop: Header=BB45_5 Depth=1
	scvtf	d0, x9
	fmov	d1, x20
	fmul	d0, d0, d1
	ldr	d1, [x8, #88]
	scvtf	d1, d1
	fdiv	d0, d0, d1
	ldr	d8, [x19, #96]
	fcmp	d8, d0
	b.ls	LBB45_14
LBB45_7:                                ;   in Loop: Header=BB45_5 Depth=1
	ldr	x10, [x19, #16]
	cmp	x9, x10
	b.ge	LBB45_12
; %bb.8:                                ;   in Loop: Header=BB45_5 Depth=1
	ldr	w9, [x19, #8]
	ldr	w8, [x8, #80]
	cmp	w9, w8
	b.ge	LBB45_12
; %bb.9:                                ;   in Loop: Header=BB45_5 Depth=1
	mov	x0, x19
	bl	_move_next
	b	LBB45_5
LBB45_10:
	ldrb	w8, [x19, #88]
	tbz	w8, #0, LBB45_13
LBB45_11:
	mov	w20, #0                         ; =0x0
	b	LBB45_15
LBB45_12:
	mov	w20, #1                         ; =0x1
	b	LBB45_15
LBB45_13:
	mov	w20, #1                         ; =0x1
	strb	w20, [x19, #88]
	mov	x8, #4636737291354636288        ; =0x4059000000000000
	str	x8, [x19, #104]
	b	LBB45_15
LBB45_14:
	ldr	x9, [x19, #40]
	ldr	x10, [x8, #32]
	orr	x10, x10, x9
	clz	x10, x10
	ldr	w11, [x8, #24]
	mov	w12, #63                        ; =0x3f
	add	w10, w11, w10
	sub	w11, w12, w10
	mvn	w10, w10
	asr	x9, x9, x10
	sxtw	x9, w9
	lsl	x10, x9, x10
	ldr	w8, [x8, #40]
	cmp	w8, w9
	cinc	w8, w11, le
	mov	w20, #1                         ; =0x1
	lsl	x8, x20, x8
	eor	x9, x8, #0x7fffffffffffffff
	add	x8, x10, x8
	sub	x8, x8, #1
	mov	x11, #9223372036854775807       ; =0x7fffffffffffffff
	cmp	x10, x9
	csel	x8, x11, x8, gt
	ldr	x9, [x19, #80]
	stp	x9, x8, [x19, #72]
	str	d8, [x19, #104]
	mov	x8, #4636737291354636288        ; =0x4059000000000000
	fmov	d9, x8
	fsub	d0, d9, d8
	fdiv	d0, d9, d0
	bl	_log
Lloh24:
	adrp	x8, lCPI45_0@PAGE
Lloh25:
	ldr	d1, [x8, lCPI45_0@PAGEOFF]
	fdiv	d0, d0, d1
	fcvtzs	x8, d0
	add	x8, x8, #1
	scvtf	d0, x8
	bl	_exp2
	fcvtzs	x8, d0
	ldrsw	x9, [x19, #92]
	mul	x8, x9, x8
	scvtf	d0, x8
	fdiv	d0, d9, d0
	fadd	d0, d8, d0
	str	d0, [x19, #96]
LBB45_15:
	mov	x0, x20
	ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #48               ; 16-byte Folded Reload
	ret
	.loh AdrpLdr	Lloh24, Lloh25
	.cfi_endproc

_hdr_percentiles_print:                 ; @hdr_percentiles_print
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #336
	stp	d11, d10, [sp, #224]            ; 16-byte Folded Spill
	stp	d9, d8, [sp, #240]              ; 16-byte Folded Spill
	stp	x28, x27, [sp, #256]            ; 16-byte Folded Spill
	stp	x24, x23, [sp, #272]            ; 16-byte Folded Spill
	stp	x22, x21, [sp, #288]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #304]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #320]            ; 16-byte Folded Spill
	add	x29, sp, #320
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset w23, -56
	.cfi_offset w24, -64
	.cfi_offset w27, -72
	.cfi_offset w28, -80
	.cfi_offset b8, -88
	.cfi_offset b9, -96
	.cfi_offset b10, -104
	.cfi_offset b11, -112
	mov	x21, x3
	fmov	d8, d0
	mov	x22, x2
	mov	x19, x1
	mov	x20, x0
Lloh32:
	adrp	x8, ___stack_chk_guard@GOTPAGE
Lloh33:
	ldr	x8, [x8, ___stack_chk_guard@GOTPAGEOFF]
Lloh34:
	ldr	x8, [x8]
	stur	x8, [x29, #-104]
	ldr	w8, [x0, #20]
	cbz	w3, LBB52_3
; %bb.1:
	cmp	w21, #1
	b.ne	LBB52_3
; %bb.2:
Lloh35:
	adrp	x9, l_.str.6@PAGE
Lloh36:
	add	x9, x9, l_.str.6@PAGEOFF
	str	x9, [sp, #16]
Lloh37:
	adrp	x9, l_.str.5@PAGE
Lloh38:
	add	x9, x9, l_.str.5@PAGEOFF
	b	LBB52_4
LBB52_3:
Lloh39:
	adrp	x9, l_.str.8@PAGE
Lloh40:
	add	x9, x9, l_.str.8@PAGEOFF
	str	x9, [sp, #16]
Lloh41:
	adrp	x9, l_.str.7@PAGE
Lloh42:
	add	x9, x9, l_.str.7@PAGEOFF
LBB52_4:
	stp	x9, x8, [sp]
Lloh43:
	adrp	x2, l_.str.4@PAGE
Lloh44:
	add	x2, x2, l_.str.4@PAGEOFF
	sub	x0, x29, #129
	mov	w1, #25                         ; =0x19
	bl	_snprintf
	str	x20, [sp, #56]
Lloh45:
	adrp	x8, l_.str.10@PAGE
Lloh46:
	add	x8, x8, l_.str.10@PAGEOFF
	mov	w9, #-1                         ; =0xffffffff
	str	w9, [sp, #64]
Lloh47:
	adrp	x9, l_.str.9@PAGE
Lloh48:
	add	x9, x9, l_.str.9@PAGEOFF
	cmp	w21, #1
	csel	x1, x9, x8, eq
	ldr	x8, [x20, #88]
	str	x8, [sp, #72]
	movi.2d	v0, #0000000000000000
	stp	q0, q0, [sp, #80]
	stp	xzr, xzr, [sp, #128]
	strb	wzr, [sp, #144]
	str	w22, [sp, #148]
	stp	xzr, xzr, [sp, #152]
Lloh49:
	adrp	x8, _percentile_iter_next@PAGE
Lloh50:
	add	x8, x8, _percentile_iter_next@PAGEOFF
	str	x8, [sp, #176]
Lloh51:
	adrp	x8, l_.str.3@PAGE
Lloh52:
	add	x8, x8, l_.str.3@PAGEOFF
Lloh53:
	adrp	x9, l_.str.2@PAGE
Lloh54:
	add	x9, x9, l_.str.2@PAGEOFF
	stp	x9, x8, [sp, #16]
Lloh55:
	adrp	x8, l_.str.1@PAGE
Lloh56:
	add	x8, x8, l_.str.1@PAGEOFF
Lloh57:
	adrp	x9, l_.str@PAGE
Lloh58:
	add	x9, x9, l_.str@PAGEOFF
	stp	x9, x8, [sp]
	mov	x0, x19
	bl	_fprintf
	mov	w23, #5                         ; =0x5
	tbnz	w0, #31, LBB52_8
; %bb.5:
	mov	w22, #0                         ; =0x0
	mov	x24, #4636737291354636288       ; =0x4059000000000000
	fmov	d9, #1.00000000
LBB52_6:                                ; =>This Inner Loop Header: Depth=1
	ldr	x8, [sp, #176]
	add	x0, sp, #56
	blr	x8
	cbz	w0, LBB52_9
; %bb.7:                                ;   in Loop: Header=BB52_6 Depth=1
	ldr	d0, [sp, #104]
	ldr	d1, [sp, #160]
	scvtf	d0, d0
	fdiv	d0, d0, d8
	fmov	d2, x24
	fdiv	d1, d1, d2
	ldr	x8, [sp, #88]
	fsub	d2, d9, d1
	fdiv	d2, d9, d2
	str	x8, [sp, #16]
	stp	d0, d1, [sp]
	sub	x1, x29, #129
	str	d2, [sp, #24]
	mov	x0, x19
	bl	_fprintf
	cmp	w0, #0
	csel	w22, w23, w22, lt
	tbz	w0, #31, LBB52_6
	b	LBB52_11
LBB52_8:
	mov	w22, #5                         ; =0x5
	b	LBB52_11
LBB52_9:
	cbnz	w21, LBB52_11
; %bb.10:
	mov	x0, x20
	bl	_hdr_mean
	fdiv	d9, d0, d8
	mov	x0, x20
	bl	_hdr_stddev
	fdiv	d10, d0, d8
	mov	x0, x20
	bl	_hdr_max
	scvtf	d0, x0
	fdiv	d0, d0, d8
	ldr	x8, [x20, #88]
	ldp	w10, w9, [x20, #40]
	stp	x9, x10, [sp, #32]
	str	x8, [sp, #24]
	stp	d10, d0, [sp, #8]
	str	d9, [sp]
Lloh59:
	adrp	x1, _CLASSIC_FOOTER@PAGE
Lloh60:
	add	x1, x1, _CLASSIC_FOOTER@PAGEOFF
	mov	x0, x19
	bl	_fprintf
	mov	w8, #5                          ; =0x5
	cmp	w0, #0
	csel	w22, w8, w22, lt
LBB52_11:
	ldur	x8, [x29, #-104]
Lloh61:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh62:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh63:
	ldr	x9, [x9]
	cmp	x9, x8
	b.ne	LBB52_13
; %bb.12:
	mov	x0, x22
	ldp	x29, x30, [sp, #320]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #304]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #288]            ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #272]            ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #256]            ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #240]              ; 16-byte Folded Reload
	ldp	d11, d10, [sp, #224]            ; 16-byte Folded Reload
	add	sp, sp, #336
	ret
LBB52_13:
	bl	___stack_chk_fail
	.loh AdrpLdrGotLdr	Lloh32, Lloh33, Lloh34
	.loh AdrpAdd	Lloh37, Lloh38
	.loh AdrpAdd	Lloh35, Lloh36
	.loh AdrpAdd	Lloh41, Lloh42
	.loh AdrpAdd	Lloh39, Lloh40
	.loh AdrpAdd	Lloh57, Lloh58
	.loh AdrpAdd	Lloh55, Lloh56
	.loh AdrpAdd	Lloh53, Lloh54
	.loh AdrpAdd	Lloh51, Lloh52
	.loh AdrpAdd	Lloh49, Lloh50
	.loh AdrpAdd	Lloh47, Lloh48
	.loh AdrpAdd	Lloh45, Lloh46
	.loh AdrpAdd	Lloh43, Lloh44
	.loh AdrpAdd	Lloh59, Lloh60
	.loh AdrpLdrGotLdr	Lloh61, Lloh62, Lloh63
	.cfi_endproc
