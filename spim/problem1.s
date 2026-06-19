.data
path:    .asciiz "/home/aarsh_kaushik/spim/input.txt"
msg:     .asciiz "Histogram:\n"
err_msg: .asciiz "Error: could not open file\n"
.align 2          # <-- forces next variable to 4-byte boundary
array:   .space 44
buffer:  .space 1
msg1:    .asciiz "[1-10]: "
msg2:    .asciiz "[11-20]: "
msg3:    .asciiz "[21-30]: "
msg4:    .asciiz "[31-40]: "
msg5:    .asciiz "[41-50]: "
msg6:    .asciiz "[51-60]: "
msg7:    .asciiz "[61-70]: "
msg8:    .asciiz "[71-80]: "
msg9:    .asciiz "[81-90]: "
msg10:   .asciiz "[91-100]: "
msg11:   .asciiz ">100: "
newline: .asciiz "\n"


.text
.globl main

main:
    # Print histogram header
    li $v0, 4
    la $a0, msg
    syscall

    # Open file
    li $v0, 13
    la $a0, path
    li $a1, 0
    li $a2, 0
    syscall
    move $s0, $v0

    # Check if file opened successfully
    bltz $s0, file_error

    li $t0, 0               # current number being built

loop1:
    li $v0, 14
    move $a0, $s0
    la $a1, buffer
    li $a2, 1
    syscall

    blez $v0, process_last  # EOF reached

    lb $t1, buffer
    beq $t1, 10, process_number   # newline
    beq $t1, 13, loop1            # carriage return (Windows)

    # Build number
    mul $t0, $t0, 10
    addi $t1, $t1, -48
    add $t0, $t0, $t1
    j loop1

process_last:
    beqz $t0, end
    j process_number

process_number:
    beqz $t0, reset

    bgt $t0, 100, greater_than_100

    li $t1, 10
    div $t0, $t1
    mflo $t2
    mfhi $t7

    beqz $t7, decrement
    j store_value

decrement:
    addi $t2, $t2, -1

store_value:
    sll $t3, $t2, 2
    la $t4, array
    add $t5, $t4, $t3
    lw $t6, 0($t5)
    addi $t6, $t6, 1
    sw $t6, 0($t5)
    j reset

greater_than_100:
    la $t4, array
    addi $t5, $t4, 40
    lw $t6, 0($t5)
    addi $t6, $t6, 1
    sw $t6, 0($t5)
    j reset

reset:
    li $t0, 0
    j loop1

file_error:
    li $v0, 4
    la $a0, err_msg
    syscall
    li $v0, 10
    syscall

end:
    # Close file
    li $v0, 16
    move $a0, $s0
    syscall

    # Print [1-10]
    li $v0, 4
    la $a0, msg1
    syscall
    la $t4, array
    lw $a0, 0($t4)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Print [11-20]
    li $v0, 4
    la $a0, msg2
    syscall
    la $t4, array
    lw $a0, 4($t4)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Print [21-30]
    li $v0, 4
    la $a0, msg3
    syscall
    la $t4, array
    lw $a0, 8($t4)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Print [31-40]
    li $v0, 4
    la $a0, msg4
    syscall
    la $t4, array
    lw $a0, 12($t4)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Print [41-50]
    li $v0, 4
    la $a0, msg5
    syscall
    la $t4, array
    lw $a0, 16($t4)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Print [51-60]
    li $v0, 4
    la $a0, msg6
    syscall
    la $t4, array
    lw $a0, 20($t4)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Print [61-70]
    li $v0, 4
    la $a0, msg7
    syscall
    la $t4, array
    lw $a0, 24($t4)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Print [71-80]
    li $v0, 4
    la $a0, msg8
    syscall
    la $t4, array
    lw $a0, 28($t4)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Print [81-90]
    li $v0, 4
    la $a0, msg9
    syscall
    la $t4, array
    lw $a0, 32($t4)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Print [91-100]
    li $v0, 4
    la $a0, msg10
    syscall
    la $t4, array
    lw $a0, 36($t4)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Print [>100]
    li $v0, 4
    la $a0, msg11
    syscall
    la $t4, array
    lw $a0, 40($t4)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Exit
    li $v0, 10
    syscall