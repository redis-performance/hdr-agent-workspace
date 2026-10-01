	.text
	.file	"reproducer.c"
	.globl	scan                            // -- Begin function scan
	.p2align	2
	.type	scan,@function
scan:                                   // @scan
	.cfi_startproc
// %bb.0:
	negs	w8, w1
	and	w9, w1, #0x3
	and	w8, w8, #0x3
	csneg	w8, w9, w8, mi
	sub	w10, w1, w8
	cmp	w10, #1
	b.lt	.LBB0_7
// %bb.1:
	mov	x9, xzr
	mov	x12, xzr
	mov	x11, x0
.LBB0_2:                                // =>This Loop Header: Depth=1
                                        //     Child Loop BB0_5 Depth 2
	add	x8, x0, x9, lsl #3
	ldp	q1, q0, [x8]
	add	v0.2d, v1.2d, v0.2d
	addp	d0, v0.2d
	fmov	x8, d0
	add	x8, x8, x12
	cmp	x8, x2
	b.hs	.LBB0_4
.LBB0_3:                                //   in Loop: Header=BB0_2 Depth=1
	add	x9, x9, #4
	add	x11, x11, #32
	mov	x12, x8
	cmp	w10, w9
	b.gt	.LBB0_2
	b	.LBB0_8
.LBB0_4:                                //   in Loop: Header=BB0_2 Depth=1
	mov	x13, xzr
	mov	x8, x12
.LBB0_5:                                //   Parent Loop BB0_2 Depth=1
                                        // =>  This Inner Loop Header: Depth=2
	ldr	x12, [x11, x13, lsl #3]
	add	x8, x12, x8
	cmp	x8, x2
	b.ge	.LBB0_14
// %bb.6:                               //   in Loop: Header=BB0_5 Depth=2
	add	x13, x13, #1
	cmp	x13, #4
	b.ne	.LBB0_5
	b	.LBB0_3
.LBB0_7:
	mov	w9, wzr
	mov	x8, xzr
.LBB0_8:
	cmp	w9, w1
	b.ge	.LBB0_12
// %bb.9:
	add	x11, x0, w9, uxtw #3
	mov	x10, xzr
	mov	w9, w9
.LBB0_10:                               // =>This Inner Loop Header: Depth=1
	ldr	x12, [x11, x10, lsl #3]
	add	x8, x12, x8
	cmp	x8, x2
	b.ge	.LBB0_13
// %bb.11:                              //   in Loop: Header=BB0_10 Depth=1
	add	x10, x10, #1
	add	w12, w9, w10
	cmp	w12, w1
	b.lt	.LBB0_10
.LBB0_12:
	mov	x0, #-1                         // =0xffffffffffffffff
	ret
.LBB0_13:
	add	x0, x9, x10
	ret
.LBB0_14:
	add	x0, x9, x13
	ret
.Lfunc_end0:
	.size	scan, .Lfunc_end0-scan
	.cfi_endproc
                                        // -- End function
	.ident	"Ubuntu clang version 18.1.3 (1ubuntu1)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
