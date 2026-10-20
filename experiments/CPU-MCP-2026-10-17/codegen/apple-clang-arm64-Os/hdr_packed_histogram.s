_hdr_packed_record_values:              ; @hdr_packed_record_values
	.cfi_startproc
; %bb.0:
	tbnz	x1, #63, LBB6_7
; %bb.1:
	stp	x24, x23, [sp, #-64]!           ; 16-byte Folded Spill
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
	.cfi_offset w23, -56
	.cfi_offset w24, -64
	mov	x21, x2
	mov	x20, x0
	mov	w0, #0                          ; =0x0
	tbnz	x2, #63, LBB6_6
; %bb.2:
	mov	x19, x1
	ldr	x22, [x20]
	ldr	x8, [x22, #8]
	cmp	x8, x1
	b.lt	LBB6_6
; %bb.3:
	mov	x0, x22
	mov	x1, x19
	bl	_counts_index_for
	ldr	w8, [x22, #80]
	cmp	w0, w8
	b.hs	LBB6_5
; %bb.4:
	ldr	x8, [x20, #24]
	eor	x9, x8, #0x7fffffffffffffff
	cmp	x9, x21
	b.hs	LBB6_8
LBB6_5:
	mov	w0, #0                          ; =0x0
LBB6_6:
	ldp	x29, x30, [sp, #48]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #32]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #16]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp], #64             ; 16-byte Folded Reload
	ret
LBB6_7:
	mov	w0, #0                          ; =0x0
	ret
LBB6_8:
	cbz	x21, LBB6_34
; %bb.9:
	mov	x23, x0
	ldr	w8, [x20, #48]
	cmp	w8, #1
	b.lt	LBB6_12
; %bb.10:
	mov	w22, #0                         ; =0x0
	ldr	x9, [x20, #8]
	mov	x10, x8
LBB6_11:                                ; =>This Inner Loop Header: Depth=1
	sub	w11, w10, w22
	add	w11, w22, w11, lsr #1
	ldr	w12, [x9, w11, uxtw #2]
	cmp	w12, w23
	csel	w10, w10, w11, lt
	csinc	w22, w22, w11, ge
	cmp	w22, w10
	b.lt	LBB6_11
	b	LBB6_13
LBB6_12:
	mov	w22, #0                         ; =0x0
LBB6_13:
	cmp	w22, w8
	b.ge	LBB6_19
; %bb.14:
	ldr	x9, [x20, #8]
	ldr	w9, [x9, w22, uxtw #2]
	cmp	w9, w23
	b.ne	LBB6_19
; %bb.15:
	mov	w9, w22
	ldr	x8, [x20, #16]
	ldrb	w10, [x20, #60]
	umull	x9, w9, w10
	cmp	w10, #4
	b.eq	LBB6_30
; %bb.16:
	cmp	w10, #2
	b.eq	LBB6_29
; %bb.17:
	cmp	w10, #1
	b.ne	LBB6_31
; %bb.18:
	ldrb	w8, [x8, x9]
	b	LBB6_32
LBB6_19:
	ldp	w10, w9, [x20, #52]
	cmp	w8, w10
	ccmp	w8, w9, #0, lt
	b.lt	LBB6_27
; %bb.20:
	cmp	w10, w9
	csel	w8, w10, w9, lt
	mov	w11, #1073741823                ; =0x3fffffff
	cmp	w8, w11
	b.gt	LBB6_5
; %bb.21:
	lsl	w11, w8, #1
	mov	w12, #4                         ; =0x4
	cmp	w8, #0
	csel	w24, w12, w11, eq
	cmp	w10, w24
	b.ge	LBB6_24
; %bb.22:
	ldr	x0, [x20, #8]
	sbfiz	x1, x24, #2, #32
	bl	_realloc
	cbz	x0, LBB6_6
; %bb.23:
	str	x0, [x20, #8]
	str	w24, [x20, #52]
	ldr	w9, [x20, #56]
LBB6_24:
	cmp	w9, w24
	b.ge	LBB6_27
; %bb.25:
	ldr	x0, [x20, #16]
	ldrb	w8, [x20, #60]
	smull	x1, w8, w24
	bl	_realloc
	cbz	x0, LBB6_6
; %bb.26:
	str	x0, [x20, #16]
	str	w24, [x20, #56]
LBB6_27:
	mov	x0, x20
	mov	x1, x21
	bl	_widen_to_fit
	cbz	w0, LBB6_6
; %bb.28:
	ldr	x8, [x20, #8]
	add	w24, w22, #1
	add	x0, x8, w24, uxtw #2
	add	x1, x8, w22, uxtw #2
	ldr	w8, [x20, #48]
	sub	w8, w8, w22
	sbfiz	x2, x8, #2, #32
	bl	_memmove
	ldr	x8, [x20, #16]
	ldrb	w9, [x20, #60]
	umaddl	x0, w9, w24, x8
	umaddl	x1, w9, w22, x8
	ldrsw	x8, [x20, #48]
	sub	x8, x8, w22, sxtw
	mul	x2, x8, x9
	bl	_memmove
	ldr	x8, [x20, #8]
	str	w23, [x8, w22, uxtw #2]
	ldr	w8, [x20, #48]
	add	w8, w8, #1
	str	w8, [x20, #48]
	mov	x23, x21
	b	LBB6_33
LBB6_29:
	ldrh	w8, [x8, x9]
	b	LBB6_32
LBB6_30:
	ldr	w8, [x8, x9]
	b	LBB6_32
LBB6_31:
	ldr	x8, [x8, x9]
LBB6_32:
	add	x23, x8, x21
	mov	x0, x20
	mov	x1, x23
	bl	_widen_to_fit
	tbz	w0, #0, LBB6_5
LBB6_33:
	mov	x0, x20
	mov	x1, x22
	mov	x2, x23
	bl	_slot_set
	ldr	x8, [x20, #24]
LBB6_34:
	add	x8, x8, x21
	str	x8, [x20, #24]
	cbz	x19, LBB6_37
; %bb.35:
	ldr	x8, [x20, #32]
	cmp	x8, x19
	b.le	LBB6_37
; %bb.36:
	str	x19, [x20, #32]
LBB6_37:
	ldr	x8, [x20, #40]
	cmp	x8, x19
	b.ge	LBB6_39
; %bb.38:
	str	x19, [x20, #40]
LBB6_39:
	mov	w0, #1                          ; =0x1
	b	LBB6_6
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
	stp	x20, x19, [sp, #-32]!           ; 16-byte Folded Spill
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	tbnz	x1, #63, LBB12_3
; %bb.1:
	mov	x19, x0
	ldr	x20, [x0]
	mov	x0, x20
	bl	_counts_index_for
	ldr	w8, [x20, #80]
	cmp	w0, w8
	b.hs	LBB12_3
; %bb.2:
	mov	x1, x0
	mov	x0, x19
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	b	_sparse_get
LBB12_3:
	mov	x0, #0                          ; =0x0
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
	.cfi_endproc

_hdr_packed_value_at_percentile:        ; @hdr_packed_value_at_percentile
	.cfi_startproc
; %bb.0:
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
	ldr	x8, [x0, #24]
	cbz	x8, LBB16_3
; %bb.1:
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
	b.ge	LBB16_4
; %bb.2:
	mov	w8, #1                          ; =0x1
	b	LBB16_6
LBB16_3:
	mov	x21, #0                         ; =0x0
	b	LBB16_61
LBB16_4:
	fcmp	d0, d1
	b.ge	LBB16_6
; %bb.5:
	fcvtzs	x8, d0
LBB16_6:
	ldr	w10, [x0, #48]
	ldrb	w12, [x0, #60]
	ldp	x9, x11, [x0, #8]
	cmp	w12, #4
	b.eq	LBB16_25
; %bb.7:
	cmp	w12, #2
	b.eq	LBB16_17
; %bb.8:
	cmp	w12, #1
	b.ne	LBB16_35
; %bb.9:
	negs	w12, w10
	and	w12, w12, #0xf
	and	w13, w10, #0xf
	csneg	w12, w13, w12, mi
	sub	w14, w10, w12
	cmp	w14, #1
	b.lt	LBB16_53
; %bb.10:
	mov	x12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
LBB16_11:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_14 Depth 2
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
	b.ge	LBB16_13
; %bb.12:                               ;   in Loop: Header=BB16_11 Depth=1
	add	x13, x15, x13
	b	LBB16_16
LBB16_13:                               ;   in Loop: Header=BB16_11 Depth=1
	mov	x15, #0                         ; =0x0
	mov	x16, x11
LBB16_14:                               ;   Parent Loop BB16_11 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w17, [x16, x12]
	add	x13, x13, x17
	cmp	x13, x8
	b.ge	LBB16_41
; %bb.15:                               ;   in Loop: Header=BB16_14 Depth=2
	add	x16, x16, #1
	sub	x15, x15, #1
	cmn	x15, #16
	b.ne	LBB16_14
LBB16_16:                               ;   in Loop: Header=BB16_11 Depth=1
	add	x12, x12, #16
	cmp	w14, w12
	b.gt	LBB16_11
	b	LBB16_54
LBB16_17:
	negs	w12, w10
	and	w12, w12, #0xf
	and	w13, w10, #0xf
	csneg	w12, w13, w12, mi
	sub	w14, w10, w12
	cmp	w14, #1
	b.lt	LBB16_43
; %bb.18:
	mov	x12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
	mov	x15, x11
LBB16_19:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_22 Depth 2
	add	x16, x11, x12, lsl #1
	ldp	q0, q1, [x16]
	uaddl2.4s	v2, v0, v1
	uaddl.4s	v0, v0, v1
	uaddl2.2d	v1, v0, v2
	uaddl.2d	v0, v0, v2
	add.2d	v0, v0, v1
	addp.2d	d0, v0
	fmov	x16, d0
	sub	x17, x8, x13
	cmp	x16, x17
	b.ge	LBB16_21
; %bb.20:                               ;   in Loop: Header=BB16_19 Depth=1
	add	x13, x16, x13
	b	LBB16_24
LBB16_21:                               ;   in Loop: Header=BB16_19 Depth=1
	mov	x16, #0                         ; =0x0
	mov	x17, x15
LBB16_22:                               ;   Parent Loop BB16_19 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrh	w0, [x17], #2
	add	x13, x13, x0
	cmp	x13, x8
	b.ge	LBB16_39
; %bb.23:                               ;   in Loop: Header=BB16_22 Depth=2
	sub	x16, x16, #1
	cmn	x16, #16
	b.ne	LBB16_22
LBB16_24:                               ;   in Loop: Header=BB16_19 Depth=1
	add	x12, x12, #16
	add	x15, x15, #32
	cmp	w14, w12
	b.gt	LBB16_19
	b	LBB16_44
LBB16_25:
	negs	w12, w10
	and	w12, w12, #0xf
	and	w13, w10, #0xf
	csneg	w12, w13, w12, mi
	sub	w14, w10, w12
	cmp	w14, #1
	b.lt	LBB16_48
; %bb.26:
	mov	x12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
	mov	x15, x11
LBB16_27:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB16_28 Depth 2
                                        ;     Child Loop BB16_32 Depth 2
	mov	x16, #0                         ; =0x0
	movi.2d	v0, #0000000000000000
	movi.2d	v1, #0000000000000000
LBB16_28:                               ;   Parent Loop BB16_27 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	q2, [x15, x16]
	uaddw2.2d	v1, v1, v2
	uaddw.2d	v0, v0, v2
	add	x16, x16, #16
	cmp	x16, #64
	b.ne	LBB16_28
; %bb.29:                               ;   in Loop: Header=BB16_27 Depth=1
	add.2d	v0, v0, v1
	addp.2d	d0, v0
	fmov	x16, d0
	sub	x17, x8, x13
	cmp	x16, x17
	b.ge	LBB16_31
; %bb.30:                               ;   in Loop: Header=BB16_27 Depth=1
	add	x13, x16, x13
	b	LBB16_34
LBB16_31:                               ;   in Loop: Header=BB16_27 Depth=1
	mov	x16, #0                         ; =0x0
LBB16_32:                               ;   Parent Loop BB16_27 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	w17, [x15, x16, lsl #2]
	add	x13, x13, x17
	cmp	x13, x8
	b.ge	LBB16_40
; %bb.33:                               ;   in Loop: Header=BB16_32 Depth=2
	add	x16, x16, #1
	cmp	x16, #16
	b.ne	LBB16_32
LBB16_34:                               ;   in Loop: Header=BB16_27 Depth=1
	add	x12, x12, #16
	add	x15, x15, #64
	cmp	w14, w12
	b.gt	LBB16_27
	b	LBB16_49
LBB16_35:
	cmp	w10, #1
	b.lt	LBB16_58
; %bb.36:
	mov	x12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
LBB16_37:                               ; =>This Inner Loop Header: Depth=1
	ldr	x14, [x11, x12, lsl #3]
	eor	x15, x13, #0x7fffffffffffffff
	add	x13, x14, x13
	cmp	x14, x15
	ccmp	x13, x8, #0, le
	b.ge	LBB16_42
; %bb.38:                               ;   in Loop: Header=BB16_37 Depth=1
	add	x12, x12, #1
	cmp	x10, x12
	b.ne	LBB16_37
	b	LBB16_58
LBB16_39:
	sub	x12, x12, x16
	b	LBB16_42
LBB16_40:
	add	x12, x12, x16
	b	LBB16_42
LBB16_41:
	sub	x12, x12, x15
LBB16_42:
	ldr	w1, [x9, x12, lsl #2]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
	b	LBB16_59
LBB16_43:
	mov	w12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
LBB16_44:
	cmp	w12, w10
	b.ge	LBB16_58
; %bb.45:
	mov	w12, w12
LBB16_46:                               ; =>This Inner Loop Header: Depth=1
	ldrh	w14, [x11, x12, lsl #1]
	add	x13, x13, x14
	cmp	x13, x8
	b.ge	LBB16_42
; %bb.47:                               ;   in Loop: Header=BB16_46 Depth=1
	mov	x20, #0                         ; =0x0
	add	x12, x12, #1
	cmp	w10, w12
	b.gt	LBB16_46
	b	LBB16_59
LBB16_48:
	mov	w12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
LBB16_49:
	cmp	w12, w10
	b.ge	LBB16_58
; %bb.50:
	mov	w12, w12
LBB16_51:                               ; =>This Inner Loop Header: Depth=1
	ldr	w14, [x11, x12, lsl #2]
	add	x13, x13, x14
	cmp	x13, x8
	b.ge	LBB16_42
; %bb.52:                               ;   in Loop: Header=BB16_51 Depth=1
	mov	x20, #0                         ; =0x0
	add	x12, x12, #1
	cmp	w10, w12
	b.gt	LBB16_51
	b	LBB16_59
LBB16_53:
	mov	w12, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
LBB16_54:
	cmp	w12, w10
	b.ge	LBB16_58
; %bb.55:
	mov	w12, w12
LBB16_56:                               ; =>This Inner Loop Header: Depth=1
	ldrb	w14, [x11, x12]
	add	x13, x13, x14
	cmp	x13, x8
	b.ge	LBB16_42
; %bb.57:                               ;   in Loop: Header=BB16_56 Depth=1
	mov	x20, #0                         ; =0x0
	add	x12, x12, #1
	cmp	w10, w12
	b.gt	LBB16_56
	b	LBB16_59
LBB16_58:
	mov	x20, #0                         ; =0x0
LBB16_59:
	mov	x0, x19
	mov	x1, x20
	bl	_hdr_lowest_equivalent_value
	mov	x21, x0
	fcmp	d8, #0.0
	b.eq	LBB16_61
; %bb.60:
	mov	x0, x19
	mov	x1, x20
	bl	_hdr_size_of_equivalent_value_range
	eor	x8, x0, #0x7fffffffffffffff
	add	x9, x21, x0
	sub	x9, x9, #1
	mov	x10, #9223372036854775807       ; =0x7fffffffffffffff
	cmp	x21, x8
	csel	x21, x10, x9, gt
LBB16_61:
	mov	x0, x21
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
	mov	x26, x0
Lloh2:
	adrp	x8, ___stack_chk_guard@GOTPAGE
Lloh3:
	ldr	x8, [x8, ___stack_chk_guard@GOTPAGEOFF]
Lloh4:
	ldr	x8, [x8]
	stur	x8, [x29, #-112]
	mov	w0, #22                         ; =0x16
	cbz	x1, LBB17_111
; %bb.1:
	mov	x20, x2
	cbz	x2, LBB17_111
; %bb.2:
	mov	x19, x3
	cbz	x3, LBB17_110
; %bb.3:
	ldr	x27, [x26, #24]
	cbz	x27, LBB17_11
; %bb.4:
	mov	x21, x1
	ldr	x22, [x26]
	cmp	x19, #33
	b.lo	LBB17_12
; %bb.5:
	lsr	x8, x19, #61
	cbnz	x8, LBB17_10
; %bb.6:
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
	cbz	x25, LBB17_9
; %bb.7:
	cbz	x24, LBB17_9
; %bb.8:
	cbnz	x23, LBB17_13
LBB17_9:
	mov	x0, x25
	bl	_free
	mov	x0, x24
	bl	_free
	mov	x0, x23
	bl	_free
LBB17_10:
	mov	w0, #12                         ; =0xc
	b	LBB17_111
LBB17_11:
	lsl	x1, x19, #3
	mov	x0, x20
	bl	_bzero
	b	LBB17_110
LBB17_12:
	add	x25, sp, #576
	add	x24, sp, #320
	add	x23, sp, #64
LBB17_13:
	mov	x8, #0                          ; =0x0
	scvtf	d0, x27
	mov	x9, #4636737291354636288        ; =0x4059000000000000
	fmov	d1, x9
	fmov	d2, #0.50000000
	fmov	d3, #1.00000000
LBB17_14:                               ; =>This Inner Loop Header: Depth=1
	ldr	d4, [x21, x8, lsl #3]
	fminnm	d4, d4, d1
	fdiv	d4, d4, d1
	fmadd	d4, d4, d0, d2
	fcmp	d4, d3
	b.ge	LBB17_16
; %bb.15:                               ;   in Loop: Header=BB17_14 Depth=1
	mov	w9, #1                          ; =0x1
	b	LBB17_18
LBB17_16:                               ;   in Loop: Header=BB17_14 Depth=1
	fcmp	d4, d0
	mov	x9, x27
	b.ge	LBB17_18
; %bb.17:                               ;   in Loop: Header=BB17_14 Depth=1
	fcvtzs	x9, d4
LBB17_18:                               ;   in Loop: Header=BB17_14 Depth=1
	str	x9, [x25, x8, lsl #3]
	str	xzr, [x24, x8, lsl #3]
	str	x8, [x23, x8, lsl #3]
	add	x8, x8, #1
	cmp	x19, x8
	b.ne	LBB17_14
; %bb.19:
	cmp	x19, #1
	b.eq	LBB17_25
; %bb.20:
	add	x8, x23, #8
	mov	w9, #1                          ; =0x1
LBB17_21:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB17_22 Depth 2
	ldr	x10, [x23, x9, lsl #3]
	ldr	x12, [x25, x10, lsl #3]
	mov	x13, x8
	mov	x11, x9
LBB17_22:                               ;   Parent Loop BB17_21 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldur	x14, [x13, #-8]
	ldr	x15, [x25, x14, lsl #3]
	cmp	x15, x12
	b.le	LBB17_24
; %bb.23:                               ;   in Loop: Header=BB17_22 Depth=2
	str	x14, [x13], #-8
	sub	x11, x11, #1
	cbnz	x11, LBB17_22
LBB17_24:                               ;   in Loop: Header=BB17_21 Depth=1
	str	x10, [x23, x11, lsl #3]
	add	x9, x9, #1
	add	x8, x8, #8
	cmp	x9, x19
	b.ne	LBB17_21
LBB17_25:
	ldr	w10, [x26, #48]
	negs	w8, w10
	and	w8, w8, #0xf
	and	w9, w10, #0xf
	csneg	w8, w9, w8, mi
	sub	w12, w10, w8
	ldrb	w8, [x26, #60]
	ldp	x9, x11, [x26, #8]
	stp	x9, x20, [sp, #48]              ; 16-byte Folded Spill
	cmp	w8, #1
	stp	x10, x11, [sp, #32]             ; 16-byte Folded Spill
	b.eq	LBB17_56
; %bb.26:
	cmp	w8, #2
	b.eq	LBB17_43
; %bb.27:
	cmp	w8, #4
	b.ne	LBB17_69
; %bb.28:
	ldr	x8, [x23]
	ldr	x8, [x25, x8, lsl #3]
	cmp	w12, #1
	b.lt	LBB17_95
; %bb.29:
	mov	x14, #0                         ; =0x0
	mov	x28, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
	add	x20, x23, #8
	mov	x26, x11
	str	w12, [sp, #24]                  ; 4-byte Folded Spill
LBB17_30:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB17_31 Depth 2
                                        ;     Child Loop BB17_36 Depth 2
                                        ;       Child Loop BB17_39 Depth 3
	mov	x9, #0                          ; =0x0
	movi.2d	v0, #0000000000000000
	movi.2d	v1, #0000000000000000
LBB17_31:                               ;   Parent Loop BB17_30 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	q2, [x26, x9]
	uaddw2.2d	v1, v1, v2
	uaddw.2d	v0, v0, v2
	add	x9, x9, #16
	cmp	x9, #64
	b.ne	LBB17_31
; %bb.32:                               ;   in Loop: Header=BB17_30 Depth=1
	add.2d	v0, v0, v1
	addp.2d	d0, v0
	fmov	x9, d0
	add	x9, x9, x13
	cmp	x9, x8
	b.ge	LBB17_35
; %bb.33:                               ;   in Loop: Header=BB17_30 Depth=1
	mov	x13, x9
	mov	x27, x28
LBB17_34:                               ;   in Loop: Header=BB17_30 Depth=1
	add	x14, x14, #16
	add	x26, x26, #64
	mov	x28, x27
	cmp	w12, w14
	b.gt	LBB17_30
	b	LBB17_96
LBB17_35:                               ;   in Loop: Header=BB17_30 Depth=1
	mov	x16, #0                         ; =0x0
	str	x14, [sp, #8]                   ; 8-byte Folded Spill
LBB17_36:                               ;   Parent Loop BB17_30 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB17_39 Depth 3
	orr	x9, x16, x14
	ldr	w10, [x11, x9, lsl #2]
	add	x13, x13, x10
	cmp	x13, x8
	b.ge	LBB17_38
; %bb.37:                               ;   in Loop: Header=BB17_36 Depth=2
	mov	x27, x28
	b	LBB17_42
LBB17_38:                               ;   in Loop: Header=BB17_36 Depth=2
	str	x16, [sp, #16]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x9, lsl #2]
	mov	x0, x22
	mov	x27, x13
	bl	_hdr_value_at_index
	mov	x13, x27
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x9, [x23, x28, lsl #3]
LBB17_39:                               ;   Parent Loop BB17_30 Depth=1
                                        ;     Parent Loop BB17_36 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	str	x0, [x24, x9, lsl #3]
	add	x27, x28, #1
	cmp	x27, x19
	b.hs	LBB17_104
; %bb.40:                               ;   in Loop: Header=BB17_39 Depth=3
	ldr	x9, [x20, x28, lsl #3]
	ldr	x8, [x25, x9, lsl #3]
	mov	x28, x27
	cmp	x13, x8
	b.ge	LBB17_39
; %bb.41:                               ;   in Loop: Header=BB17_36 Depth=2
	mov	x28, x27
	ldr	w12, [sp, #24]                  ; 4-byte Folded Reload
	ldp	x14, x16, [sp, #8]              ; 16-byte Folded Reload
LBB17_42:                               ;   in Loop: Header=BB17_36 Depth=2
	add	x16, x16, #1
	cmp	x16, #16
	b.ne	LBB17_36
	b	LBB17_34
LBB17_43:
	ldr	x8, [x23]
	ldr	x8, [x25, x8, lsl #3]
	cmp	w12, #1
	b.lt	LBB17_77
; %bb.44:
	mov	x14, #0                         ; =0x0
	mov	x26, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
	add	x20, x23, #8
	str	w12, [sp, #24]                  ; 4-byte Folded Spill
LBB17_45:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB17_49 Depth 2
                                        ;       Child Loop BB17_52 Depth 3
	add	x9, x11, x14, lsl #1
	ldp	q0, q1, [x9]
	uaddl2.4s	v2, v0, v1
	uaddl.4s	v0, v0, v1
	uaddl2.2d	v1, v0, v2
	uaddl.2d	v0, v0, v2
	add.2d	v0, v0, v1
	addp.2d	d0, v0
	fmov	x9, d0
	add	x9, x9, x13
	cmp	x9, x8
	b.ge	LBB17_48
; %bb.46:                               ;   in Loop: Header=BB17_45 Depth=1
	mov	x13, x9
	mov	x27, x26
LBB17_47:                               ;   in Loop: Header=BB17_45 Depth=1
	add	x14, x14, #16
	mov	x26, x27
	cmp	w12, w14
	b.gt	LBB17_45
	b	LBB17_78
LBB17_48:                               ;   in Loop: Header=BB17_45 Depth=1
	mov	x28, #0                         ; =0x0
	str	x14, [sp, #16]                  ; 8-byte Folded Spill
LBB17_49:                               ;   Parent Loop BB17_45 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB17_52 Depth 3
	orr	x9, x28, x14
	ldrh	w10, [x11, x9, lsl #1]
	add	x13, x13, x10
	cmp	x13, x8
	b.ge	LBB17_51
; %bb.50:                               ;   in Loop: Header=BB17_49 Depth=2
	mov	x27, x26
	b	LBB17_55
LBB17_51:                               ;   in Loop: Header=BB17_49 Depth=2
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x9, lsl #2]
	mov	x0, x22
	mov	x27, x13
	bl	_hdr_value_at_index
	mov	x13, x27
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x9, [x23, x26, lsl #3]
LBB17_52:                               ;   Parent Loop BB17_45 Depth=1
                                        ;     Parent Loop BB17_49 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	str	x0, [x24, x9, lsl #3]
	add	x27, x26, #1
	cmp	x27, x19
	b.hs	LBB17_104
; %bb.53:                               ;   in Loop: Header=BB17_52 Depth=3
	ldr	x9, [x20, x26, lsl #3]
	ldr	x8, [x25, x9, lsl #3]
	mov	x26, x27
	cmp	x13, x8
	b.ge	LBB17_52
; %bb.54:                               ;   in Loop: Header=BB17_49 Depth=2
	mov	x26, x27
	ldr	w12, [sp, #24]                  ; 4-byte Folded Reload
	ldr	x14, [sp, #16]                  ; 8-byte Folded Reload
LBB17_55:                               ;   in Loop: Header=BB17_49 Depth=2
	add	x28, x28, #1
	cmp	x28, #16
	b.ne	LBB17_49
	b	LBB17_47
LBB17_56:
	ldr	x8, [x23]
	ldr	x8, [x25, x8, lsl #3]
	cmp	w12, #1
	b.lt	LBB17_86
; %bb.57:
	mov	x14, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
	mov	x27, #0                         ; =0x0
	add	x20, x23, #8
	str	w12, [sp, #24]                  ; 4-byte Folded Spill
LBB17_58:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB17_62 Depth 2
                                        ;       Child Loop BB17_65 Depth 3
	ldr	q0, [x11, x14]
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
	add	x9, x9, x13
	cmp	x9, x8
	b.ge	LBB17_61
; %bb.59:                               ;   in Loop: Header=BB17_58 Depth=1
	mov	x26, x27
	mov	x13, x9
LBB17_60:                               ;   in Loop: Header=BB17_58 Depth=1
	add	x14, x14, #16
	mov	x27, x26
	cmp	w12, w14
	b.gt	LBB17_58
	b	LBB17_87
LBB17_61:                               ;   in Loop: Header=BB17_58 Depth=1
	mov	x28, #0                         ; =0x0
	str	x14, [sp, #16]                  ; 8-byte Folded Spill
LBB17_62:                               ;   Parent Loop BB17_58 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB17_65 Depth 3
	orr	x9, x28, x14
	ldrb	w10, [x11, x9]
	add	x13, x13, x10
	cmp	x13, x8
	b.ge	LBB17_64
; %bb.63:                               ;   in Loop: Header=BB17_62 Depth=2
	mov	x26, x27
	b	LBB17_68
LBB17_64:                               ;   in Loop: Header=BB17_62 Depth=2
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x9, lsl #2]
	mov	x0, x22
	mov	x26, x13
	bl	_hdr_value_at_index
	mov	x13, x26
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x9, [x23, x27, lsl #3]
LBB17_65:                               ;   Parent Loop BB17_58 Depth=1
                                        ;     Parent Loop BB17_62 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	str	x0, [x24, x9, lsl #3]
	add	x26, x27, #1
	cmp	x26, x19
	b.hs	LBB17_104
; %bb.66:                               ;   in Loop: Header=BB17_65 Depth=3
	ldr	x9, [x20, x27, lsl #3]
	ldr	x8, [x25, x9, lsl #3]
	mov	x27, x26
	cmp	x13, x8
	b.ge	LBB17_65
; %bb.67:                               ;   in Loop: Header=BB17_62 Depth=2
	mov	x27, x26
	ldr	w12, [sp, #24]                  ; 4-byte Folded Reload
	ldr	x14, [sp, #16]                  ; 8-byte Folded Reload
LBB17_68:                               ;   in Loop: Header=BB17_62 Depth=2
	add	x28, x28, #1
	cmp	x28, #16
	b.ne	LBB17_62
	b	LBB17_60
LBB17_69:
	ldr	x8, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w8, #0
	b.le	LBB17_104
; %bb.70:
	mov	x26, #0                         ; =0x0
	mov	x27, #0                         ; =0x0
	mov	x12, #0                         ; =0x0
	mov	x28, x23
	ldr	x8, [x28], #8
	ldr	x8, [x25, x8, lsl #3]
	mov	x13, #9223372036854775807       ; =0x7fffffffffffffff
LBB17_71:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB17_73 Depth 2
	ldr	x9, [x11, x26, lsl #3]
	eor	x10, x12, #0x7fffffffffffffff
	add	x12, x9, x12
	cmp	x9, x10
	csel	x20, x13, x12, gt
	cmp	x20, x8
	b.lt	LBB17_76
; %bb.72:                               ;   in Loop: Header=BB17_71 Depth=1
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x26, lsl #2]
	mov	x0, x22
	str	x12, [sp, #24]                  ; 8-byte Folded Spill
	bl	_hdr_value_at_index
	mov	x13, #9223372036854775807       ; =0x7fffffffffffffff
	ldr	x12, [sp, #24]                  ; 8-byte Folded Reload
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x10, [x23, x27, lsl #3]
LBB17_73:                               ;   Parent Loop BB17_71 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	x0, [x24, x10, lsl #3]
	add	x9, x27, #1
	cmp	x9, x19
	b.hs	LBB17_104
; %bb.74:                               ;   in Loop: Header=BB17_73 Depth=2
	ldr	x10, [x28, x27, lsl #3]
	ldr	x8, [x25, x10, lsl #3]
	mov	x27, x9
	cmp	x20, x8
	b.ge	LBB17_73
; %bb.75:                               ;   in Loop: Header=BB17_71 Depth=1
	mov	x27, x9
LBB17_76:                               ;   in Loop: Header=BB17_71 Depth=1
	add	x26, x26, #1
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	x26, x9
	b.ne	LBB17_71
	b	LBB17_104
LBB17_77:
	mov	x13, #0                         ; =0x0
	mov	x27, #0                         ; =0x0
	mov	w14, #0                         ; =0x0
LBB17_78:
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w14, w9
	b.ge	LBB17_104
; %bb.79:
	mov	x10, x14
	mov	w26, w10
	add	x28, x23, #8
LBB17_80:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB17_82 Depth 2
	ldrh	w9, [x11, x26, lsl #1]
	add	x13, x13, x9
	cmp	x13, x8
	b.lt	LBB17_85
; %bb.81:                               ;   in Loop: Header=BB17_80 Depth=1
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x26, lsl #2]
	mov	x0, x22
	mov	x20, x13
	bl	_hdr_value_at_index
	mov	x13, x20
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x10, [x23, x27, lsl #3]
LBB17_82:                               ;   Parent Loop BB17_80 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	x0, [x24, x10, lsl #3]
	add	x9, x27, #1
	cmp	x9, x19
	b.hs	LBB17_104
; %bb.83:                               ;   in Loop: Header=BB17_82 Depth=2
	ldr	x10, [x28, x27, lsl #3]
	ldr	x8, [x25, x10, lsl #3]
	mov	x27, x9
	cmp	x13, x8
	b.ge	LBB17_82
; %bb.84:                               ;   in Loop: Header=BB17_80 Depth=1
	mov	x27, x9
LBB17_85:                               ;   in Loop: Header=BB17_80 Depth=1
	add	x26, x26, #1
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w9, w26
	b.gt	LBB17_80
	b	LBB17_104
LBB17_86:
	mov	w14, #0                         ; =0x0
	mov	x26, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
LBB17_87:
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w14, w9
	b.ge	LBB17_104
; %bb.88:
	mov	x10, x14
	mov	w27, w10
	add	x28, x23, #8
LBB17_89:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB17_91 Depth 2
	ldrb	w9, [x11, x27]
	add	x13, x13, x9
	cmp	x13, x8
	b.lt	LBB17_94
; %bb.90:                               ;   in Loop: Header=BB17_89 Depth=1
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x27, lsl #2]
	mov	x0, x22
	mov	x20, x13
	bl	_hdr_value_at_index
	mov	x13, x20
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x10, [x23, x26, lsl #3]
LBB17_91:                               ;   Parent Loop BB17_89 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	x0, [x24, x10, lsl #3]
	add	x9, x26, #1
	cmp	x9, x19
	b.hs	LBB17_104
; %bb.92:                               ;   in Loop: Header=BB17_91 Depth=2
	ldr	x10, [x28, x26, lsl #3]
	ldr	x8, [x25, x10, lsl #3]
	mov	x26, x9
	cmp	x13, x8
	b.ge	LBB17_91
; %bb.93:                               ;   in Loop: Header=BB17_89 Depth=1
	mov	x26, x9
LBB17_94:                               ;   in Loop: Header=BB17_89 Depth=1
	add	x27, x27, #1
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w9, w27
	b.gt	LBB17_89
	b	LBB17_104
LBB17_95:
	mov	x13, #0                         ; =0x0
	mov	x27, #0                         ; =0x0
	mov	w14, #0                         ; =0x0
LBB17_96:
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w14, w9
	b.ge	LBB17_104
; %bb.97:
	mov	x10, x14
	mov	w26, w10
	add	x28, x23, #8
LBB17_98:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB17_100 Depth 2
	ldr	w9, [x11, x26, lsl #2]
	add	x13, x13, x9
	cmp	x13, x8
	b.lt	LBB17_103
; %bb.99:                               ;   in Loop: Header=BB17_98 Depth=1
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	ldr	w1, [x8, x26, lsl #2]
	mov	x0, x22
	mov	x20, x13
	bl	_hdr_value_at_index
	mov	x13, x20
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	ldr	x10, [x23, x27, lsl #3]
LBB17_100:                              ;   Parent Loop BB17_98 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	str	x0, [x24, x10, lsl #3]
	add	x9, x27, #1
	cmp	x9, x19
	b.hs	LBB17_104
; %bb.101:                              ;   in Loop: Header=BB17_100 Depth=2
	ldr	x10, [x28, x27, lsl #3]
	ldr	x8, [x25, x10, lsl #3]
	mov	x27, x9
	cmp	x13, x8
	b.ge	LBB17_100
; %bb.102:                              ;   in Loop: Header=BB17_98 Depth=1
	mov	x27, x9
LBB17_103:                              ;   in Loop: Header=BB17_98 Depth=1
	add	x26, x26, #1
	ldr	x9, [sp, #32]                   ; 8-byte Folded Reload
	cmp	w9, w26
	b.gt	LBB17_98
LBB17_104:
	mov	x28, #0                         ; =0x0
	mov	x20, #9223372036854775807       ; =0x7fffffffffffffff
LBB17_105:                              ; =>This Inner Loop Header: Depth=1
	ldr	d8, [x21, x28, lsl #3]
	ldr	x27, [x24, x28, lsl #3]
	mov	x0, x22
	mov	x1, x27
	bl	_hdr_lowest_equivalent_value
	mov	x26, x0
	fcmp	d8, #0.0
	b.eq	LBB17_107
; %bb.106:                              ;   in Loop: Header=BB17_105 Depth=1
	mov	x0, x22
	mov	x1, x27
	bl	_hdr_size_of_equivalent_value_range
	eor	x8, x0, #0x7fffffffffffffff
	add	x9, x26, x0
	sub	x9, x9, #1
	cmp	x26, x8
	csel	x26, x20, x9, gt
LBB17_107:                              ;   in Loop: Header=BB17_105 Depth=1
	ldr	x8, [sp, #56]                   ; 8-byte Folded Reload
	str	x26, [x8, x28, lsl #3]
	add	x28, x28, #1
	cmp	x19, x28
	b.ne	LBB17_105
; %bb.108:
	cmp	x19, #32
	b.ls	LBB17_110
; %bb.109:
	mov	x0, x25
	bl	_free
	mov	x0, x24
	bl	_free
	mov	x0, x23
	bl	_free
LBB17_110:
	mov	w0, #0                          ; =0x0
LBB17_111:
	ldur	x8, [x29, #-112]
Lloh5:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh6:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh7:
	ldr	x9, [x9]
	cmp	x9, x8
	b.ne	LBB17_113
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
LBB17_113:
	bl	___stack_chk_fail
	.loh AdrpLdrGotLdr	Lloh2, Lloh3, Lloh4
	.loh AdrpLdrGotLdr	Lloh5, Lloh6, Lloh7
	.cfi_endproc
