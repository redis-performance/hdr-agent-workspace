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
	js	LBB12_13
## %bb.1:
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
	jae	LBB12_16
## %bb.2:
	movl	48(%rbx), %edx
	testl	%edx, %edx
	jle	LBB12_7
## %bb.3:
	movq	8(%rbx), %rsi
	xorl	%eax, %eax
	movl	%edx, %edi
	jmp	LBB12_5
	.p2align	4, 0x90
LBB12_4:                                ##   in Loop: Header=BB12_5 Depth=1
	movl	%r9d, %edi
	cmpl	%edi, %eax
	jge	LBB12_7
LBB12_5:                                ## =>This Inner Loop Header: Depth=1
	movl	%edi, %r8d
	subl	%eax, %r8d
	shrl	%r8d
	leal	(%r8,%rax), %r9d
	cmpl	%ecx, (%rsi,%r9,4)
	jge	LBB12_4
## %bb.6:                               ##   in Loop: Header=BB12_5 Depth=1
	addl	%r8d, %eax
	incl	%eax
	cmpl	%edi, %eax
	jl	LBB12_5
LBB12_7:
	cmpl	%edx, %eax
	jge	LBB12_15
## %bb.8:
	movq	8(%rbx), %rdx
	movl	%eax, %eax
	cmpl	%ecx, (%rdx,%rax,4)
	jne	LBB12_15
## %bb.9:
	movq	16(%rbx), %rcx
	movzbl	60(%rbx), %edx
	imulq	%rdx, %rax
	cmpl	$4, %edx
	je	LBB12_18
## %bb.10:
	cmpl	$2, %edx
	je	LBB12_17
## %bb.11:
	cmpl	$1, %edx
	jne	LBB12_19
## %bb.12:
	movzbl	(%rcx,%rax), %eax
	jmp	LBB12_16
LBB12_13:
	xorl	%eax, %eax
	retq
LBB12_15:
	xorl	%eax, %eax
LBB12_16:
	popq	%rbx
	popq	%r14
	popq	%rbp
	retq
LBB12_17:
	movzwl	(%rcx,%rax), %eax
	jmp	LBB12_16
LBB12_18:
	movl	(%rcx,%rax), %eax
	jmp	LBB12_16
LBB12_19:
	movq	(%rcx,%rax), %rax
	jmp	LBB12_16
	.cfi_endproc

_hdr_packed_value_at_percentile:        ## @hdr_packed_value_at_percentile
	.cfi_startproc
## %bb.0:
	movq	24(%rdi), %rax
	testq	%rax, %rax
	je	LBB15_9
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
	subq	$120, %rsp
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movsd	LCPI15_0(%rip), %xmm2           ## xmm2 = [1.0E+2,0.0E+0]
	movsd	%xmm0, -152(%rbp)               ## 8-byte Spill
	minsd	%xmm2, %xmm0
	cvtsi2sd	%rax, %xmm1
	divsd	%xmm2, %xmm0
	mulsd	%xmm1, %xmm0
	addsd	LCPI15_1(%rip), %xmm0
	movl	$1, %edx
	ucomisd	LCPI15_2(%rip), %xmm0
	jb	LBB15_4
## %bb.2:
	ucomisd	%xmm1, %xmm0
	movq	%rax, %rdx
	jae	LBB15_4
## %bb.3:
	cvttsd2si	%xmm0, %rdx
LBB15_4:
	movq	(%rdi), %rbx
	movl	48(%rdi), %r10d
	movq	8(%rdi), %rcx
	movq	16(%rdi), %r8
	movzbl	60(%rdi), %eax
	cmpl	$4, %eax
	movq	%rbx, -56(%rbp)                 ## 8-byte Spill
	movq	%rcx, -144(%rbp)                ## 8-byte Spill
	je	LBB15_51
## %bb.5:
	cmpl	$2, %eax
	je	LBB15_30
## %bb.6:
	cmpl	$1, %eax
	jne	LBB15_73
## %bb.7:
	leal	15(%r10), %eax
	testl	%r10d, %r10d
	cmovnsl	%r10d, %eax
	andl	$-16, %eax
	movl	%eax, -44(%rbp)                 ## 4-byte Spill
	jle	LBB15_86
## %bb.8:
	movq	%r10, -64(%rbp)                 ## 8-byte Spill
	xorl	%ecx, %ecx
	xorl	%edi, %edi
	jmp	LBB15_12
LBB15_9:
	xorl	%eax, %eax
	retq
	.p2align	4, 0x90
LBB15_10:                               ##   in Loop: Header=BB15_12 Depth=1
	addq	%rbx, %rdi
LBB15_11:                               ##   in Loop: Header=BB15_12 Depth=1
	addq	$16, %rcx
	cmpl	%ecx, -44(%rbp)                 ## 4-byte Folded Reload
	jle	LBB15_96
LBB15_12:                               ## =>This Inner Loop Header: Depth=1
	movzbl	(%r8,%rcx), %r12d
	movzbl	1(%r8,%rcx), %r13d
	movzbl	2(%r8,%rcx), %r15d
	movzbl	3(%r8,%rcx), %r14d
	leaq	(%r15,%r14), %rsi
	addq	%r13, %rsi
	addq	%r12, %rsi
	movzbl	4(%r8,%rcx), %r11d
	movzbl	5(%r8,%rcx), %r10d
	leaq	(%r11,%r10), %rbx
	movzbl	6(%r8,%rcx), %r9d
	addq	%r9, %rbx
	addq	%rsi, %rbx
	movzbl	7(%r8,%rcx), %esi
	movzbl	8(%r8,%rcx), %eax
	movq	%rax, -128(%rbp)                ## 8-byte Spill
	movq	%rsi, -136(%rbp)                ## 8-byte Spill
	addq	%rsi, %rax
	movzbl	9(%r8,%rcx), %esi
	movq	%rsi, -120(%rbp)                ## 8-byte Spill
	addq	%rsi, %rax
	movzbl	10(%r8,%rcx), %esi
	movq	%rsi, -112(%rbp)                ## 8-byte Spill
	addq	%rsi, %rax
	addq	%rbx, %rax
	movzbl	11(%r8,%rcx), %ebx
	movzbl	12(%r8,%rcx), %esi
	movq	%rsi, -96(%rbp)                 ## 8-byte Spill
	movq	%rbx, -104(%rbp)                ## 8-byte Spill
	addq	%rsi, %rbx
	movzbl	13(%r8,%rcx), %esi
	movq	%rsi, -88(%rbp)                 ## 8-byte Spill
	addq	%rsi, %rbx
	movzbl	14(%r8,%rcx), %esi
	movq	%rsi, -80(%rbp)                 ## 8-byte Spill
	addq	%rsi, %rbx
	movzbl	15(%r8,%rcx), %esi
	movq	%rsi, -72(%rbp)                 ## 8-byte Spill
	addq	%rsi, %rbx
	addq	%rax, %rbx
	movq	%rdx, %rax
	subq	%rdi, %rax
	cmpq	%rax, %rbx
	jl	LBB15_10
## %bb.13:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	%r12, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_100
## %bb.14:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	%r13, %rdi
	cmpq	%rdx, %rdi
	movq	-56(%rbp), %rbx                 ## 8-byte Reload
	jge	LBB15_103
## %bb.15:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	%r15, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_106
## %bb.16:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	%r14, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_109
## %bb.17:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	%r11, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_112
## %bb.18:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	%r10, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_115
## %bb.19:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	%r9, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_118
## %bb.20:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	-136(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_121
## %bb.21:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	-128(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_124
## %bb.22:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	-120(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_127
## %bb.23:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	-112(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_130
## %bb.24:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	-104(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_133
## %bb.25:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	-96(%rbp), %rdi                 ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_136
## %bb.26:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	-88(%rbp), %rdi                 ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_139
## %bb.27:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	-80(%rbp), %rdi                 ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_91
## %bb.28:                              ##   in Loop: Header=BB15_12 Depth=1
	addq	-72(%rbp), %rdi                 ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jl	LBB15_11
## %bb.29:
	addq	$15, %rcx
	movq	-56(%rbp), %rbx                 ## 8-byte Reload
	jmp	LBB15_140
LBB15_30:
	leal	15(%r10), %eax
	testl	%r10d, %r10d
	cmovnsl	%r10d, %eax
	andl	$-16, %eax
	movl	%eax, -44(%rbp)                 ## 4-byte Spill
	jle	LBB15_78
## %bb.31:
	movq	%r10, -64(%rbp)                 ## 8-byte Spill
	xorl	%ecx, %ecx
	xorl	%edi, %edi
	jmp	LBB15_34
	.p2align	4, 0x90
LBB15_32:                               ##   in Loop: Header=BB15_34 Depth=1
	addq	%rbx, %rdi
	movq	-56(%rbp), %rbx                 ## 8-byte Reload
LBB15_33:                               ##   in Loop: Header=BB15_34 Depth=1
	addq	$16, %rcx
	cmpl	%ecx, -44(%rbp)                 ## 4-byte Folded Reload
	jle	LBB15_92
LBB15_34:                               ## =>This Inner Loop Header: Depth=1
	movzwl	(%r8,%rcx,2), %r12d
	movzwl	2(%r8,%rcx,2), %r13d
	movzwl	4(%r8,%rcx,2), %r15d
	movzwl	6(%r8,%rcx,2), %r14d
	leaq	(%r15,%r14), %r9
	addq	%r13, %r9
	addq	%r12, %r9
	movzwl	8(%r8,%rcx,2), %r11d
	movzwl	10(%r8,%rcx,2), %r10d
	leaq	(%r11,%r10), %rbx
	movzwl	12(%r8,%rcx,2), %esi
	addq	%rsi, %rbx
	addq	%r9, %rbx
	movzwl	14(%r8,%rcx,2), %r9d
	movzwl	16(%r8,%rcx,2), %eax
	movq	%rax, -128(%rbp)                ## 8-byte Spill
	movq	%r9, -136(%rbp)                 ## 8-byte Spill
	addq	%r9, %rax
	movzwl	18(%r8,%rcx,2), %r9d
	movq	%r9, -120(%rbp)                 ## 8-byte Spill
	addq	%r9, %rax
	movzwl	20(%r8,%rcx,2), %r9d
	movq	%r9, -112(%rbp)                 ## 8-byte Spill
	addq	%r9, %rax
	addq	%rbx, %rax
	movzwl	22(%r8,%rcx,2), %ebx
	movzwl	24(%r8,%rcx,2), %r9d
	movq	%r9, -96(%rbp)                  ## 8-byte Spill
	movq	%rbx, -104(%rbp)                ## 8-byte Spill
	addq	%r9, %rbx
	movzwl	26(%r8,%rcx,2), %r9d
	movq	%r9, -88(%rbp)                  ## 8-byte Spill
	addq	%r9, %rbx
	movzwl	28(%r8,%rcx,2), %r9d
	movq	%r9, -80(%rbp)                  ## 8-byte Spill
	addq	%r9, %rbx
	movzwl	30(%r8,%rcx,2), %r9d
	movq	%r9, -72(%rbp)                  ## 8-byte Spill
	addq	%r9, %rbx
	addq	%rax, %rbx
	movq	%rdx, %rax
	subq	%rdi, %rax
	cmpq	%rax, %rbx
	jl	LBB15_32
## %bb.35:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	%r12, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_100
## %bb.36:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	%r13, %rdi
	cmpq	%rdx, %rdi
	movq	-56(%rbp), %rbx                 ## 8-byte Reload
	jge	LBB15_103
## %bb.37:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	%r15, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_106
## %bb.38:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	%r14, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_109
## %bb.39:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	%r11, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_112
## %bb.40:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	%r10, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_115
## %bb.41:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	%rsi, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_118
## %bb.42:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	-136(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_121
## %bb.43:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	-128(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_124
## %bb.44:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	-120(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_127
## %bb.45:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	-112(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_130
## %bb.46:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	-104(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_133
## %bb.47:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	-96(%rbp), %rdi                 ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_136
## %bb.48:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	-88(%rbp), %rdi                 ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_139
## %bb.49:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	-80(%rbp), %rdi                 ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_91
## %bb.50:                              ##   in Loop: Header=BB15_34 Depth=1
	addq	-72(%rbp), %rdi                 ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jl	LBB15_33
	jmp	LBB15_72
LBB15_51:
	leal	15(%r10), %eax
	testl	%r10d, %r10d
	cmovnsl	%r10d, %eax
	andl	$-16, %eax
	movl	%eax, -44(%rbp)                 ## 4-byte Spill
	jle	LBB15_82
## %bb.52:
	movq	%r10, -64(%rbp)                 ## 8-byte Spill
	xorl	%ecx, %ecx
	xorl	%edi, %edi
	jmp	LBB15_55
	.p2align	4, 0x90
LBB15_53:                               ##   in Loop: Header=BB15_55 Depth=1
	addq	%rbx, %rdi
	movq	-56(%rbp), %rbx                 ## 8-byte Reload
LBB15_54:                               ##   in Loop: Header=BB15_55 Depth=1
	addq	$16, %rcx
	cmpl	%ecx, -44(%rbp)                 ## 4-byte Folded Reload
	jle	LBB15_94
LBB15_55:                               ## =>This Inner Loop Header: Depth=1
	movl	(%r8,%rcx,4), %r12d
	movl	4(%r8,%rcx,4), %r13d
	movl	8(%r8,%rcx,4), %r15d
	movl	12(%r8,%rcx,4), %r14d
	leaq	(%r15,%r14), %r9
	addq	%r13, %r9
	addq	%r12, %r9
	movl	16(%r8,%rcx,4), %r11d
	movl	20(%r8,%rcx,4), %r10d
	leaq	(%r11,%r10), %rbx
	movl	24(%r8,%rcx,4), %esi
	addq	%rsi, %rbx
	addq	%r9, %rbx
	movl	28(%r8,%rcx,4), %r9d
	movl	32(%r8,%rcx,4), %eax
	movq	%rax, -128(%rbp)                ## 8-byte Spill
	movq	%r9, -136(%rbp)                 ## 8-byte Spill
	addq	%r9, %rax
	movl	36(%r8,%rcx,4), %r9d
	movq	%r9, -120(%rbp)                 ## 8-byte Spill
	addq	%r9, %rax
	movl	40(%r8,%rcx,4), %r9d
	movq	%r9, -112(%rbp)                 ## 8-byte Spill
	addq	%r9, %rax
	addq	%rbx, %rax
	movl	44(%r8,%rcx,4), %ebx
	movl	48(%r8,%rcx,4), %r9d
	movq	%r9, -96(%rbp)                  ## 8-byte Spill
	movq	%rbx, -104(%rbp)                ## 8-byte Spill
	addq	%r9, %rbx
	movl	52(%r8,%rcx,4), %r9d
	movq	%r9, -88(%rbp)                  ## 8-byte Spill
	addq	%r9, %rbx
	movl	56(%r8,%rcx,4), %r9d
	movq	%r9, -80(%rbp)                  ## 8-byte Spill
	addq	%r9, %rbx
	movl	60(%r8,%rcx,4), %r9d
	movq	%r9, -72(%rbp)                  ## 8-byte Spill
	addq	%r9, %rbx
	addq	%rax, %rbx
	movq	%rdx, %rax
	subq	%rdi, %rax
	cmpq	%rax, %rbx
	jl	LBB15_53
## %bb.56:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	%r12, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_100
## %bb.57:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	%r13, %rdi
	cmpq	%rdx, %rdi
	movq	-56(%rbp), %rbx                 ## 8-byte Reload
	jge	LBB15_103
## %bb.58:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	%r15, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_106
## %bb.59:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	%r14, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_109
## %bb.60:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	%r11, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_112
## %bb.61:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	%r10, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_115
## %bb.62:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	%rsi, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_118
## %bb.63:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	-136(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_121
## %bb.64:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	-128(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_124
## %bb.65:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	-120(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_127
## %bb.66:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	-112(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_130
## %bb.67:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	-104(%rbp), %rdi                ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_133
## %bb.68:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	-96(%rbp), %rdi                 ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_136
## %bb.69:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	-88(%rbp), %rdi                 ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_139
## %bb.70:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	-80(%rbp), %rdi                 ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jge	LBB15_91
## %bb.71:                              ##   in Loop: Header=BB15_55 Depth=1
	addq	-72(%rbp), %rdi                 ## 8-byte Folded Reload
	cmpq	%rdx, %rdi
	jl	LBB15_54
LBB15_72:
	addq	$15, %rcx
	jmp	LBB15_140
LBB15_73:
	testl	%r10d, %r10d
	jle	LBB15_97
## %bb.74:
	movabsq	$9223372036854775807, %rax      ## imm = 0x7FFFFFFFFFFFFFFF
	xorl	%r14d, %r14d
	xorl	%ecx, %ecx
	xorl	%esi, %esi
	.p2align	4, 0x90
LBB15_75:                               ## =>This Inner Loop Header: Depth=1
	movq	(%r8,%rcx,8), %rdi
	movq	%rax, %r9
	subq	%rsi, %r9
	cmpq	%r9, %rdi
	jg	LBB15_140
## %bb.76:                              ##   in Loop: Header=BB15_75 Depth=1
	addq	%rdi, %rsi
	cmpq	%rdx, %rsi
	jge	LBB15_140
## %bb.77:                              ##   in Loop: Header=BB15_75 Depth=1
	incq	%rcx
	cmpq	%rcx, %r10
	jne	LBB15_75
	jmp	LBB15_141
LBB15_78:
	xorl	%ecx, %ecx
	xorl	%edi, %edi
	cmpl	%r10d, %ecx
	jge	LBB15_97
LBB15_79:
	movl	%ecx, %ecx
	xorl	%r14d, %r14d
	.p2align	4, 0x90
LBB15_80:                               ## =>This Inner Loop Header: Depth=1
	movq	%rdi, %rax
	movzwl	(%r8,%rcx,2), %edi
	addq	%rax, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_140
## %bb.81:                              ##   in Loop: Header=BB15_80 Depth=1
	incq	%rcx
	cmpl	%ecx, %r10d
	jg	LBB15_80
	jmp	LBB15_141
LBB15_82:
	xorl	%ecx, %ecx
	xorl	%edi, %edi
	cmpl	%r10d, %ecx
	jge	LBB15_97
LBB15_83:
	movl	%ecx, %ecx
	xorl	%r14d, %r14d
	.p2align	4, 0x90
LBB15_84:                               ## =>This Inner Loop Header: Depth=1
	movq	%rdi, %rax
	movl	(%r8,%rcx,4), %edi
	addq	%rax, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_140
## %bb.85:                              ##   in Loop: Header=BB15_84 Depth=1
	incq	%rcx
	cmpl	%ecx, %r10d
	jg	LBB15_84
	jmp	LBB15_141
LBB15_86:
	xorl	%ecx, %ecx
	xorl	%edi, %edi
	cmpl	%r10d, %ecx
	jge	LBB15_97
LBB15_87:
	movl	%ecx, %ecx
	xorl	%r14d, %r14d
	.p2align	4, 0x90
LBB15_88:                               ## =>This Inner Loop Header: Depth=1
	movq	%rdi, %rax
	movzbl	(%r8,%rcx), %edi
	addq	%rax, %rdi
	cmpq	%rdx, %rdi
	jge	LBB15_140
## %bb.89:                              ##   in Loop: Header=BB15_88 Depth=1
	incq	%rcx
	cmpl	%ecx, %r10d
	jg	LBB15_88
	jmp	LBB15_141
LBB15_100:
	movq	-56(%rbp), %rbx                 ## 8-byte Reload
	jmp	LBB15_140
LBB15_103:
	incq	%rcx
	jmp	LBB15_140
LBB15_106:
	addq	$2, %rcx
	jmp	LBB15_140
LBB15_109:
	addq	$3, %rcx
	jmp	LBB15_140
LBB15_112:
	addq	$4, %rcx
	jmp	LBB15_140
LBB15_115:
	addq	$5, %rcx
	jmp	LBB15_140
LBB15_118:
	addq	$6, %rcx
	jmp	LBB15_140
LBB15_121:
	addq	$7, %rcx
	jmp	LBB15_140
LBB15_124:
	addq	$8, %rcx
	jmp	LBB15_140
LBB15_127:
	addq	$9, %rcx
	jmp	LBB15_140
LBB15_130:
	addq	$10, %rcx
	jmp	LBB15_140
LBB15_133:
	addq	$11, %rcx
	jmp	LBB15_140
LBB15_136:
	addq	$12, %rcx
	jmp	LBB15_140
LBB15_139:
	addq	$13, %rcx
	jmp	LBB15_140
LBB15_91:
	addq	$14, %rcx
LBB15_140:
	movq	-144(%rbp), %rax                ## 8-byte Reload
	movl	(%rax,%rcx,4), %esi
	movq	%rbx, %rdi
	callq	_hdr_value_at_index
	movq	%rax, %r14
	jmp	LBB15_141
LBB15_92:
	movq	-64(%rbp), %r10                 ## 8-byte Reload
	cmpl	%r10d, %ecx
	jl	LBB15_79
	jmp	LBB15_97
LBB15_94:
	movq	-64(%rbp), %r10                 ## 8-byte Reload
	cmpl	%r10d, %ecx
	jl	LBB15_83
	jmp	LBB15_97
LBB15_96:
	movq	-56(%rbp), %rbx                 ## 8-byte Reload
	movq	-64(%rbp), %r10                 ## 8-byte Reload
	cmpl	%r10d, %ecx
	jl	LBB15_87
LBB15_97:
	xorl	%r14d, %r14d
LBB15_141:
	movq	%rbx, %rdi
	movq	%r14, %rsi
	callq	_hdr_lowest_equivalent_value
	xorpd	%xmm0, %xmm0
	movsd	-152(%rbp), %xmm1               ## 8-byte Reload
                                        ## xmm1 = mem[0],zero
	ucomisd	%xmm0, %xmm1
	jne	LBB15_142
	jnp	LBB15_143
LBB15_142:
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
LBB15_143:
	addq	$120, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
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
	movq	%rsi, -896(%rbp)                ## 8-byte Spill
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
## %bb.102:
	movq	%rdi, %rbx
	movq	%r14, %rdi
	jmp	LBB16_95
LBB16_3:
	shlq	$3, %rcx
	movq	-904(%rbp), %rdi                ## 8-byte Reload
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
	movq	-896(%rbp), %rsi                ## 8-byte Reload
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
	movq	-896(%rbp), %rsi                ## 8-byte Reload
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
	jne	LBB16_88
## %bb.31:
	movq	(%r13), %rax
	movq	(%r14,%rax,8), %rcx
	cmpl	$0, -848(%rbp)                  ## 4-byte Folded Reload
	jle	LBB16_32
## %bb.78:
	xorl	%r9d, %r9d
	xorl	%r12d, %r12d
	xorl	%r15d, %r15d
LBB16_79:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_82 Depth 2
                                        ##       Child Loop BB16_84 Depth 3
	pmovzxdq	40(%rdi,%r9,4), %xmm0           ## xmm0 = mem[0],zero,mem[1],zero
	pmovzxdq	8(%rdi,%r9,4), %xmm1            ## xmm1 = mem[0],zero,mem[1],zero
	pmovzxdq	56(%rdi,%r9,4), %xmm2           ## xmm2 = mem[0],zero,mem[1],zero
	pmovzxdq	24(%rdi,%r9,4), %xmm3           ## xmm3 = mem[0],zero,mem[1],zero
	paddq	%xmm0, %xmm1
	paddq	%xmm2, %xmm3
	pmovzxdq	32(%rdi,%r9,4), %xmm0           ## xmm0 = mem[0],zero,mem[1],zero
	paddq	%xmm1, %xmm3
	pmovzxdq	(%rdi,%r9,4), %xmm1             ## xmm1 = mem[0],zero,mem[1],zero
	paddq	%xmm0, %xmm1
	pmovzxdq	48(%rdi,%r9,4), %xmm0           ## xmm0 = mem[0],zero,mem[1],zero
	pmovzxdq	16(%rdi,%r9,4), %xmm2           ## xmm2 = mem[0],zero,mem[1],zero
	paddq	%xmm0, %xmm2
	paddq	%xmm1, %xmm2
	paddq	%xmm3, %xmm2
	pshufd	$238, %xmm2, %xmm0              ## xmm0 = xmm2[2,3,2,3]
	paddq	%xmm2, %xmm0
	movq	%xmm0, %rax
	addq	%r15, %rax
	cmpq	%rcx, %rax
	jge	LBB16_81
## %bb.80:                              ##   in Loop: Header=BB16_79 Depth=1
	movq	%rax, %r15
LBB16_87:                               ##   in Loop: Header=BB16_79 Depth=1
	addq	$16, %r9
	cmpl	%r9d, -848(%rbp)                ## 4-byte Folded Reload
	jg	LBB16_79
	jmp	LBB16_33
LBB16_81:                               ##   in Loop: Header=BB16_79 Depth=1
	xorl	%ebx, %ebx
	movq	%r9, -888(%rbp)                 ## 8-byte Spill
	jmp	LBB16_82
LBB16_86:                               ##   in Loop: Header=BB16_82 Depth=2
	incq	%rbx
	cmpq	$16, %rbx
	je	LBB16_87
LBB16_82:                               ##   Parent Loop BB16_79 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB16_84 Depth 3
	movq	%r15, %rdx
	movq	%rbx, %rax
	orq	%r9, %rax
	movl	(%rdi,%rax,4), %r15d
	addq	%rdx, %r15
	cmpq	%rcx, %r15
	jl	LBB16_86
## %bb.83:                              ##   in Loop: Header=BB16_82 Depth=2
	movq	-880(%rbp), %rcx                ## 8-byte Reload
	movl	(%rcx,%rax,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	callq	_hdr_value_at_index
	movq	-888(%rbp), %r9                 ## 8-byte Reload
	movq	-864(%rbp), %rdi                ## 8-byte Reload
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r12,8), %rdx
	.p2align	4, 0x90
LBB16_84:                               ##   Parent Loop BB16_79 Depth=1
                                        ##     Parent Loop BB16_82 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movq	%rax, (%r8,%rdx,8)
	incq	%r12
	cmpq	%rsi, %r12
	jae	LBB16_89
## %bb.85:                              ##   in Loop: Header=BB16_84 Depth=3
	movq	(%r13,%r12,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r15
	jge	LBB16_84
	jmp	LBB16_86
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
	xorl	%r9d, %r9d
	xorl	%r12d, %r12d
	xorl	%r15d, %r15d
LBB16_69:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_72 Depth 2
                                        ##       Child Loop BB16_74 Depth 3
	pmovzxwq	20(%rdi,%r9,2), %xmm0           ## xmm0 = mem[0],zero,zero,zero,mem[1],zero,zero,zero
	pmovzxwq	4(%rdi,%r9,2), %xmm1            ## xmm1 = mem[0],zero,zero,zero,mem[1],zero,zero,zero
	pmovzxwq	28(%rdi,%r9,2), %xmm2           ## xmm2 = mem[0],zero,zero,zero,mem[1],zero,zero,zero
	pmovzxwq	12(%rdi,%r9,2), %xmm3           ## xmm3 = mem[0],zero,zero,zero,mem[1],zero,zero,zero
	paddq	%xmm0, %xmm1
	paddq	%xmm2, %xmm3
	pmovzxwq	16(%rdi,%r9,2), %xmm0           ## xmm0 = mem[0],zero,zero,zero,mem[1],zero,zero,zero
	paddq	%xmm1, %xmm3
	pmovzxwq	(%rdi,%r9,2), %xmm1             ## xmm1 = mem[0],zero,zero,zero,mem[1],zero,zero,zero
	paddq	%xmm0, %xmm1
	pmovzxwq	24(%rdi,%r9,2), %xmm0           ## xmm0 = mem[0],zero,zero,zero,mem[1],zero,zero,zero
	pmovzxwq	8(%rdi,%r9,2), %xmm2            ## xmm2 = mem[0],zero,zero,zero,mem[1],zero,zero,zero
	paddq	%xmm0, %xmm2
	paddq	%xmm1, %xmm2
	paddq	%xmm3, %xmm2
	pshufd	$238, %xmm2, %xmm0              ## xmm0 = xmm2[2,3,2,3]
	paddq	%xmm2, %xmm0
	movq	%xmm0, %rax
	addq	%r15, %rax
	cmpq	%rcx, %rax
	jge	LBB16_71
## %bb.70:                              ##   in Loop: Header=BB16_69 Depth=1
	movq	%rax, %r15
LBB16_77:                               ##   in Loop: Header=BB16_69 Depth=1
	addq	$16, %r9
	cmpl	%r9d, -848(%rbp)                ## 4-byte Folded Reload
	jg	LBB16_69
	jmp	LBB16_61
LBB16_71:                               ##   in Loop: Header=BB16_69 Depth=1
	xorl	%ebx, %ebx
	movq	%r9, -888(%rbp)                 ## 8-byte Spill
	jmp	LBB16_72
LBB16_76:                               ##   in Loop: Header=BB16_72 Depth=2
	incq	%rbx
	cmpq	$16, %rbx
	je	LBB16_77
LBB16_72:                               ##   Parent Loop BB16_69 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB16_74 Depth 3
	movq	%r15, %rdx
	movq	%rbx, %rax
	orq	%r9, %rax
	movzwl	(%rdi,%rax,2), %r15d
	addq	%rdx, %r15
	cmpq	%rcx, %r15
	jl	LBB16_76
## %bb.73:                              ##   in Loop: Header=BB16_72 Depth=2
	movq	-880(%rbp), %rcx                ## 8-byte Reload
	movl	(%rcx,%rax,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	callq	_hdr_value_at_index
	movq	-888(%rbp), %r9                 ## 8-byte Reload
	movq	-864(%rbp), %rdi                ## 8-byte Reload
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r12,8), %rdx
	.p2align	4, 0x90
LBB16_74:                               ##   Parent Loop BB16_69 Depth=1
                                        ##     Parent Loop BB16_72 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	movq	%rax, (%r8,%rdx,8)
	incq	%r12
	cmpq	%rsi, %r12
	jae	LBB16_89
## %bb.75:                              ##   in Loop: Header=BB16_74 Depth=3
	movq	(%r13,%r12,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r15
	jge	LBB16_74
	jmp	LBB16_76
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
	jae	LBB16_89
## %bb.56:                              ##   in Loop: Header=BB16_55 Depth=3
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r12
	jge	LBB16_55
	jmp	LBB16_57
LBB16_88:
	cmpl	$0, -856(%rbp)                  ## 4-byte Folded Reload
	jle	LBB16_89
## %bb.96:
	movq	(%r13), %rax
	movq	(%r14,%rax,8), %rcx
	xorl	%r15d, %r15d
	xorl	%r12d, %r12d
	xorl	%r9d, %r9d
	jmp	LBB16_97
LBB16_101:                              ##   in Loop: Header=BB16_97 Depth=1
	incq	%r15
	cmpq	-856(%rbp), %r15                ## 8-byte Folded Reload
	je	LBB16_89
LBB16_97:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_99 Depth 2
	movq	(%rdi,%r15,8), %rax
	movabsq	$9223372036854775807, %rsi      ## imm = 0x7FFFFFFFFFFFFFFF
	movq	%rsi, %rdx
	subq	%r9, %rdx
	addq	%rax, %r9
	cmpq	%rdx, %rax
	movq	%r9, %rbx
	cmovgq	%rsi, %rbx
	cmpq	%rcx, %rbx
	jl	LBB16_101
## %bb.98:                              ##   in Loop: Header=BB16_97 Depth=1
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
LBB16_99:                               ##   Parent Loop BB16_97 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%rax, (%r8,%rdx,8)
	incq	%r12
	cmpq	%rsi, %r12
	jae	LBB16_89
## %bb.100:                             ##   in Loop: Header=BB16_99 Depth=2
	movq	(%r13,%r12,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %rbx
	jge	LBB16_99
	jmp	LBB16_101
LBB16_10:
	movq	-832(%rbp), %rcx                ## 8-byte Reload
	movq	-880(%rbp), %rbx                ## 8-byte Reload
	jmp	LBB16_11
LBB16_60:
	xorl	%r15d, %r15d
	xorl	%r12d, %r12d
	xorl	%r9d, %r9d
LBB16_61:
	cmpl	-856(%rbp), %r9d                ## 4-byte Folded Reload
	jge	LBB16_89
## %bb.62:
	movl	%r9d, %ebx
	jmp	LBB16_63
LBB16_67:                               ##   in Loop: Header=BB16_63 Depth=1
	incq	%rbx
	cmpl	%ebx, -856(%rbp)                ## 4-byte Folded Reload
	jle	LBB16_89
LBB16_63:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_65 Depth 2
	movq	%r15, %rax
	movzwl	(%rdi,%rbx,2), %r15d
	addq	%rax, %r15
	cmpq	%rcx, %r15
	jl	LBB16_67
## %bb.64:                              ##   in Loop: Header=BB16_63 Depth=1
	movq	-880(%rbp), %rax                ## 8-byte Reload
	movl	(%rax,%rbx,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	callq	_hdr_value_at_index
	movq	-864(%rbp), %rdi                ## 8-byte Reload
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r12,8), %rdx
LBB16_65:                               ##   Parent Loop BB16_63 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%rax, (%r8,%rdx,8)
	incq	%r12
	cmpq	%rsi, %r12
	jae	LBB16_89
## %bb.66:                              ##   in Loop: Header=BB16_65 Depth=2
	movq	(%r13,%r12,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r15
	jge	LBB16_65
	jmp	LBB16_67
LBB16_41:
	xorl	%r10d, %r10d
	xorl	%r15d, %r15d
	xorl	%r12d, %r12d
LBB16_42:
	cmpl	-856(%rbp), %r10d               ## 4-byte Folded Reload
	jge	LBB16_89
## %bb.43:
	movl	%r10d, %ebx
	jmp	LBB16_44
LBB16_48:                               ##   in Loop: Header=BB16_44 Depth=1
	incq	%rbx
	cmpl	%ebx, -856(%rbp)                ## 4-byte Folded Reload
	jle	LBB16_89
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
	jae	LBB16_89
## %bb.47:                              ##   in Loop: Header=BB16_46 Depth=2
	movq	(%r13,%r15,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r12
	jge	LBB16_46
	jmp	LBB16_48
LBB16_32:
	xorl	%r15d, %r15d
	xorl	%r12d, %r12d
	xorl	%r9d, %r9d
LBB16_33:
	cmpl	-856(%rbp), %r9d                ## 4-byte Folded Reload
	jge	LBB16_89
## %bb.34:
	movl	%r9d, %ebx
	jmp	LBB16_35
LBB16_39:                               ##   in Loop: Header=BB16_35 Depth=1
	incq	%rbx
	cmpl	%ebx, -856(%rbp)                ## 4-byte Folded Reload
	jle	LBB16_89
LBB16_35:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB16_37 Depth 2
	movq	%r15, %rax
	movl	(%rdi,%rbx,4), %r15d
	addq	%rax, %r15
	cmpq	%rcx, %r15
	jl	LBB16_39
## %bb.36:                              ##   in Loop: Header=BB16_35 Depth=1
	movq	-880(%rbp), %rax                ## 8-byte Reload
	movl	(%rax,%rbx,4), %esi
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	callq	_hdr_value_at_index
	movq	-864(%rbp), %rdi                ## 8-byte Reload
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	movq	-832(%rbp), %rsi                ## 8-byte Reload
	movq	(%r13,%r12,8), %rdx
LBB16_37:                               ##   Parent Loop BB16_35 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	movq	%rax, (%r8,%rdx,8)
	incq	%r12
	cmpq	%rsi, %r12
	jae	LBB16_89
## %bb.38:                              ##   in Loop: Header=BB16_37 Depth=2
	movq	(%r13,%r12,8), %rdx
	movq	(%r14,%rdx,8), %rcx
	cmpq	%rcx, %r15
	jge	LBB16_37
	jmp	LBB16_39
LBB16_89:
	xorl	%ebx, %ebx
	jmp	LBB16_90
	.p2align	4, 0x90
LBB16_92:                               ##   in Loop: Header=BB16_90 Depth=1
	movq	-904(%rbp), %rax                ## 8-byte Reload
	movq	%r12, (%rax,%rbx,8)
	incq	%rbx
	movq	-832(%rbp), %rax                ## 8-byte Reload
	cmpq	%rbx, %rax
	movq	-824(%rbp), %r8                 ## 8-byte Reload
	je	LBB16_93
LBB16_90:                               ## =>This Inner Loop Header: Depth=1
	movq	-896(%rbp), %rax                ## 8-byte Reload
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
	jne	LBB16_91
	jnp	LBB16_92
LBB16_91:                               ##   in Loop: Header=BB16_90 Depth=1
	movq	-840(%rbp), %rdi                ## 8-byte Reload
	movq	%r15, %rsi
	callq	_hdr_size_of_equivalent_value_range
	movabsq	$9223372036854775807, %rdx      ## imm = 0x7FFFFFFFFFFFFFFF
	movq	%rdx, %rcx
	subq	%rax, %rcx
	cmpq	%rcx, %r12
	leaq	-1(%r12,%rax), %r12
	cmovgq	%rdx, %r12
	jmp	LBB16_92
LBB16_93:
	xorl	%r12d, %r12d
	cmpq	$32, %rax
	jbe	LBB16_4
## %bb.94:
	movq	%r14, %rdi
	movq	%r8, %rbx
LBB16_95:
	callq	_free
	movq	%rbx, %rdi
	callq	_free
	movq	%r13, %rdi
	callq	_free
LBB16_4:
	movq	___stack_chk_guard@GOTPCREL(%rip), %rax
	movq	(%rax), %rax
	cmpq	-48(%rbp), %rax
	jne	LBB16_103
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
LBB16_103:
	callq	___stack_chk_fail
	.cfi_endproc
