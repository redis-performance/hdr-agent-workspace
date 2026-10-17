_hdr_packed_record_values:              ; @hdr_packed_record_values
	.cfi_startproc
; %bb.0:
	tbnz	x1, #63, LBB6_7
; %bb.1:
	mov	x8, x0
	mov	w0, #0                          ; =0x0
	tbnz	x2, #63, LBB6_8
; %bb.2:
	stp	x26, x25, [sp, #-80]!           ; 16-byte Folded Spill
	stp	x24, x23, [sp, #16]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #32]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #48]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #64]             ; 16-byte Folded Spill
	add	x29, sp, #64
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
	ldr	x19, [x8]
	ldr	x9, [x19, #8]
	cmp	x9, x1
	b.lt	LBB6_6
; %bb.3:
	mov	x20, x2
	mov	x22, x8
	mov	x0, x19
	mov	x21, x1
	bl	_counts_index_for
	ldr	w8, [x19, #80]
	cmp	w0, w8
	b.hs	LBB6_22
; %bb.4:
	ldr	x9, [x22, #24]
	eor	x9, x9, #0x7fffffffffffffff
	cmp	x9, x20
	b.hs	LBB6_9
; %bb.5:
	mov	w0, #0                          ; =0x0
LBB6_6:
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp], #80             ; 16-byte Folded Reload
	ret
LBB6_7:
	mov	w0, #0                          ; =0x0
LBB6_8:
	ret
LBB6_9:
	mov	x8, x22
	mov	x1, x20
	mov	x9, x21
	cbz	x20, LBB6_48
; %bb.10:
	ldr	w9, [x8, #48]
	cmp	w9, #1
	b.lt	LBB6_14
; %bb.11:
	mov	w19, #0                         ; =0x0
	ldr	x10, [x8, #8]
	mov	x11, x9
LBB6_12:                                ; =>This Inner Loop Header: Depth=1
	sub	w12, w11, w19
	add	w12, w19, w12, lsr #1
	ldr	w13, [x10, w12, uxtw #2]
	cmp	w13, w0
	csel	w11, w11, w12, lt
	csinc	w19, w19, w12, ge
	cmp	w19, w11
	b.lt	LBB6_12
; %bb.13:
	cmp	w19, w9
	b.lt	LBB6_15
	b	LBB6_20
LBB6_14:
	mov	w19, #0                         ; =0x0
	cmp	w19, w9
	b.ge	LBB6_20
LBB6_15:
	ldr	x10, [x8, #8]
	ldr	w10, [x10, w19, uxtw #2]
	cmp	w10, w0
	b.ne	LBB6_20
; %bb.16:
	mov	w23, w19
	ldr	x9, [x8, #16]
	ldrb	w11, [x8, #60]
	umull	x10, w23, w11
	cmp	w11, #4
	b.eq	LBB6_35
; %bb.17:
	cmp	w11, #2
	b.eq	LBB6_34
; %bb.18:
	cmp	w11, #1
	b.ne	LBB6_36
; %bb.19:
	ldrb	w9, [x9, x10]
	b	LBB6_37
LBB6_20:
	ldp	w11, w10, [x8, #52]
	cmp	w9, w11
	ccmp	w9, w10, #0, lt
	b.lt	LBB6_29
; %bb.21:
	cmp	w11, w10
	csel	w9, w11, w10, lt
	mov	w12, #1073741823                ; =0x3fffffff
	cmp	w9, w12
	b.le	LBB6_23
LBB6_22:
	mov	w0, #0                          ; =0x0
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp], #80             ; 16-byte Folded Reload
	ret
LBB6_23:
	lsl	w12, w9, #1
	mov	w13, #4                         ; =0x4
	cmp	w9, #0
	csel	w23, w13, w12, eq
	cmp	w11, w23
	b.ge	LBB6_26
; %bb.24:
	mov	x24, x0
	ldr	x0, [x8, #8]
	sbfiz	x1, x23, #2, #32
	bl	_realloc
	cbz	x0, LBB6_6
; %bb.25:
	mov	x8, x22
	str	x0, [x22, #8]
	str	w23, [x22, #52]
	ldr	w10, [x22, #56]
	mov	x1, x20
	mov	x0, x24
LBB6_26:
	cmp	w10, w23
	b.ge	LBB6_29
; %bb.27:
	mov	x24, x0
	ldr	x0, [x8, #16]
	ldrb	w8, [x8, #60]
	smull	x1, w8, w23
	bl	_realloc
	cbz	x0, LBB6_6
; %bb.28:
	mov	x8, x22
	str	x0, [x22, #16]
	str	w23, [x22, #56]
	mov	x1, x20
	mov	x0, x24
LBB6_29:
	mov	x23, x0
	mov	x0, x8
	bl	_widen_to_fit
	cbz	w0, LBB6_6
; %bb.30:
	ldr	x8, [x22, #8]
	add	w24, w19, #1
	add	x0, x8, w24, uxtw #2
	ubfiz	x25, x19, #2, #32
	ldr	w9, [x22, #48]
	sub	w9, w9, w19
	sbfiz	x2, x9, #2, #32
	add	x1, x8, x25
	bl	_memmove
	ldr	x8, [x22, #16]
	ldrb	w9, [x22, #60]
	umaddl	x0, w9, w24, x8
	umaddl	x1, w9, w19, x8
	ldrsw	x8, [x22, #48]
	sub	x8, x8, w19, sxtw
	mul	x2, x8, x9
	bl	_memmove
	mov	x8, x22
	ldp	x9, x10, [x22, #8]
	str	w23, [x9, x25]
	ldr	w9, [x22, #48]
	add	w9, w9, #1
	str	w9, [x22, #48]
	ldrb	w12, [x22, #60]
	umull	x11, w12, w19
	cmp	w12, #4
	b.eq	LBB6_43
; %bb.31:
	cmp	w12, #2
	mov	x9, x21
	mov	x1, x20
	b.eq	LBB6_42
; %bb.32:
	cmp	w12, #1
	b.ne	LBB6_44
; %bb.33:
	strb	w1, [x10, x11]
	b	LBB6_48
LBB6_34:
	ldrh	w9, [x9, x10]
	b	LBB6_37
LBB6_35:
	ldr	w9, [x9, x10]
	b	LBB6_37
LBB6_36:
	ldr	x9, [x9, x10]
LBB6_37:
	add	x19, x9, x1
	mov	x0, x8
	mov	x1, x19
	bl	_widen_to_fit
	cbz	w0, LBB6_6
; %bb.38:
	mov	x8, x22
	ldr	x10, [x22, #16]
	ldrb	w12, [x22, #60]
	umull	x11, w23, w12
	cmp	w12, #4
	b.eq	LBB6_46
; %bb.39:
	cmp	w12, #2
	mov	x9, x21
	mov	x1, x20
	b.eq	LBB6_45
; %bb.40:
	cmp	w12, #1
	b.ne	LBB6_47
; %bb.41:
	strb	w19, [x10, x11]
	b	LBB6_48
LBB6_42:
	strh	w1, [x10, x11]
	b	LBB6_48
LBB6_43:
	mov	x1, x20
	str	w1, [x10, x11]
	mov	x9, x21
	b	LBB6_48
LBB6_44:
	str	x1, [x10, x11]
	b	LBB6_48
LBB6_45:
	strh	w19, [x10, x11]
	b	LBB6_48
LBB6_46:
	str	w19, [x10, x11]
	mov	x9, x21
	mov	x1, x20
	b	LBB6_48
LBB6_47:
	str	x19, [x10, x11]
LBB6_48:
	ldr	x10, [x8, #24]
	add	x10, x10, x1
	str	x10, [x8, #24]
	cbz	x9, LBB6_51
; %bb.49:
	ldr	x10, [x8, #32]
	cmp	x10, x9
	b.le	LBB6_51
; %bb.50:
	str	x9, [x8, #32]
LBB6_51:
	ldr	x10, [x8, #40]
	cmp	x10, x9
	b.ge	LBB6_53
; %bb.52:
	str	x9, [x8, #40]
LBB6_53:
	mov	w0, #1                          ; =0x1
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp], #80             ; 16-byte Folded Reload
	ret
	.cfi_endproc

_hdr_packed_record_value:               ; @hdr_packed_record_value
	.cfi_startproc
; %bb.0:
	mov	w2, #1                          ; =0x1
	b	_hdr_packed_record_values
	.cfi_endproc

_hdr_packed_count_at_value:             ; @hdr_packed_count_at_value
	.cfi_startproc
; %bb.0:
	tbnz	x1, #63, LBB12_6
; %bb.1:
	stp	x20, x19, [sp, #-32]!           ; 16-byte Folded Spill
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	mov	x19, x0
	ldr	x20, [x0]
	mov	x0, x20
	bl	_counts_index_for
	ldr	w8, [x20, #80]
	cmp	w0, w8
	b.hs	LBB12_13
; %bb.2:
	ldr	w9, [x19, #48]
	cmp	w9, #1
	b.lt	LBB12_7
; %bb.3:
	mov	w8, #0                          ; =0x0
	ldr	x10, [x19, #8]
	mov	x11, x9
LBB12_4:                                ; =>This Inner Loop Header: Depth=1
	sub	w12, w11, w8
	add	w12, w8, w12, lsr #1
	ldr	w13, [x10, w12, uxtw #2]
	cmp	w13, w0
	csel	w11, w11, w12, lt
	csinc	w8, w8, w12, ge
	cmp	w8, w11
	b.lt	LBB12_4
; %bb.5:
	cmp	w8, w9
	b.ge	LBB12_13
	b	LBB12_8
LBB12_6:
	mov	x0, #0                          ; =0x0
	ret
LBB12_7:
	mov	w8, #0                          ; =0x0
	cmp	w8, w9
	b.ge	LBB12_13
LBB12_8:
	ldr	x9, [x19, #8]
	ldr	w9, [x9, w8, uxtw #2]
	cmp	w9, w0
	b.ne	LBB12_13
; %bb.9:
	mov	w9, w8
	ldr	x8, [x19, #16]
	ldrb	w10, [x19, #60]
	umull	x9, w9, w10
	cmp	w10, #4
	b.eq	LBB12_15
; %bb.10:
	cmp	w10, #2
	b.eq	LBB12_14
; %bb.11:
	cmp	w10, #1
	b.ne	LBB12_16
; %bb.12:
	ldrb	w0, [x8, x9]
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
LBB12_13:
	mov	x0, #0                          ; =0x0
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
LBB12_14:
	ldrh	w0, [x8, x9]
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
LBB12_15:
	ldr	w0, [x8, x9]
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
LBB12_16:
	ldr	x0, [x8, x9]
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
	.cfi_endproc

_hdr_packed_value_at_percentile:        ; @hdr_packed_value_at_percentile
	.cfi_startproc
; %bb.0:
	ldr	x8, [x0, #24]
	cbz	x8, LBB15_3
; %bb.1:
	stp	d9, d8, [sp, #-64]!             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #16]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #32]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #48]             ; 16-byte Folded Spill
	add	x29, sp, #48
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset b8, -56
	.cfi_offset b9, -64
	fmov	d8, d0
	ldr	x19, [x0]
	mov	x9, #4636737291354636288        ; =0x4059000000000000
	fmov	d0, x9
	fminnm	d1, d8, d0
	fdiv	d0, d1, d0
	scvtf	d1, x8
	fmov	d2, #0.50000000
	fmadd	d0, d0, d1, d2
	fmov	d2, #1.00000000
	fcmp	d0, d2
	b.ge	LBB15_4
; %bb.2:
	mov	w8, #1                          ; =0x1
	b	LBB15_6
LBB15_3:
	mov	x0, #0                          ; =0x0
	ret
LBB15_4:
	fcmp	d0, d1
	b.ge	LBB15_6
; %bb.5:
	fcvtzs	x8, d0
LBB15_6:
	ldr	w10, [x0, #48]
	ldrb	w12, [x0, #60]
	ldp	x9, x11, [x0, #8]
	cmp	w12, #4
	b.eq	LBB15_27
; %bb.7:
	cmp	w12, #2
	b.eq	LBB15_17
; %bb.8:
	cmp	w12, #1
	b.ne	LBB15_38
; %bb.9:
	negs	w12, w10
	and	w12, w12, #0xf
	and	w13, w10, #0xf
	csneg	w12, w13, w12, mi
	sub	w14, w10, w12
	cmp	w14, #1
	b.lt	LBB15_54
; %bb.10:
	mov	x13, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
LBB15_11:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_14 Depth 2
	ldr	q0, [x11, x13]
	ushll2.8h	v1, v0, #0
	ushll.4s	v2, v1, #0
	ushll.8h	v0, v0, #0
	ushll.4s	v3, v0, #0
	ushll2.4s	v1, v1, #0
	ushll2.4s	v0, v0, #0
	uaddl2.2d	v4, v0, v1
	uaddl2.2d	v5, v3, v2
	add.2d	v4, v5, v4
	uaddl.2d	v0, v0, v1
	uaddl.2d	v1, v3, v2
	add.2d	v0, v1, v0
	add.2d	v0, v0, v4
	addp.2d	d0, v0
	fmov	x15, d0
	sub	x16, x8, x12
	cmp	x15, x16
	b.ge	LBB15_13
; %bb.12:                               ;   in Loop: Header=BB15_11 Depth=1
	add	x12, x15, x12
	b	LBB15_16
LBB15_13:                               ;   in Loop: Header=BB15_11 Depth=1
	mov	x15, #0                         ; =0x0
	mov	x16, x11
LBB15_14:                               ;   Parent Loop BB15_11 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w17, [x16, x13]
	add	x12, x12, x17
	cmp	x12, x8
	b.ge	LBB15_42
; %bb.15:                               ;   in Loop: Header=BB15_14 Depth=2
	add	x16, x16, #1
	sub	x15, x15, #1
	cmn	x15, #16
	b.ne	LBB15_14
LBB15_16:                               ;   in Loop: Header=BB15_11 Depth=1
	add	x13, x13, #16
	cmp	w14, w13
	b.gt	LBB15_11
	b	LBB15_55
LBB15_17:
	negs	w12, w10
	and	w12, w12, #0xf
	and	w13, w10, #0xf
	csneg	w12, w13, w12, mi
	sub	w14, w10, w12
	cmp	w14, #1
	b.lt	LBB15_44
; %bb.18:
	mov	x13, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
	mov	x15, x11
LBB15_19:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_20 Depth 2
                                        ;     Child Loop BB15_24 Depth 2
	mov	x16, #0                         ; =0x0
	movi.2d	v0, #0000000000000000
	movi.2d	v1, #0000000000000000
	movi.2d	v2, #0000000000000000
	movi.2d	v3, #0000000000000000
LBB15_20:                               ;   Parent Loop BB15_19 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	q4, [x15, x16]
	ushll.4s	v5, v4, #0
	ushll2.4s	v4, v4, #0
	uaddw2.2d	v3, v3, v4
	uaddw.2d	v2, v2, v4
	uaddw2.2d	v1, v1, v5
	uaddw.2d	v0, v0, v5
	add	x16, x16, #16
	cmp	x16, #32
	b.ne	LBB15_20
; %bb.21:                               ;   in Loop: Header=BB15_19 Depth=1
	add.2d	v0, v0, v2
	add.2d	v1, v1, v3
	add.2d	v0, v0, v1
	addp.2d	d0, v0
	fmov	x16, d0
	sub	x17, x8, x12
	cmp	x16, x17
	b.ge	LBB15_23
; %bb.22:                               ;   in Loop: Header=BB15_19 Depth=1
	add	x12, x16, x12
	b	LBB15_26
LBB15_23:                               ;   in Loop: Header=BB15_19 Depth=1
	mov	x16, #0                         ; =0x0
LBB15_24:                               ;   Parent Loop BB15_19 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrh	w17, [x15, x16, lsl #1]
	add	x12, x12, x17
	cmp	x12, x8
	b.ge	LBB15_37
; %bb.25:                               ;   in Loop: Header=BB15_24 Depth=2
	add	x16, x16, #1
	cmp	x16, #16
	b.ne	LBB15_24
LBB15_26:                               ;   in Loop: Header=BB15_19 Depth=1
	add	x13, x13, #16
	add	x15, x15, #32
	cmp	w14, w13
	b.gt	LBB15_19
	b	LBB15_45
LBB15_27:
	negs	w12, w10
	and	w12, w12, #0xf
	and	w13, w10, #0xf
	csneg	w12, w13, w12, mi
	sub	w14, w10, w12
	cmp	w14, #1
	b.lt	LBB15_49
; %bb.28:
	mov	x13, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
	mov	x15, x11
LBB15_29:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_30 Depth 2
                                        ;     Child Loop BB15_34 Depth 2
	mov	x16, #0                         ; =0x0
	movi.2d	v0, #0000000000000000
	movi.2d	v1, #0000000000000000
LBB15_30:                               ;   Parent Loop BB15_29 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	q2, [x15, x16]
	uaddw2.2d	v1, v1, v2
	uaddw.2d	v0, v0, v2
	add	x16, x16, #16
	cmp	x16, #64
	b.ne	LBB15_30
; %bb.31:                               ;   in Loop: Header=BB15_29 Depth=1
	add.2d	v0, v0, v1
	addp.2d	d0, v0
	fmov	x16, d0
	sub	x17, x8, x12
	cmp	x16, x17
	b.ge	LBB15_33
; %bb.32:                               ;   in Loop: Header=BB15_29 Depth=1
	add	x12, x16, x12
	b	LBB15_36
LBB15_33:                               ;   in Loop: Header=BB15_29 Depth=1
	mov	x16, #0                         ; =0x0
LBB15_34:                               ;   Parent Loop BB15_29 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	w17, [x15, x16, lsl #2]
	add	x12, x12, x17
	cmp	x12, x8
	b.ge	LBB15_37
; %bb.35:                               ;   in Loop: Header=BB15_34 Depth=2
	add	x16, x16, #1
	cmp	x16, #16
	b.ne	LBB15_34
LBB15_36:                               ;   in Loop: Header=BB15_29 Depth=1
	add	x13, x13, #16
	add	x15, x15, #64
	cmp	w14, w13
	b.gt	LBB15_29
	b	LBB15_50
LBB15_37:
	add	x13, x13, x16
	b	LBB15_43
LBB15_38:
	cmp	w10, #1
	b.lt	LBB15_59
; %bb.39:
	mov	x13, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
LBB15_40:                               ; =>This Inner Loop Header: Depth=1
	ldr	x14, [x11, x13, lsl #3]
	eor	x15, x12, #0x7fffffffffffffff
	add	x12, x14, x12
	cmp	x14, x15
	ccmp	x12, x8, #0, le
	b.ge	LBB15_43
; %bb.41:                               ;   in Loop: Header=BB15_40 Depth=1
	add	x13, x13, #1
	cmp	x10, x13
	b.ne	LBB15_40
	b	LBB15_59
LBB15_42:
	sub	x13, x13, x15
LBB15_43:
	ldr	w1, [x9, x13, lsl #2]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
	b	LBB15_60
LBB15_44:
	mov	w13, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
LBB15_45:
	cmp	w13, w10
	b.ge	LBB15_59
; %bb.46:
	mov	w13, w13
LBB15_47:                               ; =>This Inner Loop Header: Depth=1
	ldrh	w14, [x11, x13, lsl #1]
	add	x12, x12, x14
	cmp	x12, x8
	b.ge	LBB15_43
; %bb.48:                               ;   in Loop: Header=BB15_47 Depth=1
	mov	x20, #0                         ; =0x0
	add	x13, x13, #1
	cmp	w10, w13
	b.gt	LBB15_47
	b	LBB15_60
LBB15_49:
	mov	w13, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
LBB15_50:
	cmp	w13, w10
	b.ge	LBB15_59
; %bb.51:
	mov	w13, w13
LBB15_52:                               ; =>This Inner Loop Header: Depth=1
	ldr	w14, [x11, x13, lsl #2]
	add	x12, x12, x14
	cmp	x12, x8
	b.ge	LBB15_43
; %bb.53:                               ;   in Loop: Header=BB15_52 Depth=1
	mov	x20, #0                         ; =0x0
	add	x13, x13, #1
	cmp	w10, w13
	b.gt	LBB15_52
	b	LBB15_60
LBB15_54:
	mov	w13, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
LBB15_55:
	cmp	w13, w10
	b.ge	LBB15_59
; %bb.56:
	mov	w13, w13
LBB15_57:                               ; =>This Inner Loop Header: Depth=1
	ldrb	w14, [x11, x13]
	add	x12, x12, x14
	cmp	x12, x8
	b.ge	LBB15_43
; %bb.58:                               ;   in Loop: Header=BB15_57 Depth=1
	mov	x20, #0                         ; =0x0
	add	x13, x13, #1
	cmp	w10, w13
	b.gt	LBB15_57
	b	LBB15_60
LBB15_59:
	mov	x20, #0                         ; =0x0
LBB15_60:
	mov	x0, x19
	mov	x1, x20
	bl	_hdr_lowest_equivalent_value
	fcmp	d8, #0.0
	b.ne	LBB15_62
; %bb.61:
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #32]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #64               ; 16-byte Folded Reload
	ret
LBB15_62:
	mov	x21, x0
	mov	x0, x19
	mov	x1, x20
	bl	_hdr_size_of_equivalent_value_range
	eor	x8, x0, #0x7fffffffffffffff
	add	x9, x21, x0
	sub	x9, x9, #1
	mov	x10, #9223372036854775807       ; =0x7fffffffffffffff
	cmp	x21, x8
	csel	x0, x10, x9, gt
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #32]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #64               ; 16-byte Folded Reload
	ret
	.cfi_endproc

_hdr_packed_value_at_percentiles:       ; @hdr_packed_value_at_percentiles
	.cfi_startproc
; %bb.0:
	stp	d9, d8, [sp, #-112]!            ; 16-byte Folded Spill
	stp	x28, x27, [sp, #16]             ; 16-byte Folded Spill
	stp	x26, x25, [sp, #32]             ; 16-byte Folded Spill
	stp	x24, x23, [sp, #48]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #64]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #80]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #96]             ; 16-byte Folded Spill
	add	x29, sp, #96
	sub	sp, sp, #864
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
	.cfi_offset b8, -104
	.cfi_offset b9, -112
	mov	x8, x0
Lloh2:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh3:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh4:
	ldr	x9, [x9]
	stur	x9, [x29, #-112]
	mov	w0, #22                         ; =0x16
	cbz	x1, LBB16_115
; %bb.1:
	cbz	x2, LBB16_115
; %bb.2:
	mov	x19, x3
	cbz	x3, LBB16_114
; %bb.3:
	ldr	x26, [x8, #24]
	cbz	x26, LBB16_7
; %bb.4:
	mov	x21, x1
	ldr	x22, [x8]
	cmp	x19, #33
	b.lo	LBB16_8
; %bb.5:
	lsr	x9, x19, #61
	cbz	x9, LBB16_43
; %bb.6:
	mov	w0, #12                         ; =0xc
	b	LBB16_115
LBB16_7:
	lsl	x1, x19, #3
	mov	x0, x2
	bl	_bzero
	b	LBB16_114
LBB16_8:
	mov	x20, x2
	mov	x27, x8
	add	x25, sp, #592
	add	x24, sp, #336
	add	x23, sp, #80
LBB16_9:
	scvtf	d0, x26
	str	q0, [sp, #48]                   ; 16-byte Folded Spill
	lsl	x1, x19, #3
	mov	x0, x24
	bl	_bzero
	cmp	x19, #1
	b.ne	LBB16_11
; %bb.10:
	mov	x8, #0                          ; =0x0
	mov	x16, x20
	ldr	q18, [sp, #48]                  ; 16-byte Folded Reload
	b	LBB16_32
LBB16_11:
	and	x8, x19, #0xfffffffffffffffe
	ldr	q18, [sp, #48]                  ; 16-byte Folded Reload
	dup.2d	v0, v18[0]
Lloh5:
	adrp	x9, lCPI16_0@PAGE
Lloh6:
	ldr	q1, [x9, lCPI16_0@PAGEOFF]
	dup.2d	v2, x26
	mov	x9, #4636737291354636288        ; =0x4059000000000000
	dup.2d	v3, x9
	fmov.2d	v4, #0.50000000
	fmov.2d	v5, #1.00000000
	mov	w9, #2                          ; =0x2
	dup.2d	v6, x9
	mov	x9, x8
	mov	x10, x23
	mov	x11, x25
	mov	x12, x21
LBB16_12:                               ; =>This Inner Loop Header: Depth=1
	ldr	q7, [x12], #16
	fminnm.2d	v7, v7, v3
	fdiv.2d	v7, v7, v3
	mov.16b	v16, v4
	fmla.2d	v16, v0, v7
	fcmge.2d	v7, v16, v5
	fcmge.2d	v17, v16, v0
	and.16b	v7, v7, v17
	fmaxnm.2d	v16, v16, v5
	fcvtzs.2d	v16, v16
	bsl.16b	v7, v2, v16
	str	q7, [x11], #16
	str	q1, [x10], #16
	add.2d	v1, v1, v6
	subs	x9, x9, #2
	b.ne	LBB16_12
; %bb.13:
	cmp	x8, x19
	mov	x16, x20
	b.ne	LBB16_32
LBB16_14:
	cmp	x19, #1
	b.ne	LBB16_38
LBB16_15:
	ldr	w10, [x27, #48]
	negs	w8, w10
	and	w8, w8, #0xf
	and	w9, w10, #0xf
	csneg	w8, w9, w8, mi
	sub	w14, w10, w8
	ldrb	w8, [x27, #60]
	ldp	x9, x11, [x27, #8]
	str	x9, [sp, #48]                   ; 8-byte Folded Spill
	cmp	w8, #1
	stp	x10, x11, [sp, #32]             ; 16-byte Folded Spill
	str	x16, [sp, #72]                  ; 8-byte Folded Spill
	b.eq	LBB16_61
; %bb.16:
	cmp	w8, #2
	b.eq	LBB16_47
; %bb.17:
	cmp	w8, #4
	b.ne	LBB16_73
; %bb.18:
	ldr	x8, [x23]
	ldr	x8, [x25, x8, lsl #3]
	cmp	w14, #1
	b.lt	LBB16_87
; %bb.19:
	mov	x13, #0                         ; =0x0
	mov	x27, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
	add	x20, x23, #8
	mov	x28, x11
	str	w14, [sp, #24]                  ; 4-byte Folded Spill
LBB16_20:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_21 Depth 2
                                        ;     Child Loop BB16_26 Depth 2
                                        ;       Child Loop BB16_29 Depth 3
	mov	x9, #0                          ; =0x0
	movi.2d	v0, #0000000000000000
	movi.2d	v1, #0000000000000000
LBB16_21:                               ;   Parent Loop BB16_20 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	q2, [x28, x9]
	uaddw2.2d	v1, v1, v2
	uaddw.2d	v0, v0, v2
	add	x9, x9, #16
	cmp	x9, #64
	b.ne	LBB16_21
; %bb.22:                               ;   in Loop: Header=BB16_20 Depth=1
	add.2d	v0, v0, v1
	addp.2d	d0, v0
	fmov	x9, d0
	add	x9, x9, x12
	cmp	x9, x8
	b.ge	LBB16_25
; %bb.23:                               ;   in Loop: Header=BB16_20 Depth=1
	mov	x12, x9
	mov	x26, x27
LBB16_24:                               ;   in Loop: Header=BB16_20 Depth=1
	add	x13, x13, #16
	add	x28, x28, #64
	mov	x27, x26
	cmp	w14, w13
	b.gt	LBB16_20
	b	LBB16_88
LBB16_25:                               ;   in Loop: Header=BB16_20 Depth=1
	mov	x16, #0                         ; =0x0
	str	x13, [sp, #8]                   ; 8-byte Folded Spill
LBB16_26:                               ;   Parent Loop BB16_20 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB16_29 Depth 3
	orr	x9, x16, x13
	ldr	w10, [x11, x9, lsl #2]
	add	x12, x12, x10
	cmp	x12, x8
	b.ge	LBB16_28
; %bb.27:                               ;   in Loop: Header=BB16_26 Depth=2
	mov	x26, x27
	add	x16, x16, #1
	cmp	x16, #16
	b.ne	LBB16_26
	b	LBB16_24
LBB16_28:                               ;   in Loop: Header=BB16_26 Depth=2
	str	x16, [sp, #16]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x9, lsl #2]
	mov	x0, x22
	mov	x26, x12
	bl	_hdr_value_at_index
	mov	x12, x26
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x9, [x23, x27, lsl #3]
LBB16_29:                               ;   Parent Loop BB16_20 Depth=1
                                        ;     Parent Loop BB16_26 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	str	x0, [x24, x9, lsl #3]
	add	x26, x27, #1
	cmp	x26, x19
	b.hs	LBB16_108
; %bb.30:                               ;   in Loop: Header=BB16_29 Depth=3
	ldr	x9, [x20, x27, lsl #3]
	ldr	x8, [x25, x9, lsl #3]
	mov	x27, x26
	cmp	x12, x8
	b.ge	LBB16_29
; %bb.31:                               ;   in Loop: Header=BB16_26 Depth=2
	mov	x27, x26
	ldr	w14, [sp, #24]                  ; 4-byte Folded Reload
	ldp	x13, x16, [sp, #8]              ; 16-byte Folded Reload
	add	x16, x16, #1
	cmp	x16, #16
	b.ne	LBB16_26
	b	LBB16_24
LBB16_32:
	mov	x9, #4636737291354636288        ; =0x4059000000000000
	fmov	d0, x9
	fmov	d1, #0.50000000
	fmov	d2, #1.00000000
	b	LBB16_35
LBB16_33:                               ;   in Loop: Header=BB16_35 Depth=1
	mov	w9, #1                          ; =0x1
LBB16_34:                               ;   in Loop: Header=BB16_35 Depth=1
	str	x9, [x25, x8, lsl #3]
	str	x8, [x23, x8, lsl #3]
	add	x8, x8, #1
	cmp	x19, x8
	b.eq	LBB16_14
LBB16_35:                               ; =>This Inner Loop Header: Depth=1
	ldr	d3, [x21, x8, lsl #3]
	fminnm	d3, d3, d0
	fdiv	d3, d3, d0
	fmadd	d3, d3, d18, d1
	fcmp	d3, d2
	b.lt	LBB16_33
; %bb.36:                               ;   in Loop: Header=BB16_35 Depth=1
	fcmp	d3, d18
	mov	x9, x26
	b.ge	LBB16_34
; %bb.37:                               ;   in Loop: Header=BB16_35 Depth=1
	fcvtzs	x9, d3
	b	LBB16_34
LBB16_38:
	add	x8, x23, #8
	mov	w9, #1                          ; =0x1
	b	LBB16_40
LBB16_39:                               ;   in Loop: Header=BB16_40 Depth=1
	str	x10, [x23, x11, lsl #3]
	add	x9, x9, #1
	add	x8, x8, #8
	cmp	x9, x19
	b.eq	LBB16_15
LBB16_40:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_41 Depth 2
	ldr	x10, [x23, x9, lsl #3]
	ldr	x12, [x25, x10, lsl #3]
	mov	x13, x8
	mov	x11, x9
LBB16_41:                               ;   Parent Loop BB16_40 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldur	x14, [x13, #-8]
	ldr	x15, [x25, x14, lsl #3]
	cmp	x15, x12
	b.le	LBB16_39
; %bb.42:                               ;   in Loop: Header=BB16_41 Depth=2
	str	x14, [x13], #-8
	sub	x11, x11, #1
	cbnz	x11, LBB16_41
	b	LBB16_39
LBB16_43:
	mov	x20, x2
	mov	x27, x8
	lsl	x23, x19, #3
	mov	x0, x23
	bl	_malloc
	mov	x25, x0
	mov	x0, x23
	bl	_malloc
	mov	x24, x0
	mov	x0, x23
	bl	_malloc
	mov	x23, x0
	cbz	x25, LBB16_46
; %bb.44:
	cbz	x24, LBB16_46
; %bb.45:
	cbnz	x23, LBB16_9
LBB16_46:
	mov	x0, x25
	bl	_free
	mov	x0, x24
	bl	_free
	mov	x0, x23
	bl	_free
	mov	w0, #12                         ; =0xc
	b	LBB16_115
LBB16_47:
	ldr	x8, [x23]
	ldr	x8, [x25, x8, lsl #3]
	cmp	w14, #1
	b.lt	LBB16_81
; %bb.48:
	mov	x13, #0                         ; =0x0
	mov	x27, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
	add	x20, x23, #8
	mov	x28, x11
	str	w14, [sp, #24]                  ; 4-byte Folded Spill
LBB16_49:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_50 Depth 2
                                        ;     Child Loop BB16_55 Depth 2
                                        ;       Child Loop BB16_58 Depth 3
	mov	x9, #0                          ; =0x0
	movi.2d	v0, #0000000000000000
	movi.2d	v1, #0000000000000000
	movi.2d	v2, #0000000000000000
	movi.2d	v3, #0000000000000000
LBB16_50:                               ;   Parent Loop BB16_49 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	q4, [x28, x9]
	ushll.4s	v5, v4, #0
	ushll2.4s	v4, v4, #0
	uaddw2.2d	v3, v3, v4
	uaddw.2d	v2, v2, v4
	uaddw2.2d	v1, v1, v5
	uaddw.2d	v0, v0, v5
	add	x9, x9, #16
	cmp	x9, #32
	b.ne	LBB16_50
; %bb.51:                               ;   in Loop: Header=BB16_49 Depth=1
	add.2d	v0, v0, v2
	add.2d	v1, v1, v3
	add.2d	v0, v0, v1
	addp.2d	d0, v0
	fmov	x9, d0
	add	x9, x9, x12
	cmp	x9, x8
	b.ge	LBB16_54
; %bb.52:                               ;   in Loop: Header=BB16_49 Depth=1
	mov	x12, x9
	mov	x26, x27
LBB16_53:                               ;   in Loop: Header=BB16_49 Depth=1
	add	x13, x13, #16
	add	x28, x28, #32
	mov	x27, x26
	cmp	w14, w13
	b.gt	LBB16_49
	b	LBB16_82
LBB16_54:                               ;   in Loop: Header=BB16_49 Depth=1
	mov	x16, #0                         ; =0x0
	str	x13, [sp, #8]                   ; 8-byte Folded Spill
LBB16_55:                               ;   Parent Loop BB16_49 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB16_58 Depth 3
	orr	x9, x16, x13
	ldrh	w10, [x11, x9, lsl #1]
	add	x12, x12, x10
	cmp	x12, x8
	b.ge	LBB16_57
; %bb.56:                               ;   in Loop: Header=BB16_55 Depth=2
	mov	x26, x27
	add	x16, x16, #1
	cmp	x16, #16
	b.ne	LBB16_55
	b	LBB16_53
LBB16_57:                               ;   in Loop: Header=BB16_55 Depth=2
	str	x16, [sp, #16]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x9, lsl #2]
	mov	x0, x22
	mov	x26, x12
	bl	_hdr_value_at_index
	mov	x12, x26
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x9, [x23, x27, lsl #3]
LBB16_58:                               ;   Parent Loop BB16_49 Depth=1
                                        ;     Parent Loop BB16_55 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	str	x0, [x24, x9, lsl #3]
	add	x26, x27, #1
	cmp	x26, x19
	b.hs	LBB16_108
; %bb.59:                               ;   in Loop: Header=BB16_58 Depth=3
	ldr	x9, [x20, x27, lsl #3]
	ldr	x8, [x25, x9, lsl #3]
	mov	x27, x26
	cmp	x12, x8
	b.ge	LBB16_58
; %bb.60:                               ;   in Loop: Header=BB16_55 Depth=2
	mov	x27, x26
	ldp	x13, x16, [sp, #8]              ; 16-byte Folded Reload
	ldr	w14, [sp, #24]                  ; 4-byte Folded Reload
	add	x16, x16, #1
	cmp	x16, #16
	b.ne	LBB16_55
	b	LBB16_53
LBB16_61:
	ldr	x8, [x23]
	ldr	x8, [x25, x8, lsl #3]
	cmp	w14, #1
	b.lt	LBB16_84
; %bb.62:
	mov	x13, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
	mov	x28, #0                         ; =0x0
	add	x20, x23, #8
	str	w14, [sp, #24]                  ; 4-byte Folded Spill
LBB16_63:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_67 Depth 2
                                        ;       Child Loop BB16_70 Depth 3
	ldr	q0, [x11, x13]
	ushll2.8h	v1, v0, #0
	ushll.4s	v2, v1, #0
	ushll.8h	v0, v0, #0
	ushll.4s	v3, v0, #0
	ushll2.4s	v1, v1, #0
	ushll2.4s	v0, v0, #0
	uaddl2.2d	v4, v0, v1
	uaddl2.2d	v5, v3, v2
	add.2d	v4, v5, v4
	uaddl.2d	v0, v0, v1
	uaddl.2d	v1, v3, v2
	add.2d	v0, v1, v0
	add.2d	v0, v0, v4
	addp.2d	d0, v0
	fmov	x9, d0
	add	x9, x9, x12
	cmp	x9, x8
	b.ge	LBB16_66
; %bb.64:                               ;   in Loop: Header=BB16_63 Depth=1
	mov	x26, x28
	mov	x12, x9
LBB16_65:                               ;   in Loop: Header=BB16_63 Depth=1
	add	x13, x13, #16
	mov	x28, x26
	cmp	w14, w13
	b.gt	LBB16_63
	b	LBB16_85
LBB16_66:                               ;   in Loop: Header=BB16_63 Depth=1
	mov	x27, #0                         ; =0x0
	str	x13, [sp, #16]                  ; 8-byte Folded Spill
LBB16_67:                               ;   Parent Loop BB16_63 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB16_70 Depth 3
	orr	x9, x27, x13
	ldrb	w10, [x11, x9]
	add	x12, x12, x10
	cmp	x12, x8
	b.ge	LBB16_69
; %bb.68:                               ;   in Loop: Header=BB16_67 Depth=2
	mov	x26, x28
	add	x27, x27, #1
	cmp	x27, #16
	b.ne	LBB16_67
	b	LBB16_65
LBB16_69:                               ;   in Loop: Header=BB16_67 Depth=2
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x9, lsl #2]
	mov	x0, x22
	mov	x26, x12
	bl	_hdr_value_at_index
	mov	x12, x26
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x9, [x23, x28, lsl #3]
LBB16_70:                               ;   Parent Loop BB16_63 Depth=1
                                        ;     Parent Loop BB16_67 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	str	x0, [x24, x9, lsl #3]
	add	x26, x28, #1
	cmp	x26, x19
	b.hs	LBB16_108
; %bb.71:                               ;   in Loop: Header=BB16_70 Depth=3
	ldr	x9, [x20, x28, lsl #3]
	ldr	x8, [x25, x9, lsl #3]
	mov	x28, x26
	cmp	x12, x8
	b.ge	LBB16_70
; %bb.72:                               ;   in Loop: Header=BB16_67 Depth=2
	mov	x28, x26
	ldr	w14, [sp, #24]                  ; 4-byte Folded Reload
	ldr	x13, [sp, #16]                  ; 8-byte Folded Reload
	add	x27, x27, #1
	cmp	x27, #16
	b.ne	LBB16_67
	b	LBB16_65
LBB16_73:
	ldr	x8, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w8, #0
	b.le	LBB16_108
; %bb.74:
	mov	x26, #0                         ; =0x0
	mov	x27, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
	mov	x28, x23
	ldr	x8, [x28], #8
	ldr	x8, [x25, x8, lsl #3]
	mov	x13, #9223372036854775807       ; =0x7fffffffffffffff
	b	LBB16_77
LBB16_75:                               ;   in Loop: Header=BB16_77 Depth=1
	mov	x27, x9
LBB16_76:                               ;   in Loop: Header=BB16_77 Depth=1
	add	x26, x26, #1
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	x26, x9
	b.eq	LBB16_108
LBB16_77:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_79 Depth 2
	ldr	x9, [x11, x26, lsl #3]
	eor	x10, x12, #0x7fffffffffffffff
	add	x12, x9, x12
	cmp	x9, x10
	csel	x20, x13, x12, gt
	cmp	x20, x8
	b.lt	LBB16_76
; %bb.78:                               ;   in Loop: Header=BB16_77 Depth=1
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x26, lsl #2]
	mov	x0, x22
	str	x12, [sp, #24]                  ; 8-byte Folded Spill
	bl	_hdr_value_at_index
	mov	x13, #9223372036854775807       ; =0x7fffffffffffffff
	ldr	x12, [sp, #24]                  ; 8-byte Folded Reload
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x10, [x23, x27, lsl #3]
LBB16_79:                               ;   Parent Loop BB16_77 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	x0, [x24, x10, lsl #3]
	add	x9, x27, #1
	cmp	x9, x19
	b.hs	LBB16_108
; %bb.80:                               ;   in Loop: Header=BB16_79 Depth=2
	ldr	x10, [x28, x27, lsl #3]
	ldr	x8, [x25, x10, lsl #3]
	mov	x27, x9
	cmp	x20, x8
	b.ge	LBB16_79
	b	LBB16_75
LBB16_81:
	mov	x12, #0                         ; =0x0
	mov	x26, #0                         ; =0x0
	mov	w13, #0                         ; =0x0
LBB16_82:
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w13, w9
	b.ge	LBB16_108
; %bb.83:
	mov	x10, x13
	mov	w27, w10
	add	x28, x23, #8
	b	LBB16_92
LBB16_84:
	mov	w13, #0                         ; =0x0
	mov	x26, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
LBB16_85:
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w13, w9
	b.ge	LBB16_108
; %bb.86:
	mov	x10, x13
	mov	w28, w10
	add	x27, x23, #8
	b	LBB16_98
LBB16_87:
	mov	x12, #0                         ; =0x0
	mov	x26, #0                         ; =0x0
	mov	w13, #0                         ; =0x0
LBB16_88:
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w13, w9
	b.ge	LBB16_108
; %bb.89:
	mov	x10, x13
	mov	w27, w10
	add	x28, x23, #8
	b	LBB16_104
LBB16_90:                               ;   in Loop: Header=BB16_92 Depth=1
	mov	x26, x9
LBB16_91:                               ;   in Loop: Header=BB16_92 Depth=1
	add	x27, x27, #1
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w9, w27
	b.le	LBB16_108
LBB16_92:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_94 Depth 2
	ldrh	w9, [x11, x27, lsl #1]
	add	x12, x12, x9
	cmp	x12, x8
	b.lt	LBB16_91
; %bb.93:                               ;   in Loop: Header=BB16_92 Depth=1
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x27, lsl #2]
	mov	x0, x22
	mov	x20, x12
	bl	_hdr_value_at_index
	mov	x12, x20
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x10, [x23, x26, lsl #3]
LBB16_94:                               ;   Parent Loop BB16_92 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	x0, [x24, x10, lsl #3]
	add	x9, x26, #1
	cmp	x9, x19
	b.hs	LBB16_108
; %bb.95:                               ;   in Loop: Header=BB16_94 Depth=2
	ldr	x10, [x28, x26, lsl #3]
	ldr	x8, [x25, x10, lsl #3]
	mov	x26, x9
	cmp	x12, x8
	b.ge	LBB16_94
	b	LBB16_90
LBB16_96:                               ;   in Loop: Header=BB16_98 Depth=1
	mov	x26, x9
LBB16_97:                               ;   in Loop: Header=BB16_98 Depth=1
	add	x28, x28, #1
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w9, w28
	b.le	LBB16_108
LBB16_98:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_100 Depth 2
	ldrb	w9, [x11, x28]
	add	x12, x12, x9
	cmp	x12, x8
	b.lt	LBB16_97
; %bb.99:                               ;   in Loop: Header=BB16_98 Depth=1
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x28, lsl #2]
	mov	x0, x22
	mov	x20, x12
	bl	_hdr_value_at_index
	mov	x12, x20
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x10, [x23, x26, lsl #3]
LBB16_100:                              ;   Parent Loop BB16_98 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	x0, [x24, x10, lsl #3]
	add	x9, x26, #1
	cmp	x9, x19
	b.hs	LBB16_108
; %bb.101:                              ;   in Loop: Header=BB16_100 Depth=2
	ldr	x10, [x27, x26, lsl #3]
	ldr	x8, [x25, x10, lsl #3]
	mov	x26, x9
	cmp	x12, x8
	b.ge	LBB16_100
	b	LBB16_96
LBB16_102:                              ;   in Loop: Header=BB16_104 Depth=1
	mov	x26, x9
LBB16_103:                              ;   in Loop: Header=BB16_104 Depth=1
	add	x27, x27, #1
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w9, w27
	b.le	LBB16_108
LBB16_104:                              ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_106 Depth 2
	ldr	w9, [x11, x27, lsl #2]
	add	x12, x12, x9
	cmp	x12, x8
	b.lt	LBB16_103
; %bb.105:                              ;   in Loop: Header=BB16_104 Depth=1
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x27, lsl #2]
	mov	x0, x22
	mov	x20, x12
	bl	_hdr_value_at_index
	mov	x12, x20
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x10, [x23, x26, lsl #3]
LBB16_106:                              ;   Parent Loop BB16_104 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	x0, [x24, x10, lsl #3]
	add	x9, x26, #1
	cmp	x9, x19
	b.hs	LBB16_108
; %bb.107:                              ;   in Loop: Header=BB16_106 Depth=2
	ldr	x10, [x28, x26, lsl #3]
	ldr	x8, [x25, x10, lsl #3]
	mov	x26, x9
	cmp	x12, x8
	b.ge	LBB16_106
	b	LBB16_102
LBB16_108:
	mov	x28, #0                         ; =0x0
	mov	x20, #9223372036854775807       ; =0x7fffffffffffffff
	b	LBB16_110
LBB16_109:                              ;   in Loop: Header=BB16_110 Depth=1
	ldr	x8, [sp, #72]                   ; 8-byte Folded Reload
	str	x26, [x8, x28, lsl #3]
	add	x28, x28, #1
	cmp	x19, x28
	b.eq	LBB16_112
LBB16_110:                              ; =>This Inner Loop Header: Depth=1
	ldr	d8, [x21, x28, lsl #3]
	ldr	x27, [x24, x28, lsl #3]
	mov	x0, x22
	mov	x1, x27
	bl	_hdr_lowest_equivalent_value
	mov	x26, x0
	fcmp	d8, #0.0
	b.eq	LBB16_109
; %bb.111:                              ;   in Loop: Header=BB16_110 Depth=1
	mov	x0, x22
	mov	x1, x27
	bl	_hdr_size_of_equivalent_value_range
	eor	x8, x0, #0x7fffffffffffffff
	add	x9, x26, x0
	sub	x9, x9, #1
	cmp	x26, x8
	csel	x26, x20, x9, gt
	b	LBB16_109
LBB16_112:
	cmp	x19, #32
	b.ls	LBB16_114
; %bb.113:
	mov	x0, x25
	bl	_free
	mov	x0, x24
	bl	_free
	mov	x0, x23
	bl	_free
LBB16_114:
	mov	w0, #0                          ; =0x0
LBB16_115:
	ldur	x8, [x29, #-112]
Lloh7:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh8:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh9:
	ldr	x9, [x9]
	cmp	x9, x8
	b.ne	LBB16_117
; %bb.116:
	add	sp, sp, #864
	ldp	x29, x30, [sp, #96]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #80]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #64]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #48]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #32]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #112              ; 16-byte Folded Reload
	ret
LBB16_117:
	bl	___stack_chk_fail
	.loh AdrpLdrGotLdr	Lloh2, Lloh3, Lloh4
	.loh AdrpLdr	Lloh5, Lloh6
	.loh AdrpLdrGotLdr	Lloh7, Lloh8, Lloh9
	.cfi_endproc
