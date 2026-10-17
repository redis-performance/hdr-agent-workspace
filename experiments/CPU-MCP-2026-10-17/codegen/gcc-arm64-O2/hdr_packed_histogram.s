_sparse_add:
LFB44:
	stp	x29, x30, [sp, -80]!
LCFI17:
	mov	x29, sp
LCFI18:
	stp	x19, x20, [sp, 16]
LCFI19:
	mov	w19, 0
	mov	w20, w1
	stp	x21, x22, [sp, 32]
LCFI20:
	mov	x22, x2
	stp	x23, x24, [sp, 48]
LCFI21:
	mov	x23, x0
	ldr	w6, [x0, 48]
	ldr	x0, [x0, 8]
	mov	w4, w6
	b	L50
	.p2align 2,,3
L51:
	add	w3, w19, w3, lsr 1
	ldr	w5, [x0, w3, sxtw 2]
	cmp	w20, w5
	bgt	L78
	mov	w4, w3
L50:
	subs	w3, w4, w19
	bgt	L51
	cmp	w6, w19
	ble	L52
	ldr	w1, [x0, w19, sxtw 2]
	sxtw	x21, w19
	cmp	w1, w20
	beq	L79
L52:
	ldp	w2, w3, [x23, 52]
	cmp	w6, w2
	bge	L60
	cmp	w3, w6
	bgt	L61
L60:
	cmp	w3, w2
	mov	w4, 1073741823
	csel	w1, w3, w2, le
	cmp	w1, w4
	bgt	L62
	cmp	w1, 0
	mov	w4, 4
	lsl	w1, w1, 1
	csel	w21, w1, w4, ne
	cmp	w2, w21
	blt	L80
L64:
	cmp	w21, w3
	bgt	L81
L61:
	mov	x1, x22
	mov	x0, x23
	bl	_widen_to_fit
	tbz	x0, 0, L62
	ldr	w2, [x23, 48]
	sxtw	x24, w19
	add	x21, x24, 1
	ldr	x1, [x23, 8]
	lsl	x0, x21, 2
	str	x25, [x29, 64]
LCFI22:
	sub	x25, x0, #4
	sub	w2, w2, w19
	sbfiz	x2, x2, 2, 32
	add	x0, x1, x0
	add	x1, x1, x25
	bl	_memmove
	ldrb	w3, [x23, 60]
	ldr	w1, [x23, 48]
	ldr	x0, [x23, 16]
	mul	x21, x21, x3
	sub	w1, w1, w19
	sxtw	x2, w1
	sub	x1, x21, x3
	add	x1, x0, x1
	add	x0, x0, x21
	mul	x2, x2, x3
	bl	_memmove
	ldp	x1, x0, [x23, 8]
	mov	x2, x22
	str	w20, [x1, x25]
	ldr	w3, [x23, 48]
	ldrb	w4, [x23, 60]
	add	w3, w3, 1
	madd	x0, x4, x24, x0
	mov	x1, x4
	str	w3, [x23, 48]
	bl	_store_w
	ldr	x25, [x29, 64]
LCFI23:
	mov	w0, 1
	b	L58
	.p2align 2,,3
L62:
	mov	w0, 0
L58:
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	x29, x30, [sp], 80
LCFI24:
	ret
	.p2align 2,,3
L78:
LCFI25:
	add	w19, w3, 1
	b	L50
L81:
	ldrb	w2, [x23, 60]
	sxtw	x1, w21
	ldr	x0, [x23, 16]
	mul	x1, x2, x1
	bl	_realloc
	cbz	x0, L62
	str	x0, [x23, 16]
	str	w21, [x23, 56]
	b	L61
L80:
	sbfiz	x1, x21, 2, 32
	bl	_realloc
	cbz	x0, L62
	ldr	w3, [x23, 56]
	str	x0, [x23, 8]
	str	w21, [x23, 52]
	b	L64
L79:
	ldrb	w1, [x23, 60]
	ldr	x2, [x23, 16]
	mov	x0, x1
	mul	x1, x1, x21
	cmp	w0, 2
	beq	L53
	cmp	w0, 4
	beq	L54
	cmp	w0, 1
	bne	L55
	ldrb	w19, [x2, x1]
L56:
	add	x19, x22, x19
	mov	x0, x23
	mov	x1, x19
	bl	_widen_to_fit
	tbz	x0, 0, L62
	ldr	x0, [x23, 16]
	mov	x2, x19
	ldrb	w3, [x23, 60]
	madd	x0, x3, x21, x0
	mov	x1, x3
	bl	_store_w
	mov	w0, 1
	b	L58
L55:
	ldr	x19, [x2, x1]
	b	L56
L54:
	ldr	w19, [x2, x1]
	b	L56
L53:
	ldrh	w19, [x2, x1]
	b	L56
LFE44:
	.align	2
	.p2align 5,,15
_hdr_packed_record_values:
LFB53:
	tbnz	x1, #63, L151
	stp	x29, x30, [sp, -48]!
LCFI54:
	mov	x29, sp
LCFI55:
	cmp	x2, 0
	stp	x19, x20, [sp, 16]
LCFI56:
	mov	x19, x1
	mov	x20, x2
	stp	x21, x22, [sp, 32]
LCFI57:
	mov	x21, x0
	ldr	x22, [x0]
	ldr	x0, [x22, 8]
	ccmp	x0, x1, 1, ge
	bge	L152
L134:
	mov	w0, 0
L133:
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x29, x30, [sp], 48
LCFI58:
	ret
	.p2align 2,,3
L152:
LCFI59:
	mov	x0, x22
	bl	_counts_index_for
	ldr	w1, [x22, 80]
	cmp	w1, w0
	bls	L134
	ldr	x2, [x21, 24]
	mov	x1, 9223372036854775807
	sub	x1, x1, x2
	cmp	x1, x20
	blt	L134
	cbnz	x20, L153
L135:
	ldr	x0, [x21, 32]
	add	x20, x20, x2
	cmp	x19, 0
	str	x20, [x21, 24]
	ccmp	x0, x19, 4, ne
	bgt	L154
L136:
	ldr	x0, [x21, 40]
	cmp	x0, x19
	bge	L138
	str	x19, [x21, 40]
L138:
	mov	w0, 1
	b	L133
	.p2align 2,,3
L151:
LCFI60:
	mov	w0, 0
	ret
	.p2align 2,,3
L153:
LCFI61:
	mov	w1, w0
	mov	x2, x20
	mov	x0, x21
	bl	_sparse_add
	tbz	x0, 0, L134
	ldr	x2, [x21, 24]
	b	L135
	.p2align 2,,3
L154:
	str	x19, [x21, 32]
	b	L136
LFE53:
	.align	2
	.p2align 5,,15
	.globl _hdr_packed_record_value
_hdr_packed_record_value:
LFB54:
	tbnz	x1, #63, L170
	stp	x29, x30, [sp, -48]!
LCFI62:
	mov	x29, sp
LCFI63:
	stp	x19, x20, [sp, 16]
LCFI64:
	mov	x20, x0
	mov	x19, x1
	str	x21, [sp, 32]
LCFI65:
	ldr	x21, [x0]
	ldr	x0, [x21, 8]
	cmp	x1, x0
	bgt	L158
	mov	x0, x21
	bl	_counts_index_for
	ldr	w2, [x21, 80]
	mov	w1, w0
	cmp	w2, w0
	bls	L158
	ldr	x2, [x20, 24]
	mov	x0, 9223372036854775807
	cmp	x2, x0
	beq	L158
	mov	x2, 1
	mov	x0, x20
	bl	_sparse_add
	tbz	x0, 0, L158
	ldp	x1, x2, [x20, 24]
	cmp	x19, 0
	add	x1, x1, 1
	ccmp	x19, x2, 0, ne
	str	x1, [x20, 24]
	blt	L171
L159:
	ldr	x1, [x20, 40]
	cmp	x19, x1
	ble	L157
	str	x19, [x20, 40]
	b	L157
	.p2align 2,,3
L158:
	mov	w0, 0
L157:
	ldr	x21, [sp, 32]
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 48
LCFI66:
	ret
	.p2align 2,,3
L170:
	mov	w0, 0
	ret
	.p2align 2,,3
L171:
LCFI67:
	str	x19, [x20, 32]
	b	L159
LFE54:
	.align	2
	.p2align 5,,15
	.globl _hdr_packed_reset
_hdr_packed_count_at_value:
LFB59:
	tbnz	x1, #63, L205
	stp	x29, x30, [sp, -32]!
LCFI83:
	mov	x29, sp
LCFI84:
	stp	x19, x20, [sp, 16]
LCFI85:
	mov	x19, x0
	ldr	x20, [x0]
	mov	x0, x20
	bl	_counts_index_for
	ldr	w2, [x20, 80]
	cmp	w2, w0
	bhi	L208
	ldp	x19, x20, [sp, 16]
	mov	x0, 0
	ldp	x29, x30, [sp], 32
LCFI86:
	ret
	.p2align 2,,3
L208:
LCFI87:
	mov	w1, w0
	mov	x0, x19
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 32
LCFI88:
	b	_sparse_get
	.p2align 2,,3
L205:
	mov	x0, 0
	ret
LFE59:
	.align	2
	.p2align 5,,15
	.globl _hdr_packed_max
_hdr_packed_value_at_percentile:
LFB65:
	mov	x1, x0
	ldr	x0, [x0, 24]
	cbnz	x0, L299
	ret
	.p2align 2,,3
L299:
	mov	x2, 4636737291354636288
	scvtf	d29, x0
	fmov	d26, 5.0e-1
	fmov	d27, 1.0e+0
	stp	x29, x30, [sp, -48]!
LCFI100:
	mov	x29, sp
LCFI101:
	movi	v28.4s, 0
	fmov	d30, x2
	stp	x19, x20, [sp, 16]
LCFI102:
	ldr	x19, [x1]
	str	d15, [sp, 32]
LCFI103:
	fmov	d15, d0
	fcmpe	d0, d30
	fcsel	d31, d0, d30, mi
	fdiv	d31, d31, d30
	fmul	d31, d31, d29
	fadd	d31, d31, d26
	fcmpe	d31, d27
	bge	L277
	ldrb	w3, [x1, 60]
	mov	x0, 1
	ldp	x7, x2, [x1, 8]
	ldr	w5, [x1, 48]
	cmp	w3, 2
	bne	L300
L231:
	negs	w10, w5
	and	w1, w5, 15
	and	w10, w10, 15
	csneg	w10, w1, w10, mi
	sub	w10, w5, w10
	cmp	w10, 0
	ble	L270
	mov	x8, x2
	mov	x9, 0
	mov	x4, 16
	mov	x3, 0
	b	L244
	.p2align 2,,3
L246:
	add	x3, x3, x1
L249:
	add	x9, x9, 16
	add	x8, x8, 32
	add	x1, x4, 16
	cmp	w10, w9
	ble	L243
	mov	x4, x1
L244:
	movi	v31.4s, 0
	mov	x1, 0
L245:
	ldr	q30, [x8, x1]
	add	x1, x1, 16
	zip1	v29.8h, v30.8h, v28.8h
	zip2	v30.8h, v30.8h, v28.8h
	uaddw	v31.2d, v31.2d, v29.2s
	uaddw2	v31.2d, v31.2d, v29.4s
	uaddw	v31.2d, v31.2d, v30.2s
	uaddw2	v31.2d, v31.2d, v30.4s
	cmp	x1, 32
	bne	L245
	addp	d31, v31.2d
	sub	x6, x0, x3
	fmov	x1, d31
	cmp	x1, x6
	blt	L246
	mov	x1, x9
	b	L248
	.p2align 2,,3
L247:
	add	x1, x1, 1
	cmp	x4, x1
	beq	L249
L248:
	ldrh	w6, [x2, x1, lsl 1]
	add	x3, x3, x6
	cmp	x3, x0
	blt	L247
L298:
	ldr	w1, [x7, w1, uxtw 2]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
L237:
	fcmp	d15, #0.0
	mov	x1, x20
	mov	x0, x19
	beq	L301
	bl	_hdr_lowest_equivalent_value
	mov	x2, x0
	mov	x1, x20
	mov	x0, x19
	mov	x19, x2
	bl	_hdr_size_of_equivalent_value_range
	mov	x1, 9223372036854775807
	ldr	d15, [sp, 32]
	sub	x2, x1, x0
	add	x0, x19, x0
	cmp	x19, x2
	sub	x0, x0, #1
	ldp	x19, x20, [sp, 16]
	csel	x0, x0, x1, le
	ldp	x29, x30, [sp], 48
LCFI104:
	ret
	.p2align 2,,3
L277:
LCFI105:
	fcmpe	d29, d31
	bls	L229
	fcvtzs	x0, d31
L229:
	ldrb	w3, [x1, 60]
	ldp	x7, x2, [x1, 8]
	ldr	w5, [x1, 48]
	cmp	w3, 2
	beq	L231
L300:
	cmp	w3, 4
	beq	L232
	cmp	w3, 1
	beq	L302
	cmp	w5, 0
	ble	L275
	mov	x3, 0
	mov	x1, 0
	sxtw	x5, w5
	mov	x8, 9223372036854775807
	b	L263
	.p2align 2,,3
L303:
	cmp	x1, x0
	bge	L261
	add	x3, x3, 1
	cmp	x5, x3
	beq	L275
L263:
	ldr	x4, [x2, x3, lsl 3]
	sub	x6, x8, x1
	add	x1, x1, x4
	cmp	x4, x6
	ble	L303
L261:
	ldr	w1, [x7, w3, uxtw 2]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
	b	L237
	.p2align 2,,3
L302:
	negs	w9, w5
	and	w1, w5, 15
	and	w9, w9, 15
	csneg	w9, w1, w9, mi
	sub	w9, w5, w9
	mov	x8, 0
	mov	x4, 16
	mov	x3, 0
	cmp	w9, 0
	bgt	L234
	b	L304
	.p2align 2,,3
L292:
	add	x3, x3, x1
L239:
	add	x8, x8, 16
	add	x1, x4, 16
	cmp	w9, w8
	ble	L235
	mov	x4, x1
L234:
	ldr	q30, [x2, x8]
	sub	x6, x0, x3
	uxtl	v29.8h, v30.8b
	uxtl2	v30.8h, v30.16b
	uxtl	v27.4s, v29.4h
	uxtl2	v29.4s, v29.8h
	uxtl	v28.4s, v30.4h
	uxtl2	v30.4s, v30.8h
	uxtl	v31.2d, v27.2s
	uaddw2	v31.2d, v31.2d, v27.4s
	uaddw	v31.2d, v31.2d, v29.2s
	uaddw2	v31.2d, v31.2d, v29.4s
	uaddw	v31.2d, v31.2d, v28.2s
	uaddw2	v31.2d, v31.2d, v28.4s
	uaddw	v31.2d, v31.2d, v30.2s
	uaddw2	v31.2d, v31.2d, v30.4s
	addp	d31, v31.2d
	fmov	x1, d31
	cmp	x6, x1
	bgt	L292
	mov	x1, x8
	b	L238
	.p2align 2,,3
L236:
	add	x1, x1, 1
	cmp	x4, x1
	beq	L239
L238:
	ldrb	w6, [x2, x1]
	add	x3, x3, x6
	cmp	x3, x0
	blt	L236
	b	L298
	.p2align 2,,3
L301:
	ldr	d15, [sp, 32]
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 48
LCFI106:
	b	_hdr_lowest_equivalent_value
	.p2align 2,,3
L232:
LCFI107:
	negs	w9, w5
	and	w1, w5, 15
	and	w9, w9, 15
	csneg	w9, w1, w9, mi
	sub	w9, w5, w9
	mov	x3, 0
	mov	w8, 0
	mov	x4, 64
	sub	x10, x2, #64
	cmp	w9, 0
	ble	L253
	.p2align 5,,15
L252:
	movi	v31.4s, 0
	add	x6, x10, x4
	mov	x1, 0
L254:
	ldr	q30, [x6, x1]
	add	x1, x1, 16
	uaddw	v31.2d, v31.2d, v30.2s
	uaddw2	v31.2d, v31.2d, v30.4s
	cmp	x1, 64
	bne	L254
	addp	d31, v31.2d
	sub	x6, x0, x3
	fmov	x1, d31
	cmp	x6, x1
	ble	L305
	add	x3, x3, x1
L258:
	add	w8, w8, 16
	add	x4, x4, 64
	cmp	w9, w8
	bgt	L252
L253:
	cmp	w5, w8
	ble	L275
	sub	w5, w5, w8
	ubfiz	x4, x8, 2, 32
	add	x1, x5, w8, sxtw
	lsl	x1, x1, 2
	b	L260
	.p2align 2,,3
L259:
	add	x4, x4, 4
	cmp	x1, x4
	beq	L275
L260:
	ldr	w5, [x2, x4]
	add	x3, x3, x5
	cmp	x3, x0
	blt	L259
	ldr	w1, [x7, x4]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
	b	L237
	.p2align 2,,3
L305:
	sub	x1, x4, #64
	b	L257
	.p2align 2,,3
L256:
	add	x1, x1, 4
	cmp	x4, x1
	beq	L258
L257:
	ldr	w6, [x2, x1]
	add	x3, x3, x6
	cmp	x3, x0
	blt	L256
	ldr	w1, [x7, x1]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
	b	L237
L275:
	mov	x20, 0
	b	L237
L304:
	mov	w4, 0
L235:
	cmp	w5, w4
	ble	L275
	sxtw	x1, w4
	b	L242
	.p2align 2,,3
L241:
	add	x1, x1, 1
	cmp	w5, w1
	ble	L275
L242:
	ldrb	w4, [x2, x1]
	add	x3, x3, x4
	cmp	x3, x0
	blt	L241
	b	L298
L270:
	mov	x3, 0
	mov	w4, 0
L243:
	cmp	w5, w4
	ble	L275
	sxtw	x1, w4
	b	L251
	.p2align 2,,3
L250:
	add	x1, x1, 1
	cmp	w5, w1
	ble	L275
L251:
	ldrh	w4, [x2, x1, lsl 1]
	add	x3, x3, x4
	cmp	x3, x0
	blt	L250
	b	L298
LFE65:
	.align	2
	.p2align 5,,15
	.globl _hdr_packed_value_at_percentiles
_hdr_packed_value_at_percentiles:
LFB66:
	sub	sp, sp, #928
LCFI108:
	cmp	x1, 0
	ccmp	x2, 0, 4, ne
	stp	x29, x30, [sp]
LCFI109:
	mov	x29, sp
LCFI110:
	stp	x23, x24, [sp, 48]
LCFI111:
	mov	x23, x1
	str	x2, [x29, 152]
	beq	L373
	stp	x21, x22, [x29, 32]
LCFI112:
	mov	x21, x3
	cbz	x3, L309
	mov	x24, x0
	stp	x25, x26, [x29, 64]
LCFI113:
	ldr	x25, [x0, 24]
	cbz	x25, L422
	stp	x19, x20, [x29, 16]
LCFI114:
	stp	x27, x28, [x29, 80]
LCFI115:
	ldr	x22, [x0]
	cmp	x3, 32
	bhi	L423
	add	x19, x29, 672
	add	x28, x29, 416
	add	x20, x29, 160
	lsl	x26, x3, 3
L312:
	mov	x3, 4636737291354636288
	scvtf	d29, x25
	fmov	d26, 5.0e-1
	fmov	d27, 1.0e+0
	mov	x1, 0
	fmov	d30, x3
	.p2align 5,,15
L316:
	ldr	d31, [x23, x1, lsl 3]
	mov	x3, x25
	fcmpe	d31, d30
	fcsel	d31, d31, d30, mi
	fdiv	d31, d31, d30
	fmul	d31, d31, d29
	fadd	d31, d31, d26
	fcmpe	d31, d27
	bge	L385
	mov	x3, 1
L314:
	str	x1, [x19, x1, lsl 3]
	str	x3, [x20, x1, lsl 3]
	add	x1, x1, 1
	cmp	x1, x21
	bne	L316
	mov	w1, 0
	mov	x2, x26
	mov	x0, x28
	bl	_memset
	mov	x3, 1
	movi	v28.4s, 0
	add	x1, x19, 8
	cmp	x21, x3
	beq	L326
	.p2align 5,,15
L325:
	ldr	x9, [x1]
	mov	x4, x1
	ldr	x2, [x20, x9, lsl 3]
	.p2align 5,,15
L322:
	mov	x6, x4
	ldr	x5, [x4, -8]
	ldr	x7, [x20, x5, lsl 3]
	cmp	x7, x2
	ble	L323
	str	x5, [x4]
	sub	x4, x6, #8
	cmp	x19, x4
	bne	L322
	mov	x6, x19
L323:
	add	x3, x3, 1
	str	x9, [x6]
	add	x1, x1, 8
	cmp	x21, x3
	bne	L325
L326:
	ldr	w6, [x24, 48]
	ldp	x25, x5, [x24, 8]
	ldr	x1, [x19]
	negs	w26, w6
	and	w2, w6, 15
	and	w26, w26, 15
	csneg	w26, w2, w26, mi
	sub	w26, w6, w26
	ldrb	w0, [x24, 60]
	ldr	x4, [x20, x1, lsl 3]
	cmp	w0, 2
	beq	L318
	cmp	w0, 4
	beq	L319
	cmp	w0, 1
	beq	L320
	cmp	w6, 0
	ble	L330
	mov	x24, 0
	mov	x26, 0
	add	x6, x5, w6, uxtw 3
	mov	x2, 9223372036854775807
	mov	x27, x5
	b	L367
	.p2align 2,,3
L365:
	add	x27, x27, 8
	add	x25, x25, 4
	cmp	x6, x27
	beq	L330
L367:
	ldr	x0, [x27]
	sub	x1, x2, x26
	cmp	x1, x0
	blt	L383
	add	x26, x26, x0
	cmp	x26, x4
	blt	L365
L364:
	ldr	w1, [x25]
	mov	x0, x22
	str	x6, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x6, [x29, 144]
	mov	x2, 9223372036854775807
	b	L366
	.p2align 2,,3
L424:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x26
	bgt	L365
L366:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L424
	.p2align 5,,15
L330:
	mov	x25, 0
	mov	x24, 9223372036854775807
	b	L337
	.p2align 2,,3
L426:
	bl	_hdr_lowest_equivalent_value
	ldr	x1, [x29, 152]
	str	x0, [x1, x25, lsl 3]
	add	x25, x25, 1
	cmp	x21, x25
	beq	L425
L337:
	ldr	d31, [x23, x25, lsl 3]
	mov	x0, x22
	ldr	x26, [x28, x25, lsl 3]
	fcmp	d31, #0.0
	mov	x1, x26
	beq	L426
	bl	_hdr_lowest_equivalent_value
	mov	x2, x0
	mov	x1, x26
	mov	x0, x22
	mov	x26, x2
	bl	_hdr_size_of_equivalent_value_range
	sub	x1, x24, x0
	add	x0, x26, x0
	cmp	x26, x1
	ldr	x1, [x29, 152]
	sub	x0, x0, #1
	csel	x0, x0, x24, le
	str	x0, [x1, x25, lsl 3]
	add	x25, x25, 1
	cmp	x21, x25
	bne	L337
L425:
	cmp	x21, 32
	bhi	L427
	ldp	x19, x20, [x29, 16]
LCFI116:
	ldp	x25, x26, [x29, 64]
LCFI117:
	ldp	x27, x28, [x29, 80]
LCFI118:
L309:
	mov	w0, 0
	ldp	x21, x22, [x29, 32]
LCFI119:
L306:
	ldp	x29, x30, [sp]
	ldp	x23, x24, [sp, 48]
	add	sp, sp, 928
LCFI120:
	ret
	.p2align 2,,3
L373:
LCFI121:
	ldp	x29, x30, [sp]
	mov	w0, 22
	ldp	x23, x24, [sp, 48]
	add	sp, sp, 928
LCFI122:
	ret
L422:
LCFI123:
	mov	x1, x2
	lsl	x2, x3, 3
	mov	x0, x1
	mov	w1, 0
	bl	_memset
	ldp	x25, x26, [x29, 64]
LCFI124:
	b	L309
L423:
LCFI125:
	mov	x0, 2305843009213693951
	cmp	x3, x0
	bhi	L313
	lsl	x26, x3, 3
	mov	x0, x26
	bl	_malloc
	mov	x2, x0
	mov	x0, x26
	mov	x20, x2
	str	x2, [x29, 136]
	bl	_malloc
	mov	x1, x0
	mov	x0, x26
	mov	x28, x1
	str	x1, [x29, 144]
	bl	_malloc
	ldp	x2, x1, [x29, 136]
	mov	x27, x0
	mov	x19, x0
	cmp	x2, 0
	ccmp	x1, 0, 4, ne
	ccmp	x0, 0, 4, ne
	bne	L312
	mov	x0, x2
	str	x1, [x29, 152]
	bl	_free
	ldr	x1, [x29, 152]
	mov	x0, x1
	bl	_free
	mov	x0, x27
	bl	_free
L313:
	ldp	x19, x20, [x29, 16]
LCFI126:
	mov	w0, 12
	ldp	x21, x22, [x29, 32]
LCFI127:
	ldp	x25, x26, [x29, 64]
LCFI128:
	ldp	x27, x28, [x29, 80]
LCFI129:
	b	L306
	.p2align 2,,3
L385:
LCFI130:
	fcmpe	d31, d29
	bge	L314
	fcvtzs	x3, d31
	b	L314
L383:
	mov	x26, 9223372036854775807
	b	L364
L427:
	mov	x0, x20
	bl	_free
	mov	x0, x28
	bl	_free
	mov	x0, x19
	bl	_free
	ldp	x19, x20, [x29, 16]
LCFI131:
	ldp	x25, x26, [x29, 64]
LCFI132:
	ldp	x27, x28, [x29, 80]
LCFI133:
	b	L309
L320:
LCFI134:
	cmp	w26, 0
	ble	L428
	mov	x9, x5
	mov	x7, 0
	mov	x24, 0
	mov	x27, 0
	b	L333
	.p2align 2,,3
L379:
	mov	x27, x0
L335:
	add	x0, x7, 16
	add	x9, x9, 16
	cmp	w26, w0
	ble	L429
	mov	x7, x0
L333:
	ldr	q30, [x9]
	uxtl	v29.8h, v30.8b
	uxtl2	v30.8h, v30.16b
	uxtl	v27.4s, v29.4h
	uxtl2	v29.4s, v29.8h
	uxtl	v28.4s, v30.4h
	uxtl2	v30.4s, v30.8h
	uxtl	v31.2d, v27.2s
	uaddw2	v31.2d, v31.2d, v27.4s
	uaddw	v31.2d, v31.2d, v29.2s
	uaddw2	v31.2d, v31.2d, v29.4s
	uaddw	v31.2d, v31.2d, v28.2s
	uaddw2	v31.2d, v31.2d, v28.4s
	uaddw	v31.2d, v31.2d, v30.2s
	uaddw2	v31.2d, v31.2d, v30.4s
	addp	d31, v31.2d
	fmov	x0, d31
	add	x0, x0, x27
	cmp	x0, x4
	blt	L379
	add	x0, x25, w7, uxtw 2
	mov	x3, 0
	str	x0, [x29, 104]
	b	L332
	.p2align 2,,3
L329:
	add	x3, x3, 1
	cmp	x3, 16
	beq	L335
L332:
	ldrb	w0, [x9, x3]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L329
	ldr	x0, [x29, 104]
	str	x5, [x29, 128]
	str	w6, [x29, 136]
	str	x3, [x29, 144]
	ldr	w1, [x0, x3, lsl 2]
	mov	x0, x22
	stp	x7, x9, [x29, 112]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 128]
	ldp	x7, x9, [x29, 112]
	ldr	x3, [x29, 144]
	ldr	w6, [x29, 136]
	b	L331
	.p2align 2,,3
L430:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L329
L331:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L430
	b	L330
L319:
	cmp	w26, 0
	ble	L431
	sub	x0, x5, #64
	mov	w27, 0
	mov	x24, 0
	mov	x9, 64
	mov	x2, 0
	str	x0, [x29, 104]
	.p2align 5,,15
L353:
	ldr	x0, [x29, 104]
	movi	v31.4s, 0
	add	x1, x0, x9
	mov	x0, 0
L355:
	ldr	q30, [x1, x0]
	add	x0, x0, 16
	uaddw	v31.2d, v31.2d, v30.2s
	uaddw2	v31.2d, v31.2d, v30.4s
	cmp	x0, 64
	bne	L355
	addp	d31, v31.2d
	fmov	x0, d31
	add	x0, x0, x2
	cmp	x0, x4
	bge	L432
	mov	x2, x0
L356:
	add	w27, w27, 16
	add	x9, x9, 64
	cmp	w26, w27
	bgt	L353
	cmp	w6, w27
	cset	w0, gt
	b	L360
	.p2align 2,,3
L432:
	sub	x3, x9, #64
	b	L359
	.p2align 2,,3
L357:
	add	x3, x3, 4
	cmp	x9, x3
	beq	L356
L359:
	ldr	w0, [x5, x3]
	add	x2, x2, x0
	cmp	x2, x4
	blt	L357
	ldr	w1, [x25, x3]
	mov	x0, x22
	stp	x9, x5, [x29, 112]
	str	w6, [x29, 128]
	stp	x2, x3, [x29, 136]
	bl	_hdr_value_at_index
	ldr	w6, [x29, 128]
	ldp	x9, x5, [x29, 112]
	ldp	x2, x3, [x29, 136]
	b	L358
	.p2align 2,,3
L433:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x2
	bgt	L357
L358:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L433
	b	L330
L318:
	cmp	w26, 0
	ble	L434
	mov	w3, 0
	mov	x24, 0
	mov	x7, x5
	mov	x27, 0
	mov	x9, x25
	b	L348
	.p2align 2,,3
L380:
	mov	x27, x0
L344:
	add	w3, w3, 16
	add	x7, x7, 32
	add	x9, x9, 64
	cmp	w26, w3
	ble	L435
L348:
	movi	v31.4s, 0
	mov	x0, 0
L343:
	ldr	q30, [x7, x0]
	add	x0, x0, 16
	zip1	v29.8h, v30.8h, v28.8h
	zip2	v30.8h, v30.8h, v28.8h
	uaddw	v31.2d, v31.2d, v29.2s
	uaddw2	v31.2d, v31.2d, v29.4s
	uaddw	v31.2d, v31.2d, v30.2s
	uaddw2	v31.2d, v31.2d, v30.4s
	cmp	x0, 32
	bne	L343
	addp	d31, v31.2d
	fmov	x0, d31
	add	x0, x0, x27
	cmp	x0, x4
	blt	L380
	mov	x2, 0
	b	L347
	.p2align 2,,3
L345:
	add	x2, x2, 1
	cmp	x2, 16
	beq	L344
L347:
	ldrh	w0, [x7, x2, lsl 1]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L345
	ldr	w1, [x9, x2, lsl 2]
	mov	x0, x22
	stp	x7, x5, [x29, 104]
	str	w3, [x29, 120]
	str	w6, [x29, 128]
	stp	x9, x2, [x29, 136]
	bl	_hdr_value_at_index
	ldr	w3, [x29, 120]
	movi	v28.4s, 0
	ldp	x7, x5, [x29, 104]
	ldp	x9, x2, [x29, 136]
	ldr	w6, [x29, 128]
	b	L346
	.p2align 2,,3
L436:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L345
L346:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L436
	b	L330
L428:
	mov	w7, 0
	mov	x24, 0
	mov	x27, 0
	cmp	w6, 0
	cset	w0, gt
L334:
	sxtw	x26, w7
	cbnz	w0, L340
	b	L330
	.p2align 2,,3
L338:
	add	x26, x26, 1
	cmp	w6, w26
	ble	L330
L340:
	ldrb	w0, [x5, x26]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L338
	ldr	w1, [x25, x26, lsl 2]
	mov	x0, x22
	str	x5, [x29, 136]
	str	w6, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 136]
	ldr	w6, [x29, 144]
	b	L339
	.p2align 2,,3
L437:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L338
L339:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L437
	b	L330
L434:
	mov	w3, 0
	mov	x24, 0
	mov	x27, 0
	cmp	w6, 0
	cset	w0, gt
L349:
	sxtw	x26, w3
	cbnz	w0, L352
	b	L330
	.p2align 2,,3
L350:
	add	x26, x26, 1
	cmp	w6, w26
	ble	L330
L352:
	ldrh	w0, [x5, x26, lsl 1]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L350
	ldr	w1, [x25, x26, lsl 2]
	mov	x0, x22
	str	x5, [x29, 136]
	str	w6, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 136]
	ldr	w6, [x29, 144]
	b	L351
	.p2align 2,,3
L438:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L350
L351:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L438
	b	L330
L431:
	mov	w27, 0
	mov	x24, 0
	mov	x2, 0
	cmp	w6, 0
	cset	w0, gt
L360:
	sxtw	x26, w27
	cbnz	w0, L363
	b	L330
	.p2align 2,,3
L361:
	add	x26, x26, 1
	cmp	w6, w26
	ble	L330
L363:
	ldr	w0, [x5, x26, lsl 2]
	add	x2, x2, x0
	cmp	x2, x4
	blt	L361
	ldr	w1, [x25, x26, lsl 2]
	mov	x0, x22
	str	x5, [x29, 128]
	str	w6, [x29, 136]
	str	x2, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 128]
	ldr	x2, [x29, 144]
	ldr	w6, [x29, 136]
	b	L362
	.p2align 2,,3
L439:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x2
	bgt	L361
L362:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L439
	b	L330
L429:
	add	w7, w7, 16
	cmp	w6, w7
	cset	w0, gt
	b	L334
L435:
	cmp	w6, w3
	cset	w0, gt
	b	L349
LFE66:
	.align	2
	.p2align 5,,15
	.globl _hdr_packed_get_memory_size
