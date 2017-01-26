# bogosort.s

## Reserved registers

# main_loop_iterator - main loop iterator
.eqv main_loop_iterator $t0
# temp_loop_variable - temporary loop iterator/condition status
.eqv temp_loop_variable $t1
# curr_ptr - linked list current pointer
.eqv curr_ptr $t2
# prev_ptr - linked list previous pointer
.eqv prev_ptr $t3
# head_ptr - linked list head pointer
.eqv head_ptr $t4
# $t8 - variable
# $t9 - variable

# ans - most recent answer returned by function call
.eqv ans $s0

## Constants

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
.macro read_int() # returns ans - int
li $v0, read_int_code
syscall
move ans, $v0
.end_macro

#8
.macro read_string(%addr, %num_chars) # returns ans - address of string
li $v0, read_string_code
# TODO
syscall
move ans, $v0
.end_macro

# 9
.macro malloc(%num_bytes) # returns ans - address of block
li $v0, sbrk_code
li $a0, %num_bytes
syscall
move ans, $v0
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
.macro while(%rCond, %bodyMacro)
while_cond: beqz %rCond, end_while
while_loop: %bodyMacro # must update $rCond
j while_cond
end_while:
.end_macro

# TODO: remove
.macro while_body
print_string("Hello, World!\n")
addi main_loop_iterator, main_loop_iterator, -1 # update $rCond
.end_macro

# while2 loop
.macro while2(%rCond, %bodyMacro)
while2_cond: beqz %rCond, end_while2
while2_loop: %bodyMacro # must update $rCond
j while2_cond
end_while2:
.end_macro

# linked list functions
.macro init_head() # hack: head node will be empty
malloc(node_size_num_bytes)
print_string("\nmalloc ans: ")
print_int(ans)
move head_ptr, ans # initialize head pointer
move curr_ptr, head_ptr # set current pointer to head
li $t8, terminating_addr
print_string("\n0xDEADBEEF: ")
print_int($t8)
sw $t8, ptr_offset(head_ptr)
.end_macro

.macro increment_pointers
move prev_ptr, curr_ptr # update previous pointer
lw curr_ptr, ptr_offset(curr_ptr) # update current pointer
.end_macro

.macro store_data(%rAddr, %rPrevPtr, %rData)
lw $t9, ptr_offset(%rPrevPtr) # save previous pointer
sw %rAddr, ptr_offset(%rPrevPtr) # update previous pointer
sw $t9, ptr_offset(%rAddr) # set new pointer to saved
sw %rData, data_offset(%rAddr)
.end_macro

.macro insert(%idx, %rData)
move curr_ptr, head_ptr # reset current pointer to head
for(temp_loop_variable, 0, %idx, increment_pointers)
malloc(node_size_num_bytes)
store_data(ans, prev_ptr, %rData)
.end_macro

.macro iterate
print_string("\ncurr_ptr: ")
print_int(curr_ptr)
lw $t8, ptr_offset(curr_ptr)
beq $t8, terminating_addr, terminate_iterate
j end_iterate
terminate_iterate: move temp_loop_variable, $zero
end_iterate:
.end_macro

.macro enqueue_body
iterate
increment_pointers
.end_macro

.macro enqueue(%rData) # equivalent to insert(last, data)
move curr_ptr, head_ptr # reset current pointer to head
addi temp_loop_variable, $zero, 1
while2(temp_loop_variable, enqueue_body)
malloc(node_size_num_bytes)
store_data(ans, prev_ptr, %rData)
.end_macro

.macro print_list_loop_body
lw $t8, data_offset(curr_ptr)
print_int($t8)
increment_pointers
iterate
.end_macro

.macro print_list(%rHead)
move curr_ptr, head_ptr # reset current pointer to head
addi temp_loop_variable, $zero, 1
while2(temp_loop_variable, print_list_loop_body)

.end_macro

# RNG
# TODO

# sorting functions
# TODO

# main
.macro main_loop_body
print_string("\nEnter a real number: ")
read_int()
# TODO: exception handling
bltz ans, terminate_main_loop
enqueue(ans)
j end_main_loop_body
terminate_main_loop: move main_loop_iterator, $zero
end_main_loop_body:
.end_macro

.text
.globl main
main:
print_string("\n\n-- Begin -- ")
print_int($zero)
#li main_loop_iterator, 0
#for(main_loop_iterator, 0, 4, for_body)
li main_loop_iterator, 4
#while(main_loop_iterator, while_body)
init_head()
while(main_loop_iterator, main_loop_body)
# TODO: sort!
exit()
