# bogosort.s

# Reserved registers
# $t0 - main loop iterator
.eqv main_loop_iterator $t0
# $t1 - temporary loop iterator/condition status
.eqv temp_loop_variable $t1
# $t2 - linked list current pointer
.eqv curr_ptr $t2
# $t3 - linked list previous pointer
.eqv prev_ptr $t3
# $t4 - linked list head pointer
.eqv head_ptr $t4
# $t8 - variable
# $t9 - variable

# syscall codes
.eqv print_int_code 1
.eqv print_float_code 2
.eqv print_double_code 3
.eqv print_string_code 4
.eqv read_int_code 5
.eqv read_float_code 6
.eqv read_double_code 7
.eqv read_string_code 8
.eqv sbrk_code 9
.eqv exit_code 10
.eqv print_char_code 11
.eqv read_char_code 12

# linked-list constants
.eqv ptr_offset 0
.eqv data_offset 32
.eqv node_size 64
.eqv node_size_num_bytes 8
.eqv terminating_addr 0xDEADBEEF # what Trump is made of

.data
# global variables
hello_string: .asciiz "Hello, World!\n" # test string

# RNG variables
lfsr: .word 0xACE1
taps: .word 0, 2, 3, 5

# 1
.macro print_int(%rInt)
li $v0, print_int_code
move $a0, %rInt
syscall
.end_macro

.macro print_int_imm(%int)
li $v0, print_int_code
li $a0, %int
syscall
.end_macro

# 4
.macro print_string(%str)
.data
my_string: .asciiz %str
.text
li $v0, print_string_code
la $a0, my_string
syscall
.end_macro

#5
.macro read_int() # returns $s0 - int
li $v0, read_int_code
syscall
move $s0, $v0
.end_macro

#8
.macro read_string(%addr, %num_chars) # returns $s0 - address of string
li $v0, read_string_code
# TODO
syscall
move $s0, $v0
.end_macro

# 9
.macro malloc(%num_bytes) # returns $s0 - address of block
li $v0, sbrk_code
li $a0, %num_bytes
syscall
move $s0, $v0
.end_macro

# 10
.macro exit()
li $v0, exit_code
syscall
.end_macro

# for loop
.macro for(%rIter, %lo, %hi, %bodyMacro) # lo <= rIter < hi
li %rIter, %lo # initialize $rIter
for_cond: bge %rIter, %hi, end_for
for_loop: %bodyMacro
addi %rIter, %rIter, 1 # increment $rIter
j for_cond
end_for:
.end_macro

# TODO: remove
.macro for_body
print_string("Hello, World!\n")
.end_macro

# while loop
.macro while(%rCond, %bodyMacro, %updateMacro)
while_cond: beqz %rCond, end_while
while_loop: %bodyMacro
%updateMacro # must update $rCond
j while_cond
end_while:
.end_macro

# TODO: remove
.macro while_body
print_string("Hello, World!\n")
addi $t0, $t0, -1 # update $rCond
.end_macro

# linked list functions
.macro init_head() # hack: head node will be empty
malloc(node_size_num_bytes)
move $t4, $s0 # initialize head pointer
move $t2, $t4 # set current pointer to head
.end_macro

.macro increment_pointers
move $t3, $t2 # update previous pointer
lw $t2, ptr_offset($t2) # update current pointer
.end_macro

.macro store_data(%rAddr, %rPrevPtr, %rData)
lw $t9, ptr_offset(%rPrevPtr) # save previous pointer
sw %rAddr, ptr_offset(%rPrevPtr) # update previous pointer
sw $t9, ptr_offset(%rAddr) # set new pointer to saved
sw %rData, data_offset(%rAddr)
.end_macro

.macro insert(%idx, %rData)
mov $t2, $t4 # reset current pointer to head
for($t1, 0, %idx, increment_pointers)
malloc(node_size_num_bytes)
store_data($s0, $t3, %rData)
.end_macro

.macro enqueue_update
lw $t8, ptr_offset($t2)
beq $t8, terminating_addr, terminate_enqueue
j end_enqueue_update
terminate_enqueue: move $t1, $zero
end_enqueue_update:
.end_macro

.macro enqueue(%rData) # equivalent to insert(last, data)
mov $t2, $t4 # reset current pointer to head
addi $t1, $zero, 1
while($t1, increment_pointers, enqueue_update)
malloc(node_size_num_bytes)
store_data($s0, $t3, %rData)
.end_macro

.macro print_list_update
lw $t8, ptr_offset($t2)
beq $t8, terminating_addr, terminate_enqueue
j end_enqueue_update
terminate_enqueue: move $t1, $zero
end_enqueue_update:
.end_macro

.macro print_list(%rHead)
mov $t2, $t4 # reset current pointer to head
addi $t1, $zero, 1
while($t1, increment_pointers, print_list_update)

.end_macro

# RNG
# TODO

# sorting functions
# TODO

# main
.macro main_loop_body
print_string("Enter a real number: ")
read_int()
insert($ # TODO
.end_macro

.macro main_loop_update
# TODO
.end_macro

.text
.globl main
main:
#li $t0, 0
#for($t0, 0, 4, for_body)
#li $t0, 4
#while($t0, while_body)
init_head()
while($t0, main_loop_body, main_loop_update)
# TODO: sort!
exit()
