	.build_version macos, 27, 0	sdk_version 27, 0
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_counts_index_for               ; -- Begin function counts_index_for
	.p2align	2
_counts_index_for:                      ; @counts_index_for
	.cfi_startproc
; %bb.0:
	ldr	x8, [x0, #32]
	orr	x8, x8, x1
	clz	x8, x8
	ldr	w9, [x0, #16]
	ldp	w10, w11, [x0, #24]
	add	w12, w10, w9
	add	w8, w12, w8
	sub	w9, w9, w8
	add	w9, w9, #63
	asr	x9, x1, x9
	mov	w12, #64                        ; =0x40
	sub	w8, w12, w8
	lsl	w8, w8, w10
	sub	w8, w8, w11
	add	w0, w8, w9
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_value_at_index             ; -- Begin function hdr_value_at_index
	.p2align	2
_hdr_value_at_index:                    ; @hdr_value_at_index
	.cfi_startproc
; %bb.0:
	ldp	w8, w9, [x0, #24]
	asr	w8, w1, w8
	sub	w10, w9, #1
	and	w10, w10, w1
	cmp	w8, #1
	csinc	w11, w8, wzr, gt
	ldr	w12, [x0, #16]
	add	w11, w11, w12
	cmp	w8, #0
	csel	w8, w9, wzr, gt
	add	w8, w10, w8
	sxtw	x8, w8
	sub	w9, w11, #1
	lsl	x0, x8, x9
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_size_of_equivalent_value_range ; -- Begin function hdr_size_of_equivalent_value_range
	.p2align	2
_hdr_size_of_equivalent_value_range:    ; @hdr_size_of_equivalent_value_range
	.cfi_startproc
; %bb.0:
	ldr	x8, [x0, #32]
	orr	x8, x8, x1
	clz	x8, x8
	ldr	w9, [x0, #16]
	ldr	w10, [x0, #24]
	add	w10, w9, w10
	sub	w9, w9, w10
	sub	w8, w9, w8
	add	w8, w8, #63
	asr	x9, x1, x8
	ldr	w10, [x0, #40]
	cmp	w10, w9
	cinc	w8, w8, le
	mov	w9, #1                          ; =0x1
	lsl	x0, x9, x8
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_next_non_equivalent_value  ; -- Begin function hdr_next_non_equivalent_value
	.p2align	2
_hdr_next_non_equivalent_value:         ; @hdr_next_non_equivalent_value
	.cfi_startproc
; %bb.0:
	ldr	x8, [x0, #32]
	orr	x8, x8, x1
	clz	x8, x8
	ldr	w9, [x0, #24]
	mov	w10, #63                        ; =0x3f
	add	w8, w9, w8
	sub	w9, w10, w8
	mvn	w8, w8
	asr	x10, x1, x8
	sxtw	x10, w10
	lsl	x8, x10, x8
	ldr	w11, [x0, #40]
	cmp	w11, w10
	cinc	w9, w9, le
	mov	w10, #1                         ; =0x1
	lsl	x9, x10, x9
	eor	x10, x9, #0x7fffffffffffffff
	add	x9, x9, x8
	mov	x11, #9223372036854775807       ; =0x7fffffffffffffff
	cmp	x8, x10
	csel	x0, x11, x9, gt
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_median_equivalent_value    ; -- Begin function hdr_median_equivalent_value
	.p2align	2
_hdr_median_equivalent_value:           ; @hdr_median_equivalent_value
	.cfi_startproc
; %bb.0:
	ldr	x8, [x0, #32]
	orr	x8, x8, x1
	clz	x8, x8
	ldr	w9, [x0, #24]
	mov	w10, #63                        ; =0x3f
	add	w8, w9, w8
	sub	w9, w10, w8
	mvn	w8, w8
	asr	x10, x1, x8
	sxtw	x10, w10
	lsl	x8, x10, x8
	ldr	w11, [x0, #40]
	cmp	w11, w10
	cinc	w9, w9, le
	mov	w10, #1                         ; =0x1
	lsl	x9, x10, x9
	add	x0, x8, x9, asr #1
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_reset_internal_counters_checked ; -- Begin function hdr_reset_internal_counters_checked
	.p2align	2
_hdr_reset_internal_counters_checked:   ; @hdr_reset_internal_counters_checked
	.cfi_startproc
; %bb.0:
	ldr	w13, [x0, #80]
	cmp	w13, #0
	b.le	LBB5_5
; %bb.1:
	ldr	w16, [x0, #64]
	ldr	x8, [x0, #96]
	cbz	w16, LBB5_6
; %bb.2:
	neg	w14, w13
	cmn	w13, w16
	csel	w9, wzr, w14, gt
	cmp	w16, #0
	csel	w9, w13, w9, gt
	sub	w9, w9, w16
	ldr	x9, [x8, w9, sxtw #3]
	cmp	x9, #1
	csel	x9, xzr, x9, lt
	csetm	w12, lt
	cmp	w13, #1
	b.eq	LBB5_7
; %bb.3:
	sub	w11, w13, #1
	sub	w10, w13, #2
	and	w15, w11, #0x7
	mov	w1, #1                          ; =0x1
	cmp	w10, #7
	b.hs	LBB5_15
; %bb.4:
	mov	w10, #0                         ; =0x0
	mov	w11, #-1                        ; =0xffffffff
	cbnz	w15, LBB5_34
	b	LBB5_8
LBB5_5:
	mov	x9, #0                          ; =0x0
	mov	w10, #0                         ; =0x0
	mov	x8, #9223372036854775807        ; =0x7fffffffffffffff
	stp	x8, xzr, [x0, #48]
	str	x9, [x0, #88]
	mov	w8, #1                          ; =0x1
	bic	w0, w8, w10
	ret
LBB5_6:
	ldr	x9, [x8]
	cmp	x9, #1
	csel	x9, xzr, x9, lt
	csetm	w12, lt
	cmp	w13, #1
	b.ne	LBB5_13
LBB5_7:
	mov	w10, #0                         ; =0x0
	mov	w11, #-1                        ; =0xffffffff
LBB5_8:
	cmn	w12, #1
	b.eq	LBB5_11
; %bb.9:
	ldp	w8, w13, [x0, #24]
	asr	w14, w12, w8
	sub	w15, w13, #1
	and	w12, w15, w12
	cmp	w14, #1
	csinc	w15, w14, wzr, gt
	ldr	w16, [x0, #16]
	add	w15, w15, w16
	cmp	w14, #0
	csel	w13, w13, wzr, gt
	add	w12, w12, w13
	sxtw	x12, w12
	sub	w13, w15, #1
	lsl	x12, x12, x13
	ldr	x13, [x0, #32]
	orr	x13, x12, x13
	clz	x13, x13
	mov	w14, #63                        ; =0x3f
	add	w8, w8, w13
	sub	w13, w14, w8
	mvn	w8, w8
	asr	x12, x12, x8
	sxtw	x12, w12
	lsl	x8, x12, x8
	ldr	w14, [x0, #40]
	cmp	w14, w12
	cinc	w12, w13, le
	mov	w13, #1                         ; =0x1
	lsl	x12, x13, x12
	eor	x13, x12, #0x7fffffffffffffff
	add	x12, x8, x12
	sub	x12, x12, #1
	mov	x14, #9223372036854775807       ; =0x7fffffffffffffff
	cmp	x8, x13
	csel	x8, x14, x12, gt
	str	x8, [x0, #56]
	cmn	w11, #1
	b.eq	LBB5_12
LBB5_10:
	ldp	w8, w12, [x0, #24]
	asr	w8, w11, w8
	sub	w13, w12, #1
	and	w11, w13, w11
	cmp	w8, #1
	csinc	w13, w8, wzr, gt
	ldr	w14, [x0, #16]
	add	w13, w13, w14
	cmp	w8, #0
	csel	w8, w12, wzr, gt
	add	w8, w11, w8
	sxtw	x8, w8
	sub	w11, w13, #1
	lsl	x8, x8, x11
	str	x8, [x0, #48]
	str	x9, [x0, #88]
	mov	w8, #1                          ; =0x1
	bic	w0, w8, w10
	ret
LBB5_11:
	mov	x8, #0                          ; =0x0
	str	x8, [x0, #56]
	cmn	w11, #1
	b.ne	LBB5_10
LBB5_12:
	mov	x8, #9223372036854775807        ; =0x7fffffffffffffff
	str	x8, [x0, #48]
	str	x9, [x0, #88]
	mov	w8, #1                          ; =0x1
	bic	w0, w8, w10
	ret
LBB5_13:
	sub	x11, x13, #1
	and	x14, x11, #0x7
	sub	w10, w13, #2
	cmp	w10, #7
	b.hs	LBB5_38
; %bb.14:
	mov	w10, #0                         ; =0x0
	mov	w11, #-1                        ; =0xffffffff
	mov	w13, #1                         ; =0x1
	cbnz	x14, LBB5_41
	b	LBB5_8
LBB5_15:
	mov	x4, #0                          ; =0x0
	mov	w10, #0                         ; =0x0
	neg	w17, w16
	sub	w1, w1, w16
	sxtw	x1, w1
	and	x2, x11, #0xfffffff8
	mov	w11, #-1                        ; =0xffffffff
	mov	x3, #9223372036854775807        ; =0x7fffffffffffffff
	b	LBB5_17
LBB5_16:                                ;   in Loop: Header=BB5_17 Depth=1
	mov	x4, x5
	cmp	w2, w5
	b.eq	LBB5_33
LBB5_17:                                ; =>This Inner Loop Header: Depth=1
	add	w5, w17, w4
	add	w5, w5, #1
	cmp	w5, w13
	csel	w6, wzr, w14, lt
	cmp	w5, #0
	csel	w5, w13, w6, lt
	add	x6, x1, x4
	add	x5, x6, w5, sxtw
	ldr	x5, [x8, x5, lsl #3]
	cmp	x5, #1
	b.lt	LBB5_19
; %bb.18:                               ;   in Loop: Header=BB5_17 Depth=1
	add	x12, x4, #1
	eor	x6, x9, #0x7fffffffffffffff
	add	x9, x5, x9
	cmp	x5, x6
	csel	x9, x3, x9, hi
	cset	w5, hi
	orr	w10, w5, w10
	cmn	w11, #1
	csel	w11, w12, w11, eq
LBB5_19:                                ;   in Loop: Header=BB5_17 Depth=1
	add	w5, w17, w4
	add	w5, w5, #2
	cmp	w5, w13
	csel	w6, wzr, w14, lt
	cmp	w5, #0
	csel	w6, w13, w6, lt
	add	w5, w5, w6
	ldr	x5, [x8, w5, sxtw #3]
	cmp	x5, #1
	b.lt	LBB5_21
; %bb.20:                               ;   in Loop: Header=BB5_17 Depth=1
	add	x12, x4, #2
	eor	x6, x9, #0x7fffffffffffffff
	add	x9, x5, x9
	cmp	x5, x6
	csel	x9, x3, x9, hi
	cset	w5, hi
	orr	w10, w5, w10
	cmn	w11, #1
	csel	w11, w12, w11, eq
                                        ; kill: def $w12 killed $w12 killed $x12 def $x12
LBB5_21:                                ;   in Loop: Header=BB5_17 Depth=1
	add	w5, w17, w4
	add	w5, w5, #3
	cmp	w5, w13
	csel	w6, wzr, w14, lt
	cmp	w5, #0
	csel	w6, w13, w6, lt
	add	w5, w5, w6
	ldr	x5, [x8, w5, sxtw #3]
	cmp	x5, #1
	b.lt	LBB5_23
; %bb.22:                               ;   in Loop: Header=BB5_17 Depth=1
	add	x12, x4, #3
	eor	x6, x9, #0x7fffffffffffffff
	add	x9, x5, x9
	cmp	x5, x6
	csel	x9, x3, x9, hi
	cset	w5, hi
	orr	w10, w5, w10
	cmn	w11, #1
	csel	w11, w12, w11, eq
                                        ; kill: def $w12 killed $w12 killed $x12 def $x12
LBB5_23:                                ;   in Loop: Header=BB5_17 Depth=1
	add	w5, w17, w4
	add	w5, w5, #4
	cmp	w5, w13
	csel	w6, wzr, w14, lt
	cmp	w5, #0
	csel	w6, w13, w6, lt
	add	w5, w5, w6
	ldr	x5, [x8, w5, sxtw #3]
	cmp	x5, #1
	b.lt	LBB5_25
; %bb.24:                               ;   in Loop: Header=BB5_17 Depth=1
	add	x12, x4, #4
	eor	x6, x9, #0x7fffffffffffffff
	add	x9, x5, x9
	cmp	x5, x6
	csel	x9, x3, x9, hi
	cset	w5, hi
	orr	w10, w5, w10
	cmn	w11, #1
	csel	w11, w12, w11, eq
                                        ; kill: def $w12 killed $w12 killed $x12 def $x12
LBB5_25:                                ;   in Loop: Header=BB5_17 Depth=1
	add	w5, w17, w4
	add	w5, w5, #5
	cmp	w5, w13
	csel	w6, wzr, w14, lt
	cmp	w5, #0
	csel	w6, w13, w6, lt
	add	w5, w5, w6
	ldr	x5, [x8, w5, sxtw #3]
	cmp	x5, #1
	b.lt	LBB5_27
; %bb.26:                               ;   in Loop: Header=BB5_17 Depth=1
	add	x12, x4, #5
	eor	x6, x9, #0x7fffffffffffffff
	add	x9, x5, x9
	cmp	x5, x6
	csel	x9, x3, x9, hi
	cset	w5, hi
	orr	w10, w5, w10
	cmn	w11, #1
	csel	w11, w12, w11, eq
                                        ; kill: def $w12 killed $w12 killed $x12 def $x12
LBB5_27:                                ;   in Loop: Header=BB5_17 Depth=1
	add	w5, w17, w4
	add	w5, w5, #6
	cmp	w5, w13
	csel	w6, wzr, w14, lt
	cmp	w5, #0
	csel	w6, w13, w6, lt
	add	w5, w5, w6
	ldr	x5, [x8, w5, sxtw #3]
	cmp	x5, #1
	b.lt	LBB5_29
; %bb.28:                               ;   in Loop: Header=BB5_17 Depth=1
	add	x12, x4, #6
	eor	x6, x9, #0x7fffffffffffffff
	add	x9, x5, x9
	cmp	x5, x6
	csel	x9, x3, x9, hi
	cset	w5, hi
	orr	w10, w5, w10
	cmn	w11, #1
	csel	w11, w12, w11, eq
                                        ; kill: def $w12 killed $w12 killed $x12 def $x12
LBB5_29:                                ;   in Loop: Header=BB5_17 Depth=1
	add	w5, w17, w4
	add	w5, w5, #7
	cmp	w5, w13
	csel	w6, wzr, w14, lt
	cmp	w5, #0
	csel	w6, w13, w6, lt
	add	w5, w5, w6
	ldr	x5, [x8, w5, sxtw #3]
	cmp	x5, #1
	b.lt	LBB5_31
; %bb.30:                               ;   in Loop: Header=BB5_17 Depth=1
	add	x12, x4, #7
	eor	x6, x9, #0x7fffffffffffffff
	add	x9, x5, x9
	cmp	x5, x6
	csel	x9, x3, x9, hi
	cset	w5, hi
	orr	w10, w5, w10
	cmn	w11, #1
	csel	w11, w12, w11, eq
                                        ; kill: def $w12 killed $w12 killed $x12 def $x12
LBB5_31:                                ;   in Loop: Header=BB5_17 Depth=1
	add	x5, x4, #8
	add	w4, w17, w4
	add	w4, w4, #8
	cmp	w4, w13
	csel	w6, wzr, w14, lt
	cmp	w4, #0
	csel	w6, w13, w6, lt
	add	w4, w4, w6
	ldr	x4, [x8, w4, sxtw #3]
	cmp	x4, #1
	b.lt	LBB5_16
; %bb.32:                               ;   in Loop: Header=BB5_17 Depth=1
	eor	x12, x9, #0x7fffffffffffffff
	add	x9, x4, x9
	cmp	x4, x12
	csel	x9, x3, x9, hi
	cset	w12, hi
	orr	w10, w12, w10
	cmn	w11, #1
	csel	w11, w5, w11, eq
	mov	x12, x5
	b	LBB5_16
LBB5_33:
	add	w1, w5, #1
	cbz	w15, LBB5_8
LBB5_34:
	neg	w16, w16
	mov	x17, #9223372036854775807       ; =0x7fffffffffffffff
	b	LBB5_36
LBB5_35:                                ;   in Loop: Header=BB5_36 Depth=1
	add	w1, w1, #1
	subs	w15, w15, #1
	b.eq	LBB5_8
LBB5_36:                                ; =>This Inner Loop Header: Depth=1
	add	w2, w16, w1
	cmp	w2, w13
	csel	w3, wzr, w14, lt
	cmp	w2, #0
	csel	w3, w13, w3, lt
	add	w2, w2, w3
	ldr	x2, [x8, w2, sxtw #3]
	cmp	x2, #1
	b.lt	LBB5_35
; %bb.37:                               ;   in Loop: Header=BB5_36 Depth=1
	eor	x12, x9, #0x7fffffffffffffff
	add	x9, x2, x9
	cmp	x2, x12
	csel	x9, x17, x9, hi
	cset	w12, hi
	orr	w10, w12, w10
	cmn	w11, #1
	csel	w11, w1, w11, eq
	mov	x12, x1
	b	LBB5_35
LBB5_38:
	mov	w10, #0                         ; =0x0
	mov	x13, #0                         ; =0x0
	and	x15, x11, #0xfffffffffffffff8
	add	x16, x8, #32
	mov	w11, #-1                        ; =0xffffffff
	mov	x17, #9223372036854775807       ; =0x7fffffffffffffff
LBB5_39:                                ; =>This Inner Loop Header: Depth=1
	eor	x1, x9, #0x7fffffffffffffff
	ldp	x2, x3, [x16, #-24]
	add	x4, x2, x9
	cmp	x2, x1
	csel	x1, x17, x4, hi
	cset	w4, hi
	orr	w4, w4, w10
	cmn	w11, #1
	csinc	w5, w11, w13, ne
	cmp	x2, #1
	csel	x9, x9, x1, lt
	csinc	w12, w12, w13, lt
	csel	w11, w11, w5, lt
	csel	w10, w10, w4, lt
	eor	x1, x9, #0x7fffffffffffffff
	add	x2, x3, x9
	cmp	x3, x1
	csel	x1, x17, x2, hi
	cset	w2, hi
	orr	w2, w2, w10
	add	w4, w13, #2
	cmn	w11, #1
	csel	w5, w4, w11, eq
	cmp	x3, #1
	csel	x9, x9, x1, lt
	csel	w12, w12, w4, lt
	csel	w11, w11, w5, lt
	csel	w10, w10, w2, lt
	eor	x1, x9, #0x7fffffffffffffff
	ldp	x2, x3, [x16, #-8]
	add	x4, x2, x9
	cmp	x2, x1
	csel	x1, x17, x4, hi
	cset	w4, hi
	orr	w4, w4, w10
	add	w5, w13, #3
	cmn	w11, #1
	csel	w6, w5, w11, eq
	cmp	x2, #1
	csel	x9, x9, x1, lt
	csel	w12, w12, w5, lt
	csel	w11, w11, w6, lt
	csel	w10, w10, w4, lt
	eor	x1, x9, #0x7fffffffffffffff
	add	x2, x3, x9
	cmp	x3, x1
	csel	x1, x17, x2, hi
	cset	w2, hi
	orr	w2, w2, w10
	add	w4, w13, #4
	cmn	w11, #1
	csel	w5, w4, w11, eq
	cmp	x3, #1
	csel	x9, x9, x1, lt
	csel	w12, w12, w4, lt
	csel	w11, w11, w5, lt
	csel	w10, w10, w2, lt
	eor	x1, x9, #0x7fffffffffffffff
	ldp	x2, x3, [x16, #8]
	add	x4, x2, x9
	cmp	x2, x1
	csel	x1, x17, x4, hi
	cset	w4, hi
	orr	w4, w4, w10
	add	w5, w13, #5
	cmn	w11, #1
	csel	w6, w5, w11, eq
	cmp	x2, #1
	csel	x9, x9, x1, lt
	csel	w12, w12, w5, lt
	csel	w11, w11, w6, lt
	csel	w10, w10, w4, lt
	eor	x1, x9, #0x7fffffffffffffff
	add	x2, x3, x9
	cmp	x3, x1
	csel	x1, x17, x2, hi
	cset	w2, hi
	orr	w2, w2, w10
	add	w4, w13, #6
	cmn	w11, #1
	csel	w5, w4, w11, eq
	cmp	x3, #1
	csel	x9, x9, x1, lt
	csel	w12, w12, w4, lt
	csel	w11, w11, w5, lt
	csel	w10, w10, w2, lt
	eor	x1, x9, #0x7fffffffffffffff
	ldp	x2, x3, [x16, #24]
	add	x4, x2, x9
	cmp	x2, x1
	csel	x1, x17, x4, hi
	cset	w4, hi
	orr	w4, w4, w10
	add	w5, w13, #7
	cmn	w11, #1
	csel	w6, w5, w11, eq
	cmp	x2, #1
	csel	x9, x9, x1, lt
	csel	w12, w12, w5, lt
	csel	w11, w11, w6, lt
	csel	w10, w10, w4, lt
	eor	x1, x9, #0x7fffffffffffffff
	add	x2, x3, x9
	cmp	x3, x1
	csel	x1, x17, x2, hi
	cset	w2, hi
	orr	w2, w2, w10
	add	w4, w13, #8
	cmn	w11, #1
	csel	w5, w4, w11, eq
	cmp	x3, #1
	csel	x9, x9, x1, lt
	csel	w12, w12, w4, lt
	csel	w11, w11, w5, lt
	csel	w10, w10, w2, lt
	add	x13, x13, #8
	add	x16, x16, #64
	cmp	x15, x13
	b.ne	LBB5_39
; %bb.40:
	add	x13, x13, #1
	cbz	x14, LBB5_8
LBB5_41:
	mov	x15, #9223372036854775807       ; =0x7fffffffffffffff
LBB5_42:                                ; =>This Inner Loop Header: Depth=1
	ldr	x16, [x8, x13, lsl #3]
	eor	x17, x9, #0x7fffffffffffffff
	add	x1, x16, x9
	cmp	x16, x17
	csel	x17, x15, x1, hi
	cset	w1, hi
	orr	w1, w1, w10
	cmn	w11, #1
	csel	w2, w13, w11, eq
	cmp	x16, #1
	csel	x9, x9, x17, lt
	csel	w12, w12, w13, lt
	csel	w11, w11, w2, lt
	csel	w10, w10, w1, lt
	add	x13, x13, #1
	subs	x14, x14, #1
	b.ne	LBB5_42
	b	LBB5_8
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_reset_internal_counters    ; -- Begin function hdr_reset_internal_counters
	.p2align	2
_hdr_reset_internal_counters:           ; @hdr_reset_internal_counters
	.cfi_startproc
; %bb.0:
	b	_hdr_reset_internal_counters_checked
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_calculate_bucket_config    ; -- Begin function hdr_calculate_bucket_config
	.p2align	2
_hdr_calculate_bucket_config:           ; @hdr_calculate_bucket_config
	.cfi_startproc
; %bb.0:
	movi.2d	v0, #0000000000000000
	stp	q0, q0, [x3, #32]
	stp	q0, q0, [x3]
	sub	w8, w2, #6
	add	x9, x1, x1, lsr #63
	cmp	x0, x9, asr #1
	ccmp	x0, #1, #8, le
	ccmn	w8, #5, #0, ge
	b.hs	LBB7_2
; %bb.1:
	mov	w0, #22                         ; =0x16
	ret
LBB7_2:
	stp	d9, d8, [sp, #-80]!             ; 16-byte Folded Spill
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
	.cfi_offset b8, -72
	.cfi_offset b9, -80
	mov	x19, x3
	mov	x20, x0
	mov	w8, w2
	str	x8, [x3, #24]
	stp	x0, x1, [x3]
	sub	w8, w2, #1
	mov	x22, x1
	cmp	w8, #3
	b.hi	LBB7_4
; %bb.3:
Lloh0:
	adrp	x9, l_switch.table.hdr_calculate_bucket_config@PAGE
Lloh1:
	add	x9, x9, l_switch.table.hdr_calculate_bucket_config@PAGEOFF
	ldr	d0, [x9, w8, uxtw #3]
	b	LBB7_5
LBB7_4:
	mov	x8, #116548232544256            ; =0x6a0000000000
	movk	x8, #16648, lsl #48
	fmov	d0, x8
LBB7_5:
	bl	_log
	mov	x8, #14831                      ; =0x39ef
	movk	x8, #65274, lsl #16
	movk	x8, #11842, lsl #32
	movk	x8, #16358, lsl #48
	fmov	d8, x8
	fdiv	d0, d0, d8
	fcvtps	w8, d0
	cmp	w8, #1
	csinc	w21, w8, wzr, gt
	sub	w23, w21, #1
	str	w23, [x19, #32]
	ucvtf	d0, x20
	bl	_log
	fdiv	d0, d0, d8
	mov	x8, #281474972516352            ; =0xffffffc00000
	movk	x8, #16863, lsl #48
	fmov	d1, x8
	fcmp	d0, d1
	b.gt	LBB7_7
; %bb.6:
	fcvtzs	w8, d0
	sxtw	x20, w8
	str	x20, [x19, #16]
	fmov	d0, #1.00000000
	mov	x0, x21
	bl	_ldexp
	fcvtzs	w9, d0
	str	w9, [x19, #48]
	add	w8, w9, w9, lsr #31
	asr	w8, w8, #1
	str	w8, [x19, #36]
	add	x10, x20, w23, uxtw
	cmp	x10, #61
	b.le	LBB7_8
LBB7_7:
	mov	w0, #22                         ; =0x16
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #80               ; 16-byte Folded Reload
	ret
LBB7_8:
	sxtw	x9, w9
	sub	x10, x9, #1
	lsl	x10, x10, x20
	str	x10, [x19, #40]
	lsl	x10, x9, x20
	cmp	x10, x22
	b.le	LBB7_10
; %bb.9:
	mov	w9, #1                          ; =0x1
	b	LBB7_14
LBB7_10:
	mov	w9, #2                          ; =0x2
	mov	x11, #4611686018427387903       ; =0x3fffffffffffffff
LBB7_11:                                ; =>This Inner Loop Header: Depth=1
	cmp	x10, x11
	b.gt	LBB7_14
; %bb.12:                               ;   in Loop: Header=BB7_11 Depth=1
	lsl	x10, x10, #1
	add	w9, w9, #1
	cmp	x10, x22
	b.le	LBB7_11
; %bb.13:
	sub	w9, w9, #1
LBB7_14:
	mov	w0, #0                          ; =0x0
	madd	w8, w8, w9, w8
	stp	w9, w8, [x19, #52]
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #80               ; 16-byte Folded Reload
	ret
	.loh AdrpAdd	Lloh0, Lloh1
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__literal16,16byte_literals
	.p2align	4, 0x0                          ; -- Begin function hdr_init_preallocated
lCPI8_0:
	.quad	9223372036854775807             ; 0x7fffffffffffffff
	.quad	0                               ; 0x0
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_hdr_init_preallocated
	.p2align	2
_hdr_init_preallocated:                 ; @hdr_init_preallocated
	.cfi_startproc
; %bb.0:
	ldr	q0, [x1]
	str	q0, [x0]
	ldr	q0, [x1, #16]
	xtn.2s	v0, v0
	str	d0, [x0, #16]
	ldr	d0, [x1, #32]
	str	d0, [x0, #24]
	ldr	x8, [x1, #40]
	str	x8, [x0, #32]
Lloh2:
	adrp	x8, lCPI8_0@PAGE
Lloh3:
	ldr	q0, [x8, lCPI8_0@PAGEOFF]
	str	q0, [x0, #48]
	str	wzr, [x0, #64]
	mov	x8, #4607182418800017408        ; =0x3ff0000000000000
	str	x8, [x0, #72]
	ldr	d0, [x1, #48]
	str	d0, [x0, #40]
	ldr	w8, [x1, #56]
	str	w8, [x0, #80]
	str	xzr, [x0, #88]
	ret
	.loh AdrpLdr	Lloh2, Lloh3
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_init                       ; -- Begin function hdr_init
	.p2align	2
_hdr_init:                              ; @hdr_init
	.cfi_startproc
; %bb.0:
	sub	w8, w2, #6
	add	x9, x1, x1, lsr #63
	cmp	x0, x9, asr #1
	ccmp	x0, #1, #8, le
	ccmn	w8, #5, #0, ge
	b.hs	LBB9_2
; %bb.1:
	mov	w0, #22                         ; =0x16
	ret
LBB9_2:
	sub	sp, sp, #144
	stp	d9, d8, [sp, #32]               ; 16-byte Folded Spill
	stp	x28, x27, [sp, #48]             ; 16-byte Folded Spill
	stp	x26, x25, [sp, #64]             ; 16-byte Folded Spill
	stp	x24, x23, [sp, #80]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #96]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #112]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #128]            ; 16-byte Folded Spill
	add	x29, sp, #128
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
	mov	x19, x1
	mov	x20, x0
	sub	w8, w2, #1
	cmp	w8, #3
	str	x3, [sp, #24]                   ; 8-byte Folded Spill
	mov	x23, x2
	b.hi	LBB9_4
; %bb.3:
Lloh4:
	adrp	x9, l_switch.table.hdr_init@PAGE
Lloh5:
	add	x9, x9, l_switch.table.hdr_init@PAGEOFF
	ldr	d0, [x9, w8, uxtw #3]
	b	LBB9_5
LBB9_4:
	mov	x8, #116548232544256            ; =0x6a0000000000
	movk	x8, #16648, lsl #48
	fmov	d0, x8
LBB9_5:
	bl	_log
	mov	x8, #14831                      ; =0x39ef
	movk	x8, #65274, lsl #16
	movk	x8, #11842, lsl #32
	movk	x8, #16358, lsl #48
	fmov	d8, x8
	fdiv	d0, d0, d8
	fcvtps	w8, d0
	cmp	w8, #1
	csinc	w21, w8, wzr, gt
	ucvtf	d0, x20
	bl	_log
	fdiv	d0, d0, d8
	mov	x8, #281474972516352            ; =0xffffffc00000
	movk	x8, #16863, lsl #48
	fmov	d1, x8
	fcmp	d0, d1
	b.gt	LBB9_7
; %bb.6:
	sub	w24, w21, #1
	fcvtzs	w25, d0
	sxtw	x27, w25
	fmov	d0, #1.00000000
	mov	x0, x21
	bl	_ldexp
	add	x8, x27, w24, uxtw
	cmp	x8, #61
	b.le	LBB9_9
LBB9_7:
	mov	w0, #22                         ; =0x16
LBB9_8:
	ldp	x29, x30, [sp, #128]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #112]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #96]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #80]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #64]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #48]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #32]               ; 16-byte Folded Reload
	add	sp, sp, #144
	ret
LBB9_9:
	fcvtzs	w26, d0
	add	w8, w26, w26, lsr #31
	asr	w10, w8, #1
	sxtw	x8, w26
	str	x8, [sp, #8]                    ; 8-byte Folded Spill
	lsl	x8, x8, x25
	cmp	x8, x19
	b.le	LBB9_11
; %bb.10:
	mov	w28, #1                         ; =0x1
	b	LBB9_15
LBB9_11:
	mov	w28, #2                         ; =0x2
	mov	x9, #4611686018427387903        ; =0x3fffffffffffffff
LBB9_12:                                ; =>This Inner Loop Header: Depth=1
	cmp	x8, x9
	b.gt	LBB9_15
; %bb.13:                               ;   in Loop: Header=BB9_12 Depth=1
	lsl	x8, x8, #1
	add	w28, w28, #1
	cmp	x8, x19
	b.le	LBB9_12
; %bb.14:
	sub	w28, w28, #1
LBB9_15:
	str	w10, [sp, #20]                  ; 4-byte Folded Spill
	madd	w22, w10, w28, w10
	sxtw	x0, w22
	mov	w1, #8                          ; =0x8
	bl	_calloc
	cbz	x0, LBB9_19
; %bb.16:
	mov	x21, x0
	mov	w0, #1                          ; =0x1
	mov	w1, #104                        ; =0x68
	bl	_calloc
	cbz	x0, LBB9_18
; %bb.17:
	mov	x8, x0
	mov	w0, #0                          ; =0x0
	str	x21, [x8, #96]
	ldr	x9, [sp, #8]                    ; 8-byte Folded Reload
	sub	x9, x9, #1
	lsl	x9, x9, x27
	stp	x20, x19, [x8]
	stp	w25, w23, [x8, #16]
	ldr	w10, [sp, #20]                  ; 4-byte Folded Reload
	stp	w24, w10, [x8, #24]
	str	x9, [x8, #32]
	mov	x9, #9223372036854775807        ; =0x7fffffffffffffff
	str	x9, [x8, #48]
	mov	x9, #4607182418800017408        ; =0x3ff0000000000000
	str	x9, [x8, #72]
	stp	w26, w28, [x8, #40]
	str	w22, [x8, #80]
	ldr	x9, [sp, #24]                   ; 8-byte Folded Reload
	str	x8, [x9]
	b	LBB9_8
LBB9_18:
	mov	x0, x21
	bl	_free
LBB9_19:
	mov	w0, #12                         ; =0xc
	b	LBB9_8
	.loh AdrpAdd	Lloh4, Lloh5
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_close                      ; -- Begin function hdr_close
	.p2align	2
_hdr_close:                             ; @hdr_close
	.cfi_startproc
; %bb.0:
	cbz	x0, LBB10_2
; %bb.1:
	stp	x20, x19, [sp, #-32]!           ; 16-byte Folded Spill
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	ldr	x8, [x0, #96]
	mov	x19, x0
	mov	x0, x8
	bl	_free
	mov	x0, x19
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	b	_free
LBB10_2:
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_alloc                      ; -- Begin function hdr_alloc
	.p2align	2
_hdr_alloc:                             ; @hdr_alloc
	.cfi_startproc
; %bb.0:
	mov	x3, x2
	mov	x2, x1
	mov	x1, x0
	mov	w0, #1                          ; =0x1
	b	_hdr_init
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__literal16,16byte_literals
	.p2align	4, 0x0                          ; -- Begin function hdr_reset
lCPI12_0:
	.quad	9223372036854775807             ; 0x7fffffffffffffff
	.quad	0                               ; 0x0
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_hdr_reset
	.p2align	2
_hdr_reset:                             ; @hdr_reset
	.cfi_startproc
; %bb.0:
	str	xzr, [x0, #88]
Lloh6:
	adrp	x8, lCPI12_0@PAGE
Lloh7:
	ldr	q0, [x8, lCPI12_0@PAGEOFF]
	str	q0, [x0, #48]
	ldr	x8, [x0, #96]
	ldrsw	x9, [x0, #80]
	lsl	x1, x9, #3
	mov	x0, x8
	b	_bzero
	.loh AdrpLdr	Lloh6, Lloh7
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_get_memory_size            ; -- Begin function hdr_get_memory_size
	.p2align	2
_hdr_get_memory_size:                   ; @hdr_get_memory_size
	.cfi_startproc
; %bb.0:
	ldrsw	x8, [x0, #80]
	lsl	x8, x8, #3
	add	x0, x8, #104
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_record_value               ; -- Begin function hdr_record_value
	.p2align	2
_hdr_record_value:                      ; @hdr_record_value
	.cfi_startproc
; %bb.0:
	tbnz	x1, #63, LBB14_7
; %bb.1:
	ldr	x8, [x0, #8]
	cmp	x8, x1
	b.lt	LBB14_7
; %bb.2:
	ldr	x8, [x0, #32]
	orr	x8, x8, x1
	clz	x8, x8
	ldr	w9, [x0, #16]
	ldp	w10, w11, [x0, #24]
	add	w12, w10, w9
	add	w8, w12, w8
	sub	w9, w9, w8
	add	w9, w9, #63
	lsr	x9, x1, x9
	mov	w12, #64                        ; =0x40
	sub	w8, w12, w8
	lsl	w8, w8, w10
	sub	w8, w8, w11
	add	w8, w8, w9
	ldr	w9, [x0, #80]
	cmp	w8, w9
	b.hs	LBB14_7
; %bb.3:
	ldr	w10, [x0, #64]
	sub	w11, w8, w10
	cmp	w11, w9
	csneg	w12, wzr, w9, lt
	cmp	w11, #0
	csel	w9, w9, w12, lt
	add	w9, w9, w11
	cmp	w10, #0
	csel	w8, w8, w9, eq
	ldr	x9, [x0, #96]
	prfm	pstl1keep, [x9, w8, sxtw #3]
	ldr	x10, [x9, w8, sxtw #3]
	add	x10, x10, #1
	str	x10, [x9, w8, sxtw #3]
	ldr	x8, [x0, #88]
	add	x8, x8, #1
	str	x8, [x0, #88]
	ldr	x8, [x0, #56]
	cmp	x1, x8
	b.gt	LBB14_8
; %bb.4:
	cbz	x1, LBB14_9
LBB14_5:
	ldr	x8, [x0, #48]
	cmp	x1, x8
	b.lt	LBB14_10
; %bb.6:
	mov	w0, #1                          ; =0x1
	ret
LBB14_7:
	mov	w0, #0                          ; =0x0
	ret
LBB14_8:
	str	x1, [x0, #56]
	cbnz	x1, LBB14_5
LBB14_9:
	mov	w0, #1                          ; =0x1
	ret
LBB14_10:
	str	x1, [x0, #48]
	mov	w0, #1                          ; =0x1
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_record_value_atomic        ; -- Begin function hdr_record_value_atomic
	.p2align	2
_hdr_record_value_atomic:               ; @hdr_record_value_atomic
	.cfi_startproc
; %bb.0:
	tbnz	x1, #63, LBB15_6
; %bb.1:
	ldr	x8, [x0, #8]
	cmp	x8, x1
	b.lt	LBB15_6
; %bb.2:
	ldr	x8, [x0, #32]
	orr	x8, x8, x1
	clz	x8, x8
	ldr	w9, [x0, #16]
	ldp	w10, w11, [x0, #24]
	add	w12, w10, w9
	add	w8, w12, w8
	sub	w9, w9, w8
	add	w9, w9, #63
	lsr	x9, x1, x9
	mov	w12, #64                        ; =0x40
	sub	w8, w12, w8
	lsl	w8, w8, w10
	sub	w8, w8, w11
	add	w8, w8, w9
	ldr	w9, [x0, #80]
	cmp	w8, w9
	b.hs	LBB15_6
; %bb.3:
	ldr	w10, [x0, #64]
	sub	w11, w8, w10
	cmp	w11, w9
	csneg	w12, wzr, w9, lt
	cmp	w11, #0
	csel	w9, w9, w12, lt
	add	w9, w9, w11
	cmp	w10, #0
	csel	w8, w8, w9, eq
	ldr	x9, [x0, #96]
	add	x8, x9, w8, sxtw #3
	prfm	pstl1keep, [x8]
	mov	w9, #1                          ; =0x1
	ldaddal	x9, x8, [x8]
	add	x8, x0, #88
	ldaddal	x9, x8, [x8]
	cbz	x1, LBB15_7
LBB15_4:                                ; =>This Inner Loop Header: Depth=1
	add	x9, x0, #48
	ldar	x8, [x9]
	cmp	x8, x1
	b.le	LBB15_8
; %bb.5:                                ;   in Loop: Header=BB15_4 Depth=1
	mov	x10, x8
	casal	x10, x1, [x9]
	cmp	x10, x8
	b.ne	LBB15_4
	b	LBB15_8
LBB15_6:
	mov	w0, #0                          ; =0x0
	ret
LBB15_7:
	add	x8, x0, #48
	ldar	xzr, [x8]
LBB15_8:                                ; =>This Inner Loop Header: Depth=1
	add	x8, x0, #56
	ldar	x9, [x8]
	cmp	x1, x9
	b.le	LBB15_10
; %bb.9:                                ;   in Loop: Header=BB15_8 Depth=1
	mov	x10, x9
	casal	x10, x1, [x8]
	cmp	x10, x9
	b.ne	LBB15_8
LBB15_10:
	mov	w0, #1                          ; =0x1
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_record_values              ; -- Begin function hdr_record_values
	.p2align	2
_hdr_record_values:                     ; @hdr_record_values
	.cfi_startproc
; %bb.0:
	orr	x8, x2, x1
	tbnz	x8, #63, LBB16_7
; %bb.1:
	ldr	x8, [x0, #8]
	cmp	x8, x1
	b.lt	LBB16_7
; %bb.2:
	ldr	x8, [x0, #32]
	orr	x8, x8, x1
	clz	x8, x8
	ldr	w9, [x0, #16]
	ldp	w10, w11, [x0, #24]
	add	w12, w10, w9
	add	w8, w12, w8
	sub	w9, w9, w8
	add	w9, w9, #63
	lsr	x9, x1, x9
	mov	w12, #64                        ; =0x40
	sub	w8, w12, w8
	lsl	w8, w8, w10
	sub	w8, w8, w11
	add	w8, w8, w9
	ldr	w9, [x0, #80]
	cmp	w8, w9
	b.hs	LBB16_7
; %bb.3:
	ldr	w10, [x0, #64]
	sub	w11, w8, w10
	cmp	w11, w9
	csneg	w12, wzr, w9, lt
	cmp	w11, #0
	csel	w9, w9, w12, lt
	add	w9, w9, w11
	cmp	w10, #0
	csel	w8, w8, w9, eq
	ldr	x9, [x0, #96]
	prfm	pstl1keep, [x9, w8, sxtw #3]
	ldr	x10, [x9, w8, sxtw #3]
	add	x10, x10, x2
	str	x10, [x9, w8, sxtw #3]
	ldr	x8, [x0, #88]
	add	x8, x8, x2
	str	x8, [x0, #88]
	ldr	x8, [x0, #56]
	cmp	x1, x8
	b.gt	LBB16_8
; %bb.4:
	cbz	x1, LBB16_9
LBB16_5:
	ldr	x8, [x0, #48]
	cmp	x1, x8
	b.lt	LBB16_10
; %bb.6:
	mov	w0, #1                          ; =0x1
	ret
LBB16_7:
	mov	w0, #0                          ; =0x0
	ret
LBB16_8:
	str	x1, [x0, #56]
	cbnz	x1, LBB16_5
LBB16_9:
	mov	w0, #1                          ; =0x1
	ret
LBB16_10:
	str	x1, [x0, #48]
	mov	w0, #1                          ; =0x1
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_record_values_atomic       ; -- Begin function hdr_record_values_atomic
	.p2align	2
_hdr_record_values_atomic:              ; @hdr_record_values_atomic
	.cfi_startproc
; %bb.0:
	orr	x8, x2, x1
	tbnz	x8, #63, LBB17_6
; %bb.1:
	ldr	x8, [x0, #8]
	cmp	x8, x1
	b.lt	LBB17_6
; %bb.2:
	ldr	x8, [x0, #32]
	orr	x8, x8, x1
	clz	x8, x8
	ldr	w9, [x0, #16]
	ldp	w10, w11, [x0, #24]
	add	w12, w10, w9
	add	w8, w12, w8
	sub	w9, w9, w8
	add	w9, w9, #63
	lsr	x9, x1, x9
	mov	w12, #64                        ; =0x40
	sub	w8, w12, w8
	lsl	w8, w8, w10
	sub	w8, w8, w11
	add	w8, w8, w9
	ldr	w9, [x0, #80]
	cmp	w8, w9
	b.hs	LBB17_6
; %bb.3:
	ldr	w10, [x0, #64]
	sub	w11, w8, w10
	cmp	w11, w9
	csneg	w12, wzr, w9, lt
	cmp	w11, #0
	csel	w9, w9, w12, lt
	add	w9, w9, w11
	cmp	w10, #0
	csel	w8, w8, w9, eq
	ldr	x9, [x0, #96]
	add	x8, x9, w8, sxtw #3
	prfm	pstl1keep, [x8]
	ldaddal	x2, x8, [x8]
	add	x8, x0, #88
	ldaddal	x2, x8, [x8]
	cbz	x1, LBB17_7
LBB17_4:                                ; =>This Inner Loop Header: Depth=1
	add	x9, x0, #48
	ldar	x8, [x9]
	cmp	x8, x1
	b.le	LBB17_8
; %bb.5:                                ;   in Loop: Header=BB17_4 Depth=1
	mov	x10, x8
	casal	x10, x1, [x9]
	cmp	x10, x8
	b.ne	LBB17_4
	b	LBB17_8
LBB17_6:
	mov	w0, #0                          ; =0x0
	ret
LBB17_7:
	add	x8, x0, #48
	ldar	xzr, [x8]
LBB17_8:                                ; =>This Inner Loop Header: Depth=1
	add	x8, x0, #56
	ldar	x9, [x8]
	cmp	x1, x9
	b.le	LBB17_10
; %bb.9:                                ;   in Loop: Header=BB17_8 Depth=1
	mov	x10, x9
	casal	x10, x1, [x8]
	cmp	x10, x9
	b.ne	LBB17_8
LBB17_10:
	mov	w0, #1                          ; =0x1
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_record_corrected_value     ; -- Begin function hdr_record_corrected_value
	.p2align	2
_hdr_record_corrected_value:            ; @hdr_record_corrected_value
	.cfi_startproc
; %bb.0:
	mov	x3, x2
	mov	w2, #1                          ; =0x1
	b	_hdr_record_corrected_values
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_record_corrected_values    ; -- Begin function hdr_record_corrected_values
	.p2align	2
_hdr_record_corrected_values:           ; @hdr_record_corrected_values
	.cfi_startproc
; %bb.0:
	orr	x8, x2, x1
	tbnz	x8, #63, LBB19_20
; %bb.1:
	ldr	x8, [x0, #8]
	cmp	x8, x1
	b.lt	LBB19_20
; %bb.2:
	ldr	x8, [x0, #32]
	orr	x8, x8, x1
	clz	x8, x8
	ldr	w12, [x0, #16]
	ldp	w9, w10, [x0, #24]
	add	w11, w9, w12
	add	w8, w11, w8
	add	w12, w12, #63
	sub	w13, w12, w8
	lsr	x13, x1, x13
	mov	w14, #64                        ; =0x40
	sub	w8, w14, w8
	lsl	w8, w8, w9
	sub	w8, w8, w10
	add	w8, w8, w13
	ldr	w13, [x0, #80]
	cmp	w8, w13
	b.hs	LBB19_20
; %bb.3:
	ldr	w14, [x0, #64]
	sub	w15, w8, w14
	cmp	w15, w13
	csneg	w16, wzr, w13, lt
	cmp	w15, #0
	csel	w16, w13, w16, lt
	add	w15, w16, w15
	cmp	w14, #0
	csel	w8, w8, w15, eq
	ldr	x15, [x0, #96]
	prfm	pstl1keep, [x15, w8, sxtw #3]
	ldr	x16, [x15, w8, sxtw #3]
	add	x16, x16, x2
	str	x16, [x15, w8, sxtw #3]
	ldr	x8, [x0, #88]
	add	x8, x8, x2
	str	x8, [x0, #88]
	ldr	x8, [x0, #56]
	cmp	x1, x8
	b.gt	LBB19_22
; %bb.4:
	cbz	x1, LBB19_6
LBB19_5:
	ldr	x8, [x0, #48]
	cmp	x1, x8
	b.lt	LBB19_23
LBB19_6:
	mov	w8, #1                          ; =0x1
	cmp	x3, #1
	b.lt	LBB19_21
; %bb.7:
	subs	x16, x1, x3
	b.le	LBB19_21
; %bb.8:
	cmp	x16, x3
	b.lt	LBB19_21
; %bb.9:
	neg	w17, w13
	mov	w1, #64                         ; =0x40
LBB19_10:                               ; =>This Inner Loop Header: Depth=1
	orr	x8, x16, x2
	tbnz	x8, #63, LBB19_20
; %bb.11:                               ;   in Loop: Header=BB19_10 Depth=1
	ldr	x8, [x0, #8]
	cmp	x8, x16
	b.lt	LBB19_20
; %bb.12:                               ;   in Loop: Header=BB19_10 Depth=1
	ldr	x8, [x0, #32]
	orr	x8, x8, x16
	clz	x8, x8
	add	w8, w11, w8
	sub	w4, w12, w8
	lsr	x4, x16, x4
	sub	w8, w1, w8
	lsl	w8, w8, w9
	sub	w8, w8, w10
	add	w8, w8, w4
	cmp	w8, w13
	b.hs	LBB19_20
; %bb.13:                               ;   in Loop: Header=BB19_10 Depth=1
	cbnz	w14, LBB19_17
LBB19_14:                               ;   in Loop: Header=BB19_10 Depth=1
	prfm	pstl1keep, [x15, w8, sxtw #3]
	ldr	x4, [x15, w8, sxtw #3]
	add	x4, x4, x2
	str	x4, [x15, w8, sxtw #3]
	ldr	x8, [x0, #88]
	add	x8, x8, x2
	str	x8, [x0, #88]
	ldr	x8, [x0, #56]
	cmp	x16, x8
	b.gt	LBB19_18
; %bb.15:                               ;   in Loop: Header=BB19_10 Depth=1
	ldr	x8, [x0, #48]
	cmp	x16, x8
	b.lt	LBB19_19
LBB19_16:                               ;   in Loop: Header=BB19_10 Depth=1
	mov	w8, #1                          ; =0x1
	sub	x16, x16, x3
	cmp	x16, x3
	b.ge	LBB19_10
	b	LBB19_21
LBB19_17:                               ;   in Loop: Header=BB19_10 Depth=1
	sub	w8, w8, w14
	cmp	w8, w13
	csel	w4, wzr, w17, lt
	cmp	w8, #0
	csel	w4, w13, w4, lt
	add	w8, w4, w8
	b	LBB19_14
LBB19_18:                               ;   in Loop: Header=BB19_10 Depth=1
	str	x16, [x0, #56]
	ldr	x8, [x0, #48]
	cmp	x16, x8
	b.ge	LBB19_16
LBB19_19:                               ;   in Loop: Header=BB19_10 Depth=1
	str	x16, [x0, #48]
	mov	w8, #1                          ; =0x1
	sub	x16, x16, x3
	cmp	x16, x3
	b.ge	LBB19_10
	b	LBB19_21
LBB19_20:
	mov	w8, #0                          ; =0x0
LBB19_21:
	mov	x0, x8
	ret
LBB19_22:
	str	x1, [x0, #56]
	cbnz	x1, LBB19_5
	b	LBB19_6
LBB19_23:
	str	x1, [x0, #48]
	b	LBB19_6
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_record_corrected_value_atomic ; -- Begin function hdr_record_corrected_value_atomic
	.p2align	2
_hdr_record_corrected_value_atomic:     ; @hdr_record_corrected_value_atomic
	.cfi_startproc
; %bb.0:
	mov	x3, x2
	mov	w2, #1                          ; =0x1
	b	_hdr_record_corrected_values_atomic
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_record_corrected_values_atomic ; -- Begin function hdr_record_corrected_values_atomic
	.p2align	2
_hdr_record_corrected_values_atomic:    ; @hdr_record_corrected_values_atomic
	.cfi_startproc
; %bb.0:
	orr	x8, x2, x1
	tbnz	x8, #63, LBB21_24
; %bb.1:
	ldr	x8, [x0, #8]
	cmp	x8, x1
	b.lt	LBB21_24
; %bb.2:
	ldr	x8, [x0, #32]
	orr	x8, x8, x1
	clz	x8, x8
	ldr	w9, [x0, #16]
	ldp	w10, w11, [x0, #24]
	add	w12, w10, w9
	add	w8, w12, w8
	sub	w9, w9, w8
	add	w9, w9, #63
	lsr	x9, x1, x9
	mov	w12, #64                        ; =0x40
	sub	w8, w12, w8
	lsl	w8, w8, w10
	sub	w8, w8, w11
	add	w8, w8, w9
	ldr	w9, [x0, #80]
	cmp	w8, w9
	b.hs	LBB21_24
; %bb.3:
	ldr	w10, [x0, #64]
	sub	w11, w8, w10
	cmp	w11, w9
	csneg	w12, wzr, w9, lt
	cmp	w11, #0
	csel	w9, w9, w12, lt
	add	w9, w9, w11
	cmp	w10, #0
	csel	w8, w8, w9, eq
	ldr	x9, [x0, #96]
	add	x8, x9, w8, sxtw #3
	prfm	pstl1keep, [x8]
	ldaddal	x2, x8, [x8]
	add	x8, x0, #88
	ldaddal	x2, x8, [x8]
	cbz	x1, LBB21_6
LBB21_4:                                ; =>This Inner Loop Header: Depth=1
	add	x9, x0, #48
	ldar	x8, [x9]
	cmp	x8, x1
	b.le	LBB21_7
; %bb.5:                                ;   in Loop: Header=BB21_4 Depth=1
	mov	x10, x8
	casal	x10, x1, [x9]
	cmp	x10, x8
	b.ne	LBB21_4
	b	LBB21_7
LBB21_6:
	add	x8, x0, #48
	ldar	xzr, [x8]
LBB21_7:                                ; =>This Inner Loop Header: Depth=1
	add	x9, x0, #56
	ldar	x8, [x9]
	cmp	x1, x8
	b.le	LBB21_9
; %bb.8:                                ;   in Loop: Header=BB21_7 Depth=1
	mov	x10, x8
	casal	x10, x1, [x9]
	cmp	x10, x8
	b.ne	LBB21_7
LBB21_9:
	mov	w8, #1                          ; =0x1
	cmp	x3, #1
	b.lt	LBB21_25
; %bb.10:
	cmp	x1, x3
	b.le	LBB21_25
; %bb.11:
	sub	x9, x1, x3
	cmp	x9, x3
	b.lt	LBB21_25
; %bb.12:
	mov	w10, #64                        ; =0x40
	b	LBB21_14
LBB21_13:                               ;   in Loop: Header=BB21_14 Depth=1
	mov	w8, #1                          ; =0x1
	sub	x9, x9, x3
	cmp	x9, x3
	b.lt	LBB21_25
LBB21_14:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB21_19 Depth 2
                                        ;     Child Loop BB21_21 Depth 2
	orr	x8, x9, x2
	tbnz	x8, #63, LBB21_24
; %bb.15:                               ;   in Loop: Header=BB21_14 Depth=1
	ldr	x8, [x0, #8]
	cmp	x8, x9
	b.lt	LBB21_24
; %bb.16:                               ;   in Loop: Header=BB21_14 Depth=1
	ldr	x8, [x0, #32]
	orr	x8, x8, x9
	clz	x8, x8
	ldr	w11, [x0, #16]
	ldp	w12, w13, [x0, #24]
	add	w14, w12, w11
	add	w8, w14, w8
	sub	w11, w11, w8
	add	w11, w11, #63
	lsr	x11, x9, x11
	sub	w8, w10, w8
	lsl	w8, w8, w12
	sub	w8, w8, w13
	add	w8, w8, w11
	ldr	w11, [x0, #80]
	cmp	w8, w11
	b.hs	LBB21_24
; %bb.17:                               ;   in Loop: Header=BB21_14 Depth=1
	ldr	w12, [x0, #64]
	cbnz	w12, LBB21_23
LBB21_18:                               ;   in Loop: Header=BB21_14 Depth=1
	ldr	x11, [x0, #96]
	add	x8, x11, w8, sxtw #3
	prfm	pstl1keep, [x8]
	ldaddal	x2, x8, [x8]
	add	x8, x0, #88
	ldaddal	x2, x8, [x8]
LBB21_19:                               ;   Parent Loop BB21_14 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	add	x11, x0, #48
	ldar	x8, [x11]
	cmp	x8, x9
	b.le	LBB21_21
; %bb.20:                               ;   in Loop: Header=BB21_19 Depth=2
	mov	x12, x8
	casal	x12, x9, [x11]
	cmp	x12, x8
	b.ne	LBB21_19
LBB21_21:                               ;   Parent Loop BB21_14 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	add	x11, x0, #56
	ldar	x8, [x11]
	cmp	x9, x8
	b.le	LBB21_13
; %bb.22:                               ;   in Loop: Header=BB21_21 Depth=2
	mov	x12, x8
	casal	x12, x9, [x11]
	cmp	x12, x8
	b.ne	LBB21_21
	b	LBB21_13
LBB21_23:                               ;   in Loop: Header=BB21_14 Depth=1
	sub	w8, w8, w12
	cmp	w8, w11
	csneg	w12, wzr, w11, lt
	cmp	w8, #0
	csel	w11, w11, w12, lt
	add	w8, w11, w8
	b	LBB21_18
LBB21_24:
	mov	w8, #0                          ; =0x0
LBB21_25:
	mov	x0, x8
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_add                        ; -- Begin function hdr_add
	.p2align	2
_hdr_add:                               ; @hdr_add
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #176
	stp	x22, x21, [sp, #128]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #144]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #160]            ; 16-byte Folded Spill
	add	x29, sp, #160
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	mov	x19, x0
	str	x1, [sp]
	mov	w8, #-1                         ; =0xffffffff
	str	w8, [sp, #8]
	ldr	x8, [x1, #88]
	str	x8, [sp, #16]
	movi.2d	v0, #0000000000000000
	stur	q0, [sp, #24]
	stur	q0, [sp, #40]
	stp	xzr, xzr, [sp, #72]
Lloh8:
	adrp	x8, _recorded_iter_next@PAGE
Lloh9:
	add	x8, x8, _recorded_iter_next@PAGEOFF
	str	xzr, [sp, #88]
	str	x8, [sp, #120]
	mov	x0, sp
	bl	_recorded_iter_next
	mov	x20, #0                         ; =0x0
	cbz	w0, LBB22_14
; %bb.1:
	mov	x20, #0                         ; =0x0
	mov	w21, #64                        ; =0x40
	b	LBB22_4
LBB22_2:                                ;   in Loop: Header=BB22_4 Depth=1
	add	x20, x9, x20
LBB22_3:                                ;   in Loop: Header=BB22_4 Depth=1
	ldr	x8, [sp, #120]
	mov	x0, sp
	blr	x8
	tbz	w0, #0, LBB22_14
LBB22_4:                                ; =>This Inner Loop Header: Depth=1
	ldr	x8, [sp, #40]
	ldr	x9, [sp, #24]
	orr	x10, x9, x8
	tbnz	x10, #63, LBB22_2
; %bb.5:                                ;   in Loop: Header=BB22_4 Depth=1
	ldr	x10, [x19, #8]
	cmp	x10, x8
	b.lt	LBB22_2
; %bb.6:                                ;   in Loop: Header=BB22_4 Depth=1
	ldr	x10, [x19, #32]
	orr	x10, x10, x8
	clz	x10, x10
	ldr	w11, [x19, #16]
	ldp	w12, w13, [x19, #24]
	add	w14, w12, w11
	add	w10, w14, w10
	sub	w11, w11, w10
	add	w11, w11, #63
	lsr	x11, x8, x11
	sub	w10, w21, w10
	lsl	w10, w10, w12
	sub	w10, w10, w13
	add	w10, w10, w11
	ldr	w11, [x19, #80]
	cmp	w10, w11
	b.hs	LBB22_2
; %bb.7:                                ;   in Loop: Header=BB22_4 Depth=1
	ldr	w12, [x19, #64]
	cbnz	w12, LBB22_12
LBB22_8:                                ;   in Loop: Header=BB22_4 Depth=1
	ldr	x11, [x19, #96]
	prfm	pstl1keep, [x11, w10, sxtw #3]
	ldr	x12, [x11, w10, sxtw #3]
	add	x12, x12, x9
	str	x12, [x11, w10, sxtw #3]
	ldr	x10, [x19, #88]
	add	x9, x10, x9
	str	x9, [x19, #88]
	ldr	x9, [x19, #56]
	cmp	x8, x9
	b.gt	LBB22_13
; %bb.9:                                ;   in Loop: Header=BB22_4 Depth=1
	cbz	x8, LBB22_3
LBB22_10:                               ;   in Loop: Header=BB22_4 Depth=1
	ldr	x9, [x19, #48]
	cmp	x8, x9
	b.ge	LBB22_3
; %bb.11:                               ;   in Loop: Header=BB22_4 Depth=1
	str	x8, [x19, #48]
	b	LBB22_3
LBB22_12:                               ;   in Loop: Header=BB22_4 Depth=1
	sub	w10, w10, w12
	cmp	w10, w11
	csneg	w12, wzr, w11, lt
	cmp	w10, #0
	csel	w11, w11, w12, lt
	add	w10, w11, w10
	b	LBB22_8
LBB22_13:                               ;   in Loop: Header=BB22_4 Depth=1
	str	x8, [x19, #56]
	cbnz	x8, LBB22_10
	b	LBB22_3
LBB22_14:
	mov	x0, x20
	ldp	x29, x30, [sp, #160]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #144]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #128]            ; 16-byte Folded Reload
	add	sp, sp, #176
	ret
	.loh AdrpAdd	Lloh8, Lloh9
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_iter_recorded_init         ; -- Begin function hdr_iter_recorded_init
	.p2align	2
_hdr_iter_recorded_init:                ; @hdr_iter_recorded_init
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
	stp	xzr, xzr, [x0, #80]
	str	xzr, [x0, #72]
Lloh10:
	adrp	x8, _recorded_iter_next@PAGE
Lloh11:
	add	x8, x8, _recorded_iter_next@PAGEOFF
	str	x8, [x0, #120]
	ret
	.loh AdrpAdd	Lloh10, Lloh11
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_iter_next                  ; -- Begin function hdr_iter_next
	.p2align	2
_hdr_iter_next:                         ; @hdr_iter_next
	.cfi_startproc
; %bb.0:
	ldr	x1, [x0, #120]
	br	x1
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_add_while_correcting_for_coordinated_omission ; -- Begin function hdr_add_while_correcting_for_coordinated_omission
	.p2align	2
_hdr_add_while_correcting_for_coordinated_omission: ; @hdr_add_while_correcting_for_coordinated_omission
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #176
	stp	x22, x21, [sp, #128]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #144]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #160]            ; 16-byte Folded Spill
	add	x29, sp, #160
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	mov	x19, x2
	mov	x20, x0
	str	x1, [sp]
	mov	w8, #-1                         ; =0xffffffff
	str	w8, [sp, #8]
	ldr	x8, [x1, #88]
	str	x8, [sp, #16]
	movi.2d	v0, #0000000000000000
	stur	q0, [sp, #24]
	stur	q0, [sp, #40]
	stp	xzr, xzr, [sp, #72]
Lloh12:
	adrp	x8, _recorded_iter_next@PAGE
Lloh13:
	add	x8, x8, _recorded_iter_next@PAGEOFF
	str	xzr, [sp, #88]
	str	x8, [sp, #120]
	mov	x0, sp
	bl	_recorded_iter_next
	mov	x21, #0                         ; =0x0
	cbz	w0, LBB25_3
; %bb.1:
	mov	x21, #0                         ; =0x0
LBB25_2:                                ; =>This Inner Loop Header: Depth=1
	ldr	x1, [sp, #40]
	ldr	x22, [sp, #24]
	mov	x0, x20
	mov	x2, x22
	mov	x3, x19
	bl	_hdr_record_corrected_values
	cmp	w0, #0
	csel	x8, xzr, x22, ne
	add	x21, x8, x21
	ldr	x8, [sp, #120]
	mov	x0, sp
	blr	x8
	tbnz	w0, #0, LBB25_2
LBB25_3:
	mov	x0, x21
	ldp	x29, x30, [sp, #160]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #144]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #128]            ; 16-byte Folded Reload
	add	sp, sp, #176
	ret
	.loh AdrpAdd	Lloh12, Lloh13
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_max                        ; -- Begin function hdr_max
	.p2align	2
_hdr_max:                               ; @hdr_max
	.cfi_startproc
; %bb.0:
	ldr	x8, [x0, #56]
	cbz	x8, LBB26_2
; %bb.1:
	ldr	x9, [x0, #32]
	orr	x9, x9, x8
	clz	x9, x9
	ldr	w10, [x0, #24]
	mov	w11, #63                        ; =0x3f
	add	w9, w10, w9
	sub	w10, w11, w9
	mvn	w9, w9
	asr	x8, x8, x9
	sxtw	x8, w8
	lsl	x9, x8, x9
	ldr	w11, [x0, #40]
	cmp	w11, w8
	cinc	w8, w10, le
	mov	w10, #1                         ; =0x1
	lsl	x8, x10, x8
	eor	x10, x8, #0x7fffffffffffffff
	add	x8, x9, x8
	sub	x8, x8, #1
	mov	x11, #9223372036854775807       ; =0x7fffffffffffffff
	cmp	x9, x10
	csel	x0, x11, x8, gt
	ret
LBB26_2:
	mov	x0, #0                          ; =0x0
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_min                        ; -- Begin function hdr_min
	.p2align	2
_hdr_min:                               ; @hdr_min
	.cfi_startproc
; %bb.0:
	ldr	w8, [x0, #80]
	cbz	w8, LBB27_3
; %bb.1:
	ldr	w9, [x0, #64]
	cmn	w8, w9
	csneg	w10, wzr, w8, gt
	cmp	w9, #0
	csel	w8, w8, w10, gt
	sub	w8, w8, w9
	sxtw	x8, w8
	cmp	w9, #0
	csel	x8, xzr, x8, eq
	ldr	x9, [x0, #96]
	ldr	x8, [x9, x8, lsl #3]
	cmp	x8, #0
	b.le	LBB27_3
; %bb.2:
	mov	x0, #0                          ; =0x0
	ret
LBB27_3:
	ldr	x9, [x0, #48]
	mov	x8, #9223372036854775807        ; =0x7fffffffffffffff
	cmp	x9, x8
	b.eq	LBB27_5
; %bb.4:
	ldr	x8, [x0, #32]
	orr	x8, x8, x9
	clz	x8, x8
	ldr	w10, [x0, #24]
	add	w8, w10, w8
	mvn	w8, w8
	asr	x9, x9, x8
	sxtw	x9, w9
	lsl	x8, x9, x8
LBB27_5:
	mov	x0, x8
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_count_at_index             ; -- Begin function hdr_count_at_index
	.p2align	2
_hdr_count_at_index:                    ; @hdr_count_at_index
	.cfi_startproc
; %bb.0:
	ldr	w8, [x0, #80]
	cmp	w1, w8
	b.hs	LBB28_2
; %bb.1:
	ldr	w9, [x0, #64]
	sub	w10, w1, w9
	cmp	w10, w8
	csneg	w11, wzr, w8, lt
	cmp	w10, #0
	csel	w8, w8, w11, lt
	add	w8, w8, w10
	cmp	w9, #0
	csel	w8, w1, w8, eq
	ldr	x9, [x0, #96]
	ldr	x0, [x9, w8, sxtw #3]
	ret
LBB28_2:
	mov	x0, #0                          ; =0x0
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_value_at_percentile        ; -- Begin function hdr_value_at_percentile
	.p2align	2
_hdr_value_at_percentile:               ; @hdr_value_at_percentile
	.cfi_startproc
; %bb.0:
	mov	x8, #4636737291354636288        ; =0x4059000000000000
	fmov	d1, x8
	fminnm	d2, d0, d1
	fdiv	d1, d2, d1
	ldr	d2, [x0, #88]
	scvtf	d2, d2
	fmov	d3, #0.50000000
	fmadd	d1, d1, d2, d3
	fcvtzs	x8, d1
	cmp	x8, #1
	csinc	x9, x8, xzr, gt
	ldr	x11, [x0, #96]
	ldr	w10, [x0, #80]
	ldr	w14, [x0, #64]
	cbnz	w14, LBB29_16
; %bb.1:
	negs	w8, w10
	and	w8, w8, #0x3
	and	w12, w10, #0x3
	csneg	w8, w12, w8, mi
	sub	w13, w10, w8
	cmp	w13, #1
	b.lt	LBB29_10
; %bb.2:
	mov	x8, #0                          ; =0x0
	mov	x12, #0                         ; =0x0
	add	x14, x11, #16
LBB29_3:                                ; =>This Inner Loop Header: Depth=1
	ldp	x15, x16, [x14, #-16]
	ldp	x1, x2, [x14]
	add	x17, x15, x12
	add	x16, x17, x16
	add	x15, x16, x1
	add	x12, x15, x2
	cmp	x12, x9
	b.hs	LBB29_5
LBB29_4:                                ;   in Loop: Header=BB29_3 Depth=1
	add	x14, x14, #32
	add	x8, x8, #4
	cmp	w13, w8
	b.gt	LBB29_3
	b	LBB29_11
LBB29_5:                                ;   in Loop: Header=BB29_3 Depth=1
	cmp	x17, x9
	b.ge	LBB29_22
; %bb.6:                                ;   in Loop: Header=BB29_3 Depth=1
	cmp	x16, x9
	b.ge	LBB29_20
; %bb.7:                                ;   in Loop: Header=BB29_3 Depth=1
	cmp	x15, x9
	b.ge	LBB29_21
; %bb.8:                                ;   in Loop: Header=BB29_3 Depth=1
	cmp	x12, x9
	b.lt	LBB29_4
; %bb.9:
	add	x8, x8, #3
	b	LBB29_22
LBB29_10:
	mov	w8, #0                          ; =0x0
	mov	x12, #0                         ; =0x0
LBB29_11:
	cmp	w8, w10
	b.ge	LBB29_15
; %bb.12:
	add	x11, x11, w8, uxtw #3
LBB29_13:                               ; =>This Inner Loop Header: Depth=1
	ldr	x13, [x11], #8
	add	x12, x13, x12
	cmp	x12, x9
	b.ge	LBB29_22
; %bb.14:                               ;   in Loop: Header=BB29_13 Depth=1
	add	w8, w8, #1
	cmp	w10, w8
	b.gt	LBB29_13
LBB29_15:
	mov	x15, #0                         ; =0x0
	b	LBB29_23
LBB29_16:
	cmp	w10, #1
	b.lt	LBB29_15
; %bb.17:
	mov	x12, #0                         ; =0x0
	mov	w8, #0                          ; =0x0
	neg	w13, w10
	neg	w14, w14
	sxtw	x14, w14
LBB29_18:                               ; =>This Inner Loop Header: Depth=1
	cmp	w14, w10
	csel	w15, wzr, w13, lt
	cmp	w14, #0
	csel	w15, w10, w15, lt
	add	x15, x14, w15, sxtw
	ldr	x15, [x11, x15, lsl #3]
	add	x12, x15, x12
	cmp	x12, x9
	b.ge	LBB29_22
; %bb.19:                               ;   in Loop: Header=BB29_18 Depth=1
	mov	x15, #0                         ; =0x0
	add	w8, w8, #1
	add	x14, x14, #1
	cmp	w10, w8
	b.ne	LBB29_18
	b	LBB29_23
LBB29_20:
	add	x8, x8, #1
	b	LBB29_22
LBB29_21:
	add	x8, x8, #2
LBB29_22:
	ldp	w9, w10, [x0, #24]
	lsr	w9, w8, w9
	mov	w11, #2147483647                ; =0x7fffffff
	add	w11, w10, w11
	and	w8, w11, w8
	cmp	w9, #1
	csinc	w11, w9, wzr, gt
	ldr	w12, [x0, #16]
	add	w11, w11, w12
	cmp	w9, #0
	csel	w9, wzr, w10, eq
	add	w8, w8, w9
	sxtw	x8, w8
	sub	w9, w11, #1
	lsl	x15, x8, x9
LBB29_23:
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
	b.ne	LBB29_25
; %bb.24:
	mov	x0, x8
	ret
LBB29_25:
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
	mov	x0, x8
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_value_at_percentiles       ; -- Begin function hdr_value_at_percentiles
	.p2align	2
_hdr_value_at_percentiles:              ; @hdr_value_at_percentiles
	.cfi_startproc
; %bb.0:
	mov	w8, #22                         ; =0x16
	cbz	x1, LBB30_33
; %bb.1:
	cbz	x2, LBB30_33
; %bb.2:
	sub	sp, sp, #208
	stp	x26, x25, [sp, #128]            ; 16-byte Folded Spill
	stp	x24, x23, [sp, #144]            ; 16-byte Folded Spill
	stp	x22, x21, [sp, #160]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #176]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #192]            ; 16-byte Folded Spill
	add	x29, sp, #192
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
	cbz	x3, LBB30_10
; %bb.3:
	ldr	d0, [x0, #88]
	scvtf	d0, d0
	cmp	x3, #8
	b.hs	LBB30_5
; %bb.4:
	mov	x8, #0                          ; =0x0
	b	LBB30_8
LBB30_5:
	and	x8, x3, #0xfffffffffffffff8
	add	x9, x1, #32
	mov	x10, #4636737291354636288       ; =0x4059000000000000
	dup.2d	v1, x10
	add	x10, x2, #32
	fmov.2d	v2, #0.50000000
	mov	w11, #1                         ; =0x1
	dup.2d	v3, x11
	mov	x11, x8
LBB30_6:                                ; =>This Inner Loop Header: Depth=1
	ldp	q4, q5, [x9, #-32]
	ldp	q6, q7, [x9], #64
	fminnm.2d	v4, v4, v1
	fminnm.2d	v5, v5, v1
	fminnm.2d	v6, v6, v1
	fminnm.2d	v7, v7, v1
	fdiv.2d	v4, v4, v1
	fdiv.2d	v5, v5, v1
	fdiv.2d	v6, v6, v1
	fdiv.2d	v7, v7, v1
	mov.16b	v16, v2
	fmla.2d	v16, v4, v0[0]
	mov.16b	v4, v2
	fmla.2d	v4, v5, v0[0]
	mov.16b	v5, v2
	fmla.2d	v5, v6, v0[0]
	mov.16b	v6, v2
	fmla.2d	v6, v7, v0[0]
	fcvtzs.2d	v7, v16
	fcvtzs.2d	v4, v4
	fcvtzs.2d	v5, v5
	fcvtzs.2d	v6, v6
	cmgt.2d	v16, v7, v3
	and.16b	v7, v7, v16
	mvn.16b	v16, v16
	sub.2d	v7, v7, v16
	cmgt.2d	v16, v4, v3
	and.16b	v4, v4, v16
	mvn.16b	v16, v16
	sub.2d	v4, v4, v16
	cmgt.2d	v16, v5, v3
	and.16b	v5, v5, v16
	mvn.16b	v16, v16
	sub.2d	v5, v5, v16
	cmgt.2d	v16, v6, v3
	and.16b	v6, v6, v16
	mvn.16b	v16, v16
	stp	q7, q4, [x10, #-32]
	sub.2d	v4, v6, v16
	stp	q5, q4, [x10], #64
	subs	x11, x11, #8
	b.ne	LBB30_6
; %bb.7:
	cmp	x3, x8
	b.eq	LBB30_10
LBB30_8:
	sub	x9, x3, x8
	lsl	x10, x8, #3
	add	x8, x2, x10
	add	x10, x1, x10
	mov	x11, #4636737291354636288       ; =0x4059000000000000
	fmov	d1, x11
	fmov	d2, #0.50000000
LBB30_9:                                ; =>This Inner Loop Header: Depth=1
	ldr	d3, [x10], #8
	fminnm	d3, d3, d1
	fdiv	d3, d3, d1
	fmadd	d3, d3, d0, d2
	fcvtzs	x11, d3
	cmp	x11, #1
	csinc	x11, x11, xzr, gt
	str	x11, [x8], #8
	subs	x9, x9, #1
	b.ne	LBB30_9
LBB30_10:
	ldr	w8, [x0, #64]
	cbnz	w8, LBB30_34
; %bb.11:
	mov	w12, #0                         ; =0x0
	mov	x9, #0                          ; =0x0
	ldr	x8, [x0, #96]
	ldr	w11, [x0, #80]
	mov	x10, #0                         ; =0x0
	cmp	w11, #8
	b.lt	LBB30_24
; %bb.12:
	cbz	x3, LBB30_24
; %bb.13:
	mov	x13, #0                         ; =0x0
	mov	x10, #0                         ; =0x0
	mov	x9, #0                          ; =0x0
	mov	w1, #8                          ; =0x8
	mov	w14, #2147483647                ; =0x7fffffff
	mov	w15, #63                        ; =0x3f
	mov	w16, #1                         ; =0x1
	mov	x17, #9223372036854775807       ; =0x7fffffffffffffff
LBB30_14:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB30_21 Depth 2
                                        ;       Child Loop BB30_22 Depth 3
	mov	x12, x1
	add	x1, x8, x13, lsl #3
	ldp	q0, q1, [x1, #32]
	ldp	q2, q3, [x1]
	add.2d	v1, v3, v1
	add.2d	v0, v2, v0
	add.2d	v0, v0, v1
	addp.2d	d0, v0
	fmov	x1, d0
	ldr	x4, [x2, x9, lsl #3]
	add	x1, x1, x10
	cmp	x1, x4
	b.ge	LBB30_18
; %bb.15:                               ;   in Loop: Header=BB30_14 Depth=1
	mov	x10, x1
LBB30_16:                               ;   in Loop: Header=BB30_14 Depth=1
	add	x1, x12, #8
	cmp	x1, x11
	b.hi	LBB30_24
; %bb.17:                               ;   in Loop: Header=BB30_14 Depth=1
	add	x13, x13, #8
	cmp	x9, x3
	b.lo	LBB30_14
	b	LBB30_24
LBB30_18:                               ;   in Loop: Header=BB30_14 Depth=1
	mov	x1, x13
	b	LBB30_21
LBB30_19:                               ;   in Loop: Header=BB30_21 Depth=2
	mov	x9, x3
LBB30_20:                               ;   in Loop: Header=BB30_21 Depth=2
	add	x1, x1, #1
	cmp	x1, x12
	b.eq	LBB30_16
LBB30_21:                               ;   Parent Loop BB30_14 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB30_22 Depth 3
	ldr	x4, [x8, x1, lsl #3]
	add	x10, x4, x10
	cmp	x9, x3
	b.hs	LBB30_20
LBB30_22:                               ;   Parent Loop BB30_14 Depth=1
                                        ;     Parent Loop BB30_21 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	ldr	x4, [x2, x9, lsl #3]
	cmp	x10, x4
	b.lt	LBB30_20
; %bb.23:                               ;   in Loop: Header=BB30_22 Depth=3
	ldp	w4, w5, [x0, #24]
	lsr	w6, w1, w4
	add	w7, w5, w14
	and	w7, w7, w1
	cmp	w6, #1
	csinc	w19, w6, wzr, gt
	ldr	w20, [x0, #16]
	add	w19, w19, w20
	cmp	w6, #0
	csel	w5, wzr, w5, eq
	add	w5, w7, w5
	sxtw	x5, w5
	sub	w6, w19, #1
	lsl	x5, x5, x6
	ldr	x6, [x0, #32]
	orr	x6, x5, x6
	clz	x6, x6
	add	w4, w4, w6
	sub	w6, w15, w4
	mvn	w4, w4
	asr	x5, x5, x4
	sxtw	x5, w5
	lsl	x4, x5, x4
	ldr	w7, [x0, #40]
	cmp	w7, w5
	cinc	w5, w6, le
	lsl	x5, x16, x5
	eor	x6, x5, #0x7fffffffffffffff
	add	x5, x4, x5
	sub	x5, x5, #1
	cmp	x4, x6
	csel	x4, x17, x5, gt
	str	x4, [x2, x9, lsl #3]
	add	x9, x9, #1
	cmp	x3, x9
	b.ne	LBB30_22
	b	LBB30_19
LBB30_24:
	cmp	w12, w11
	b.ge	LBB30_32
; %bb.25:
	cmp	x9, x3
	b.hs	LBB30_32
; %bb.26:
	sxtw	x11, w11
	mov	w13, #2147483647                ; =0x7fffffff
	mov	w14, #63                        ; =0x3f
	mov	w15, #1                         ; =0x1
	mov	x16, #9223372036854775807       ; =0x7fffffffffffffff
	mov	w12, w12
LBB30_27:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB30_28 Depth 2
	ldr	x17, [x8, x12, lsl #3]
	add	x10, x17, x10
LBB30_28:                               ;   Parent Loop BB30_27 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	x17, [x2, x9, lsl #3]
	cmp	x10, x17
	b.lt	LBB30_30
; %bb.29:                               ;   in Loop: Header=BB30_28 Depth=2
	ldp	w17, w1, [x0, #24]
	lsr	w4, w12, w17
	add	w5, w1, w13
	and	w5, w5, w12
	cmp	w4, #1
	csinc	w6, w4, wzr, gt
	ldr	w7, [x0, #16]
	add	w6, w6, w7
	cmp	w4, #0
	csel	w1, wzr, w1, eq
	add	w1, w5, w1
	sxtw	x1, w1
	sub	w4, w6, #1
	lsl	x1, x1, x4
	ldr	x4, [x0, #32]
	orr	x4, x1, x4
	clz	x4, x4
	add	w17, w17, w4
	sub	w4, w14, w17
	mvn	w17, w17
	asr	x1, x1, x17
	sxtw	x1, w1
	lsl	x17, x1, x17
	ldr	w5, [x0, #40]
	cmp	w5, w1
	cinc	w1, w4, le
	lsl	x1, x15, x1
	eor	x4, x1, #0x7fffffffffffffff
	add	x1, x17, x1
	sub	x1, x1, #1
	cmp	x17, x4
	csel	x17, x16, x1, gt
	str	x17, [x2, x9, lsl #3]
	add	x9, x9, #1
	cmp	x9, x3
	b.lo	LBB30_28
LBB30_30:                               ;   in Loop: Header=BB30_27 Depth=1
	add	x12, x12, #1
	cmp	x12, x11
	b.ge	LBB30_32
; %bb.31:                               ;   in Loop: Header=BB30_27 Depth=1
	cmp	x9, x3
	b.lo	LBB30_27
LBB30_32:
	mov	w8, #0                          ; =0x0
	ldp	x29, x30, [sp, #192]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #176]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #160]            ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #144]            ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #128]            ; 16-byte Folded Reload
	add	sp, sp, #208
LBB30_33:
	mov	x0, x8
	ret
LBB30_34:
	str	x0, [sp]
	mov	w8, #-1                         ; =0xffffffff
	str	w8, [sp, #8]
	ldr	x8, [x0, #88]
	str	x8, [sp, #16]
	movi.2d	v0, #0000000000000000
	stur	q0, [sp, #24]
	stur	q0, [sp, #40]
	stp	xzr, xzr, [sp, #72]
Lloh14:
	adrp	x8, _all_values_iter_next@PAGE
Lloh15:
	add	x8, x8, _all_values_iter_next@PAGEOFF
	str	x8, [sp, #120]
	mov	x19, x0
	mov	x0, sp
	mov	x20, x3
	mov	x21, x2
	bl	_all_values_iter_next
	cbz	x20, LBB30_32
; %bb.35:
	cbz	w0, LBB30_32
; %bb.36:
	mov	x8, x21
	mov	x9, x20
	mov	x10, x19
	mov	x22, #0                         ; =0x0
	mov	x23, #0                         ; =0x0
	mov	w24, #63                        ; =0x3f
	mov	w25, #1                         ; =0x1
	mov	x26, #9223372036854775807       ; =0x7fffffffffffffff
LBB30_37:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB30_38 Depth 2
	ldr	x12, [sp, #24]
	ldr	x11, [sp, #40]
	add	x22, x12, x22
LBB30_38:                               ;   Parent Loop BB30_37 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	x12, [x8, x23, lsl #3]
	cmp	x22, x12
	b.lt	LBB30_40
; %bb.39:                               ;   in Loop: Header=BB30_38 Depth=2
	ldr	x12, [x10, #32]
	orr	x12, x12, x11
	clz	x12, x12
	ldr	w13, [x10, #24]
	add	w12, w13, w12
	sub	w13, w24, w12
	mvn	w12, w12
	asr	x14, x11, x12
	sxtw	x14, w14
	lsl	x12, x14, x12
	ldr	w15, [x10, #40]
	cmp	w15, w14
	cinc	w13, w13, le
	lsl	x13, x25, x13
	eor	x14, x13, #0x7fffffffffffffff
	add	x13, x12, x13
	sub	x13, x13, #1
	cmp	x12, x14
	csel	x12, x26, x13, gt
	str	x12, [x8, x23, lsl #3]
	add	x23, x23, #1
	cmp	x23, x9
	b.lo	LBB30_38
LBB30_40:                               ;   in Loop: Header=BB30_37 Depth=1
	ldr	x8, [sp, #120]
	mov	x0, sp
	blr	x8
	cmp	x23, x20
	b.hs	LBB30_32
; %bb.41:                               ;   in Loop: Header=BB30_37 Depth=1
	mov	x8, x21
	mov	x9, x20
	mov	x10, x19
	tbnz	w0, #0, LBB30_37
	b	LBB30_32
	.loh AdrpAdd	Lloh14, Lloh15
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_iter_init                  ; -- Begin function hdr_iter_init
	.p2align	2
_hdr_iter_init:                         ; @hdr_iter_init
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
Lloh16:
	adrp	x8, _all_values_iter_next@PAGE
Lloh17:
	add	x8, x8, _all_values_iter_next@PAGEOFF
	str	x8, [x0, #120]
	ret
	.loh AdrpAdd	Lloh16, Lloh17
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_mean                       ; -- Begin function hdr_mean
	.p2align	2
_hdr_mean:                              ; @hdr_mean
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #208
	stp	d9, d8, [sp, #128]              ; 16-byte Folded Spill
	stp	x24, x23, [sp, #144]            ; 16-byte Folded Spill
	stp	x22, x21, [sp, #160]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #176]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #192]            ; 16-byte Folded Spill
	add	x29, sp, #192
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset w23, -56
	.cfi_offset w24, -64
	.cfi_offset b8, -72
	.cfi_offset b9, -80
	mov	x19, x0
	ldr	x20, [x0, #88]
	str	x0, [sp]
	mov	w8, #-1                         ; =0xffffffff
	str	w8, [sp, #8]
	str	x20, [sp, #16]
	movi.2d	v0, #0000000000000000
	stur	q0, [sp, #24]
	stur	q0, [sp, #40]
	stp	xzr, xzr, [sp, #72]
Lloh18:
	adrp	x8, _all_values_iter_next@PAGE
Lloh19:
	add	x8, x8, _all_values_iter_next@PAGEOFF
	str	x8, [sp, #120]
	mov	x0, sp
	bl	_all_values_iter_next
	movi.2d	v8, #0000000000000000
	cbz	w0, LBB32_6
; %bb.1:
	cmp	x20, #1
	b.lt	LBB32_6
; %bb.2:
	mov	x21, #0                         ; =0x0
	mov	w22, #63                        ; =0x3f
	mov	w23, #1                         ; =0x1
	b	LBB32_4
LBB32_3:                                ;   in Loop: Header=BB32_4 Depth=1
	ldr	x8, [sp, #120]
	mov	x0, sp
	blr	x8
	cmp	w0, #0
	ccmp	x21, x20, #0, ne
	b.ge	LBB32_6
LBB32_4:                                ; =>This Inner Loop Header: Depth=1
	ldr	x8, [sp, #24]
	cbz	x8, LBB32_3
; %bb.5:                                ;   in Loop: Header=BB32_4 Depth=1
	add	x21, x8, x21
	scvtf	d0, x8
	ldr	x8, [sp, #40]
	ldr	x9, [x19, #32]
	orr	x9, x9, x8
	clz	x9, x9
	ldr	w10, [x19, #24]
	add	w9, w10, w9
	sub	w10, w22, w9
	mvn	w9, w9
	asr	x8, x8, x9
	sxtw	x8, w8
	lsl	x9, x8, x9
	ldr	w11, [x19, #40]
	cmp	w11, w8
	cinc	w8, w10, le
	lsl	x8, x23, x8
	add	x8, x9, x8, asr #1
	scvtf	d1, x8
	fmadd	d8, d0, d1, d8
	b	LBB32_3
LBB32_6:
	scvtf	d0, x20
	fdiv	d0, d8, d0
	ldp	x29, x30, [sp, #192]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #176]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #160]            ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #144]            ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #128]              ; 16-byte Folded Reload
	add	sp, sp, #208
	ret
	.loh AdrpAdd	Lloh18, Lloh19
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_stddev                     ; -- Begin function hdr_stddev
	.p2align	2
_hdr_stddev:                            ; @hdr_stddev
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #208
	stp	d9, d8, [sp, #128]              ; 16-byte Folded Spill
	stp	x24, x23, [sp, #144]            ; 16-byte Folded Spill
	stp	x22, x21, [sp, #160]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #176]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #192]            ; 16-byte Folded Spill
	add	x29, sp, #192
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset w23, -56
	.cfi_offset w24, -64
	.cfi_offset b8, -72
	.cfi_offset b9, -80
	mov	x19, x0
	ldr	x20, [x0, #88]
	mov	x22, x20
	str	x0, [sp]
Lloh20:
	adrp	x21, _all_values_iter_next@PAGE
Lloh21:
	add	x21, x21, _all_values_iter_next@PAGEOFF
	str	x20, [sp, #16]
	str	x21, [sp, #120]
	str	wzr, [sp, #8]
	ldr	w8, [x0, #80]
	movi.2d	v8, #0000000000000000
	cmp	w8, #1
	b.lt	LBB33_7
; %bb.1:
	ldr	w9, [x19, #64]
	cmn	w8, w9
	csneg	w10, wzr, w8, gt
	cmp	w9, #0
	csel	w8, w8, w10, gt
	sub	w8, w8, w9
	sxtw	x8, w8
	cmp	w9, #0
	csel	x8, xzr, x8, eq
	ldr	x9, [x19, #96]
	ldr	x8, [x9, x8, lsl #3]
	mov	x9, sp
	stp	x8, x8, [sp, #24]
	ldr	w8, [x19, #24]
	ldr	x10, [x19, #32]
	clz	x10, x10
	ldr	w11, [x19, #40]
	cmp	w11, #1
	cset	w11, lt
	add	w8, w8, w10
	sub	w8, w11, w8
	add	w8, w8, #63
	mov	w10, #1                         ; =0x1
	lsl	x8, x10, x8
	sub	x10, x8, #1
	stp	xzr, x10, [sp, #40]
	asr	x8, x8, #1
	stp	xzr, x8, [sp, #56]
	stp	xzr, xzr, [x9, #72]
	movi.2d	v9, #0000000000000000
	cmp	x20, #1
	b.lt	LBB33_8
; %bb.2:
	mov	x22, #0                         ; =0x0
	mov	w23, #63                        ; =0x3f
	mov	w24, #1                         ; =0x1
	b	LBB33_4
LBB33_3:                                ;   in Loop: Header=BB33_4 Depth=1
	ldr	x8, [sp, #120]
	mov	x0, sp
	blr	x8
	cmp	w0, #0
	ccmp	x22, x20, #0, ne
	b.ge	LBB33_6
LBB33_4:                                ; =>This Inner Loop Header: Depth=1
	ldr	x8, [sp, #24]
	cbz	x8, LBB33_3
; %bb.5:                                ;   in Loop: Header=BB33_4 Depth=1
	add	x22, x8, x22
	scvtf	d0, x8
	ldr	x8, [sp, #40]
	ldr	x9, [x19, #32]
	orr	x9, x9, x8
	clz	x9, x9
	ldr	w10, [x19, #24]
	add	w9, w10, w9
	sub	w10, w23, w9
	mvn	w9, w9
	asr	x8, x8, x9
	sxtw	x8, w8
	lsl	x9, x8, x9
	ldr	w11, [x19, #40]
	cmp	w11, w8
	cinc	w8, w10, le
	lsl	x8, x24, x8
	add	x8, x9, x8, asr #1
	scvtf	d1, x8
	fmadd	d9, d0, d1, d9
	b	LBB33_3
LBB33_6:
	ldr	x22, [x19, #88]
	b	LBB33_8
LBB33_7:
	movi.2d	v9, #0000000000000000
LBB33_8:
	str	x19, [sp]
	mov	w8, #-1                         ; =0xffffffff
	str	w8, [sp, #8]
	str	x22, [sp, #16]
	movi.2d	v0, #0000000000000000
	stur	q0, [sp, #24]
	stur	q0, [sp, #40]
	stp	xzr, xzr, [sp, #72]
	str	x21, [sp, #120]
	mov	x0, sp
	bl	_all_values_iter_next
	cbz	w0, LBB33_14
; %bb.9:
	scvtf	d0, x20
	fdiv	d9, d9, d0
	movi.2d	v8, #0000000000000000
	mov	w20, #63                        ; =0x3f
	mov	w21, #1                         ; =0x1
	b	LBB33_11
LBB33_10:                               ;   in Loop: Header=BB33_11 Depth=1
	ldr	x8, [sp, #120]
	mov	x0, sp
	blr	x8
	tbz	w0, #0, LBB33_13
LBB33_11:                               ; =>This Inner Loop Header: Depth=1
	ldr	x8, [sp, #24]
	cbz	x8, LBB33_10
; %bb.12:                               ;   in Loop: Header=BB33_11 Depth=1
	ldr	x9, [sp, #40]
	ldr	x10, [x19, #32]
	orr	x10, x10, x9
	clz	x10, x10
	ldr	w11, [x19, #24]
	add	w10, w11, w10
	sub	w11, w20, w10
	mvn	w10, w10
	asr	x9, x9, x10
	sxtw	x9, w9
	lsl	x10, x9, x10
	ldr	w12, [x19, #40]
	cmp	w12, w9
	cinc	w9, w11, le
	lsl	x9, x21, x9
	add	x9, x10, x9, asr #1
	scvtf	d0, x9
	fsub	d0, d0, d9
	fmul	d0, d0, d0
	scvtf	d1, x8
	fmadd	d8, d0, d1, d8
	b	LBB33_10
LBB33_13:
	ldr	x22, [x19, #88]
LBB33_14:
	scvtf	d0, x22
	fdiv	d0, d8, d0
	fsqrt	d0, d0
	ldp	x29, x30, [sp, #192]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #176]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #160]            ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #144]            ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #128]              ; 16-byte Folded Reload
	add	sp, sp, #208
	ret
	.loh AdrpAdd	Lloh20, Lloh21
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_values_are_equivalent      ; -- Begin function hdr_values_are_equivalent
	.p2align	2
_hdr_values_are_equivalent:             ; @hdr_values_are_equivalent
	.cfi_startproc
; %bb.0:
	ldr	x8, [x0, #32]
	orr	x9, x8, x1
	clz	x9, x9
	ldr	w10, [x0, #24]
	add	w9, w10, w9
	mvn	w9, w9
	asr	x11, x1, x9
	sxtw	x11, w11
	lsl	x9, x11, x9
	orr	x8, x8, x2
	clz	x8, x8
	add	w8, w10, w8
	mvn	w8, w8
	asr	x10, x2, x8
	sxtw	x10, w10
	lsl	x8, x10, x8
	cmp	x9, x8
	cset	w0, eq
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_lowest_equivalent_value    ; -- Begin function hdr_lowest_equivalent_value
	.p2align	2
_hdr_lowest_equivalent_value:           ; @hdr_lowest_equivalent_value
	.cfi_startproc
; %bb.0:
	ldr	x8, [x0, #32]
	orr	x8, x8, x1
	clz	x8, x8
	ldr	w9, [x0, #24]
	add	w8, w9, w8
	mvn	w8, w8
	asr	x9, x1, x8
	sxtw	x9, w9
	lsl	x0, x9, x8
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_count_at_value             ; -- Begin function hdr_count_at_value
	.p2align	2
_hdr_count_at_value:                    ; @hdr_count_at_value
	.cfi_startproc
; %bb.0:
	tbnz	x1, #63, LBB36_3
; %bb.1:
	ldr	x8, [x0, #32]
	orr	x8, x8, x1
	clz	x8, x8
	ldr	w9, [x0, #16]
	ldp	w10, w11, [x0, #24]
	add	w12, w10, w9
	add	w8, w12, w8
	sub	w9, w9, w8
	add	w9, w9, #63
	lsr	x9, x1, x9
	mov	w12, #64                        ; =0x40
	sub	w8, w12, w8
	lsl	w8, w8, w10
	sub	w8, w8, w11
	add	w8, w8, w9
	ldr	w9, [x0, #80]
	cmp	w8, w9
	b.hs	LBB36_3
; %bb.2:
	ldr	w10, [x0, #64]
	sub	w11, w8, w10
	cmp	w11, w9
	csneg	w12, wzr, w9, lt
	cmp	w11, #0
	csel	w9, w9, w12, lt
	add	w9, w9, w11
	cmp	w10, #0
	csel	w8, w8, w9, eq
	ldr	x9, [x0, #96]
	ldr	x0, [x9, w8, sxtw #3]
	ret
LBB36_3:
	mov	x0, #0                          ; =0x0
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function all_values_iter_next
_all_values_iter_next:                  ; @all_values_iter_next
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
	mov	x19, x0
	bl	_move_next
	cbz	w0, LBB37_2
; %bb.1:
	ldr	x8, [x19, #40]
	ldr	x9, [x19, #80]
	stp	x9, x8, [x19, #72]
LBB37_2:
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_iter_percentile_init       ; -- Begin function hdr_iter_percentile_init
	.p2align	2
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
                                        ; -- End function
	.p2align	2                               ; -- Begin function percentile_iter_next
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
	b.ge	LBB39_3
; %bb.1:
	ldr	w8, [x19, #8]
	cmn	w8, #1
	b.eq	LBB39_5
; %bb.2:
	mov	x8, #4636737291354636288        ; =0x4059000000000000
	fmov	d9, x8
	ldr	x8, [x19]
	ldp	x10, x9, [x19, #24]
	cbnz	x10, LBB39_7
	b	LBB39_8
LBB39_3:
	ldrb	w8, [x19, #88]
	tbnz	w8, #0, LBB39_12
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
LBB39_5:
	ldr	x8, [x19]
	ldr	w8, [x8, #80]
	tbnz	w8, #31, LBB39_12
; %bb.6:
	mov	x0, x19
	bl	_move_next
	mov	x8, #4636737291354636288        ; =0x4059000000000000
	fmov	d9, x8
	ldr	x8, [x19]
	ldp	x10, x9, [x19, #24]
	cbz	x10, LBB39_8
LBB39_7:
	scvtf	d0, x9
	fmul	d0, d0, d9
	ldr	d1, [x8, #88]
	scvtf	d1, d1
	fdiv	d0, d0, d1
	ldr	d8, [x19, #96]
	fcmp	d8, d0
	b.ls	LBB39_13
LBB39_8:                                ; =>This Inner Loop Header: Depth=1
	ldr	x10, [x19, #16]
	cmp	x9, x10
	b.ge	LBB39_11
; %bb.9:                                ;   in Loop: Header=BB39_8 Depth=1
	ldr	w9, [x19, #8]
	ldr	w8, [x8, #80]
	cmp	w9, w8
	b.ge	LBB39_11
; %bb.10:                               ;   in Loop: Header=BB39_8 Depth=1
	mov	x0, x19
	bl	_move_next
	ldr	x8, [x19]
	ldp	x10, x9, [x19, #24]
	cbnz	x10, LBB39_7
	b	LBB39_8
LBB39_11:
	mov	w20, #1                         ; =0x1
	mov	x0, x20
	ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #48               ; 16-byte Folded Reload
	ret
LBB39_12:
	mov	w20, #0                         ; =0x0
	mov	x0, x20
	ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #48               ; 16-byte Folded Reload
	ret
LBB39_13:
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
                                        ; -- End function
	.p2align	2                               ; -- Begin function recorded_iter_next
_recorded_iter_next:                    ; @recorded_iter_next
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
	mov	x19, x0
LBB40_1:                                ; =>This Inner Loop Header: Depth=1
	ldr	x8, [x19, #16]
	ldr	x9, [x19, #32]
	cmp	x9, x8
	b.ge	LBB40_5
; %bb.2:                                ;   in Loop: Header=BB40_1 Depth=1
	ldr	w8, [x19, #8]
	ldr	x9, [x19]
	ldr	w9, [x9, #80]
	cmp	w8, w9
	b.ge	LBB40_5
; %bb.3:                                ;   in Loop: Header=BB40_1 Depth=1
	mov	x0, x19
	bl	_move_next
	ldr	x8, [x19, #24]
	cbz	x8, LBB40_1
; %bb.4:
	ldr	x9, [x19, #40]
	ldr	x10, [x19, #80]
	stp	x10, x9, [x19, #72]
	str	x8, [x19, #88]
	mov	w0, #1                          ; =0x1
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
LBB40_5:
	mov	w0, #0                          ; =0x0
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_iter_linear_init           ; -- Begin function hdr_iter_linear_init
	.p2align	2
_hdr_iter_linear_init:                  ; @hdr_iter_linear_init
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
	stp	x2, xzr, [x0, #88]
	cmp	x2, #0
	b.le	LBB41_2
; %bb.1:
	str	x2, [x0, #104]
	ldr	x8, [x1, #32]
	orr	x8, x8, x2
	clz	x8, x8
	ldr	w9, [x1, #24]
	add	w8, w9, w8
	mvn	w8, w8
	lsr	x9, x2, x8
	sxtw	x9, w9
	lsl	x8, x9, x8
Lloh24:
	adrp	x9, _iter_linear_next@PAGE
Lloh25:
	add	x9, x9, _iter_linear_next@PAGEOFF
	stp	x8, x9, [x0, #112]
	ret
LBB41_2:
	mov	x8, #9223372036854775807        ; =0x7fffffffffffffff
	str	x8, [x0, #104]
Lloh26:
	adrp	x9, _iter_linear_next@PAGE
Lloh27:
	add	x9, x9, _iter_linear_next@PAGEOFF
	stp	x8, x9, [x0, #112]
	ret
	.loh AdrpAdd	Lloh24, Lloh25
	.loh AdrpAdd	Lloh26, Lloh27
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function iter_linear_next
_iter_linear_next:                      ; @iter_linear_next
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
	mov	x19, x0
	str	xzr, [x0, #96]
	ldr	x9, [x0, #16]
	ldr	x10, [x0, #32]
	ldr	x8, [x0, #112]
	cmp	x10, x9
	b.ge	LBB42_8
LBB42_1:
	ldr	x9, [x19, #40]
	cmp	x9, x8
	b.ge	LBB42_4
LBB42_2:                                ; =>This Inner Loop Header: Depth=1
	mov	x0, x19
	bl	_move_next
	cbz	w0, LBB42_16
; %bb.3:                                ;   in Loop: Header=BB42_2 Depth=1
	ldr	x8, [x19, #24]
	ldr	x9, [x19, #96]
	add	x8, x9, x8
	str	x8, [x19, #96]
	ldr	x8, [x19, #40]
	ldr	x9, [x19, #112]
	cmp	x8, x9
	b.lt	LBB42_2
LBB42_4:
	ldr	x8, [x19, #104]
	ldr	x9, [x19, #80]
	stp	x9, x8, [x19, #72]
	mov	x9, #9223372036854775807        ; =0x7fffffffffffffff
	cmp	x8, x9
	b.eq	LBB42_15
; %bb.5:
	ldr	x9, [x19, #88]
	cmp	x9, #1
	b.lt	LBB42_13
; %bb.6:
	eor	x10, x9, #0x7fffffffffffffff
	cmp	x8, x10
	b.gt	LBB42_13
; %bb.7:
	ldr	x10, [x19]
	ldr	x11, [x10, #32]
	add	x8, x9, x8
	orr	x9, x11, x8
	str	x8, [x19, #104]
	clz	x9, x9
	ldr	w10, [x10, #24]
	add	w9, w10, w9
	mvn	w9, w9
	asr	x8, x8, x9
	b	LBB42_14
LBB42_8:
	ldr	x10, [x19]
	ldr	w9, [x19, #8]
	ldr	w11, [x10, #80]
	cmp	w9, w11
	b.ge	LBB42_12
; %bb.9:
	add	w11, w9, #1
	ldr	w9, [x10, #24]
	lsr	w13, w11, w9
	cmp	w13, #1
	csinc	w9, w13, wzr, gt
	ldr	w12, [x10, #16]
	add	w9, w12, w9
	sub	w12, w9, #1
	mov	x9, #9223372036854775807        ; =0x7fffffffffffffff
	cmp	w12, #62
	b.gt	LBB42_11
; %bb.10:
	ldr	w10, [x10, #28]
	sub	w14, w10, #1
	and	w11, w14, w11
	cmp	w13, #0
	csel	w10, w10, wzr, gt
	add	w10, w11, w10
	sxtw	x10, w10
	lsr	x11, x9, x12
	lsl	x12, x10, x12
	cmp	x11, x10
	csel	x9, x9, x12, lo
LBB42_11:
	cmp	x9, x8
	b.gt	LBB42_1
LBB42_12:
	mov	w0, #0                          ; =0x0
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
LBB42_13:
	mov	x8, #9223372036854775807        ; =0x7fffffffffffffff
	str	x8, [x19, #104]
	ldr	x9, [x19]
	ldr	x10, [x9, #32]
	orr	x10, x10, #0x7fffffffffffffff
	clz	x10, x10
	ldr	w9, [x9, #24]
	add	w9, w9, w10
	mvn	w9, w9
	lsr	x8, x8, x9
LBB42_14:
	sxtw	x8, w8
	lsl	x9, x8, x9
LBB42_15:
	str	x9, [x19, #112]
LBB42_16:
	mov	w0, #1                          ; =0x1
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_iter_log_init              ; -- Begin function hdr_iter_log_init
	.p2align	2
_hdr_iter_log_init:                     ; @hdr_iter_log_init
	.cfi_startproc
; %bb.0:
	str	x1, [x0]
	mov	w8, #-1                         ; =0xffffffff
	str	w8, [x0, #8]
	ldr	x8, [x1, #88]
	str	x8, [x0, #16]
	movi.2d	v1, #0000000000000000
	stur	q1, [x0, #40]
	stur	q1, [x0, #24]
	stp	xzr, xzr, [x0, #72]
	str	d0, [x0, #88]
	stp	xzr, x2, [x0, #96]
	cmp	x2, #1
	b.lt	LBB43_4
; %bb.1:
	fmov	x8, d0
	and	x8, x8, #0x7fffffffffffffff
	mov	x9, #9218868437227405311        ; =0x7fefffffffffffff
	cmp	x8, x9
	cset	w8, gt
	mov	x9, #4890909195324358656        ; =0x43e0000000000000
	fmov	d1, x9
	fcmp	d0, d1
	b.ge	LBB43_4
; %bb.2:
	fmov	d1, #1.00000000
	fcmp	d0, d1
	ccmp	w8, #0, #0, hi
	b.ne	LBB43_4
; %bb.3:
	ldr	x8, [x1, #32]
	orr	x8, x8, x2
	clz	x8, x8
	ldr	w9, [x1, #24]
	add	w8, w9, w8
	mvn	w8, w8
	lsr	x9, x2, x8
	sxtw	x9, w9
	lsl	x8, x9, x8
Lloh28:
	adrp	x9, _log_iter_next@PAGE
Lloh29:
	add	x9, x9, _log_iter_next@PAGEOFF
	stp	x8, x9, [x0, #112]
	ret
LBB43_4:
	mov	x8, #9223372036854775807        ; =0x7fffffffffffffff
	str	x8, [x0, #104]
Lloh30:
	adrp	x9, _log_iter_next@PAGE
Lloh31:
	add	x9, x9, _log_iter_next@PAGEOFF
	stp	x8, x9, [x0, #112]
	ret
	.loh AdrpAdd	Lloh28, Lloh29
	.loh AdrpAdd	Lloh30, Lloh31
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function log_iter_next
_log_iter_next:                         ; @log_iter_next
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
	mov	x19, x0
	str	xzr, [x0, #96]
	ldr	x9, [x0, #16]
	ldr	x10, [x0, #32]
	ldr	x8, [x0, #112]
	cmp	x10, x9
	b.ge	LBB44_9
LBB44_1:
	ldr	x9, [x19, #40]
	cmp	x9, x8
	b.ge	LBB44_4
LBB44_2:                                ; =>This Inner Loop Header: Depth=1
	mov	x0, x19
	bl	_move_next
	cbz	w0, LBB44_18
; %bb.3:                                ;   in Loop: Header=BB44_2 Depth=1
	ldr	x8, [x19, #24]
	ldr	x9, [x19, #96]
	add	x8, x9, x8
	str	x8, [x19, #96]
	ldr	x8, [x19, #40]
	ldr	x9, [x19, #112]
	cmp	x8, x9
	b.lt	LBB44_2
LBB44_4:
	ldr	x9, [x19, #104]
	ldr	x8, [x19, #80]
	stp	x8, x9, [x19, #72]
	mov	x8, #9223372036854775807        ; =0x7fffffffffffffff
	cmp	x9, x8
	b.eq	LBB44_17
; %bb.5:
	cmp	x9, #1
	b.lt	LBB44_14
; %bb.6:
	ldr	d0, [x19, #88]
	fcvtzs	x10, d0
	cmp	x10, #1
	b.le	LBB44_14
; %bb.7:
	udiv	x11, x8, x10
	ldr	x8, [x19]
	cmp	x9, x11
	b.hi	LBB44_15
; %bb.8:
	mul	x9, x9, x10
	str	x9, [x19, #104]
	ldr	x10, [x8, #32]
	orr	x10, x10, x9
	b	LBB44_16
LBB44_9:
	ldr	x10, [x19]
	ldr	w9, [x19, #8]
	ldr	w11, [x10, #80]
	cmp	w9, w11
	b.ge	LBB44_13
; %bb.10:
	add	w11, w9, #1
	ldr	w9, [x10, #24]
	lsr	w13, w11, w9
	cmp	w13, #1
	csinc	w9, w13, wzr, gt
	ldr	w12, [x10, #16]
	add	w9, w12, w9
	sub	w12, w9, #1
	mov	x9, #9223372036854775807        ; =0x7fffffffffffffff
	cmp	w12, #62
	b.gt	LBB44_12
; %bb.11:
	ldr	w10, [x10, #28]
	sub	w14, w10, #1
	and	w11, w14, w11
	cmp	w13, #0
	csel	w10, w10, wzr, gt
	add	w10, w11, w10
	sxtw	x10, w10
	lsr	x11, x9, x12
	lsl	x12, x10, x12
	cmp	x11, x10
	csel	x9, x9, x12, lo
LBB44_12:
	cmp	x9, x8
	b.gt	LBB44_1
LBB44_13:
	mov	w0, #0                          ; =0x0
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
LBB44_14:
	ldr	x8, [x19]
LBB44_15:
	mov	x9, #9223372036854775807        ; =0x7fffffffffffffff
	str	x9, [x19, #104]
	ldr	x10, [x8, #32]
	orr	x10, x10, #0x7fffffffffffffff
LBB44_16:
	clz	x10, x10
	ldr	w8, [x8, #24]
	add	w8, w8, w10
	mvn	w8, w8
	lsr	x9, x9, x8
	sxtw	x9, w9
	lsl	x8, x9, x8
LBB44_17:
	str	x8, [x19, #112]
LBB44_18:
	mov	w0, #1                          ; =0x1
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_hdr_percentiles_print          ; -- Begin function hdr_percentiles_print
	.p2align	2
_hdr_percentiles_print:                 ; @hdr_percentiles_print
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #464
	stp	d11, d10, [sp, #352]            ; 16-byte Folded Spill
	stp	d9, d8, [sp, #368]              ; 16-byte Folded Spill
	stp	x28, x27, [sp, #384]            ; 16-byte Folded Spill
	stp	x24, x23, [sp, #400]            ; 16-byte Folded Spill
	stp	x22, x21, [sp, #416]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #432]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #448]            ; 16-byte Folded Spill
	add	x29, sp, #448
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
	mov.16b	v8, v0
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
	cbz	w3, LBB45_3
; %bb.1:
	cmp	w21, #1
	b.ne	LBB45_3
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
	b	LBB45_4
LBB45_3:
Lloh39:
	adrp	x9, l_.str.8@PAGE
Lloh40:
	add	x9, x9, l_.str.8@PAGEOFF
	str	x9, [sp, #16]
Lloh41:
	adrp	x9, l_.str.7@PAGE
Lloh42:
	add	x9, x9, l_.str.7@PAGEOFF
LBB45_4:
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
	tbnz	w0, #31, LBB45_8
; %bb.5:
	mov	x8, #4636737291354636288        ; =0x4059000000000000
	fmov	d9, x8
	fmov	d10, #1.00000000
LBB45_6:                                ; =>This Inner Loop Header: Depth=1
	ldr	x8, [sp, #176]
	add	x0, sp, #56
	blr	x8
	cbz	w0, LBB45_10
; %bb.7:                                ;   in Loop: Header=BB45_6 Depth=1
	ldr	d0, [sp, #104]
	ldr	d1, [sp, #160]
	scvtf	d0, d0
	fdiv	d0, d0, d8
	fdiv	d1, d1, d9
	ldr	x8, [sp, #88]
	fsub	d2, d10, d1
	fdiv	d2, d10, d2
	str	x8, [sp, #16]
	stp	d0, d1, [sp]
	sub	x1, x29, #129
	str	d2, [sp, #24]
	mov	x0, x19
	bl	_fprintf
	tbz	w0, #31, LBB45_6
LBB45_8:
	mov	w0, #5                          ; =0x5
	ldur	x8, [x29, #-104]
Lloh59:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh60:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh61:
	ldr	x9, [x9]
	cmp	x9, x8
	b.ne	LBB45_12
LBB45_9:
	ldp	x29, x30, [sp, #448]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #432]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #416]            ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #400]            ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #384]            ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #368]              ; 16-byte Folded Reload
	ldp	d11, d10, [sp, #352]            ; 16-byte Folded Reload
	add	sp, sp, #464
	ret
LBB45_10:
	cbz	w21, LBB45_13
; %bb.11:
	mov	w0, #0                          ; =0x0
	ldur	x8, [x29, #-104]
Lloh62:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh63:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh64:
	ldr	x9, [x9]
	cmp	x9, x8
	b.eq	LBB45_9
LBB45_12:
	bl	___stack_chk_fail
LBB45_13:
	ldr	x21, [x20, #88]
	str	x20, [sp, #184]
Lloh65:
	adrp	x8, _all_values_iter_next@PAGE
Lloh66:
	add	x8, x8, _all_values_iter_next@PAGEOFF
	str	x21, [sp, #200]
	str	x8, [sp, #304]
	str	wzr, [sp, #192]
	ldr	w8, [x20, #80]
	movi.2d	v9, #0000000000000000
	cmp	w8, #1
	b.lt	LBB45_19
; %bb.14:
	add	x9, sp, #184
	ldr	w10, [x20, #64]
	cmn	w8, w10
	csneg	w11, wzr, w8, gt
	cmp	w10, #0
	csel	w8, w8, w11, gt
	sub	w8, w8, w10
	sxtw	x8, w8
	cmp	w10, #0
	csel	x8, xzr, x8, eq
	ldr	x10, [x20, #96]
	ldr	x8, [x10, x8, lsl #3]
	stp	x8, x8, [sp, #208]
	ldr	w8, [x20, #24]
	ldr	x10, [x20, #32]
	clz	x10, x10
	ldr	w11, [x20, #40]
	cmp	w11, #1
	cset	w11, lt
	add	w8, w8, w10
	sub	w8, w11, w8
	add	w8, w8, #63
	mov	w10, #1                         ; =0x1
	lsl	x8, x10, x8
	sub	x10, x8, #1
	stp	xzr, x10, [sp, #224]
	asr	x8, x8, #1
	stp	xzr, x8, [sp, #240]
	stp	xzr, xzr, [x9, #72]
	cmp	x21, #1
	b.lt	LBB45_19
; %bb.15:
	mov	x22, #0                         ; =0x0
	mov	w23, #63                        ; =0x3f
	mov	w24, #1                         ; =0x1
	b	LBB45_17
LBB45_16:                               ;   in Loop: Header=BB45_17 Depth=1
	ldr	x8, [sp, #304]
	add	x0, sp, #184
	blr	x8
	cmp	w0, #0
	ccmp	x22, x21, #0, ne
	b.ge	LBB45_19
LBB45_17:                               ; =>This Inner Loop Header: Depth=1
	ldr	x8, [sp, #208]
	cbz	x8, LBB45_16
; %bb.18:                               ;   in Loop: Header=BB45_17 Depth=1
	add	x22, x8, x22
	scvtf	d0, x8
	ldr	x8, [sp, #224]
	ldr	x9, [x20, #32]
	orr	x9, x9, x8
	clz	x9, x9
	ldr	w10, [x20, #24]
	add	w9, w10, w9
	sub	w10, w23, w9
	mvn	w9, w9
	asr	x8, x8, x9
	sxtw	x8, w8
	lsl	x9, x8, x9
	ldr	w11, [x20, #40]
	cmp	w11, w8
	cinc	w8, w10, le
	lsl	x8, x24, x8
	add	x8, x9, x8, asr #1
	scvtf	d1, x8
	fmadd	d9, d0, d1, d9
	b	LBB45_16
LBB45_19:
	scvtf	d0, x21
	fdiv	d0, d9, d0
	fdiv	d9, d0, d8
	mov	x0, x20
	bl	_hdr_stddev
	ldr	x8, [x20, #56]
	fdiv	d0, d0, d8
	cbz	x8, LBB45_21
; %bb.20:
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
	b	LBB45_22
LBB45_21:
	ldr	w8, [x20, #40]
	movi.2d	v1, #0000000000000000
LBB45_22:
	ldr	x9, [x20, #88]
	ldr	w10, [x20, #44]
	fdiv	d1, d1, d8
	stp	x10, x8, [sp, #32]
	str	x9, [sp, #24]
	stp	d0, d1, [sp, #8]
	str	d9, [sp]
Lloh67:
	adrp	x1, _CLASSIC_FOOTER@PAGE
Lloh68:
	add	x1, x1, _CLASSIC_FOOTER@PAGEOFF
	mov	x0, x19
	bl	_fprintf
	mov	w8, #5                          ; =0x5
	and	w0, w8, w0, asr #31
	ldur	x8, [x29, #-104]
Lloh69:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh70:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh71:
	ldr	x9, [x9]
	cmp	x9, x8
	b.eq	LBB45_9
	b	LBB45_12
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
	.loh AdrpLdrGotLdr	Lloh59, Lloh60, Lloh61
	.loh AdrpLdrGotLdr	Lloh62, Lloh63, Lloh64
	.loh AdrpAdd	Lloh65, Lloh66
	.loh AdrpLdrGotLdr	Lloh69, Lloh70, Lloh71
	.loh AdrpAdd	Lloh67, Lloh68
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function move_next
_move_next:                             ; @move_next
	.cfi_startproc
; %bb.0:
	ldr	w11, [x0, #8]
	add	w8, w11, #1
	str	w8, [x0, #8]
	ldr	x10, [x0]
	ldr	w9, [x10, #80]
	cmp	w8, w9
	b.ge	LBB46_2
; %bb.1:
	ldr	w12, [x10, #64]
	sub	w13, w8, w12
	cmp	w13, w9
	csneg	w14, wzr, w9, lt
	cmp	w13, #0
	csel	w14, w9, w14, lt
	add	w13, w14, w13
	cmp	w12, #0
	csinc	w11, w13, w11, ne
	ldr	x12, [x10, #96]
	ldr	x11, [x12, w11, sxtw #3]
	ldr	x12, [x0, #32]
	add	x12, x12, x11
	stp	x11, x12, [x0, #24]
	ldp	w11, w12, [x10, #24]
	asr	w13, w8, w11
	sub	w14, w12, #1
	and	w14, w14, w8
	cmp	w13, #1
	csinc	w15, w13, wzr, gt
	ldr	w16, [x10, #16]
	add	w15, w15, w16
	cmp	w13, #0
	csel	w12, w12, wzr, gt
	add	w12, w14, w12
	sxtw	x12, w12
	sub	w13, w15, #1
	lsl	x12, x12, x13
	ldr	x13, [x10, #32]
	orr	x13, x12, x13
	clz	x13, x13
	mov	w14, #63                        ; =0x3f
	add	w11, w11, w13
	sub	w13, w14, w11
	mvn	w11, w11
	asr	x14, x12, x11
	sxtw	x15, w14
	lsl	x11, x15, x11
	ldr	w10, [x10, #40]
	cmp	w10, w14
	cinc	w10, w13, le
	mov	w13, #1                         ; =0x1
	lsl	x10, x13, x10
	eor	x13, x10, #0x7fffffffffffffff
	add	x14, x11, x10
	sub	x14, x14, #1
	mov	x15, #9223372036854775807       ; =0x7fffffffffffffff
	cmp	x11, x13
	csel	x13, x15, x14, gt
	stp	x12, x13, [x0, #40]
	add	x10, x11, x10, asr #1
	stp	x11, x10, [x0, #56]
LBB46_2:
	cmp	w8, w9
	cset	w0, lt
	ret
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"Value"

l_.str.1:                               ; @.str.1
	.asciz	"Percentile"

l_.str.2:                               ; @.str.2
	.asciz	"TotalCount"

l_.str.3:                               ; @.str.3
	.asciz	"1/(1-Percentile)"

	.section	__TEXT,__const
_CLASSIC_FOOTER:                        ; @CLASSIC_FOOTER
	.asciz	"#[Mean    = %12.3f, StdDeviation   = %12.3f]\n#[Max     = %12.3f, Total count    = %12llu]\n#[Buckets = %12d, SubBuckets     = %12d]\n"

	.section	__TEXT,__cstring,cstring_literals
l_.str.4:                               ; @.str.4
	.asciz	"%s%d%s"

l_.str.5:                               ; @.str.5
	.asciz	"%."

l_.str.6:                               ; @.str.6
	.asciz	"f,%f,%d,%.2f\n"

l_.str.7:                               ; @.str.7
	.asciz	"%12."

l_.str.8:                               ; @.str.8
	.asciz	"f %12f %12d %12.2f\n"

l_.str.9:                               ; @.str.9
	.asciz	"%s,%s,%s,%s\n"

l_.str.10:                              ; @.str.10
	.asciz	"%12s %12s %12s %12s\n\n"

	.section	__TEXT,__const
	.p2align	3, 0x0                          ; @switch.table.hdr_calculate_bucket_config
l_switch.table.hdr_calculate_bucket_config:
	.quad	0x4034000000000000              ; double 20
	.quad	0x4069000000000000              ; double 200
	.quad	0x409f400000000000              ; double 2000
	.quad	0x40d3880000000000              ; double 2.0E+4

	.p2align	3, 0x0                          ; @switch.table.hdr_init
l_switch.table.hdr_init:
	.quad	0x4034000000000000              ; double 20
	.quad	0x4069000000000000              ; double 200
	.quad	0x409f400000000000              ; double 2000
	.quad	0x40d3880000000000              ; double 2.0E+4

.subsections_via_symbols
