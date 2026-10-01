	.build_version macos, 27, 0	sdk_version 27, 0
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_scan                           ; -- Begin function scan
	.p2align	2
_scan:                                  ; @scan
	.cfi_startproc
; %bb.0:
	mov	x8, x0
	negs	w9, w1
	and	w9, w9, #0x3
	and	w10, w1, #0x3
	csneg	w9, w10, w9, mi
	sub	w9, w1, w9
	cmp	w9, #1
	b.lt	LBB0_9
; %bb.1:
	mov	x0, #0                          ; =0x0
	mov	x12, #0                         ; =0x0
	add	x10, x8, #16
LBB0_2:                                 ; =>This Inner Loop Header: Depth=1
	ldp	x16, x15, [x10, #-16]
	add	x11, x15, x16
	ldp	x14, x13, [x10]
	add	x17, x13, x14
	add	x11, x17, x11
	add	x11, x11, x12
	cmp	x11, x2
	b.hs	LBB0_4
LBB0_3:                                 ;   in Loop: Header=BB0_2 Depth=1
	add	x10, x10, #32
	add	x0, x0, #4
	mov	x12, x11
	cmp	w9, w0
	b.gt	LBB0_2
	b	LBB0_10
LBB0_4:                                 ;   in Loop: Header=BB0_2 Depth=1
	add	x11, x16, x12
	cmp	x11, x2
	b.ge	LBB0_16
; %bb.5:                                ;   in Loop: Header=BB0_2 Depth=1
	add	x11, x15, x11
	cmp	x11, x2
	b.ge	LBB0_15
; %bb.6:                                ;   in Loop: Header=BB0_2 Depth=1
	add	x11, x14, x11
	cmp	x11, x2
	b.ge	LBB0_17
; %bb.7:                                ;   in Loop: Header=BB0_2 Depth=1
	add	x11, x13, x11
	cmp	x11, x2
	b.lt	LBB0_3
; %bb.8:
	add	x0, x0, #3
	ret
LBB0_9:
	mov	w0, #0                          ; =0x0
	mov	x11, #0                         ; =0x0
LBB0_10:
	cmp	w0, w1
	b.ge	LBB0_14
; %bb.11:
	mov	w0, w0
LBB0_12:                                ; =>This Inner Loop Header: Depth=1
	ldr	x9, [x8, x0, lsl #3]
	add	x11, x9, x11
	cmp	x11, x2
	b.ge	LBB0_16
; %bb.13:                               ;   in Loop: Header=BB0_12 Depth=1
	add	x0, x0, #1
	cmp	w1, w0
	b.gt	LBB0_12
LBB0_14:
	mov	x0, #-1                         ; =0xffffffffffffffff
	ret
LBB0_15:
	add	x0, x0, #1
LBB0_16:
	ret
LBB0_17:
	add	x0, x0, #2
	ret
	.cfi_endproc
                                        ; -- End function
.subsections_via_symbols
