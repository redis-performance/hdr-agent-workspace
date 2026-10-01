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
	mov	x8, x0
	cmp	w10, #1
	b.lt	.LBB0_9
// %bb.1:
	mov	x0, xzr
	mov	x12, xzr
	add	x11, x8, #16
.LBB0_2:                                // =>This Inner Loop Header: Depth=1
	ldp	x16, x15, [x11, #-16]
	ldp	x14, x13, [x11]
	add	x9, x15, x16
	add	x17, x13, x14
	add	x9, x17, x9
	add	x9, x9, x12
	cmp	x9, x2
	b.hs	.LBB0_4
.LBB0_3:                                //   in Loop: Header=BB0_2 Depth=1
	add	x0, x0, #4
	add	x11, x11, #32
	mov	x12, x9
	cmp	w10, w0
	b.gt	.LBB0_2
	b	.LBB0_10
.LBB0_4:                                //   in Loop: Header=BB0_2 Depth=1
	add	x9, x16, x12
	cmp	x9, x2
	b.ge	.LBB0_17
// %bb.5:                               //   in Loop: Header=BB0_2 Depth=1
	add	x9, x15, x9
	cmp	x9, x2
	b.ge	.LBB0_16
// %bb.6:                               //   in Loop: Header=BB0_2 Depth=1
	add	x9, x14, x9
	cmp	x9, x2
	b.ge	.LBB0_18
// %bb.7:                               //   in Loop: Header=BB0_2 Depth=1
	add	x9, x13, x9
	cmp	x9, x2
	b.lt	.LBB0_3
// %bb.8:
	add	x0, x0, #3
	ret
.LBB0_9:
	mov	w0, wzr
	mov	x9, xzr
.LBB0_10:
	cmp	w0, w1
	b.ge	.LBB0_14
// %bb.11:
	add	x11, x8, w0, uxtw #3
	mov	x10, xzr
	mov	w8, w0
.LBB0_12:                               // =>This Inner Loop Header: Depth=1
	ldr	x12, [x11, x10, lsl #3]
	add	x9, x12, x9
	cmp	x9, x2
	b.ge	.LBB0_15
// %bb.13:                              //   in Loop: Header=BB0_12 Depth=1
	add	x10, x10, #1
	add	w12, w8, w10
	cmp	w12, w1
	b.lt	.LBB0_12
.LBB0_14:
	mov	x0, #-1                         // =0xffffffffffffffff
	ret
.LBB0_15:
	add	x0, x8, x10
	ret
.LBB0_16:
	add	x0, x0, #1
.LBB0_17:
	ret
.LBB0_18:
	add	x0, x0, #2
	ret
.Lfunc_end0:
	.size	scan, .Lfunc_end0-scan
	.cfi_endproc
                                        // -- End function
	.ident	"Ubuntu clang version 18.1.3 (1ubuntu1)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
