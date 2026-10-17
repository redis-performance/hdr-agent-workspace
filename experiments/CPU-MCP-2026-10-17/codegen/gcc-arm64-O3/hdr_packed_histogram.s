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
	cbz	x0, L432
	mov	x2, 4636737291354636288
	scvtf	d29, x0
	fmov	d27, 5.0e-1
	fmov	d28, 1.0e+0
	stp	x29, x30, [sp, -96]!
LCFI116:
	mov	x29, sp
LCFI117:
	fmov	d30, x2
	stp	x19, x20, [sp, 16]
LCFI118:
	ldr	x19, [x1]
	str	x27, [sp, 80]
	str	d15, [sp, 88]
LCFI119:
	fmov	d15, d0
	fcmpe	d0, d30
	fcsel	d31, d0, d30, mi
	fdiv	d31, d31, d30
	fmul	d31, d31, d29
	fadd	d31, d31, d27
	fcmpe	d31, d28
	bge	L414
	ldrb	w2, [x1, 60]
	mov	x0, 1
	ldp	x27, x5, [x1, 8]
	ldr	w4, [x1, 48]
	cmp	w2, 2
	bne	L454
L328:
	negs	w8, w4
	and	w1, w4, 15
	and	w8, w8, 15
	csneg	w8, w1, w8, mi
	sub	w8, w4, w8
	mov	x7, 0
	mov	x2, x5
	mov	x3, 0
	cmp	w8, 0
	ble	L357
	stp	x21, x22, [x29, 32]
LCFI120:
	stp	x23, x24, [x29, 48]
LCFI121:
	stp	x25, x26, [x29, 64]
LCFI122:
	b	L374
	.p2align 2,,3
L429:
	add	x3, x3, x1
L373:
	add	x1, x7, 16
	add	x2, x2, 32
	cmp	w8, w1
	ble	L455
	mov	x7, x1
L374:
	ldrh	w9, [x2]
	sub	x6, x0, x3
	ldrh	w10, [x2, 2]
	ldrh	w11, [x2, 4]
	ldrh	w12, [x2, 6]
	add	x1, x9, x10
	ldrh	w13, [x2, 8]
	add	x1, x1, x11
	ldrh	w14, [x2, 10]
	add	x1, x1, x12
	ldrh	w15, [x2, 12]
	add	x1, x1, x13
	ldrh	w16, [x2, 14]
	add	x1, x1, x14
	ldrh	w17, [x2, 16]
	add	x1, x1, x15
	ldrh	w20, [x2, 18]
	add	x1, x1, x16
	ldrh	w21, [x2, 20]
	add	x1, x1, x17
	ldrh	w22, [x2, 22]
	add	x1, x1, x20
	ldrh	w23, [x2, 24]
	add	x1, x1, x21
	ldrh	w24, [x2, 26]
	add	x1, x1, x22
	ldrh	w25, [x2, 28]
	add	x1, x1, x23
	ldrh	w26, [x2, 30]
	add	x1, x1, x24
	add	x1, x1, x25
	add	x1, x1, x26
	cmp	x6, x1
	bgt	L429
	add	x3, x3, x9
	cmp	x0, x3
	ble	L358
	add	x3, x3, x10
	cmp	x0, x3
	ble	L453
	add	x3, x3, x11
	cmp	x0, x3
	ble	L452
	add	x3, x3, x12
	cmp	x0, x3
	ble	L451
	add	x3, x3, x13
	cmp	x0, x3
	ble	L450
	add	x3, x3, x14
	cmp	x0, x3
	ble	L449
	add	x3, x3, x15
	cmp	x0, x3
	ble	L448
	add	x3, x3, x16
	cmp	x0, x3
	ble	L447
	add	x3, x3, x17
	cmp	x0, x3
	ble	L446
	add	x3, x3, x20
	cmp	x0, x3
	ble	L445
	add	x3, x3, x21
	cmp	x0, x3
	ble	L444
	add	x3, x3, x22
	cmp	x0, x3
	ble	L443
	add	x3, x3, x23
	cmp	x0, x3
	ble	L442
	add	x3, x3, x24
	cmp	x0, x3
	ble	L441
	add	x3, x3, x25
	cmp	x0, x3
	ble	L440
	add	x3, x3, x26
	cmp	x0, x3
	bgt	L373
	add	x7, x7, 15
	.p2align 5,,15
L358:
	ldr	w1, [x27, w7, uxtw 2]
L437:
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
	fcmp	d15, #0.0
	ldp	x21, x22, [x29, 32]
LCFI123:
	mov	x1, x20
	mov	x0, x19
	ldp	x23, x24, [x29, 48]
LCFI124:
	ldp	x25, x26, [x29, 64]
LCFI125:
	bne	L408
L458:
	ldp	x19, x20, [sp, 16]
	ldr	x27, [sp, 80]
	ldr	d15, [sp, 88]
	ldp	x29, x30, [sp], 96
LCFI126:
	b	_hdr_lowest_equivalent_value
	.p2align 2,,3
L414:
LCFI127:
	fcmpe	d29, d31
	bls	L326
	fcvtzs	x0, d31
L326:
	ldrb	w2, [x1, 60]
	ldp	x27, x5, [x1, 8]
	ldr	w4, [x1, 48]
	cmp	w2, 2
	beq	L328
L454:
	cmp	w2, 4
	beq	L329
	cmp	w2, 1
	bne	L330
	negs	w8, w4
	and	w1, w4, 15
	and	w8, w8, 15
	csneg	w8, w1, w8, mi
	sub	w8, w4, w8
	mov	x7, 0
	mov	x2, x5
	mov	x3, 0
	cmp	w8, 0
	ble	L332
	stp	x21, x22, [x29, 32]
LCFI128:
	stp	x23, x24, [x29, 48]
LCFI129:
	stp	x25, x26, [x29, 64]
LCFI130:
	b	L350
	.p2align 2,,3
L428:
	add	x3, x3, x1
L348:
	add	x1, x7, 16
	add	x2, x2, 16
	cmp	w8, w1
	ble	L456
	mov	x7, x1
L350:
	ldrb	w9, [x2]
	sub	x6, x0, x3
	ldrb	w10, [x2, 1]
	ldrb	w11, [x2, 2]
	ldrb	w12, [x2, 3]
	add	x1, x9, x10
	ldrb	w13, [x2, 4]
	add	x1, x1, x11
	ldrb	w14, [x2, 5]
	add	x1, x1, x12
	ldrb	w15, [x2, 6]
	add	x1, x1, x13
	ldrb	w16, [x2, 7]
	add	x1, x1, x14
	ldrb	w17, [x2, 8]
	add	x1, x1, x15
	ldrb	w20, [x2, 9]
	add	x1, x1, x16
	ldrb	w21, [x2, 10]
	add	x1, x1, x17
	ldrb	w22, [x2, 11]
	add	x1, x1, x20
	ldrb	w23, [x2, 12]
	add	x1, x1, x21
	ldrb	w24, [x2, 13]
	add	x1, x1, x22
	ldrb	w25, [x2, 14]
	add	x1, x1, x23
	ldrb	w26, [x2, 15]
	add	x1, x1, x24
	add	x1, x1, x25
	add	x1, x1, x26
	cmp	x6, x1
	bgt	L428
	add	x3, x3, x9
	cmp	x0, x3
	ble	L358
	add	x3, x3, x10
	cmp	x0, x3
	ble	L453
	add	x3, x3, x11
	cmp	x0, x3
	ble	L452
	add	x3, x3, x12
	cmp	x0, x3
	ble	L451
	add	x3, x3, x13
	cmp	x0, x3
	ble	L450
	add	x3, x3, x14
	cmp	x0, x3
	ble	L449
	add	x3, x3, x15
	cmp	x0, x3
	ble	L448
	add	x3, x3, x16
	cmp	x0, x3
	ble	L447
	add	x3, x3, x17
	cmp	x0, x3
	ble	L446
	add	x3, x3, x20
	cmp	x0, x3
	ble	L445
	add	x3, x3, x21
	cmp	x0, x3
	ble	L444
	add	x3, x3, x22
	cmp	x0, x3
	ble	L443
	add	x3, x3, x23
	cmp	x0, x3
	ble	L442
	add	x3, x3, x24
	cmp	x0, x3
	ble	L441
	add	x3, x3, x25
	cmp	x0, x3
	ble	L440
	add	x3, x3, x26
	cmp	x0, x3
	bgt	L348
	add	x7, x7, 15
	b	L358
	.p2align 2,,3
L432:
LCFI131:
	ret
	.p2align 2,,3
L330:
LCFI132:
	cmp	w4, 0
	ble	L412
	mov	x2, 0
	mov	x1, 0
	sxtw	x4, w4
	mov	x7, 9223372036854775807
	b	L407
	.p2align 2,,3
L457:
	cmp	x0, x1
	ble	L405
	add	x2, x2, 1
	cmp	x2, x4
	beq	L412
L407:
	ldr	x3, [x5, x2, lsl 3]
	sub	x6, x7, x1
	add	x1, x1, x3
	cmp	x3, x6
	ble	L457
L405:
	ldr	w1, [x27, w2, uxtw 2]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
L349:
	fcmp	d15, #0.0
	mov	x1, x20
	mov	x0, x19
	beq	L458
L408:
	bl	_hdr_lowest_equivalent_value
	mov	x2, x0
	mov	x1, x20
	mov	x0, x19
	mov	x19, x2
	bl	_hdr_size_of_equivalent_value_range
	mov	x1, 9223372036854775807
	ldr	x27, [sp, 80]
	sub	x2, x1, x0
	add	x0, x19, x0
	ldr	d15, [sp, 88]
	cmp	x19, x2
	sub	x0, x0, #1
	ldp	x19, x20, [sp, 16]
	csel	x0, x0, x1, le
	ldp	x29, x30, [sp], 96
LCFI133:
	ret
	.p2align 2,,3
L329:
LCFI134:
	negs	w9, w4
	and	w1, w4, 15
	and	w9, w9, 15
	csneg	w9, w1, w9, mi
	sub	w9, w4, w9
	mov	x3, 0
	mov	w7, 0
	cmp	w9, 0
	ble	L381
	mov	x3, 0
	mov	w7, 0
	stp	x21, x22, [x29, 32]
LCFI135:
	mov	x2, x5
	mov	x8, 60
	stp	x23, x24, [x29, 48]
LCFI136:
	stp	x25, x26, [x29, 64]
LCFI137:
	b	L399
	.p2align 2,,3
L430:
	add	x3, x3, x1
L398:
	add	w7, w7, 16
	add	x2, x2, 64
	add	x8, x8, 64
	cmp	w9, w7
	ble	L459
L399:
	ldp	w10, w11, [x2]
	sub	x6, x0, x3
	ldp	w12, w13, [x2, 8]
	ldp	w14, w15, [x2, 16]
	add	x1, x10, x11
	ldp	w16, w17, [x2, 24]
	add	x1, x1, x12
	ldp	w30, w20, [x2, 32]
	add	x1, x1, x13
	add	x1, x1, x14
	ldp	w21, w22, [x2, 40]
	add	x1, x1, x15
	add	x1, x1, x16
	ldp	w23, w24, [x2, 48]
	add	x1, x1, x17
	add	x1, x1, x30
	ldp	w25, w26, [x2, 56]
	add	x1, x1, x20
	add	x1, x1, x21
	add	x1, x1, x22
	add	x1, x1, x23
	add	x1, x1, x24
	add	x1, x1, x25
	add	x1, x1, x26
	cmp	x6, x1
	bgt	L430
	add	x3, x3, x10
	cmp	x0, x3
	ble	L460
	add	x3, x3, x11
	cmp	x0, x3
	ble	L461
	add	x3, x3, x12
	cmp	x0, x3
	ble	L462
	add	x3, x3, x13
	cmp	x0, x3
	ble	L463
	add	x3, x3, x14
	cmp	x0, x3
	ble	L464
	add	x3, x3, x15
	cmp	x0, x3
	ble	L465
	add	x3, x3, x16
	cmp	x0, x3
	ble	L466
	add	x3, x3, x17
	cmp	x0, x3
	ble	L467
	add	x3, x3, x30
	cmp	x0, x3
	ble	L468
	add	x3, x3, x20
	cmp	x0, x3
	ble	L469
	add	x3, x3, x21
	cmp	x0, x3
	ble	L470
	add	x3, x3, x22
	cmp	x0, x3
	ble	L471
	add	x3, x3, x23
	cmp	x0, x3
	ble	L472
	add	x3, x3, x24
	cmp	x0, x3
	ble	L473
	add	x3, x3, x25
	cmp	x0, x3
	ble	L474
	add	x3, x3, x26
	cmp	x0, x3
	bgt	L398
	ldr	w1, [x27, x8]
	b	L437
	.p2align 2,,3
L456:
	ldp	x21, x22, [x29, 32]
LCFI138:
	add	w7, w7, 16
	ldp	x23, x24, [x29, 48]
LCFI139:
	ldp	x25, x26, [x29, 64]
LCFI140:
L332:
	sxtw	x1, w7
	cmp	w4, w7
	bgt	L355
L412:
	mov	x20, 0
	b	L349
	.p2align 2,,3
L354:
	add	x1, x1, 1
	cmp	w4, w1
	ble	L412
L355:
	ldrb	w2, [x5, x1]
	add	x3, x3, x2
	cmp	x0, x3
	bgt	L354
L438:
	ldr	w1, [x27, w1, uxtw 2]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
	b	L349
L455:
LCFI141:
	ldp	x21, x22, [x29, 32]
LCFI142:
	add	w7, w7, 16
	ldp	x23, x24, [x29, 48]
LCFI143:
	ldp	x25, x26, [x29, 64]
LCFI144:
L357:
	sxtw	x1, w7
	cmp	w4, w7
	bgt	L379
	b	L412
	.p2align 2,,3
L378:
	add	x1, x1, 1
	cmp	w4, w1
	ble	L412
L379:
	ldrh	w2, [x5, x1, lsl 1]
	add	x3, x3, x2
	cmp	x0, x3
	bgt	L378
	b	L438
L459:
LCFI145:
	ldp	x21, x22, [x29, 32]
LCFI146:
	ldp	x23, x24, [x29, 48]
LCFI147:
	ldp	x25, x26, [x29, 64]
LCFI148:
L381:
	cmp	w4, w7
	ble	L412
	sub	w4, w4, w7
	ubfiz	x2, x7, 2, 32
	add	x1, x4, w7, sxtw
	lsl	x1, x1, 2
	b	L404
	.p2align 2,,3
L403:
	add	x2, x2, 4
	cmp	x2, x1
	beq	L412
L404:
	ldr	w4, [x5, x2]
	add	x3, x3, x4
	cmp	x0, x3
	bgt	L403
	ldr	w1, [x27, x2]
	mov	x0, x19
	bl	_hdr_value_at_index
	mov	x20, x0
	b	L349
L453:
LCFI149:
	add	x7, x7, 1
	b	L358
L452:
	add	x7, x7, 2
	b	L358
L451:
	add	x7, x7, 3
	b	L358
L450:
	add	x7, x7, 4
	b	L358
L449:
	add	x7, x7, 5
	b	L358
L447:
	add	x7, x7, 7
	b	L358
L448:
	add	x7, x7, 6
	b	L358
L446:
	add	x7, x7, 8
	b	L358
L445:
	add	x7, x7, 9
	b	L358
L444:
	add	x7, x7, 10
	b	L358
L443:
	add	x7, x7, 11
	b	L358
L460:
	sub	x8, x8, #60
	ldr	w1, [x27, x8]
	b	L437
L442:
	add	x7, x7, 12
	b	L358
L440:
	add	x7, x7, 14
	b	L358
L441:
	add	x7, x7, 13
	b	L358
L462:
	sub	x8, x8, #52
	ldr	w1, [x27, x8]
	b	L437
L461:
	sub	x8, x8, #56
	ldr	w1, [x27, x8]
	b	L437
L465:
	sub	x8, x8, #40
	ldr	w1, [x27, x8]
	b	L437
L464:
	sub	x8, x8, #44
	ldr	w1, [x27, x8]
	b	L437
L463:
	sub	x8, x8, #48
	ldr	w1, [x27, x8]
	b	L437
L466:
	sub	x8, x8, #36
	ldr	w1, [x27, x8]
	b	L437
L468:
	sub	x8, x8, #28
	ldr	w1, [x27, x8]
	b	L437
L467:
	sub	x8, x8, #32
	ldr	w1, [x27, x8]
	b	L437
L470:
	sub	x8, x8, #20
	ldr	w1, [x27, x8]
	b	L437
L469:
	sub	x8, x8, #24
	ldr	w1, [x27, x8]
	b	L437
L471:
	sub	x8, x8, #16
	ldr	w1, [x27, x8]
	b	L437
L472:
	sub	x8, x8, #12
	ldr	w1, [x27, x8]
	b	L437
L474:
	sub	x8, x8, #4
	ldr	w1, [x27, x8]
	b	L437
L473:
	sub	x8, x8, #8
	ldr	w1, [x27, x8]
	b	L437
LFE65:
	.align	2
	.p2align 5,,15
	.globl _hdr_packed_value_at_percentiles
_hdr_packed_value_at_percentiles:
LFB66:
	sub	sp, sp, #928
LCFI150:
	cmp	x1, 0
	ccmp	x2, 0, 4, ne
	stp	x29, x30, [sp]
LCFI151:
	mov	x29, sp
LCFI152:
	stp	x23, x24, [sp, 48]
LCFI153:
	mov	x23, x1
	str	x2, [x29, 152]
	beq	L555
	stp	x21, x22, [x29, 32]
LCFI154:
	mov	x21, x3
	cbz	x3, L478
	mov	x24, x0
	stp	x25, x26, [x29, 64]
LCFI155:
	ldr	x26, [x0, 24]
	cbz	x26, L604
	stp	x19, x20, [x29, 16]
LCFI156:
	stp	x27, x28, [x29, 80]
LCFI157:
	ldr	x22, [x0]
	cmp	x3, 32
	bhi	L605
	sub	x0, x3, #1
	scvtf	d22, x26
	cmp	x0, 1
	bls	L556
	add	x19, x29, 672
	add	x28, x29, 416
	add	x20, x29, 160
L554:
	dup	v23.2d, x26
	adrp	x0, lC1@PAGE
	lsr	x25, x21, 1
	mov	x1, 0
	ldr	q30, [x0, #lC1@PAGEOFF]
	dup	v26.2d, v22.d[0]
	adrp	x0, lC2@PAGE
	fmov	v24.2d, 5.0e-1
	fmov	v25.2d, 1.0e+0
	ldr	q27, [x0, #lC2@PAGEOFF]
	lsl	x0, x25, 4
	.p2align 5,,15
L485:
	ldr	q29, [x23, x1]
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
	str	q31, [x20, x1]
	add	x1, x1, 16
	cmp	x1, x0
	bne	L485
	and	x2, x21, -2
	and	x27, x21, 1
	tbz	x21, 0, L606
L484:
	mov	x0, 4636737291354636288
	lsl	x1, x2, 3
	fmov	d28, 5.0e-1
	fmov	d29, 1.0e+0
	add	x3, x20, x1
	fmov	d30, x0
	ldr	d31, [x23, x1]
	fcmpe	d31, d30
	fcsel	d31, d31, d30, mi
	fdiv	d31, d31, d30
	fmul	d31, d31, d22
	fadd	d31, d31, d28
	fcmpe	d31, d29
	bge	L567
	mov	x0, 1
L487:
	add	x2, x2, 1
	str	x0, [x3]
	cmp	x21, x2
	bls	L489
	mov	x0, 4636737291354636288
	add	x1, x1, 8
	fmov	d28, 5.0e-1
	fmov	d29, 1.0e+0
	add	x3, x20, x1
	fmov	d30, x0
	ldr	d31, [x23, x1]
	fcmpe	d31, d30
	fcsel	d31, d31, d30, mi
	fdiv	d31, d31, d30
	fmul	d31, d31, d22
	fadd	d31, d31, d28
	fcmpe	d31, d29
	bge	L490
	mov	x26, 1
L492:
	lsl	x2, x21, 3
	mov	w1, 0
	str	x26, [x3]
	mov	x0, x28
	lsr	x25, x21, 1
	and	x27, x21, 1
	bl	_memset
L493:
	adrp	x2, lC4@PAGE
	adrp	x0, lC3@PAGE
	mov	x1, x19
	ldr	q30, [x2, #lC4@PAGEOFF]
	ldr	q31, [x0, #lC3@PAGEOFF]
	add	x0, x19, x25, lsl 4
	.p2align 5,,15
L495:
	mov	v29.16b, v31.16b
	add	v31.2d, v31.2d, v30.2d
	str	q29, [x1], 16
	cmp	x1, x0
	bne	L495
	cbz	x27, L496
	and	x0, x21, -2
	str	x0, [x19, x0, lsl 3]
L496:
	add	x1, x19, 8
	mov	x3, 1
	.p2align 5,,15
L506:
	ldr	x9, [x1]
	mov	x4, x1
	ldr	x2, [x20, x9, lsl 3]
	.p2align 5,,15
L503:
	mov	x6, x4
	ldr	x5, [x4, -8]
	ldr	x7, [x20, x5, lsl 3]
	cmp	x7, x2
	ble	L504
	str	x5, [x4]
	sub	x4, x6, #8
	cmp	x4, x19
	bne	L503
	mov	x6, x19
L504:
	add	x3, x3, 1
	str	x9, [x6]
	add	x1, x1, 8
	cmp	x21, x3
	bne	L506
L498:
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
	beq	L499
	cmp	w0, 4
	beq	L500
	cmp	w0, 1
	beq	L501
	cmp	w6, 0
	ble	L510
	mov	x24, 0
	mov	x26, 0
	add	x6, x5, w6, uxtw 3
	mov	x2, 9223372036854775807
	mov	x27, x5
	b	L548
	.p2align 2,,3
L546:
	add	x27, x27, 8
	add	x25, x25, 4
	cmp	x6, x27
	beq	L510
L548:
	ldr	x0, [x27]
	sub	x1, x2, x26
	cmp	x1, x0
	blt	L565
	add	x26, x26, x0
	cmp	x26, x4
	blt	L546
L545:
	ldr	w1, [x25]
	mov	x0, x22
	str	x6, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x6, [x29, 144]
	mov	x2, 9223372036854775807
	b	L547
	.p2align 2,,3
L607:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x26
	bgt	L546
L547:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L607
	.p2align 5,,15
L510:
	mov	x25, 0
	mov	x24, 9223372036854775807
	b	L515
	.p2align 2,,3
L609:
	bl	_hdr_lowest_equivalent_value
	ldr	x1, [x29, 152]
	str	x0, [x1, x25, lsl 3]
	add	x25, x25, 1
	cmp	x21, x25
	beq	L608
L515:
	ldr	d28, [x23, x25, lsl 3]
	mov	x0, x22
	ldr	x26, [x28, x25, lsl 3]
	fcmp	d28, #0.0
	mov	x1, x26
	beq	L609
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
	bne	L515
L608:
	cmp	x21, 32
	bhi	L610
	ldp	x19, x20, [x29, 16]
LCFI158:
	ldp	x25, x26, [x29, 64]
LCFI159:
	ldp	x27, x28, [x29, 80]
LCFI160:
L478:
	mov	w0, 0
	ldp	x21, x22, [x29, 32]
LCFI161:
L475:
	ldp	x29, x30, [sp]
	ldp	x23, x24, [sp, 48]
	add	sp, sp, 928
LCFI162:
	ret
	.p2align 2,,3
L555:
LCFI163:
	ldp	x29, x30, [sp]
	mov	w0, 22
	ldp	x23, x24, [sp, 48]
	add	sp, sp, 928
LCFI164:
	ret
L604:
LCFI165:
	mov	x1, x2
	lsl	x2, x3, 3
	mov	x0, x1
	mov	w1, 0
	bl	_memset
	ldp	x25, x26, [x29, 64]
LCFI166:
	b	L478
L605:
LCFI167:
	mov	x0, 2305843009213693951
	cmp	x3, x0
	bhi	L482
	lsl	x19, x3, 3
	mov	x0, x19
	bl	_malloc
	mov	x20, x0
	mov	x0, x19
	bl	_malloc
	mov	x28, x0
	mov	x0, x19
	bl	_malloc
	cmp	x20, 0
	mov	x19, x0
	ccmp	x28, 0, 4, ne
	ccmp	x0, 0, 4, ne
	beq	L611
	scvtf	d22, x26
	b	L554
L490:
	fcmpe	d31, d22
	bge	L492
	fcvtzs	x26, d31
	b	L492
L567:
	fcmpe	d31, d22
	mov	x0, x26
	bge	L487
	fcvtzs	x0, d31
	b	L487
L565:
	mov	x26, 9223372036854775807
	b	L545
L489:
	lsl	x2, x21, 3
	mov	w1, 0
	mov	x0, x28
	bl	_memset
	cmp	x21, 1
	beq	L494
	lsr	x25, x21, 1
	and	x27, x21, 1
	b	L493
L610:
	mov	x0, x20
	bl	_free
	mov	x0, x28
	bl	_free
	mov	x0, x19
	bl	_free
	ldp	x19, x20, [x29, 16]
LCFI168:
	ldp	x25, x26, [x29, 64]
LCFI169:
	ldp	x27, x28, [x29, 80]
LCFI170:
	b	L478
L606:
LCFI171:
	lsl	x2, x2, 3
	mov	w1, 0
	mov	x0, x28
	bl	_memset
	b	L493
L500:
	cmp	w26, 0
	ble	L612
	mov	w7, 0
	mov	x24, 0
	mov	x3, x5
	mov	x27, 0
	mov	x9, 64
	b	L538
	.p2align 2,,3
L564:
	mov	x27, x0
L540:
	add	w7, w7, 16
	add	x3, x3, 64
	add	x9, x9, 64
	cmp	w26, w7
	ble	L613
L538:
	ldp	w2, w10, [x3]
	ldp	w1, w0, [x3, 8]
	add	x2, x2, x10
	add	x1, x1, x2
	ldp	w10, w2, [x3, 16]
	add	x0, x0, x1
	ldr	w1, [x3, 24]
	add	x10, x10, x0
	add	x2, x2, x10
	ldp	w0, w10, [x3, 28]
	add	x1, x1, x2
	ldr	w2, [x3, 36]
	add	x0, x0, x1
	add	x10, x10, x0
	ldp	w1, w0, [x3, 40]
	add	x2, x2, x10
	ldr	w10, [x3, 48]
	add	x1, x1, x2
	add	x0, x0, x1
	ldp	w2, w1, [x3, 52]
	add	x10, x10, x0
	ldr	w0, [x3, 60]
	add	x2, x2, x10
	add	x1, x1, x2
	add	x0, x0, x1
	add	x0, x0, x27
	cmp	x0, x4
	blt	L564
	sub	x2, x9, #64
	b	L537
	.p2align 2,,3
L535:
	add	x2, x2, 4
	cmp	x2, x9
	beq	L540
L537:
	ldr	w0, [x5, x2]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L535
	ldr	w1, [x25, x2]
	mov	x0, x22
	stp	x5, x9, [x29, 104]
	str	x3, [x29, 120]
	str	w7, [x29, 128]
	str	w6, [x29, 136]
	str	x2, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x3, [x29, 120]
	ldp	x5, x9, [x29, 104]
	ldr	x2, [x29, 144]
	ldr	w7, [x29, 128]
	ldr	w6, [x29, 136]
	b	L536
	.p2align 2,,3
L614:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L535
L536:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L614
	b	L510
L499:
	cmp	w26, 0
	ble	L615
	mov	x7, x5
	mov	x9, 0
	mov	x24, 0
	mov	x27, 0
	b	L526
	.p2align 2,,3
L563:
	mov	x27, x0
L528:
	add	x0, x9, 16
	add	x7, x7, 32
	cmp	w26, w0
	ble	L616
	mov	x9, x0
L526:
	ldrh	w10, [x7, 2]
	ldrh	w3, [x7]
	ldrh	w1, [x7, 4]
	ldrh	w0, [x7, 6]
	add	x3, x3, x10
	ldrh	w10, [x7, 8]
	add	x1, x1, x3
	ldrh	w3, [x7, 10]
	add	x0, x0, x1
	ldrh	w1, [x7, 12]
	add	x10, x10, x0
	ldrh	w0, [x7, 14]
	add	x3, x3, x10
	ldrh	w10, [x7, 16]
	add	x1, x1, x3
	ldrh	w3, [x7, 18]
	add	x0, x0, x1
	ldrh	w1, [x7, 20]
	add	x10, x10, x0
	ldrh	w0, [x7, 22]
	add	x3, x3, x10
	ldrh	w10, [x7, 24]
	add	x1, x1, x3
	ldrh	w3, [x7, 26]
	add	x0, x0, x1
	ldrh	w1, [x7, 28]
	add	x10, x10, x0
	ldrh	w0, [x7, 30]
	add	x3, x3, x10
	add	x1, x1, x3
	add	x0, x0, x1
	add	x0, x0, x27
	cmp	x0, x4
	blt	L563
	add	x0, x25, w9, uxtw 2
	mov	x3, 0
	str	x0, [x29, 104]
	b	L525
	.p2align 2,,3
L523:
	add	x3, x3, 1
	cmp	x3, 16
	beq	L528
L525:
	ldrh	w0, [x7, x3, lsl 1]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L523
	ldr	x0, [x29, 104]
	str	x5, [x29, 112]
	str	w6, [x29, 120]
	str	x3, [x29, 144]
	ldr	w1, [x0, x3, lsl 2]
	mov	x0, x22
	stp	x7, x9, [x29, 128]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 112]
	ldp	x7, x9, [x29, 128]
	ldr	x3, [x29, 144]
	ldr	w6, [x29, 120]
	b	L524
	.p2align 2,,3
L617:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L523
L524:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L617
	b	L510
L501:
	cmp	w26, 0
	ble	L618
	mov	x7, x5
	mov	x9, 0
	mov	x24, 0
	mov	x27, 0
	b	L513
	.p2align 2,,3
L561:
	mov	x27, x0
L516:
	add	x0, x9, 16
	add	x7, x7, 16
	cmp	w26, w0
	ble	L619
	mov	x9, x0
L513:
	ldrb	w10, [x7, 1]
	ldrb	w3, [x7]
	ldrb	w1, [x7, 2]
	ldrb	w0, [x7, 3]
	add	x3, x3, x10
	ldrb	w10, [x7, 4]
	add	x1, x1, x3
	ldrb	w3, [x7, 5]
	add	x0, x0, x1
	ldrb	w1, [x7, 6]
	add	x10, x10, x0
	ldrb	w0, [x7, 7]
	add	x3, x3, x10
	ldrb	w10, [x7, 8]
	add	x1, x1, x3
	ldrb	w3, [x7, 9]
	add	x0, x0, x1
	ldrb	w1, [x7, 10]
	add	x10, x10, x0
	ldrb	w0, [x7, 11]
	add	x3, x3, x10
	ldrb	w10, [x7, 12]
	add	x1, x1, x3
	ldrb	w3, [x7, 13]
	add	x0, x0, x1
	ldrb	w1, [x7, 14]
	add	x10, x10, x0
	ldrb	w0, [x7, 15]
	add	x3, x3, x10
	add	x1, x1, x3
	add	x0, x0, x1
	add	x0, x0, x27
	cmp	x0, x4
	blt	L561
	add	x0, x25, w9, uxtw 2
	mov	x3, 0
	str	x0, [x29, 104]
	b	L512
	.p2align 2,,3
L509:
	add	x3, x3, 1
	cmp	x3, 16
	beq	L516
L512:
	ldrb	w0, [x7, x3]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L509
	ldr	x0, [x29, 104]
	str	x5, [x29, 128]
	str	w6, [x29, 136]
	str	x3, [x29, 144]
	ldr	w1, [x0, x3, lsl 2]
	mov	x0, x22
	stp	x9, x7, [x29, 112]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 128]
	ldp	x9, x7, [x29, 112]
	ldr	x3, [x29, 144]
	ldr	w6, [x29, 136]
	b	L511
	.p2align 2,,3
L620:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L509
L511:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L620
	b	L510
L611:
	mov	x0, x20
	bl	_free
	mov	x0, x28
	bl	_free
	mov	x0, x19
	bl	_free
L482:
	ldp	x19, x20, [x29, 16]
LCFI172:
	mov	w0, 12
	ldp	x21, x22, [x29, 32]
LCFI173:
	ldp	x25, x26, [x29, 64]
LCFI174:
	ldp	x27, x28, [x29, 80]
LCFI175:
	b	L475
L556:
LCFI176:
	mov	x2, 0
	add	x19, x29, 672
	add	x28, x29, 416
	add	x20, x29, 160
	b	L484
L494:
	str	xzr, [x19]
	b	L498
L612:
	mov	w7, 0
	mov	x24, 0
	mov	x27, 0
	cmp	w6, 0
	cset	w0, gt
L539:
	sxtw	x26, w7
	cbnz	w0, L544
	b	L510
	.p2align 2,,3
L542:
	add	x26, x26, 1
	cmp	w6, w26
	ble	L510
L544:
	ldr	w0, [x5, x26, lsl 2]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L542
	ldr	w1, [x25, x26, lsl 2]
	mov	x0, x22
	str	x5, [x29, 136]
	str	w6, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 136]
	ldr	w6, [x29, 144]
	b	L543
	.p2align 2,,3
L621:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L542
L543:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L621
	b	L510
L615:
	mov	w9, 0
	mov	x24, 0
	mov	x27, 0
	cmp	w6, 0
	cset	w0, gt
L527:
	sxtw	x26, w9
	cbnz	w0, L532
	b	L510
	.p2align 2,,3
L530:
	add	x26, x26, 1
	cmp	w6, w26
	ble	L510
L532:
	ldrh	w0, [x5, x26, lsl 1]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L530
	ldr	w1, [x25, x26, lsl 2]
	mov	x0, x22
	str	x5, [x29, 136]
	str	w6, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 136]
	ldr	w6, [x29, 144]
	b	L531
	.p2align 2,,3
L622:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L530
L531:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L622
	b	L510
L618:
	mov	w9, 0
	mov	x24, 0
	mov	x27, 0
	cmp	w6, 0
	cset	w0, gt
L514:
	sxtw	x26, w9
	cbnz	w0, L520
	b	L510
	.p2align 2,,3
L518:
	add	x26, x26, 1
	cmp	w6, w26
	ble	L510
L520:
	ldrb	w0, [x5, x26]
	add	x27, x27, x0
	cmp	x27, x4
	blt	L518
	ldr	w1, [x25, x26, lsl 2]
	mov	x0, x22
	str	x5, [x29, 136]
	str	w6, [x29, 144]
	bl	_hdr_value_at_index
	ldr	x5, [x29, 136]
	ldr	w6, [x29, 144]
	b	L519
	.p2align 2,,3
L623:
	ldr	x1, [x19, x24, lsl 3]
	ldr	x4, [x20, x1, lsl 3]
	cmp	x4, x27
	bgt	L518
L519:
	ldr	x1, [x19, x24, lsl 3]
	add	x24, x24, 1
	str	x0, [x28, x1, lsl 3]
	cmp	x21, x24
	bhi	L623
	b	L510
L613:
	cmp	w6, w7
	cset	w0, gt
	b	L539
L616:
	add	w9, w9, 16
	cmp	w6, w9
	cset	w0, gt
	b	L527
L619:
	add	w9, w9, 16
	cmp	w6, w9
	cset	w0, gt
	b	L514
LFE66:
	.align	2
	.p2align 5,,15
	.globl _hdr_packed_get_memory_size
