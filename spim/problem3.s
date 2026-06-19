# Computing tan(x) using Taylor series
# sin(x) = x - x^3/3! + x^5/5! - ...
# cos(x) = 1 - x^2/2! + x^4/4! - ...
# tan(x) = sin(x)/cos(x)

.data
inf_msg:    .asciiz "tan is infinity (90 degrees or equivalent)\n"

.text
.globl main
main:
    # read float input (degrees)
    li $v0, 6
    syscall
    mov.s $f12, $f0

    # --- reduce angle to (-90, 90) ---
    # step 1: reduce mod 180 so range becomes [0, 180)
    li $t0, 0x43340000     # 180.0
    mtc1 $t0, $f24

    div.s $f26, $f12, $f24     # x / 180
    floor.w.s $f26, $f26       # floor(x / 180)
    cvt.s.w $f26, $f26         # convert back to float
    mul.s $f26, $f26, $f24     # floor(x/180) * 180
    sub.s $f12, $f12, $f26     # x = x mod 180, now in [0, 180)

    # step 2: if x > 90, subtract 180 to bring into (-90, 90]
    li $t0, 0x42b40000         # 90.0
    mtc1 $t0, $f28
    c.lt.s $f28, $f12          # 90 < x?
    bc1f skip_adjust           # if x <= 90, skip
    sub.s $f12, $f12, $f24     # x = x - 180, now in (-90, 0)
skip_adjust:

    # load pi
    li $t0, 0x40490fdb
    mtc1 $t0, $f0

    # load 180.0
    li $t0, 0x43340000
    mtc1 $t0, $f2

    # convert degrees to radians
    div.s $f12, $f12, $f2
    mul.s $f12, $f12, $f0

    # load 1.0 into f4
    li $t0, 0x3f800000
    mtc1 $t0, $f4

    # initialize sin(x) = 0.0
    li $t0, 0
    mtc1 $t0, $f8

    # initialize cos(x) = 1.0
    mov.s $f10, $f4

    # f14 = 1.0 so after first mul becomes x^1
    mov.s $f14, $f4

    # f5 = 0.0 so after first add becomes 1.0
    li $t0, 0
    mtc1 $t0, $f5

    mov.s $f6, $f4             # f6 = n! = 1.0

    li $t0, 1                  # loop counter
    li $t1, 35                 # limit (n = 1 to 34)
    li $t2, 0                  # sin sign counter
    li $t3, 0                  # cos sign counter

loop:
    mul.s $f14, $f14, $f12     # x^n
    add.s $f5, $f5, $f4        # factorial counter
    mul.s $f6, $f6, $f5        # n!

    # odd n -> sin term
    andi $t5, $t0, 1
    beqz $t5, check_cos

    div.s $f16, $f14, $f6
    andi $t5, $t2, 1
    beqz $t5, add_sin
    sub.s $f8, $f8, $f16
    addi $t2, $t2, 1
    j check_cos
add_sin:
    add.s $f8, $f8, $f16
    addi $t2, $t2, 1

check_cos:
    andi $t5, $t0, 1
    bnez $t5, update

    div.s $f16, $f14, $f6
    andi $t5, $t3, 1
    bnez $t5, add_cos
    sub.s $f10, $f10, $f16
    addi $t3, $t3, 1
    j update
add_cos:
    add.s $f10, $f10, $f16
    addi $t3, $t3, 1

update:
    addi $t0, $t0, 1
    blt $t0, $t1, loop

    # --- division by zero check ---
    li $t0, 0x358637bd         # epsilon = 1e-6
    mtc1 $t0, $f18
    abs.s $f22, $f10           # |cos(x)|
    c.lt.s $f22, $f18          # |cos(x)| < epsilon?
    bc1t print_inf

    # compute and print tan(x)
    div.s $f12, $f8, $f10
    li $v0, 2
    syscall
    j exit

print_inf:
    la $a0, inf_msg
    li $v0, 4
    syscall

exit:
    li $v0, 10
    syscall