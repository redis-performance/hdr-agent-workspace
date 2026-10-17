_hdr_value_at_percentile:               ## @hdr_value_at_percentile
	.cfi_startproc
## %bb.0:
	movq	88(%rdi), %rax
	testq	%rax, %rax
	je	LBB32_1
## %bb.3:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%rbx
	pushq	%rax
	.cfi_offset %rbx, -24
	movq	%rdi, %rbx
	movsd	LCPI32_0(%rip), %xmm1           ## xmm1 = [1.0E+2,0.0E+0]
	movapd	%xmm0, %xmm2
	minsd	%xmm1, %xmm2
	divsd	%xmm1, %xmm2
	cvtsi2sd	%rax, %xmm1
	mulsd	%xmm1, %xmm2
	addsd	LCPI32_1(%rip), %xmm2
	pushq	$1
	popq	%rsi
	ucomisd	LCPI32_2(%rip), %xmm2
	movq	%rsi, %rcx
	jb	LBB32_6
## %bb.4:
	ucomisd	%xmm1, %xmm2
	movq	%rax, %rcx
	jae	LBB32_6
## %bb.5:
	cvttsd2si	%xmm2, %rcx
LBB32_6:
	cmpq	$2, %rcx
	cmovgeq	%rcx, %rsi
	movl	64(%rbx), %edx
	testl	%edx, %edx
	je	LBB32_7
## %bb.9:
	movl	80(%rbx), %ecx
	xorl	%eax, %eax
	testl	%ecx, %ecx
	jle	LBB32_31
## %bb.10:
	movq	96(%rbx), %rdi
	movl	%ecx, %r8d
	negl	%r8d
	negl	%edx
	movslq	%edx, %r9
	xorl	%r10d, %r10d
	xorl	%edx, %edx
LBB32_11:                               ## =>This Inner Loop Header: Depth=1
	cmpl	%ecx, %r9d
	movl	%r8d, %r11d
	cmovll	%eax, %r11d
	testl	%r9d, %r9d
	cmovsl	%ecx, %r11d
	movslq	%r11d, %r11
	addq	%r9, %r11
	addq	(%rdi,%r11,8), %r10
	cmpq	%rsi, %r10
	jge	LBB32_25
## %bb.12:                              ##   in Loop: Header=BB32_11 Depth=1
	incl	%edx
	incq	%r9
	cmpl	%edx, %ecx
	jne	LBB32_11
	jmp	LBB32_31
LBB32_7:
	testb	$4, ___cpu_model+13(%rip)
	jne	LBB32_8
## %bb.13:
	movq	96(%rbx), %rdi
	movl	80(%rbx), %ecx
	pushq	$4
	popq	%r8
	movl	%ecx, %eax
	cltd
	idivl	%r8d
	movl	%ecx, %eax
	subl	%edx, %eax
	jle	LBB32_14
## %bb.17:
	xorl	%edx, %edx
	xorl	%r8d, %r8d
LBB32_18:                               ## =>This Inner Loop Header: Depth=1
	movq	%r8, %r11
	addq	(%rdi,%rdx,8), %r11
	movq	8(%rdi,%rdx,8), %r10
	addq	%r11, %r10
	movq	16(%rdi,%rdx,8), %r9
	addq	%r10, %r9
	movq	24(%rdi,%rdx,8), %r8
	addq	%r9, %r8
	cmpq	%rsi, %r8
	jae	LBB32_19
LBB32_23:                               ##   in Loop: Header=BB32_18 Depth=1
	addq	$4, %rdx
	cmpl	%edx, %eax
	jg	LBB32_18
	jmp	LBB32_15
LBB32_19:                               ##   in Loop: Header=BB32_18 Depth=1
	cmpq	%rsi, %r11
	jge	LBB32_25
## %bb.20:                              ##   in Loop: Header=BB32_18 Depth=1
	cmpq	%rsi, %r10
	jge	LBB32_24
## %bb.21:                              ##   in Loop: Header=BB32_18 Depth=1
	cmpq	%rsi, %r9
	jge	LBB32_26
## %bb.22:                              ##   in Loop: Header=BB32_18 Depth=1
	cmpq	%rsi, %r8
	jl	LBB32_23
## %bb.27:
	addq	$3, %rdx
	jmp	LBB32_25
LBB32_8:
	movq	%rbx, %rdi
	movsd	%xmm0, -16(%rbp)                ## 8-byte Spill
	callq	_get_value_from_idx_up_to_count_avx2
	movsd	-16(%rbp), %xmm0                ## 8-byte Reload
                                        ## xmm0 = mem[0],zero
	jmp	LBB32_31
LBB32_14:
	xorl	%edx, %edx
	xorl	%r8d, %r8d
LBB32_15:
	cmpl	%ecx, %edx
	jge	LBB32_16
## %bb.28:
	movl	%edx, %eax
	leaq	(%rdi,%rax,8), %rdi
	xorl	%eax, %eax
LBB32_29:                               ## =>This Inner Loop Header: Depth=1
	addq	(%rdi), %r8
	cmpq	%rsi, %r8
	jge	LBB32_25
## %bb.30:                              ##   in Loop: Header=BB32_29 Depth=1
	incl	%edx
	addq	$8, %rdi
	cmpl	%edx, %ecx
	jg	LBB32_29
	jmp	LBB32_31
LBB32_16:
	xorl	%eax, %eax
	jmp	LBB32_31
LBB32_1:
	xorl	%edx, %edx
	jmp	LBB32_2
LBB32_24:
	incq	%rdx
	jmp	LBB32_25
LBB32_26:
	addq	$2, %rdx
LBB32_25:
	movb	24(%rbx), %cl
	movl	28(%rbx), %eax
	leal	2147483647(%rax), %esi
	andl	%edx, %esi
	shrl	%cl, %edx
	xorl	%edi, %edi
	movl	%edx, %ecx
	subl	$1, %ecx
	cmovbl	%edi, %ecx
	testl	%edx, %edx
	cmovnel	%eax, %edx
	addl	%esi, %edx
	movslq	%edx, %rax
	addl	16(%rbx), %ecx
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %rax
LBB32_31:
	movq	32(%rbx), %rcx
	orq	%rax, %rcx
	bsrq	%rcx, %rdx
	xorl	$63, %edx
	addl	24(%rbx), %edx
	pushq	$63
	popq	%rcx
	subl	%edx, %ecx
	sarq	%cl, %rax
	movslq	%eax, %rdx
	shlq	%cl, %rdx
	xorpd	%xmm1, %xmm1
	ucomisd	%xmm1, %xmm0
	jne	LBB32_32
	jnp	LBB32_33
LBB32_32:
	xorl	%esi, %esi
	cmpl	%eax, 40(%rbx)
	setle	%sil
	addl	%esi, %ecx
	pushq	$1
	popq	%rax
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %rax
	movabsq	$9223372036854775807, %rcx      ## imm = 0x7FFFFFFFFFFFFFFF
	movq	%rcx, %rsi
	subq	%rax, %rsi
	cmpq	%rsi, %rdx
	leaq	-1(%rdx,%rax), %rdx
	cmovgq	%rcx, %rdx
LBB32_33:
	addq	$8, %rsp
	popq	%rbx
	popq	%rbp
LBB32_2:
	movq	%rdx, %rax
	retq
	.cfi_endproc

_hdr_value_at_percentiles:              ## @hdr_value_at_percentiles
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
	subq	$168, %rsp
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movq	%rcx, %rbx
	testq	%rsi, %rsi
	sete	%al
	testq	%rdx, %rdx
	sete	%cl
	orb	%al, %cl
	movl	$22, %eax
	jne	LBB33_58
## %bb.1:
	movq	88(%rdi), %rax
	testq	%rax, %rax
	je	LBB33_2
## %bb.4:
	testq	%rbx, %rbx
	je	LBB33_15
## %bb.5:
	cvtsi2sd	%rax, %xmm1
	cmpq	$1, %rbx
	jne	LBB33_12
## %bb.6:
	xorl	%ecx, %ecx
	jmp	LBB33_7
LBB33_12:
	movq	%rbx, %rcx
	andq	$-2, %rcx
	movddup	%xmm1, %xmm2                    ## xmm2 = xmm1[0,0]
	movq	%rax, %xmm0
	pshufd	$68, %xmm0, %xmm3               ## xmm3 = xmm0[0,1,0,1]
	xorl	%r8d, %r8d
	movapd	LCPI33_0(%rip), %xmm4           ## xmm4 = [1.0E+2,1.0E+2]
	movapd	LCPI33_1(%rip), %xmm5           ## xmm5 = [5.0E-1,5.0E-1]
	movapd	LCPI33_2(%rip), %xmm6           ## xmm6 = [1.0E+0,1.0E+0]
	.p2align	4, 0x90
LBB33_13:                               ## =>This Inner Loop Header: Depth=1
	movupd	(%rsi,%r8,8), %xmm7
	minpd	%xmm4, %xmm7
	divpd	%xmm4, %xmm7
	mulpd	%xmm2, %xmm7
	addpd	%xmm5, %xmm7
	movapd	%xmm6, %xmm8
	cmplepd	%xmm7, %xmm8
	movapd	%xmm2, %xmm0
	cmplepd	%xmm7, %xmm0
	andpd	%xmm8, %xmm0
	maxpd	%xmm6, %xmm7
	cvttsd2si	%xmm7, %r9
	movq	%r9, %xmm8
	unpckhpd	%xmm7, %xmm7                    ## xmm7 = xmm7[1,1]
	cvttsd2si	%xmm7, %r9
	movq	%r9, %xmm7
	punpcklqdq	%xmm7, %xmm8            ## xmm8 = xmm8[0],xmm7[0]
	blendvpd	%xmm0, %xmm3, %xmm8
	movupd	%xmm8, (%rdx,%r8,8)
	addq	$2, %r8
	cmpq	%r8, %rcx
	jne	LBB33_13
## %bb.14:
	cmpq	%rbx, %rcx
	jne	LBB33_7
LBB33_15:
	cmpl	$0, 64(%rdi)
	jne	LBB33_40
## %bb.16:
	movabsq	$9223372036854775807, %r8       ## imm = 0x7FFFFFFFFFFFFFFF
	movq	96(%rdi), %rax
	movq	%rax, -48(%rbp)                 ## 8-byte Spill
	movslq	80(%rdi), %rcx
	movq	%rcx, -64(%rbp)                 ## 8-byte Spill
	cmpq	$8, %rcx
	setl	%al
	testq	%rbx, %rbx
	sete	%cl
	orb	%al, %cl
	jne	LBB33_17
## %bb.28:
	movl	$8, %eax
	xorl	%r12d, %r12d
	pxor	%xmm0, %xmm0
	xorl	%r13d, %r13d
	xorl	%r15d, %r15d
	xorl	%r11d, %r11d
	.p2align	4, 0x90
LBB33_29:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB33_31 Depth 2
                                        ##       Child Loop BB33_32 Depth 3
	movq	%rax, -56(%rbp)                 ## 8-byte Spill
	movq	-48(%rbp), %rax                 ## 8-byte Reload
	movdqu	(%rax,%r13,8), %xmm1
	movdqu	16(%rax,%r13,8), %xmm2
	movdqu	32(%rax,%r13,8), %xmm3
	paddq	%xmm1, %xmm3
	movdqu	48(%rax,%r13,8), %xmm1
	paddq	%xmm2, %xmm1
	paddq	%xmm3, %xmm1
	pshufd	$238, %xmm1, %xmm2              ## xmm2 = xmm1[2,3,2,3]
	paddq	%xmm1, %xmm2
	movq	%xmm2, %rax
	addq	%r11, %rax
	cmpq	(%rdx,%r15,8), %rax
	movq	%r13, -72(%rbp)                 ## 8-byte Spill
	jge	LBB33_31
## %bb.30:                              ##   in Loop: Header=BB33_29 Depth=1
	movq	%rax, %r11
LBB33_38:                               ##   in Loop: Header=BB33_29 Depth=1
	movq	-56(%rbp), %rcx                 ## 8-byte Reload
	leaq	8(%rcx), %rax
	cmpq	-64(%rbp), %rax                 ## 8-byte Folded Reload
	movq	-72(%rbp), %r13                 ## 8-byte Reload
	ja	LBB33_18
## %bb.39:                              ##   in Loop: Header=BB33_29 Depth=1
	addq	$8, %r13
	cmpq	%rbx, %r15
	jb	LBB33_29
	jmp	LBB33_18
	.p2align	4, 0x90
LBB33_36:                               ##   in Loop: Header=BB33_31 Depth=2
	movq	%rbx, %r15
LBB33_37:                               ##   in Loop: Header=BB33_31 Depth=2
	incq	%r13
	cmpq	-56(%rbp), %r13                 ## 8-byte Folded Reload
	je	LBB33_38
LBB33_31:                               ##   Parent Loop BB33_29 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB33_32 Depth 3
	movq	-48(%rbp), %rax                 ## 8-byte Reload
	addq	(%rax,%r13,8), %r11
	cmpq	%rbx, %r15
	jb	LBB33_32
	jmp	LBB33_37
	.p2align	4, 0x90
LBB33_35:                               ##   in Loop: Header=BB33_32 Depth=3
	movq	%rax, (%rdx,%r15,8)
	incq	%r15
	cmpq	%r15, %rbx
	je	LBB33_36
LBB33_32:                               ##   Parent Loop BB33_29 Depth=1
                                        ##     Parent Loop BB33_31 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	cmpq	(%rdx,%r15,8), %r11
	jl	LBB33_37
## %bb.33:                              ##   in Loop: Header=BB33_32 Depth=3
	movl	24(%rdi), %eax
	movl	%r13d, %r10d
	movl	%eax, %ecx
	shrl	%cl, %r10d
	movl	28(%rdi), %r9d
	leal	2147483647(%r9), %r14d
	andl	%r13d, %r14d
	movl	%r10d, %ecx
	subl	$1, %ecx
	cmovbl	%r12d, %ecx
	testl	%r10d, %r10d
	cmovnel	%r9d, %r10d
	addl	%r14d, %r10d
	movslq	%r10d, %r10
	addl	16(%rdi), %ecx
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %r10
	movq	32(%rdi), %rcx
	orq	%r10, %rcx
	bsrq	%rcx, %r9
	xorl	$63, %r9d
	addl	%eax, %r9d
	movl	$63, %ecx
	subl	%r9d, %ecx
	sarq	%cl, %r10
	movslq	%r10d, %rax
	shlq	%cl, %rax
	movsd	(%rsi,%r15,8), %xmm1            ## xmm1 = mem[0],zero
	ucomisd	%xmm0, %xmm1
	jne	LBB33_34
	jnp	LBB33_35
LBB33_34:                               ##   in Loop: Header=BB33_32 Depth=3
	xorl	%r9d, %r9d
	cmpl	%r10d, 40(%rdi)
	setle	%r9b
	addl	%r9d, %ecx
	movl	$1, %r9d
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %r9
	movq	%r8, %rcx
	subq	%r9, %rcx
	cmpq	%rcx, %rax
	leaq	-1(%rax,%r9), %rax
	cmovgq	%r8, %rax
	jmp	LBB33_35
LBB33_17:
	xorl	%r11d, %r11d
	xorl	%r15d, %r15d
	xorl	%ecx, %ecx
LBB33_18:
	cmpl	-64(%rbp), %ecx                 ## 4-byte Folded Reload
	jge	LBB33_51
## %bb.19:
	cmpq	%rbx, %r15
	jae	LBB33_51
## %bb.20:
	movl	%ecx, %r14d
	xorl	%r12d, %r12d
	pxor	%xmm0, %xmm0
	.p2align	4, 0x90
LBB33_21:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB33_22 Depth 2
	movq	-48(%rbp), %rax                 ## 8-byte Reload
	addq	(%rax,%r14,8), %r11
	jmp	LBB33_22
	.p2align	4, 0x90
LBB33_25:                               ##   in Loop: Header=BB33_22 Depth=2
	movq	%rax, (%rdx,%r15,8)
	incq	%r15
	cmpq	%rbx, %r15
	jae	LBB33_26
LBB33_22:                               ##   Parent Loop BB33_21 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	cmpq	(%rdx,%r15,8), %r11
	jl	LBB33_26
## %bb.23:                              ##   in Loop: Header=BB33_22 Depth=2
	movl	24(%rdi), %eax
	movl	%r14d, %r9d
	movl	%eax, %ecx
	shrl	%cl, %r9d
	movl	28(%rdi), %r10d
	leal	2147483647(%r10), %r13d
	andl	%r14d, %r13d
	movl	%r9d, %ecx
	subl	$1, %ecx
	cmovbl	%r12d, %ecx
	testl	%r9d, %r9d
	cmovnel	%r10d, %r9d
	addl	%r13d, %r9d
	movslq	%r9d, %r10
	addl	16(%rdi), %ecx
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %r10
	movq	32(%rdi), %rcx
	orq	%r10, %rcx
	bsrq	%rcx, %r9
	xorl	$63, %r9d
	addl	%eax, %r9d
	movl	$63, %ecx
	subl	%r9d, %ecx
	sarq	%cl, %r10
	movslq	%r10d, %rax
	shlq	%cl, %rax
	movsd	(%rsi,%r15,8), %xmm1            ## xmm1 = mem[0],zero
	ucomisd	%xmm0, %xmm1
	jne	LBB33_24
	jnp	LBB33_25
LBB33_24:                               ##   in Loop: Header=BB33_22 Depth=2
	xorl	%r9d, %r9d
	cmpl	%r10d, 40(%rdi)
	setle	%r9b
	addl	%r9d, %ecx
	movl	$1, %r9d
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %r9
	movq	%r8, %rcx
	subq	%r9, %rcx
	cmpq	%rcx, %rax
	leaq	-1(%rax,%r9), %rax
	cmovgq	%r8, %rax
	jmp	LBB33_25
	.p2align	4, 0x90
LBB33_26:                               ##   in Loop: Header=BB33_21 Depth=1
	incq	%r14
	cmpq	-64(%rbp), %r14                 ## 8-byte Folded Reload
	jge	LBB33_51
## %bb.27:                              ##   in Loop: Header=BB33_21 Depth=1
	cmpq	%rbx, %r15
	jb	LBB33_21
LBB33_51:
	cmpq	%rbx, %r15
	jae	LBB33_57
## %bb.52:
	pxor	%xmm0, %xmm0
	jmp	LBB33_53
	.p2align	4, 0x90
LBB33_55:                               ##   in Loop: Header=BB33_53 Depth=1
	bsrq	32(%rdi), %rax
	xorl	$63, %eax
	xorl	%ecx, %ecx
	cmpl	$0, 40(%rdi)
	setle	%cl
	addl	24(%rdi), %eax
	subl	%eax, %ecx
	addb	$63, %cl
	movq	$-1, %rax
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %rax
	notq	%rax
	movq	%rax, (%rdx,%r15,8)
	incq	%r15
	cmpq	%r15, %rbx
	je	LBB33_57
LBB33_53:                               ## =>This Inner Loop Header: Depth=1
	movsd	(%rsi,%r15,8), %xmm1            ## xmm1 = mem[0],zero
	ucomisd	%xmm0, %xmm1
	jne	LBB33_55
	jp	LBB33_55
## %bb.54:                              ##   in Loop: Header=BB33_53 Depth=1
	xorl	%eax, %eax
	movq	%rax, (%rdx,%r15,8)
	incq	%r15
	cmpq	%r15, %rbx
	jne	LBB33_53
LBB33_57:
	xorl	%eax, %eax
LBB33_58:
	addq	$168, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
LBB33_7:
	movsd	LCPI33_3(%rip), %xmm0           ## xmm0 = [1.0E+2,0.0E+0]
	movsd	LCPI33_4(%rip), %xmm2           ## xmm2 = [5.0E-1,0.0E+0]
	movsd	LCPI33_5(%rip), %xmm3           ## xmm3 = [1.0E+0,0.0E+0]
	jmp	LBB33_8
	.p2align	4, 0x90
LBB33_11:                               ##   in Loop: Header=BB33_8 Depth=1
	movq	%r8, (%rdx,%rcx,8)
	incq	%rcx
	cmpq	%rcx, %rbx
	je	LBB33_15
LBB33_8:                                ## =>This Inner Loop Header: Depth=1
	movsd	(%rsi,%rcx,8), %xmm4            ## xmm4 = mem[0],zero
	minsd	%xmm0, %xmm4
	divsd	%xmm0, %xmm4
	mulsd	%xmm1, %xmm4
	addsd	%xmm2, %xmm4
	movl	$1, %r8d
	ucomisd	%xmm3, %xmm4
	jb	LBB33_11
## %bb.9:                               ##   in Loop: Header=BB33_8 Depth=1
	ucomisd	%xmm1, %xmm4
	movq	%rax, %r8
	jae	LBB33_11
## %bb.10:                              ##   in Loop: Header=BB33_8 Depth=1
	cvttsd2si	%xmm4, %r8
	jmp	LBB33_11
LBB33_2:
	xorl	%eax, %eax
	testq	%rbx, %rbx
	je	LBB33_58
## %bb.3:
	shlq	$3, %rbx
	movq	%rdx, %rdi
	movq	%rbx, %rsi
	callq	___bzero
	jmp	LBB33_57
LBB33_40:
	movq	%rsi, -48(%rbp)                 ## 8-byte Spill
	movq	%rdx, -56(%rbp)                 ## 8-byte Spill
	movq	%rdi, -200(%rbp)
	movl	$-1, -192(%rbp)
	movq	%rdi, %r14
	movq	88(%rdi), %rax
	movq	%rax, -184(%rbp)
	pxor	%xmm0, %xmm0
	movdqu	%xmm0, -176(%rbp)
	movdqu	%xmm0, -160(%rbp)
	movdqu	%xmm0, -128(%rbp)
	leaq	_all_values_iter_next(%rip), %rax
	movq	%rax, -80(%rbp)
	leaq	-200(%rbp), %rdi
	callq	_all_values_iter_next
	xorb	$1, %al
	testq	%rbx, %rbx
	sete	%cl
	orb	%al, %cl
	jne	LBB33_41
## %bb.42:
	movabsq	$9223372036854775807, %r12      ## imm = 0x7FFFFFFFFFFFFFFF
	xorl	%r15d, %r15d
	xorpd	%xmm1, %xmm1
	xorl	%r13d, %r13d
	movq	-56(%rbp), %rdx                 ## 8-byte Reload
	movq	-48(%rbp), %rsi                 ## 8-byte Reload
	movq	%r14, %rdi
LBB33_43:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB33_44 Depth 2
	addq	-176(%rbp), %r13
	movq	-160(%rbp), %rax
	jmp	LBB33_44
LBB33_47:                               ##   in Loop: Header=BB33_44 Depth=2
	movq	%r8, (%rdx,%r15,8)
	incq	%r15
	cmpq	%rbx, %r15
	jae	LBB33_48
LBB33_44:                               ##   Parent Loop BB33_43 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	cmpq	(%rdx,%r15,8), %r13
	jl	LBB33_48
## %bb.45:                              ##   in Loop: Header=BB33_44 Depth=2
	movq	32(%rdi), %rcx
	orq	%rax, %rcx
	bsrq	%rcx, %r8
	xorl	$63, %r8d
	addl	24(%rdi), %r8d
	movl	$63, %ecx
	subl	%r8d, %ecx
	movq	%rax, %r9
	sarq	%cl, %r9
	movslq	%r9d, %r8
	shlq	%cl, %r8
	movsd	(%rsi,%r15,8), %xmm0            ## xmm0 = mem[0],zero
	ucomisd	%xmm1, %xmm0
	jne	LBB33_46
	jnp	LBB33_47
LBB33_46:                               ##   in Loop: Header=BB33_44 Depth=2
	xorl	%r10d, %r10d
	cmpl	%r9d, 40(%rdi)
	setle	%r10b
	addl	%r10d, %ecx
	movl	$1, %r9d
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %r9
	movq	%r12, %rcx
	subq	%r9, %rcx
	cmpq	%rcx, %r8
	leaq	-1(%r8,%r9), %r8
	cmovgq	%r12, %r8
	jmp	LBB33_47
LBB33_48:                               ##   in Loop: Header=BB33_43 Depth=1
	leaq	-200(%rbp), %rdi
	callq	*-80(%rbp)
	cmpq	%rbx, %r15
	jae	LBB33_49
## %bb.50:                              ##   in Loop: Header=BB33_43 Depth=1
	testb	%al, %al
	movq	-56(%rbp), %rdx                 ## 8-byte Reload
	movq	-48(%rbp), %rsi                 ## 8-byte Reload
	movq	%r14, %rdi
	xorpd	%xmm1, %xmm1
	jne	LBB33_43
	jmp	LBB33_51
LBB33_41:
	xorl	%r15d, %r15d
LBB33_49:
	movq	-56(%rbp), %rdx                 ## 8-byte Reload
	movq	-48(%rbp), %rsi                 ## 8-byte Reload
	movq	%r14, %rdi
	jmp	LBB33_51
	.cfi_endproc

_hdr_iter_percentile_init:              ## @hdr_iter_percentile_init
	.cfi_startproc
## %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	movq	%rsi, (%rdi)
	movl	$-1, 8(%rdi)
	movq	88(%rsi), %rax
	movq	%rax, 16(%rdi)
	xorps	%xmm0, %xmm0
	movups	%xmm0, 24(%rdi)
	movups	%xmm0, 40(%rdi)
	movups	%xmm0, 72(%rdi)
	movb	$0, 88(%rdi)
	movl	%edx, 92(%rdi)
	movups	%xmm0, 96(%rdi)
	leaq	_percentile_iter_next(%rip), %rax
	movq	%rax, 120(%rdi)
	popq	%rbp
	retq
	.cfi_endproc

_percentile_iter_next:                  ## @percentile_iter_next
	.cfi_startproc
## %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%rbx
	pushq	%rax
	.cfi_offset %rbx, -24
	movq	%rdi, %rbx
	movq	32(%rdi), %rax
	cmpq	16(%rdi), %rax
	jge	LBB42_5
## %bb.1:
	cmpl	$-1, 8(%rbx)
	jne	LBB42_9
## %bb.2:
	movq	(%rbx), %rax
	cmpl	$0, 80(%rax)
	jns	LBB42_8
	jmp	LBB42_3
LBB42_5:
	cmpb	$0, 88(%rbx)
	je	LBB42_7
LBB42_3:
	xorl	%eax, %eax
LBB42_4:
                                        ## kill: def $al killed $al killed $eax
	addq	$8, %rsp
	popq	%rbx
	popq	%rbp
	retq
LBB42_7:
	movb	$1, 88(%rbx)
	movabsq	$4636737291354636288, %rax      ## imm = 0x4059000000000000
	movq	%rax, 104(%rbx)
	jmp	LBB42_14
LBB42_8:
	movq	%rbx, %rdi
	callq	_move_next
LBB42_9:
	movq	(%rbx), %rdx
	movq	32(%rbx), %rcx
	cmpq	$0, 24(%rbx)
	je	LBB42_11
## %bb.10:
	xorps	%xmm0, %xmm0
	cvtsi2sd	%rcx, %xmm0
	mulsd	LCPI42_0(%rip), %xmm0
	xorps	%xmm1, %xmm1
	cvtsi2sdq	88(%rdx), %xmm1
	divsd	%xmm1, %xmm0
	movsd	96(%rbx), %xmm1                 ## xmm1 = mem[0],zero
	ucomisd	%xmm1, %xmm0
	jae	LBB42_13
LBB42_11:
	movb	$1, %al
	cmpq	16(%rbx), %rcx
	jge	LBB42_4
## %bb.12:
	movl	8(%rbx), %ecx
	cmpl	80(%rdx), %ecx
	jl	LBB42_8
	jmp	LBB42_4
LBB42_13:
	movq	40(%rbx), %rax
	movq	32(%rdx), %rcx
	orq	%rax, %rcx
	bsrq	%rcx, %rsi
	xorl	$63, %esi
	addl	24(%rdx), %esi
	movl	$63, %ecx
	subl	%esi, %ecx
	sarq	%cl, %rax
	movslq	%eax, %rsi
	movq	%rsi, %rdi
	shlq	%cl, %rdi
	xorl	%eax, %eax
	cmpl	%esi, 40(%rdx)
	setle	%al
	addl	%ecx, %eax
	movl	$1, %edx
	movl	%eax, %ecx
	shlq	%cl, %rdx
	movabsq	$9223372036854775807, %rax      ## imm = 0x7FFFFFFFFFFFFFFF
	movq	%rax, %rcx
	subq	%rdx, %rcx
	cmpq	%rcx, %rdi
	leaq	-1(%rdi,%rdx), %rcx
	cmovgq	%rax, %rcx
	movq	80(%rbx), %rax
	movq	%rax, 72(%rbx)
	movq	%rcx, 80(%rbx)
	movsd	%xmm1, 104(%rbx)
	movsd	LCPI42_0(%rip), %xmm2           ## xmm2 = [1.0E+2,0.0E+0]
	movapd	%xmm1, %xmm0
	movsd	%xmm1, -16(%rbp)                ## 8-byte Spill
	movapd	%xmm2, %xmm1
	subsd	%xmm0, %xmm1
	movapd	%xmm2, %xmm0
	divsd	%xmm1, %xmm0
	callq	_log
	divsd	LCPI42_1(%rip), %xmm0
	cvttsd2si	%xmm0, %rax
	incq	%rax
	xorps	%xmm0, %xmm0
	cvtsi2sd	%rax, %xmm0
	callq	_exp2
	cvttsd2si	%xmm0, %rax
	movslq	92(%rbx), %rcx
	imulq	%rax, %rcx
	xorps	%xmm0, %xmm0
	cvtsi2sd	%rcx, %xmm0
	movsd	LCPI42_0(%rip), %xmm1           ## xmm1 = [1.0E+2,0.0E+0]
	divsd	%xmm0, %xmm1
	addsd	-16(%rbp), %xmm1                ## 8-byte Folded Reload
	movsd	%xmm1, 96(%rbx)
LBB42_14:
	movb	$1, %al
                                        ## kill: def $al killed $al killed $eax
	addq	$8, %rsp
	popq	%rbx
	popq	%rbp
	retq
	.cfi_endproc

_hdr_percentiles_print:                 ## @hdr_percentiles_print
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
	subq	$328, %rsp                      ## imm = 0x148
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movl	%ecx, %r12d
	movsd	%xmm0, -96(%rbp)                ## 8-byte Spill
	movl	%edx, %r15d
	movq	%rsi, %rbx
	movq	%rdi, %r14
	movq	___stack_chk_guard@GOTPCREL(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, -48(%rbp)
	movl	20(%rdi), %r8d
	testl	%ecx, %ecx
	je	LBB49_3
## %bb.1:
	cmpl	$1, %r12d
	jne	LBB49_3
## %bb.2:
	leaq	L_.str.4(%rip), %rdx
	leaq	L_.str.5(%rip), %rcx
	leaq	L_.str.6(%rip), %r9
	jmp	LBB49_4
LBB49_3:
	leaq	L_.str.4(%rip), %rdx
	leaq	L_.str.7(%rip), %rcx
	leaq	L_.str.8(%rip), %r9
LBB49_4:
	leaq	-80(%rbp), %rdi
	movl	$25, %esi
	xorl	%eax, %eax
	callq	_snprintf
	cmpl	$1, %r12d
	leaq	L_.str.9(%rip), %rax
	leaq	L_.str.10(%rip), %rsi
	cmoveq	%rax, %rsi
	movq	%r14, -232(%rbp)
	movl	$-1, -224(%rbp)
	movq	88(%r14), %rax
	movq	%rax, -216(%rbp)
	xorpd	%xmm0, %xmm0
	movupd	%xmm0, -208(%rbp)
	movupd	%xmm0, -192(%rbp)
	movupd	%xmm0, -160(%rbp)
	movb	$0, -144(%rbp)
	movl	%r15d, -140(%rbp)
	movupd	%xmm0, -136(%rbp)
	leaq	_percentile_iter_next(%rip), %rax
	movq	%rax, -112(%rbp)
	leaq	L_.str(%rip), %rdx
	leaq	L_.str.1(%rip), %rcx
	leaq	L_.str.2(%rip), %r8
	leaq	L_.str.3(%rip), %r9
	xorl	%r15d, %r15d
	movq	%rbx, %rdi
	xorl	%eax, %eax
	callq	_fprintf
	testl	%eax, %eax
	js	LBB49_5
## %bb.6:
	movl	%r12d, -88(%rbp)                ## 4-byte Spill
	movq	%r14, -104(%rbp)                ## 8-byte Spill
	leaq	-232(%rbp), %r13
	leaq	-80(%rbp), %r14
	movl	$5, %r12d
	.p2align	4, 0x90
LBB49_7:                                ## =>This Inner Loop Header: Depth=1
	movq	%r13, %rdi
	callq	*-112(%rbp)
	testb	%al, %al
	je	LBB49_9
## %bb.8:                               ##   in Loop: Header=BB49_7 Depth=1
	xorps	%xmm0, %xmm0
	cvtsi2sdq	-184(%rbp), %xmm0
	divsd	-96(%rbp), %xmm0                ## 8-byte Folded Reload
	movsd	-128(%rbp), %xmm1               ## xmm1 = mem[0],zero
	divsd	LCPI49_0(%rip), %xmm1
	movq	-200(%rbp), %rdx
	movsd	LCPI49_1(%rip), %xmm2           ## xmm2 = [1.0E+0,0.0E+0]
	movapd	%xmm2, %xmm3
	subsd	%xmm1, %xmm3
	divsd	%xmm3, %xmm2
	movq	%rbx, %rdi
	movq	%r14, %rsi
	movb	$3, %al
	callq	_fprintf
	testl	%eax, %eax
	cmovsl	%r12d, %r15d
	jns	LBB49_7
	jmp	LBB49_28
LBB49_5:
	movl	$5, %r15d
	jmp	LBB49_28
LBB49_9:
	cmpl	$0, -88(%rbp)                   ## 4-byte Folded Reload
	jne	LBB49_28
## %bb.10:
	movq	-104(%rbp), %r12                ## 8-byte Reload
	movq	88(%r12), %r14
	testq	%r14, %r14
	je	LBB49_11
## %bb.12:
	movq	%r12, -360(%rbp)
	movq	%r14, -344(%rbp)
	leaq	_all_values_iter_next(%rip), %rax
	movq	%rax, -240(%rbp)
	movl	$0, -352(%rbp)
	movl	80(%r12), %ecx
	testl	%ecx, %ecx
	jle	LBB49_13
## %bb.14:
	leaq	-288(%rbp), %rax
	movl	64(%r12), %esi
	xorl	%edx, %edx
	xorpd	%xmm0, %xmm0
	testl	%esi, %esi
	je	LBB49_15
## %bb.16:
	movsd	%xmm0, -88(%rbp)                ## 8-byte Spill
	movl	%esi, %edi
	negl	%edi
	movl	%ecx, %r8d
	negl	%r8d
	cmpl	%edi, %ecx
	cmovgl	%edx, %r8d
	testl	%esi, %esi
	cmovgl	%ecx, %r8d
	subl	%esi, %r8d
	movslq	%r8d, %rdx
	jmp	LBB49_17
LBB49_11:
	xorpd	%xmm0, %xmm0
	jmp	LBB49_24
LBB49_13:
	xorpd	%xmm0, %xmm0
	movsd	%xmm0, -88(%rbp)                ## 8-byte Spill
	jmp	LBB49_23
LBB49_15:
	movsd	%xmm0, -88(%rbp)                ## 8-byte Spill
LBB49_17:
	movq	96(%r12), %rcx
	movq	(%rcx,%rdx,8), %rcx
	movq	%rcx, -336(%rbp)
	movq	%rcx, -328(%rbp)
	bsrq	32(%r12), %rdx
	xorl	$63, %edx
	xorl	%ecx, %ecx
	cmpl	$0, 40(%r12)
	setle	%cl
	addl	24(%r12), %edx
	subl	%edx, %ecx
	addb	$63, %cl
	movl	$1, %edx
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %rdx
	movq	$0, -304(%rbp)
	movq	$0, -320(%rbp)
	leaq	-1(%rdx), %rcx
	movq	%rcx, -312(%rbp)
	sarq	%rdx
	movq	%rdx, -296(%rbp)
	xorpd	%xmm0, %xmm0
	movupd	%xmm0, (%rax)
	testq	%r14, %r14
	jle	LBB49_23
## %bb.18:
	xorpd	%xmm0, %xmm0
	movsd	%xmm0, -88(%rbp)                ## 8-byte Spill
	xorl	%r13d, %r13d
	leaq	-360(%rbp), %r12
	.p2align	4, 0x90
LBB49_19:                               ## =>This Inner Loop Header: Depth=1
	movq	-336(%rbp), %rdx
	testq	%rdx, %rdx
	je	LBB49_21
## %bb.20:                              ##   in Loop: Header=BB49_19 Depth=1
	movq	-320(%rbp), %rax
	movq	-104(%rbp), %r8                 ## 8-byte Reload
	movq	32(%r8), %rcx
	orq	%rax, %rcx
	bsrq	%rcx, %rsi
	xorl	$63, %esi
	addl	24(%r8), %esi
	movl	$63, %ecx
	subl	%esi, %ecx
	sarq	%cl, %rax
	movslq	%eax, %rsi
	movq	%rsi, %rdi
	shlq	%cl, %rdi
	addq	%rdx, %r13
	xorl	%eax, %eax
	cmpl	%esi, 40(%r8)
	setle	%al
	addl	%ecx, %eax
	movl	$1, %esi
	movl	%eax, %ecx
	shlq	%cl, %rsi
	xorps	%xmm0, %xmm0
	cvtsi2sd	%rdx, %xmm0
	sarq	%rsi
	addq	%rdi, %rsi
	xorps	%xmm1, %xmm1
	cvtsi2sd	%rsi, %xmm1
	mulsd	%xmm0, %xmm1
	movsd	-88(%rbp), %xmm0                ## 8-byte Reload
                                        ## xmm0 = mem[0],zero
	addsd	%xmm1, %xmm0
	movsd	%xmm0, -88(%rbp)                ## 8-byte Spill
LBB49_21:                               ##   in Loop: Header=BB49_19 Depth=1
	movq	%r12, %rdi
	callq	*-240(%rbp)
	testb	%al, %al
	je	LBB49_23
## %bb.22:                              ##   in Loop: Header=BB49_19 Depth=1
	cmpq	%r14, %r13
	jl	LBB49_19
LBB49_23:
	xorps	%xmm0, %xmm0
	cvtsi2sd	%r14, %xmm0
	movsd	-88(%rbp), %xmm1                ## 8-byte Reload
                                        ## xmm1 = mem[0],zero
	divsd	%xmm0, %xmm1
	movapd	%xmm1, %xmm0
	movq	-104(%rbp), %r12                ## 8-byte Reload
LBB49_24:
	divsd	-96(%rbp), %xmm0                ## 8-byte Folded Reload
	movsd	%xmm0, -88(%rbp)                ## 8-byte Spill
	movq	%r12, %rdi
	callq	_hdr_stddev
	movapd	%xmm0, %xmm1
	divsd	-96(%rbp), %xmm1                ## 8-byte Folded Reload
	movq	56(%r12), %rax
	testq	%rax, %rax
	je	LBB49_25
## %bb.26:
	movq	32(%r12), %rcx
	orq	%rax, %rcx
	bsrq	%rcx, %rdx
	xorl	$63, %edx
	addl	24(%r12), %edx
	movl	$63, %ecx
	subl	%edx, %ecx
	sarq	%cl, %rax
	movslq	%eax, %rdx
	movq	%rdx, %rsi
	shlq	%cl, %rsi
	movl	40(%r12), %r8d
	xorl	%eax, %eax
	cmpl	%edx, %r8d
	setle	%al
	addl	%ecx, %eax
	movl	$1, %edx
	movl	%eax, %ecx
	shlq	%cl, %rdx
	movabsq	$9223372036854775807, %rax      ## imm = 0x7FFFFFFFFFFFFFFF
	movq	%rax, %rcx
	subq	%rdx, %rcx
	cmpq	%rcx, %rsi
	leaq	-1(%rsi,%rdx), %rcx
	cmovgq	%rax, %rcx
	xorps	%xmm2, %xmm2
	cvtsi2sd	%rcx, %xmm2
	jmp	LBB49_27
LBB49_25:
	movl	40(%r12), %r8d
	xorpd	%xmm2, %xmm2
LBB49_27:
	divsd	-96(%rbp), %xmm2                ## 8-byte Folded Reload
	movq	88(%r12), %rdx
	movl	44(%r12), %ecx
	leaq	_CLASSIC_FOOTER(%rip), %rsi
	movq	%rbx, %rdi
	movsd	-88(%rbp), %xmm0                ## 8-byte Reload
                                        ## xmm0 = mem[0],zero
	movb	$3, %al
	callq	_fprintf
	testl	%eax, %eax
	movl	$5, %eax
	cmovsl	%eax, %r15d
LBB49_28:
	movq	___stack_chk_guard@GOTPCREL(%rip), %rax
	movq	(%rax), %rax
	cmpq	-48(%rbp), %rax
	jne	LBB49_30
## %bb.29:
	movl	%r15d, %eax
	addq	$328, %rsp                      ## imm = 0x148
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
LBB49_30:
	callq	___stack_chk_fail
	.cfi_endproc

_get_value_from_idx_up_to_count_avx2:   ## @get_value_from_idx_up_to_count_avx2
	.cfi_startproc
## %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%rbx
	.cfi_offset %rbx, -24
	movl	80(%rdi), %ecx
	movl	%ecx, %eax
	andl	$-16, %eax
	testl	%eax, %eax
	jle	LBB50_1
## %bb.4:
	movq	96(%rdi), %r9
	leal	-1(%rcx), %r10d
	xorl	%edx, %edx
	xorl	%r11d, %r11d
	.p2align	4, 0x90
LBB50_5:                                ## =>This Inner Loop Header: Depth=1
	leal	64(%rdx), %r8d
	cmpl	%ecx, %r8d
	cmovgel	%r10d, %r8d
	movslq	%r8d, %r8
	prefetcht0	(%r9,%r8,8)
	vmovdqu	(%r9,%rdx,8), %ymm0
	vpaddq	32(%r9,%rdx,8), %ymm0, %ymm1
	vpaddq	64(%r9,%rdx,8), %ymm1, %ymm1
	vpaddq	96(%r9,%rdx,8), %ymm1, %ymm1
	vextracti128	$1, %ymm1, %xmm2
	vpaddq	%xmm2, %xmm1, %xmm1
	vpextrq	$1, %xmm1, %rbx
	vmovq	%xmm1, %r8
	addq	%r11, %r8
	addq	%rbx, %r8
	cmpq	%rsi, %r8
	jge	LBB50_6
LBB50_34:                               ##   in Loop: Header=BB50_5 Depth=1
	addq	$16, %rdx
	movq	%r8, %r11
	cmpq	%rax, %rdx
	jb	LBB50_5
	jmp	LBB50_2
LBB50_6:                                ##   in Loop: Header=BB50_5 Depth=1
	vmovq	%xmm0, %r8
	addq	%r11, %r8
	cmpq	%rsi, %r8
	jge	LBB50_41
## %bb.7:                               ##   in Loop: Header=BB50_5 Depth=1
	addq	8(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_33
## %bb.8:                               ##   in Loop: Header=BB50_5 Depth=1
	addq	16(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_32
## %bb.9:                               ##   in Loop: Header=BB50_5 Depth=1
	addq	24(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_31
## %bb.10:                              ##   in Loop: Header=BB50_5 Depth=1
	addq	32(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_40
## %bb.11:                              ##   in Loop: Header=BB50_5 Depth=1
	addq	40(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_30
## %bb.12:                              ##   in Loop: Header=BB50_5 Depth=1
	addq	48(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_29
## %bb.13:                              ##   in Loop: Header=BB50_5 Depth=1
	addq	56(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_28
## %bb.14:                              ##   in Loop: Header=BB50_5 Depth=1
	addq	64(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_39
## %bb.15:                              ##   in Loop: Header=BB50_5 Depth=1
	addq	72(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_27
## %bb.16:                              ##   in Loop: Header=BB50_5 Depth=1
	addq	80(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_26
## %bb.17:                              ##   in Loop: Header=BB50_5 Depth=1
	addq	88(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_25
## %bb.18:                              ##   in Loop: Header=BB50_5 Depth=1
	addq	96(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_38
## %bb.19:                              ##   in Loop: Header=BB50_5 Depth=1
	addq	104(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_24
## %bb.20:                              ##   in Loop: Header=BB50_5 Depth=1
	addq	112(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_23
## %bb.21:                              ##   in Loop: Header=BB50_5 Depth=1
	addq	120(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jl	LBB50_34
## %bb.22:
	addq	$15, %rdx
	jmp	LBB50_41
LBB50_1:
	xorl	%edx, %edx
	xorl	%r8d, %r8d
LBB50_2:
	cmpl	%ecx, %edx
	jge	LBB50_3
## %bb.35:
	movq	96(%rdi), %r9
	movl	%edx, %edx
	xorl	%eax, %eax
	.p2align	4, 0x90
LBB50_36:                               ## =>This Inner Loop Header: Depth=1
	addq	(%r9,%rdx,8), %r8
	cmpq	%rsi, %r8
	jge	LBB50_41
## %bb.37:                              ##   in Loop: Header=BB50_36 Depth=1
	incq	%rdx
	cmpq	%rdx, %rcx
	jne	LBB50_36
## %bb.42:
	popq	%rbx
	popq	%rbp
	vzeroupper
	retq
LBB50_3:
	xorl	%eax, %eax
	popq	%rbx
	popq	%rbp
	vzeroupper
	retq
LBB50_33:
	incq	%rdx
	jmp	LBB50_41
LBB50_32:
	addq	$2, %rdx
	jmp	LBB50_41
LBB50_31:
	addq	$3, %rdx
	jmp	LBB50_41
LBB50_40:
	addq	$4, %rdx
	jmp	LBB50_41
LBB50_30:
	addq	$5, %rdx
	jmp	LBB50_41
LBB50_29:
	addq	$6, %rdx
	jmp	LBB50_41
LBB50_28:
	addq	$7, %rdx
	jmp	LBB50_41
LBB50_39:
	addq	$8, %rdx
	jmp	LBB50_41
LBB50_27:
	addq	$9, %rdx
	jmp	LBB50_41
LBB50_26:
	addq	$10, %rdx
	jmp	LBB50_41
LBB50_25:
	addq	$11, %rdx
	jmp	LBB50_41
LBB50_38:
	addq	$12, %rdx
	jmp	LBB50_41
LBB50_24:
	addq	$13, %rdx
	jmp	LBB50_41
LBB50_23:
	addq	$14, %rdx
LBB50_41:
	movzbl	24(%rdi), %ecx
	movl	28(%rdi), %eax
	leal	2147483647(%rax), %esi
	andl	%edx, %esi
	shrl	%cl, %edx
	xorl	%r8d, %r8d
	movl	%edx, %ecx
	subl	$1, %ecx
	cmovbl	%r8d, %ecx
	testl	%edx, %edx
	cmovnel	%eax, %edx
	addl	%esi, %edx
	movslq	%edx, %rax
	addl	16(%rdi), %ecx
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %rax
	popq	%rbx
	popq	%rbp
	vzeroupper
	retq
	.cfi_endproc
