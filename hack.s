.section .data
//.global beforesend_count
beforesend_count: .quad 0
//.global beforemethod_count
beforemethod_count: .quad 0

.section .text
.intel_syntax noprefix

.global beforesend
beforesend:
add QWORD PTR [rip + beforesend_count], 1
ret

.global beforemethod
beforemethod:
add QWORD PTR [rip + beforemethod_count], 1
ret
