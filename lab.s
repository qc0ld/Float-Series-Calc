bits 64
; Compare exponent from mathlib and my own implementation
section .data
filename:
	db "result",0
result:
	db "%.10g) %.10g",10,0
flags:
	db "a",0
msg0:
	db "Input accuracy", 10, 0
msg1:
	db "Input x", 10, 0
msg10:
	db "Input a", 10, 0
msg2:
	db "%lf", 0
msg3:
	db "pow(1 + %.10g)=%.10g", 10, 0
msg4:
	db "mypow(1 + %.10g)=%.10g", 10, 0
msg5:
	db "Cant be negative and zero",10,0
msg6:
	db "Bad input",10, 0
msg7:
	db "File error",10, 0
msg8:
	db "Absence of filename",10, 0

extern printf
extern scanf
extern pow
extern write
extern fopen
extern fprintf
extern fclose
global main

%define STDIN 0
%define STDOUT 1
%define STDERR 2

%define SYS_write 1
%define SYS_open 2


section .text

neg_one dq -1.0
one dq 1.0
two dq 2.0
zero dq 0.0
EOF dq 4294967295


input_x:
	push rbp
	jmp .m0
	.m1:
	mov edi, msg6
	xor rax, rax

	call printf

.m0:
	mov edi, msg2
	lea rsi, [rbp - x]
	xor rax, rax

	call scanf
	cmp rax, 0
	je m2
	cmp rax, [EOF]
	je m2

	ucomisd xmm0, [zero]
	jc .m2
	ucomisd xmm0, [one]
	jz .m1
	jnc .m1
	jmp .m3

.m2:
	mulsd xmm0, [neg_one]
	ucomisd xmm0, [one]
	jz .m1
	jnc .m1
	mulsd xmm0, [neg_one]
	jmp .m3
	.m3:
	pop rbp
	ret




mypow:
	push rbp
.n1:
	mov edi, msg0
	xor eax, eax
	call printf

	mov edi, msg2
	lea rsi, [rbp - z]
	xor eax, eax
	call scanf
	cmp rax, [zero]
	je m2
	cmp rax, [EOF]
	je m2

	movsd xmm9, [rbp - z]
	ucomisd xmm9, [zero]
	jc .n2
	je .n2

	movsd xmm0, [one]
	movsd xmm1, [one]
	mov rdi, r14
	mov rsi, result
	mov rax, 2
	call fprintf


	movsd xmm0, [rbp-x]
	movsd xmm9, [rbp-z]
	movsd xmm8, [rbp-a]
	movsd [rbp-last], xmm9

	movsd xmm11, [one]; знаменатель
	movsd xmm10, [one]; счетчик
	movsd xmm12, [one]; x^n
	movsd xmm13, [one];числитель
	; xmm14 ;член ряда
	movsd xmm15, [one] ;сумма ряда



.m1:
	mulsd xmm11, xmm10
	movsd xmm7, [rbp-a]
	subsd xmm7, xmm10
	addsd xmm7, [one]
	mulsd xmm13, xmm7
	mulsd xmm12, [rbp-x]
	movsd xmm14, xmm12
	mulsd xmm14, xmm13
	divsd xmm14, xmm11

	addsd xmm15, xmm14

	addsd xmm10, [one]
	movsd xmm0, xmm10
	movsd xmm1, xmm14
	mov rdi, r14
	mov rsi, result
	mov rax, 2
	call fprintf

	movsd xmm7, [rbp-last]
	movsd [rbp-last], xmm14

	ucomisd xmm14, [zero]
	jnc .m4
	mulsd xmm14, [neg_one]

.m4:
	ucomisd xmm7,[zero]
	jc .m2
.m3:
	ucomisd xmm10, [two]
	jnz .m5
	ucomisd xmm14, xmm9
	jnc .m1
	pop rbp
	ret
.m5:
	subsd xmm7, xmm14

	ucomisd xmm7, [zero]
	jnc .m6
	mulsd xmm7, [neg_one]
.m6:
	ucomisd xmm7, xmm9
	jnc .m1
	pop rbp
	ret
.m2:
	mulsd xmm7,[neg_one]
	jmp .m3

.n2:
	mov edi, msg5
	xor rax, rax
	call printf
	jmp .n1


x equ 16
y equ x+16
z equ y+16
a equ z+16
last equ a+16

main:
	push rbp
	mov rbp, rsp


	cmp rdi, 1
	je absence_of_filename
	xor rax, rax

	add rsi, 8
	mov r15, [rsi]
	mov rdi, [rsi]
	xor rax, rax
	mov rbx, 2048
	mov rcx, 2048
	repne scasb
	sub rbx, rcx
	dec rbx


	;file name is in rsi
	;lea rsi, [filename]
	;mov rax, SYS_open
	mov rdi, r15 ;put the * on filename in rdi
	lea rsi, [flags] ;check defines!!!
	;mov rdx, FILE_mod ;put the rights on file
	call fopen
	cmp rax, 0
	jle file_open_failed ; check it's not less than zero; exit with error otherwise
	mov r14, rax ;set file descriptor in r10


	;push rbp

	sub rsp, last

	mov edi, msg10
	xor eax, eax
	call printf

	mov edi, msg2
	lea rsi, [rbp-a]
	xor eax, eax
	call scanf
	cmp rax, [zero]
	je m2
	cmp rax, [EOF]
	je m2

	mov edi, msg1
	xor eax, eax
	call printf

	call input_x


	movsd xmm0, [rbp-x]
	addsd xmm0, [one]
	movsd xmm1, [rbp - a]
	call pow
	movsd [rbp-y], xmm0




	mov edi, msg3
	movsd xmm0, [rbp-x]
	movsd xmm1, [rbp-y]
	mov eax, 2
	call printf
	movsd xmm0, [rbp-x]
	movsd xmm8, [rbp-a]
	call mypow

	movsd xmm0, xmm15
	movsd [rbp-y], xmm0
	mov edi, msg4
	movsd xmm0, [rbp-x]
	movsd xmm1, [rbp-y]
	mov eax, 2
	call printf

	mov rdi, r14
	call fclose

	leave
	xor eax, eax
	ret
	m2:
	mov edi, msg6
	xor rax, rax
	call printf
	;pop rsp
	mov rdi, r14
	call fclose
	leave
	xor rax, rax
	ret
file_open_failed:
	mov edi, msg7
	xor rax, rax
	call printf
	;pop rsp
	leave
	xor rax, rax
	ret
absence_of_filename:
	mov edi, msg8
	xor rax, rax
	call printf
	;pop rsp

	leave
	xor rax, rax
	ret
