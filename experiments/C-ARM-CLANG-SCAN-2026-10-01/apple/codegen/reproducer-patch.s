	.build_version macos, 27, 0	sdk_version 27, 0
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_scan                           ; -- Begin function scan
	.p2align	2
_scan:                                  ; @scan
	.cfi_startproc
; %bb.0:
	negs	w8, w1
	and	w8, w8, #0x3
	and	w9, w1, #0x3
	csneg	w8, w9, w8, mi
	sub	w10, w1, w8
	cmp	w10, #1
	b.lt	LBB0_7
; %bb.1:
	mov	x8, #0                          ; =0x0
	mov	x12, #0                         ; =0x0
	mov	x11, x0
LBB0_2:                                 ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_5 Depth 2
	add	x9, x0, x8, lsl #3
	ldp	q1, q0, [x9]
	add.2d	v0, v1, v0
	addp.2d	d0, v0
	fmov	x9, d0
	add	x9, x9, x12
	cmp	x9, x2
	b.hs	LBB0_4
LBB0_3:                                 ;   in Loop: Header=BB0_2 Depth=1
	add	x8, x8, #4
	add	x11, x11, #32
	mov	x12, x9
	cmp	w10, w8
	b.gt	LBB0_2
	b	LBB0_8
LBB0_4:                                 ;   in Loop: Header=BB0_2 Depth=1
	mov	x13, #0                         ; =0x0
	mov	x14, x11
	mov	x9, x12
LBB0_5:                                 ;   Parent Loop BB0_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	x12, [x14], #8
	add	x9, x12, x9
	cmp	x9, x2
	b.ge	LBB0_14
; %bb.6:                                ;   in Loop: Header=BB0_5 Depth=2
	sub	x13, x13, #1
	cmn	x13, #4
	b.ne	LBB0_5
	b	LBB0_3
LBB0_7:
	mov	w8, #0                          ; =0x0
	mov	x9, #0                          ; =0x0
LBB0_8:
	cmp	w8, w1
	b.ge	LBB0_12
; %bb.9:
	mov	w8, w8
LBB0_10:                                ; =>This Inner Loop Header: Depth=1
	ldr	x10, [x0, x8, lsl #3]
	add	x9, x10, x9
	cmp	x9, x2
	b.ge	LBB0_13
; %bb.11:                               ;   in Loop: Header=BB0_10 Depth=1
	add	x8, x8, #1
	cmp	w1, w8
	b.gt	LBB0_10
LBB0_12:
	mov	x0, #-1                         ; =0xffffffffffffffff
	ret
LBB0_13:
	mov	x0, x8
	ret
LBB0_14:
	sub	x0, x8, x13
	ret
	.cfi_endproc
                                        ; -- End function
.subsections_via_symbols
