_hdr_value_at_percentile:               ## @hdr_value_at_percentile
	.cfi_startproc
## %bb.0:
	movq	88(%rdi), %rax
	testq	%rax, %rax
	je	LBB34_1
## %bb.3:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r14
	pushq	%rbx
	subq	$16, %rsp
	.cfi_offset %rbx, -32
	.cfi_offset %r14, -24
	movq	%rdi, %rbx
	movsd	LCPI34_0(%rip), %xmm1           ## xmm1 = [1.0E+2,0.0E+0]
	movapd	%xmm0, %xmm2
	minsd	%xmm1, %xmm2
	divsd	%xmm1, %xmm2
	cvtsi2sd	%rax, %xmm1
	mulsd	%xmm1, %xmm2
	addsd	LCPI34_1(%rip), %xmm2
	pushq	$1
	popq	%rsi
	ucomisd	LCPI34_2(%rip), %xmm2
	movq	%rsi, %rcx
	jb	LBB34_6
## %bb.4:
	ucomisd	%xmm1, %xmm2
	movq	%rax, %rcx
	jae	LBB34_6
## %bb.5:
	cvttsd2si	%xmm2, %rcx
LBB34_6:
	cmpq	$2, %rcx
	cmovgeq	%rcx, %rsi
	movl	64(%rbx), %edx
	testl	%edx, %edx
	je	LBB34_7
## %bb.9:
	movl	80(%rbx), %ecx
	xorl	%eax, %eax
	testl	%ecx, %ecx
	jle	LBB34_28
## %bb.10:
	movq	96(%rbx), %rdi
	movl	%ecx, %r8d
	negl	%r8d
	negl	%edx
	movslq	%edx, %r9
	xorl	%r10d, %r10d
	xorl	%edx, %edx
LBB34_11:                               ## =>This Inner Loop Header: Depth=1
	cmpl	%ecx, %r9d
	movl	%r8d, %r11d
	cmovll	%eax, %r11d
	testl	%r9d, %r9d
	cmovsl	%ecx, %r11d
	movslq	%r11d, %r11
	addq	%r9, %r11
	addq	(%rdi,%r11,8), %r10
	cmpq	%rsi, %r10
	jge	LBB34_21
## %bb.12:                              ##   in Loop: Header=BB34_11 Depth=1
	incl	%edx
	incq	%r9
	cmpl	%edx, %ecx
	jne	LBB34_11
	jmp	LBB34_28
LBB34_7:
	testb	$4, ___cpu_model+13(%rip)
	jne	LBB34_8
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
	jle	LBB34_14
## %bb.15:
	xorl	%r9d, %r9d
	movq	%rdi, %r10
	xorl	%edx, %edx
	xorl	%r11d, %r11d
LBB34_16:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB34_19 Depth 2
	movdqu	(%rdi,%rdx,8), %xmm2
	movdqu	16(%rdi,%rdx,8), %xmm1
	paddq	%xmm2, %xmm1
	pshufd	$238, %xmm1, %xmm2              ## xmm2 = xmm1[2,3,2,3]
	paddq	%xmm1, %xmm2
	movq	%xmm2, %r8
	addq	%r11, %r8
	cmpq	%rsi, %r8
	jae	LBB34_17
LBB34_22:                               ##   in Loop: Header=BB34_16 Depth=1
	addq	$4, %rdx
	addq	$-4, %r9
	addq	$32, %r10
	movq	%r8, %r11
	cmpl	%edx, %eax
	jg	LBB34_16
	jmp	LBB34_23
LBB34_17:                               ##   in Loop: Header=BB34_16 Depth=1
	xorl	%r14d, %r14d
	movq	%r11, %r8
LBB34_19:                               ##   Parent Loop BB34_16 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	addq	(%r10,%r14,8), %r8
	cmpq	%rsi, %r8
	jge	LBB34_20
## %bb.18:                              ##   in Loop: Header=BB34_19 Depth=2
	incq	%r14
	cmpq	$4, %r14
	jne	LBB34_19
	jmp	LBB34_22
LBB34_8:
	movq	%rbx, %rdi
	movsd	%xmm0, -24(%rbp)                ## 8-byte Spill
	callq	_get_value_from_idx_up_to_count_avx2
	movsd	-24(%rbp), %xmm0                ## 8-byte Reload
                                        ## xmm0 = mem[0],zero
	jmp	LBB34_28
LBB34_14:
	xorl	%edx, %edx
	xorl	%r8d, %r8d
LBB34_23:
	cmpl	%ecx, %edx
	jge	LBB34_24
## %bb.25:
	movl	%edx, %eax
	leaq	(%rdi,%rax,8), %rdi
	xorl	%eax, %eax
LBB34_26:                               ## =>This Inner Loop Header: Depth=1
	addq	(%rdi), %r8
	cmpq	%rsi, %r8
	jge	LBB34_21
## %bb.27:                              ##   in Loop: Header=BB34_26 Depth=1
	incl	%edx
	addq	$8, %rdi
	cmpl	%edx, %ecx
	jg	LBB34_26
	jmp	LBB34_28
LBB34_24:
	xorl	%eax, %eax
	jmp	LBB34_28
LBB34_20:
	subl	%r9d, %r14d
	movl	%r14d, %edx
LBB34_21:
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
LBB34_28:
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
	jne	LBB34_29
	jnp	LBB34_30
LBB34_29:
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
LBB34_30:
	addq	$16, %rsp
	popq	%rbx
	popq	%r14
	popq	%rbp
LBB34_2:
	movq	%rdx, %rax
	retq
LBB34_1:
	xorl	%edx, %edx
	jmp	LBB34_2
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
	subq	$184, %rsp
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movq	%rcx, %r8
	movq	%rsi, -64(%rbp)                 ## 8-byte Spill
	testq	%rsi, %rsi
	sete	%al
	testq	%rdx, %rdx
	sete	%cl
	orb	%al, %cl
	movl	$22, %ebx
	jne	LBB35_45
## %bb.1:
	movq	%rdx, %r14
	movq	%rdi, %r12
	movq	88(%rdi), %rax
	testq	%rax, %rax
	je	LBB35_2
## %bb.4:
	testq	%r8, %r8
	je	LBB35_10
## %bb.5:
	cvtsi2sd	%rax, %xmm0
	xorl	%ecx, %ecx
	movsd	LCPI35_0(%rip), %xmm1           ## xmm1 = [1.0E+2,0.0E+0]
	movsd	LCPI35_1(%rip), %xmm2           ## xmm2 = [5.0E-1,0.0E+0]
	movsd	LCPI35_2(%rip), %xmm3           ## xmm3 = [1.0E+0,0.0E+0]
LBB35_6:                                ## =>This Inner Loop Header: Depth=1
	movq	-64(%rbp), %rdx                 ## 8-byte Reload
	movsd	(%rdx,%rcx,8), %xmm4            ## xmm4 = mem[0],zero
	minsd	%xmm1, %xmm4
	divsd	%xmm1, %xmm4
	mulsd	%xmm0, %xmm4
	addsd	%xmm2, %xmm4
	movl	$1, %edx
	ucomisd	%xmm3, %xmm4
	jb	LBB35_9
## %bb.7:                               ##   in Loop: Header=BB35_6 Depth=1
	ucomisd	%xmm0, %xmm4
	movq	%rax, %rdx
	jae	LBB35_9
## %bb.8:                               ##   in Loop: Header=BB35_6 Depth=1
	cvttsd2si	%xmm4, %rdx
LBB35_9:                                ##   in Loop: Header=BB35_6 Depth=1
	movq	%rdx, (%r14,%rcx,8)
	incq	%rcx
	cmpq	%rcx, %r8
	jne	LBB35_6
LBB35_10:
	cmpl	$0, 64(%r12)
	movq	%r8, -56(%rbp)                  ## 8-byte Spill
	jne	LBB35_31
## %bb.11:
	movq	96(%r12), %rax
	movq	%rax, -48(%rbp)                 ## 8-byte Spill
	movslq	80(%r12), %rcx
	movq	%rcx, -72(%rbp)                 ## 8-byte Spill
	cmpq	$8, %rcx
	setl	%al
	testq	%r8, %r8
	sete	%cl
	orb	%al, %cl
	jne	LBB35_12
## %bb.21:
	movl	$8, %eax
	xorl	%r13d, %r13d
	xorl	%ebx, %ebx
	xorl	%r15d, %r15d
LBB35_22:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB35_24 Depth 2
                                        ##       Child Loop BB35_25 Depth 3
	movq	%rax, -80(%rbp)                 ## 8-byte Spill
	movq	-48(%rbp), %rax                 ## 8-byte Reload
	movdqu	(%rax,%r13,8), %xmm0
	movdqu	16(%rax,%r13,8), %xmm1
	movdqu	32(%rax,%r13,8), %xmm2
	paddq	%xmm0, %xmm2
	movdqu	48(%rax,%r13,8), %xmm0
	paddq	%xmm1, %xmm0
	paddq	%xmm2, %xmm0
	pshufd	$238, %xmm0, %xmm1              ## xmm1 = xmm0[2,3,2,3]
	paddq	%xmm0, %xmm1
	movq	%xmm1, %rax
	addq	%r15, %rax
	cmpq	(%r14,%rbx,8), %rax
	movq	%r13, -88(%rbp)                 ## 8-byte Spill
	jge	LBB35_24
## %bb.23:                              ##   in Loop: Header=BB35_22 Depth=1
	movq	%rax, %r15
	jmp	LBB35_29
LBB35_24:                               ##   Parent Loop BB35_22 Depth=1
                                        ## =>  This Loop Header: Depth=2
                                        ##       Child Loop BB35_25 Depth 3
	movq	-48(%rbp), %rax                 ## 8-byte Reload
	addq	(%rax,%r13,8), %r15
	cmpq	%r8, %rbx
	jae	LBB35_28
LBB35_25:                               ##   Parent Loop BB35_22 Depth=1
                                        ##     Parent Loop BB35_24 Depth=2
                                        ## =>    This Inner Loop Header: Depth=3
	cmpq	(%r14,%rbx,8), %r15
	jl	LBB35_28
## %bb.26:                              ##   in Loop: Header=BB35_25 Depth=3
	movb	24(%r12), %cl
	movl	%r13d, %eax
	shrl	%cl, %eax
	movl	28(%r12), %edx
	leal	2147483647(%rdx), %esi
	andl	%r13d, %esi
	movl	%eax, %ecx
	subl	$1, %ecx
	movl	$0, %edi
	cmovbl	%edi, %ecx
	movq	-64(%rbp), %rdi                 ## 8-byte Reload
	movq	(%rdi,%rbx,8), %xmm0            ## xmm0 = mem[0],zero
	testl	%eax, %eax
	cmovnel	%edx, %eax
	addl	%esi, %eax
	movslq	%eax, %rsi
	addl	16(%r12), %ecx
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %rsi
	movq	%r12, %rdi
	callq	_percentile_bound
	movq	-56(%rbp), %r8                  ## 8-byte Reload
	movq	%rax, (%r14,%rbx,8)
	incq	%rbx
	cmpq	%rbx, %r8
	jne	LBB35_25
## %bb.27:                              ##   in Loop: Header=BB35_24 Depth=2
	movq	%r8, %rbx
LBB35_28:                               ##   in Loop: Header=BB35_24 Depth=2
	incq	%r13
	cmpq	-80(%rbp), %r13                 ## 8-byte Folded Reload
	jne	LBB35_24
LBB35_29:                               ##   in Loop: Header=BB35_22 Depth=1
	movq	-80(%rbp), %rcx                 ## 8-byte Reload
	leaq	8(%rcx), %rax
	cmpq	-72(%rbp), %rax                 ## 8-byte Folded Reload
	movq	-88(%rbp), %r13                 ## 8-byte Reload
	ja	LBB35_13
## %bb.30:                              ##   in Loop: Header=BB35_22 Depth=1
	addq	$8, %r13
	cmpq	%r8, %rbx
	jb	LBB35_22
	jmp	LBB35_13
LBB35_12:
	xorl	%r15d, %r15d
	xorl	%ebx, %ebx
	xorl	%ecx, %ecx
LBB35_13:
	cmpl	-72(%rbp), %ecx                 ## 4-byte Folded Reload
	jge	LBB35_38
## %bb.14:
	cmpq	%r8, %rbx
	jae	LBB35_38
## %bb.15:
	movl	%ecx, %r13d
LBB35_16:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB35_17 Depth 2
	movq	-48(%rbp), %rax                 ## 8-byte Reload
	addq	(%rax,%r13,8), %r15
LBB35_17:                               ##   Parent Loop BB35_16 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	cmpq	(%r14,%rbx,8), %r15
	jl	LBB35_19
## %bb.18:                              ##   in Loop: Header=BB35_17 Depth=2
	movb	24(%r12), %cl
	movl	%r13d, %eax
	shrl	%cl, %eax
	movl	28(%r12), %edx
	leal	2147483647(%rdx), %esi
	andl	%r13d, %esi
	movl	%eax, %ecx
	subl	$1, %ecx
	movl	$0, %edi
	cmovbl	%edi, %ecx
	movq	-64(%rbp), %rdi                 ## 8-byte Reload
	movsd	(%rdi,%rbx,8), %xmm0            ## xmm0 = mem[0],zero
	testl	%eax, %eax
	cmovnel	%edx, %eax
	addl	%esi, %eax
	movslq	%eax, %rsi
	addl	16(%r12), %ecx
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %rsi
	movq	%r12, %rdi
	callq	_percentile_bound
	movq	-56(%rbp), %r8                  ## 8-byte Reload
	movq	%rax, (%r14,%rbx,8)
	incq	%rbx
	cmpq	%r8, %rbx
	jb	LBB35_17
LBB35_19:                               ##   in Loop: Header=BB35_16 Depth=1
	incq	%r13
	cmpq	-72(%rbp), %r13                 ## 8-byte Folded Reload
	jge	LBB35_38
## %bb.20:                              ##   in Loop: Header=BB35_16 Depth=1
	cmpq	%r8, %rbx
	jb	LBB35_16
LBB35_38:
	cmpq	%r8, %rbx
	jae	LBB35_44
## %bb.39:
	xorpd	%xmm0, %xmm0
LBB35_40:                               ## =>This Inner Loop Header: Depth=1
	movq	-64(%rbp), %rax                 ## 8-byte Reload
	movsd	(%rax,%rbx,8), %xmm1            ## xmm1 = mem[0],zero
	ucomisd	%xmm0, %xmm1
	jne	LBB35_42
	jp	LBB35_42
## %bb.41:                              ##   in Loop: Header=BB35_40 Depth=1
	xorl	%eax, %eax
	jmp	LBB35_43
LBB35_42:                               ##   in Loop: Header=BB35_40 Depth=1
	bsrq	32(%r12), %rax
	xorl	$63, %eax
	xorl	%ecx, %ecx
	cmpl	$0, 40(%r12)
	setle	%cl
	addl	24(%r12), %eax
	subl	%eax, %ecx
	addb	$63, %cl
	movq	$-1, %rax
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %rax
	notq	%rax
LBB35_43:                               ##   in Loop: Header=BB35_40 Depth=1
	movq	%rax, (%r14,%rbx,8)
	incq	%rbx
	cmpq	%rbx, %r8
	jne	LBB35_40
LBB35_44:
	xorl	%ebx, %ebx
LBB35_45:
	movl	%ebx, %eax
	addq	$184, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
LBB35_2:
	xorl	%ebx, %ebx
	testq	%r8, %r8
	je	LBB35_45
## %bb.3:
	shlq	$3, %r8
	movq	%r14, %rdi
	movq	%r8, %rsi
	callq	___bzero
	jmp	LBB35_45
LBB35_31:
	leaq	-216(%rbp), %rdi
	movq	%r12, (%rdi)
	movl	$-1, 8(%rdi)
	movq	88(%r12), %rax
	movq	%rax, 16(%rdi)
	xorpd	%xmm0, %xmm0
	movupd	%xmm0, 24(%rdi)
	movupd	%xmm0, 40(%rdi)
	movupd	%xmm0, 72(%rdi)
	leaq	_all_values_iter_next(%rip), %rax
	movq	%rax, 120(%rdi)
	callq	_all_values_iter_next
	movq	-56(%rbp), %r8                  ## 8-byte Reload
	xorb	$1, %al
	testq	%r8, %r8
	sete	%cl
	xorl	%ebx, %ebx
	orb	%al, %cl
	jne	LBB35_38
## %bb.32:
	leaq	-216(%rbp), %r13
	xorl	%r15d, %r15d
LBB35_33:                               ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB35_34 Depth 2
	addq	-192(%rbp), %r15
	movq	-176(%rbp), %rax
	movq	%rax, -48(%rbp)                 ## 8-byte Spill
LBB35_34:                               ##   Parent Loop BB35_33 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	cmpq	(%r14,%rbx,8), %r15
	jl	LBB35_36
## %bb.35:                              ##   in Loop: Header=BB35_34 Depth=2
	movq	-64(%rbp), %rax                 ## 8-byte Reload
	movsd	(%rax,%rbx,8), %xmm0            ## xmm0 = mem[0],zero
	movq	%r12, %rdi
	movq	-48(%rbp), %rsi                 ## 8-byte Reload
	callq	_percentile_bound
	movq	%rax, (%r14,%rbx,8)
	incq	%rbx
	cmpq	-56(%rbp), %rbx                 ## 8-byte Folded Reload
	jb	LBB35_34
LBB35_36:                               ##   in Loop: Header=BB35_33 Depth=1
	movq	%r13, %rdi
	callq	*-96(%rbp)
	movq	-56(%rbp), %r8                  ## 8-byte Reload
	cmpq	%r8, %rbx
	jae	LBB35_38
## %bb.37:                              ##   in Loop: Header=BB35_33 Depth=1
	testb	%al, %al
	jne	LBB35_33
	jmp	LBB35_38
	.cfi_endproc

_percentile_bound:                      ## -- Begin function percentile_bound
                                        ## @percentile_bound
	.cfi_startproc
## %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	movq	32(%rdi), %rax
	orq	%rsi, %rax
	bsrq	%rax, %rax
	xorl	$63, %eax
	addl	24(%rdi), %eax
	movl	$63, %ecx
	subl	%eax, %ecx
	sarq	%cl, %rsi
	movslq	%esi, %rax
	shlq	%cl, %rax
	xorpd	%xmm1, %xmm1
	ucomisd	%xmm1, %xmm0
	jne	LBB36_1
	jnp	LBB36_2
LBB36_1:
	xorl	%edx, %edx
	cmpl	%esi, 40(%rdi)
	setle	%dl
	addl	%edx, %ecx
	movl	$1, %edx
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %rdx
	movabsq	$9223372036854775807, %rcx      ## imm = 0x7FFFFFFFFFFFFFFF
	movq	%rcx, %rsi
	subq	%rdx, %rsi
	cmpq	%rsi, %rax
	leaq	-1(%rax,%rdx), %rax
	cmovgq	%rcx, %rax
LBB36_2:
	popq	%rbp
	retq
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
	jge	LBB45_1
## %bb.3:
	cmpl	$-1, 8(%rbx)
	jne	LBB45_6
## %bb.4:
	movq	(%rbx), %rax
	cmpl	$0, 80(%rax)
	jns	LBB45_5
	jmp	LBB45_2
LBB45_1:
	cmpb	$0, 88(%rbx)
	je	LBB45_11
LBB45_2:
	xorl	%eax, %eax
	jmp	LBB45_13
LBB45_11:
	movb	$1, 88(%rbx)
	movabsq	$4636737291354636288, %rax      ## imm = 0x4059000000000000
	movq	%rax, 104(%rbx)
	jmp	LBB45_12
LBB45_5:
	movq	%rbx, %rdi
	callq	_move_next
LBB45_6:
	movq	(%rbx), %rdx
	movq	32(%rbx), %rcx
	cmpq	$0, 24(%rbx)
	je	LBB45_9
## %bb.7:
	xorps	%xmm0, %xmm0
	cvtsi2sd	%rcx, %xmm0
	mulsd	LCPI45_0(%rip), %xmm0
	xorps	%xmm1, %xmm1
	cvtsi2sdq	88(%rdx), %xmm1
	divsd	%xmm1, %xmm0
	movsd	96(%rbx), %xmm1                 ## xmm1 = mem[0],zero
	ucomisd	%xmm1, %xmm0
	jae	LBB45_8
LBB45_9:
	movb	$1, %al
	cmpq	16(%rbx), %rcx
	jge	LBB45_13
## %bb.10:
	movl	8(%rbx), %ecx
	cmpl	80(%rdx), %ecx
	jl	LBB45_5
	jmp	LBB45_13
LBB45_8:
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
	movsd	LCPI45_0(%rip), %xmm2           ## xmm2 = [1.0E+2,0.0E+0]
	movapd	%xmm1, %xmm0
	movsd	%xmm1, -16(%rbp)                ## 8-byte Spill
	movapd	%xmm2, %xmm1
	subsd	%xmm0, %xmm1
	movapd	%xmm2, %xmm0
	divsd	%xmm1, %xmm0
	callq	_log
	divsd	LCPI45_1(%rip), %xmm0
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
	movsd	LCPI45_0(%rip), %xmm1           ## xmm1 = [1.0E+2,0.0E+0]
	divsd	%xmm0, %xmm1
	addsd	-16(%rbp), %xmm1                ## 8-byte Folded Reload
	movsd	%xmm1, 96(%rbx)
LBB45_12:
	movb	$1, %al
LBB45_13:
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
	subq	$200, %rsp
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movl	%ecx, %r15d
	movsd	%xmm0, -88(%rbp)                ## 8-byte Spill
	movl	%edx, %r12d
	movq	%rsi, %rbx
	movq	%rdi, %r14
	movq	___stack_chk_guard@GOTPCREL(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, -48(%rbp)
	movl	20(%rdi), %r8d
	testl	%ecx, %ecx
	je	LBB52_3
## %bb.1:
	cmpl	$1, %r15d
	jne	LBB52_3
## %bb.2:
	leaq	L_.str.4(%rip), %rdx
	leaq	L_.str.5(%rip), %rcx
	leaq	L_.str.6(%rip), %r9
	jmp	LBB52_4
LBB52_3:
	leaq	L_.str.4(%rip), %rdx
	leaq	L_.str.7(%rip), %rcx
	leaq	L_.str.8(%rip), %r9
LBB52_4:
	leaq	-80(%rbp), %rdi
	movl	$25, %esi
	xorl	%eax, %eax
	callq	_snprintf
	cmpl	$1, %r15d
	leaq	L_.str.9(%rip), %rax
	leaq	L_.str.10(%rip), %rsi
	cmoveq	%rax, %rsi
	movq	%r14, -240(%rbp)
	movl	$-1, -232(%rbp)
	movq	88(%r14), %rax
	movq	%rax, -224(%rbp)
	xorpd	%xmm0, %xmm0
	movupd	%xmm0, -216(%rbp)
	movupd	%xmm0, -200(%rbp)
	movupd	%xmm0, -168(%rbp)
	movb	$0, -152(%rbp)
	movl	%r12d, -148(%rbp)
	movupd	%xmm0, -144(%rbp)
	leaq	_percentile_iter_next(%rip), %rax
	movq	%rax, -120(%rbp)
	leaq	L_.str(%rip), %rdx
	leaq	L_.str.1(%rip), %rcx
	leaq	L_.str.2(%rip), %r8
	leaq	L_.str.3(%rip), %r9
	xorl	%r12d, %r12d
	movq	%rbx, %rdi
	xorl	%eax, %eax
	callq	_fprintf
	testl	%eax, %eax
	js	LBB52_5
## %bb.6:
	movl	%r15d, -96(%rbp)                ## 4-byte Spill
	movq	%r14, -112(%rbp)                ## 8-byte Spill
	leaq	-240(%rbp), %r13
	leaq	-80(%rbp), %r15
	movl	$5, %r14d
LBB52_7:                                ## =>This Inner Loop Header: Depth=1
	movq	%r13, %rdi
	callq	*-120(%rbp)
	testb	%al, %al
	je	LBB52_9
## %bb.8:                               ##   in Loop: Header=BB52_7 Depth=1
	xorps	%xmm0, %xmm0
	cvtsi2sdq	-192(%rbp), %xmm0
	divsd	-88(%rbp), %xmm0                ## 8-byte Folded Reload
	movsd	-136(%rbp), %xmm1               ## xmm1 = mem[0],zero
	divsd	LCPI52_0(%rip), %xmm1
	movq	-208(%rbp), %rdx
	movsd	LCPI52_1(%rip), %xmm2           ## xmm2 = [1.0E+0,0.0E+0]
	movapd	%xmm2, %xmm3
	subsd	%xmm1, %xmm3
	divsd	%xmm3, %xmm2
	movq	%rbx, %rdi
	movq	%r15, %rsi
	movb	$3, %al
	callq	_fprintf
	testl	%eax, %eax
	cmovsl	%r14d, %r12d
	jns	LBB52_7
	jmp	LBB52_11
LBB52_5:
	movl	$5, %r12d
	jmp	LBB52_11
LBB52_9:
	cmpl	$0, -96(%rbp)                   ## 4-byte Folded Reload
	jne	LBB52_11
## %bb.10:
	movq	-112(%rbp), %r14                ## 8-byte Reload
	movq	%r14, %rdi
	callq	_hdr_mean
	divsd	-88(%rbp), %xmm0                ## 8-byte Folded Reload
	movsd	%xmm0, -96(%rbp)                ## 8-byte Spill
	movq	%r14, %rdi
	callq	_hdr_stddev
	divsd	-88(%rbp), %xmm0                ## 8-byte Folded Reload
	movsd	%xmm0, -104(%rbp)               ## 8-byte Spill
	movq	%r14, %rdi
	callq	_hdr_max
	xorps	%xmm2, %xmm2
	cvtsi2sd	%rax, %xmm2
	divsd	-88(%rbp), %xmm2                ## 8-byte Folded Reload
	movq	88(%r14), %rdx
	movl	40(%r14), %r8d
	movl	44(%r14), %ecx
	leaq	_CLASSIC_FOOTER(%rip), %rsi
	movq	%rbx, %rdi
	movsd	-96(%rbp), %xmm0                ## 8-byte Reload
                                        ## xmm0 = mem[0],zero
	movsd	-104(%rbp), %xmm1               ## 8-byte Reload
                                        ## xmm1 = mem[0],zero
	movb	$3, %al
	callq	_fprintf
	testl	%eax, %eax
	movl	$5, %eax
	cmovsl	%eax, %r12d
LBB52_11:
	movq	___stack_chk_guard@GOTPCREL(%rip), %rax
	movq	(%rax), %rax
	cmpq	-48(%rbp), %rax
	jne	LBB52_13
## %bb.12:
	movl	%r12d, %eax
	addq	$200, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
LBB52_13:
	callq	___stack_chk_fail
	.cfi_endproc

_get_value_from_idx_up_to_count_avx2:   ## -- Begin function get_value_from_idx_up_to_count_avx2
                                        ## @get_value_from_idx_up_to_count_avx2
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
	.cfi_offset %rbx, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movl	80(%rdi), %ecx
	movl	%ecx, %edx
	andl	$-16, %edx
	testl	%edx, %edx
	jle	LBB53_1
## %bb.4:
	movq	96(%rdi), %r8
	leal	-1(%rcx), %r11d
	xorl	%r9d, %r9d
	movq	%r8, %rbx
	xorl	%eax, %eax
	xorl	%r15d, %r15d
LBB53_5:                                ## =>This Loop Header: Depth=1
                                        ##     Child Loop BB53_7 Depth 2
	leal	64(%rax), %r10d
	cmpl	%ecx, %r10d
	cmovgel	%r11d, %r10d
	movslq	%r10d, %r10
	prefetcht0	(%r8,%r10,8)
	vmovdqu	32(%r8,%rax,8), %ymm0
	vpaddq	(%r8,%rax,8), %ymm0, %ymm0
	vpaddq	64(%r8,%rax,8), %ymm0, %ymm0
	vpaddq	96(%r8,%rax,8), %ymm0, %ymm0
	vextracti128	$1, %ymm0, %xmm1
	vpaddq	%xmm1, %xmm0, %xmm0
	vpextrq	$1, %xmm0, %r14
	vmovq	%xmm0, %r10
	addq	%r15, %r10
	addq	%r14, %r10
	cmpq	%rsi, %r10
	jge	LBB53_6
LBB53_9:                                ##   in Loop: Header=BB53_5 Depth=1
	addq	$16, %rax
	addq	$-16, %r9
	subq	$-128, %rbx
	movq	%r10, %r15
	cmpq	%rdx, %rax
	jb	LBB53_5
	jmp	LBB53_2
LBB53_6:                                ##   in Loop: Header=BB53_5 Depth=1
	xorl	%r14d, %r14d
	movq	%r15, %r10
LBB53_7:                                ##   Parent Loop BB53_5 Depth=1
                                        ## =>  This Inner Loop Header: Depth=2
	addq	(%rbx,%r14,8), %r10
	cmpq	%rsi, %r10
	jge	LBB53_13
## %bb.8:                               ##   in Loop: Header=BB53_7 Depth=2
	incq	%r14
	cmpq	$16, %r14
	jne	LBB53_7
	jmp	LBB53_9
LBB53_1:
	xorl	%eax, %eax
	xorl	%r10d, %r10d
LBB53_2:
	cmpl	%ecx, %eax
	jge	LBB53_3
## %bb.10:
	movq	96(%rdi), %rdx
	movl	%eax, %r14d
	xorl	%eax, %eax
LBB53_11:                               ## =>This Inner Loop Header: Depth=1
	addq	(%rdx,%r14,8), %r10
	cmpq	%rsi, %r10
	jge	LBB53_14
## %bb.12:                              ##   in Loop: Header=BB53_11 Depth=1
	incq	%r14
	cmpq	%r14, %rcx
	jne	LBB53_11
	jmp	LBB53_15
LBB53_3:
	xorl	%eax, %eax
	jmp	LBB53_15
LBB53_13:
	subq	%r9, %r14
LBB53_14:
	movb	24(%rdi), %cl
	movl	28(%rdi), %eax
	leal	2147483647(%rax), %edx
	andl	%r14d, %edx
	shrl	%cl, %r14d
	xorl	%esi, %esi
	movl	%r14d, %ecx
	subl	$1, %ecx
	cmovbl	%esi, %ecx
	testl	%r14d, %r14d
	cmovnel	%eax, %r14d
	addl	%edx, %r14d
	movslq	%r14d, %rax
	addl	16(%rdi), %ecx
                                        ## kill: def $cl killed $cl killed $ecx
	shlq	%cl, %rax
LBB53_15:
	popq	%rbx
	popq	%r14
	popq	%r15
	popq	%rbp
	vzeroupper
	retq
	.cfi_endproc
