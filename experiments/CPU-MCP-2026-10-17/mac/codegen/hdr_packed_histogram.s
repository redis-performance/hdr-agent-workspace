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
	b.eq	LBB15_25
; %bb.7:
	cmp	w12, #2
	b.eq	LBB15_17
; %bb.8:
	cmp	w12, #1
	b.ne	LBB15_34
; %bb.9:
	negs	w12, w10
	and	w12, w12, #0xf
	and	w13, w10, #0xf
	csneg	w12, w13, w12, mi
	sub	w14, w10, w12
	cmp	w14, #1
	b.lt	LBB15_50
; %bb.10:
	mov	x12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
LBB15_11:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_14 Depth 2
	ldr	q0, [x11, x12]
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
	sub	x16, x8, x13
	cmp	x15, x16
	b.ge	LBB15_13
; %bb.12:                               ;   in Loop: Header=BB15_11 Depth=1
	add	x13, x15, x13
	b	LBB15_16
LBB15_13:                               ;   in Loop: Header=BB15_11 Depth=1
	mov	x15, #0                         ; =0x0
	mov	x16, x11
LBB15_14:                               ;   Parent Loop BB15_11 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w17, [x16, x12]
	add	x13, x13, x17
	cmp	x13, x8
	b.ge	LBB15_38
; %bb.15:                               ;   in Loop: Header=BB15_14 Depth=2
	add	x16, x16, #1
	sub	x15, x15, #1
	cmn	x15, #16
	b.ne	LBB15_14
LBB15_16:                               ;   in Loop: Header=BB15_11 Depth=1
	add	x12, x12, #16
	cmp	w14, w12
	b.gt	LBB15_11
	b	LBB15_51
LBB15_17:
	negs	w12, w10
	and	w12, w12, #0xf
	and	w13, w10, #0xf
	csneg	w12, w13, w12, mi
	sub	w14, w10, w12
	cmp	w14, #1
	b.lt	LBB15_40
; %bb.18:
	mov	x12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
	mov	x15, x11
LBB15_19:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_22 Depth 2
	add	x16, x11, x12, lsl #1
	ldp	q0, q1, [x16]
	ushll.4s	v2, v1, #0
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
	fmov	x16, d0
	sub	x17, x8, x13
	cmp	x16, x17
	b.ge	LBB15_21
; %bb.20:                               ;   in Loop: Header=BB15_19 Depth=1
	add	x13, x16, x13
	b	LBB15_24
LBB15_21:                               ;   in Loop: Header=BB15_19 Depth=1
	mov	x16, #0                         ; =0x0
	mov	x17, x15
LBB15_22:                               ;   Parent Loop BB15_19 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrh	w0, [x17], #2
	add	x13, x13, x0
	cmp	x13, x8
	b.ge	LBB15_33
; %bb.23:                               ;   in Loop: Header=BB15_22 Depth=2
	sub	x16, x16, #1
	cmn	x16, #16
	b.ne	LBB15_22
LBB15_24:                               ;   in Loop: Header=BB15_19 Depth=1
	add	x12, x12, #16
	add	x15, x15, #32
	cmp	w14, w12
	b.gt	LBB15_19
	b	LBB15_41
LBB15_25:
	negs	w12, w10
	and	w12, w12, #0xf
	and	w13, w10, #0xf
	csneg	w12, w13, w12, mi
	sub	w14, w10, w12
	cmp	w14, #1
	b.lt	LBB15_45
; %bb.26:
	mov	x12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
	mov	x15, x11
LBB15_27:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB15_30 Depth 2
	add	x16, x11, x12, lsl #2
	ldp	q1, q0, [x16]
	ldp	q3, q2, [x16, #32]
	uaddl2.2d	v4, v0, v2
	uaddl2.2d	v5, v1, v3
	add.2d	v4, v5, v4
	uaddl.2d	v0, v0, v2
	uaddl.2d	v1, v1, v3
	add.2d	v0, v1, v0
	add.2d	v0, v0, v4
	addp.2d	d0, v0
	fmov	x16, d0
	sub	x17, x8, x13
	cmp	x16, x17
	b.ge	LBB15_29
; %bb.28:                               ;   in Loop: Header=BB15_27 Depth=1
	add	x13, x16, x13
	b	LBB15_32
LBB15_29:                               ;   in Loop: Header=BB15_27 Depth=1
	mov	x16, #0                         ; =0x0
	mov	x17, x15
LBB15_30:                               ;   Parent Loop BB15_27 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	w0, [x17], #4
	add	x13, x13, x0
	cmp	x13, x8
	b.ge	LBB15_33
; %bb.31:                               ;   in Loop: Header=BB15_30 Depth=2
	sub	x16, x16, #1
	cmn	x16, #16
	b.ne	LBB15_30
LBB15_32:                               ;   in Loop: Header=BB15_27 Depth=1
	add	x12, x12, #16
	add	x15, x15, #64
	cmp	w14, w12
	b.gt	LBB15_27
	b	LBB15_46
LBB15_33:
	sub	x12, x12, x16
	b	LBB15_39
LBB15_34:
	cmp	w10, #1
	b.lt	LBB15_55
; %bb.35:
	mov	x12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
LBB15_36:                               ; =>This Inner Loop Header: Depth=1
	ldr	x14, [x11, x12, lsl #3]
	eor	x15, x13, #0x7fffffffffffffff
	add	x13, x14, x13
	cmp	x14, x15
	ccmp	x13, x8, #0, le
	b.ge	LBB15_39
; %bb.37:                               ;   in Loop: Header=BB15_36 Depth=1
	add	x12, x12, #1
	cmp	x10, x12
	b.ne	LBB15_36
	b	LBB15_55
LBB15_38:
	sub	x12, x12, x15
LBB15_39:
	ldr	w1, [x9, x12, lsl #2]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
	b	LBB15_56
LBB15_40:
	mov	w12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
LBB15_41:
	cmp	w12, w10
	b.ge	LBB15_55
; %bb.42:
	mov	w12, w12
LBB15_43:                               ; =>This Inner Loop Header: Depth=1
	ldrh	w14, [x11, x12, lsl #1]
	add	x13, x13, x14
	cmp	x13, x8
	b.ge	LBB15_39
; %bb.44:                               ;   in Loop: Header=BB15_43 Depth=1
	mov	x20, #0                         ; =0x0
	add	x12, x12, #1
	cmp	w10, w12
	b.gt	LBB15_43
	b	LBB15_56
LBB15_45:
	mov	w12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
LBB15_46:
	cmp	w12, w10
	b.ge	LBB15_55
; %bb.47:
	mov	w12, w12
LBB15_48:                               ; =>This Inner Loop Header: Depth=1
	ldr	w14, [x11, x12, lsl #2]
	add	x13, x13, x14
	cmp	x13, x8
	b.ge	LBB15_39
; %bb.49:                               ;   in Loop: Header=BB15_48 Depth=1
	mov	x20, #0                         ; =0x0
	add	x12, x12, #1
	cmp	w10, w12
	b.gt	LBB15_48
	b	LBB15_56
LBB15_50:
	mov	w12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
LBB15_51:
	cmp	w12, w10
	b.ge	LBB15_55
; %bb.52:
	mov	w12, w12
LBB15_53:                               ; =>This Inner Loop Header: Depth=1
	ldrb	w14, [x11, x12]
	add	x13, x13, x14
	cmp	x13, x8
	b.ge	LBB15_39
; %bb.54:                               ;   in Loop: Header=BB15_53 Depth=1
	mov	x20, #0                         ; =0x0
	add	x12, x12, #1
	cmp	w10, w12
	b.gt	LBB15_53
	b	LBB15_56
LBB15_55:
	mov	x20, #0                         ; =0x0
LBB15_56:
	mov	x0, x19
	mov	x1, x20
	bl	_hdr_lowest_equivalent_value
	fcmp	d8, #0.0
	b.ne	LBB15_58
; %bb.57:
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #32]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #64               ; 16-byte Folded Reload
	ret
LBB15_58:
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
	sub	sp, sp, #848
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
	cbz	x1, LBB16_111
; %bb.1:
	cbz	x2, LBB16_111
; %bb.2:
	mov	x19, x3
	cbz	x3, LBB16_110
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
	cbz	x9, LBB16_41
; %bb.6:
	mov	w0, #12                         ; =0xc
	b	LBB16_111
LBB16_7:
	lsl	x1, x19, #3
	mov	x0, x2
	bl	_bzero
	b	LBB16_110
LBB16_8:
	mov	x20, x2
	mov	x27, x8
	add	x25, sp, #576
	add	x24, sp, #320
	add	x23, sp, #64
LBB16_9:
	scvtf	d0, x26
	str	q0, [sp, #32]                   ; 16-byte Folded Spill
	lsl	x1, x19, #3
	mov	x0, x24
	bl	_bzero
	cmp	x19, #1
	b.ne	LBB16_11
; %bb.10:
	mov	x8, #0                          ; =0x0
	mov	x16, x20
	ldr	q18, [sp, #32]                  ; 16-byte Folded Reload
	b	LBB16_30
LBB16_11:
	and	x8, x19, #0xfffffffffffffffe
	ldr	q18, [sp, #32]                  ; 16-byte Folded Reload
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
	b.ne	LBB16_30
LBB16_14:
	cmp	x19, #1
	b.ne	LBB16_36
LBB16_15:
	ldr	w10, [x27, #48]
	negs	w8, w10
	and	w8, w8, #0xf
	and	w9, w10, #0xf
	csneg	w8, w9, w8, mi
	sub	w14, w10, w8
	ldrb	w8, [x27, #60]
	ldp	x9, x11, [x27, #8]
	str	x9, [sp, #32]                   ; 8-byte Folded Spill
	cmp	w8, #1
	stp	x10, x11, [sp, #16]             ; 16-byte Folded Spill
	str	x16, [sp, #56]                  ; 8-byte Folded Spill
	b.eq	LBB16_57
; %bb.16:
	cmp	w8, #2
	b.eq	LBB16_45
; %bb.17:
	cmp	w8, #4
	b.ne	LBB16_69
; %bb.18:
	ldr	x8, [x23]
	ldr	x8, [x25, x8, lsl #3]
	cmp	w14, #1
	b.lt	LBB16_83
; %bb.19:
	mov	x13, #0                         ; =0x0
	mov	x28, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
	add	x20, x23, #8
	str	w14, [sp, #8]                   ; 4-byte Folded Spill
LBB16_20:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_24 Depth 2
                                        ;       Child Loop BB16_27 Depth 3
	add	x9, x11, x13, lsl #2
	ldp	q1, q0, [x9]
	ldp	q3, q2, [x9, #32]
	uaddl2.2d	v4, v0, v2
	uaddl2.2d	v5, v1, v3
	add.2d	v4, v5, v4
	uaddl.2d	v0, v0, v2
	uaddl.2d	v1, v1, v3
	add.2d	v0, v1, v0
	add.2d	v0, v0, v4
	addp.2d	d0, v0
	fmov	x9, d0
	add	x9, x9, x12
	cmp	x9, x8
	b.ge	LBB16_23
; %bb.21:                               ;   in Loop: Header=BB16_20 Depth=1
	mov	x12, x9
	mov	x26, x28
LBB16_22:                               ;   in Loop: Header=BB16_20 Depth=1
	add	x13, x13, #16
	mov	x28, x26
	cmp	w14, w13
	b.gt	LBB16_20
	b	LBB16_84
LBB16_23:                               ;   in Loop: Header=BB16_20 Depth=1
	mov	x27, #0                         ; =0x0
	str	x13, [sp]                       ; 8-byte Folded Spill
LBB16_24:                               ;   Parent Loop BB16_20 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB16_27 Depth 3
	orr	x9, x27, x13
	ldr	w10, [x11, x9, lsl #2]
	add	x12, x12, x10
	cmp	x12, x8
	b.ge	LBB16_26
; %bb.25:                               ;   in Loop: Header=BB16_24 Depth=2
	mov	x26, x28
	add	x27, x27, #1
	cmp	x27, #16
	b.ne	LBB16_24
	b	LBB16_22
LBB16_26:                               ;   in Loop: Header=BB16_24 Depth=2
	ldr	x8, [sp, #32]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x9, lsl #2]
	mov	x0, x22
	mov	x26, x12
	bl	_hdr_value_at_index
	mov	x12, x26
	ldr	x11, [sp, #24]                  ; 8-byte Folded Reload
	ldr	x9, [x23, x28, lsl #3]
LBB16_27:                               ;   Parent Loop BB16_20 Depth=1
                                        ;     Parent Loop BB16_24 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	str	x0, [x24, x9, lsl #3]
	add	x26, x28, #1
	cmp	x26, x19
	b.hs	LBB16_104
; %bb.28:                               ;   in Loop: Header=BB16_27 Depth=3
	ldr	x9, [x20, x28, lsl #3]
	ldr	x8, [x25, x9, lsl #3]
	mov	x28, x26
	cmp	x12, x8
	b.ge	LBB16_27
; %bb.29:                               ;   in Loop: Header=BB16_24 Depth=2
	mov	x28, x26
	ldr	w14, [sp, #8]                   ; 4-byte Folded Reload
	ldr	x13, [sp]                       ; 8-byte Folded Reload
	add	x27, x27, #1
	cmp	x27, #16
	b.ne	LBB16_24
	b	LBB16_22
LBB16_30:
	mov	x9, #4636737291354636288        ; =0x4059000000000000
	fmov	d0, x9
	fmov	d1, #0.50000000
	fmov	d2, #1.00000000
	b	LBB16_33
LBB16_31:                               ;   in Loop: Header=BB16_33 Depth=1
	mov	w9, #1                          ; =0x1
LBB16_32:                               ;   in Loop: Header=BB16_33 Depth=1
	str	x9, [x25, x8, lsl #3]
	str	x8, [x23, x8, lsl #3]
	add	x8, x8, #1
	cmp	x19, x8
	b.eq	LBB16_14
LBB16_33:                               ; =>This Inner Loop Header: Depth=1
	ldr	d3, [x21, x8, lsl #3]
	fminnm	d3, d3, d0
	fdiv	d3, d3, d0
	fmadd	d3, d3, d18, d1
	fcmp	d3, d2
	b.lt	LBB16_31
; %bb.34:                               ;   in Loop: Header=BB16_33 Depth=1
	fcmp	d3, d18
	mov	x9, x26
	b.ge	LBB16_32
; %bb.35:                               ;   in Loop: Header=BB16_33 Depth=1
	fcvtzs	x9, d3
	b	LBB16_32
LBB16_36:
	add	x8, x23, #8
	mov	w9, #1                          ; =0x1
	b	LBB16_38
LBB16_37:                               ;   in Loop: Header=BB16_38 Depth=1
	str	x10, [x23, x11, lsl #3]
	add	x9, x9, #1
	add	x8, x8, #8
	cmp	x9, x19
	b.eq	LBB16_15
LBB16_38:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_39 Depth 2
	ldr	x10, [x23, x9, lsl #3]
	ldr	x12, [x25, x10, lsl #3]
	mov	x13, x8
	mov	x11, x9
LBB16_39:                               ;   Parent Loop BB16_38 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldur	x14, [x13, #-8]
	ldr	x15, [x25, x14, lsl #3]
	cmp	x15, x12
	b.le	LBB16_37
; %bb.40:                               ;   in Loop: Header=BB16_39 Depth=2
	str	x14, [x13], #-8
	sub	x11, x11, #1
	cbnz	x11, LBB16_39
	b	LBB16_37
LBB16_41:
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
	cbz	x25, LBB16_44
; %bb.42:
	cbz	x24, LBB16_44
; %bb.43:
	cbnz	x23, LBB16_9
LBB16_44:
	mov	x0, x25
	bl	_free
	mov	x0, x24
	bl	_free
	mov	x0, x23
	bl	_free
	mov	w0, #12                         ; =0xc
	b	LBB16_111
LBB16_45:
	ldr	x8, [x23]
	ldr	x8, [x25, x8, lsl #3]
	cmp	w14, #1
	b.lt	LBB16_77
; %bb.46:
	mov	x13, #0                         ; =0x0
	mov	x26, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
	add	x20, x23, #8
	str	w14, [sp, #8]                   ; 4-byte Folded Spill
LBB16_47:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_51 Depth 2
                                        ;       Child Loop BB16_54 Depth 3
	add	x9, x11, x13, lsl #1
	ldp	q0, q1, [x9]
	ushll.4s	v2, v1, #0
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
	b.ge	LBB16_50
; %bb.48:                               ;   in Loop: Header=BB16_47 Depth=1
	mov	x12, x9
	mov	x28, x26
LBB16_49:                               ;   in Loop: Header=BB16_47 Depth=1
	add	x13, x13, #16
	mov	x26, x28
	cmp	w14, w13
	b.gt	LBB16_47
	b	LBB16_78
LBB16_50:                               ;   in Loop: Header=BB16_47 Depth=1
	mov	x27, #0                         ; =0x0
	str	x13, [sp]                       ; 8-byte Folded Spill
LBB16_51:                               ;   Parent Loop BB16_47 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB16_54 Depth 3
	orr	x9, x27, x13
	ldrh	w10, [x11, x9, lsl #1]
	add	x12, x12, x10
	cmp	x12, x8
	b.ge	LBB16_53
; %bb.52:                               ;   in Loop: Header=BB16_51 Depth=2
	mov	x28, x26
	add	x27, x27, #1
	cmp	x27, #16
	b.ne	LBB16_51
	b	LBB16_49
LBB16_53:                               ;   in Loop: Header=BB16_51 Depth=2
	ldr	x8, [sp, #32]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x9, lsl #2]
	mov	x0, x22
	mov	x28, x12
	bl	_hdr_value_at_index
	mov	x12, x28
	ldr	x11, [sp, #24]                  ; 8-byte Folded Reload
	ldr	x9, [x23, x26, lsl #3]
LBB16_54:                               ;   Parent Loop BB16_47 Depth=1
                                        ;     Parent Loop BB16_51 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	str	x0, [x24, x9, lsl #3]
	add	x28, x26, #1
	cmp	x28, x19
	b.hs	LBB16_104
; %bb.55:                               ;   in Loop: Header=BB16_54 Depth=3
	ldr	x9, [x20, x26, lsl #3]
	ldr	x8, [x25, x9, lsl #3]
	mov	x26, x28
	cmp	x12, x8
	b.ge	LBB16_54
; %bb.56:                               ;   in Loop: Header=BB16_51 Depth=2
	mov	x26, x28
	ldr	w14, [sp, #8]                   ; 4-byte Folded Reload
	ldr	x13, [sp]                       ; 8-byte Folded Reload
	add	x27, x27, #1
	cmp	x27, #16
	b.ne	LBB16_51
	b	LBB16_49
LBB16_57:
	ldr	x8, [x23]
	ldr	x8, [x25, x8, lsl #3]
	cmp	w14, #1
	b.lt	LBB16_80
; %bb.58:
	mov	x13, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
	mov	x26, #0                         ; =0x0
	add	x20, x23, #8
	str	w14, [sp, #8]                   ; 4-byte Folded Spill
LBB16_59:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_63 Depth 2
                                        ;       Child Loop BB16_66 Depth 3
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
	b.ge	LBB16_62
; %bb.60:                               ;   in Loop: Header=BB16_59 Depth=1
	mov	x28, x26
	mov	x12, x9
LBB16_61:                               ;   in Loop: Header=BB16_59 Depth=1
	add	x13, x13, #16
	mov	x26, x28
	cmp	w14, w13
	b.gt	LBB16_59
	b	LBB16_81
LBB16_62:                               ;   in Loop: Header=BB16_59 Depth=1
	mov	x27, #0                         ; =0x0
	str	x13, [sp]                       ; 8-byte Folded Spill
LBB16_63:                               ;   Parent Loop BB16_59 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB16_66 Depth 3
	orr	x9, x27, x13
	ldrb	w10, [x11, x9]
	add	x12, x12, x10
	cmp	x12, x8
	b.ge	LBB16_65
; %bb.64:                               ;   in Loop: Header=BB16_63 Depth=2
	mov	x28, x26
	add	x27, x27, #1
	cmp	x27, #16
	b.ne	LBB16_63
	b	LBB16_61
LBB16_65:                               ;   in Loop: Header=BB16_63 Depth=2
	ldr	x8, [sp, #32]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x9, lsl #2]
	mov	x0, x22
	mov	x28, x12
	bl	_hdr_value_at_index
	mov	x12, x28
	ldr	x11, [sp, #24]                  ; 8-byte Folded Reload
	ldr	x9, [x23, x26, lsl #3]
LBB16_66:                               ;   Parent Loop BB16_59 Depth=1
                                        ;     Parent Loop BB16_63 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	str	x0, [x24, x9, lsl #3]
	add	x28, x26, #1
	cmp	x28, x19
	b.hs	LBB16_104
; %bb.67:                               ;   in Loop: Header=BB16_66 Depth=3
	ldr	x9, [x20, x26, lsl #3]
	ldr	x8, [x25, x9, lsl #3]
	mov	x26, x28
	cmp	x12, x8
	b.ge	LBB16_66
; %bb.68:                               ;   in Loop: Header=BB16_63 Depth=2
	mov	x26, x28
	ldr	x13, [sp]                       ; 8-byte Folded Reload
	ldr	w14, [sp, #8]                   ; 4-byte Folded Reload
	add	x27, x27, #1
	cmp	x27, #16
	b.ne	LBB16_63
	b	LBB16_61
LBB16_69:
	ldr	x8, [sp, #16]                   ; 8-byte Folded Reload
	cmp	w8, #0
	b.le	LBB16_104
; %bb.70:
	mov	x26, #0                         ; =0x0
	mov	x27, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
	mov	x28, x23
	ldr	x8, [x28], #8
	ldr	x8, [x25, x8, lsl #3]
	mov	x13, #9223372036854775807       ; =0x7fffffffffffffff
	b	LBB16_73
LBB16_71:                               ;   in Loop: Header=BB16_73 Depth=1
	mov	x27, x9
LBB16_72:                               ;   in Loop: Header=BB16_73 Depth=1
	add	x26, x26, #1
	ldr	x9, [sp, #16]                   ; 8-byte Folded Reload
	cmp	x26, x9
	b.eq	LBB16_104
LBB16_73:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_75 Depth 2
	ldr	x9, [x11, x26, lsl #3]
	eor	x10, x12, #0x7fffffffffffffff
	add	x12, x9, x12
	cmp	x9, x10
	csel	x20, x13, x12, gt
	cmp	x20, x8
	b.lt	LBB16_72
; %bb.74:                               ;   in Loop: Header=BB16_73 Depth=1
	ldr	x8, [sp, #32]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x26, lsl #2]
	mov	x0, x22
	str	x12, [sp, #8]                   ; 8-byte Folded Spill
	bl	_hdr_value_at_index
	mov	x13, #9223372036854775807       ; =0x7fffffffffffffff
	ldr	x12, [sp, #8]                   ; 8-byte Folded Reload
	ldr	x11, [sp, #24]                  ; 8-byte Folded Reload
	ldr	x10, [x23, x27, lsl #3]
LBB16_75:                               ;   Parent Loop BB16_73 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	x0, [x24, x10, lsl #3]
	add	x9, x27, #1
	cmp	x9, x19
	b.hs	LBB16_104
; %bb.76:                               ;   in Loop: Header=BB16_75 Depth=2
	ldr	x10, [x28, x27, lsl #3]
	ldr	x8, [x25, x10, lsl #3]
	mov	x27, x9
	cmp	x20, x8
	b.ge	LBB16_75
	b	LBB16_71
LBB16_77:
	mov	x12, #0                         ; =0x0
	mov	x28, #0                         ; =0x0
	mov	w13, #0                         ; =0x0
LBB16_78:
	ldr	x9, [sp, #16]                   ; 8-byte Folded Reload
	cmp	w13, w9
	b.ge	LBB16_104
; %bb.79:
	mov	x10, x13
	mov	w26, w10
	add	x27, x23, #8
	b	LBB16_88
LBB16_80:
	mov	w13, #0                         ; =0x0
	mov	x28, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
LBB16_81:
	ldr	x9, [sp, #16]                   ; 8-byte Folded Reload
	cmp	w13, w9
	b.ge	LBB16_104
; %bb.82:
	mov	x10, x13
	mov	w26, w10
	add	x27, x23, #8
	b	LBB16_94
LBB16_83:
	mov	x12, #0                         ; =0x0
	mov	x26, #0                         ; =0x0
	mov	w13, #0                         ; =0x0
LBB16_84:
	ldr	x9, [sp, #16]                   ; 8-byte Folded Reload
	cmp	w13, w9
	b.ge	LBB16_104
; %bb.85:
	mov	x10, x13
	mov	w28, w10
	add	x27, x23, #8
	b	LBB16_100
LBB16_86:                               ;   in Loop: Header=BB16_88 Depth=1
	mov	x28, x9
LBB16_87:                               ;   in Loop: Header=BB16_88 Depth=1
	add	x26, x26, #1
	ldr	x9, [sp, #16]                   ; 8-byte Folded Reload
	cmp	w9, w26
	b.le	LBB16_104
LBB16_88:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_90 Depth 2
	ldrh	w9, [x11, x26, lsl #1]
	add	x12, x12, x9
	cmp	x12, x8
	b.lt	LBB16_87
; %bb.89:                               ;   in Loop: Header=BB16_88 Depth=1
	ldr	x8, [sp, #32]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x26, lsl #2]
	mov	x0, x22
	mov	x20, x12
	bl	_hdr_value_at_index
	mov	x12, x20
	ldr	x11, [sp, #24]                  ; 8-byte Folded Reload
	ldr	x10, [x23, x28, lsl #3]
LBB16_90:                               ;   Parent Loop BB16_88 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	x0, [x24, x10, lsl #3]
	add	x9, x28, #1
	cmp	x9, x19
	b.hs	LBB16_104
; %bb.91:                               ;   in Loop: Header=BB16_90 Depth=2
	ldr	x10, [x27, x28, lsl #3]
	ldr	x8, [x25, x10, lsl #3]
	mov	x28, x9
	cmp	x12, x8
	b.ge	LBB16_90
	b	LBB16_86
LBB16_92:                               ;   in Loop: Header=BB16_94 Depth=1
	mov	x28, x9
LBB16_93:                               ;   in Loop: Header=BB16_94 Depth=1
	add	x26, x26, #1
	ldr	x9, [sp, #16]                   ; 8-byte Folded Reload
	cmp	w9, w26
	b.le	LBB16_104
LBB16_94:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_96 Depth 2
	ldrb	w9, [x11, x26]
	add	x12, x12, x9
	cmp	x12, x8
	b.lt	LBB16_93
; %bb.95:                               ;   in Loop: Header=BB16_94 Depth=1
	ldr	x8, [sp, #32]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x26, lsl #2]
	mov	x0, x22
	mov	x20, x12
	bl	_hdr_value_at_index
	mov	x12, x20
	ldr	x11, [sp, #24]                  ; 8-byte Folded Reload
	ldr	x10, [x23, x28, lsl #3]
LBB16_96:                               ;   Parent Loop BB16_94 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	x0, [x24, x10, lsl #3]
	add	x9, x28, #1
	cmp	x9, x19
	b.hs	LBB16_104
; %bb.97:                               ;   in Loop: Header=BB16_96 Depth=2
	ldr	x10, [x27, x28, lsl #3]
	ldr	x8, [x25, x10, lsl #3]
	mov	x28, x9
	cmp	x12, x8
	b.ge	LBB16_96
	b	LBB16_92
LBB16_98:                               ;   in Loop: Header=BB16_100 Depth=1
	mov	x26, x9
LBB16_99:                               ;   in Loop: Header=BB16_100 Depth=1
	add	x28, x28, #1
	ldr	x9, [sp, #16]                   ; 8-byte Folded Reload
	cmp	w9, w28
	b.le	LBB16_104
LBB16_100:                              ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_102 Depth 2
	ldr	w9, [x11, x28, lsl #2]
	add	x12, x12, x9
	cmp	x12, x8
	b.lt	LBB16_99
; %bb.101:                              ;   in Loop: Header=BB16_100 Depth=1
	ldr	x8, [sp, #32]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x28, lsl #2]
	mov	x0, x22
	mov	x20, x12
	bl	_hdr_value_at_index
	mov	x12, x20
	ldr	x11, [sp, #24]                  ; 8-byte Folded Reload
	ldr	x10, [x23, x26, lsl #3]
LBB16_102:                              ;   Parent Loop BB16_100 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	x0, [x24, x10, lsl #3]
	add	x9, x26, #1
	cmp	x9, x19
	b.hs	LBB16_104
; %bb.103:                              ;   in Loop: Header=BB16_102 Depth=2
	ldr	x10, [x27, x26, lsl #3]
	ldr	x8, [x25, x10, lsl #3]
	mov	x26, x9
	cmp	x12, x8
	b.ge	LBB16_102
	b	LBB16_98
LBB16_104:
	mov	x28, #0                         ; =0x0
	mov	x20, #9223372036854775807       ; =0x7fffffffffffffff
	b	LBB16_106
LBB16_105:                              ;   in Loop: Header=BB16_106 Depth=1
	ldr	x8, [sp, #56]                   ; 8-byte Folded Reload
	str	x26, [x8, x28, lsl #3]
	add	x28, x28, #1
	cmp	x19, x28
	b.eq	LBB16_108
LBB16_106:                              ; =>This Inner Loop Header: Depth=1
	ldr	d8, [x21, x28, lsl #3]
	ldr	x27, [x24, x28, lsl #3]
	mov	x0, x22
	mov	x1, x27
	bl	_hdr_lowest_equivalent_value
	mov	x26, x0
	fcmp	d8, #0.0
	b.eq	LBB16_105
; %bb.107:                              ;   in Loop: Header=BB16_106 Depth=1
	mov	x0, x22
	mov	x1, x27
	bl	_hdr_size_of_equivalent_value_range
	eor	x8, x0, #0x7fffffffffffffff
	add	x9, x26, x0
	sub	x9, x9, #1
	cmp	x26, x8
	csel	x26, x20, x9, gt
	b	LBB16_105
LBB16_108:
	cmp	x19, #32
	b.ls	LBB16_110
; %bb.109:
	mov	x0, x25
	bl	_free
	mov	x0, x24
	bl	_free
	mov	x0, x23
	bl	_free
LBB16_110:
	mov	w0, #0                          ; =0x0
LBB16_111:
	ldur	x8, [x29, #-112]
Lloh7:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh8:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh9:
	ldr	x9, [x9]
	cmp	x9, x8
	b.ne	LBB16_113
; %bb.112:
	add	sp, sp, #848
	ldp	x29, x30, [sp, #96]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #80]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #64]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #48]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #32]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #112              ; 16-byte Folded Reload
	ret
LBB16_113:
	bl	___stack_chk_fail
	.loh AdrpLdrGotLdr	Lloh2, Lloh3, Lloh4
	.loh AdrpLdr	Lloh5, Lloh6
	.loh AdrpLdrGotLdr	Lloh7, Lloh8, Lloh9
	.cfi_endproc
