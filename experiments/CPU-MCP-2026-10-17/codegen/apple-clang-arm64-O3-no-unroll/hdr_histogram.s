_hdr_value_at_percentile:               ; @hdr_value_at_percentile
	.cfi_startproc
; %bb.0:
	ldr	x8, [x0, #88]
	cbz	x8, LBB32_25
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
	b.ge	LBB32_3
; %bb.2:
	mov	w8, #1                          ; =0x1
	b	LBB32_5
LBB32_3:
	fcmp	d1, d2
	b.ge	LBB32_5
; %bb.4:
	fcvtzs	x8, d1
LBB32_5:
	cmp	x8, #1
	csinc	x8, x8, xzr, gt
	ldr	x11, [x0, #96]
	ldr	w10, [x0, #80]
	ldr	w14, [x0, #64]
	cbnz	w14, LBB32_26
; %bb.6:
	mov	w9, #4                          ; =0x4
	sdiv	w9, w10, w9
	lsl	w12, w9, #2
	cmp	w12, #1
	b.lt	LBB32_15
; %bb.7:
	mov	x9, #0                          ; =0x0
	mov	x15, #0                         ; =0x0
	mov	x13, x11
LBB32_8:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB32_9 Depth 2
                                        ;     Child Loop BB32_13 Depth 2
	mov	x14, #0                         ; =0x0
	movi.2d	v1, #0000000000000000
LBB32_9:                                ;   Parent Loop BB32_8 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	q2, [x13, x14]
	add.2d	v1, v2, v1
	add	x14, x14, #16
	cmp	x14, #32
	b.ne	LBB32_9
; %bb.10:                               ;   in Loop: Header=BB32_8 Depth=1
	addp.2d	d1, v1
	fmov	x14, d1
	add	x14, x14, x15
	cmp	x14, x8
	b.hs	LBB32_12
LBB32_11:                               ;   in Loop: Header=BB32_8 Depth=1
	add	x9, x9, #4
	add	x13, x13, #32
	mov	x15, x14
	cmp	w12, w9
	b.gt	LBB32_8
	b	LBB32_16
LBB32_12:                               ;   in Loop: Header=BB32_8 Depth=1
	mov	x16, #0                         ; =0x0
	mov	x14, x15
LBB32_13:                               ;   Parent Loop BB32_8 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	x15, [x13, x16, lsl #3]
	add	x14, x15, x14
	cmp	x14, x8
	b.ge	LBB32_21
; %bb.14:                               ;   in Loop: Header=BB32_13 Depth=2
	add	x16, x16, #1
	cmp	x16, #4
	b.ne	LBB32_13
	b	LBB32_11
LBB32_15:
	mov	w9, #0                          ; =0x0
	mov	x14, #0                         ; =0x0
LBB32_16:
	cmp	w9, w10
	b.ge	LBB32_20
; %bb.17:
	add	x11, x11, w9, uxtw #3
LBB32_18:                               ; =>This Inner Loop Header: Depth=1
	ldr	x12, [x11], #8
	add	x14, x12, x14
	cmp	x14, x8
	b.ge	LBB32_22
; %bb.19:                               ;   in Loop: Header=BB32_18 Depth=1
	add	w9, w9, #1
	cmp	w10, w9
	b.gt	LBB32_18
LBB32_20:
	mov	x15, #0                         ; =0x0
	b	LBB32_23
LBB32_21:
	add	w9, w9, w16
LBB32_22:
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
LBB32_23:
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
	b.eq	LBB32_25
; %bb.24:
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
LBB32_25:
	mov	x0, x8
	ret
LBB32_26:
	cmp	w10, #1
	b.lt	LBB32_20
; %bb.27:
	mov	x12, #0                         ; =0x0
	mov	w9, #0                          ; =0x0
	neg	w13, w10
	neg	w14, w14
	sxtw	x14, w14
LBB32_28:                               ; =>This Inner Loop Header: Depth=1
	cmp	w14, w10
	csel	w15, wzr, w13, lt
	cmp	w14, #0
	csel	w15, w10, w15, lt
	add	x15, x14, w15, sxtw
	ldr	x15, [x11, x15, lsl #3]
	add	x12, x15, x12
	cmp	x12, x8
	b.ge	LBB32_22
; %bb.29:                               ;   in Loop: Header=BB32_28 Depth=1
	mov	x15, #0                         ; =0x0
	add	w9, w9, #1
	add	x14, x14, #1
	cmp	w10, w9
	b.ne	LBB32_28
	b	LBB32_23
	.cfi_endproc

_hdr_value_at_percentiles:              ; @hdr_value_at_percentiles
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #224
	stp	x28, x27, [sp, #128]            ; 16-byte Folded Spill
	stp	x26, x25, [sp, #144]            ; 16-byte Folded Spill
	stp	x24, x23, [sp, #160]            ; 16-byte Folded Spill
	stp	x22, x21, [sp, #176]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #192]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #208]            ; 16-byte Folded Spill
	add	x29, sp, #208
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
	mov	w8, #22                         ; =0x16
	cbz	x1, LBB33_42
; %bb.1:
	cbz	x2, LBB33_42
; %bb.2:
	ldr	x8, [x0, #88]
	cbz	x8, LBB33_43
; %bb.3:
	cbz	x3, LBB33_10
; %bb.4:
	scvtf	d0, x8
	mov	x9, #4636737291354636288        ; =0x4059000000000000
	fmov	d1, x9
	fmov	d2, #0.50000000
	fmov	d3, #1.00000000
	mov	x9, x1
	mov	x10, x2
	mov	x11, x3
	b	LBB33_7
LBB33_5:                                ;   in Loop: Header=BB33_7 Depth=1
	mov	w12, #1                         ; =0x1
LBB33_6:                                ;   in Loop: Header=BB33_7 Depth=1
	str	x12, [x10], #8
	add	x9, x9, #8
	subs	x11, x11, #1
	b.eq	LBB33_10
LBB33_7:                                ; =>This Inner Loop Header: Depth=1
	ldr	d4, [x9]
	fminnm	d4, d4, d1
	fdiv	d4, d4, d1
	fmadd	d4, d4, d0, d2
	fcmp	d4, d3
	b.lt	LBB33_5
; %bb.8:                                ;   in Loop: Header=BB33_7 Depth=1
	fcmp	d4, d0
	mov	x12, x8
	b.ge	LBB33_6
; %bb.9:                                ;   in Loop: Header=BB33_7 Depth=1
	fcvtzs	x12, d4
	b	LBB33_6
LBB33_10:
	ldr	w8, [x0, #64]
	cbnz	w8, LBB33_45
; %bb.11:
	mov	w11, #0                         ; =0x0
	mov	x9, #0                          ; =0x0
	ldr	x8, [x0, #96]
	ldr	w10, [x0, #80]
	mov	x19, #0                         ; =0x0
	cmp	w10, #8
	b.lt	LBB33_26
; %bb.12:
	cbz	x3, LBB33_26
; %bb.13:
	mov	x12, #0                         ; =0x0
	mov	x19, #0                         ; =0x0
	mov	x9, #0                          ; =0x0
	mov	w17, #8                         ; =0x8
	mov	w13, #2147483647                ; =0x7fffffff
	mov	w14, #63                        ; =0x3f
	mov	w15, #1                         ; =0x1
	mov	x16, #9223372036854775807       ; =0x7fffffffffffffff
LBB33_14:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB33_21 Depth 2
                                        ;       Child Loop BB33_23 Depth 3
	mov	x11, x17
	add	x17, x8, x12, lsl #3
	ldp	q0, q1, [x17, #32]
	ldp	q2, q3, [x17]
	add.2d	v1, v3, v1
	add.2d	v0, v2, v0
	add.2d	v0, v0, v1
	addp.2d	d0, v0
	fmov	x17, d0
	ldr	x4, [x2, x19, lsl #3]
	add	x17, x17, x9
	cmp	x17, x4
	b.ge	LBB33_18
; %bb.15:                               ;   in Loop: Header=BB33_14 Depth=1
	mov	x9, x17
LBB33_16:                               ;   in Loop: Header=BB33_14 Depth=1
	add	x17, x11, #8
	cmp	x17, x10
	b.hi	LBB33_26
; %bb.17:                               ;   in Loop: Header=BB33_14 Depth=1
	add	x12, x12, #8
	cmp	x19, x3
	b.lo	LBB33_14
	b	LBB33_26
LBB33_18:                               ;   in Loop: Header=BB33_14 Depth=1
	mov	x17, x12
	b	LBB33_21
LBB33_19:                               ;   in Loop: Header=BB33_21 Depth=2
	mov	x19, x3
LBB33_20:                               ;   in Loop: Header=BB33_21 Depth=2
	add	x17, x17, #1
	cmp	x17, x11
	b.eq	LBB33_16
LBB33_21:                               ;   Parent Loop BB33_14 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB33_23 Depth 3
	ldr	x4, [x8, x17, lsl #3]
	add	x9, x4, x9
	cmp	x19, x3
	b.lo	LBB33_23
	b	LBB33_20
LBB33_22:                               ;   in Loop: Header=BB33_23 Depth=3
	str	x4, [x2, x19, lsl #3]
	add	x19, x19, #1
	cmp	x3, x19
	b.eq	LBB33_19
LBB33_23:                               ;   Parent Loop BB33_14 Depth=1
                                        ;     Parent Loop BB33_21 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	ldr	x4, [x2, x19, lsl #3]
	cmp	x9, x4
	b.lt	LBB33_20
; %bb.24:                               ;   in Loop: Header=BB33_23 Depth=3
	ldr	d0, [x1, x19, lsl #3]
	ldp	w4, w5, [x0, #24]
	lsr	w6, w17, w4
	add	w7, w5, w13
	and	w7, w7, w17
	subs	w20, w6, #1
	csel	w20, wzr, w20, lo
	cmp	w6, #0
	csel	w5, wzr, w5, eq
	add	w5, w7, w5
	ldr	w6, [x0, #16]
	sxtw	x5, w5
	add	w6, w20, w6
	lsl	x5, x5, x6
	ldr	x6, [x0, #32]
	orr	x6, x5, x6
	clz	x6, x6
	add	w6, w4, w6
	mvn	w4, w6
	asr	x5, x5, x4
	sxtw	x7, w5
	lsl	x4, x7, x4
	fcmp	d0, #0.0
	b.eq	LBB33_22
; %bb.25:                               ;   in Loop: Header=BB33_23 Depth=3
	sub	w6, w14, w6
	ldr	w7, [x0, #40]
	cmp	w7, w5
	cinc	w5, w6, le
	lsl	x5, x15, x5
	eor	x6, x5, #0x7fffffffffffffff
	add	x5, x4, x5
	sub	x5, x5, #1
	cmp	x4, x6
	csel	x4, x16, x5, gt
	b	LBB33_22
LBB33_26:
	cmp	w11, w10
	b.ge	LBB33_36
; %bb.27:
	cmp	x19, x3
	b.hs	LBB33_36
; %bb.28:
	sxtw	x10, w10
	mov	w12, #2147483647                ; =0x7fffffff
	mov	w13, #63                        ; =0x3f
	mov	w14, #1                         ; =0x1
	mov	x15, #9223372036854775807       ; =0x7fffffffffffffff
	mov	w11, w11
LBB33_29:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB33_31 Depth 2
	ldr	x16, [x8, x11, lsl #3]
	add	x9, x16, x9
	b	LBB33_31
LBB33_30:                               ;   in Loop: Header=BB33_31 Depth=2
	str	x16, [x2, x19, lsl #3]
	add	x19, x19, #1
	cmp	x19, x3
	b.hs	LBB33_34
LBB33_31:                               ;   Parent Loop BB33_29 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	x16, [x2, x19, lsl #3]
	cmp	x9, x16
	b.lt	LBB33_34
; %bb.32:                               ;   in Loop: Header=BB33_31 Depth=2
	ldr	d0, [x1, x19, lsl #3]
	ldp	w16, w17, [x0, #24]
	lsr	w4, w11, w16
	add	w5, w17, w12
	and	w5, w5, w11
	subs	w6, w4, #1
	csel	w6, wzr, w6, lo
	cmp	w4, #0
	csel	w17, wzr, w17, eq
	add	w17, w5, w17
	ldr	w4, [x0, #16]
	sxtw	x17, w17
	add	w4, w6, w4
	lsl	x17, x17, x4
	ldr	x4, [x0, #32]
	orr	x4, x17, x4
	clz	x4, x4
	add	w4, w16, w4
	mvn	w16, w4
	asr	x17, x17, x16
	sxtw	x5, w17
	lsl	x16, x5, x16
	fcmp	d0, #0.0
	b.eq	LBB33_30
; %bb.33:                               ;   in Loop: Header=BB33_31 Depth=2
	sub	w4, w13, w4
	ldr	w5, [x0, #40]
	cmp	w5, w17
	cinc	w17, w4, le
	lsl	x17, x14, x17
	eor	x4, x17, #0x7fffffffffffffff
	add	x17, x16, x17
	sub	x17, x17, #1
	cmp	x16, x4
	csel	x16, x15, x17, gt
	b	LBB33_30
LBB33_34:                               ;   in Loop: Header=BB33_29 Depth=1
	add	x11, x11, #1
	cmp	x11, x10
	b.ge	LBB33_36
; %bb.35:                               ;   in Loop: Header=BB33_29 Depth=1
	cmp	x19, x3
	b.lo	LBB33_29
LBB33_36:
	subs	x8, x3, x19
	b.ls	LBB33_41
; %bb.37:
	lsl	x10, x19, #3
	add	x9, x2, x10
	add	x10, x1, x10
	mov	x11, #-1                        ; =0xffffffffffffffff
	b	LBB33_39
LBB33_38:                               ;   in Loop: Header=BB33_39 Depth=1
	ldr	x12, [x0, #32]
	clz	x12, x12
	ldr	w13, [x0, #24]
	ldr	w14, [x0, #40]
	cmp	w14, #1
	cset	w14, lt
	add	w12, w13, w12
	sub	w12, w14, w12
	add	w12, w12, #63
	lsl	x12, x11, x12
	mvn	x12, x12
	str	x12, [x9], #8
	add	x10, x10, #8
	subs	x8, x8, #1
	b.eq	LBB33_41
LBB33_39:                               ; =>This Inner Loop Header: Depth=1
	ldr	d0, [x10]
	fcmp	d0, #0.0
	b.ne	LBB33_38
; %bb.40:                               ;   in Loop: Header=BB33_39 Depth=1
	mov	x12, #0                         ; =0x0
	str	x12, [x9], #8
	add	x10, x10, #8
	subs	x8, x8, #1
	b.ne	LBB33_39
LBB33_41:
	mov	w8, #0                          ; =0x0
LBB33_42:
	mov	x0, x8
	ldp	x29, x30, [sp, #208]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #192]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #176]            ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #160]            ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #144]            ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #128]            ; 16-byte Folded Reload
	add	sp, sp, #224
	ret
LBB33_43:
	cbz	x3, LBB33_41
; %bb.44:
	lsl	x1, x3, #3
	mov	x0, x2
	bl	_bzero
	b	LBB33_41
LBB33_45:
	mov	x20, x1
	mov	x21, x2
	str	x0, [sp]
	mov	w8, #-1                         ; =0xffffffff
	str	w8, [sp, #8]
	mov	x22, x0
	ldr	x8, [x0, #88]
	str	x8, [sp, #16]
	movi.2d	v0, #0000000000000000
	stur	q0, [sp, #24]
	stur	q0, [sp, #40]
	stp	xzr, xzr, [sp, #72]
Lloh10:
	adrp	x8, _all_values_iter_next@PAGE
Lloh11:
	add	x8, x8, _all_values_iter_next@PAGEOFF
	str	x8, [sp, #120]
	mov	x0, sp
	mov	x23, x3
	bl	_all_values_iter_next
	mov	x3, x23
	mov	x19, #0                         ; =0x0
	cbz	x23, LBB33_55
; %bb.46:
	mov	x8, x0
	mov	x0, x22
	mov	x2, x21
	mov	x1, x20
	cbz	w8, LBB33_36
; %bb.47:
	mov	x19, #0                         ; =0x0
	mov	x24, #0                         ; =0x0
	mov	w25, #63                        ; =0x3f
	mov	w26, #1                         ; =0x1
	mov	x27, #9223372036854775807       ; =0x7fffffffffffffff
LBB33_48:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB33_50 Depth 2
	ldr	x9, [sp, #24]
	ldr	x8, [sp, #40]
	add	x24, x9, x24
	b	LBB33_50
LBB33_49:                               ;   in Loop: Header=BB33_50 Depth=2
	str	x9, [x2, x19, lsl #3]
	add	x19, x19, #1
	cmp	x19, x3
	b.hs	LBB33_53
LBB33_50:                               ;   Parent Loop BB33_48 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	x9, [x2, x19, lsl #3]
	cmp	x24, x9
	b.lt	LBB33_53
; %bb.51:                               ;   in Loop: Header=BB33_50 Depth=2
	ldr	d0, [x1, x19, lsl #3]
	ldr	x9, [x0, #32]
	orr	x9, x9, x8
	clz	x9, x9
	ldr	w10, [x0, #24]
	add	w11, w10, w9
	mvn	w9, w11
	asr	x10, x8, x9
	sxtw	x12, w10
	lsl	x9, x12, x9
	fcmp	d0, #0.0
	b.eq	LBB33_49
; %bb.52:                               ;   in Loop: Header=BB33_50 Depth=2
	sub	w11, w25, w11
	ldr	w12, [x0, #40]
	cmp	w12, w10
	cinc	w10, w11, le
	lsl	x10, x26, x10
	eor	x11, x10, #0x7fffffffffffffff
	add	x10, x9, x10
	sub	x10, x10, #1
	cmp	x9, x11
	csel	x9, x27, x10, gt
	b	LBB33_49
LBB33_53:                               ;   in Loop: Header=BB33_48 Depth=1
	ldr	x8, [sp, #120]
	mov	x0, sp
	blr	x8
	mov	x3, x23
	cmp	x19, x23
	b.hs	LBB33_55
; %bb.54:                               ;   in Loop: Header=BB33_48 Depth=1
	mov	x8, x0
	mov	x0, x22
	mov	x2, x21
	mov	x1, x20
	tbnz	w8, #0, LBB33_48
	b	LBB33_36
LBB33_55:
	mov	x0, x22
	mov	x2, x21
	mov	x1, x20
	b	LBB33_36
	.loh AdrpAdd	Lloh10, Lloh11
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
Lloh18:
	adrp	x8, _percentile_iter_next@PAGE
Lloh19:
	add	x8, x8, _percentile_iter_next@PAGEOFF
	str	x8, [x0, #120]
	ret
	.loh AdrpAdd	Lloh18, Lloh19
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
	ldr	x8, [x0, #16]
	ldr	x9, [x0, #32]
	cmp	x9, x8
	b.ge	LBB42_3
; %bb.1:
	ldr	w8, [x19, #8]
	cmn	w8, #1
	b.eq	LBB42_5
; %bb.2:
	mov	x20, #4636737291354636288       ; =0x4059000000000000
	ldr	x8, [x19]
	ldp	x10, x9, [x19, #24]
	cbnz	x10, LBB42_7
	b	LBB42_8
LBB42_3:
	ldrb	w8, [x19, #88]
	tbnz	w8, #0, LBB42_12
; %bb.4:
	mov	w20, #1                         ; =0x1
	strb	w20, [x19, #88]
	mov	x8, #4636737291354636288        ; =0x4059000000000000
	str	x8, [x19, #104]
	mov	x0, x20
	ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #48               ; 16-byte Folded Reload
	ret
LBB42_5:
	ldr	x8, [x19]
	ldr	w8, [x8, #80]
	tbnz	w8, #31, LBB42_12
; %bb.6:
	mov	x0, x19
	bl	_move_next
	mov	x20, #4636737291354636288       ; =0x4059000000000000
	ldr	x8, [x19]
	ldp	x10, x9, [x19, #24]
	cbz	x10, LBB42_8
LBB42_7:
	scvtf	d0, x9
	fmov	d1, x20
	fmul	d0, d0, d1
	ldr	d1, [x8, #88]
	scvtf	d1, d1
	fdiv	d0, d0, d1
	ldr	d8, [x19, #96]
	fcmp	d8, d0
	b.ls	LBB42_13
LBB42_8:                                ; =>This Inner Loop Header: Depth=1
	ldr	x10, [x19, #16]
	cmp	x9, x10
	b.ge	LBB42_11
; %bb.9:                                ;   in Loop: Header=BB42_8 Depth=1
	ldr	w9, [x19, #8]
	ldr	w8, [x8, #80]
	cmp	w9, w8
	b.ge	LBB42_11
; %bb.10:                               ;   in Loop: Header=BB42_8 Depth=1
	mov	x0, x19
	bl	_move_next
	ldr	x8, [x19]
	ldp	x10, x9, [x19, #24]
	cbnz	x10, LBB42_7
	b	LBB42_8
LBB42_11:
	mov	w20, #1                         ; =0x1
	mov	x0, x20
	ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #48               ; 16-byte Folded Reload
	ret
LBB42_12:
	mov	w20, #0                         ; =0x0
	mov	x0, x20
	ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #48               ; 16-byte Folded Reload
	ret
LBB42_13:
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
	mov	x8, #14831                      ; =0x39ef
	movk	x8, #65274, lsl #16
	movk	x8, #11842, lsl #32
	movk	x8, #16358, lsl #48
	fmov	d1, x8
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
	mov	x0, x20
	ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #48               ; 16-byte Folded Reload
	ret
	.cfi_endproc

_hdr_percentiles_print:                 ; @hdr_percentiles_print
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #448
	stp	d9, d8, [sp, #352]              ; 16-byte Folded Spill
	stp	x26, x25, [sp, #368]            ; 16-byte Folded Spill
	stp	x24, x23, [sp, #384]            ; 16-byte Folded Spill
	stp	x22, x21, [sp, #400]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #416]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #432]            ; 16-byte Folded Spill
	add	x29, sp, #432
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
	.cfi_offset b8, -88
	.cfi_offset b9, -96
	mov	x22, x3
	fmov	d8, d0
	mov	x21, x2
	mov	x19, x1
	mov	x20, x0
Lloh30:
	adrp	x8, ___stack_chk_guard@GOTPAGE
Lloh31:
	ldr	x8, [x8, ___stack_chk_guard@GOTPAGEOFF]
Lloh32:
	ldr	x8, [x8]
	stur	x8, [x29, #-88]
	ldr	w8, [x0, #20]
	cbz	w3, LBB49_3
; %bb.1:
	cmp	w22, #1
	b.ne	LBB49_3
; %bb.2:
Lloh33:
	adrp	x9, l_.str.6@PAGE
Lloh34:
	add	x9, x9, l_.str.6@PAGEOFF
	str	x9, [sp, #16]
Lloh35:
	adrp	x9, l_.str.5@PAGE
Lloh36:
	add	x9, x9, l_.str.5@PAGEOFF
	b	LBB49_4
LBB49_3:
Lloh37:
	adrp	x9, l_.str.8@PAGE
Lloh38:
	add	x9, x9, l_.str.8@PAGEOFF
	str	x9, [sp, #16]
Lloh39:
	adrp	x9, l_.str.7@PAGE
Lloh40:
	add	x9, x9, l_.str.7@PAGEOFF
LBB49_4:
	stp	x9, x8, [sp]
Lloh41:
	adrp	x2, l_.str.4@PAGE
Lloh42:
	add	x2, x2, l_.str.4@PAGEOFF
	sub	x0, x29, #113
	mov	w1, #25                         ; =0x19
	bl	_snprintf
	str	x20, [sp, #56]
Lloh43:
	adrp	x8, l_.str.10@PAGE
Lloh44:
	add	x8, x8, l_.str.10@PAGEOFF
	mov	w9, #-1                         ; =0xffffffff
	str	w9, [sp, #64]
Lloh45:
	adrp	x9, l_.str.9@PAGE
Lloh46:
	add	x9, x9, l_.str.9@PAGEOFF
	cmp	w22, #1
	csel	x1, x9, x8, eq
	ldr	x8, [x20, #88]
	str	x8, [sp, #72]
	movi.2d	v0, #0000000000000000
	stp	q0, q0, [sp, #80]
	stp	xzr, xzr, [sp, #128]
	strb	wzr, [sp, #144]
	str	w21, [sp, #148]
	stp	xzr, xzr, [sp, #152]
Lloh47:
	adrp	x8, _percentile_iter_next@PAGE
Lloh48:
	add	x8, x8, _percentile_iter_next@PAGEOFF
	str	x8, [sp, #176]
Lloh49:
	adrp	x8, l_.str.3@PAGE
Lloh50:
	add	x8, x8, l_.str.3@PAGEOFF
Lloh51:
	adrp	x9, l_.str.2@PAGE
Lloh52:
	add	x9, x9, l_.str.2@PAGEOFF
	stp	x9, x8, [sp, #16]
Lloh53:
	adrp	x8, l_.str.1@PAGE
Lloh54:
	add	x8, x8, l_.str.1@PAGEOFF
Lloh55:
	adrp	x9, l_.str@PAGE
Lloh56:
	add	x9, x9, l_.str@PAGEOFF
	stp	x9, x8, [sp]
	mov	x0, x19
	bl	_fprintf
	mov	w23, #5                         ; =0x5
	tbnz	w0, #31, LBB49_8
; %bb.5:
	mov	w21, #0                         ; =0x0
	mov	x24, #4636737291354636288       ; =0x4059000000000000
	fmov	d9, #1.00000000
LBB49_6:                                ; =>This Inner Loop Header: Depth=1
	ldr	x8, [sp, #176]
	add	x0, sp, #56
	blr	x8
	cbz	w0, LBB49_9
; %bb.7:                                ;   in Loop: Header=BB49_6 Depth=1
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
	sub	x1, x29, #113
	str	d2, [sp, #24]
	mov	x0, x19
	bl	_fprintf
	cmp	w0, #0
	csel	w21, w23, w21, lt
	tbz	w0, #31, LBB49_6
	b	LBB49_22
LBB49_8:
	mov	w21, #5                         ; =0x5
	b	LBB49_22
LBB49_9:
	cbnz	w22, LBB49_22
; %bb.10:
	ldr	x22, [x20, #88]
	cbz	x22, LBB49_19
; %bb.11:
	str	x20, [sp, #184]
Lloh57:
	adrp	x8, _all_values_iter_next@PAGE
Lloh58:
	add	x8, x8, _all_values_iter_next@PAGEOFF
	str	x22, [sp, #200]
	str	x8, [sp, #304]
	str	wzr, [sp, #192]
	ldr	w8, [x20, #80]
	movi	d9, #0000000000000000
	cmp	w8, #1
	b.lt	LBB49_17
; %bb.12:
	ldr	w9, [x20, #64]
	neg	w10, w9
	cmp	w8, w10
	csneg	w10, wzr, w8, gt
	cmp	w9, #0
	csel	w8, w8, w10, gt
	sub	w8, w8, w9
	sxtw	x8, w8
	cmp	w9, #0
	csel	x8, xzr, x8, eq
	ldr	x9, [x20, #96]
	ldr	x8, [x9, x8, lsl #3]
	stp	x8, x8, [sp, #208]
	ldr	w8, [x20, #24]
	ldr	x9, [x20, #32]
	clz	x9, x9
	ldr	w10, [x20, #40]
	cmp	w10, #1
	cset	w10, lt
	add	w8, w8, w9
	sub	w8, w10, w8
	add	w8, w8, #63
	mov	w9, #1                          ; =0x1
	lsl	x8, x9, x8
	sub	x9, x8, #1
	stp	xzr, x9, [sp, #224]
	add	x9, sp, #184
	asr	x8, x8, #1
	stp	xzr, x8, [sp, #240]
	stp	xzr, xzr, [x9, #72]
	cmp	x22, #1
	b.lt	LBB49_17
; %bb.13:
	mov	x23, #0                         ; =0x0
	mov	w24, #63                        ; =0x3f
	mov	w25, #1                         ; =0x1
	b	LBB49_15
LBB49_14:                               ;   in Loop: Header=BB49_15 Depth=1
	ldr	x8, [sp, #304]
	add	x0, sp, #184
	blr	x8
	cmp	w0, #0
	ccmp	x23, x22, #0, ne
	b.ge	LBB49_17
LBB49_15:                               ; =>This Inner Loop Header: Depth=1
	ldr	x8, [sp, #208]
	cbz	x8, LBB49_14
; %bb.16:                               ;   in Loop: Header=BB49_15 Depth=1
	add	x23, x8, x23
	scvtf	d0, x8
	ldr	x8, [sp, #224]
	ldr	x9, [x20, #32]
	orr	x9, x9, x8
	clz	x9, x9
	ldr	w10, [x20, #24]
	add	w9, w10, w9
	sub	w10, w24, w9
	mvn	w9, w9
	asr	x8, x8, x9
	sxtw	x8, w8
	lsl	x9, x8, x9
	ldr	w11, [x20, #40]
	cmp	w11, w8
	cinc	w8, w10, le
	lsl	x8, x25, x8
	add	x8, x9, x8, asr #1
	scvtf	d1, x8
	fmadd	d9, d0, d1, d9
	b	LBB49_14
LBB49_17:
	scvtf	d0, x22
	fdiv	d0, d9, d0
	fdiv	d9, d0, d8
	mov	x0, x20
	bl	_hdr_stddev
	ldr	x8, [x20, #56]
	fdiv	d0, d0, d8
	cbz	x8, LBB49_20
LBB49_18:
	ldr	x9, [x20, #32]
	orr	x9, x9, x8
	clz	x9, x9
	ldr	w10, [x20, #24]
	mov	w11, #63                        ; =0x3f
	add	w9, w10, w9
	sub	w10, w11, w9
	mvn	w9, w9
	asr	x8, x8, x9
	sxtw	x11, w8
	lsl	x9, x11, x9
	ldr	w8, [x20, #40]
	cmp	w8, w11
	cinc	w10, w10, le
	mov	w11, #1                         ; =0x1
	lsl	x10, x11, x10
	eor	x11, x10, #0x7fffffffffffffff
	add	x10, x9, x10
	sub	x10, x10, #1
	mov	x12, #9223372036854775807       ; =0x7fffffffffffffff
	cmp	x9, x11
	csel	x9, x12, x10, gt
	scvtf	d1, x9
	b	LBB49_21
LBB49_19:
	movi	d0, #0000000000000000
	fdiv	d9, d0, d8
	mov	x0, x20
	bl	_hdr_stddev
	ldr	x8, [x20, #56]
	fdiv	d0, d0, d8
	cbnz	x8, LBB49_18
LBB49_20:
	ldr	w8, [x20, #40]
	movi	d1, #0000000000000000
LBB49_21:
	ldr	x9, [x20, #88]
	ldr	w10, [x20, #44]
	fdiv	d1, d1, d8
	stp	x10, x8, [sp, #32]
	str	x9, [sp, #24]
	stp	d0, d1, [sp, #8]
	str	d9, [sp]
Lloh59:
	adrp	x1, _CLASSIC_FOOTER@PAGE
Lloh60:
	add	x1, x1, _CLASSIC_FOOTER@PAGEOFF
	mov	x0, x19
	bl	_fprintf
	mov	w8, #5                          ; =0x5
	cmp	w0, #0
	csel	w21, w8, w21, lt
LBB49_22:
	ldur	x8, [x29, #-88]
Lloh61:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh62:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh63:
	ldr	x9, [x9]
	cmp	x9, x8
	b.ne	LBB49_24
; %bb.23:
	mov	x0, x21
	ldp	x29, x30, [sp, #432]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #416]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #400]            ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #384]            ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #368]            ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #352]              ; 16-byte Folded Reload
	add	sp, sp, #448
	ret
LBB49_24:
	bl	___stack_chk_fail
	.loh AdrpLdrGotLdr	Lloh30, Lloh31, Lloh32
	.loh AdrpAdd	Lloh35, Lloh36
	.loh AdrpAdd	Lloh33, Lloh34
	.loh AdrpAdd	Lloh39, Lloh40
	.loh AdrpAdd	Lloh37, Lloh38
	.loh AdrpAdd	Lloh55, Lloh56
	.loh AdrpAdd	Lloh53, Lloh54
	.loh AdrpAdd	Lloh51, Lloh52
	.loh AdrpAdd	Lloh49, Lloh50
	.loh AdrpAdd	Lloh47, Lloh48
	.loh AdrpAdd	Lloh45, Lloh46
	.loh AdrpAdd	Lloh43, Lloh44
	.loh AdrpAdd	Lloh41, Lloh42
	.loh AdrpAdd	Lloh57, Lloh58
	.loh AdrpAdd	Lloh59, Lloh60
	.loh AdrpLdrGotLdr	Lloh61, Lloh62, Lloh63
	.cfi_endproc
