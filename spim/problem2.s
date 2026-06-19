.data
num_calls:  .word 0
left_val:   .word 0x00000000
right_val:  .word 0x3F800000
msg1:       .asciiz "Solution: "
msg2:       .asciiz "Number of calls: "
newline:    .asciiz "\n"

.text
.globl main

main:
    li $t0, 0
    sw $t0, num_calls
    li $t0, 0x00000000
    sw $t0, left_val
    li $t0, 0x3F800000
    sw $t0, right_val

    jal bisection

    li $v0, 4
    la $a0, msg1
    syscall

    mov.s $f12, $f0
    li $v0, 2
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    li $v0, 4
    la $a0, msg2
    syscall

    lw $a0, num_calls
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    li $v0, 10
    syscall

########################################
bisection:
    # increment call counter
    lw $t0, num_calls
    addi $t0, $t0, 1
    sw $t0, num_calls

    # save $ra on stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # load left and right from memory
    lw $t0, left_val
    mtc1 $t0, $f2           # $f2 = left
    lw $t1, right_val
    mtc1 $t1, $f4           # $f4 = right

    # mid = (left + right) / 2.0
    add.s $f6, $f2, $f4
    li $t0, 0x40000000      # 2.0
    mtc1 $t0, $f8
    div.s $f6, $f6, $f8     # $f6 = mid

    # --- compute f(mid) ---
    # save mid before calling f (f clobbers $f6)
    addi $sp, $sp, -4
    s.s $f6, 0($sp)

    mov.s $f12, $f6
    jal f
    mov.s $f10, $f0         # $f10 = f(mid)

    # restore mid
    l.s $f6, 0($sp)
    addi $sp, $sp, 4

    # termination: |f(mid)| < epsilon
    abs.s $f14, $f10
    li $t0, 0x36800000      # epsilon ~ 3.8e-6
    mtc1 $t0, $f16
    c.lt.s $f14, $f16
    bc1t end_bisection

    # --- compute f(left) ---
    # save mid again before calling f
    addi $sp, $sp, -4
    s.s $f6, 0($sp)

    mov.s $f12, $f2
    jal f
    mov.s $f18, $f0         # $f18 = f(left)

    # restore mid
    l.s $f6, 0($sp)
    addi $sp, $sp, 4

    # check sign: f(left) * f(mid) < 0 → root in left half
    mul.s $f20, $f18, $f10
    li $t0, 0
    mtc1 $t0, $f22
    c.lt.s $f20, $f22
    bc1t root_left

########################################
# root in right half → update left = mid
root_right:
    mfc1 $t0, $f6
    sw $t0, left_val
    # restore $ra and tail-call bisection
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    j bisection

########################################
# root in left half → update right = mid
root_left:
    mfc1 $t0, $f6
    sw $t0, right_val
    # restore $ra and tail-call bisection
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    j bisection

########################################
end_bisection:
    mov.s $f0, $f6
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

########################################
# f(x) = x^3 + x^2 + x - 1.5
# input:  $f12 = x
# output: $f0  = f(x)
# uses:   $f2, $f4, $f6 (local only — won't clobber caller's registers
#         since caller saves/restores $f6 around every call to f)
f:
    mul.s $f2, $f12, $f12   # x^2
    mul.s $f4, $f2,  $f12   # x^3
    add.s $f0, $f4,  $f2    # x^3 + x^2
    add.s $f0, $f0,  $f12   # x^3 + x^2 + x
    li $t0, 0x3FC00000      # 1.5
    mtc1 $t0, $f6
    sub.s $f0, $f0,  $f6    # x^3 + x^2 + x - 1.5
    jr $ra