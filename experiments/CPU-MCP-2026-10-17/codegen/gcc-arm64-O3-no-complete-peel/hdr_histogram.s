_percentile_iter_next:
LFB95:
	ldr	x13, [x0, 16]
	mov	x12, x0
	ldr	x1, [x0, 32]
	cmp	x13, x1
	bgt	L117
	ldrb	w0, [x0, 88]
	mov	w1, 0
	tbz	x0, 0, L138
	mov	w0, w1
	ret
	.p2align 2,,3
L117:
	stp	x29, x30, [sp, -48]!
LCFI0:
	mov	x29, sp
LCFI1:
	ldr	w2, [x0, 8]
	ldr	x14, [x0]
	cmn	w2, #1
	beq	L139
	str	x19, [x29, 16]
LCFI2:
	stp	d14, d15, [x29, 32]
LCFI3:
L120:
	ldr	d30, [x14, 88]
	mov	x0, 4636737291354636288
	fmov	d29, x0
	scvtf	d30, d30
L125:
	ldr	x0, [x12, 24]
	add	x19, x12, 88
	cbz	x0, L121
	scvtf	d31, x1
	ldr	d15, [x19, 8]
	fmul	d31, d31, d29
	fdiv	d31, d31, d30
	fcmpe	d15, d31
	bls	L129
L121:
	cmp	x13, x1
	ble	L119
	ldr	w2, [x12, 8]
	mov	x0, x12
	ldr	w1, [x14, 80]
	cmp	w2, w1
	blt	L140
L119:
	ldp	d14, d15, [x29, 32]
LCFI4:
	mov	w1, 1
	ldr	x19, [x29, 16]
LCFI5:
L118:
	mov	w0, w1
	ldp	x29, x30, [sp], 48
LCFI6:
	ret
	.p2align 2,,3
L138:
	mov	w1, 1
	mov	x0, 4636737291354636288
	strb	w1, [x12, 88]
	mov	w1, 1
	str	x0, [x12, 104]
	mov	w0, w1
	ret
	.p2align 2,,3
L140:
LCFI7:
	bl	_move_next
	ldr	x1, [x12, 32]
	b	L125
	.p2align 2,,3
L139:
LCFI8:
	ldr	w2, [x14, 80]
	mov	w1, 0
	tbnz	w2, #31, L118
	str	x19, [x29, 16]
LCFI9:
	stp	d14, d15, [x29, 32]
LCFI10:
	bl	_move_next
	ldr	x1, [x12, 32]
	b	L120
	.p2align 2,,3
L129:
	mov	x1, 4636737291354636288
	ldr	x5, [x14, 32]
	mov	w2, 64
	mov	x0, 1
	mov	x7, 9223372036854775807
	ldr	x4, [x12, 40]
	fmov	d14, x1
	ldr	w3, [x14, 16]
	ldr	w6, [x14, 24]
	orr	x1, x4, x5
	clz	x1, x1
	ldr	w8, [x14, 40]
	sub	w1, w2, w1
	sub	w1, w1, w3
	ldr	x5, [x12, 80]
	add	w2, w6, 1
	sub	w1, w1, w2
	fsub	d0, d14, d15
	add	w2, w3, w1
	asr	x1, x4, x2
	sxtw	x4, w1
	cmp	w8, w1
	lsl	x1, x4, x2
	csinc	w2, w2, w2, gt
	lsl	x0, x0, x2
	sub	x2, x7, x0
	add	x0, x1, x0
	cmp	x1, x2
	sub	x0, x0, #1
	csel	x0, x0, x7, le
	stp	x5, x0, [x12, 72]
	fdiv	d0, d14, d0
	str	d15, [x19, 16]
	bl	_log
	adrp	x0, lC0@PAGE
	fmov	d31, d0
	fmov	d0, 2.0e+0
	ldr	d30, [x0, #lC0@PAGEOFF]
	fdiv	d31, d31, d30
	fcvtzs	x0, d31
	add	x0, x0, 1
	scvtf	d1, x0
	bl	_pow
	fcvtzs	x1, d0
	ldrsw	x0, [x19, 4]
	mul	x0, x0, x1
	scvtf	d31, x0
	fdiv	d14, d14, d31
	fadd	d14, d14, d15
	str	d14, [x19, 8]
	b	L119
LFE95:
	.align	2
	.p2align 5,,15
_hdr_value_at_percentile:
LFB76:
	mov	x10, x0
	ldr	x0, [x0, 88]
	cbz	x0, L563
	mov	x1, 4636737291354636288
	scvtf	d29, x0
	fmov	d27, 5.0e-1
	fmov	d28, 1.0e+0
	fmov	d30, x1
	fcmpe	d0, d30
	fcsel	d31, d0, d30, mi
	fdiv	d31, d31, d30
	fmul	d31, d31, d29
	fadd	d31, d31, d27
	fcmpe	d31, d28
	bge	L594
	mov	x7, 1
	b	L565
	.p2align 2,,3
L594:
	fcmpe	d29, d31
	bls	L595
	fcvtzs	x7, d31
	cmp	x7, 0
	csinc	x7, x7, xzr, gt
L565:
	ldr	w13, [x10, 64]
	ldr	x0, [x10, 96]
	ldr	w11, [x10, 16]
	ldr	w12, [x10, 24]
	ldr	w9, [x10, 80]
	cbnz	w13, L614
	negs	w8, w9
	and	w1, w9, 3
	and	w8, w8, 3
	csneg	w8, w1, w8, mi
	sub	w8, w9, w8
	cmp	w8, 0
	ble	L591
	mov	x4, x0
	mov	w5, 0
	mov	x6, 0
	.p2align 5,,15
L577:
	mov	x1, 0
	mov	x2, 0
L578:
	ldr	x3, [x4, x1, lsl 3]
	add	x1, x1, 1
	add	x2, x2, x3
	cmp	x1, 4
	bne	L578
	add	x2, x6, x2
	cmp	x2, x7
	bcs	L615
	mov	x6, x2
L583:
	add	w5, w5, 4
	add	x4, x4, 32
	cmp	w8, w5
	bgt	L577
L576:
	cmp	w5, w9
	bge	L592
	sxtw	x5, w5
	b	L586
	.p2align 2,,3
L584:
	add	x5, x5, 1
	cmp	w9, w5
	ble	L592
L586:
	ldr	x1, [x0, x5, lsl 3]
	add	x6, x6, x1
	cmp	x6, x7
	blt	L584
	ldr	w2, [x10, 28]
L612:
	asr	w1, w5, w12
	sub	w0, w2, #1
	sub	w3, w1, #1
	and	w0, w0, w5
	cbz	w1, L585
	add	w0, w0, w2
	mov	w13, w3
L585:
	sxtw	x0, w0
	add	w13, w13, w11
	lsl	x0, x0, x13
L570:
	ldr	x2, [x10, 32]
	mov	w1, 64
	add	w12, w12, 1
	fcmp	d0, #0.0
	orr	x2, x0, x2
	clz	x2, x2
	sub	w1, w1, w2
	sub	w1, w1, w11
	sub	w1, w1, w12
	add	w4, w1, w11
	asr	x2, x0, x4
	sxtw	x7, w2
	lsl	x0, x7, x4
	beq	L563
	ldr	w6, [x10, 40]
	mov	x3, 1
	mov	x5, 9223372036854775807
	cmp	w6, w2
	csinc	w4, w4, w4, gt
	lsl	x1, x3, x4
	sub	x2, x5, x1
	add	x1, x1, x0
	cmp	x2, x0
	sub	x1, x1, #1
	csel	x0, x1, x5, ge
L563:
	ret
L595:
	cmp	x0, 0
	csinc	x7, x0, xzr, gt
	b	L565
	.p2align 2,,3
L615:
	mov	x1, 0
	ldr	x2, [x4, x1, lsl 3]
	add	x6, x6, x2
	cmp	x6, x7
	bge	L616
L580:
	add	x1, x1, 1
	cmp	x1, 4
	beq	L583
	ldr	x2, [x4, x1, lsl 3]
	add	x6, x6, x2
	cmp	x6, x7
	blt	L580
L616:
	ldr	w2, [x10, 28]
	add	w5, w5, w1
	b	L612
L592:
	mov	x0, 0
	b	L570
L614:
	cmp	w9, 0
	ble	L592
	neg	w1, w13
	mov	x3, 0
	mov	w2, 0
	add	w13, w9, w13
	b	L575
	.p2align 2,,3
L573:
	add	w2, w2, 1
	cmp	w9, w2
	beq	L592
L575:
	add	w4, w9, w1
	tbnz	w1, #31, L572
	cmp	w9, w1
	sub	w4, w2, w13
	csel	w4, w4, w1, le
L572:
	ldr	x4, [x0, w4, sxtw 3]
	add	w1, w1, 1
	add	x3, x3, x4
	cmp	x3, x7
	blt	L573
	ldr	w3, [x10, 28]
	asr	w4, w2, w12
	sub	w1, w4, #1
	sub	w0, w3, #1
	and	w0, w0, w2
	cbz	w4, L590
	add	w0, w0, w3
L574:
	sxtw	x0, w0
	add	w1, w1, w11
	lsl	x0, x0, x1
	b	L570
L591:
	mov	w5, 0
	mov	x6, 0
	b	L576
L590:
	mov	w1, 0
	b	L574
LFE76:
	.align	2
	.p2align 5,,15
	.globl _hdr_value_at_percentiles
_hdr_value_at_percentiles:
LFB78:
	cmp	x1, 0
	ccmp	x2, 0, 4, ne
	beq	L673
	stp	x29, x30, [sp, -224]!
LCFI79:
	mov	x29, sp
LCFI80:
	stp	x19, x20, [sp, 16]
LCFI81:
	mov	x20, x0
	stp	x21, x22, [sp, 32]
LCFI82:
	mov	x21, x2
	mov	x22, x3
	ldr	x2, [x0, 88]
	cbz	x2, L619
	stp	x23, x24, [x29, 48]
LCFI83:
	mov	x23, x1
	ldr	w3, [x0, 64]
	cbz	x22, L710
	sub	x0, x22, #1
	scvtf	d22, x2
	cmp	x0, 1
	bls	L674
	dup	v23.2d, x2
	adrp	x4, lC3@PAGE
	adrp	x0, lC2@PAGE
	lsr	x1, x22, 1
	ldr	q27, [x4, #lC3@PAGEOFF]
	dup	v26.2d, v22.d[0]
	fmov	v24.2d, 5.0e-1
	fmov	v25.2d, 1.0e+0
	lsl	x1, x1, 4
	ldr	q30, [x0, #lC2@PAGEOFF]
	mov	x0, 0
	.p2align 5,,15
L625:
	ldr	q29, [x23, x0]
	fcmgt	v31.2d, v30.2d, v29.2d
	bsl	v31.16b, v29.16b, v30.16b
	fdiv	v31.2d, v31.2d, v30.2d
	fmul	v31.2d, v31.2d, v26.2d
	fadd	v31.2d, v31.2d, v24.2d
	fcvtzs	v28.2d, v31.2d
	fcmge	v29.2d, v31.2d, v26.2d
	fcmge	v31.2d, v31.2d, v25.2d
	bsl	v29.16b, v23.16b, v28.16b
	bsl	v31.16b, v29.16b, v27.16b
	str	q31, [x21, x0]
	add	x0, x0, 16
	cmp	x0, x1
	bne	L625
	and	x0, x22, -2
	tbz	x22, 0, L626
L624:
	mov	x1, 4636737291354636288
	fmov	d28, 5.0e-1
	fmov	d29, 1.0e+0
	fmov	d30, x1
L628:
	ldr	d31, [x23, x0, lsl 3]
	mov	x1, x2
	fcmpe	d31, d30
	fcsel	d31, d31, d30, mi
	fdiv	d31, d31, d30
	fmul	d31, d31, d22
	fadd	d31, d31, d28
	fcmpe	d31, d29
	bge	L627
	mov	x1, 1
L629:
	str	x1, [x21, x0, lsl 3]
	add	x0, x0, 1
	cmp	x22, x0
	bhi	L628
L626:
	cbnz	w3, L630
	ldr	w12, [x20, 80]
	ldr	x13, [x20, 96]
	cmp	w12, 7
	ble	L631
	mov	w8, 0
	mov	x19, 0
	mov	x9, x13
	mov	x7, 0
	mov	w11, 7
	mov	w2, 64
	mov	x3, 1
	mov	x1, 9223372036854775807
	b	L646
	.p2align 2,,3
L676:
	mov	x7, x0
L632:
	cmp	x19, x22
	add	w11, w11, 8
	cset	w0, cc
	cmp	w0, 0
	add	w8, w8, 8
	ccmp	w11, w12, 0, ne
	add	x9, x9, 64
	bge	L711
L646:
	ldp	q28, q31, [x9]
	ldp	q29, q30, [x9, 32]
	ldr	x4, [x21, x19, lsl 3]
	add	v31.2d, v31.2d, v28.2d
	add	v30.2d, v30.2d, v29.2d
	add	v31.2d, v31.2d, v30.2d
	addp	d31, v31.2d
	fmov	x0, d31
	add	x0, x7, x0
	cmp	x0, x4
	blt	L676
	cmp	w8, w11
	bgt	L632
	mov	x10, x9
	mov	w6, w8
	ldr	x0, [x10]
	add	x7, x7, x0
	cmp	x22, x19
	bhi	L634
	b	L712
	.p2align 2,,3
L714:
	orr	x0, x5, x0
	clz	x0, x0
	sub	w0, w2, w0
	sub	w0, w0, w14
	asr	x4, x5, x0
	sxtw	x4, w4
	lsl	x4, x4, x0
	str	x4, [x21, x19, lsl 3]
	add	x19, x19, 1
	cmp	x22, x19
	beq	L639
L634:
	ldr	x0, [x21, x19, lsl 3]
	cmp	x0, x7
	bgt	L713
	ldp	w14, w15, [x20, 24]
	ldr	d30, [x23, x19, lsl 3]
	asr	w5, w6, w14
	sub	w4, w15, #1
	sub	w0, w5, #1
	and	w4, w4, w6
	cbz	w5, L677
	add	w4, w4, w15
L635:
	ldr	w15, [x20, 16]
	sxtw	x4, w4
	fcmp	d30, #0.0
	add	w14, w14, 1
	add	w0, w15, w0
	lsl	x5, x4, x0
	ldr	x0, [x20, 32]
	beq	L714
	orr	x0, x5, x0
	clz	x0, x0
	ldr	w16, [x20, 40]
	sub	w0, w2, w0
	sub	w0, w0, w15
	sub	w0, w0, w14
	add	w4, w15, w0
	asr	x5, x5, x4
	sxtw	x0, w5
	cmp	w16, w5
	lsl	x0, x0, x4
	csinc	w4, w4, w4, gt
	lsl	x4, x3, x4
	sub	x5, x1, x4
	add	x4, x0, x4
	cmp	x0, x5
	sub	x4, x4, #1
	csel	x4, x4, x1, le
	str	x4, [x21, x19, lsl 3]
	add	x19, x19, 1
	cmp	x22, x19
	bne	L634
L639:
	add	w6, w6, 1
	cmp	w6, w11
	bgt	L632
	add	x10, x10, 8
L715:
	ldr	x0, [x10]
	add	x7, x7, x0
	cmp	x22, x19
	bhi	L634
L712:
	add	w6, w6, 1
	sxtw	x0, w6
	cmp	w11, w6
	blt	L632
L644:
	ldr	x4, [x13, x0, lsl 3]
	add	x0, x0, 1
	add	x7, x7, x4
	cmp	w11, w0
	bge	L644
	b	L632
	.p2align 2,,3
L677:
	mov	w0, 0
	b	L635
	.p2align 2,,3
L713:
	add	w6, w6, 1
	cmp	w11, w6
	blt	L632
	add	x10, x10, 8
	b	L715
L711:
	cmp	w0, 0
	ccmp	w12, w8, 4, ne
	ble	L647
L668:
	sxtw	x8, w8
	mov	w5, 64
	mov	x6, 1
	mov	x4, 9223372036854775807
	.p2align 5,,15
L655:
	ldr	x0, [x13, x8, lsl 3]
	mov	w9, w8
	mov	w3, w8
	add	x7, x7, x0
	cmp	x22, x19
	bhi	L649
	b	L708
	.p2align 2,,3
L717:
	orr	x2, x1, x2
	clz	x2, x2
	sub	w2, w5, w2
	sub	w2, w2, w11
	asr	x0, x1, x2
	sxtw	x0, w0
	lsl	x0, x0, x2
	str	x0, [x21, x19, lsl 3]
	add	x19, x19, 1
	cmp	x22, x19
	beq	L708
L649:
	ldr	x0, [x21, x19, lsl 3]
	cmp	x0, x7
	bgt	L716
	ldp	w2, w11, [x20, 24]
	ldr	d28, [x23, x19, lsl 3]
	asr	w10, w3, w2
	sub	w0, w11, #1
	sub	w1, w10, #1
	and	w0, w0, w3
	cbz	w10, L679
	add	w0, w0, w11
L650:
	ldr	w10, [x20, 16]
	sxtw	x0, w0
	fcmp	d28, #0.0
	add	w11, w2, 1
	ldr	x2, [x20, 32]
	add	w1, w10, w1
	lsl	x1, x0, x1
	beq	L717
	orr	x2, x1, x2
	ldr	w14, [x20, 40]
	clz	x2, x2
	sub	w2, w5, w2
	sub	w2, w2, w10
	sub	w2, w2, w11
	add	w0, w10, w2
	asr	x1, x1, x0
	sxtw	x2, w1
	cmp	w14, w1
	lsl	x1, x2, x0
	csinc	w0, w0, w0, gt
	lsl	x0, x6, x0
	sub	x2, x4, x0
	add	x0, x1, x0
	cmp	x1, x2
	sub	x0, x0, #1
	csel	x0, x0, x4, le
	str	x0, [x21, x19, lsl 3]
	add	x19, x19, 1
	cmp	x22, x19
	bne	L649
L708:
	ldp	x23, x24, [x29, 48]
LCFI84:
L623:
	mov	w0, 0
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x29, x30, [sp], 224
LCFI85:
	ret
	.p2align 2,,3
L679:
LCFI86:
	mov	w1, 0
	b	L650
	.p2align 2,,3
L716:
	add	w9, w9, 1
	add	x8, x8, 1
	cmp	w12, w9
	ccmp	x22, x19, 0, gt
	bhi	L655
L647:
	cmp	x19, x22
	bcs	L708
L669:
	mov	w5, 64
	mov	x4, 1
	.p2align 5,,15
L666:
	ldr	d29, [x23, x19, lsl 3]
	mov	x0, 0
	fcmp	d29, #0.0
	beq	L664
	ldr	x1, [x20, 32]
	ldr	w0, [x20, 16]
	ldr	w2, [x20, 24]
	clz	x1, x1
	ldr	w3, [x20, 40]
	sub	w1, w5, w1
	sub	w1, w1, w0
	add	w2, w2, 1
	sub	w1, w1, w2
	cmp	w3, 0
	cinc	w1, w1, le
	add	w0, w0, w1
	lsl	x0, x4, x0
	sub	x0, x0, #1
L664:
	str	x0, [x21, x19, lsl 3]
	add	x19, x19, 1
	cmp	x22, x19
	bne	L666
	b	L708
L627:
	fcmpe	d22, d31
	bls	L629
	fcvtzs	x1, d31
	b	L629
L673:
LCFI87:
	mov	w0, 22
	ret
L619:
LCFI88:
	cbz	x3, L623
	lsl	x2, x3, 3
	mov	x0, x21
	mov	w1, 0
	bl	_memset
	b	L623
L710:
LCFI89:
	cbz	w3, L708
	stp	x25, x26, [x29, 64]
LCFI90:
	stp	x27, x28, [x29, 80]
LCFI91:
	b	L667
L674:
LCFI92:
	mov	x0, 0
	b	L624
L630:
	stp	x25, x26, [x29, 64]
LCFI93:
	stp	x27, x28, [x29, 80]
LCFI94:
	ldr	x2, [x20, 88]
L667:
	adrp	x0, _all_values_iter_next@PAGE
	mov	w3, -1
	str	x20, [x29, 96]
	add	x0, x0, _all_values_iter_next@PAGEOFF;
	mov	x19, 0
	stp	x2, xzr, [x29, 112]
	mov	x25, 0
	add	x24, x29, 96
	mov	x1, x0
	mov	w27, 64
	mov	x28, 1
	mov	x26, 9223372036854775807
	str	w3, [x29, 104]
	stp	xzr, xzr, [x29, 128]
	str	xzr, [x29, 144]
	stp	xzr, xzr, [x29, 168]
	str	x0, [x29, 216]
L656:
	mov	x0, x24
	blr	x1
	cmp	w0, 0
	ccmp	x19, x22, 2, ne
	bcs	L718
	ldr	x0, [x29, 120]
	ldr	x2, [x29, 136]
	add	x25, x25, x0
	b	L657
	.p2align 2,,3
L719:
	ldr	w0, [x20, 24]
	orr	x1, x2, x1
	clz	x1, x1
	sub	w1, w27, w1
	add	w0, w0, 1
	sub	w1, w1, w0
	asr	x0, x2, x1
	sxtw	x0, w0
	lsl	x0, x0, x1
	str	x0, [x21, x19, lsl 3]
	add	x19, x19, 1
	cmp	x22, x19
	bls	L661
L657:
	ldr	x0, [x21, x19, lsl 3]
	cmp	x0, x25
	bgt	L661
	ldr	d31, [x23, x19, lsl 3]
	ldr	x1, [x20, 32]
	fcmp	d31, #0.0
	beq	L719
	ldr	w3, [x20, 16]
	orr	x1, x2, x1
	clz	x1, x1
	ldr	w0, [x20, 24]
	sub	w1, w27, w1
	ldr	w5, [x20, 40]
	sub	w1, w1, w3
	add	w0, w0, 1
	sub	w1, w1, w0
	add	w0, w3, w1
	asr	x4, x2, x0
	sxtw	x1, w4
	cmp	w5, w4
	lsl	x1, x1, x0
	csinc	w0, w0, w0, gt
	lsl	x0, x28, x0
	sub	x3, x26, x0
	add	x0, x1, x0
	cmp	x1, x3
	sub	x0, x0, #1
	csel	x0, x0, x26, le
	str	x0, [x21, x19, lsl 3]
	add	x19, x19, 1
	cmp	x22, x19
	bhi	L657
L661:
	ldr	x1, [x29, 216]
	b	L656
L718:
	ldp	x25, x26, [x29, 64]
LCFI95:
	ldp	x27, x28, [x29, 80]
LCFI96:
	b	L647
L631:
	mov	x19, 0
	cmp	w12, 0
	ble	L669
	mov	w8, 0
	mov	x7, 0
	mov	x19, 0
	b	L668
LFE78:
	.align	2
	.p2align 5,,15
	.globl _hdr_mean
_hdr_iter_percentile_init:
LFB96:
	ldr	x4, [x1, 88]
	adrp	x3, _percentile_iter_next@PAGE
	mov	w5, -1
	add	x3, x3, _percentile_iter_next@PAGEOFF;
	str	x1, [x0]
	str	w5, [x0, 8]
	stp	xzr, xzr, [x0, 32]
	stp	x4, xzr, [x0, 16]
	str	xzr, [x0, 48]
	stp	xzr, xzr, [x0, 72]
	strb	wzr, [x0, 88]
	str	w2, [x0, 92]
	stp	xzr, xzr, [x0, 96]
	str	x3, [x0, 120]
	ret
LFE96:
	.align	2
	.p2align 5,,15
	.globl _hdr_iter_recorded_init
_hdr_percentiles_print:
LFB106:
	sub	sp, sp, #288
LCFI113:
	stp	x29, x30, [sp, 48]
LCFI114:
	add	x29, sp, 48
LCFI115:
	stp	x19, x20, [sp, 64]
LCFI116:
	mov	x19, x1
	stp	x21, x22, [sp, 80]
LCFI117:
	mov	x22, x0
	mov	w21, w2
	stp	d13, d14, [sp, 112]
LCFI118:
	fmov	d14, d0
	ldr	w0, [x0, 20]
	str	x23, [sp, 96]
LCFI119:
	mov	w23, w3
	cmp	w3, 1
	beq	L818
	adrp	x3, lC10@PAGE
	adrp	x1, lC11@PAGE
	str	w0, [sp, 8]
	add	x3, x3, lC10@PAGEOFF;
	add	x1, x1, lC11@PAGEOFF;
	adrp	x2, lC7@PAGE
	add	x20, x29, 80
	add	x2, x2, lC7@PAGEOFF;
	mov	x0, x20
	str	x1, [sp]
	mov	x1, 25
	str	x3, [sp, 16]
	bl	_snprintf
	adrp	x1, lC6@PAGE
	add	x1, x1, lC6@PAGEOFF;
L799:
	ldr	x6, [x22, 88]
	adrp	x5, lC12@PAGE
	adrp	x4, lC13@PAGE
	adrp	x2, lC14@PAGE
	adrp	x0, lC15@PAGE
	str	x22, [x29, 112]
	add	x5, x5, lC12@PAGEOFF;
	add	x4, x4, lC13@PAGEOFF;
	stp	xzr, xzr, [x29, 144]
	add	x2, x2, lC14@PAGEOFF;
	add	x0, x0, lC15@PAGEOFF;
	adrp	x3, _percentile_iter_next@PAGE
	mov	w7, -1
	add	x3, x3, _percentile_iter_next@PAGEOFF;
	stp	x0, x2, [sp]
	mov	x0, x19
	stp	x4, x5, [sp, 16]
	str	w7, [x29, 120]
	stp	x6, xzr, [x29, 128]
	str	xzr, [x29, 160]
	stp	xzr, xzr, [x29, 184]
	strb	wzr, [x29, 200]
	str	w21, [x29, 204]
	add	x21, x29, 112
	stp	xzr, xzr, [x29, 208]
	str	x3, [x29, 232]
	bl	_fprintf
	tbnz	w0, #31, L802
	mov	x0, 4636737291354636288
	str	d15, [x29, 56]
LCFI120:
	fmov	d15, 1.0e+0
	fmov	d13, x0
	b	L800
	.p2align 2,,3
L803:
	ldr	d30, [x29, 216]
	ldr	d31, [x29, 160]
	ldr	x2, [x29, 144]
	fdiv	d30, d30, d13
	scvtf	d31, d31
	str	x2, [sp, 16]
	fdiv	d31, d31, d14
	fsub	d29, d15, d30
	stp	d31, d30, [sp]
	fdiv	d31, d15, d29
	str	d31, [sp, 24]
	bl	_fprintf
	tbnz	w0, #31, L817
L800:
	ldr	x2, [x29, 232]
	mov	x0, x21
	blr	x2
	mov	x1, x20
	mov	w2, w0
	mov	x0, x19
	tbnz	x2, 0, L803
	cbz	w23, L819
L804:
L801:
	ldr	d15, [x29, 56]
LCFI121:
	mov	w0, 0
	ldp	x29, x30, [sp, 48]
	ldp	x19, x20, [sp, 64]
	ldp	x21, x22, [sp, 80]
	ldr	x23, [sp, 96]
	ldp	d13, d14, [sp, 112]
	add	sp, sp, 288
LCFI122:
	ret
	.p2align 2,,3
L819:
LCFI123:
	mov	x0, x22
	bl	_hdr_mean
	ldr	x4, [x22, 88]
	fdiv	d15, d0, d14
	movi	d31, #0
	cbz	x4, L805
	mov	x0, x22
	bl	_hdr_stddev.part.0
	ldr	x4, [x22, 88]
	fmov	d31, d0
L805:
	fdiv	d30, d31, d14
	movi	d31, #0
	ldr	x1, [x22, 56]
	ldr	w6, [x22, 40]
	cbz	x1, L806
	mov	w0, 64
	mov	x5, 1
	ldr	x2, [x22, 32]
	mov	x7, 9223372036854775807
	ldr	w3, [x22, 16]
	ldr	w8, [x22, 24]
	orr	x2, x1, x2
	clz	x2, x2
	sub	w0, w0, w2
	sub	w0, w0, w3
	add	w2, w8, 1
	sub	w0, w0, w2
	add	w2, w3, w0
	asr	x1, x1, x2
	sxtw	x0, w1
	cmp	w6, w1
	lsl	x0, x0, x2
	csinc	w2, w2, w2, gt
	lsl	x1, x5, x2
	sub	x2, x7, x1
	cmp	x0, x2
	bgt	L810
	add	x0, x0, x1
	sub	x0, x0, #1
	scvtf	d31, x0
L806:
	fdiv	d31, d31, d14
	ldr	w2, [x22, 44]
	adrp	x1, _CLASSIC_FOOTER@PAGE
	mov	x0, x19
	add	x1, x1, _CLASSIC_FOOTER@PAGEOFF;
	stp	d15, d30, [sp]
	str	x4, [sp, 24]
	str	w6, [sp, 40]
	str	w2, [sp, 32]
	str	d31, [sp, 16]
	bl	_fprintf
	tbz	w0, #31, L804
	.p2align 5,,15
L817:
	ldr	d15, [x29, 56]
LCFI124:
L802:
	ldp	x29, x30, [sp, 48]
	mov	w0, 5
	ldp	x19, x20, [sp, 64]
	ldp	x21, x22, [sp, 80]
	ldr	x23, [sp, 96]
	ldp	d13, d14, [sp, 112]
	add	sp, sp, 288
LCFI125:
	ret
	.p2align 2,,3
L818:
LCFI126:
	adrp	x3, lC8@PAGE
	adrp	x1, lC9@PAGE
	str	w0, [sp, 8]
	add	x3, x3, lC8@PAGEOFF;
	add	x1, x1, lC9@PAGEOFF;
	adrp	x2, lC7@PAGE
	add	x20, x29, 80
	add	x2, x2, lC7@PAGEOFF;
	mov	x0, x20
	str	x1, [sp]
	mov	x1, 25
	str	x3, [sp, 16]
	bl	_snprintf
	adrp	x1, lC5@PAGE
	add	x1, x1, lC5@PAGEOFF;
	b	L799
L810:
LCFI127:
	mov	x0, 4890909195324358656
	fmov	d31, x0
	b	L806
LFE106:
	.const
	.align	3
