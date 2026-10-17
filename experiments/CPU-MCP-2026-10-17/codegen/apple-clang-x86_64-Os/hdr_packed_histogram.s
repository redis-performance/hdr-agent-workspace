_hdr_packed_record_values:              ## @hdr_packed_record_values
	.cfi_startproc
## %bb.0:
	testq	%rsi, %rsi
	js	LBB6_7
## %bb.1:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	subq	$24, %rsp
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movq	%rdx, %r15
	xorl	%eax, %eax
	testq	%rdx, %rdx
	js	LBB6_6
## %bb.2:
	movq	%rsi, %rbx
	movq	%rdi, %r14
	movq	(%rdi), %r12
	cmpq	%rsi, 8(%r12)
	jl	LBB6_6
## %bb.3:
	movq	%r12, %rdi
	movq	%rbx, %rsi
	callq	_counts_index_for
	cmpl	80(%r12), %eax
	jae	LBB6_5
## %bb.4:
	movl	%eax, %r13d
	movq	24(%r14), %rax
	movabsq	$9223372036854775807, %rcx      ## imm = 0x7FFFFFFFFFFFFFFF
	xorq	%rax, %rcx
	cmpq	%r15, %rcx
	jae	LBB6_9
LBB6_5:
	xorl	%eax, %eax
LBB6_6:
	addq	$24, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
                                        ## kill: def $al killed $al killed $eax
	retq
LBB6_7:
	xorl	%eax, %eax
                                        ## kill: def $al killed $al killed $eax
	retq
LBB6_9:
	testq	%r15, %r15
	je	LBB6_38
## %bb.10:
	movl	48(%r14), %eax
	testl	%eax, %eax
	jle	LBB6_16
## %bb.11:
	movq	8(%r14), %rcx
	xorl	%r12d, %r12d
	movl	%eax, %edx
LBB6_12:                                ## =>This Inner Loop Header: Depth=1
	movl	%edx, %esi
	subl	%r12d, %esi
	shrl	%esi
	leal	(%rsi,%r12), %edi
	cmpl	%r13d, (%rcx,%rdi,4)
	jl	LBB6_14
## %bb.13:                              ##   in Loop: Header=BB6_12 Depth=1
	movl	%edi, %edx
	jmp	LBB6_15
LBB6_14:                                ##   in Loop: Header=BB6_12 Depth=1
	addl	%esi, %r12d
	incl	%r12d
LBB6_15:                                ##   in Loop: Header=BB6_12 Depth=1
	cmpl	%edx, %r12d
	jl	LBB6_12
	jmp	LBB6_17
LBB6_16:
	xorl	%r12d, %r12d
LBB6_17:
	cmpl	%eax, %r12d
	jge	LBB6_23
## %bb.18:
	movq	8(%r14), %rdx
	movl	%r12d, %ecx
	cmpl	%r13d, (%rdx,%rcx,4)
	jne	LBB6_23
## %bb.19:
	movq	16(%r14), %rax
	movzbl	60(%r14), %edx
	imulq	%rdx, %rcx
	cmpl	$4, %edx
	je	LBB6_34
## %bb.20:
	cmpl	$2, %edx
	je	LBB6_33
## %bb.21:
	cmpl	$1, %edx
	jne	LBB6_35
## %bb.22:
	movzbl	(%rax,%rcx), %r13d
	jmp	LBB6_36
LBB6_23:
	movl	52(%r14), %edx
	movl	56(%r14), %ecx
	cmpl	%edx, %eax
	setl	%sil
	cmpl	%ecx, %eax
	setl	%al
	testb	%al, %sil
	je	LBB6_26
LBB6_24:
	movq	%r14, %rdi
	movq	%r15, %rsi
	callq	_widen_to_fit
	testb	%al, %al
	je	LBB6_5
## %bb.25:
	movq	8(%r14), %rax
	movl	%r12d, %ecx
	movq	%rcx, -48(%rbp)                 ## 8-byte Spill
	leaq	1(%rcx), %rdx
	movq	%rdx, -56(%rbp)                 ## 8-byte Spill
	leaq	4(%rax,%rcx,4), %rdi
	leaq	(%rax,%rcx,4), %rsi
	movslq	48(%r14), %rdx
	movslq	%r12d, %rax
	movq	%rax, -64(%rbp)                 ## 8-byte Spill
	subq	%rax, %rdx
	shlq	$2, %rdx
	callq	_memmove
	movq	16(%r14), %rax
	movzbl	60(%r14), %esi
	movq	-56(%rbp), %rdi                 ## 8-byte Reload
	imulq	%rsi, %rdi
	addq	%rax, %rdi
	movslq	48(%r14), %rdx
	subq	-64(%rbp), %rdx                 ## 8-byte Folded Reload
	imulq	%rsi, %rdx
	imulq	-48(%rbp), %rsi                 ## 8-byte Folded Reload
	addq	%rax, %rsi
	callq	_memmove
	movq	8(%r14), %rax
	movq	-48(%rbp), %rcx                 ## 8-byte Reload
	movl	%r13d, (%rax,%rcx,4)
	incl	48(%r14)
	movq	%r15, %r13
	jmp	LBB6_37
LBB6_26:
	cmpl	%ecx, %edx
	movl	%ecx, %eax
	cmovll	%edx, %eax
	cmpl	$1073741823, %eax               ## imm = 0x3FFFFFFF
	jg	LBB6_5
## %bb.27:
	leal	(%rax,%rax), %esi
	testl	%eax, %eax
	movl	$4, %eax
	cmovnel	%esi, %eax
	cmpl	%eax, %edx
	movl	%eax, -48(%rbp)                 ## 4-byte Spill
	jge	LBB6_30
## %bb.28:
	movq	8(%r14), %rdi
	movslq	%eax, %rsi
	shlq	$2, %rsi
	callq	_realloc
	testq	%rax, %rax
	je	LBB6_5
## %bb.29:
	movq	%rax, 8(%r14)
	movl	-48(%rbp), %eax                 ## 4-byte Reload
	movl	%eax, 52(%r14)
	movl	56(%r14), %ecx
LBB6_30:
	cmpl	%eax, %ecx
	jge	LBB6_24
## %bb.31:
	movq	16(%r14), %rdi
	cltq
	movzbl	60(%r14), %esi
	imulq	%rax, %rsi
	callq	_realloc
	testq	%rax, %rax
	je	LBB6_5
## %bb.32:
	movq	%rax, 16(%r14)
	movl	-48(%rbp), %eax                 ## 4-byte Reload
	movl	%eax, 56(%r14)
	jmp	LBB6_24
LBB6_33:
	movzwl	(%rax,%rcx), %r13d
	jmp	LBB6_36
LBB6_34:
	movl	(%rax,%rcx), %r13d
	jmp	LBB6_36
LBB6_35:
	movq	(%rax,%rcx), %r13
LBB6_36:
	addq	%r15, %r13
	movq	%r14, %rdi
	movq	%r13, %rsi
	callq	_widen_to_fit
	testb	%al, %al
	je	LBB6_5
LBB6_37:
	movq	%r14, %rdi
	movl	%r12d, %esi
	movq	%r13, %rdx
	callq	_slot_set
	movq	24(%r14), %rax
LBB6_38:
	addq	%r15, %rax
	movq	%rax, 24(%r14)
	testq	%rbx, %rbx
	je	LBB6_41
## %bb.39:
	cmpq	%rbx, 32(%r14)
	jle	LBB6_41
## %bb.40:
	movq	%rbx, 32(%r14)
LBB6_41:
	movb	$1, %al
	cmpq	%rbx, 40(%r14)
	jge	LBB6_6
## %bb.42:
	movq	%rbx, 40(%r14)
	jmp	LBB6_6
	.cfi_endproc

_hdr_packed_record_value:               ## @hdr_packed_record_value
	.cfi_startproc
## %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	movl	$1, %edx
	popq	%rbp
	jmp	_hdr_packed_record_values       ## TAILCALL
	.cfi_endproc

_hdr_packed_count_at_value:             ## @hdr_packed_count_at_value
	.cfi_startproc
## %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r14
	pushq	%rbx
	.cfi_offset %rbx, -32
	.cfi_offset %r14, -24
	testq	%rsi, %rsi
	js	LBB12_2
## %bb.1:
	movq	%rdi, %rbx
	movq	(%rdi), %r14
	movq	%r14, %rdi
	callq	_counts_index_for
	cmpl	80(%r14), %eax
	jae	LBB12_2
## %bb.3:
	movq	%rbx, %rdi
	movl	%eax, %esi
	popq	%rbx
	popq	%r14
	popq	%rbp
	jmp	_sparse_get                     ## TAILCALL
LBB12_2:
	xorl	%eax, %eax
	popq	%rbx
	popq	%r14
	popq	%rbp
	retq
	.cfi_endproc

_hdr_packed_value_at_percentile:        ## @hdr_packed_value_at_percentile
	.cfi_startproc
## %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r15
	pushq	%r14
	pushq	%rbx
	pushq	%rax
	.cfi_offset %rbx, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movq	24(%rdi), %rax
	testq	%rax, %rax
	je	LBB16_1
## %bb.2:
	movsd	LCPI16_0(%rip), %xmm2           ## xmm2 = [1.0E+2,0.0E+0]
	movapd	%xmm0, %xmm3
	minsd	%xmm2, %xmm3
	cvtsi2sd	%rax, %xmm1
	divsd	%xmm2, %xmm3
	mulsd	%xmm1, %xmm3
	addsd	LCPI16_1(%rip), %xmm3
	movl	$1, %ecx
	ucomisd	LCPI16_2(%rip), %xmm3
	jb	LBB16_5
## %bb.3:
	ucomisd	%xmm1, %xmm3
	movq	%rax, %rcx
	jae	LBB16_5
## %bb.4:
	cvttsd2si	%xmm3, %rcx
LBB16_5:
	movq	(%rdi), %rbx
	movl	48(%rdi), %edx
	movq	8(%rdi), %rax
	movq	16(%rdi), %rsi
	movzbl	60(%rdi), %edi
	cmpl	$4, %edi
	movsd	%xmm0, -32(%rbp)                ## 8-byte Spill
	je	LBB16_37
## %bb.6:
	cmpl	$2, %edi
	je	LBB16_22
## %bb.7:
	cmpl	$1, %edi
	jne	LBB16_53
## %bb.8:
	leal	15(%rdx), %r9d
	testl	%edx, %edx
	cmovnsl	%edx, %r9d
	andl	$-16, %r9d
	jle	LBB16_9
## %bb.12:
	xorl	%r11d, %r11d
	xorpd	%xmm3, %xmm3
	movq	%rsi, %r14
	xorl	%r10d, %r10d
	xorl	%r8d, %r8d
LBB16_13:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_17 Depth 2
	movdqu	(%rsi,%r10), %xmm1
	psadbw	%xmm3, %xmm1
	pshufd	$238, %xmm1, %xmm2              ## xmm2 = xmm1[2,3,2,3]
	paddq	%xmm1, %xmm2
	movq	%xmm2, %rdi
	movq	%rcx, %r15
	subq	%r8, %r15
	cmpq	%r15, %rdi
	jge	LBB16_14
## %bb.18:                              ##   in Loop: Header=BB16_13 Depth=1
	addq	%rdi, %r8
	jmp	LBB16_19
LBB16_14:                               ##   in Loop: Header=BB16_13 Depth=1
	xorl	%edi, %edi
LBB16_17:                               ##   Parent Loop BB16_13 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%r8, %r15
	movzbl	(%r14,%rdi), %r8d
	addq	%r15, %r8
	cmpq	%rcx, %r8
	jge	LBB16_48
## %bb.16:                              ##   in Loop: Header=BB16_17 Depth=2
	incq	%rdi
	cmpq	$16, %rdi
	jne	LBB16_17
LBB16_19:                               ##   in Loop: Header=BB16_13 Depth=1
	addq	$16, %r10
	addq	$-16, %r11
	addq	$16, %r14
	cmpl	%r10d, %r9d
	jg	LBB16_13
	jmp	LBB16_10
LBB16_1:
	xorl	%r15d, %r15d
	jmp	LBB16_61
LBB16_22:
	leal	15(%rdx), %r9d
	testl	%edx, %edx
	cmovnsl	%edx, %r9d
	andl	$-16, %r9d
	jle	LBB16_23
## %bb.26:
	xorl	%r11d, %r11d
	movq	%rsi, %r14
	xorl	%r10d, %r10d
	xorl	%r8d, %r8d
LBB16_27:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_28 Depth 2
                                        ##     Child Loop BB16_32 Depth 2
	xorpd	%xmm2, %xmm2
	xorl	%edi, %edi
LBB16_28:                               ##   Parent Loop BB16_27 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	pmovzxwq	(%r14,%rdi,2), %xmm1            ## xmm1 = mem[0],zero,zero,zero,mem[1],zero,zero,zero
	paddq	%xmm1, %xmm2
	addq	$2, %rdi
	cmpq	$16, %rdi
	jne	LBB16_28
## %bb.29:                              ##   in Loop: Header=BB16_27 Depth=1
	pshufd	$238, %xmm2, %xmm1              ## xmm1 = xmm2[2,3,2,3]
	paddq	%xmm2, %xmm1
	movq	%xmm1, %rdi
	movq	%rcx, %r15
	subq	%r8, %r15
	cmpq	%r15, %rdi
	jge	LBB16_30
## %bb.33:                              ##   in Loop: Header=BB16_27 Depth=1
	addq	%rdi, %r8
	jmp	LBB16_34
LBB16_30:                               ##   in Loop: Header=BB16_27 Depth=1
	xorl	%edi, %edi
LBB16_32:                               ##   Parent Loop BB16_27 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%r8, %r15
	movzwl	(%r14,%rdi,2), %r8d
	addq	%r15, %r8
	cmpq	%rcx, %r8
	jge	LBB16_48
## %bb.31:                              ##   in Loop: Header=BB16_32 Depth=2
	incq	%rdi
	cmpq	$16, %rdi
	jne	LBB16_32
LBB16_34:                               ##   in Loop: Header=BB16_27 Depth=1
	addq	$16, %r10
	addq	$32, %r14
	addq	$-16, %r11
	cmpl	%r10d, %r9d
	jg	LBB16_27
	jmp	LBB16_24
LBB16_37:
	leal	15(%rdx), %r9d
	testl	%edx, %edx
	cmovnsl	%edx, %r9d
	andl	$-16, %r9d
	jle	LBB16_38
## %bb.41:
	xorl	%r11d, %r11d
	movq	%rsi, %r14
	xorl	%r10d, %r10d
	xorl	%r8d, %r8d
LBB16_42:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_43 Depth 2
                                        ##     Child Loop BB16_47 Depth 2
	xorpd	%xmm2, %xmm2
	xorl	%edi, %edi
LBB16_43:                               ##   Parent Loop BB16_42 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	pmovzxdq	(%r14,%rdi,4), %xmm1            ## xmm1 = mem[0],zero,mem[1],zero
	paddq	%xmm1, %xmm2
	addq	$2, %rdi
	cmpq	$16, %rdi
	jne	LBB16_43
## %bb.44:                              ##   in Loop: Header=BB16_42 Depth=1
	pshufd	$238, %xmm2, %xmm1              ## xmm1 = xmm2[2,3,2,3]
	paddq	%xmm2, %xmm1
	movq	%xmm1, %rdi
	movq	%rcx, %r15
	subq	%r8, %r15
	cmpq	%r15, %rdi
	jge	LBB16_45
## %bb.49:                              ##   in Loop: Header=BB16_42 Depth=1
	addq	%rdi, %r8
	jmp	LBB16_50
LBB16_45:                               ##   in Loop: Header=BB16_42 Depth=1
	xorl	%edi, %edi
LBB16_47:                               ##   Parent Loop BB16_42 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%r8, %r15
	movl	(%r14,%rdi,4), %r8d
	addq	%r15, %r8
	cmpq	%rcx, %r8
	jge	LBB16_48
## %bb.46:                              ##   in Loop: Header=BB16_47 Depth=2
	incq	%rdi
	cmpq	$16, %rdi
	jne	LBB16_47
LBB16_50:                               ##   in Loop: Header=BB16_42 Depth=1
	addq	$16, %r10
	addq	$64, %r14
	addq	$-16, %r11
	cmpl	%r10d, %r9d
	jg	LBB16_42
	jmp	LBB16_39
LBB16_48:
	subq	%r11, %rdi
LBB16_58:
	movl	(%rax,%rdi,4), %esi
	movq	%rbx, %rdi
	callq	_hdr_value_at_index
	movq	%rax, %r14
	jmp	LBB16_59
LBB16_53:
	testl	%edx, %edx
	jle	LBB16_11
## %bb.54:
	movabsq	$9223372036854775807, %r8       ## imm = 0x7FFFFFFFFFFFFFFF
	xorl	%r14d, %r14d
	xorl	%edi, %edi
	xorl	%r9d, %r9d
LBB16_56:                               ## =>This Inner Loop Header: Depth=1
	movq	(%rsi,%rdi,8), %r10
	movq	%r8, %r11
	subq	%r9, %r11
	cmpq	%r11, %r10
	jg	LBB16_58
## %bb.57:                              ##   in Loop: Header=BB16_56 Depth=1
	addq	%r10, %r9
	cmpq	%rcx, %r9
	jge	LBB16_58
## %bb.55:                              ##   in Loop: Header=BB16_56 Depth=1
	incq	%rdi
	cmpq	%rdi, %rdx
	jne	LBB16_56
	jmp	LBB16_59
LBB16_23:
	xorl	%r10d, %r10d
	xorl	%r8d, %r8d
LBB16_24:
	cmpl	%edx, %r10d
	jge	LBB16_11
## %bb.25:
	movl	%r10d, %edi
	xorl	%r14d, %r14d
LBB16_36:                               ## =>This Inner Loop Header: Depth=1
	movq	%r8, %r9
	movzwl	(%rsi,%rdi,2), %r8d
	addq	%r9, %r8
	cmpq	%rcx, %r8
	jge	LBB16_58
## %bb.35:                              ##   in Loop: Header=BB16_36 Depth=1
	incq	%rdi
	cmpl	%edi, %edx
	jg	LBB16_36
	jmp	LBB16_59
LBB16_38:
	xorl	%r10d, %r10d
	xorl	%r8d, %r8d
LBB16_39:
	cmpl	%edx, %r10d
	jge	LBB16_11
## %bb.40:
	movl	%r10d, %edi
	xorl	%r14d, %r14d
LBB16_52:                               ## =>This Inner Loop Header: Depth=1
	movq	%r8, %r9
	movl	(%rsi,%rdi,4), %r8d
	addq	%r9, %r8
	cmpq	%rcx, %r8
	jge	LBB16_58
## %bb.51:                              ##   in Loop: Header=BB16_52 Depth=1
	incq	%rdi
	cmpl	%edi, %edx
	jg	LBB16_52
	jmp	LBB16_59
LBB16_9:
	xorl	%r10d, %r10d
	xorl	%r8d, %r8d
LBB16_10:
	cmpl	%edx, %r10d
	jge	LBB16_11
## %bb.15:
	movl	%r10d, %edi
	xorl	%r14d, %r14d
LBB16_21:                               ## =>This Inner Loop Header: Depth=1
	movq	%r8, %r9
	movzbl	(%rsi,%rdi), %r8d
	addq	%r9, %r8
	cmpq	%rcx, %r8
	jge	LBB16_58
## %bb.20:                              ##   in Loop: Header=BB16_21 Depth=1
	incq	%rdi
	cmpl	%edi, %edx
	jg	LBB16_21
	jmp	LBB16_59
LBB16_11:
	xorl	%r14d, %r14d
LBB16_59:
	movq	%rbx, %rdi
	movq	%r14, %rsi
	callq	_hdr_lowest_equivalent_value
	movq	%rax, %r15
	xorpd	%xmm0, %xmm0
	movsd	-32(%rbp), %xmm1                ## 8-byte Reload
                                        ## xmm1 = mem[0],zero
	ucomisd	%xmm0, %xmm1
	jne	LBB16_60
	jnp	LBB16_61
LBB16_60:
	movq	%rbx, %rdi
	movq	%r14, %rsi
	callq	_hdr_size_of_equivalent_value_range
	movabsq	$9223372036854775807, %rcx      ## imm = 0x7FFFFFFFFFFFFFFF
	movq	%rcx, %rdx
	subq	%rax, %rdx
	cmpq	%rdx, %r15
	leaq	-1(%r15,%rax), %r15
	cmovgq	%rcx, %r15
LBB16_61:
	movq	%r15, %rax
	addq	$8, %rsp
	popq	%rbx
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
	.cfi_endproc

_hdr_packed_value_at_percentiles:       ## @hdr_packed_value_at_percentiles
	.cfi_startproc
## %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	subq	$872, %rsp                      ## imm = 0x368
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movq	___stack_chk_guard@GOTPCREL(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, -48(%rbp)
	testq	%rsi, %rsi
	sete	%al
	movq	%rdx, -904(%rbp)                ## 8-byte Spill
	testq	%rdx, %rdx
	sete	%dl
	orb	%al, %dl
	movl	$22, %r15d
	jne	LBB17_4
## %bb.1:
	xorl	%r15d, %r15d
	testq	%rcx, %rcx
	je	LBB17_4
## %bb.2:
	movq	24(%rdi), %r12
	testq	%r12, %r12
	je	LBB17_3
## %bb.6:
	movq	(%rdi), %rax
	movq	%rax, -840(%rbp)                ## 8-byte Spill
	cmpq	$33, %rcx
	movq	%rcx, -832(%rbp)                ## 8-byte Spill
	jb	LBB17_7
## %bb.8:
	movq	%rcx, %rax
	shrq	$61, %rax
	movl	$12, %r15d
	jne	LBB17_4
## %bb.9:
	movq	%rdi, -824(%rbp)                ## 8-byte Spill
	movq	%rsi, -888(%rbp)                ## 8-byte Spill
	leaq	(,%rcx,8), %r13
	movq	%r13, %rdi
	callq	_malloc
	movq	%rax, %r14
	movq	%r13, %rdi
	callq	_malloc
	movq	%rax, %rbx
	movq	%r13, %rdi
	callq	_malloc
	movq	%rbx, %r9
	movq	%rax, %r13
	testq	%r14, %r14
	setne	%al
	testq	%rbx, %rbx
	setne	%cl
	andb	%al, %cl
	testq	%r13, %r13
	setne	%al
	testb	%al, %cl
	je	LBB17_93
## %bb.10:
	movq	-832(%rbp), %rcx                ## 8-byte Reload
	movq	-888(%rbp), %rsi                ## 8-byte Reload
	movq	-824(%rbp), %rdi                ## 8-byte Reload
	jmp	LBB17_11
LBB17_3:
	shlq	$3, %rcx
	movq	-904(%rbp), %rdi                ## 8-byte Reload
	movq	%rcx, %rsi
	callq	___bzero
	jmp	LBB17_4
LBB17_7:
	leaq	-304(%rbp), %r14
	leaq	-560(%rbp), %r9
	leaq	-816(%rbp), %r13
LBB17_11:
	cvtsi2sd	%r12, %xmm0
	xorl	%eax, %eax
	movsd	LCPI17_0(%rip), %xmm1           ## xmm1 = [1.0E+2,0.0E+0]
	movsd	LCPI17_1(%rip), %xmm2           ## xmm2 = [5.0E-1,0.0E+0]
	movsd	LCPI17_2(%rip), %xmm3           ## xmm3 = [1.0E+0,0.0E+0]
LBB17_12:                               ## =>This Inner Loop Header: Depth=1
	movsd	(%rsi,%rax,8), %xmm4            ## xmm4 = mem[0],zero
	minsd	%xmm1, %xmm4
	divsd	%xmm1, %xmm4
	mulsd	%xmm0, %xmm4
	addsd	%xmm2, %xmm4
	movl	$1, %edx
	ucomisd	%xmm3, %xmm4
	jb	LBB17_15
## %bb.13:                              ##   in Loop: Header=BB17_12 Depth=1
	ucomisd	%xmm0, %xmm4
	movq	%r12, %rdx
	jae	LBB17_15
## %bb.14:                              ##   in Loop: Header=BB17_12 Depth=1
	cvttsd2si	%xmm4, %rdx
LBB17_15:                               ##   in Loop: Header=BB17_12 Depth=1
	movq	%rdx, (%r14,%rax,8)
	movq	$0, (%r9,%rax,8)
	movq	%rax, (%r13,%rax,8)
	incq	%rax
	cmpq	%rax, %rcx
	jne	LBB17_12
## %bb.16:
	movq	%rsi, -888(%rbp)                ## 8-byte Spill
	cmpq	$1, %rcx
	je	LBB17_23
## %bb.17:
	movl	$1, %eax
LBB17_18:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB17_19 Depth 2
	movq	(%r13,%rax,8), %r8
	movq	(%r14,%r8,8), %rsi
	movq	%rax, %rdx
LBB17_19:                               ##   Parent Loop BB17_18 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	-8(%r13,%rdx,8), %r10
	cmpq	%rsi, (%r14,%r10,8)
	jle	LBB17_22
## %bb.20:                              ##   in Loop: Header=BB17_19 Depth=2
	movq	%r10, (%r13,%rdx,8)
	decq	%rdx
	jne	LBB17_19
## %bb.21:                              ##   in Loop: Header=BB17_18 Depth=1
	xorl	%edx, %edx
LBB17_22:                               ##   in Loop: Header=BB17_18 Depth=1
	movq	%r8, (%r13,%rdx,8)
	incq	%rax
	cmpq	%rcx, %rax
	jne	LBB17_18
LBB17_23:
	movslq	48(%rdi), %rax
	leal	15(%rax), %edx
	testq	%rax, %rax
	movq	8(%rdi), %rcx
	movq	%rcx, -824(%rbp)                ## 8-byte Spill
	movq	%rax, -856(%rbp)                ## 8-byte Spill
	cmovnsl	%eax, %edx
	movq	16(%rdi), %r10
	andl	$-16, %edx
	movl	%edx, -848(%rbp)                ## 4-byte Spill
	movzbl	60(%rdi), %eax
	cmpl	$1, %eax
	movq	%r9, -864(%rbp)                 ## 8-byte Spill
	movq	%r10, -872(%rbp)                ## 8-byte Spill
	je	LBB17_35
## %bb.24:
	cmpl	$2, %eax
	je	LBB17_54
## %bb.25:
	cmpl	$4, %eax
	jne	LBB17_87
## %bb.26:
	movq	(%r13), %rax
	movq	(%r14,%rax,8), %rcx
	cmpl	$0, -848(%rbp)                  ## 4-byte Folded Reload
	jle	LBB17_27
## %bb.75:
	xorl	%edi, %edi
	movq	%r10, %r12
	xorl	%r15d, %r15d
	xorl	%r8d, %r8d
LBB17_76:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB17_77 Depth 2
                                        ##     Child Loop BB17_81 Depth 2
                                        ##       Child Loop BB17_83 Depth 3
	xorpd	%xmm0, %xmm0
	xorl	%eax, %eax
LBB17_77:                               ##   Parent Loop BB17_76 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	pmovzxdq	(%r12,%rax,4), %xmm1            ## xmm1 = mem[0],zero,mem[1],zero
	paddq	%xmm1, %xmm0
	addq	$2, %rax
	cmpq	$16, %rax
	jne	LBB17_77
## %bb.78:                              ##   in Loop: Header=BB17_76 Depth=1
	pshufd	$238, %xmm0, %xmm1              ## xmm1 = xmm0[2,3,2,3]
	paddq	%xmm0, %xmm1
	movq	%xmm1, %rax
	addq	%r8, %rax
	cmpq	%rcx, %rax
	jge	LBB17_80
## %bb.79:                              ##   in Loop: Header=BB17_76 Depth=1
	movq	%rax, %r8
LBB17_86:                               ##   in Loop: Header=BB17_76 Depth=1
	addq	$16, %rdi
	addq	$64, %r12
	cmpl	%edi, -848(%rbp)                ## 4-byte Folded Reload
	jg	LBB17_76
	jmp	LBB17_28
LBB17_80:                               ##   in Loop: Header=BB17_76 Depth=1
	xorl	%ebx, %ebx
	movq	%rdi, -896(%rbp)                ## 8-byte Spill
LBB17_81:                               ##   Parent Loop BB17_76 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB17_83 Depth 3
	movq	%r8, %rdx
	movq	%rbx, %rax
	orq	%rdi, %rax
	movl	(%r10,%rax,4), %r8d
	addq	%rdx, %r8
	cmpq	%rcx, %r8
	jl	LBB17_85
## %bb.82:                              ##   in Loop: Header=BB17_81 Depth=2
	movq	-824(%rbp), %rcx                ## 8-byte Reload
	movl	(%rcx,%rax,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r8, -880(%rbp)                 ## 8-byte Spill
	callq	_hdr_value_at_index
	movq	-896(%rbp), %rdi                ## 8-byte Reload
	movq	-880(%rbp), %r8                 ## 8-byte Reload
	movq	-872(%rbp), %r10                ## 8-byte Reload
	movq	-864(%rbp), %r9                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r15,8), %rdx
LBB17_83:                               ##   Parent Loop BB17_76 Depth=1
                                        ##     Parent Loop BB17_81 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movq	%rax, (%r9,%rdx,8)
	incq	%r15
	cmpq	%rsi, %r15
	jae	LBB17_88
## %bb.84:                              ##   in Loop: Header=BB17_83 Depth=3
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r8
	jge	LBB17_83
LBB17_85:                               ##   in Loop: Header=BB17_81 Depth=2
	incq	%rbx
	cmpq	$16, %rbx
	jne	LBB17_81
	jmp	LBB17_86
LBB17_54:
	movq	(%r13), %rax
	movq	(%r14,%rax,8), %rcx
	cmpl	$0, -848(%rbp)                  ## 4-byte Folded Reload
	jle	LBB17_55
## %bb.63:
	xorl	%edi, %edi
	movq	%r10, %r12
	xorl	%r15d, %r15d
	xorl	%r8d, %r8d
LBB17_64:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB17_65 Depth 2
                                        ##     Child Loop BB17_69 Depth 2
                                        ##       Child Loop BB17_71 Depth 3
	xorpd	%xmm0, %xmm0
	xorl	%eax, %eax
LBB17_65:                               ##   Parent Loop BB17_64 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	pmovzxwq	(%r12,%rax,2), %xmm1            ## xmm1 = mem[0],zero,zero,zero,mem[1],zero,zero,zero
	paddq	%xmm1, %xmm0
	addq	$2, %rax
	cmpq	$16, %rax
	jne	LBB17_65
## %bb.66:                              ##   in Loop: Header=BB17_64 Depth=1
	pshufd	$238, %xmm0, %xmm1              ## xmm1 = xmm0[2,3,2,3]
	paddq	%xmm0, %xmm1
	movq	%xmm1, %rax
	addq	%r8, %rax
	cmpq	%rcx, %rax
	jge	LBB17_68
## %bb.67:                              ##   in Loop: Header=BB17_64 Depth=1
	movq	%rax, %r8
LBB17_74:                               ##   in Loop: Header=BB17_64 Depth=1
	addq	$16, %rdi
	addq	$32, %r12
	cmpl	%edi, -848(%rbp)                ## 4-byte Folded Reload
	jg	LBB17_64
	jmp	LBB17_56
LBB17_68:                               ##   in Loop: Header=BB17_64 Depth=1
	xorl	%ebx, %ebx
	movq	%rdi, -896(%rbp)                ## 8-byte Spill
LBB17_69:                               ##   Parent Loop BB17_64 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB17_71 Depth 3
	movq	%r8, %rdx
	movq	%rbx, %rax
	orq	%rdi, %rax
	movzwl	(%r10,%rax,2), %r8d
	addq	%rdx, %r8
	cmpq	%rcx, %r8
	jl	LBB17_73
## %bb.70:                              ##   in Loop: Header=BB17_69 Depth=2
	movq	-824(%rbp), %rcx                ## 8-byte Reload
	movl	(%rcx,%rax,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r8, -880(%rbp)                 ## 8-byte Spill
	callq	_hdr_value_at_index
	movq	-896(%rbp), %rdi                ## 8-byte Reload
	movq	-880(%rbp), %r8                 ## 8-byte Reload
	movq	-872(%rbp), %r10                ## 8-byte Reload
	movq	-864(%rbp), %r9                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r15,8), %rdx
LBB17_71:                               ##   Parent Loop BB17_64 Depth=1
                                        ##     Parent Loop BB17_69 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movq	%rax, (%r9,%rdx,8)
	incq	%r15
	cmpq	%rsi, %r15
	jae	LBB17_88
## %bb.72:                              ##   in Loop: Header=BB17_71 Depth=3
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r8
	jge	LBB17_71
LBB17_73:                               ##   in Loop: Header=BB17_69 Depth=2
	incq	%rbx
	cmpq	$16, %rbx
	jne	LBB17_69
	jmp	LBB17_74
LBB17_35:
	movq	(%r13), %rax
	movq	(%r14,%rax,8), %rcx
	cmpl	$0, -848(%rbp)                  ## 4-byte Folded Reload
	jle	LBB17_36
## %bb.44:
	xorl	%ebx, %ebx
	xorpd	%xmm2, %xmm2
	xorl	%r12d, %r12d
	xorl	%r15d, %r15d
LBB17_45:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB17_48 Depth 2
                                        ##       Child Loop BB17_50 Depth 3
	movdqu	(%r10,%rbx), %xmm0
	psadbw	%xmm2, %xmm0
	pshufd	$238, %xmm0, %xmm1              ## xmm1 = xmm0[2,3,2,3]
	paddq	%xmm0, %xmm1
	movq	%xmm1, %rax
	addq	%r12, %rax
	cmpq	%rcx, %rax
	jge	LBB17_47
## %bb.46:                              ##   in Loop: Header=BB17_45 Depth=1
	movq	%rax, %r12
LBB17_53:                               ##   in Loop: Header=BB17_45 Depth=1
	addq	$16, %rbx
	cmpl	%ebx, -848(%rbp)                ## 4-byte Folded Reload
	jg	LBB17_45
	jmp	LBB17_37
LBB17_47:                               ##   in Loop: Header=BB17_45 Depth=1
	xorl	%edi, %edi
LBB17_48:                               ##   Parent Loop BB17_45 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB17_50 Depth 3
	movq	%r12, %rdx
	movq	%rdi, %rax
	orq	%rbx, %rax
	movzbl	(%r10,%rax), %r12d
	addq	%rdx, %r12
	cmpq	%rcx, %r12
	jl	LBB17_52
## %bb.49:                              ##   in Loop: Header=BB17_48 Depth=2
	movq	-824(%rbp), %rcx                ## 8-byte Reload
	movl	(%rcx,%rax,4), %esi
	movq	%rdi, -880(%rbp)                ## 8-byte Spill
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	callq	_hdr_value_at_index
	movq	-880(%rbp), %rdi                ## 8-byte Reload
	xorpd	%xmm2, %xmm2
	movq	-872(%rbp), %r10                ## 8-byte Reload
	movq	-864(%rbp), %r9                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r15,8), %rdx
LBB17_50:                               ##   Parent Loop BB17_45 Depth=1
                                        ##     Parent Loop BB17_48 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movq	%rax, (%r9,%rdx,8)
	incq	%r15
	cmpq	%rsi, %r15
	jae	LBB17_88
## %bb.51:                              ##   in Loop: Header=BB17_50 Depth=3
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r12
	jge	LBB17_50
LBB17_52:                               ##   in Loop: Header=BB17_48 Depth=2
	incq	%rdi
	cmpq	$16, %rdi
	jne	LBB17_48
	jmp	LBB17_53
LBB17_87:
	cmpl	$0, -856(%rbp)                  ## 4-byte Folded Reload
	jle	LBB17_88
## %bb.94:
	movq	(%r13), %rax
	movq	(%r14,%rax,8), %rcx
	xorl	%r15d, %r15d
	xorl	%r12d, %r12d
	xorl	%edi, %edi
LBB17_95:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB17_97 Depth 2
	movq	(%r10,%r15,8), %rax
	movabsq	$9223372036854775807, %rsi      ## imm = 0x7FFFFFFFFFFFFFFF
	movq	%rsi, %rdx
	subq	%rdi, %rdx
	addq	%rax, %rdi
	cmpq	%rdx, %rax
	movq	%rdi, %rbx
	cmovgq	%rsi, %rbx
	cmpq	%rcx, %rbx
	jl	LBB17_99
## %bb.96:                              ##   in Loop: Header=BB17_95 Depth=1
	movq	-824(%rbp), %rax                ## 8-byte Reload
	movl	(%rax,%r15,4), %esi
	movq	%rdi, -848(%rbp)                ## 8-byte Spill
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	callq	_hdr_value_at_index
	movq	-848(%rbp), %rdi                ## 8-byte Reload
	movq	-872(%rbp), %r10                ## 8-byte Reload
	movq	-864(%rbp), %r9                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r12,8), %rdx
LBB17_97:                               ##   Parent Loop BB17_95 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%rax, (%r9,%rdx,8)
	incq	%r12
	cmpq	%rsi, %r12
	jae	LBB17_88
## %bb.98:                              ##   in Loop: Header=BB17_97 Depth=2
	movq	(%r13,%r12,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %rbx
	jge	LBB17_97
LBB17_99:                               ##   in Loop: Header=BB17_95 Depth=1
	incq	%r15
	cmpq	-856(%rbp), %r15                ## 8-byte Folded Reload
	jne	LBB17_95
	jmp	LBB17_88
LBB17_55:
	xorl	%r8d, %r8d
	xorl	%r15d, %r15d
	xorl	%edi, %edi
LBB17_56:
	cmpl	-856(%rbp), %edi                ## 4-byte Folded Reload
	jge	LBB17_88
## %bb.57:
	movl	%edi, %r12d
LBB17_58:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB17_60 Depth 2
	movq	%r8, %rax
	movzwl	(%r10,%r12,2), %r8d
	addq	%rax, %r8
	cmpq	%rcx, %r8
	jl	LBB17_62
## %bb.59:                              ##   in Loop: Header=BB17_58 Depth=1
	movq	-824(%rbp), %rax                ## 8-byte Reload
	movl	(%rax,%r12,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r8, %rbx
	callq	_hdr_value_at_index
	movq	%rbx, %r8
	movq	-872(%rbp), %r10                ## 8-byte Reload
	movq	-864(%rbp), %r9                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r15,8), %rdx
LBB17_60:                               ##   Parent Loop BB17_58 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%rax, (%r9,%rdx,8)
	incq	%r15
	cmpq	%rsi, %r15
	jae	LBB17_88
## %bb.61:                              ##   in Loop: Header=BB17_60 Depth=2
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r8
	jge	LBB17_60
LBB17_62:                               ##   in Loop: Header=BB17_58 Depth=1
	incq	%r12
	cmpl	%r12d, -856(%rbp)               ## 4-byte Folded Reload
	jg	LBB17_58
	jmp	LBB17_88
LBB17_36:
	xorl	%ebx, %ebx
	xorl	%r15d, %r15d
	xorl	%r12d, %r12d
LBB17_37:
	cmpl	-856(%rbp), %ebx                ## 4-byte Folded Reload
	jge	LBB17_88
## %bb.38:
	movl	%ebx, %ebx
LBB17_39:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB17_41 Depth 2
	movq	%r12, %rax
	movzbl	(%r10,%rbx), %r12d
	addq	%rax, %r12
	cmpq	%rcx, %r12
	jl	LBB17_43
## %bb.40:                              ##   in Loop: Header=BB17_39 Depth=1
	movq	-824(%rbp), %rax                ## 8-byte Reload
	movl	(%rax,%rbx,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	callq	_hdr_value_at_index
	movq	-872(%rbp), %r10                ## 8-byte Reload
	movq	-864(%rbp), %r9                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r15,8), %rdx
LBB17_41:                               ##   Parent Loop BB17_39 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%rax, (%r9,%rdx,8)
	incq	%r15
	cmpq	%rsi, %r15
	jae	LBB17_88
## %bb.42:                              ##   in Loop: Header=BB17_41 Depth=2
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r12
	jge	LBB17_41
LBB17_43:                               ##   in Loop: Header=BB17_39 Depth=1
	incq	%rbx
	cmpl	%ebx, -856(%rbp)                ## 4-byte Folded Reload
	jg	LBB17_39
	jmp	LBB17_88
LBB17_27:
	xorl	%r8d, %r8d
	xorl	%r15d, %r15d
	xorl	%edi, %edi
LBB17_28:
	cmpl	-856(%rbp), %edi                ## 4-byte Folded Reload
	jge	LBB17_88
## %bb.29:
	movl	%edi, %r12d
LBB17_30:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB17_32 Depth 2
	movq	%r8, %rax
	movl	(%r10,%r12,4), %r8d
	addq	%rax, %r8
	cmpq	%rcx, %r8
	jl	LBB17_34
## %bb.31:                              ##   in Loop: Header=BB17_30 Depth=1
	movq	-824(%rbp), %rax                ## 8-byte Reload
	movl	(%rax,%r12,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r8, %rbx
	callq	_hdr_value_at_index
	movq	%rbx, %r8
	movq	-872(%rbp), %r10                ## 8-byte Reload
	movq	-864(%rbp), %r9                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r15,8), %rdx
LBB17_32:                               ##   Parent Loop BB17_30 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%rax, (%r9,%rdx,8)
	incq	%r15
	cmpq	%rsi, %r15
	jae	LBB17_88
## %bb.33:                              ##   in Loop: Header=BB17_32 Depth=2
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r8
	jge	LBB17_32
LBB17_34:                               ##   in Loop: Header=BB17_30 Depth=1
	incq	%r12
	cmpl	%r12d, -856(%rbp)               ## 4-byte Folded Reload
	jg	LBB17_30
LBB17_88:
	xorl	%ebx, %ebx
	movq	-888(%rbp), %rcx                ## 8-byte Reload
LBB17_89:                               ## =>This Inner Loop Header: Depth=1
	movsd	(%rcx,%rbx,8), %xmm0            ## xmm0 = mem[0],zero
	movsd	%xmm0, -824(%rbp)               ## 8-byte Spill
	movq	(%r9,%rbx,8), %r12
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r12, %rsi
	callq	_hdr_lowest_equivalent_value
	movq	%rax, %r15
	movsd	-824(%rbp), %xmm0               ## 8-byte Reload
                                        ## xmm0 = mem[0],zero
	ucomisd	LCPI17_3(%rip), %xmm0
	jne	LBB17_90
	jnp	LBB17_91
LBB17_90:                               ##   in Loop: Header=BB17_89 Depth=1
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r12, %rsi
	callq	_hdr_size_of_equivalent_value_range
	movabsq	$9223372036854775807, %rdx      ## imm = 0x7FFFFFFFFFFFFFFF
	movq	%rdx, %rcx
	subq	%rax, %rcx
	cmpq	%rcx, %r15
	leaq	-1(%r15,%rax), %r15
	cmovgq	%rdx, %r15
LBB17_91:                               ##   in Loop: Header=BB17_89 Depth=1
	movq	-904(%rbp), %rax                ## 8-byte Reload
	movq	%r15, (%rax,%rbx,8)
	incq	%rbx
	movq	-832(%rbp), %rax                ## 8-byte Reload
	cmpq	%rbx, %rax
	movq	-888(%rbp), %rcx                ## 8-byte Reload
	movq	-864(%rbp), %r9                 ## 8-byte Reload
	jne	LBB17_89
## %bb.92:
	xorl	%r15d, %r15d
	cmpq	$32, %rax
	jbe	LBB17_4
LBB17_93:
	movq	%r14, %rdi
	movq	%r9, %rbx
	callq	_free
	movq	%rbx, %rdi
	callq	_free
	movq	%r13, %rdi
	callq	_free
LBB17_4:
	movq	___stack_chk_guard@GOTPCREL(%rip), %rax
	movq	(%rax), %rax
	cmpq	-48(%rbp), %rax
	jne	LBB17_100
## %bb.5:
	movl	%r15d, %eax
	addq	$872, %rsp                      ## imm = 0x368
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
LBB17_100:
	callq	___stack_chk_fail
	.cfi_endproc
