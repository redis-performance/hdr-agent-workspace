_packed_count_at_percentile.isra.0:
LFB71:
	adrp	x1, lC0@PAGE
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
	bge	L31
	mov	x0, 1
	b	L28
L31:
	fcmpe	d29, d31
	bls	L28
	fcvtzs	x0, d31
L28:
	ret
LFE71:
	.align	2
_hdr_packed_record_values:
LFB53:
	tbz	x1, #63, L73
	mov	w0, 0
	ret
L75:
LCFI31:
	mov	w0, 0
L74:
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	x25, x26, [sp, 64]
	ldp	x29, x30, [sp], 80
LCFI32:
	ret
L73:
	stp	x29, x30, [sp, -80]!
LCFI33:
	mov	x29, sp
LCFI34:
	stp	x19, x20, [sp, 16]
LCFI35:
	mov	x19, x0
	stp	x21, x22, [sp, 32]
LCFI36:
	mov	x21, x1
	stp	x23, x24, [sp, 48]
	stp	x25, x26, [sp, 64]
LCFI37:
	ldr	x20, [x0]
	ldr	x0, [x20, 8]
	cmp	x0, x1
	blt	L75
	mov	x22, x2
	tbnz	x2, #63, L75
	mov	x0, x20
	bl	_counts_index_for
	mov	w24, w0
	ldr	w0, [x20, 80]
	cmp	w0, w24
	bls	L75
	ldr	x1, [x19, 24]
	mov	x0, 9223372036854775807
	sub	x0, x0, x1
	cmp	x0, x22
	blt	L75
	cbz	x22, L76
	ldr	w2, [x19, 48]
	mov	w20, 0
	mov	w1, w2
L78:
	cmp	w1, w20
	bgt	L79
	cmp	w2, w20
	ble	L80
	ldr	x0, [x19, 8]
	sxtw	x23, w20
	ldr	w0, [x0, w20, sxtw 2]
	cmp	w24, w0
	bne	L80
	mov	w1, w20
	mov	x0, x19
	bl	_slot_get
	add	x20, x22, x0
	mov	x0, x19
	mov	x1, x20
	bl	_widen_to_fit
	tbz	x0, 0, L75
	ldr	x0, [x19, 16]
	mov	x2, x20
	ldrb	w3, [x19, 60]
	ldrb	w1, [x19, 60]
	madd	x0, x3, x23, x0
L112:
	bl	_store_w
L76:
	ldp	x0, x1, [x19, 24]
	add	x0, x0, x22
	str	x0, [x19, 24]
	cmp	x1, x21
	ble	L86
	cbz	x21, L86
	str	x21, [x19, 32]
L86:
	ldr	x0, [x19, 40]
	cmp	x0, x21
	blt	L87
L88:
	mov	w0, 1
	b	L74
L79:
	ldr	x3, [x19, 8]
	sub	w0, w1, w20
	add	w0, w20, w0, lsr 1
	ldr	w3, [x3, w0, sxtw 2]
	cmp	w24, w3
	ble	L89
	add	w20, w0, 1
	b	L78
L89:
	mov	w1, w0
	b	L78
L80:
	ldp	w0, w1, [x19, 52]
	cmp	w2, w0
	bge	L81
	cmp	w2, w1
	blt	L82
L81:
	cmp	w1, w0
	mov	w2, 1073741823
	csel	w1, w1, w0, le
	cmp	w1, w2
	bgt	L75
	cmp	w1, 0
	lsl	w23, w1, 1
	mov	w1, 4
	csel	w23, w23, w1, ne
	cmp	w0, w23
	bge	L84
	ldr	x0, [x19, 8]
	sbfiz	x1, x23, 2, 32
	bl	_realloc
	cbz	x0, L75
	str	x0, [x19, 8]
	str	w23, [x19, 52]
L84:
	ldr	w0, [x19, 56]
	cmp	w23, w0
	ble	L82
	ldrb	w1, [x19, 60]
	sxtw	x0, w23
	mul	x1, x1, x0
	ldr	x0, [x19, 16]
	bl	_realloc
	cbz	x0, L75
	str	x0, [x19, 16]
	str	w23, [x19, 56]
L82:
	mov	x1, x22
	mov	x0, x19
	bl	_widen_to_fit
	tbz	x0, 0, L75
	ldr	w2, [x19, 48]
	sxtw	x25, w20
	add	x23, x25, 1
	ldr	x3, [x19, 8]
	lsl	x0, x23, 2
	sub	x26, x0, #4
	sub	w2, w2, w20
	sbfiz	x2, x2, 2, 32
	add	x1, x3, x26
	add	x0, x3, x0
	bl	_memmove
	ldrb	w3, [x19, 60]
	ldr	w2, [x19, 48]
	ldr	x0, [x19, 16]
	mul	x23, x23, x3
	sub	w2, w2, w20
	sxtw	x2, w2
	sub	x1, x23, x3
	add	x1, x0, x1
	add	x0, x0, x23
	mul	x2, x2, x3
	bl	_memmove
	ldr	x0, [x19, 8]
	mov	x2, x22
	str	w24, [x0, x26]
	ldr	w0, [x19, 48]
	ldrb	w3, [x19, 60]
	ldrb	w1, [x19, 60]
	add	w0, w0, 1
	str	w0, [x19, 48]
	ldr	x0, [x19, 16]
	madd	x0, x3, x25, x0
	b	L112
L87:
	str	x21, [x19, 40]
	b	L88
LFE53:
	.align	2
	.globl _hdr_packed_record_value
_hdr_packed_record_value:
LFB54:
	mov	x2, 1
	b	_hdr_packed_record_values
LFE54:
	.align	2
	.globl _hdr_packed_reset
_hdr_packed_count_at_value:
LFB59:
	tbnz	x1, #63, L142
	stp	x29, x30, [sp, -32]!
LCFI52:
	mov	x29, sp
LCFI53:
	stp	x19, x20, [sp, 16]
LCFI54:
	mov	x19, x0
	ldr	x20, [x0]
	mov	x0, x20
	bl	_counts_index_for
	mov	w1, w0
	ldr	w0, [x20, 80]
	cmp	w0, w1
	bls	L139
	mov	x0, x19
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 32
LCFI55:
	b	_sparse_get
L139:
LCFI56:
	ldp	x19, x20, [sp, 16]
	mov	x0, 0
	ldp	x29, x30, [sp], 32
LCFI57:
	ret
L142:
	mov	x0, 0
	ret
LFE59:
	.align	2
	.globl _hdr_packed_max
_hdr_packed_value_at_percentile:
LFB65:
	mov	x2, x0
	ldr	x0, [x0, 24]
	cbz	x0, L157
	stp	x29, x30, [sp, -32]!
LCFI63:
	mov	x29, sp
LCFI64:
	str	x19, [sp, 16]
	str	d15, [sp, 24]
LCFI65:
	fmov	d15, d0
	bl	_packed_count_at_percentile.isra.0
	ldrb	w4, [x2, 60]
	mov	x3, x0
	ldp	x19, x5, [x2]
	ldr	x0, [x2, 16]
	ldr	w1, [x2, 48]
	cmp	w4, 2
	beq	L159
	cmp	w4, 4
	beq	L160
	cmp	w4, 1
	bne	L191
	negs	w6, w1
	and	w2, w1, 15
	and	w6, w6, 15
	mov	x4, 0
	csneg	w6, w2, w6, mi
	mov	x2, 0
	sub	w6, w1, w6
L162:
	cmp	w6, w2
	bgt	L192
	sxtw	x2, w2
L169:
	cmp	w1, w2
	bgt	L170
L208:
	mov	x0, 0
	b	L166
L192:
	mov	x8, 0
	mov	x7, 0
	add	x10, x0, x2
L163:
	ldrb	w9, [x10, x8]
	add	x8, x8, 1
	add	x7, x7, x9
	cmp	x8, 16
	bne	L163
	sub	x8, x3, x4
	cmp	x7, x8
	blt	L164
	mov	x7, x2
	add	x8, x2, 16
L167:
	ldrb	w9, [x0, x7]
	add	x4, x4, x9
	cmp	x3, x4
	bgt	L165
L209:
	ldr	w1, [x5, w7, uxtw 2]
L207:
	mov	x0, x19
	bl	_hdr_value_at_index
L166:
	fcmp	d15, #0.0
	mov	x1, x0
	mov	x0, x19
	bne	L190
	ldr	x19, [sp, 16]
	ldr	d15, [sp, 24]
	ldp	x29, x30, [sp], 32
LCFI66:
	b	_hdr_lowest_equivalent_value
L165:
LCFI67:
	add	x7, x7, 1
	cmp	x8, x7
	bne	L167
L168:
	add	x2, x2, 16
	b	L162
L164:
	add	x4, x4, x7
	b	L168
L170:
	ldrb	w6, [x0, x2]
	add	x4, x4, x6
	add	x6, x2, 1
	cmp	x3, x4
	bgt	L193
L210:
	ldr	w1, [x5, x2, lsl 2]
	b	L207
L193:
	mov	x2, x6
	b	L169
L159:
	negs	w6, w1
	and	w2, w1, 15
	and	w6, w6, 15
	mov	x4, 0
	csneg	w6, w2, w6, mi
	mov	x2, 0
	sub	w6, w1, w6
L171:
	cmp	w6, w2
	bgt	L177
	sxtw	x2, w2
L178:
	cmp	w1, w2
	ble	L208
	ldrh	w6, [x0, x2, lsl 1]
	add	x4, x4, x6
	add	x6, x2, 1
	cmp	x3, x4
	ble	L210
	mov	x2, x6
	b	L178
L177:
	mov	x8, 0
	mov	x7, 0
	add	x10, x0, w2, uxtw 1
L172:
	ldrh	w9, [x10, x8, lsl 1]
	add	x8, x8, 1
	add	x7, x7, x9
	cmp	x8, 16
	bne	L172
	sub	x8, x3, x4
	cmp	x7, x8
	blt	L173
	mov	x7, x2
	add	x8, x2, 16
L175:
	ldrh	w9, [x0, x7, lsl 1]
	add	x4, x4, x9
	cmp	x3, x4
	ble	L209
	add	x7, x7, 1
	cmp	x7, x8
	bne	L175
L176:
	add	x2, x2, 16
	b	L171
L173:
	add	x4, x4, x7
	b	L176
L160:
	negs	w6, w1
	and	w2, w1, 15
	and	w6, w6, 15
	mov	x7, 0
	csneg	w6, w2, w6, mi
	mov	x4, 0
	sub	w6, w1, w6
	mov	w2, 0
L180:
	cmp	w6, w2
	bgt	L195
	sxtw	x2, w2
L186:
	cmp	w1, w2
	ble	L208
	ldr	w6, [x0, x2, lsl 2]
	add	x4, x4, x6
	add	x6, x2, 1
	cmp	x3, x4
	ble	L210
	mov	x2, x6
	b	L186
L195:
	mov	x9, 0
	mov	x8, 0
	add	x11, x0, x7
L181:
	ldr	w10, [x11, x9, lsl 2]
	add	x9, x9, 1
	add	x8, x8, x10
	cmp	x9, 16
	bne	L181
	sub	x9, x3, x4
	cmp	x8, x9
	blt	L182
	mov	x8, x7
	mov	w9, 0
L184:
	ldr	w10, [x0, x8]
	add	x4, x4, x10
	cmp	x3, x4
	bgt	L183
	ldr	w1, [x5, x8]
	b	L207
L183:
	add	w9, w9, 1
	add	x8, x8, 4
	cmp	w9, 16
	bne	L184
L185:
	add	w2, w2, 16
	add	x7, x7, 64
	b	L180
L182:
	add	x4, x4, x8
	b	L185
L191:
	mov	x2, 0
	mov	x4, 0
	mov	x7, 9223372036854775807
L161:
	cmp	w1, w2
	ble	L208
	ldr	x6, [x0, x2, lsl 3]
	sub	x8, x7, x4
	cmp	x6, x8
	bgt	L188
	add	x4, x4, x6
	add	x6, x2, 1
	cmp	x3, x4
	bgt	L197
L188:
	ldr	w1, [x5, w2, uxtw 2]
	b	L207
L197:
	mov	x2, x6
	b	L161
L190:
	ldr	x19, [sp, 16]
	ldr	d15, [sp, 24]
	ldp	x29, x30, [sp], 32
LCFI68:
	b	_packed_highest_equivalent
L157:
	mov	x0, 0
	ret
LFE65:
	.align	2
	.globl _hdr_packed_value_at_percentiles
_hdr_packed_value_at_percentiles:
LFB66:
	sub	sp, sp, #944
LCFI69:
	cmp	x1, 0
	ccmp	x2, 0, 4, ne
	stp	x29, x30, [sp]
LCFI70:
	mov	x29, sp
LCFI71:
	stp	x19, x20, [sp, 16]
	stp	x21, x22, [sp, 32]
	stp	x23, x24, [sp, 48]
	stp	x25, x26, [sp, 64]
LCFI72:
	mov	x25, x0
	stp	x27, x28, [sp, 80]
LCFI73:
	stp	x2, x1, [x29, 160]
	beq	L267
	mov	x19, x3
	cbz	x3, L214
	ldr	x23, [x0, 24]
	cbnz	x23, L215
	mov	x0, x2
	mov	w1, 0
	lsl	x2, x3, 3
	bl	_memset
L214:
	mov	w0, 0
	b	L211
L215:
	ldr	x22, [x0]
	cmp	x3, 32
	bls	L268
	mov	x0, 2305843009213693951
	cmp	x3, x0
	bhi	L218
	lsl	x24, x3, 3
	mov	x0, x24
	bl	_malloc
	mov	x20, x0
	mov	x0, x24
	bl	_malloc
	mov	x21, x0
	mov	x0, x24
	bl	_malloc
	cmp	x20, 0
	mov	x27, x0
	ccmp	x21, 0, 4, ne
	beq	L219
	cbnz	x0, L217
L219:
	mov	x0, x20
	bl	_free
	mov	x0, x21
	bl	_free
	mov	x0, x27
	bl	_free
L218:
	mov	w0, 12
L211:
	ldp	x29, x30, [sp]
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	x25, x26, [sp, 64]
	ldp	x27, x28, [sp, 80]
	add	sp, sp, 944
LCFI74:
	ret
L268:
LCFI75:
	add	x27, x29, 688
	add	x21, x29, 432
	add	x20, x29, 176
L217:
	mov	x2, 0
L220:
	ldr	x0, [x29, 168]
	ldr	d0, [x0, x2, lsl 3]
	mov	x0, x23
	bl	_packed_count_at_percentile.isra.0
	str	x0, [x20, x2, lsl 3]
	str	x2, [x27, x2, lsl 3]
	add	x2, x2, 1
	cmp	x2, x19
	bne	L220
	mov	w1, 0
	lsl	x2, x19, 3
	mov	x0, x21
	bl	_memset
	mov	x1, 1
	sub	x5, x27, #8
L221:
	cmp	x1, x19
	bne	L225
	ldr	w24, [x25, 48]
	ldr	x1, [x27]
	negs	w23, w24
	and	w0, w24, 15
	and	w23, w23, 15
	csneg	w23, w0, w23, mi
	ldrb	w0, [x25, 60]
	sub	w23, w24, w23
	ldp	x25, x26, [x25, 8]
	ldr	x28, [x20, x1, lsl 3]
	cmp	w0, 2
	beq	L226
	cmp	w0, 4
	beq	L269
	mov	x4, 0
	cmp	w0, 1
	beq	L270
	mov	x5, 0
	mov	x23, 0
	mov	x6, 9223372036854775807
L229:
	cmp	w24, w4
	ble	L242
	ldr	x0, [x26, x4, lsl 3]
	sub	x1, x6, x23
	cmp	x1, x0
	blt	L280
	add	x23, x23, x0
	cmp	x28, x23
	bgt	L262
L261:
	ldr	w1, [x25, x4, lsl 2]
	mov	x0, x22
	stp	x5, x4, [x29, 144]
	bl	_hdr_value_at_index
	ldp	x5, x4, [x29, 144]
	mov	x6, 9223372036854775807
L263:
	ldr	x1, [x27, x5, lsl 3]
	add	x5, x5, 1
	str	x0, [x21, x1, lsl 3]
	cmp	x19, x5
	bls	L242
	ldr	x1, [x27, x5, lsl 3]
	ldr	x28, [x20, x1, lsl 3]
	cmp	x28, x23
	ble	L263
L262:
	add	x4, x4, 1
	b	L229
L225:
	ldr	x2, [x27, x1, lsl 3]
	lsl	x0, x1, 3
	ldr	x6, [x20, x2, lsl 3]
L222:
	ldr	x4, [x5, x0]
	ldr	x7, [x20, x4, lsl 3]
	cmp	x7, x6
	ble	L223
	str	x4, [x27, x0]
	subs	x0, x0, #8
	bne	L222
L223:
	add	x1, x1, 1
	str	x2, [x27, x0]
	b	L221
L226:
	mov	x8, x26
	mov	x9, x25
	mov	w4, 0
	mov	w0, 0
	mov	x6, 0
	mov	x5, 0
L230:
	eor	w7, w0, 1
	cmp	w7, 0
	ccmp	w4, w23, 0, ne
	blt	L276
	sxtw	x23, w4
L248:
	cmp	w7, 0
	ccmp	w23, w24, 0, ne
	bge	L242
	ldrh	w0, [x26, x23, lsl 1]
	add	x5, x5, x0
	cmp	x28, x5
	bgt	L249
	ldr	w1, [x25, x23, lsl 2]
	mov	x0, x22
	stp	x6, x5, [x29, 136]
	str	w7, [x29, 152]
	bl	_hdr_value_at_index
	ldr	w7, [x29, 152]
	ldp	x6, x5, [x29, 136]
L250:
	ldr	x1, [x27, x6, lsl 3]
	add	x6, x6, 1
	str	x0, [x21, x1, lsl 3]
	cmp	x19, x6
	bls	L242
	ldr	x1, [x27, x6, lsl 3]
	ldr	x28, [x20, x1, lsl 3]
	cmp	x28, x5
	ble	L250
L249:
	add	x23, x23, 1
	b	L248
L273:
	mov	x0, 0
	mov	x5, 0
	add	x8, x26, x4
L231:
	ldrb	w1, [x8, x0]
	add	x0, x0, 1
	add	x5, x5, x1
	cmp	x0, 16
	bne	L231
	add	x5, x7, x5
	cmp	x5, x28
	blt	L271
	mov	x5, x7
	mov	x7, 0
	add	x9, x25, w4, uxtw 2
L235:
	ldrb	w0, [x8, x7]
	add	x5, x5, x0
	cmp	x5, x28
	blt	L233
	ldr	w1, [x9, x7, lsl 2]
	mov	x0, x22
	stp	x8, x6, [x29, 112]
	stp	x5, x4, [x29, 128]
	stp	x9, x7, [x29, 144]
	bl	_hdr_value_at_index
	ldp	x8, x6, [x29, 112]
	ldp	x5, x4, [x29, 128]
	ldp	x9, x7, [x29, 144]
L234:
	ldr	x1, [x27, x6, lsl 3]
	add	x6, x6, 1
	str	x0, [x21, x1, lsl 3]
	cmp	x19, x6
	bls	L272
	ldr	x1, [x27, x6, lsl 3]
	ldr	x1, [x20, x1, lsl 3]
	cmp	x1, x5
	ble	L234
	mov	x28, x1
L233:
	add	x7, x7, 1
	cmp	x7, 16
	bne	L235
L271:
	mov	w0, 0
L232:
	add	x4, x4, 16
	mov	x7, x5
L228:
	eor	w5, w0, 1
	cmp	w5, 0
	ccmp	w4, w23, 0, ne
	blt	L273
	sxtw	x23, w4
L236:
	cmp	w5, 0
	ccmp	w24, w23, 4, ne
	ble	L242
	ldrb	w0, [x26, x23]
	add	x7, x7, x0
	cmp	x28, x7
	bgt	L237
	ldr	w1, [x25, x23, lsl 2]
	mov	x0, x22
	stp	x6, x7, [x29, 136]
	str	w5, [x29, 152]
	bl	_hdr_value_at_index
	ldr	w5, [x29, 152]
	ldp	x6, x7, [x29, 136]
L240:
	ldr	x1, [x27, x6, lsl 3]
	add	x6, x6, 1
	str	x0, [x21, x1, lsl 3]
	cmp	x19, x6
	bhi	L238
L242:
	mov	x23, 0
L239:
	ldr	x0, [x29, 168]
	ldr	x1, [x21, x23, lsl 3]
	ldr	d31, [x0, x23, lsl 3]
	mov	x0, x22
	fcmp	d31, #0.0
	bne	L265
	bl	_hdr_lowest_equivalent_value
L266:
	ldr	x1, [x29, 160]
	str	x0, [x1, x23, lsl 3]
	add	x23, x23, 1
	cmp	x19, x23
	bne	L239
	cmp	x19, 32
	bls	L214
	mov	x0, x20
	bl	_free
	mov	x0, x21
	bl	_free
	mov	x0, x27
	bl	_free
	b	L214
L272:
	mov	w0, 1
	b	L232
L270:
	mov	w0, 0
	mov	x6, 0
	mov	x7, 0
	b	L228
L238:
	ldr	x1, [x27, x6, lsl 3]
	ldr	x28, [x20, x1, lsl 3]
	cmp	x28, x7
	ble	L240
L237:
	add	x23, x23, 1
	b	L236
L276:
	mov	x1, 0
	mov	x0, 0
L243:
	ldrh	w7, [x8, x1, lsl 1]
	add	x1, x1, 1
	add	x0, x0, x7
	cmp	x1, 16
	bne	L243
	add	x0, x5, x0
	cmp	x0, x28
	blt	L274
	mov	x7, 0
L247:
	ldrh	w0, [x8, x7, lsl 1]
	add	x5, x5, x0
	cmp	x5, x28
	blt	L245
	ldr	w1, [x9, x7, lsl 2]
	mov	x0, x22
	str	w4, [x29, 112]
	stp	x6, x5, [x29, 120]
	stp	x8, x9, [x29, 136]
	str	x7, [x29, 152]
	bl	_hdr_value_at_index
	ldr	x7, [x29, 152]
	ldp	x6, x5, [x29, 120]
	ldp	x8, x9, [x29, 136]
	ldr	w4, [x29, 112]
L246:
	ldr	x1, [x27, x6, lsl 3]
	add	x6, x6, 1
	str	x0, [x21, x1, lsl 3]
	cmp	x19, x6
	bls	L275
	ldr	x1, [x27, x6, lsl 3]
	ldr	x1, [x20, x1, lsl 3]
	cmp	x1, x5
	ble	L246
	mov	x28, x1
L245:
	add	x7, x7, 1
	cmp	x7, 16
	bne	L247
L300:
	mov	w0, 0
L244:
	add	w4, w4, 16
	add	x8, x8, 32
	add	x9, x9, 64
	b	L230
L274:
	mov	x5, x0
	b	L300
L275:
	mov	w0, 1
	b	L244
L279:
	mov	x1, 0
	mov	x0, 0
	add	x9, x26, x8
L252:
	ldr	w4, [x9, x1, lsl 2]
	add	x1, x1, 1
	add	x0, x0, x4
	cmp	x1, 16
	bne	L252
	add	x0, x5, x0
	cmp	x0, x28
	blt	L277
	mov	x4, 0
	add	x10, x25, x8
L256:
	ldr	w0, [x9, x4]
	add	x5, x5, x0
	cmp	x5, x28
	blt	L254
	ldr	w1, [x10, x4]
	mov	x0, x22
	stp	x8, x9, [x29, 104]
	str	w7, [x29, 120]
	stp	x6, x5, [x29, 128]
	stp	x4, x10, [x29, 144]
	bl	_hdr_value_at_index
	ldr	w7, [x29, 120]
	ldp	x8, x9, [x29, 104]
	ldp	x6, x5, [x29, 128]
	ldp	x4, x10, [x29, 144]
L255:
	ldr	x1, [x27, x6, lsl 3]
	add	x6, x6, 1
	str	x0, [x21, x1, lsl 3]
	cmp	x19, x6
	bls	L278
	ldr	x1, [x27, x6, lsl 3]
	ldr	x1, [x20, x1, lsl 3]
	cmp	x1, x5
	ble	L255
	mov	x28, x1
L254:
	add	x4, x4, 4
	cmp	x4, 64
	bne	L256
L301:
	mov	w0, 0
L253:
	add	w7, w7, 16
	add	x8, x8, 64
L227:
	eor	w4, w0, 1
	cmp	w4, 0
	ccmp	w7, w23, 0, ne
	blt	L279
	sxtw	x23, w7
L257:
	cmp	w4, 0
	ccmp	w23, w24, 0, ne
	bge	L242
	ldr	w0, [x26, x23, lsl 2]
	add	x5, x5, x0
	cmp	x28, x5
	bgt	L258
	ldr	w1, [x25, x23, lsl 2]
	mov	x0, x22
	stp	x6, x5, [x29, 136]
	str	w4, [x29, 152]
	bl	_hdr_value_at_index
	ldr	w4, [x29, 152]
	ldp	x6, x5, [x29, 136]
L259:
	ldr	x1, [x27, x6, lsl 3]
	add	x6, x6, 1
	str	x0, [x21, x1, lsl 3]
	cmp	x19, x6
	bls	L242
	ldr	x1, [x27, x6, lsl 3]
	ldr	x28, [x20, x1, lsl 3]
	cmp	x28, x5
	ble	L259
L258:
	add	x23, x23, 1
	b	L257
L277:
	mov	x5, x0
	b	L301
L278:
	mov	w0, 1
	b	L253
L269:
	mov	x8, 0
	mov	w7, 0
	mov	w0, 0
	mov	x6, 0
	mov	x5, 0
	b	L227
L280:
	mov	x23, 9223372036854775807
	b	L261
L265:
	bl	_packed_highest_equivalent
	b	L266
L267:
	mov	w0, 22
	b	L211
LFE66:
	.align	2
	.globl _hdr_packed_get_memory_size
