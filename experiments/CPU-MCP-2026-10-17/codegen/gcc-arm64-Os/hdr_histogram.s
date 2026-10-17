_percentile_bound:
LFB77:
	fcmp	d0, #0.0
	bne	L125
	b	_lowest_equivalent_value
L125:
	b	_highest_equivalent_value
LFE77:
	.align	2
_percentile_iter_next:
LFB95:
	ldr	x2, [x0, 16]
	mov	x8, x0
	ldr	x1, [x0, 32]
	cmp	x2, x1
	bgt	L127
	ldrb	w1, [x0, 88]
	tbnz	x1, 0, L143
	mov	w1, 1
	strb	w1, [x0, 88]
	mov	x1, 4636737291354636288
	mov	w0, 1
	str	x1, [x8, 104]
	ret
L127:
	stp	x29, x30, [sp, -48]!
LCFI47:
	mov	x29, sp
LCFI48:
	stp	d14, d15, [sp, 32]
	ldr	w1, [x0, 8]
	str	x19, [sp, 16]
LCFI49:
	cmn	w1, #1
	beq	L130
L132:
	adrp	x0, lC0@PAGE
	ldr	d15, [x0, #lC0@PAGEOFF]
L131:
	ldr	x0, [x8, 24]
	cbz	x0, L133
	ldr	d31, [x8, 32]
	mov	x19, x8
	ldr	x0, [x19], 88
	scvtf	d31, d31
	ldr	d30, [x0, 88]
	ldr	d14, [x19, 8]
	fmul	d31, d31, d15
	scvtf	d30, d30
	fdiv	d31, d31, d30
	fcmpe	d14, d31
	bls	L137
L133:
	mov	x0, x8
	bl	_basic_iter_next
	tbnz	x0, 0, L131
	b	L135
L130:
	bl	_basic_iter_next
	tbnz	x0, 0, L132
	mov	w0, 0
	b	L136
L137:
	ldr	x1, [x8, 40]
	fsub	d0, d15, d14
	bl	_highest_equivalent_value
	ldr	x1, [x8, 80]
	fdiv	d0, d15, d0
	stp	x1, x0, [x8, 72]
	str	d14, [x19, 16]
	bl	_log
	adrp	x0, lC1@PAGE
	ldr	d31, [x0, #lC1@PAGEOFF]
	fdiv	d0, d0, d31
	fcvtzs	x0, d0
	fmov	d0, 2.0e+0
	add	x0, x0, 1
	scvtf	d1, x0
	bl	_pow
	fcvtzs	x1, d0
	ldrsw	x0, [x19, 4]
	mul	x0, x0, x1
	scvtf	d31, x0
	fdiv	d15, d15, d31
	fadd	d15, d15, d14
	str	d15, [x19, 8]
L135:
	mov	w0, 1
L136:
	ldr	x19, [sp, 16]
	ldp	d14, d15, [sp, 32]
	ldp	x29, x30, [sp], 48
LCFI50:
	ret
L143:
	mov	w0, 0
	ret
LFE95:
	.align	2
	.globl _hdr_next_non_equivalent_value
_hdr_value_at_percentile:
LFB76:
	mov	x5, x0
	ldr	x0, [x0, 88]
	cbz	x0, L235
	adrp	x1, lC0@PAGE
	stp	x29, x30, [sp, -16]!
LCFI85:
	mov	x29, sp
LCFI86:
	scvtf	d29, x0
	ldr	d30, [x1, #lC0@PAGEOFF]
	fcmpe	d0, d30
	fcsel	d31, d0, d30, mi
	fdiv	d31, d31, d30
	fmov	d30, 5.0e-1
	fmul	d31, d31, d29
	fadd	d31, d31, d30
	fmov	d30, 1.0e+0
	fcmpe	d31, d30
	bge	L257
	mov	x0, 1
	b	L237
L257:
	fcmpe	d29, d31
	bls	L237
	fcvtzs	x0, d31
L237:
	ldr	w1, [x5, 64]
	cmp	x0, 0
	csinc	x7, x0, xzr, gt
	ldr	x9, [x5, 96]
	ldr	w6, [x5, 80]
	cbz	w1, L261
	mov	x9, 0
	mov	w8, 0
	b	L239
L243:
	mov	w1, w8
	mov	x0, x5
	bl	_counts_get_normalised
	add	x9, x9, x0
	cmp	x7, x9
	bgt	L241
	mov	w1, w8
L265:
	mov	x0, x5
	bl	_hdr_value_at_index
	mov	x1, x0
L242:
	fcmp	d0, #0.0
	mov	x0, x5
	bne	L252
	ldp	x29, x30, [sp], 16
LCFI87:
	b	_lowest_equivalent_value
L241:
LCFI88:
	add	w8, w8, 1
L239:
	cmp	w6, w8
	bgt	L243
L266:
	mov	x1, 0
	b	L242
L261:
	negs	w2, w6
	and	w0, w6, 3
	and	w2, w2, 3
	mov	x4, x9
	csneg	w2, w0, w2, mi
	mov	x0, 0
	sub	w2, w6, w2
L244:
	cmp	w2, w1
	bgt	L255
	sxtw	x1, w1
L250:
	cmp	w6, w1
	ble	L266
	ldr	x2, [x9, x1, lsl 3]
	add	x0, x0, x2
	add	x2, x1, 1
	cmp	x7, x0
	ble	L265
	mov	x1, x2
	b	L250
L255:
	mov	x8, 0
	mov	x3, 0
L245:
	ldr	x10, [x4, x8, lsl 3]
	add	x8, x8, 1
	add	x3, x3, x10
	cmp	x8, 4
	bne	L245
	add	x3, x0, x3
	cmp	x3, x7
	bcc	L246
	mov	x3, 0
L248:
	ldr	x8, [x4, x3, lsl 3]
	add	x0, x0, x8
	cmp	x7, x0
	bgt	L247
	add	w1, w1, w3
	b	L265
L247:
	add	x3, x3, 1
	cmp	x3, 4
	bne	L248
L249:
	add	w1, w1, 4
	add	x4, x4, 32
	b	L244
L246:
	mov	x0, x3
	b	L249
L252:
	ldp	x29, x30, [sp], 16
LCFI89:
	b	_highest_equivalent_value
L235:
	mov	x0, 0
	ret
LFE76:
	.align	2
	.globl _hdr_values_are_equivalent
_hdr_value_at_percentiles:
LFB78:
	cmp	x1, 0
	ccmp	x2, 0, 4, ne
	beq	L325
	stp	x29, x30, [sp, -208]!
LCFI103:
	mov	x29, sp
LCFI104:
	stp	x19, x20, [sp, 16]
LCFI105:
	mov	x20, x0
	mov	x0, 0
	stp	x21, x22, [sp, 32]
LCFI106:
	mov	x22, x1
	mov	x21, x2
	stp	x23, x24, [sp, 48]
LCFI107:
	mov	x23, x3
	ldr	x1, [x20, 88]
	str	x25, [sp, 64]
LCFI108:
	cbz	x1, L291
	adrp	x2, lC0@PAGE
	fmov	d28, 5.0e-1
	fmov	d27, 1.0e+0
	ldr	d30, [x2, #lC0@PAGEOFF]
L292:
	cmp	x0, x23
	bne	L296
	ldr	w0, [x20, 64]
	cbnz	w0, L297
	ldr	x12, [x20, 96]
	mov	x8, 0
	mov	x19, 0
	mov	x10, 0
	ldr	w11, [x20, 80]
	mov	x9, x12
L298:
	add	w0, w8, 7
	cmp	w11, w0
	bgt	L306
L309:
	sxtw	x8, w8
L307:
	cmp	w11, w8
	mov	w9, w8
	ccmp	x19, x23, 2, gt
	bcc	L313
L321:
	cmp	x19, x23
	bcs	L320
	ldr	d31, [x22, x19, lsl 3]
	mov	x1, 0
	mov	x0, x20
	fcmp	d31, #0.0
	bne	L322
	bl	_lowest_equivalent_value
L323:
	str	x0, [x21, x19, lsl 3]
	add	x19, x19, 1
	b	L321
L293:
	str	xzr, [x21, x0, lsl 3]
	add	x0, x0, 1
L291:
	cmp	x0, x23
	bne	L293
L320:
	ldr	x25, [sp, 64]
	mov	w0, 0
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	x29, x30, [sp], 208
LCFI109:
	ret
L296:
LCFI110:
	ldr	d31, [x22, x0, lsl 3]
	scvtf	d29, x1
	fcmpe	d31, d30
	fcsel	d31, d31, d30, mi
	fdiv	d31, d31, d30
	fmul	d31, d31, d29
	fadd	d31, d31, d28
	fcmpe	d31, d27
	bge	L330
	mov	x4, 1
	b	L294
L330:
	fcmpe	d29, d31
	bls	L328
	fcvtzs	x4, d31
L294:
	str	x4, [x21, x0, lsl 3]
	add	x0, x0, 1
	b	L292
L328:
	mov	x4, x1
	b	L294
L305:
	ldr	x0, [x12, x8, lsl 3]
	add	x10, x10, x0
L301:
	cmp	x19, x23
	bcc	L302
L304:
	add	x8, x8, 1
L299:
	mov	w14, w8
	cmp	x8, x13
	bne	L305
	b	L300
L302:
	ldr	x0, [x21, x19, lsl 3]
	cmp	x0, x10
	bgt	L304
	mov	w1, w14
	mov	x0, x20
	ldr	d0, [x22, x19, lsl 3]
	bl	_hdr_value_at_index
	mov	x1, x0
	mov	x0, x20
	bl	_percentile_bound
	str	x0, [x21, x19, lsl 3]
	add	x19, x19, 1
	b	L301
L306:
	cmp	x19, x23
	bcs	L309
	ldp	x0, x1, [x9]
	add	x13, x8, 8
	add	x0, x0, x1
	ldp	x3, x1, [x9, 32]
	add	x0, x0, x1
	ldp	x1, x2, [x9, 48]
	add	x0, x0, x1
	ldp	x1, x4, [x9, 16]
	add	x0, x0, x10
	add	x1, x1, x4
	add	x1, x1, x3
	add	x1, x1, x2
	add	x0, x0, x1
	ldr	x1, [x21, x19, lsl 3]
	cmp	x0, x1
	bge	L299
	mov	x10, x0
L300:
	mov	x8, x13
	add	x9, x9, 64
	b	L298
L313:
	ldr	x0, [x12, x8, lsl 3]
	add	x10, x10, x0
L310:
	ldr	x0, [x21, x19, lsl 3]
	cmp	x0, x10
	bgt	L312
	mov	w1, w9
	mov	x0, x20
	ldr	d0, [x22, x19, lsl 3]
	bl	_hdr_value_at_index
	mov	x1, x0
	mov	x0, x20
	bl	_percentile_bound
	str	x0, [x21, x19, lsl 3]
	add	x19, x19, 1
	cmp	x23, x19
	bhi	L310
L312:
	add	x8, x8, 1
	b	L307
L297:
	mov	w0, -1
	stp	xzr, xzr, [x29, 104]
	mov	x19, 0
	mov	x24, 0
	add	x25, x29, 80
	str	w0, [x29, 88]
	stp	xzr, xzr, [x29, 120]
	stp	xzr, xzr, [x29, 152]
	ldr	x0, [x20, 88]
	str	x20, [x29, 80]
	str	x0, [x29, 96]
	adrp	x0, _all_values_iter_next@PAGE
	add	x0, x0, _all_values_iter_next@PAGEOFF;
	str	x0, [x29, 200]
L315:
	mov	x0, x25
	bl	_hdr_iter_next
	tbz	x0, 0, L321
	cmp	x19, x23
	bcs	L320
	ldr	x0, [x29, 104]
	ldr	x8, [x29, 120]
	add	x24, x24, x0
L316:
	ldr	x0, [x21, x19, lsl 3]
	cmp	x0, x24
	bgt	L315
	ldr	d0, [x22, x19, lsl 3]
	mov	x1, x8
	mov	x0, x20
	bl	_percentile_bound
	str	x0, [x21, x19, lsl 3]
	add	x19, x19, 1
	cmp	x23, x19
	bne	L316
	b	L315
L322:
	bl	_highest_equivalent_value
	b	L323
L325:
LCFI111:
	mov	w0, 22
	ret
LFE78:
	.align	2
	.globl _hdr_mean
_hdr_iter_percentile_init:
LFB96:
	stp	x29, x30, [sp, -16]!
LCFI137:
	mov	x29, sp
LCFI138:
	mov	x3, x0
	mov	w4, w2
	bl	_hdr_iter_init
	strb	wzr, [x0, 88]
	stp	xzr, xzr, [x0, 96]
	adrp	x0, _percentile_iter_next@PAGE
	add	x0, x0, _percentile_iter_next@PAGEOFF;
	ldp	x29, x30, [sp], 16
LCFI139:
	str	w4, [x3, 92]
	str	x0, [x3, 120]
	ret
LFE96:
	.align	2
	.globl _hdr_iter_recorded_init
_hdr_percentiles_print:
LFB106:
	sub	sp, sp, #288
LCFI151:
	cmp	w3, 1
	stp	x29, x30, [sp, 48]
LCFI152:
	add	x29, sp, 48
LCFI153:
	stp	x19, x20, [sp, 64]
LCFI154:
	mov	x20, x1
	mov	x19, x0
	stp	x21, x22, [sp, 80]
LCFI155:
	mov	w21, w3
	add	x22, x29, 80
	stp	d13, d14, [sp, 112]
	ldr	w1, [x0, 20]
	str	x23, [sp, 96]
LCFI156:
	mov	w23, w2
	adrp	x2, lC4@PAGE
	str	d15, [sp, 104]
LCFI157:
	fmov	d15, d0
	bne	L394
	adrp	x0, lC5@PAGE
	add	x2, x2, lC4@PAGEOFF;
	str	w1, [sp, 8]
	add	x0, x0, lC5@PAGEOFF;
	mov	x1, 25
	str	x0, [sp, 16]
	adrp	x0, lC6@PAGE
	add	x0, x0, lC6@PAGEOFF;
	str	x0, [sp]
	mov	x0, x22
	bl	_snprintf
	adrp	x4, lC2@PAGE
	add	x1, x4, lC2@PAGEOFF;
L395:
	mov	w0, -1
	stp	xzr, xzr, [x29, 136]
	adrp	x2, lC9@PAGE
	add	x2, x2, lC9@PAGEOFF;
	str	w0, [x29, 120]
	stp	xzr, xzr, [x29, 152]
	stp	xzr, xzr, [x29, 184]
	stp	xzr, xzr, [x29, 208]
	ldr	x0, [x19, 88]
	str	x19, [x29, 112]
	strb	wzr, [x29, 200]
	str	w23, [x29, 204]
	str	x0, [x29, 128]
	adrp	x0, _percentile_iter_next@PAGE
	add	x0, x0, _percentile_iter_next@PAGEOFF;
	str	x0, [x29, 232]
	adrp	x0, lC10@PAGE
	add	x0, x0, lC10@PAGEOFF;
	stp	x0, x2, [sp, 16]
	adrp	x2, lC11@PAGE
	adrp	x0, lC12@PAGE
	add	x0, x0, lC12@PAGEOFF;
	add	x2, x2, lC11@PAGEOFF;
	stp	x0, x2, [sp]
	mov	x0, x20
	bl	_fprintf
	tbnz	w0, #31, L398
	adrp	x0, lC0@PAGE
	fmov	d14, 1.0e+0
	add	x23, x29, 112
	ldr	d13, [x0, #lC0@PAGEOFF]
L396:
	mov	x0, x23
	bl	_hdr_iter_next
	tbnz	x0, 0, L399
	cbz	w21, L400
L401:
	mov	w0, 0
	b	L393
L394:
	adrp	x0, lC7@PAGE
	add	x2, x2, lC4@PAGEOFF;
	str	w1, [sp, 8]
	add	x0, x0, lC7@PAGEOFF;
	mov	x1, 25
	str	x0, [sp, 16]
	adrp	x0, lC8@PAGE
	add	x0, x0, lC8@PAGEOFF;
	str	x0, [sp]
	mov	x0, x22
	bl	_snprintf
	adrp	x4, lC3@PAGE
	add	x1, x4, lC3@PAGEOFF;
	b	L395
L399:
	ldr	d30, [x29, 216]
	mov	x1, x22
	ldr	x0, [x29, 144]
	fdiv	d30, d30, d13
	str	x0, [sp, 16]
	mov	x0, x20
	fsub	d31, d14, d30
	fdiv	d31, d14, d31
	str	d31, [sp, 24]
	ldr	d31, [x29, 160]
	scvtf	d31, d31
	fdiv	d31, d31, d15
	stp	d31, d30, [sp]
	bl	_fprintf
	tbz	w0, #31, L396
L398:
	mov	w0, 5
L397:
L393:
	ldr	x23, [sp, 96]
	ldp	x29, x30, [sp, 48]
	ldp	x19, x20, [sp, 64]
	ldp	x21, x22, [sp, 80]
	ldr	d15, [sp, 104]
	ldp	d13, d14, [sp, 112]
	add	sp, sp, 288
LCFI158:
	ret
L400:
LCFI159:
	mov	x0, x19
	bl	_hdr_mean
	fdiv	d14, d0, d15
	mov	x0, x19
	bl	_hdr_stddev
	mov	x0, x19
	fdiv	d0, d0, d15
	bl	_hdr_max
	scvtf	d31, x0
	ldp	w2, w1, [x19, 40]
	mov	x0, x20
	str	w1, [sp, 32]
	fdiv	d31, d31, d15
	str	w2, [sp, 40]
	ldr	x1, [x19, 88]
	stp	d14, d0, [sp]
	str	x1, [sp, 24]
	adrp	x1, _CLASSIC_FOOTER@PAGE
	add	x1, x1, _CLASSIC_FOOTER@PAGEOFF;
	str	d31, [sp, 16]
	bl	_fprintf
	tbz	w0, #31, L401
	b	L398
LFE106:
	.const
