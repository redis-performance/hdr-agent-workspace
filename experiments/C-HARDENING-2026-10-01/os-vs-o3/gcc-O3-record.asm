0000000000004ca0 <hdr_record_value>:
    4ca0:	f3 0f 1e fa          	endbr64
    4ca4:	48 89 f8             	mov    %rdi,%rax
    4ca7:	48 89 f2             	mov    %rsi,%rdx
    4caa:	45 31 c0             	xor    %r8d,%r8d
    4cad:	48 85 f6             	test   %rsi,%rsi
    4cb0:	78 64                	js     4d16 <hdr_record_value+0x76>
    4cb2:	48 3b 77 08          	cmp    0x8(%rdi),%rsi
    4cb6:	7f 5e                	jg     4d16 <hdr_record_value+0x76>
    4cb8:	48 8b 4f 20          	mov    0x20(%rdi),%rcx
    4cbc:	44 8b 4f 18          	mov    0x18(%rdi),%r9d
    4cc0:	48 09 f1             	or     %rsi,%rcx
    4cc3:	48 0f bd c9          	bsr    %rcx,%rcx
    4cc7:	44 29 c9             	sub    %r9d,%ecx
    4cca:	89 cf                	mov    %ecx,%edi
    4ccc:	2b 78 10             	sub    0x10(%rax),%edi
    4ccf:	48 d3 fe             	sar    %cl,%rsi
    4cd2:	44 89 c9             	mov    %r9d,%ecx
    4cd5:	83 c7 01             	add    $0x1,%edi
    4cd8:	2b 70 1c             	sub    0x1c(%rax),%esi
    4cdb:	d3 e7                	shl    %cl,%edi
    4cdd:	8d 0c 3e             	lea    (%rsi,%rdi,1),%ecx
    4ce0:	8b 70 50             	mov    0x50(%rax),%esi
    4ce3:	39 f1                	cmp    %esi,%ecx
    4ce5:	73 2f                	jae    4d16 <hdr_record_value+0x76>
    4ce7:	8b 78 40             	mov    0x40(%rax),%edi
    4cea:	4c 8b 40 60          	mov    0x60(%rax),%r8
    4cee:	85 ff                	test   %edi,%edi
    4cf0:	75 2e                	jne    4d20 <hdr_record_value+0x80>
    4cf2:	48 63 c9             	movslq %ecx,%rcx
    4cf5:	49 8d 0c c8          	lea    (%r8,%rcx,8),%rcx
    4cf9:	0f 18 09             	prefetcht0 (%rcx)
    4cfc:	48 83 01 01          	addq   $0x1,(%rcx)
    4d00:	48 83 40 58 01       	addq   $0x1,0x58(%rax)
    4d05:	48 3b 50 38          	cmp    0x38(%rax),%rdx
    4d09:	7f 25                	jg     4d30 <hdr_record_value+0x90>
    4d0b:	48 85 d2             	test   %rdx,%rdx
    4d0e:	75 30                	jne    4d40 <hdr_record_value+0xa0>
    4d10:	41 b8 01 00 00 00    	mov    $0x1,%r8d
    4d16:	44 89 c0             	mov    %r8d,%eax
    4d19:	c3                   	ret
    4d1a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    4d20:	29 f9                	sub    %edi,%ecx
    4d22:	78 28                	js     4d4c <hdr_record_value+0xac>
    4d24:	89 cf                	mov    %ecx,%edi
    4d26:	29 f7                	sub    %esi,%edi
    4d28:	39 ce                	cmp    %ecx,%esi
    4d2a:	0f 4e cf             	cmovle %edi,%ecx
    4d2d:	eb c3                	jmp    4cf2 <hdr_record_value+0x52>
    4d2f:	90                   	nop
    4d30:	48 89 50 38          	mov    %rdx,0x38(%rax)
    4d34:	eb d5                	jmp    4d0b <hdr_record_value+0x6b>
    4d36:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    4d3d:	00 00 00
    4d40:	48 3b 50 30          	cmp    0x30(%rax),%rdx
    4d44:	7d ca                	jge    4d10 <hdr_record_value+0x70>
    4d46:	48 89 50 30          	mov    %rdx,0x30(%rax)
    4d4a:	eb c4                	jmp    4d10 <hdr_record_value+0x70>
    4d4c:	01 f1                	add    %esi,%ecx
    4d4e:	eb a2                	jmp    4cf2 <hdr_record_value+0x52>
