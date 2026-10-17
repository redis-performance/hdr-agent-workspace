_hdr_packed_record_values:
LFB53:
	tbnz	x1, #63, L202
	stp	x29, x30, [sp, -80]!
LCFI45:
	mov	x29, sp
LCFI46:
	cmp	x2, 0
	stp	x19, x20, [sp, 16]
LCFI47:
	mov	x19, x0
	mov	x20, x2
	stp	x21, x22, [sp, 32]
LCFI48:
	mov	x22, x1
	ldr	x21, [x0]
	ldr	x0, [x21, 8]
	ccmp	x0, x1, 1, ge
	bge	L203
L149:
	mov	w0, 0
L148:
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x29, x30, [sp], 80
LCFI49:
	ret
	.p2align 2,,3
L203:
LCFI50:
	mov	x0, x21
	stp	x23, x24, [x29, 48]
LCFI51:
	bl	_counts_index_for
	ldr	w1, [x21, 80]
	mov	w23, w0
	cmp	w1, w0
	bls	L201
	ldr	x1, [x19, 24]
	mov	x0, 9223372036854775807
	sub	x0, x0, x1
	cmp	x0, x20
	blt	L201
	cbnz	x20, L204
L150:
	ldr	x0, [x19, 32]
	add	x20, x20, x1
	cmp	x22, 0
	str	x20, [x19, 24]
	ccmp	x22, x0, 0, ne
	blt	L205
L170:
	ldr	x0, [x19, 40]
	cmp	x22, x0
	ble	L171
	str	x22, [x19, 40]
L171:
	ldp	x23, x24, [x29, 48]
LCFI52:
	mov	w0, 1
	b	L148
	.p2align 2,,3
L202:
LCFI53:
	mov	w0, 0
	ret
	.p2align 2,,3
L201:
LCFI54:
	ldp	x23, x24, [x29, 48]
LCFI55:
	b	L149
	.p2align 2,,3
L204:
LCFI56:
	ldr	w1, [x19, 48]
	mov	w21, 0
	mov	w3, w1
	b	L152
	.p2align 2,,3
L153:
	ldr	x0, [x19, 8]
	add	w2, w21, w2, lsr 1
	ldr	w0, [x0, w2, sxtw 2]
	cmp	w23, w0
	bgt	L206
	mov	w3, w2
L152:
	subs	w2, w3, w21
	bgt	L153
	cmp	w1, w21
	ble	L154
	ldr	x0, [x19, 8]
	sxtw	x24, w21
	ldr	w0, [x0, w21, sxtw 2]
	cmp	w23, w0
	beq	L207
L154:
	ldp	w2, w3, [x19, 52]
	cmp	w1, w2
	bge	L162
	cmp	w1, w3
	blt	L163
L162:
	cmp	w3, w2
	mov	w1, 1073741823
	csel	w0, w3, w2, le
	cmp	w0, w1
	bgt	L201
	cmp	w0, 0
	mov	w1, 4
	lsl	w0, w0, 1
	csel	w24, w0, w1, ne
	cmp	w2, w24
	blt	L208
L165:
	cmp	w24, w3
	bgt	L209
L163:
	mov	x1, x20
	mov	x0, x19
	bl	_widen_to_fit
	tbz	x0, 0, L201
	stp	x25, x26, [x29, 64]
LCFI57:
	sxtw	x25, w21
	add	x24, x25, 1
	lsl	x0, x24, 2
	ldr	w2, [x19, 48]
	sub	x26, x0, #4
	ldr	x1, [x19, 8]
	sub	w2, w2, w21
	sbfiz	x2, x2, 2, 32
	add	x0, x1, x0
	add	x1, x1, x26
	bl	_memmove
	ldrb	w3, [x19, 60]
	ldr	w1, [x19, 48]
	ldr	x0, [x19, 16]
	mul	x24, x24, x3
	sub	w1, w1, w21
	sxtw	x2, w1
	sub	x1, x24, x3
	add	x1, x0, x1
	add	x0, x0, x24
	mul	x2, x2, x3
	bl	_memmove
	ldp	x0, x3, [x19, 8]
	str	w23, [x0, x26]
	ldr	w1, [x19, 48]
	ldrb	w2, [x19, 60]
	add	w1, w1, 1
	mov	x0, x2
	str	w1, [x19, 48]
	mul	x2, x2, x25
	cmp	w0, 2
	beq	L167
	cmp	w0, 4
	beq	L168
	cmp	w0, 1
	bne	L169
	strb	w20, [x3, x2]
	ldr	x1, [x19, 24]
	ldp	x25, x26, [x29, 64]
LCFI58:
	b	L150
	.p2align 2,,3
L206:
	add	w21, w2, 1
	b	L152
	.p2align 2,,3
L205:
	str	x22, [x19, 32]
	b	L170
L207:
	ldrb	w1, [x19, 60]
	ldr	x2, [x19, 16]
	mov	x0, x1
	mul	x1, x1, x24
	cmp	w0, 2
	beq	L155
	cmp	w0, 4
	beq	L156
	cmp	w0, 1
	bne	L157
	ldrb	w21, [x2, x1]
L158:
	add	x21, x20, x21
	mov	x0, x19
	mov	x1, x21
	bl	_widen_to_fit
	tbz	x0, 0, L201
	ldrb	w0, [x19, 60]
	ldr	x2, [x19, 16]
	mov	x1, x0
	mul	x0, x0, x24
	cmp	w1, 2
	beq	L159
	cmp	w1, 4
	beq	L160
	cmp	w1, 1
	bne	L161
	strb	w21, [x2, x0]
	ldr	x1, [x19, 24]
	b	L150
L208:
	ldr	x0, [x19, 8]
	sbfiz	x1, x24, 2, 32
	bl	_realloc
	cbz	x0, L201
	ldr	w3, [x19, 56]
	str	x0, [x19, 8]
	str	w24, [x19, 52]
	b	L165
L209:
	ldrb	w2, [x19, 60]
	sxtw	x1, w24
	ldr	x0, [x19, 16]
	mul	x1, x2, x1
	bl	_realloc
	cbz	x0, L201
	str	x0, [x19, 16]
	str	w24, [x19, 56]
	b	L163
L157:
	ldr	x21, [x2, x1]
	b	L158
L156:
	ldr	w21, [x2, x1]
	b	L158
L155:
	ldrh	w21, [x2, x1]
	b	L158
L169:
LCFI59:
	str	x20, [x3, x2]
	ldr	x1, [x19, 24]
	ldp	x25, x26, [x29, 64]
LCFI60:
	b	L150
L168:
LCFI61:
	str	w20, [x3, x2]
	ldr	x1, [x19, 24]
	ldp	x25, x26, [x29, 64]
LCFI62:
	b	L150
L167:
LCFI63:
	strh	w20, [x3, x2]
	ldr	x1, [x19, 24]
	ldp	x25, x26, [x29, 64]
LCFI64:
	b	L150
L159:
	strh	w21, [x2, x0]
	ldr	x1, [x19, 24]
	b	L150
L161:
	str	x21, [x2, x0]
	ldr	x1, [x19, 24]
	b	L150
L160:
	str	w21, [x2, x0]
	ldr	x1, [x19, 24]
	b	L150
LFE53:
	.align	2
	.p2align 5,,15
	.globl _hdr_packed_record_value
_hdr_packed_record_value:
LFB54:
	tbnz	x1, #63, L263
	stp	x29, x30, [sp, -80]!
LCFI65:
	mov	x29, sp
LCFI66:
	stp	x19, x20, [sp, 16]
LCFI67:
	mov	x20, x0
	stp	x23, x24, [sp, 48]
LCFI68:
	mov	x23, x1
	ldr	x19, [x0]
	ldr	x0, [x19, 8]
	cmp	x1, x0
	bgt	L213
	mov	x0, x19
	stp	x21, x22, [x29, 32]
LCFI69:
	bl	_counts_index_for
	ldr	w1, [x19, 80]
	mov	w21, w0
	cmp	w1, w0
	bls	L262
	ldr	x1, [x20, 24]
	mov	x0, 9223372036854775807
	cmp	x1, x0
	beq	L262
	ldr	w0, [x20, 48]
	mov	w19, 0
	mov	w3, w0
	b	L215
	.p2align 2,,3
L216:
	ldr	x4, [x20, 8]
	add	w2, w19, w2, lsr 1
	ldr	w4, [x4, w2, sxtw 2]
	cmp	w21, w4
	bgt	L264
	mov	w3, w2
L215:
	subs	w2, w3, w19
	bgt	L216
	cmp	w0, w19
	ble	L217
	ldr	x1, [x20, 8]
	sxtw	x22, w19
	ldr	w1, [x1, w19, sxtw 2]
	cmp	w21, w1
	beq	L265
L217:
	ldp	w1, w2, [x20, 52]
	cmp	w0, w1
	bge	L226
	cmp	w0, w2
	blt	L227
L226:
	cmp	w1, w2
	mov	w3, 1073741823
	csel	w0, w1, w2, le
	cmp	w0, w3
	bgt	L262
	cmp	w0, 0
	mov	w3, 4
	lsl	w0, w0, 1
	csel	w22, w0, w3, ne
	cmp	w1, w22
	blt	L266
L229:
	cmp	w2, w22
	blt	L267
L227:
	mov	x1, 1
	mov	x0, x20
	bl	_widen_to_fit
	tbnz	x0, 0, L268
	.p2align 5,,15
L262:
	ldp	x21, x22, [x29, 32]
LCFI70:
L213:
	mov	w0, 0
L212:
	ldp	x19, x20, [sp, 16]
	ldp	x23, x24, [sp, 48]
	ldp	x29, x30, [sp], 80
LCFI71:
	ret
	.p2align 2,,3
L263:
	mov	w0, 0
	ret
	.p2align 2,,3
L264:
LCFI72:
	add	w19, w2, 1
	b	L215
	.p2align 2,,3
L268:
	ldr	w2, [x20, 48]
	sxtw	x24, w19
	add	x22, x24, 1
	ldr	x1, [x20, 8]
	lsl	x0, x22, 2
	str	x25, [x29, 64]
LCFI73:
	sub	x25, x0, #4
	sub	w2, w2, w19
	sbfiz	x2, x2, 2, 32
	add	x0, x1, x0
	add	x1, x1, x25
	bl	_memmove
	ldrb	w3, [x20, 60]
	ldr	w1, [x20, 48]
	ldr	x0, [x20, 16]
	mul	x22, x22, x3
	sub	w1, w1, w19
	sxtw	x2, w1
	sub	x1, x22, x3
	add	x1, x0, x1
	add	x0, x0, x22
	mul	x2, x2, x3
	bl	_memmove
	ldp	x0, x3, [x20, 8]
	str	w21, [x0, x25]
	ldr	w1, [x20, 48]
	ldrb	w2, [x20, 60]
	add	w1, w1, 1
	mov	x0, x2
	str	w1, [x20, 48]
	mul	x2, x2, x24
	cmp	w0, 2
	beq	L231
	cmp	w0, 4
	beq	L232
	cmp	w0, 1
	bne	L233
	strb	w0, [x3, x2]
	ldr	x25, [x29, 64]
LCFI74:
	.p2align 5,,15
L225:
	ldp	x0, x1, [x20, 24]
	cmp	x23, 0
	add	x0, x0, 1
	ccmp	x23, x1, 0, ne
	str	x0, [x20, 24]
	blt	L269
L234:
	ldr	x0, [x20, 40]
	cmp	x23, x0
	ble	L235
	str	x23, [x20, 40]
L235:
	ldp	x21, x22, [x29, 32]
LCFI75:
	mov	w0, 1
	b	L212
	.p2align 2,,3
L265:
LCFI76:
	ldrb	w1, [x20, 60]
	ldr	x2, [x20, 16]
	mov	x0, x1
	mul	x1, x1, x22
	cmp	w0, 2
	beq	L218
	cmp	w0, 4
	beq	L219
	cmp	w0, 1
	bne	L220
	ldrb	w19, [x2, x1]
L221:
	add	x19, x19, 1
	mov	x0, x20
	mov	x1, x19
	bl	_widen_to_fit
	tbz	x0, 0, L262
	ldrb	w1, [x20, 60]
	ldr	x2, [x20, 16]
	mov	x0, x1
	mul	x1, x1, x22
	cmp	w0, 2
	beq	L222
	cmp	w0, 4
	beq	L223
	cmp	w0, 1
	bne	L224
	strb	w19, [x2, x1]
	b	L225
L269:
	str	x23, [x20, 32]
	b	L234
L266:
	ldr	x0, [x20, 8]
	sbfiz	x1, x22, 2, 32
	bl	_realloc
	cbz	x0, L262
	ldr	w2, [x20, 56]
	str	x0, [x20, 8]
	str	w22, [x20, 52]
	b	L229
L267:
	ldrb	w2, [x20, 60]
	sxtw	x1, w22
	ldr	x0, [x20, 16]
	mul	x1, x2, x1
	bl	_realloc
	cbz	x0, L262
	str	x0, [x20, 16]
	str	w22, [x20, 56]
	b	L227
L220:
	ldr	x19, [x2, x1]
	b	L221
L219:
	ldr	w19, [x2, x1]
	b	L221
L218:
	ldrh	w19, [x2, x1]
	b	L221
L231:
LCFI77:
	mov	w0, 1
	strh	w0, [x3, x2]
	ldr	x25, [x29, 64]
LCFI78:
	b	L225
L233:
LCFI79:
	mov	x0, 1
	str	x0, [x3, x2]
	ldr	x25, [x29, 64]
LCFI80:
	b	L225
L232:
LCFI81:
	mov	w0, 1
	str	w0, [x3, x2]
	ldr	x25, [x29, 64]
LCFI82:
	b	L225
L222:
	strh	w19, [x2, x1]
	b	L225
L224:
	str	x19, [x2, x1]
	b	L225
L223:
	str	w19, [x2, x1]
	b	L225
LFE54:
	.align	2
	.p2align 5,,15
	.globl _hdr_packed_reset
_hdr_packed_count_at_value:
LFB59:
	tbnz	x1, #63, L302
	stp	x29, x30, [sp, -32]!
LCFI99:
	mov	x29, sp
LCFI100:
	stp	x19, x20, [sp, 16]
LCFI101:
	mov	x19, x0
	ldr	x20, [x0]
	mov	x0, x20
	bl	_counts_index_for
	ldr	w2, [x20, 80]
	cmp	w2, w0
	bhi	L305
	ldp	x19, x20, [sp, 16]
	mov	x0, 0
	ldp	x29, x30, [sp], 32
LCFI102:
	ret
	.p2align 2,,3
L305:
LCFI103:
	mov	w1, w0
	mov	x0, x19
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 32
LCFI104:
	b	_sparse_get
	.p2align 2,,3
L302:
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
	cbz	x0, L391
	mov	x2, 4636737291354636288
	scvtf	d29, x0
	fmov	d26, 5.0e-1
	fmov	d27, 1.0e+0
	stp	x29, x30, [sp, -48]!
LCFI116:
	mov	x29, sp
LCFI117:
	movi	v28.4s, 0
	fmov	d30, x2
	stp	x19, x20, [sp, 16]
LCFI118:
	ldr	x19, [x1]
	str	d15, [sp, 32]
LCFI119:
	fmov	d15, d0
	fcmpe	d0, d30
	fcsel	d31, d0, d30, mi
	fdiv	d31, d31, d30
	fmul	d31, d31, d29
	fadd	d31, d31, d26
	fcmpe	d31, d27
	bge	L374
	ldrb	w3, [x1, 60]
	mov	x0, 1
	ldp	x7, x2, [x1, 8]
	ldr	w5, [x1, 48]
	cmp	w3, 2
	bne	L396
L328:
	negs	w10, w5
	and	w1, w5, 15
	and	w10, w10, 15
	csneg	w10, w1, w10, mi
	sub	w10, w5, w10
	cmp	w10, 0
	ble	L367
	mov	x8, x2
	mov	x9, 0
	mov	x4, 16
	mov	x3, 0
	b	L341
	.p2align 2,,3
L343:
	add	x3, x3, x1
L346:
	add	x9, x9, 16
	add	x8, x8, 32
	add	x1, x4, 16
	cmp	w10, w9
	ble	L340
	mov	x4, x1
L341:
	movi	v31.4s, 0
	mov	x1, 0
L342:
	ldr	q30, [x8, x1]
	add	x1, x1, 16
	zip1	v29.8h, v30.8h, v28.8h
	zip2	v30.8h, v30.8h, v28.8h
	uaddw	v31.2d, v31.2d, v29.2s
	uaddw2	v31.2d, v31.2d, v29.4s
	uaddw	v31.2d, v31.2d, v30.2s
	uaddw2	v31.2d, v31.2d, v30.4s
	cmp	x1, 32
	bne	L342
	addp	d31, v31.2d
	sub	x6, x0, x3
	fmov	x1, d31
	cmp	x6, x1
	bgt	L343
	mov	x1, x9
	b	L345
	.p2align 2,,3
L344:
	add	x1, x1, 1
	cmp	x4, x1
	beq	L346
L345:
	ldrh	w6, [x2, x1, lsl 1]
	add	x3, x3, x6
	cmp	x0, x3
	bgt	L344
L395:
	ldr	w1, [x7, w1, uxtw 2]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
L334:
	fcmp	d15, #0.0
	mov	x1, x20
	mov	x0, x19
	beq	L397
L361:
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
LCFI120:
	ret
	.p2align 2,,3
L374:
LCFI121:
	fcmpe	d29, d31
	bls	L326
	fcvtzs	x0, d31
L326:
	ldrb	w3, [x1, 60]
	ldp	x7, x2, [x1, 8]
	ldr	w5, [x1, 48]
	cmp	w3, 2
	beq	L328
L396:
	cmp	w3, 4
	beq	L329
	cmp	w3, 1
	beq	L398
	cmp	w5, 0
	ble	L372
	mov	x3, 0
	mov	x1, 0
	sxtw	x5, w5
	mov	x8, 9223372036854775807
	b	L360
	.p2align 2,,3
L399:
	cmp	x0, x1
	ble	L358
	add	x3, x3, 1
	cmp	x5, x3
	beq	L372
L360:
	ldr	x4, [x2, x3, lsl 3]
	sub	x6, x8, x1
	add	x1, x1, x4
	cmp	x4, x6
	ble	L399
L358:
	ldr	w1, [x7, w3, uxtw 2]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
	fcmp	d15, #0.0
	mov	x0, x19
	mov	x1, x20
	bne	L361
L397:
	ldr	d15, [sp, 32]
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 48
LCFI122:
	b	_hdr_lowest_equivalent_value
	.p2align 2,,3
L391:
	ret
	.p2align 2,,3
L398:
LCFI123:
	negs	w9, w5
	and	w1, w5, 15
	and	w9, w9, 15
	csneg	w9, w1, w9, mi
	sub	w9, w5, w9
	mov	x8, 0
	mov	x4, 16
	mov	x3, 0
	cmp	w9, 0
	bgt	L331
	b	L400
	.p2align 2,,3
L389:
	add	x3, x3, x1
L336:
	add	x8, x8, 16
	add	x1, x4, 16
	cmp	w9, w8
	ble	L332
	mov	x4, x1
L331:
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
	bgt	L389
	mov	x1, x8
	b	L335
	.p2align 2,,3
L333:
	add	x1, x1, 1
	cmp	x4, x1
	beq	L336
L335:
	ldrb	w6, [x2, x1]
	add	x3, x3, x6
	cmp	x0, x3
	bgt	L333
	b	L395
	.p2align 2,,3
L329:
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
	ble	L350
	.p2align 5,,15
L349:
	movi	v31.4s, 0
	add	x6, x10, x4
	mov	x1, 0
L351:
	ldr	q30, [x6, x1]
	add	x1, x1, 16
	uaddw	v31.2d, v31.2d, v30.2s
	uaddw2	v31.2d, v31.2d, v30.4s
	cmp	x1, 64
	bne	L351
	addp	d31, v31.2d
	sub	x6, x0, x3
	fmov	x1, d31
	cmp	x1, x6
	bge	L401
	add	x3, x3, x1
L355:
	add	w8, w8, 16
	add	x4, x4, 64
	cmp	w9, w8
	bgt	L349
L350:
	cmp	w5, w8
	ble	L372
	sub	w5, w5, w8
	ubfiz	x4, x8, 2, 32
	add	x1, x5, w8, sxtw
	lsl	x1, x1, 2
	b	L357
	.p2align 2,,3
L356:
	add	x4, x4, 4
	cmp	x4, x1
	beq	L372
L357:
	ldr	w5, [x2, x4]
	add	x3, x3, x5
	cmp	x0, x3
	bgt	L356
	ldr	w1, [x7, x4]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
	b	L334
L367:
	mov	x3, 0
	mov	w4, 0
L340:
	cmp	w5, w4
	bgt	L402
L372:
	mov	x20, 0
	b	L334
	.p2align 2,,3
L401:
	sub	x1, x4, #64
	b	L354
	.p2align 2,,3
L353:
	add	x1, x1, 4
	cmp	x1, x4
	beq	L355
L354:
	ldr	w6, [x2, x1]
	add	x3, x3, x6
	cmp	x0, x3
	bgt	L353
	ldr	w1, [x7, x1]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
	b	L334
L400:
	mov	w4, 0
L332:
	cmp	w5, w4
	ble	L372
	sxtw	x1, w4
	b	L339
	.p2align 2,,3
L338:
	add	x1, x1, 1
	cmp	w5, w1
	ble	L372
L339:
	ldrb	w4, [x2, x1]
	add	x3, x3, x4
	cmp	x0, x3
	bgt	L338
	b	L395
L402:
	sxtw	x1, w4
	b	L348
	.p2align 2,,3
L347:
	add	x1, x1, 1
	cmp	w5, w1
	ble	L372
L348:
	ldrh	w4, [x2, x1, lsl 1]
	add	x3, x3, x4
	cmp	x0, x3
	bgt	L347
	b	L395
LFE65:
	.align	2
	.p2align 5,,15
	.globl _hdr_packed_value_at_percentiles
_hdr_packed_value_at_percentiles:
LFB66:
	sub	sp, sp, #928
LCFI124:
	cmp	x1, 0
	ccmp	x2, 0, 4, ne
	stp	x29, x30, [sp]
LCFI125:
	mov	x29, sp
LCFI126:
	stp	x23, x24, [sp, 48]
LCFI127:
	mov	x23, x1
	str	x2, [x29, 152]
	beq	L480
	stp	x21, x22, [x29, 32]
LCFI128:
	mov	x21, x3
	cbz	x3, L406
	mov	x24, x0
	stp	x25, x26, [x29, 64]
LCFI129:
	ldr	x26, [x0, 24]
	cbz	x26, L529
	stp	x19, x20, [x29, 16]
LCFI130:
	stp	x27, x28, [x29, 80]
LCFI131:
	ldr	x22, [x0]
	cmp	x3, 32
	bhi	L530
	sub	x0, x3, #1
	scvtf	d21, x26
	cmp	x0, 1
	bls	L481
	add	x19, x29, 672
	add	x28, x29, 416
	add	x20, x29, 160
	lsl	x27, x3, 3
L479:
	dup	v22.2d, x26
	adrp	x0, lC1@PAGE
	lsr	x25, x21, 1
	mov	x1, 0
	ldr	q30, [x0, #lC1@PAGEOFF]
	dup	v26.2d, v21.d[0]
	adrp	x0, lC2@PAGE
	fmov	v23.2d, 5.0e-1
	fmov	v24.2d, 1.0e+0
	ldr	q27, [x0, #lC2@PAGEOFF]
	lsl	x0, x25, 4
	.p2align 5,,15
L413:
	ldr	q29, [x23, x1]
	fcmgt	v31.2d, v30.2d, v29.2d
	bsl	v31.16b, v29.16b, v30.16b
	fdiv	v31.2d, v31.2d, v30.2d
	fmul	v31.2d, v31.2d, v26.2d
	fadd	v31.2d, v31.2d, v23.2d
	fcvtzs	v28.2d, v31.2d
	fcmge	v29.2d, v31.2d, v26.2d
	fcmge	v31.2d, v31.2d, v24.2d
	bsl	v29.16b, v22.16b, v28.16b
	bsl	v31.16b, v29.16b, v27.16b
	str	q31, [x20, x1]
	add	x1, x1, 16
	cmp	x0, x1
	bne	L413
	and	x3, x21, 1
	and	x0, x21, -2
	tbz	x21, 0, L531
L412:
	mov	x1, 4636737291354636288
	fmov	d27, 5.0e-1
	fmov	d28, 1.0e+0
	fmov	d30, x1
L416:
	ldr	d31, [x23, x0, lsl 3]
	fmov	d29, x26
	fcmpe	d31, d30
	fcsel	d31, d31, d30, mi
	fdiv	d31, d31, d30
	fmul	d31, d31, d21
	fadd	d31, d31, d27
	fcmpe	d31, d28
	bge	L415
	mov	x1, 1
	fmov	d29, x1
L418:
	str	d29, [x20, x0, lsl 3]
	add	x0, x0, 1
	cmp	x0, x21
	bcc	L416
	mov	x2, x27
	mov	w1, 0
	mov	x0, x28
	bl	_memset
	cmp	x21, 1
	movi	v25.4s, 0
	beq	L420
	lsr	x25, x21, 1
	and	x3, x21, 1
L419:
	adrp	x2, lC4@PAGE
	adrp	x0, lC3@PAGE
	mov	x1, x19
	ldr	q29, [x2, #lC4@PAGEOFF]
	ldr	q31, [x0, #lC3@PAGEOFF]
	add	x0, x19, x25, lsl 4
	.p2align 5,,15
L421:
	mov	v30.16b, v31.16b
	add	v31.2d, v31.2d, v29.2d
	str	q30, [x1], 16
	cmp	x1, x0
	bne	L421
	cbz	x3, L422
	and	x0, x21, -2
	str	x0, [x19, x0, lsl 3]
L422:
	add	x1, x19, 8
	mov	x3, 1
	.p2align 5,,15
L432:
	ldr	x9, [x1]
	mov	x4, x1
	ldr	x2, [x20, x9, lsl 3]
	.p2align 5,,15
L429:
	mov	x6, x4
	ldr	x5, [x4, -8]
	ldr	x7, [x20, x5, lsl 3]
	cmp	x7, x2
	ble	L430
	str	x5, [x4]
	sub	x4, x6, #8
	cmp	x4, x19
	bne	L429
	mov	x6, x19
L430:
	add	x3, x3, 1
	str	x9, [x6]
	add	x1, x1, 8
	cmp	x21, x3
	bne	L432
L424:
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
	beq	L425
	cmp	w0, 4
	beq	L426
	cmp	w0, 1
	beq	L427
	cmp	w6, 0
	ble	L436
	mov	x24, 0
	mov	x26, 0
	add	x6, x5, w6, uxtw 3
	mov	x2, 9223372036854775807
	mov	x27, x5
	b	L473
	.p2align 2,,3
L471:
	add	x27, x27, 8
	add	x25, x25, 4
	cmp	x6, x27
	beq	L436
L473:
	ldr	x0, [x27]
	sub	x1, x2, x26
	cmp	x1, x0
	blt	L489
	add	x26, x26, x0
	cmp	x26, x4
	blt	L471
L470:
	ldr	w1, [x25]
	mov	x0, x22
	str	x6, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x6, [x29, 144]
	mov	x2, 9223372036854775807
	b	L472
	.p2align 2,,3
L532:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x26
	bgt	L471
L472:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L532
	.p2align 5,,15
L436:
	mov	x25, 0
	mov	x24, 9223372036854775807
	b	L443
	.p2align 2,,3
L534:
	bl	_hdr_lowest_equivalent_value
	ldr	x1, [x29, 152]
	str	x0, [x1, x25, lsl 3]
	add	x25, x25, 1
	cmp	x21, x25
	beq	L533
L443:
	ldr	d31, [x23, x25, lsl 3]
	mov	x0, x22
	ldr	x26, [x28, x25, lsl 3]
	fcmp	d31, #0.0
	mov	x1, x26
	beq	L534
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
	bne	L443
L533:
	cmp	x21, 32
	bhi	L535
	ldp	x19, x20, [x29, 16]
LCFI132:
	ldp	x25, x26, [x29, 64]
LCFI133:
	ldp	x27, x28, [x29, 80]
LCFI134:
L406:
	mov	w0, 0
	ldp	x21, x22, [x29, 32]
LCFI135:
L403:
	ldp	x29, x30, [sp]
	ldp	x23, x24, [sp, 48]
	add	sp, sp, 928
LCFI136:
	ret
	.p2align 2,,3
L480:
LCFI137:
	ldp	x29, x30, [sp]
	mov	w0, 22
	ldp	x23, x24, [sp, 48]
	add	sp, sp, 928
LCFI138:
	ret
L529:
LCFI139:
	mov	x1, x2
	lsl	x2, x3, 3
	mov	x0, x1
	mov	w1, 0
	bl	_memset
	ldp	x25, x26, [x29, 64]
LCFI140:
	b	L406
L530:
LCFI141:
	mov	x0, 2305843009213693951
	cmp	x3, x0
	bhi	L410
	lsl	x27, x3, 3
	mov	x0, x27
	bl	_malloc
	mov	x20, x0
	mov	x0, x27
	bl	_malloc
	mov	x28, x0
	mov	x0, x27
	bl	_malloc
	cmp	x20, 0
	mov	x19, x0
	ccmp	x28, 0, 4, ne
	ccmp	x0, 0, 4, ne
	beq	L536
	scvtf	d21, x26
	b	L479
	.p2align 2,,3
L415:
	fcmpe	d31, d21
	bge	L418
	fcvtzs	d29, d31
	b	L418
L489:
	mov	x26, 9223372036854775807
	b	L470
L535:
	mov	x0, x20
	bl	_free
	mov	x0, x28
	bl	_free
	mov	x0, x19
	bl	_free
	ldp	x19, x20, [x29, 16]
LCFI142:
	ldp	x25, x26, [x29, 64]
LCFI143:
	ldp	x27, x28, [x29, 80]
LCFI144:
	b	L406
L531:
LCFI145:
	mov	x2, x27
	mov	w1, 0
	str	x3, [x29, 144]
	mov	x0, x28
	bl	_memset
	ldr	x3, [x29, 144]
	movi	v25.4s, 0
	b	L419
L425:
	cmp	w26, 0
	ble	L537
	mov	w3, 0
	mov	x24, 0
	mov	x7, x5
	mov	x27, 0
	mov	x9, x25
	b	L454
	.p2align 2,,3
L486:
	mov	x27, x0
L450:
	add	w3, w3, 16
	add	x7, x7, 32
	add	x9, x9, 64
	cmp	w26, w3
	ble	L538
L454:
	movi	v31.4s, 0
	mov	x0, 0
L449:
	ldr	q30, [x7, x0]
	add	x0, x0, 16
	zip1	v29.8h, v30.8h, v25.8h
	zip2	v30.8h, v30.8h, v25.8h
	uaddw	v31.2d, v31.2d, v29.2s
	uaddw2	v31.2d, v31.2d, v29.4s
	uaddw	v31.2d, v31.2d, v30.2s
	uaddw2	v31.2d, v31.2d, v30.4s
	cmp	x0, 32
	bne	L449
	addp	d31, v31.2d
	fmov	x0, d31
	add	x0, x0, x27
	cmp	x0, x4
	blt	L486
	mov	x2, 0
	b	L453
	.p2align 2,,3
L451:
	add	x2, x2, 1
	cmp	x2, 16
	beq	L450
L453:
	ldrh	w0, [x7, x2, lsl 1]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L451
	ldr	w1, [x9, x2, lsl 2]
	mov	x0, x22
	str	x5, [x29, 104]
	str	w3, [x29, 112]
	str	w6, [x29, 120]
	stp	x7, x9, [x29, 128]
	str	x2, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 104]
	movi	v25.4s, 0
	ldp	x7, x9, [x29, 128]
	ldr	x2, [x29, 144]
	ldr	w3, [x29, 112]
	ldr	w6, [x29, 120]
	b	L452
	.p2align 2,,3
L539:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L451
L452:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L539
	b	L436
L427:
	cmp	w26, 0
	ble	L540
	mov	x9, x5
	mov	x7, 0
	mov	x24, 0
	mov	x27, 0
	b	L439
	.p2align 2,,3
L485:
	mov	x27, x0
L441:
	add	x0, x7, 16
	add	x9, x9, 16
	cmp	w26, w0
	ble	L541
	mov	x7, x0
L439:
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
	blt	L485
	add	x0, x25, w7, uxtw 2
	mov	x3, 0
	str	x0, [x29, 104]
	b	L438
	.p2align 2,,3
L435:
	add	x3, x3, 1
	cmp	x3, 16
	beq	L441
L438:
	ldrb	w0, [x9, x3]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L435
	ldr	x0, [x29, 104]
	str	x5, [x29, 112]
	str	w6, [x29, 120]
	str	x3, [x29, 144]
	ldr	w1, [x0, x3, lsl 2]
	mov	x0, x22
	stp	x9, x7, [x29, 128]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 112]
	ldp	x9, x7, [x29, 128]
	ldr	x3, [x29, 144]
	ldr	w6, [x29, 120]
	b	L437
	.p2align 2,,3
L542:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L435
L437:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L542
	b	L436
L426:
	cmp	w26, 0
	ble	L543
	sub	x0, x5, #64
	mov	w27, 0
	mov	x24, 0
	mov	x9, 64
	mov	x2, 0
	str	x0, [x29, 104]
	.p2align 5,,15
L459:
	ldr	x0, [x29, 104]
	movi	v31.4s, 0
	add	x1, x0, x9
	mov	x0, 0
L461:
	ldr	q30, [x1, x0]
	add	x0, x0, 16
	uaddw	v31.2d, v31.2d, v30.2s
	uaddw2	v31.2d, v31.2d, v30.4s
	cmp	x0, 64
	bne	L461
	addp	d31, v31.2d
	fmov	x0, d31
	add	x0, x0, x2
	cmp	x0, x4
	bge	L544
	mov	x2, x0
L462:
	add	w27, w27, 16
	add	x9, x9, 64
	cmp	w26, w27
	bgt	L459
	cmp	w6, w27
	cset	w0, gt
	b	L466
	.p2align 2,,3
L544:
	sub	x3, x9, #64
	b	L465
	.p2align 2,,3
L463:
	add	x3, x3, 4
	cmp	x3, x9
	beq	L462
L465:
	ldr	w0, [x5, x3]
	add	x2, x2, x0
	cmp	x2, x4
	blt	L463
	ldr	w1, [x25, x3]
	mov	x0, x22
	stp	x5, x9, [x29, 112]
	str	w6, [x29, 128]
	stp	x2, x3, [x29, 136]
	bl	_hdr_value_at_index
	ldr	w6, [x29, 128]
	ldp	x5, x9, [x29, 112]
	ldp	x2, x3, [x29, 136]
	b	L464
	.p2align 2,,3
L545:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x2
	bgt	L463
L464:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L545
	b	L436
L536:
	mov	x0, x20
	bl	_free
	mov	x0, x28
	bl	_free
	mov	x0, x19
	bl	_free
L410:
	ldp	x19, x20, [x29, 16]
LCFI146:
	mov	w0, 12
	ldp	x21, x22, [x29, 32]
LCFI147:
	ldp	x25, x26, [x29, 64]
LCFI148:
	ldp	x27, x28, [x29, 80]
LCFI149:
	b	L403
L481:
LCFI150:
	mov	x0, 0
	add	x19, x29, 672
	add	x28, x29, 416
	add	x20, x29, 160
	lsl	x27, x3, 3
	b	L412
L420:
	str	xzr, [x19]
	b	L424
L537:
	mov	w3, 0
	mov	x24, 0
	mov	x27, 0
	cmp	w6, 0
	cset	w0, gt
L455:
	sxtw	x26, w3
	cbnz	w0, L458
	b	L436
	.p2align 2,,3
L456:
	add	x26, x26, 1
	cmp	w6, w26
	ble	L436
L458:
	ldrh	w0, [x5, x26, lsl 1]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L456
	ldr	w1, [x25, x26, lsl 2]
	mov	x0, x22
	str	x5, [x29, 136]
	str	w6, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 136]
	ldr	w6, [x29, 144]
	b	L457
	.p2align 2,,3
L546:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L456
L457:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L546
	b	L436
L543:
	mov	w27, 0
	mov	x24, 0
	mov	x2, 0
	cmp	w6, 0
	cset	w0, gt
L466:
	sxtw	x26, w27
	cbnz	w0, L469
	b	L436
	.p2align 2,,3
L467:
	add	x26, x26, 1
	cmp	w6, w26
	ble	L436
L469:
	ldr	w0, [x5, x26, lsl 2]
	add	x2, x2, x0
	cmp	x2, x4
	blt	L467
	ldr	w1, [x25, x26, lsl 2]
	mov	x0, x22
	str	x5, [x29, 128]
	str	w6, [x29, 136]
	str	x2, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 128]
	ldr	x2, [x29, 144]
	ldr	w6, [x29, 136]
	b	L468
	.p2align 2,,3
L547:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x2
	bgt	L467
L468:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L547
	b	L436
L540:
	mov	w7, 0
	mov	x24, 0
	mov	x27, 0
	cmp	w6, 0
	cset	w0, gt
L440:
	sxtw	x26, w7
	cbnz	w0, L446
	b	L436
	.p2align 2,,3
L444:
	add	x26, x26, 1
	cmp	w6, w26
	ble	L436
L446:
	ldrb	w0, [x5, x26]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L444
	ldr	w1, [x25, x26, lsl 2]
	mov	x0, x22
	str	x5, [x29, 136]
	str	w6, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 136]
	ldr	w6, [x29, 144]
	b	L445
	.p2align 2,,3
L548:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L444
L445:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L548
	b	L436
L541:
	add	w7, w7, 16
	cmp	w6, w7
	cset	w0, gt
	b	L440
L538:
	cmp	w6, w3
	cset	w0, gt
	b	L455
LFE66:
	.align	2
	.p2align 5,,15
	.globl _hdr_packed_get_memory_size
