# bogosort.s
# NOTE: The linked list is effectively one-indexed, where the zeroth node contains metadata (length).

## Reserved registers

# main_loop_iterator - main loop iterator
.eqv main_loop_iterator $t0
# inner_loop_variable - temporary loop iterator/condition status
.eqv inner_loop_iterator $t1
.eqv main_loop_variable $t2
.eqv inner_loop_variable $t3
# curr_ptr - linked list current pointer
.eqv curr_ptr $k0
# prev_ptr - linked list previous pointer
.eqv prev_ptr $k1
# head_ptr - linked list head pointer
.eqv head_ptr $t4
.eqv index $t5 # list index counter
.eqv lfsr $t6 # LFSR value
.eqv bit $t7 # feedback bit
# $t8 - local variable
# $t9 - local variable

# ans - most recent answer returned
.eqv ans $s0
# param# - top-level function input param1eters
.eqv param1 $s1
.eqv param2 $s2
.eqv param3 $s3

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

# RNG constants
.eqv seed 0xACE1
# NOTE: The following constants are technically 16 minus each of the taps.
.eqv tap0 0
.eqv tap1 2
.eqv tap2 3
.eqv tap3 5

.data
# test constants
hello_string: .asciiz "Hello, World!\n" # test string

uint16_max: .float 65536.0 # 2^16

# datatype conversion functions
.macro int2float(%rInt, %rFloat)
#sub $sp, $sp, 32
#sw %rInt, ($sp)
#l.s %rFloat, ($sp)
#addi $sp, $sp, 32

mtc1 %rInt, %rFloat
cvt.s.w %rFloat, %rFloat
.end_macro

.macro float2int(%rFloat, %rInt)
#sub $sp, $sp, 32
#s.s %rFloat, ($sp)
#lw %rInt, ($sp)
#addi $sp, $sp, 32

cvt.w.s %rFloat, %rFloat
mfc1 %rInt, %rFloat
.end_macro

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

# 2 - TODO: debug
.macro print_float(%rFloat)
li $v0, print_float_code
mov.s $f12, %rFloat
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
.macro read_int() # returns int
li $v0, read_int_code
syscall
move ans, $v0
.end_macro

#8
.macro read_string(%addr, %num_chars) # returns address of string
li $v0, read_string_code
# TODO
syscall
move ans, $v0
.end_macro

# 9
.macro malloc(%num_bytes) # returns address of block
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
.macro for(%rIter, %rLo, %rHi, %bodyMacro) # lo <= rIter < hi
move %rIter, %rLo # initialize $rIter
for_cond: bge %rIter, %rHi, end_for
for_loop: %bodyMacro
addi %rIter, %rIter, 1 # increment $rIter
j for_cond
end_for:
.end_macro

# TODO: remove
.macro for_body
print_string("Hello, World!\n")
.end_macro

# main while loop
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

# inner while loop, TODO: refactor
# (hacky duplicate of main while loop used to avoid compiler detection of a loop upon macro unrolling)
.macro while2(%rCond, %bodyMacro)
while2_cond: beqz %rCond, end_while2
while2_loop: %bodyMacro # must update $rCond
j while2_cond
end_while2:
.end_macro

# linked list functions
.macro init_head(%rHead) # head contains list length as metadata
malloc(node_size) # TODO: malloc(node_size_num_bytes)
move %rHead, ans # initialize head pointer
move curr_ptr, %rHead # set current pointer to head
li $t8, terminating_addr
sw $t8, ptr_offset(%rHead)
sw $zero, data_offset(%rHead)
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
lw $t8, data_offset(%rAddr)
.end_macro

.macro insert(%rHead, %rIdx, %rData)
move curr_ptr, %rHead # reset current pointer to head
for(inner_loop_variable, 0, %rIdx, increment_pointers)
malloc(node_size) # TODO: malloc(node_size_num_bytes)
store_data(ans, prev_ptr, %rData)
# increment length of list
get_length(%rHead)
addi $t8, ans, 1
sw $t8, data_offset(%rHead)
.end_macro

# TODO: write remove(idx)

.macro iterate
addi index, index, 1
lw $t8, ptr_offset(curr_ptr)
beq $t8, terminating_addr, terminate_iterate
j end_iterate
terminate_iterate: move inner_loop_variable, $zero
end_iterate:
.end_macro

.macro enqueue_body
iterate
increment_pointers
.end_macro

# TODO: rewrite as insert(last)
.macro enqueue(%rHead, %rData) # equivalent to insert(last)
move curr_ptr, %rHead # reset current pointer to head
addi inner_loop_variable, $zero, 1
while2(inner_loop_variable, enqueue_body)
malloc(node_size) # TODO: malloc(node_size_num_bytes)
store_data(ans, prev_ptr, %rData)
# increment length of list
get_length(%rHead)
addi $t8, ans, 1
sw $t8, data_offset(%rHead)
.end_macro

.macro print_list_loop_body
lw $t8, data_offset(curr_ptr)
beqz index, skip_metadata
print_int(index)
print_string(":")
print_int($t8)
print_string(" ")
skip_metadata: increment_pointers
iterate
.end_macro

.macro print_list(%rHead)
move index, $zero
move curr_ptr, %rHead # reset current pointer to head
addi inner_loop_variable, $zero, 1
while2(inner_loop_variable, print_list_loop_body)
# print_list_loop_body, except w/o iterate
lw $t8, data_offset(curr_ptr)
beqz index, skip_metadata
print_int(index)
print_string(":")
print_int($t8)
print_string(" ")
skip_metadata: increment_pointers
.end_macro

.macro get_length(%rHead)
lw ans, data_offset(%rHead)
.end_macro

.macro swap(%rHead, %rIdx1, %rIdx2)
# save data1
move curr_ptr, %rHead # reset current pointer to head
for(inner_loop_variable, $zero, %rIdx1, increment_pointers)
lw $t8, data_offset(curr_ptr)
# save data2
move curr_ptr, head_ptr # reset current pointer to head
for(inner_loop_variable, $zero, %rIdx2, increment_pointers)
lw $t9, data_offset(curr_ptr)
# overwrite node1 w/ data2
move curr_ptr, head_ptr # reset current pointer to head
for(inner_loop_variable, $zero, %rIdx1, increment_pointers)
sw $t9, data_offset(curr_ptr)
# overwrite node2 w/ data1
move curr_ptr, head_ptr # reset current pointer to head
for(inner_loop_variable, $zero, %rIdx2, increment_pointers)
sw $t8, data_offset(curr_ptr)
.end_macro

# random functions
.macro init_rand()
li lfsr, 0 # TODO: remove?
lui lfsr, 0
li lfsr, seed
.end_macro

.macro rand() # returns random 16-bit integer
# compute new feedback bit
srl bit, lfsr, tap0
srl $t8, lfsr, tap1
xor bit, bit, $t8
srl $t8, lfsr, tap2
xor bit, bit, $t8
srl $t8, lfsr, tap3
xor bit, bit, $t8
andi bit, bit, 0x0001
# compute new LFSR value
srl $t8, lfsr, 1
sll $t9, bit, 15
or lfsr, $t8, $t9
move ans, lfsr
.end_macro

.macro rand_int(%rIntMax) # returns random int between 0 (inclusive) and $rIntMax
#print_string("\nint max: ")
#print_int(%rIntMax)
int2float(%rIntMax, $f9)
#print_string("\nfloat max: ")
#print_float($f9)
rand()
int2float(ans, $f8)
#print_string("\nans: ")
#print_float($f8)
l.s $f10, uint16_max
#print_string("\nuint16 max: ")
#print_float($f10)
mul.s $f11, $f8, $f9
#print_string("\nmul ans: ")
#print_float($f11)
div.s $f11, $f11, $f10
#print_string("\ndiv ans: ")
#print_float($f11)
#print_string("\n")
float2int($f11, ans)
.end_macro

.macro test_rand_body
li $t8, 10
rand_int($t8)
print_int(ans)
print_string("\n")
.end_macro

# sorting functions
.macro is_sorted(%rHead)
# TODO: return 1 if sorted, 0 otherwise
.end_macro

.macro bogosort_loop_body
is_sorted(head_ptr)
bgtz ans, terminate_bogosort_loop
j end_bogosort_loop_body
terminate_bogosort_loop: move inner_loop_iterator, $zero
end_bogosort_loop_body:
.end_macro

.macro bogosort

.end_macro

# main
.macro main_loop_body
# user input
print_string("\nEnter a real number: ")
read_int()
# TODO: exception handling
bltz ans, terminate_main_loop
move param1, ans
enqueue(head_ptr, param1)
j end_main_loop_body
terminate_main_loop: move main_loop_iterator, $zero
end_main_loop_body:
.end_macro

.text
.globl main
main:
# TODO: uncomment
print_string("\n\n-- Begin -- ")

#li main_loop_iterator, 0
#for(main_loop_iterator, 0, 4, for_body)
#li main_loop_iterator, 4
#while(main_loop_iterator, while_body)

li main_loop_iterator, 1
init_head(head_ptr)
while(main_loop_iterator, main_loop_body)
print_list(head_ptr)
#init_rand()
#for(main_loop_iterator, $zero, 1000, test_rand_body)

# TODO: sort!
#li param1, 2
#li param2, 3
#swap(head_ptr, param1, param2)

#get_length(head_ptr)
#print_string("\nlength: ")
#print_int(ans)

exit()
