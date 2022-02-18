#####################################################################################
#
#	Name:			Barros, Mark
#	Course:			CS2640 - Computer Organization and Assembly Programming
#	Description:	This program implements a link list to store input lines of text.
#					It will then print the link list constructed.
#
#####################################################################################

				.data
header:			.asciiz		"Link List by M. Barros\n\n"		
prompt:			.asciiz		"Enter text? "
llist:			.word		0				# head of link list
 				.align		2
inbuf:			.space		82				# up to 80 characters + \n + \0

#####################################################################################

				.text
main:
	
	# save the return address of startup code onto the stack
	addiu		$sp, $sp, -4				
	sw			$ra, 0($sp)
	
	# output header
	li			$v0, 4						
	la			$a0, header
	syscall

loop:

	# prompt user for a string
	li			$v0, 4
	la			$a0, prompt					
	syscall
	
	# channel the input string into inbuf
	li			$v0, 8
	la			$a0, inbuf
	li			$a1, 82
	syscall
	
	# exit loop if only a single "Enter" is input
	lb			$t0, 0($a0)					# load first character of input string
	li			$t1, '\n'					# load newline character
	beq			$t0, $t1, exit_loop
	
	# duplicate the input string	
	la			$a0, inbuf
	jal			strdup
	
	# add a node
	move		$a0, $v0					# load base address of string argument					
	la			$t2, llist					# load head of link list argument
	lw			$a1, 0($t2)
	jal			addnode 
	
	# continue prompting for strings, duplicating them, and adding nodes
	b			loop
	
exit_loop:

	# output a blank line
	li			$v0, 11
	li			$a0, '\n'
	syscall

	# traverse the link list and output each string to the console
	la			$t3, llist					# load address of llist argument
	lw			$a0, 0($t3)
	la			$a1, print					# load address of print argument
	jal			traverse

	# return to startup code
	lw			$ra, 0($sp)
	addiu		$sp, $sp, 4	
	jr			$ra

#####################################################################################
#
# addnode($a0, $a1)
# 	add a node to a link list
# parameters:
#	$a0: points to string data
#	$a1: points to next node
# return:
#	$v0: the new address of the link list
#
#####################################################################################

addnode:
	
	# load address of heap (address of c string data) into $t0
	# load address of llist (address of next node) into $t1
	move		$t0, $a0                    
	move		$t1, $a1

	# allocate 2 words on the heap for each node using sbrk code
	li			$a0, 8						
	li			$v0, 9
	syscall
	
	# Note: at this juncture, $v0 contains the new node address
	
	# update llist address
	la			$t2, llist
	sw			$v0, 0($t2)
		
end_if:

	# store addresses of next node and string data 
	# into first and second words, respectively
	sw		$t1, 0($v0)
	sw		$t0, 4($v0)
	
	# return to main
	jr			$ra

#####################################################################################
#
# traverse($a0, $a1)
# 	traverse a link list
# parameters:
#	$a0: points to node address
#	$a1: points to procedure address
#
#####################################################################################

traverse:
	# save the return address of caller onto the stack
	addiu		$sp, $sp, -8
	sw			$ra, 0($sp)
	
	# save the current node address onto the stack
	sw			$a0, 4($sp)

	# if the current node is not the last, then recursively call traverse
	lw			$t0, 0($a0)
	beqz		$t0, end
	move		$a0, $t0
	jal			traverse
	
end:

	# load string address argument and print string
	lw			$t0, 4($sp)
	lw			$a0, 4($t0)
	jalr		$a1							# print is in the register
	
	# return to caller
	lw			$ra, 0($sp)					# restore return address
	addiu		$sp, $sp, 8					# and restore the stack
	jr			$ra
		
#####################################################################################
#
# print($a0)
# 	output a string to the console
# parameters:
#	$a0: points to the source string
#
#####################################################################################
 
 print:
 
	# address of string to be printed is in $a0
	li			$v0, 4
	syscall
	jr			$ra

#####################################################################################
#
# strdup($a0)
# 	duplicates a string
# parameters:
#	$a0: points to source string
# return:
#	$v0: the address of the node containing the duplicated string
#
#####################################################################################

strdup:

	# save the return address of main code onto the stack
	addiu		$sp, $sp, -4
	sw			$ra, 0($sp)
	
	# get the string's length
	jal			strlen
	
	# strlen's return becomes argument for sbrk
	move		$a0, $v0
	
	# use sbrk syscall to dynamically-allocate memory on the heap	
	add			$a0, 1						# make space for the null character
	add			$a0, 3						# ensure a multiple of 4
	and			$a0, $a0, 0xFFFFFFFFC		#	"		"		"
	li			$v0, 9						# sbrk code
	syscall
	
	# Note: At this juncture, $v0 holds sbrk's return, which is the heap address
	#       of the duplicated string. This will also be strdup's return.
	
	# initialize variables
	move		$t2, $v0					# load address of heap memory
	la			$t3, inbuf					# load address of inbuf					

	# copy input string
	
loop0:

	# $t4 holds the current character
	lb			$t4, 0($t3)					
	
	# exit loop when current character is 0 (null character)
	beqz		$t4, exit_loop0
	
	# copy input string to heap
	lb			$t5, 0($t3)
	sb			$t5, 0($t2)
	
	# increment offsets of cstring and allocated heap memory
	add			$t3, 1
	add			$t2, 1
	
	# continue copying characters
	b			loop0
	
exit_loop0:
	
	# return to main code
	lw			$ra, 0($sp)
	addiu		$sp, $sp, 4	
	jr			$ra
	
#####################################################################################
#
# strlen($a0)
# 	compute the length of a string
# parameters:
#	$a0: points to the source string
# return:
#	$v0: the length of the string
#
#####################################################################################

strlen:
	# initialize character count $t0
	li			$t0, 0

	# $t1 holds address of inbuf and $t2 holds current character
	move		$t1, $a0
	lb			$t2, 0($t1)

loop1:
	
	# if current character ($t2) is null then exit loop
	beqz		$t2, exit_loop1
	
	# increment address to process next character
	add			$t1, 1
	
	# load current character into $t2
	lb			$t2, 0($t1)
	
	# increment character count
	add			$t0, 1
	
	# continue counting characters
	b			loop1

exit_loop1:
	
	# return length of string
	move		$v0, $t0
	
	# return to strdup
	jr			$ra
	
# End of Program ####################################################################