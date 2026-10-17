_hdr_packed_record_values:              ## @hdr_packed_record_values
	.cfi_startproc
## %bb.0:
	xorl	%eax, %eax
	testq	%rsi, %rsi
	js	LBB6_8
## %bb.1:
	testq	%rdx, %rdx
	js	LBB6_8
## %bb.2:
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
	movq	(%rdi), %rbx
	cmpq	%rsi, 8(%rbx)
	jl	LBB6_7
## %bb.3:
	movq	%rdx, %r14
	movq	%rdi, %r12
	movq	%rbx, %rdi
	movq	%rsi, %r15
	callq	_counts_index_for
	cmpl	80(%rbx), %eax
	jae	LBB6_6
## %bb.4:
	movabsq	$9223372036854775807, %rdx      ## imm = 0x7FFFFFFFFFFFFFFF
	xorq	24(%r12), %rdx
	cmpq	%r14, %rdx
	jae	LBB6_9
LBB6_6:
	xorl	%eax, %eax
LBB6_7:
	addq	$24, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
LBB6_8:
                                        ## kill: def $al killed $al killed $eax
	retq
LBB6_9:
	movq	%r12, %rcx
	movq	%r14, %rsi
	testq	%r14, %r14
	movq	%r15, %rdx
	je	LBB6_53
## %bb.10:
	movl	48(%rcx), %edx
	testl	%edx, %edx
	jle	LBB6_15
## %bb.11:
	movq	8(%rcx), %rdi
	xorl	%r13d, %r13d
	movl	%edx, %r8d
	jmp	LBB6_13
	.p2align	4, 0x90
LBB6_12:                                ##   in Loop: Header=BB6_13 Depth=1
	movl	%r10d, %r8d
	cmpl	%r8d, %r13d
	jge	LBB6_16
LBB6_13:                                ## =>This Inner Loop Header: Depth=1
	movl	%r8d, %r9d
	subl	%r13d, %r9d
	shrl	%r9d
	leal	(%r9,%r13), %r10d
	cmpl	%eax, (%rdi,%r10,4)
	jge	LBB6_12
## %bb.14:                              ##   in Loop: Header=BB6_13 Depth=1
	addl	%r9d, %r13d
	incl	%r13d
	cmpl	%r8d, %r13d
	jl	LBB6_13
	jmp	LBB6_16
LBB6_15:
	xorl	%r13d, %r13d
LBB6_16:
	cmpl	%edx, %r13d
	jge	LBB6_22
## %bb.17:
	movq	8(%rcx), %rdi
	movl	%r13d, %ebx
	cmpl	%eax, (%rdi,%rbx,4)
	jne	LBB6_22
## %bb.18:
	movq	16(%rcx), %rax
	movzbl	60(%rcx), %edi
	movq	%rdi, %rdx
	imulq	%rbx, %rdx
	cmpl	$4, %edi
	je	LBB6_38
## %bb.19:
	cmpl	$2, %edi
	je	LBB6_37
## %bb.20:
	cmpl	$1, %edi
	jne	LBB6_39
## %bb.21:
	movzbl	(%rax,%rdx), %r13d
	jmp	LBB6_40
LBB6_22:
	movl	52(%rcx), %r8d
	movl	56(%rcx), %edi
	cmpl	%r8d, %edx
	setl	%r9b
	cmpl	%edi, %edx
	setl	%dl
	testb	%dl, %r9b
	movl	%eax, -44(%rbp)                 ## 4-byte Spill
	je	LBB6_28
LBB6_23:
	movq	%rcx, %rdi
	callq	_widen_to_fit
	testb	%al, %al
	je	LBB6_6
## %bb.24:
	movq	8(%r12), %rax
	movl	%r13d, %ecx
	movq	%rcx, -56(%rbp)                 ## 8-byte Spill
	leaq	1(%rcx), %rbx
	leaq	(%rax,%rcx,4), %rdi
	addq	$4, %rdi
	leaq	(%rax,%rcx,4), %rsi
	movslq	48(%r12), %rdx
	movslq	%r13d, %r13
	subq	%r13, %rdx
	shlq	$2, %rdx
	callq	_memmove
	movq	16(%r12), %rax
	movzbl	60(%r12), %esi
	imulq	%rsi, %rbx
	addq	%rax, %rbx
	movslq	48(%r12), %rdx
	subq	%r13, %rdx
	imulq	%rsi, %rdx
	movq	-56(%rbp), %r13                 ## 8-byte Reload
	imulq	%r13, %rsi
	addq	%rax, %rsi
	movq	%rbx, %rdi
	callq	_memmove
	movq	%r13, %r8
	movq	%r12, %rcx
	movq	8(%r12), %rdx
	movl	-44(%rbp), %eax                 ## 4-byte Reload
	movl	%eax, (%rdx,%r13,4)
	incl	48(%r12)
	movq	16(%r12), %rax
	movzbl	60(%r12), %edi
	imulq	%rdi, %r8
	cmpl	$4, %edi
	je	LBB6_47
## %bb.25:
	cmpl	$2, %edi
	movq	%r15, %rdx
	movq	%r14, %rsi
	je	LBB6_46
## %bb.26:
	cmpl	$1, %edi
	jne	LBB6_48
## %bb.27:
	movb	%sil, (%rax,%r8)
	jmp	LBB6_53
LBB6_28:
	cmpl	%edi, %r8d
	movl	%edi, %edx
	cmovll	%r8d, %edx
	cmpl	$1073741823, %edx               ## imm = 0x3FFFFFFF
	jg	LBB6_6
## %bb.31:
	leal	(%rdx,%rdx), %r9d
	testl	%edx, %edx
	movl	$4, %ebx
	cmovnel	%r9d, %ebx
	cmpl	%ebx, %r8d
	jge	LBB6_34
## %bb.32:
	movq	8(%rcx), %rdi
	movslq	%ebx, %rsi
	shlq	$2, %rsi
	callq	_realloc
	testq	%rax, %rax
	je	LBB6_6
## %bb.33:
	movq	%r12, %rcx
	movq	%rax, 8(%r12)
	movl	%ebx, 52(%r12)
	movl	56(%r12), %edi
	movq	%r14, %rsi
LBB6_34:
	cmpl	%ebx, %edi
	jge	LBB6_23
## %bb.35:
	movq	16(%rcx), %rdi
	movslq	%ebx, %rax
	movzbl	60(%rcx), %esi
	imulq	%rax, %rsi
	callq	_realloc
	testq	%rax, %rax
	je	LBB6_6
## %bb.36:
	movq	%r12, %rcx
	movq	%rax, 16(%r12)
	movl	%ebx, 56(%r12)
	movq	%r14, %rsi
	jmp	LBB6_23
LBB6_37:
	movzwl	(%rax,%rdx), %r13d
	jmp	LBB6_40
LBB6_38:
	movl	(%rax,%rdx), %r13d
	jmp	LBB6_40
LBB6_39:
	movq	(%rax,%rdx), %r13
LBB6_40:
	addq	%rsi, %r13
	movq	%rcx, %rdi
	movq	%r13, %rsi
	callq	_widen_to_fit
	testb	%al, %al
	je	LBB6_6
## %bb.41:
	movq	%r12, %rcx
	movq	16(%r12), %rax
	movzbl	60(%r12), %edi
	imulq	%rdi, %rbx
	cmpl	$4, %edi
	je	LBB6_51
## %bb.42:
	cmpl	$2, %edi
	movq	%r15, %rdx
	movq	%r14, %rsi
	je	LBB6_50
## %bb.43:
	cmpl	$1, %edi
	jne	LBB6_52
## %bb.44:
	movb	%r13b, (%rax,%rbx)
	jmp	LBB6_53
LBB6_46:
	movw	%si, (%rax,%r8)
	jmp	LBB6_53
LBB6_47:
	movq	%r14, %rsi
	movl	%esi, (%rax,%r8)
	movq	%r15, %rdx
	jmp	LBB6_53
LBB6_48:
	movq	%rsi, (%rax,%r8)
	jmp	LBB6_53
LBB6_50:
	movw	%r13w, (%rax,%rbx)
	jmp	LBB6_53
LBB6_51:
	movl	%r13d, (%rax,%rbx)
	movq	%r15, %rdx
	movq	%r14, %rsi
	jmp	LBB6_53
LBB6_52:
	movq	%r13, (%rax,%rbx)
LBB6_53:
	addq	%rsi, 24(%rcx)
	testq	%rdx, %rdx
	je	LBB6_56
## %bb.54:
	cmpq	%rdx, 32(%rcx)
	jle	LBB6_56
## %bb.55:
	movq	%rdx, 32(%rcx)
LBB6_56:
	movb	$1, %al
	cmpq	%rdx, 40(%rcx)
	jge	LBB6_7
## %bb.57:
	movq	%rdx, 40(%rcx)
	jmp	LBB6_7
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
	testq	%rsi, %rsi
	js	LBB12_1
## %bb.3:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r14
	pushq	%rbx
	.cfi_offset %rbx, -32
	.cfi_offset %r14, -24
	movq	%rdi, %rbx
	movq	(%rdi), %r14
	movq	%r14, %rdi
	callq	_counts_index_for
	movl	%eax, %ecx
	xorl	%eax, %eax
	cmpl	80(%r14), %ecx
	jae	LBB12_21
## %bb.4:
	movl	48(%rbx), %edx
	testl	%edx, %edx
	jle	LBB12_10
## %bb.5:
	movq	8(%rbx), %rsi
	xorl	%eax, %eax
	movl	%edx, %edi
	jmp	LBB12_6
	.p2align	4, 0x90
LBB12_8:                                ##   in Loop: Header=BB12_6 Depth=1
	movl	%r9d, %edi
	cmpl	%edi, %eax
	jge	LBB12_10
LBB12_6:                                ## =>This Inner Loop Header: Depth=1
	movl	%edi, %r8d
	subl	%eax, %r8d
	shrl	%r8d
	leal	(%r8,%rax), %r9d
	cmpl	%ecx, (%rsi,%r9,4)
	jge	LBB12_8
## %bb.7:                               ##   in Loop: Header=BB12_6 Depth=1
	addl	%r8d, %eax
	incl	%eax
	cmpl	%edi, %eax
	jl	LBB12_6
LBB12_10:
	cmpl	%edx, %eax
	jge	LBB12_11
## %bb.12:
	movq	8(%rbx), %rdx
	movl	%eax, %eax
	cmpl	%ecx, (%rdx,%rax,4)
	jne	LBB12_13
## %bb.14:
	movq	16(%rbx), %rcx
	movzbl	60(%rbx), %edx
	imulq	%rdx, %rax
	cmpl	$4, %edx
	je	LBB12_18
## %bb.15:
	cmpl	$2, %edx
	je	LBB12_20
## %bb.16:
	cmpl	$1, %edx
	jne	LBB12_19
## %bb.17:
	movzbl	(%rcx,%rax), %eax
	popq	%rbx
	popq	%r14
	popq	%rbp
	retq
LBB12_1:
	xorl	%eax, %eax
	retq
LBB12_11:
	xorl	%eax, %eax
LBB12_21:
	popq	%rbx
	popq	%r14
	popq	%rbp
	retq
LBB12_13:
	xorl	%eax, %eax
	popq	%rbx
	popq	%r14
	popq	%rbp
	retq
LBB12_20:
	movzwl	(%rcx,%rax), %eax
	popq	%rbx
	popq	%r14
	popq	%rbp
	retq
LBB12_18:
	movl	(%rcx,%rax), %eax
	popq	%rbx
	popq	%r14
	popq	%rbp
	retq
LBB12_19:
	movq	(%rcx,%rax), %rax
	popq	%rbx
	popq	%r14
	popq	%rbp
	retq
	.cfi_endproc

_hdr_packed_value_at_percentile:        ## @hdr_packed_value_at_percentile
	.cfi_startproc
## %bb.0:
	movq	24(%rdi), %rax
	testq	%rax, %rax
	je	LBB15_15
## %bb.1:
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
	movsd	LCPI15_0(%rip), %xmm2           ## xmm2 = [1.0E+2,0.0E+0]
	movapd	%xmm0, %xmm3
	minsd	%xmm2, %xmm3
	cvtsi2sd	%rax, %xmm1
	divsd	%xmm2, %xmm3
	mulsd	%xmm1, %xmm3
	addsd	LCPI15_1(%rip), %xmm3
	movl	$1, %ecx
	ucomisd	LCPI15_2(%rip), %xmm3
	jb	LBB15_4
## %bb.2:
	ucomisd	%xmm1, %xmm3
	movq	%rax, %rcx
	jae	LBB15_4
## %bb.3:
	cvttsd2si	%xmm3, %rcx
LBB15_4:
	movq	(%rdi), %rbx
	movl	48(%rdi), %edx
	movq	8(%rdi), %rax
	movq	16(%rdi), %rsi
	movzbl	60(%rdi), %edi
	cmpl	$4, %edi
	movsd	%xmm0, -32(%rbp)                ## 8-byte Spill
	je	LBB15_26
## %bb.5:
	cmpl	$2, %edi
	je	LBB15_16
## %bb.6:
	cmpl	$1, %edi
	jne	LBB15_41
## %bb.7:
	leal	15(%rdx), %r9d
	testl	%edx, %edx
	cmovnsl	%edx, %r9d
	andl	$-16, %r9d
	jle	LBB15_56
## %bb.8:
	xorl	%r11d, %r11d
	xorpd	%xmm3, %xmm3
	movq	%rsi, %r14
	xorl	%r10d, %r10d
	xorl	%r8d, %r8d
LBB15_9:                                ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB15_12 Depth 2
	movdqu	(%rsi,%r10), %xmm1
	psadbw	%xmm3, %xmm1
	pshufd	$238, %xmm1, %xmm2              ## xmm2 = xmm1[2,3,2,3]
	paddq	%xmm1, %xmm2
	movq	%xmm2, %rdi
	movq	%rcx, %r15
	subq	%r8, %r15
	cmpq	%r15, %rdi
	jge	LBB15_11
## %bb.10:                              ##   in Loop: Header=BB15_9 Depth=1
	addq	%rdi, %r8
	jmp	LBB15_14
LBB15_11:                               ##   in Loop: Header=BB15_9 Depth=1
	xorl	%edi, %edi
	.p2align	4, 0x90
LBB15_12:                               ##   Parent Loop BB15_9 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%r8, %r15
	movzbl	(%r14,%rdi), %r8d
	addq	%r15, %r8
	cmpq	%rcx, %r8
	jge	LBB15_36
## %bb.13:                              ##   in Loop: Header=BB15_12 Depth=2
	incq	%rdi
	cmpq	$16, %rdi
	jne	LBB15_12
LBB15_14:                               ##   in Loop: Header=BB15_9 Depth=1
	addq	$16, %r10
	addq	$-16, %r11
	addq	$16, %r14
	cmpl	%r10d, %r9d
	jg	LBB15_9
	jmp	LBB15_57
LBB15_15:
	xorl	%eax, %eax
	retq
LBB15_16:
	leal	15(%rdx), %r9d
	testl	%edx, %edx
	cmovnsl	%edx, %r9d
	andl	$-16, %r9d
	jle	LBB15_46
## %bb.17:
	xorl	%r11d, %r11d
	movq	%rsi, %r14
	xorl	%r10d, %r10d
	xorl	%r8d, %r8d
LBB15_18:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB15_19 Depth 2
                                        ##     Child Loop BB15_23 Depth 2
	xorpd	%xmm2, %xmm2
	xorl	%edi, %edi
	.p2align	4, 0x90
LBB15_19:                               ##   Parent Loop BB15_18 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	pmovzxwq	(%r14,%rdi,2), %xmm1            ## xmm1 = mem[0],zero,zero,zero,mem[1],zero,zero,zero
	paddq	%xmm1, %xmm2
	addq	$2, %rdi
	cmpq	$16, %rdi
	jne	LBB15_19
## %bb.20:                              ##   in Loop: Header=BB15_18 Depth=1
	pshufd	$238, %xmm2, %xmm1              ## xmm1 = xmm2[2,3,2,3]
	paddq	%xmm2, %xmm1
	movq	%xmm1, %rdi
	movq	%rcx, %r15
	subq	%r8, %r15
	cmpq	%r15, %rdi
	jge	LBB15_22
## %bb.21:                              ##   in Loop: Header=BB15_18 Depth=1
	addq	%rdi, %r8
	jmp	LBB15_25
LBB15_22:                               ##   in Loop: Header=BB15_18 Depth=1
	xorl	%edi, %edi
	.p2align	4, 0x90
LBB15_23:                               ##   Parent Loop BB15_18 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%r8, %r15
	movzwl	(%r14,%rdi,2), %r8d
	addq	%r15, %r8
	cmpq	%rcx, %r8
	jge	LBB15_36
## %bb.24:                              ##   in Loop: Header=BB15_23 Depth=2
	incq	%rdi
	cmpq	$16, %rdi
	jne	LBB15_23
LBB15_25:                               ##   in Loop: Header=BB15_18 Depth=1
	addq	$16, %r10
	addq	$32, %r14
	addq	$-16, %r11
	cmpl	%r10d, %r9d
	jg	LBB15_18
	jmp	LBB15_47
LBB15_26:
	leal	15(%rdx), %r9d
	testl	%edx, %edx
	cmovnsl	%edx, %r9d
	andl	$-16, %r9d
	jle	LBB15_51
## %bb.27:
	xorl	%r11d, %r11d
	movq	%rsi, %r14
	xorl	%r10d, %r10d
	xorl	%r8d, %r8d
LBB15_28:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB15_29 Depth 2
                                        ##     Child Loop BB15_33 Depth 2
	xorpd	%xmm2, %xmm2
	xorl	%edi, %edi
	.p2align	4, 0x90
LBB15_29:                               ##   Parent Loop BB15_28 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	pmovzxdq	(%r14,%rdi,4), %xmm1            ## xmm1 = mem[0],zero,mem[1],zero
	paddq	%xmm1, %xmm2
	addq	$2, %rdi
	cmpq	$16, %rdi
	jne	LBB15_29
## %bb.30:                              ##   in Loop: Header=BB15_28 Depth=1
	pshufd	$238, %xmm2, %xmm1              ## xmm1 = xmm2[2,3,2,3]
	paddq	%xmm2, %xmm1
	movq	%xmm1, %rdi
	movq	%rcx, %r15
	subq	%r8, %r15
	cmpq	%r15, %rdi
	jge	LBB15_32
## %bb.31:                              ##   in Loop: Header=BB15_28 Depth=1
	addq	%rdi, %r8
	jmp	LBB15_35
LBB15_32:                               ##   in Loop: Header=BB15_28 Depth=1
	xorl	%edi, %edi
	.p2align	4, 0x90
LBB15_33:                               ##   Parent Loop BB15_28 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%r8, %r15
	movl	(%r14,%rdi,4), %r8d
	addq	%r15, %r8
	cmpq	%rcx, %r8
	jge	LBB15_36
## %bb.34:                              ##   in Loop: Header=BB15_33 Depth=2
	incq	%rdi
	cmpq	$16, %rdi
	jne	LBB15_33
LBB15_35:                               ##   in Loop: Header=BB15_28 Depth=1
	addq	$16, %r10
	addq	$64, %r14
	addq	$-16, %r11
	cmpl	%r10d, %r9d
	jg	LBB15_28
	jmp	LBB15_52
LBB15_36:
	subq	%r11, %rdi
LBB15_37:
	movl	(%rax,%rdi,4), %esi
	movq	%rbx, %rdi
	callq	_hdr_value_at_index
	movq	%rax, %r14
	jmp	LBB15_38
LBB15_41:
	testl	%edx, %edx
	jle	LBB15_64
## %bb.42:
	movabsq	$9223372036854775807, %r8       ## imm = 0x7FFFFFFFFFFFFFFF
	xorl	%r14d, %r14d
	xorl	%edi, %edi
	xorl	%r9d, %r9d
	.p2align	4, 0x90
LBB15_43:                               ## =>This Inner Loop Header: Depth=1
	movq	(%rsi,%rdi,8), %r10
	movq	%r8, %r11
	subq	%r9, %r11
	cmpq	%r11, %r10
	jg	LBB15_37
## %bb.44:                              ##   in Loop: Header=BB15_43 Depth=1
	addq	%r10, %r9
	cmpq	%rcx, %r9
	jge	LBB15_37
## %bb.45:                              ##   in Loop: Header=BB15_43 Depth=1
	incq	%rdi
	cmpq	%rdi, %rdx
	jne	LBB15_43
	jmp	LBB15_38
LBB15_46:
	xorl	%r10d, %r10d
	xorl	%r8d, %r8d
LBB15_47:
	cmpl	%edx, %r10d
	jge	LBB15_64
## %bb.48:
	movl	%r10d, %edi
	xorl	%r14d, %r14d
	.p2align	4, 0x90
LBB15_49:                               ## =>This Inner Loop Header: Depth=1
	movq	%r8, %r9
	movzwl	(%rsi,%rdi,2), %r8d
	addq	%r9, %r8
	cmpq	%rcx, %r8
	jge	LBB15_37
## %bb.50:                              ##   in Loop: Header=BB15_49 Depth=1
	incq	%rdi
	cmpl	%edi, %edx
	jg	LBB15_49
	jmp	LBB15_38
LBB15_51:
	xorl	%r10d, %r10d
	xorl	%r8d, %r8d
LBB15_52:
	cmpl	%edx, %r10d
	jge	LBB15_64
## %bb.53:
	movl	%r10d, %edi
	xorl	%r14d, %r14d
	.p2align	4, 0x90
LBB15_54:                               ## =>This Inner Loop Header: Depth=1
	movq	%r8, %r9
	movl	(%rsi,%rdi,4), %r8d
	addq	%r9, %r8
	cmpq	%rcx, %r8
	jge	LBB15_37
## %bb.55:                              ##   in Loop: Header=BB15_54 Depth=1
	incq	%rdi
	cmpl	%edi, %edx
	jg	LBB15_54
	jmp	LBB15_38
LBB15_56:
	xorl	%r10d, %r10d
	xorl	%r8d, %r8d
LBB15_57:
	cmpl	%edx, %r10d
	jge	LBB15_64
## %bb.58:
	movl	%r10d, %edi
	xorl	%r14d, %r14d
	.p2align	4, 0x90
LBB15_59:                               ## =>This Inner Loop Header: Depth=1
	movq	%r8, %r9
	movzbl	(%rsi,%rdi), %r8d
	addq	%r9, %r8
	cmpq	%rcx, %r8
	jge	LBB15_37
## %bb.60:                              ##   in Loop: Header=BB15_59 Depth=1
	incq	%rdi
	cmpl	%edi, %edx
	jg	LBB15_59
	jmp	LBB15_38
LBB15_64:
	xorl	%r14d, %r14d
LBB15_38:
	movq	%rbx, %rdi
	movq	%r14, %rsi
	callq	_hdr_lowest_equivalent_value
	xorpd	%xmm0, %xmm0
	movsd	-32(%rbp), %xmm1                ## 8-byte Reload
                                        ## xmm1 = mem[0],zero
	ucomisd	%xmm0, %xmm1
	jne	LBB15_39
	jnp	LBB15_40
LBB15_39:
	movq	%rbx, %rdi
	movq	%r14, %rsi
	movq	%rax, %rbx
	callq	_hdr_size_of_equivalent_value_range
	movabsq	$9223372036854775807, %rdx      ## imm = 0x7FFFFFFFFFFFFFFF
	movq	%rdx, %rsi
	subq	%rax, %rsi
	cmpq	%rsi, %rbx
	leaq	-1(%rbx,%rax), %rax
	cmovgq	%rdx, %rax
LBB15_40:
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
	movq	%rdx, -912(%rbp)                ## 8-byte Spill
	testq	%rdx, %rdx
	sete	%dl
	orb	%al, %dl
	movl	$22, %r12d
	jne	LBB16_4
## %bb.1:
	xorl	%r12d, %r12d
	testq	%rcx, %rcx
	je	LBB16_4
## %bb.2:
	movq	%rdi, %rbx
	movq	24(%rdi), %r15
	testq	%r15, %r15
	je	LBB16_3
## %bb.6:
	movq	(%rbx), %rax
	movq	%rax, -840(%rbp)                ## 8-byte Spill
	cmpq	$33, %rcx
	movq	%rcx, -832(%rbp)                ## 8-byte Spill
	movq	%rsi, -904(%rbp)                ## 8-byte Spill
	jb	LBB16_7
## %bb.8:
	movq	%rcx, %rax
	shrq	$61, %rax
	movl	$12, %r12d
	jne	LBB16_4
## %bb.9:
	movq	%rbx, -880(%rbp)                ## 8-byte Spill
	leaq	(,%rcx,8), %r13
	movq	%r13, %rdi
	callq	_malloc
	movq	%rax, %r14
	movq	%r13, %rdi
	callq	_malloc
	movq	%rax, %rbx
	movq	%r13, %rdi
	callq	_malloc
	movq	%rbx, %rdi
	movq	%rax, %r13
	testq	%r14, %r14
	setne	%al
	testq	%rbx, %rbx
	setne	%cl
	andb	%al, %cl
	testq	%r13, %r13
	setne	%al
	testb	%al, %cl
	jne	LBB16_10
## %bb.106:
	movq	%rdi, %rbx
	movq	%r14, %rdi
	jmp	LBB16_99
LBB16_3:
	shlq	$3, %rcx
	movq	-912(%rbp), %rdi                ## 8-byte Reload
	movq	%rcx, %rsi
	callq	___bzero
	jmp	LBB16_4
LBB16_7:
	leaq	-304(%rbp), %r14
	leaq	-560(%rbp), %rdi
	leaq	-816(%rbp), %r13
LBB16_11:
	cvtsi2sd	%r15, %xmm0
	movapd	%xmm0, -880(%rbp)               ## 16-byte Spill
	leaq	(,%rcx,8), %rsi
	movq	%rdi, -824(%rbp)                ## 8-byte Spill
	callq	___bzero
	movq	-832(%rbp), %r8                 ## 8-byte Reload
	cmpq	$1, %r8
	jne	LBB16_18
## %bb.12:
	xorl	%eax, %eax
	movq	-904(%rbp), %rsi                ## 8-byte Reload
	movapd	-880(%rbp), %xmm10              ## 16-byte Reload
	jmp	LBB16_13
LBB16_18:
	movq	%r8, %rax
	andq	$-2, %rax
	movapd	-880(%rbp), %xmm10              ## 16-byte Reload
	movddup	%xmm10, %xmm1                   ## xmm1 = xmm10[0,0]
	movq	%r15, %xmm0
	pshufd	$68, %xmm0, %xmm2               ## xmm2 = xmm0[0,1,0,1]
	pmovsxbq	LCPI16_9(%rip), %xmm3           ## xmm3 = [0,1]
	xorl	%ecx, %ecx
	movapd	LCPI16_1(%rip), %xmm4           ## xmm4 = [1.0E+2,1.0E+2]
	movapd	LCPI16_2(%rip), %xmm5           ## xmm5 = [5.0E-1,5.0E-1]
	movapd	LCPI16_3(%rip), %xmm6           ## xmm6 = [1.0E+0,1.0E+0]
	pmovsxbq	LCPI16_10(%rip), %xmm7          ## xmm7 = [2,2]
	movq	-904(%rbp), %rsi                ## 8-byte Reload
	.p2align	4, 0x90
LBB16_19:                               ## =>This Inner Loop Header: Depth=1
	movupd	(%rsi,%rcx,8), %xmm8
	minpd	%xmm4, %xmm8
	divpd	%xmm4, %xmm8
	mulpd	%xmm1, %xmm8
	addpd	%xmm5, %xmm8
	movapd	%xmm6, %xmm9
	cmplepd	%xmm8, %xmm9
	movapd	%xmm1, %xmm0
	cmplepd	%xmm8, %xmm0
	andpd	%xmm9, %xmm0
	maxpd	%xmm6, %xmm8
	cvttsd2si	%xmm8, %rdx
	movq	%rdx, %xmm9
	unpckhpd	%xmm8, %xmm8                    ## xmm8 = xmm8[1,1]
	cvttsd2si	%xmm8, %rdx
	movq	%rdx, %xmm8
	punpcklqdq	%xmm8, %xmm9            ## xmm9 = xmm9[0],xmm8[0]
	blendvpd	%xmm0, %xmm2, %xmm9
	movupd	%xmm9, (%r14,%rcx,8)
	movdqu	%xmm3, (%r13,%rcx,8)
	addq	$2, %rcx
	paddq	%xmm7, %xmm3
	cmpq	%rcx, %rax
	jne	LBB16_19
## %bb.20:
	cmpq	%r8, %rax
	jne	LBB16_13
LBB16_21:
	cmpq	$1, %r8
	jne	LBB16_22
LBB16_28:
	movslq	48(%rbx), %rax
	leal	15(%rax), %esi
	testq	%rax, %rax
	movq	8(%rbx), %rcx
	movq	%rcx, -880(%rbp)                ## 8-byte Spill
	movq	%rax, -856(%rbp)                ## 8-byte Spill
	cmovnsl	%eax, %esi
	movq	16(%rbx), %rdi
	andl	$-16, %esi
	movl	%esi, -848(%rbp)                ## 4-byte Spill
	movzbl	60(%rbx), %eax
	cmpl	$1, %eax
	movq	%rdi, -864(%rbp)                ## 8-byte Spill
	je	LBB16_40
## %bb.29:
	cmpl	$2, %eax
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	je	LBB16_59
## %bb.30:
	cmpl	$4, %eax
	jne	LBB16_92
## %bb.31:
	movq	(%r13), %rax
	movq	(%r14,%rax,8), %rcx
	cmpl	$0, -848(%rbp)                  ## 4-byte Folded Reload
	jle	LBB16_32
## %bb.80:
	xorl	%ebx, %ebx
	movq	%rdi, %r12
	xorl	%r15d, %r15d
	xorl	%r9d, %r9d
LBB16_81:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_82 Depth 2
                                        ##     Child Loop BB16_86 Depth 2
                                        ##       Child Loop BB16_88 Depth 3
	pxor	%xmm0, %xmm0
	xorl	%eax, %eax
	.p2align	4, 0x90
LBB16_82:                               ##   Parent Loop BB16_81 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	pmovzxdq	(%r12,%rax,4), %xmm1            ## xmm1 = mem[0],zero,mem[1],zero
	paddq	%xmm1, %xmm0
	addq	$2, %rax
	cmpq	$16, %rax
	jne	LBB16_82
## %bb.83:                              ##   in Loop: Header=BB16_81 Depth=1
	pshufd	$238, %xmm0, %xmm1              ## xmm1 = xmm0[2,3,2,3]
	paddq	%xmm0, %xmm1
	movq	%xmm1, %rax
	addq	%r9, %rax
	cmpq	%rcx, %rax
	jge	LBB16_85
## %bb.84:                              ##   in Loop: Header=BB16_81 Depth=1
	movq	%rax, %r9
LBB16_91:                               ##   in Loop: Header=BB16_81 Depth=1
	addq	$16, %rbx
	addq	$64, %r12
	cmpl	%ebx, -848(%rbp)                ## 4-byte Folded Reload
	jg	LBB16_81
	jmp	LBB16_33
LBB16_85:                               ##   in Loop: Header=BB16_81 Depth=1
	xorl	%r11d, %r11d
	jmp	LBB16_86
LBB16_90:                               ##   in Loop: Header=BB16_86 Depth=2
	incq	%r11
	cmpq	$16, %r11
	je	LBB16_91
LBB16_86:                               ##   Parent Loop BB16_81 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB16_88 Depth 3
	movq	%r9, %rdx
	movq	%r11, %rax
	orq	%rbx, %rax
	movl	(%rdi,%rax,4), %r9d
	addq	%rdx, %r9
	cmpq	%rcx, %r9
	jl	LBB16_90
## %bb.87:                              ##   in Loop: Header=BB16_86 Depth=2
	movq	-880(%rbp), %rcx                ## 8-byte Reload
	movl	(%rcx,%rax,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r9, -888(%rbp)                 ## 8-byte Spill
	movq	%r11, -896(%rbp)                ## 8-byte Spill
	callq	_hdr_value_at_index
	movq	-896(%rbp), %r11                ## 8-byte Reload
	movq	-888(%rbp), %r9                 ## 8-byte Reload
	movq	-864(%rbp), %rdi                ## 8-byte Reload
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r15,8), %rdx
	.p2align	4, 0x90
LBB16_88:                               ##   Parent Loop BB16_81 Depth=1
                                        ##     Parent Loop BB16_86 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movq	%rax, (%r8,%rdx,8)
	incq	%r15
	cmpq	%rsi, %r15
	jae	LBB16_93
## %bb.89:                              ##   in Loop: Header=BB16_88 Depth=3
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r9
	jge	LBB16_88
	jmp	LBB16_90
LBB16_13:
	movsd	LCPI16_5(%rip), %xmm0           ## xmm0 = [1.0E+2,0.0E+0]
	movsd	LCPI16_6(%rip), %xmm1           ## xmm1 = [5.0E-1,0.0E+0]
	movsd	LCPI16_7(%rip), %xmm2           ## xmm2 = [1.0E+0,0.0E+0]
	jmp	LBB16_14
	.p2align	4, 0x90
LBB16_17:                               ##   in Loop: Header=BB16_14 Depth=1
	movq	%rcx, (%r14,%rax,8)
	movq	%rax, (%r13,%rax,8)
	incq	%rax
	cmpq	%rax, %r8
	je	LBB16_21
LBB16_14:                               ## =>This Inner Loop Header: Depth=1
	movsd	(%rsi,%rax,8), %xmm3            ## xmm3 = mem[0],zero
	minsd	%xmm0, %xmm3
	divsd	%xmm0, %xmm3
	mulsd	%xmm10, %xmm3
	addsd	%xmm1, %xmm3
	movl	$1, %ecx
	ucomisd	%xmm2, %xmm3
	jb	LBB16_17
## %bb.15:                              ##   in Loop: Header=BB16_14 Depth=1
	ucomisd	%xmm10, %xmm3
	movq	%r15, %rcx
	jae	LBB16_17
## %bb.16:                              ##   in Loop: Header=BB16_14 Depth=1
	cvttsd2si	%xmm3, %rcx
	jmp	LBB16_17
LBB16_22:
	movl	$1, %eax
	jmp	LBB16_23
	.p2align	4, 0x90
LBB16_26:                               ##   in Loop: Header=BB16_23 Depth=1
	xorl	%edx, %edx
LBB16_27:                               ##   in Loop: Header=BB16_23 Depth=1
	movq	%rcx, (%r13,%rdx,8)
	incq	%rax
	cmpq	%r8, %rax
	je	LBB16_28
LBB16_23:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_24 Depth 2
	movq	(%r13,%rax,8), %rcx
	movq	(%r14,%rcx,8), %rsi
	movq	%rax, %rdx
	.p2align	4, 0x90
LBB16_24:                               ##   Parent Loop BB16_23 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	-8(%r13,%rdx,8), %rdi
	cmpq	%rsi, (%r14,%rdi,8)
	jle	LBB16_27
## %bb.25:                              ##   in Loop: Header=BB16_24 Depth=2
	movq	%rdi, (%r13,%rdx,8)
	decq	%rdx
	jne	LBB16_24
	jmp	LBB16_26
LBB16_59:
	movq	(%r13), %rax
	movq	(%r14,%rax,8), %rcx
	cmpl	$0, -848(%rbp)                  ## 4-byte Folded Reload
	jle	LBB16_60
## %bb.68:
	xorl	%ebx, %ebx
	movq	%rdi, %r12
	xorl	%r15d, %r15d
	xorl	%r9d, %r9d
LBB16_69:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_70 Depth 2
                                        ##     Child Loop BB16_74 Depth 2
                                        ##       Child Loop BB16_76 Depth 3
	pxor	%xmm0, %xmm0
	xorl	%eax, %eax
	.p2align	4, 0x90
LBB16_70:                               ##   Parent Loop BB16_69 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	pmovzxwq	(%r12,%rax,2), %xmm1            ## xmm1 = mem[0],zero,zero,zero,mem[1],zero,zero,zero
	paddq	%xmm1, %xmm0
	addq	$2, %rax
	cmpq	$16, %rax
	jne	LBB16_70
## %bb.71:                              ##   in Loop: Header=BB16_69 Depth=1
	pshufd	$238, %xmm0, %xmm1              ## xmm1 = xmm0[2,3,2,3]
	paddq	%xmm0, %xmm1
	movq	%xmm1, %rax
	addq	%r9, %rax
	cmpq	%rcx, %rax
	jge	LBB16_73
## %bb.72:                              ##   in Loop: Header=BB16_69 Depth=1
	movq	%rax, %r9
LBB16_79:                               ##   in Loop: Header=BB16_69 Depth=1
	addq	$16, %rbx
	addq	$32, %r12
	cmpl	%ebx, -848(%rbp)                ## 4-byte Folded Reload
	jg	LBB16_69
	jmp	LBB16_61
LBB16_73:                               ##   in Loop: Header=BB16_69 Depth=1
	xorl	%r11d, %r11d
	jmp	LBB16_74
LBB16_78:                               ##   in Loop: Header=BB16_74 Depth=2
	incq	%r11
	cmpq	$16, %r11
	je	LBB16_79
LBB16_74:                               ##   Parent Loop BB16_69 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB16_76 Depth 3
	movq	%r9, %rdx
	movq	%r11, %rax
	orq	%rbx, %rax
	movzwl	(%rdi,%rax,2), %r9d
	addq	%rdx, %r9
	cmpq	%rcx, %r9
	jl	LBB16_78
## %bb.75:                              ##   in Loop: Header=BB16_74 Depth=2
	movq	-880(%rbp), %rcx                ## 8-byte Reload
	movl	(%rcx,%rax,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r9, -888(%rbp)                 ## 8-byte Spill
	movq	%r11, -896(%rbp)                ## 8-byte Spill
	callq	_hdr_value_at_index
	movq	-896(%rbp), %r11                ## 8-byte Reload
	movq	-888(%rbp), %r9                 ## 8-byte Reload
	movq	-864(%rbp), %rdi                ## 8-byte Reload
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r15,8), %rdx
	.p2align	4, 0x90
LBB16_76:                               ##   Parent Loop BB16_69 Depth=1
                                        ##     Parent Loop BB16_74 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movq	%rax, (%r8,%rdx,8)
	incq	%r15
	cmpq	%rsi, %r15
	jae	LBB16_93
## %bb.77:                              ##   in Loop: Header=BB16_76 Depth=3
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r9
	jge	LBB16_76
	jmp	LBB16_78
LBB16_40:
	movq	(%r13), %rax
	movq	(%r14,%rax,8), %rcx
	cmpl	$0, -848(%rbp)                  ## 4-byte Folded Reload
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	jle	LBB16_41
## %bb.49:
	xorl	%r10d, %r10d
	pxor	%xmm2, %xmm2
	xorl	%r12d, %r12d
	xorl	%r15d, %r15d
LBB16_50:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_53 Depth 2
                                        ##       Child Loop BB16_55 Depth 3
	movdqu	(%rdi,%r10), %xmm0
	psadbw	%xmm2, %xmm0
	pshufd	$238, %xmm0, %xmm1              ## xmm1 = xmm0[2,3,2,3]
	paddq	%xmm0, %xmm1
	movq	%xmm1, %rax
	addq	%r12, %rax
	cmpq	%rcx, %rax
	jge	LBB16_52
## %bb.51:                              ##   in Loop: Header=BB16_50 Depth=1
	movq	%rax, %r12
LBB16_58:                               ##   in Loop: Header=BB16_50 Depth=1
	addq	$16, %r10
	cmpl	%r10d, -848(%rbp)               ## 4-byte Folded Reload
	jg	LBB16_50
	jmp	LBB16_42
LBB16_52:                               ##   in Loop: Header=BB16_50 Depth=1
	xorl	%ebx, %ebx
	movq	%r10, -888(%rbp)                ## 8-byte Spill
	jmp	LBB16_53
LBB16_57:                               ##   in Loop: Header=BB16_53 Depth=2
	incq	%rbx
	cmpq	$16, %rbx
	je	LBB16_58
LBB16_53:                               ##   Parent Loop BB16_50 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB16_55 Depth 3
	movq	%r12, %rdx
	movq	%rbx, %rax
	orq	%r10, %rax
	movzbl	(%rdi,%rax), %r12d
	addq	%rdx, %r12
	cmpq	%rcx, %r12
	jl	LBB16_57
## %bb.54:                              ##   in Loop: Header=BB16_53 Depth=2
	movq	-880(%rbp), %rcx                ## 8-byte Reload
	movl	(%rcx,%rax,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	callq	_hdr_value_at_index
	movq	-888(%rbp), %r10                ## 8-byte Reload
	pxor	%xmm2, %xmm2
	movq	-864(%rbp), %rdi                ## 8-byte Reload
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r15,8), %rdx
	.p2align	4, 0x90
LBB16_55:                               ##   Parent Loop BB16_50 Depth=1
                                        ##     Parent Loop BB16_53 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movq	%rax, (%r8,%rdx,8)
	incq	%r15
	cmpq	%rsi, %r15
	jae	LBB16_93
## %bb.56:                              ##   in Loop: Header=BB16_55 Depth=3
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r12
	jge	LBB16_55
	jmp	LBB16_57
LBB16_92:
	cmpl	$0, -856(%rbp)                  ## 4-byte Folded Reload
	jle	LBB16_93
## %bb.100:
	movq	(%r13), %rax
	movq	(%r14,%rax,8), %rcx
	xorl	%r15d, %r15d
	xorl	%r12d, %r12d
	xorl	%r9d, %r9d
	jmp	LBB16_101
LBB16_105:                              ##   in Loop: Header=BB16_101 Depth=1
	incq	%r15
	cmpq	-856(%rbp), %r15                ## 8-byte Folded Reload
	je	LBB16_93
LBB16_101:                              ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_103 Depth 2
	movq	(%rdi,%r15,8), %rax
	movabsq	$9223372036854775807, %rsi      ## imm = 0x7FFFFFFFFFFFFFFF
	movq	%rsi, %rdx
	subq	%r9, %rdx
	addq	%rax, %r9
	cmpq	%rdx, %rax
	movq	%r9, %rbx
	cmovgq	%rsi, %rbx
	cmpq	%rcx, %rbx
	jl	LBB16_105
## %bb.102:                             ##   in Loop: Header=BB16_101 Depth=1
	movq	-880(%rbp), %rax                ## 8-byte Reload
	movl	(%rax,%r15,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r9, -848(%rbp)                 ## 8-byte Spill
	callq	_hdr_value_at_index
	movq	-848(%rbp), %r9                 ## 8-byte Reload
	movq	-864(%rbp), %rdi                ## 8-byte Reload
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r12,8), %rdx
	.p2align	4, 0x90
LBB16_103:                              ##   Parent Loop BB16_101 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%rax, (%r8,%rdx,8)
	incq	%r12
	cmpq	%rsi, %r12
	jae	LBB16_93
## %bb.104:                             ##   in Loop: Header=BB16_103 Depth=2
	movq	(%r13,%r12,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %rbx
	jge	LBB16_103
	jmp	LBB16_105
LBB16_10:
	movq	-832(%rbp), %rcx                ## 8-byte Reload
	movq	-880(%rbp), %rbx                ## 8-byte Reload
	jmp	LBB16_11
LBB16_60:
	xorl	%r9d, %r9d
	xorl	%r15d, %r15d
	xorl	%ebx, %ebx
LBB16_61:
	cmpl	-856(%rbp), %ebx                ## 4-byte Folded Reload
	jge	LBB16_93
## %bb.62:
	movl	%ebx, %r12d
	jmp	LBB16_63
LBB16_67:                               ##   in Loop: Header=BB16_63 Depth=1
	incq	%r12
	cmpl	%r12d, -856(%rbp)               ## 4-byte Folded Reload
	jle	LBB16_93
LBB16_63:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_65 Depth 2
	movq	%r9, %rax
	movzwl	(%rdi,%r12,2), %r9d
	addq	%rax, %r9
	cmpq	%rcx, %r9
	jl	LBB16_67
## %bb.64:                              ##   in Loop: Header=BB16_63 Depth=1
	movq	-880(%rbp), %rax                ## 8-byte Reload
	movl	(%rax,%r12,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r9, %rbx
	callq	_hdr_value_at_index
	movq	%rbx, %r9
	movq	-864(%rbp), %rdi                ## 8-byte Reload
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r15,8), %rdx
LBB16_65:                               ##   Parent Loop BB16_63 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%rax, (%r8,%rdx,8)
	incq	%r15
	cmpq	%rsi, %r15
	jae	LBB16_93
## %bb.66:                              ##   in Loop: Header=BB16_65 Depth=2
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r9
	jge	LBB16_65
	jmp	LBB16_67
LBB16_41:
	xorl	%r10d, %r10d
	xorl	%r15d, %r15d
	xorl	%r12d, %r12d
LBB16_42:
	cmpl	-856(%rbp), %r10d               ## 4-byte Folded Reload
	jge	LBB16_93
## %bb.43:
	movl	%r10d, %ebx
	jmp	LBB16_44
LBB16_48:                               ##   in Loop: Header=BB16_44 Depth=1
	incq	%rbx
	cmpl	%ebx, -856(%rbp)                ## 4-byte Folded Reload
	jle	LBB16_93
LBB16_44:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_46 Depth 2
	movq	%r12, %rax
	movzbl	(%rdi,%rbx), %r12d
	addq	%rax, %r12
	cmpq	%rcx, %r12
	jl	LBB16_48
## %bb.45:                              ##   in Loop: Header=BB16_44 Depth=1
	movq	-880(%rbp), %rax                ## 8-byte Reload
	movl	(%rax,%rbx,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	callq	_hdr_value_at_index
	movq	-864(%rbp), %rdi                ## 8-byte Reload
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r15,8), %rdx
LBB16_46:                               ##   Parent Loop BB16_44 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%rax, (%r8,%rdx,8)
	incq	%r15
	cmpq	%rsi, %r15
	jae	LBB16_93
## %bb.47:                              ##   in Loop: Header=BB16_46 Depth=2
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r12
	jge	LBB16_46
	jmp	LBB16_48
LBB16_32:
	xorl	%r9d, %r9d
	xorl	%r15d, %r15d
	xorl	%ebx, %ebx
LBB16_33:
	cmpl	-856(%rbp), %ebx                ## 4-byte Folded Reload
	jge	LBB16_93
## %bb.34:
	movl	%ebx, %r12d
	jmp	LBB16_35
LBB16_39:                               ##   in Loop: Header=BB16_35 Depth=1
	incq	%r12
	cmpl	%r12d, -856(%rbp)               ## 4-byte Folded Reload
	jle	LBB16_93
LBB16_35:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_37 Depth 2
	movq	%r9, %rax
	movl	(%rdi,%r12,4), %r9d
	addq	%rax, %r9
	cmpq	%rcx, %r9
	jl	LBB16_39
## %bb.36:                              ##   in Loop: Header=BB16_35 Depth=1
	movq	-880(%rbp), %rax                ## 8-byte Reload
	movl	(%rax,%r12,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r9, %rbx
	callq	_hdr_value_at_index
	movq	%rbx, %r9
	movq	-864(%rbp), %rdi                ## 8-byte Reload
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r15,8), %rdx
LBB16_37:                               ##   Parent Loop BB16_35 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%rax, (%r8,%rdx,8)
	incq	%r15
	cmpq	%rsi, %r15
	jae	LBB16_93
## %bb.38:                              ##   in Loop: Header=BB16_37 Depth=2
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r9
	jge	LBB16_37
	jmp	LBB16_39
LBB16_93:
	xorl	%ebx, %ebx
	jmp	LBB16_94
	.p2align	4, 0x90
LBB16_96:                               ##   in Loop: Header=BB16_94 Depth=1
	movq	-912(%rbp), %rax                ## 8-byte Reload
	movq	%r12, (%rax,%rbx,8)
	incq	%rbx
	movq	-832(%rbp), %rax                ## 8-byte Reload
	cmpq	%rbx, %rax
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	je	LBB16_97
LBB16_94:                               ## =>This Inner Loop Header: Depth=1
	movq	-904(%rbp), %rax                ## 8-byte Reload
	movsd	(%rax,%rbx,8), %xmm0            ## xmm0 = mem[0],zero
	movsd	%xmm0, -880(%rbp)               ## 8-byte Spill
	movq	(%r8,%rbx,8), %r15
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r15, %rsi
	callq	_hdr_lowest_equivalent_value
	movq	%rax, %r12
	movsd	-880(%rbp), %xmm0               ## 8-byte Reload
                                        ## xmm0 = mem[0],zero
	ucomisd	LCPI16_8(%rip), %xmm0
	jne	LBB16_95
	jnp	LBB16_96
LBB16_95:                               ##   in Loop: Header=BB16_94 Depth=1
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r15, %rsi
	callq	_hdr_size_of_equivalent_value_range
	movabsq	$9223372036854775807, %rdx      ## imm = 0x7FFFFFFFFFFFFFFF
	movq	%rdx, %rcx
	subq	%rax, %rcx
	cmpq	%rcx, %r12
	leaq	-1(%r12,%rax), %r12
	cmovgq	%rdx, %r12
	jmp	LBB16_96
LBB16_97:
	xorl	%r12d, %r12d
	cmpq	$32, %rax
	jbe	LBB16_4
## %bb.98:
	movq	%r14, %rdi
	movq	%r8, %rbx
LBB16_99:
	callq	_free
	movq	%rbx, %rdi
	callq	_free
	movq	%r13, %rdi
	callq	_free
LBB16_4:
	movq	___stack_chk_guard@GOTPCREL(%rip), %rax
	movq	(%rax), %rax
	cmpq	-48(%rbp), %rax
	jne	LBB16_107
## %bb.5:
	movl	%r12d, %eax
	addq	$872, %rsp                      ## imm = 0x368
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
LBB16_107:
	callq	___stack_chk_fail
	.cfi_endproc
