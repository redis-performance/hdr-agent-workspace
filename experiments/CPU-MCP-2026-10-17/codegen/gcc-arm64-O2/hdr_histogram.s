_percentile_iter_next:
LFB95:
	ldr	x13, [x0, 16]
	mov	x12, x0
	ldr	x1, [x0, 32]
	cmp	x13, x1
	bgt	L80
	ldrb	w0, [x0, 88]
	mov	w1, 0
	tbz	x0, 0, L98
	mov	w0, w1
	ret
	.p2align 2,,3
L80:
	stp	x29, x30, [sp, -48]!
LCFI8:
	mov	x29, sp
LCFI9:
	ldr	w2, [x0, 8]
	ldr	x14, [x0]
	cmn	w2, #1
	beq	L99
	str	x19, [x29, 16]
LCFI10:
	stp	d14, d15, [x29, 32]
LCFI11:
L83:
	ldr	d30, [x14, 88]
	mov	x0, 4636737291354636288
	fmov	d14, x0
	scvtf	d30, d30
L86:
	ldr	x0, [x12, 24]
	add	x19, x12, 88
	cbz	x0, L84
	scvtf	d31, x1
	ldr	d15, [x19, 8]
	fmul	d31, d31, d14
	fdiv	d31, d31, d30
	fcmpe	d15, d31
	bls	L89
L84:
	cmp	x13, x1
	ble	L82
	ldr	w2, [x12, 8]
	mov	x0, x12
	ldr	w1, [x14, 80]
	cmp	w2, w1
	blt	L100
L82:
	ldp	d14, d15, [x29, 32]
LCFI12:
	mov	w1, 1
	ldr	x19, [x29, 16]
LCFI13:
L81:
	mov	w0, w1
	ldp	x29, x30, [sp], 48
LCFI14:
	ret
	.p2align 2,,3
L98:
	mov	w1, 1
	mov	x0, 4636737291354636288
	strb	w1, [x12, 88]
	mov	w1, 1
	str	x0, [x12, 104]
	mov	w0, w1
	ret
	.p2align 2,,3
L100:
LCFI15:
	bl	_move_next
	ldr	x1, [x12, 32]
	b	L86
	.p2align 2,,3
L99:
LCFI16:
	ldr	w2, [x14, 80]
	mov	w1, 0
	tbnz	w2, #31, L81
	str	x19, [x29, 16]
LCFI17:
	stp	d14, d15, [x29, 32]
LCFI18:
	bl	_move_next
	ldr	x1, [x12, 32]
	b	L83
	.p2align 2,,3
L89:
	ldr	x1, [x12, 40]
	mov	x0, x14
	fsub	d0, d14, d15
	bl	_highest_equivalent_value
	ldr	x1, [x12, 80]
	fdiv	d0, d14, d0
	stp	x1, x0, [x12, 72]
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
	b	L82
LFE95:
	.align	2
	.p2align 5,,15
_hdr_value_at_percentile:
LFB76:
	ldr	x1, [x0, 88]
	cbz	x1, L323
	mov	x2, 4636737291354636288
	scvtf	d29, x1
	fmov	d27, 5.0e-1
	fmov	d28, 1.0e+0
	fmov	d30, x2
	fcmpe	d0, d30
	fcsel	d31, d0, d30, mi
	fdiv	d31, d31, d30
	fmul	d31, d31, d29
	fadd	d31, d31, d27
	fcmpe	d31, d28
	bge	L353
	mov	x7, 1
	b	L325
	.p2align 2,,3
L353:
	fcmpe	d29, d31
	bls	L354
	fcvtzs	x7, d31
	cmp	x7, 0
	csinc	x7, x7, xzr, gt
L325:
	ldr	w11, [x0, 64]
	ldr	x10, [x0, 96]
	ldr	w9, [x0, 80]
	cbnz	w11, L371
	negs	w8, w9
	and	w1, w9, 3
	and	w8, w8, 3
	csneg	w8, w1, w8, mi
	sub	w8, w9, w8
	cmp	w8, 0
	ble	L351
	mov	x4, x10
	mov	w5, 0
	mov	x6, 0
	.p2align 5,,15
L337:
	mov	x1, 0
	mov	x2, 0
L338:
	ldr	x3, [x4, x1, lsl 3]
	add	x1, x1, 1
	add	x2, x2, x3
	cmp	x1, 4
	bne	L338
	add	x2, x6, x2
	cmp	x2, x7
	bcs	L372
	mov	x6, x2
L343:
	add	w5, w5, 4
	add	x4, x4, 32
	cmp	w8, w5
	bgt	L337
L336:
	cmp	w9, w5
	ble	L352
	sxtw	x5, w5
	b	L346
	.p2align 2,,3
L344:
	add	x5, x5, 1
	cmp	w9, w5
	ble	L352
L346:
	ldr	x1, [x10, x5, lsl 3]
	add	x6, x6, x1
	cmp	x6, x7
	blt	L344
	ldp	w2, w3, [x0, 24]
	asr	w2, w5, w2
	sub	w1, w3, #1
	sub	w4, w2, #1
	and	w1, w1, w5
	cbz	w2, L345
	add	w1, w1, w3
	mov	w11, w4
L345:
	ldr	w2, [x0, 16]
	sxtw	x1, w1
	add	w11, w11, w2
	lsl	x1, x1, x11
L330:
	fcmp	d0, #0.0
	beq	L373
L347:
	b	_highest_equivalent_value
L354:
	cmp	x1, 0
	csinc	x7, x1, xzr, gt
	b	L325
	.p2align 2,,3
L372:
	mov	x1, 0
	ldr	x2, [x4, x1, lsl 3]
	add	x6, x6, x2
	cmp	x6, x7
	bge	L374
L340:
	add	x1, x1, 1
	cmp	x1, 4
	beq	L343
	ldr	x2, [x4, x1, lsl 3]
	add	x6, x6, x2
	cmp	x6, x7
	blt	L340
L374:
	ldp	w2, w3, [x0, 24]
	add	w5, w5, w1
	asr	w2, w5, w2
	sub	w1, w3, #1
	sub	w4, w2, #1
	and	w1, w1, w5
	cbz	w2, L341
	add	w1, w1, w3
	mov	w11, w4
L341:
	ldr	w2, [x0, 16]
	sxtw	x1, w1
	fcmp	d0, #0.0
	add	w2, w11, w2
	lsl	x1, x1, x2
	bne	L347
L373:
	ldr	x3, [x0, 32]
	mov	w2, 64
	ldr	w4, [x0, 24]
	orr	x0, x1, x3
	clz	x0, x0
	add	w3, w4, 1
	sub	w0, w2, w0
	sub	w0, w0, w3
	asr	x1, x1, x0
	sxtw	x1, w1
	lsl	x1, x1, x0
L323:
	mov	x0, x1
	ret
L352:
	mov	x1, 0
	b	L330
L371:
	cmp	w9, 0
	ble	L352
	neg	w1, w11
	mov	x3, 0
	mov	w2, 0
	add	w11, w9, w11
	b	L335
	.p2align 2,,3
L333:
	add	w2, w2, 1
	cmp	w9, w2
	beq	L352
L335:
	add	w4, w9, w1
	tbnz	w1, #31, L332
	cmp	w9, w1
	sub	w4, w2, w11
	csel	w4, w4, w1, le
L332:
	ldr	x4, [x10, w4, sxtw 3]
	add	w1, w1, 1
	add	x3, x3, x4
	cmp	x3, x7
	blt	L333
	ldp	w4, w5, [x0, 24]
	asr	w4, w2, w4
	sub	w1, w5, #1
	sub	w3, w4, #1
	and	w1, w1, w2
	cbz	w4, L350
	add	w1, w1, w5
L334:
	ldr	w2, [x0, 16]
	sxtw	x1, w1
	add	w3, w3, w2
	lsl	x1, x1, x3
	b	L330
L351:
	mov	w5, 0
	mov	x6, 0
	b	L336
L350:
	mov	w3, 0
	b	L334
LFE76:
	.align	2
	.p2align 5,,15
	.globl _hdr_value_at_percentiles
_hdr_value_at_percentiles:
LFB78:
	cmp	x1, 0
	ccmp	x2, 0, 4, ne
	beq	L419
	stp	x29, x30, [sp, -208]!
LCFI84:
	mov	x29, sp
LCFI85:
	stp	x19, x20, [sp, 16]
LCFI86:
	mov	x20, x0
	stp	x21, x22, [sp, 32]
LCFI87:
	mov	x22, x1
	mov	x21, x2
	stp	x23, x24, [sp, 48]
LCFI88:
	mov	x23, x3
	ldr	x1, [x0, 88]
	cbz	x1, L377
	ldr	w3, [x0, 64]
	cbz	x23, L448
	mov	x0, 4636737291354636288
	scvtf	d29, x1
	fmov	d27, 5.0e-1
	fmov	d28, 1.0e+0
	mov	x7, 0
	fmov	d30, x0
	.p2align 5,,15
L384:
	ldr	d31, [x22, x7, lsl 3]
	mov	x0, x1
	fcmpe	d31, d30
	fcsel	d31, d31, d30, mi
	fdiv	d31, d31, d30
	fmul	d31, d31, d29
	fadd	d31, d31, d27
	fcmpe	d31, d28
	bge	L431
	mov	x0, 1
	add	x2, x7, 1
	str	x0, [x21, x7, lsl 3]
	cmp	x23, x2
	bne	L422
L452:
	cbnz	w3, L385
	ldr	w14, [x20, 80]
	ldr	x12, [x20, 96]
	cmp	w14, 7
	ble	L386
	mov	x13, 0
	mov	x19, 0
	mov	x10, x12
	mov	x6, 0
	mov	w3, 7
	mov	w1, 64
	mov	x11, 1
	mov	x8, 9223372036854775807
	b	L395
	.p2align 2,,3
L423:
	mov	x6, x0
L387:
	cmp	x19, x2
	mov	w0, w3
	cset	w4, cc
	add	w3, w3, 8
	cmp	w4, 0
	ccmp	w3, w14, 0, ne
	add	x13, x13, 8
	add	x10, x10, 64
	bge	L449
L395:
	ldp	x0, x5, [x10]
	ldp	x4, x15, [x10, 16]
	add	x0, x0, x5
	ldp	x5, x9, [x10, 32]
	add	x4, x4, x15
	add	x0, x0, x9
	ldp	x15, x9, [x10, 48]
	add	x4, x4, x5
	ldr	x5, [x21, x19, lsl 3]
	add	x0, x0, x15
	add	x4, x4, x9
	add	x0, x0, x6
	add	x0, x0, x4
	cmp	x0, x5
	blt	L423
	cmp	w3, w13
	blt	L387
	mov	x9, x13
	.p2align 5,,15
L394:
	ldr	x4, [x12, x9, lsl 3]
	mov	w0, w9
	add	x6, x6, x4
	cmp	x19, x2
	bcc	L389
	b	L388
	.p2align 2,,3
L451:
	add	w4, w4, w16
L390:
	ldr	w17, [x20, 16]
	sxtw	x16, w4
	add	w5, w5, 1
	fcmp	d30, #0.0
	add	x15, x19, 1
	ldr	x4, [x20, 32]
	add	w30, w17, w30
	lsl	x16, x16, x30
	orr	x4, x16, x4
	clz	x4, x4
	sub	w4, w1, w4
	sub	w4, w4, w17
	sub	w4, w4, w5
	add	w5, w17, w4
	asr	x16, x16, x5
	sxtw	x4, w16
	lsl	x4, x4, x5
	beq	L391
	ldr	w30, [x20, 40]
	cmp	w30, w16
	csinc	w5, w5, w5, gt
	lsl	x5, x11, x5
	sub	x16, x8, x5
	add	x5, x5, x4
	cmp	x16, x4
	sub	x5, x5, #1
	csel	x4, x5, x8, ge
L391:
	str	x4, [x21, x19, lsl 3]
	cmp	x19, x7
	beq	L426
	mov	x19, x15
L389:
	ldr	x4, [x21, x19, lsl 3]
	cmp	x4, x6
	bgt	L450
	ldp	w5, w16, [x20, 24]
	ldr	d30, [x22, x19, lsl 3]
	asr	w15, w0, w5
	sub	w4, w16, #1
	sub	w30, w15, #1
	and	w4, w4, w0
	cbnz	w15, L451
	mov	w30, 0
	b	L390
	.p2align 2,,3
L431:
	fcmpe	d31, d29
	bge	L382
	fcvtzs	x0, d31
L382:
	add	x2, x7, 1
	str	x0, [x21, x7, lsl 3]
	cmp	x23, x2
	beq	L452
L422:
	mov	x7, x2
	b	L384
	.p2align 2,,3
L426:
	mov	x19, x2
L388:
	add	x9, x9, 1
	cmp	w3, w9
	bge	L394
	add	w0, w3, 1
	cmp	x2, x19
	cset	w4, hi
L416:
	cmp	w4, 0
	ccmp	w14, w0, 4, ne
	ble	L396
L414:
	sxtw	x9, w0
	mov	w8, 64
	mov	x10, 1
	mov	x5, 9223372036854775807
	.p2align 5,,15
L403:
	ldr	x0, [x12, x9, lsl 3]
	mov	w11, w9
	mov	w4, w9
	add	x6, x6, x0
	cmp	x19, x2
	bcc	L398
	b	L381
	.p2align 2,,3
L454:
	add	w0, w0, w13
L399:
	ldr	w15, [x20, 16]
	sxtw	x1, w0
	add	w3, w3, 1
	fcmp	d28, #0.0
	add	x13, x19, 1
	ldr	x0, [x20, 32]
	add	w16, w15, w16
	lsl	x1, x1, x16
	orr	x0, x1, x0
	clz	x0, x0
	sub	w0, w8, w0
	sub	w0, w0, w15
	sub	w0, w0, w3
	add	w3, w15, w0
	asr	x1, x1, x3
	sxtw	x0, w1
	lsl	x0, x0, x3
	beq	L400
	ldr	w16, [x20, 40]
	cmp	w16, w1
	csinc	w3, w3, w3, gt
	lsl	x3, x10, x3
	sub	x1, x5, x3
	add	x3, x3, x0
	cmp	x1, x0
	sub	x3, x3, #1
	csel	x0, x3, x5, ge
L400:
	str	x0, [x21, x19, lsl 3]
	cmp	x19, x7
	beq	L381
	mov	x19, x13
L398:
	ldr	x0, [x21, x19, lsl 3]
	cmp	x0, x6
	bgt	L453
	ldp	w3, w13, [x20, 24]
	ldr	d28, [x22, x19, lsl 3]
	asr	w1, w4, w3
	sub	w0, w13, #1
	sub	w16, w1, #1
	and	w0, w0, w4
	cbnz	w1, L454
	mov	w16, 0
	b	L399
	.p2align 2,,3
L450:
	add	x9, x9, 1
	cmp	w3, w9
	bge	L394
	b	L387
	.p2align 2,,3
L453:
	add	w11, w11, 1
	add	x9, x9, 1
	cmp	w14, w11
	ccmp	x19, x2, 2, gt
	bcc	L403
L396:
	cmp	x19, x23
	bcs	L381
	.p2align 5,,15
L412:
	ldr	d29, [x22, x19, lsl 3]
	mov	x1, 0
	mov	x0, x20
	mov	x2, 0
	fcmp	d29, #0.0
	beq	L411
	bl	_highest_equivalent_value
	mov	x2, x0
L411:
	str	x2, [x21, x19, lsl 3]
	add	x19, x19, 1
	cmp	x23, x19
	bne	L412
L381:
	ldp	x19, x20, [sp, 16]
	mov	w0, 0
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	x29, x30, [sp], 208
LCFI89:
	ret
L419:
	mov	w0, 22
	ret
L448:
LCFI90:
	cbz	w3, L381
	stp	x25, x26, [x29, 64]
LCFI91:
	b	L413
L377:
LCFI92:
	cbz	x3, L381
	lsl	x2, x3, 3
	mov	x0, x21
	mov	w1, 0
	bl	_memset
	b	L381
L385:
	stp	x25, x26, [x29, 64]
LCFI93:
	ldr	x1, [x20, 88]
L413:
	adrp	x0, _all_values_iter_next@PAGE
	mov	w3, -1
	str	x20, [x29, 80]
	add	x0, x0, _all_values_iter_next@PAGEOFF;
	mov	x19, 0
	stp	x1, xzr, [x29, 96]
	mov	x26, 0
	add	x25, x29, 80
	mov	x2, x0
	mov	w24, 64
	str	w3, [x29, 88]
	stp	xzr, xzr, [x29, 112]
	str	xzr, [x29, 128]
	stp	xzr, xzr, [x29, 152]
	str	x0, [x29, 200]
L404:
	mov	x0, x25
	blr	x2
	cmp	w0, 0
	ccmp	x19, x23, 2, ne
	bcs	L455
	ldr	x0, [x29, 104]
	ldr	x8, [x29, 120]
	add	x26, x26, x0
	b	L405
	.p2align 2,,3
L456:
	ldr	x0, [x20, 32]
	ldr	w1, [x20, 24]
	orr	x0, x8, x0
	clz	x0, x0
	add	w1, w1, 1
	sub	w0, w24, w0
	sub	w0, w0, w1
	asr	x1, x8, x0
	sxtw	x1, w1
	lsl	x0, x1, x0
	str	x0, [x21, x19, lsl 3]
	add	x19, x19, 1
	cmp	x23, x19
	bls	L408
L405:
	ldr	x2, [x21, x19, lsl 3]
	mov	x1, x8
	mov	x0, x20
	cmp	x2, x26
	bgt	L408
	ldr	d31, [x22, x19, lsl 3]
	fcmp	d31, #0.0
	beq	L456
	bl	_highest_equivalent_value
	str	x0, [x21, x19, lsl 3]
	add	x19, x19, 1
	cmp	x23, x19
	bhi	L405
L408:
	ldr	x2, [x29, 200]
	b	L404
L455:
	ldp	x25, x26, [x29, 64]
LCFI94:
	b	L396
L449:
	add	w0, w0, 1
	b	L416
L386:
	mov	x19, 0
	cmp	w14, 0
	ble	L412
	mov	w0, 0
	mov	x19, 0
	mov	x6, 0
	b	L414
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
LCFI111:
	stp	x29, x30, [sp, 48]
LCFI112:
	add	x29, sp, 48
LCFI113:
	stp	x19, x20, [sp, 64]
LCFI114:
	mov	x19, x1
	stp	x21, x22, [sp, 80]
LCFI115:
	mov	x22, x0
	mov	w21, w2
	stp	d13, d14, [sp, 112]
LCFI116:
	fmov	d14, d0
	ldr	w0, [x0, 20]
	str	x23, [sp, 96]
LCFI117:
	mov	w23, w3
	cmp	w3, 1
	beq	L554
	adrp	x3, lC7@PAGE
	adrp	x1, lC8@PAGE
	str	w0, [sp, 8]
	add	x3, x3, lC7@PAGEOFF;
	add	x1, x1, lC8@PAGEOFF;
	adrp	x2, lC4@PAGE
	add	x20, x29, 80
	add	x2, x2, lC4@PAGEOFF;
	mov	x0, x20
	str	x1, [sp]
	mov	x1, 25
	str	x3, [sp, 16]
	bl	_snprintf
	adrp	x1, lC3@PAGE
	add	x1, x1, lC3@PAGEOFF;
L537:
	ldr	x6, [x22, 88]
	adrp	x5, lC9@PAGE
	adrp	x4, lC10@PAGE
	adrp	x2, lC11@PAGE
	adrp	x0, lC12@PAGE
	str	x22, [x29, 112]
	add	x5, x5, lC9@PAGEOFF;
	add	x4, x4, lC10@PAGEOFF;
	stp	xzr, xzr, [x29, 144]
	add	x2, x2, lC11@PAGEOFF;
	add	x0, x0, lC12@PAGEOFF;
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
	tbnz	w0, #31, L540
	mov	x0, 4636737291354636288
	str	d15, [x29, 56]
LCFI118:
	fmov	d15, 1.0e+0
	fmov	d13, x0
	b	L538
	.p2align 2,,3
L541:
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
	tbnz	w0, #31, L553
L538:
	ldr	x2, [x29, 232]
	mov	x0, x21
	blr	x2
	mov	x1, x20
	mov	w2, w0
	mov	x0, x19
	tbnz	x2, 0, L541
	cbz	w23, L555
L542:
L539:
	ldr	d15, [x29, 56]
LCFI119:
	mov	w0, 0
	ldp	x29, x30, [sp, 48]
	ldp	x19, x20, [sp, 64]
	ldp	x21, x22, [sp, 80]
	ldr	x23, [sp, 96]
	ldp	d13, d14, [sp, 112]
	add	sp, sp, 288
LCFI120:
	ret
	.p2align 2,,3
L555:
LCFI121:
	mov	x0, x22
	bl	_hdr_mean
	ldr	x8, [x22, 88]
	fdiv	d15, d0, d14
	movi	d31, #0
	cbz	x8, L543
	mov	x0, x22
	bl	_hdr_stddev.part.0
	ldr	x8, [x22, 88]
	fmov	d31, d0
L543:
	fdiv	d30, d31, d14
	movi	d31, #0
	ldr	x1, [x22, 56]
	cbz	x1, L544
	mov	x0, x22
	bl	_highest_equivalent_value
	scvtf	d31, x0
L544:
	fdiv	d31, d31, d14
	stp	d15, d30, [sp]
	adrp	x1, _CLASSIC_FOOTER@PAGE
	ldp	w3, w2, [x22, 40]
	mov	x0, x19
	add	x1, x1, _CLASSIC_FOOTER@PAGEOFF;
	str	x8, [sp, 24]
	str	w2, [sp, 32]
	str	w3, [sp, 40]
	str	d31, [sp, 16]
	bl	_fprintf
	tbz	w0, #31, L542
	.p2align 5,,15
L553:
	ldr	d15, [x29, 56]
LCFI122:
L540:
	ldp	x29, x30, [sp, 48]
	mov	w0, 5
	ldp	x19, x20, [sp, 64]
	ldp	x21, x22, [sp, 80]
	ldr	x23, [sp, 96]
	ldp	d13, d14, [sp, 112]
	add	sp, sp, 288
LCFI123:
	ret
	.p2align 2,,3
L554:
LCFI124:
	adrp	x3, lC5@PAGE
	adrp	x1, lC6@PAGE
	str	w0, [sp, 8]
	add	x3, x3, lC5@PAGEOFF;
	add	x1, x1, lC6@PAGEOFF;
	adrp	x2, lC4@PAGE
	add	x20, x29, 80
	add	x2, x2, lC4@PAGEOFF;
	mov	x0, x20
	str	x1, [sp]
	mov	x1, 25
	str	x3, [sp, 16]
	bl	_snprintf
	adrp	x1, lC2@PAGE
	add	x1, x1, lC2@PAGEOFF;
	b	L537
LFE106:
	.const
	.align	3
