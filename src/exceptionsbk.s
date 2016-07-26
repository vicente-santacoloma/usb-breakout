############################################ 
#                AUTORES                   #  
############################################
#  Argenis Chang 08-10220                  #
#  Vicente Santacoloma 08-11044            #
############################################
#
# SPIM S20 MIPS simulator.
# The default exception handler for spim.
#
# Copyright (c) 1990-2010, James R. Larus.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# Neither the name of the James R. Larus nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Definición de constantes para el juego de Breakout. Usted debe fijar el T 
# adecuado para correr su juego en su computadora. M y N podrán ser variados,
# con 10 <= N y 20 <= M.
# Estas constantes pueden ser usadas en este archivo, por ejemplo:
# li $t0, M

M = 45	# Número de columnas
N = 13	# Número de filas
T = 200	# Intervalo de redibujo

# Define the exception handling code.  This must go first!

	.kdata
__m1_:	.asciiz "  Exception "
__m2_:	.asciiz " occurred and ignored\n"
__e0_:	.asciiz "  [Interrupt] "
__e1_:	.asciiz	"  [TLB]"
__e2_:	.asciiz	"  [TLB]"
__e3_:	.asciiz	"  [TLB]"
__e4_:	.asciiz	"  [Address error in inst/data fetch] "
__e5_:	.asciiz	"  [Address error in store] "
__e6_:	.asciiz	"  [Bad instruction address] "
__e7_:	.asciiz	"  [Bad data address] "
__e8_:	.asciiz	"  [Error in syscall] "
__e9_:	.asciiz	"  [Breakpoint] "
__e10_:	.asciiz	"  [Reserved instruction] "
__e11_:	.asciiz	""
__e12_:	.asciiz	"  [Arithmetic overflow] "
__e13_:	.asciiz	"  [Trap] "
__e14_:	.asciiz	""
__e15_:	.asciiz	"  [Floating point] "
__e16_:	.asciiz	""
__e17_:	.asciiz	""
__e18_:	.asciiz	"  [Coproc 2]"
__e19_:	.asciiz	""
__e20_:	.asciiz	""
__e21_:	.asciiz	""
__e22_:	.asciiz	"  [MDMX]"
__e23_:	.asciiz	"  [Watch]"
__e24_:	.asciiz	"  [Machine check]"
__e25_:	.asciiz	""
__e26_:	.asciiz	""
__e27_:	.asciiz	""
__e28_:	.asciiz	""
__e29_:	.asciiz	""
__e30_:	.asciiz	"  [Cache]"
__e31_:	.asciiz	""
__excp:	.word __e0_, __e1_, __e2_, __e3_, __e4_, __e5_, __e6_, __e7_, __e8_, __e9_
	.word __e10_, __e11_, __e12_, __e13_, __e14_, __e15_, __e16_, __e17_, __e18_,
	.word __e19_, __e20_, __e21_, __e22_, __e23_, __e24_, __e25_, __e26_, __e27_,
	.word __e28_, __e29_, __e30_, __e31_
s1:	.word 0
s2:	.word 0
Vector:	.space 8
PosAct:	.space 8
PosAnt:	.space 8
Arreglo:	.word -1, -1, -1, -2, 0, -2, 1, -2, 1, -1 
Vectores: 	.word -1, 1, -1, -1, 1, 1, 1, -1, 0, -2, 0, 2, -2, -1, -2, 1, 2, -1, 2, 1, -1, -2, -1, 2, 1, -2, 1, 2
Matrix: .space 4000
Score:	.space 4

###################################################################
#                           DATA BREAKOUT                         #
###################################################################
barra: 			.asciiz "-"
bola:			.asciiz "o"
corchete1:		.asciiz	"["
corchete2:		.asciiz	"]"
pared: 			.asciiz "|"
pared_salto:	.asciiz "|\n"
techo:			.asciiz "-"
espacio:		.asciiz "\n"
blanco: 		.asciiz " "	
result:			.asciiz "Su puntuacion ha sido: "
opcion:			.asciiz "\n\nEscoja una opcion:                                          \n 1.Jugar de nuevo \n 2.Salir"
eleccion:		.asciiz	"\n\nIntroduzca opcion: "
text_fin:		.asciiz "\n\n###########################################\n#  THANKS FOR PLAYING BLIZZARD PRODUCTS!  #                                         #\n###########################################\n\n"
text_bienvenida: .asciiz "################################################\n#  Welcome to Breakout Game. Enjoy your stay!  #\n#                                              #\n#       Press F or H to move, Q to exit        #\n################################################\n\n"

###################################################################
# 							EXCEPTION BREAKOUT                    #
###################################################################


# This is the exception handler code that the processor runs when
# an exception occurs. It only prints some information about the
# exception, but can server as a model of how to write a handler.
#
# Because we are running in the kernel, we can use $k0/$k1 without
# saving their old values.

# This is the exception vector address for MIPS-1 (R2000):
#	.ktext 0x80000080
# This is the exception vector address for MIPS32:
	.ktext 0x80000180
# Select the appropriate one for the mode in which SPIM is compiled.
	.set noat
	move $k1 $at		# Save $at
	.set at
	sw $v0 s1		# Not re-entrant and we can't trust $sp
	sw $a0 s2		# But we need to use these registers

	### Tenemos que mirar el registro cause para saber si alguien toco una tecla, se aprovecha parte del codigo que ya tienen el exceptions.s original y solo se añade un salto a una etiqueta o rutina
	
	mfc0 $k0 $13		# Cause register
	
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f	## Después de desplazar y hacer el and en $a0 solo tengo el Exception Code
	
	## Ejemplo barra, añadir para tratar interrupciones
	beqz $a0, interrupt  ## Sí es 0, por la tabla de Exception Code se que es de hardware y la trato
		
	# Print information about exception.
	#
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m1_
	syscall

	li $v0 1		# syscall 1 (print_int)
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	syscall

	li $v0 4		# syscall 4 (print_str)
	andi $a0 $k0 0x3c
	lw $a0 __excp($a0)
	nop
	syscall

	bne $k0 0x18 ok_pc	# Bad PC exception requires special checks
	nop

	mfc0 $a0 $14		# EPC
	andi $a0 $a0 0x3	# Is EPC word-aligned?
	beq $a0 0 ok_pc
	nop

	li $v0 10		# Exit on really bad PC
	syscall

ok_pc:
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m2_
	syscall

	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	bne $a0 0 ret		# 0 means exception was an interrupt
	nop

# Interrupt-specific code goes here!
# Don't skip instruction at EPC since it has not executed.

### Añadir el codigo para tratar la interrupcion

interrupt:
		## Desactivar interrupciones en Status, para evitarlas mientras estamos tratando la interrupción actual
		mfc0 $a0, $12          ## Inhabilitamos las interrupciones poniendo a 0 el bit 0 de Status (Interrupt Enable)
		li $a1, 0xfffffffe
		and  $a0, $a0, $a1
		mtc0 $a0, $12

		## Leemos Receiver control, realizamos una máscara para saber si el bit Ready está a 1 (se ha tecleado algo).
		lw   $a0, 0xffff0000
		andi $a0, $a0, 0x1		
		bnez  $a0, tecla
		mfc0 $t0, $9
		mfc0 $t1, $11
		bge  $t0, $t1, Act_Ball
		
		## Las interrupciones de reloj se controlan verificando el contenido del registro Count (9) y Compare (11), 
		## el timer lanzara una interrupción cuando count = compare (Tienen que inicializarlo).
		
Act_Ball:	lb $t0, blanco
			sb $t0, Matrix+0($s6)
			lw $t0, PosAct+0($zero)
			sw $t0, PosAnt+0($zero)
			lw $t0, PosAct+4($zero)
			sw $t0, PosAnt+4($zero)
			move $s3, $s6
			jal SumVecPosAct
			lw $a0, PosAct+0($zero)	
			lw $a1, PosAct+4($zero)
			jal CalcBytesExc
			move $s6, $v0
			jal CondicionalBloque
			jal CondicionalColumna
			jal CondicionalFila	
			b int_Reloj
			

#####################################################################				
#                       CONDICIONALES BLOQUES                       #
#####################################################################			 
			
CondicionalBloque: 	lw $t0, Vector+0($zero)
					lw $t1, Vector+4($zero)
					lw $t6, Vector+4($zero)
					beq $t0, -2, Caso_1
					beq $t0, -1, Caso_2
					beq $t0,  0, Caso_3
					beq $t0,  1, Caso_4
					beq $t0,  2, Caso_5
					
Caso_1:		lw $t0, Vector+0($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+0($zero)
			addi $s3, $s3, -1
			lw $t1, PosAct+0($zero)
			lw $t2, PosAct+4($zero)
			lw $t3, PosAnt+0($zero)
			lw $t4, PosAnt+4($zero)
			sw $t3, PosAct+0($zero)
			sw $t4, PosAct+4($zero)
			lb $t0, Matrix+0($s3)
			beq $t0, 93, DestruirBloqueDer
			addi $t4, $t4, -1
			sw $t4, PosAct+4($zero)
			addi $s3, $s3, -1
			lb $t0, Matrix+0($s3)
			beq $t0, 93, DestruirBloqueDer
			lw $t0, Vector+0($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+0($zero)
			lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			addi $t4, $t4, -1
			sw $t4, PosAct+4($zero)
			li $t0, M
			addi $t0, $t0, 1
			lw $t3, Vector+4($zero)
			beq $t3, -1, Caso_1_1
			lw $t3, Vector+4($zero)
			beq $t3,  1, Caso_1_2
			
Caso_1_1:	subu $s3, $s3, $t0
			b Caso_1_Gen

Caso_1_2:	add  $s3, $s3, $t0
			b Caso_1_Gen

Caso_1_Gen:	lb $t0, Matrix+0($s6)
			beq $t0, 91, DestruirBloqueIzq
			beq $t0, 93, DestruirBloqueDer
			sw $t1, PosAct+0($zero)
			sw $t2, PosAct+4($zero)
			lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			jr $ra
			
Caso_2:		beq $t6, -1, Caso_General
			beq $t6,  1, Caso_General
			b Caso_2_Gen
			
Caso_2_Gen: lw $t0, Vector+0($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+0($zero)
			li $t5, M
			addi $t5, $t5, 1
			subu $s3, $s3, 1
			lw $t1, PosAct+0($zero)
			lw $t2, PosAct+4($zero)
			lw $t3, PosAnt+0($zero)
			lw $t4, PosAnt+4($zero)
			sw $t3, PosAct+0($zero)
			sw $t4, PosAct+4($zero)
			lb $t0, Matrix+0($s3)
			beq $t0, 93, DestruirBloqueDer
			lw $t0, Vector+0($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+0($zero)
			lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			addi $t4, $t4, -1
			sw $t4, PosAct+4($zero)
			beq $t6, -2, Caso_2_1
			beq $t6,  2, Caso_2_2
			
Caso_2_1:	subu $s3, $s3, $t5 
			lb $t0, Matrix+0($s3)
			beq $t0, 91, DestruirBloqueIzq
			beq $t0, 93, DestruirBloqueDer
			addi $t3, $t3, -1
			sw $t3, PosAct+0($zero)
			subu $s3, $s3, $t5
			lb $t0, Matrix+0($s6)
			beq $t0, 91, DestruirBloqueIzq
			beq $t0, 93, DestruirBloqueDer
			sw $t1, PosAct+0($zero)
			sw $t2, PosAct+4($zero)
			lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			jr $ra

Caso_2_2:   add $s3, $s3, $t5 
			lb $t0, Matrix+0($s3)
			beq $t0, 91, DestruirBloqueIzq
			beq $t0, 93, DestruirBloqueDer
			addi $t3, $t3, 1
			sw $t3, PosAct+0($zero)
			add $s3, $s3, $t5
			lb $t0, Matrix+0($s6)
			beq $t0, 91, DestruirBloqueIzq
			beq $t0, 93, DestruirBloqueDer
			sw $t1, PosAct+0($zero)
			sw $t2, PosAct+4($zero)
			lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			jr $ra
			
Caso_General:	lw $t0, Vector+4($zero)
				mul $t0, $t0, -1
				sw $t0, Vector+4($zero)
				lw $t1, PosAct+0($zero)
				lw $t2, PosAct+4($zero)
				lw $t3, PosAnt+0($zero)
				lw $t4, PosAnt+4($zero)
				sw $t3, PosAct+0($zero)
				sw $t4, PosAct+4($zero)
				move $t5, $s3
				move $s3, $s6
				lb $t0, Matrix+0($s6)
				beq $t0, 91, DestruirBloqueIzq
				beq $t0, 93, DestruirBloqueDer
				sw $t1, PosAct+0($zero)
				sw $t2, PosAct+4($zero)
				lw $t0, Vector+4($zero)
				mul $t0, $t0, -1
				sw $t0, Vector+4($zero)
				jr $ra
								
Caso_3:		beq $t1, -2, Caso_3_1
			jr $ra
			
Caso_3_1:   lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			li $t0, M
			addi $t0, $t0, 1
			subu $s3, $s3, $t0
			lw $t1, PosAct+0($zero)
			lw $t2, PosAnt+0($zero)
			sw $t2, PosAct+0($zero)
			lb $t3, Matrix+0($s3)
			beq $t3, 91, DestruirBloqueIzq
			beq $t3, 93, DestruirBloqueDer
			addi $t2, $t2, -1
			sw $t2, PosAct+0($zero)
			subu $s3, $s3, $t0
			lb $t3, Matrix+0($s3)
			beq $t3, 91, DestruirBloqueIzq
			beq $t3, 93, DestruirBloqueDer
			sw $t1, PosAct+0($zero)
			lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			jr $ra

Caso_4:		beq $t6, -1, Caso_General
			beq $t6,  1, Caso_General
			b Caso_4_Gen
			
Caso_4_Gen: lw $t0, Vector+0($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+0($zero)
			li $t5, M
			addi $t5, $t5, 1
			addi $s3, $s3, 1
			lw $t1, PosAct+0($zero)
			lw $t2, PosAct+4($zero)
			lw $t3, PosAnt+0($zero)
			lw $t4, PosAnt+4($zero)
			sw $t3, PosAct+0($zero)
			sw $t4, PosAct+4($zero)
			lb $t0, Matrix+0($s3)
			beq $t0, 91, DestruirBloqueIzq
			lw $t0, Vector+0($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+0($zero)
			lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			addi $t4, $t4, 1
			sw $t4, PosAct+4($zero)
			beq $t6, -2, Caso_4_1
			beq $t6,  2, Caso_4_2
			
Caso_4_1:	subu $s3, $s3, $t5 
			lb $t0, Matrix+0($s3)
			beq $t0, 91, DestruirBloqueIzq
			beq $t0, 93, DestruirBloqueDer
			addi $t3, $t3, -1
			sw $t3, PosAct+0($zero)
			subu $s3, $s3, $t5
			lb $t0, Matrix+0($s6)
			beq $t0, 91, DestruirBloqueIzq
			beq $t0, 93, DestruirBloqueDer
			sw $t1, PosAct+0($zero)
			sw $t2, PosAct+4($zero)
			lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			jr $ra

Caso_4_2:   add $s3, $s3, $t5 
			lb $t0, Matrix+0($s3)
			beq $t0, 91, DestruirBloqueIzq
			beq $t0, 93, DestruirBloqueDer
			addi $t3, $t3, 1
			sw $t3, PosAct+0($zero)
			add $s3, $s3, $t5
			lb $t0, Matrix+0($s6)
			beq $t0, 91, DestruirBloqueIzq
			beq $t0, 93, DestruirBloqueDer
			sw $t1, PosAct+0($zero)
			sw $t2, PosAct+4($zero)
			lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			jr $ra
	
Caso_5:		lw $t0, Vector+0($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+0($zero)
			addi $s3, $s3, 1
			lw $t1, PosAct+0($zero)
			lw $t2, PosAct+4($zero)
			lw $t3, PosAnt+0($zero)
			lw $t4, PosAnt+4($zero)
			sw $t3, PosAct+0($zero)
			sw $t4, PosAct+4($zero)
			lb $t0, Matrix+0($s3)
			beq $t0, 93, DestruirBloqueIzq
			addi $t4, $t4, 1
			sw $t4, PosAct+4($zero)
			addi $s3, $s3, 1
			lb $t0, Matrix+0($s3)
			beq $t0, 93, DestruirBloqueIzq
			lw $t0, Vector+0($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+0($zero)
			lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			addi $t4, $t4, 1
			sw $t4, PosAct+4($zero)
			li $t0, M
			addi $t0, $t0, 1
			lw $t3, Vector+4($zero)
			beq $t3, -1, Caso_1_1
			lw $t3, Vector+4($zero)
			beq $t3,  1, Caso_1_2
			
Caso_5_1:	subu $s3, $s3, $t0
			b Caso_1_Gen

Caso_5_2:	add  $s3, $s3, $t0
			b Caso_1_Gen

Caso_5_Gen:	lb $t0, Matrix+0($s6)
			beq $t0, 91, DestruirBloqueIzq
			beq $t0, 93, DestruirBloqueDer
			sw $t1, PosAct+0($zero)
			sw $t2, PosAct+4($zero)
			lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			jr $ra

DestruirBloqueIzq:	lw $a0, PosAct+0($zero)	
					lw $a1, PosAct+4($zero)
					jal CalcBytesExc
					move $s6, $v0
					lb $t0, blanco
					sb $t0, Matrix+0($s3)
					addi $s3, $s3, 1
					sb $t0, Matrix+0($s3)
					lw $s7, Score + 0($zero)
					addi $s4, $s4, 50
					beq $s4, $s7, Resultado
					b int_Reloj
					

DestruirBloqueDer:	lw $a0, PosAct+0($zero)	
					lw $a1, PosAct+4($zero)
					jal CalcBytesExc
					move $s6, $v0
					lb $t0, blanco
					sb $t0, Matrix+0($s3)
					addi $s3, $s3, -1
					sb $t0, Matrix+0($s3)
					lw $s7, Score + 0($zero)
					addi $s4, $s4, 50
					beq $s4, $s7, Resultado
					b int_Reloj
					
#####################################################################				
#                   CONDICIONALES FILA-COLUMNA-BARRA                #
#####################################################################	
			
CondicionalFila:	lw $t0, PosAct+0($zero)
					beq $t0, 1, Caso_Techo	# Caso donde la bola rebota justo en el techo
					beqz $t0, Caso_TechoExc	# Caso donde la bola rebota dentro en el techo
					li $t1, N
					beq $t0, $t1, Resultado	# Caso donde la bola no es tocada por la barra
					addi $t1, $t1, 1
					beq $t0, $t1, Resultado # Caso donde la bola no es tocada por la barra
					li $t1, N
					addi $t1, $t1, -2
					beq $t0, $t1, Caso_BarraNormal	# Caso donde la bola rebota justo antes de la barra
					addi $t1, $t1, 1
					beq $t0, $t1, Caso_BarraExc		# Caso donde la bola rebota en la barra
					jr $ra
					
CondicionalColumna:	lw $t0, PosAct+4($zero)
					beq $t0, 1, Caso_Pared # Caso donde la pola choca justo antes de la pared
					beqz $t0, Caso_ParedIzq
					li $t1, M
					addi $t1, $t1, -1
					beq $t0, $t1, Caso_ParedDer
					addi $t1, $t1, -1
					beq $t0, $t1, Caso_Pared
					jr $ra
				
Caso_BarraNormal:	move $t3, $s6
					addi $t1, $t1, 1
					sw $t1, PosAct+0($zero)
					lw $a0, PosAct+0($zero)	
					lw $a1, PosAct+4($zero)
					jal CalcBytesExc
					move $s6, $v0
					jal Caso_Barra
					move $s6, $t3
					li $t1, N
					addi $t1, $t1, -2
					sw $t1, PosAct+0($zero)
					lb $t0, bola
					sb $t0, Matrix+0($s6)
					b int_Reloj
					
			
Caso_Barra:		move $t0, $s5
				li $t1, 0
				addi $t0, $t0, -2
				beq $s6, $t0, Barra
				li $t1, 8
				addi $t0, $t0, 1
				beq $s6, $t0, Barra
				li $t1, 16
				addi $t0, $t0, 1
				beq $s6, $t0, Barra
				li $t1, 24
				addi $t0, $t0, 1
				beq $s6, $t0, Barra
				li $t1, 32
				addi $t0, $t0, 1
			 	beq $s6, $t0, Barra
				b int_Reloj
			
Caso_BarraExc:	lb $t2, Matrix+0($s6)
				beq $t2, 0x20, Resultado
				jal Caso_Barra
				li $t1, N
				addi $t1, $t1, -2
				sw $t1, PosAct+0($zero)
				lw $a0, PosAct+0($zero)	
				lw $a1, PosAct+4($zero)
				jal CalcBytesExc
				move $s6, $v0
				lb $t0, bola
				sb $t0, Matrix+0($s6)
				b int_Reloj
			
Barra:		lw $t0, Arreglo+0($t1)
			sw $t0, Vector+0($zero)
			lw $t0, Arreglo+4($t1)
			sw $t0, Vector+4($zero)
			jr $ra
			
Caso_Pared: jal Caso_Esquina
			lw $t0, Vector+0($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+0($zero)
			b int_Reloj
			
Caso_ParedIzq:  jal Caso_Esquina
				li $t0, 1
				sw $t0, PosAct+4($zero)
				lw $a0, PosAct+0($zero)	
				lw $a1, PosAct+4($zero)
				jal CalcBytesExc
				move $s6, $v0
				b Caso_Pared

Caso_ParedDer:	jal Caso_Esquina
				li $t0, M
				addi $t0, $t0, -2
				sw $t0, PosAct+4($zero)
				lw $a0, PosAct+0($zero)	
				lw $a1, PosAct+4($zero)
				jal CalcBytesExc
				move $s6, $v0
				b Caso_Pared
				
Caso_Esquina:	lw $t0, PosAct+0($zero)
				beqz $t0, Cambiar_Vector
				beq $t0, 1, Cambiar_Vector
				li $t1, N
				addi $t1, $t1, -1
				beq $t0, $t1, Cambiar_Vector
				addi $t1, $t1, -1
				beq $t0, $t1, Cambiar_Vector
				jr $ra
				
Cambiar_Vector: lw $t0, Vector+0($zero)
				mul $t0, $t0, -1
				sw $t0, Vector+0($zero)
				lw $t0, Vector+4($zero)
				mul $t0, $t0, -1
				sw $t0, Vector+4($zero)
				jr $ra
				
			
Caso_Techo:	lw $t0, Vector+4($zero)
			mul $t0, $t0, -1
			sw $t0, Vector+4($zero)
			lb $t0, bola
			sb $t0, Matrix+0($s6)
			b int_Reloj
			
Caso_TechoExc:	li $t0, 1
				sw $t0, PosAct+0($zero)
				lw $a0, PosAct+0($zero)	
				lw $a1, PosAct+4($zero)
				jal CalcBytesExc
				move $s6, $v0
				b Caso_Techo

Resultado:	lb $t0, bola
			sb $t0, Matrix+0($s6)
			li $v0, 4
			la $a0, Matrix
			syscall
			li $v0, 4
			la $a0, result
			syscall
			li $v0, 1
			move $a0, $s4
			syscall
			li $v0, 4
			la $a0, opcion
			syscall
			li $v0, 4
			la $a0, eleccion
			syscall
			li $v0, 5
			syscall
			move $t0, $v0
			beq $t0, 1, reiniciar
			beq $t0, 2, tecla_Q

reiniciar:	li $s7, 1
			b ret2

int_Reloj:	lb $t0, bola
			sb $t0, Matrix+0($s6)
			li $v0, 4
			la $a0, Matrix
			syscall
			li $v0, 4
			la $a0, espacio
			syscall
			b ret2
			
#####################################################################				
#                               TECLA                               #
#####################################################################	
	
tecla:		lw   $a0, 0xffff0004	## Se lee Receiver data (carácter tecleado)
			li $t0, T		
			mtc0 $t0, $11
			mfc0 $t1, $9
			bgt $t1, $t0, Act_Ball
			
			## Verifica tecla
			
			beq  $a0, 0x66, tecla_F #(f)
			beq  $a0, 0x46, tecla_F #(F)
			beq  $a0, 0x68, tecla_H #(h)
			beq  $a0, 0x48, tecla_H #(H)
			beq  $a0, 0x70, tecla_P #(p)
			beq  $a0, 0x50, tecla_P #(P)
			beq  $a0, 0x71, tecla_Q #(q)
			beq  $a0, 0x51, tecla_Q #(Q)
			b ret3
			
tecla_F:	## Mover barra a la izquierda
			beqz $s1, ret2					## La barra esta en el límite izquierdo, no hacer nada			
			addi $s1, $s1, -1
			addi $s2, $s2, -1
			addi $s5, $s5, -3
			lb $t9, barra
			sb $t9, Matrix+0($s5)
			addi $s5, $s5, 5
			lb $t9, blanco
			sb $t9, Matrix+0($s5)
			addi $s5, $s5, -3
			b dibujar
			
tecla_H:	## Mover barra a la derecha
			li $t9, M
			addi $t9, $t9, -7
			beq	$s1, $t9 ret2				## La barra esta en el límite derecho, no hacer nada			
			addi $s1, $s1, 1
			addi $s2, $s2, 1
			addi $s5, $s5, 3
			lb $t9, barra
			sb $t9, Matrix+0($s5)
			addi $s5, $s5, -5
			lb $t9, blanco
			sb $t9, Matrix+0($s5)
			addi $s5, $s5, 3
			b dibujar	

tecla_P:	## Poner juego en pausa
			mtc0 $zero, $11
			b ret3
			
tecla_Q:	## Salir del juego
			la $a0, text_fin
			li $v0, 4
			syscall
			b fin_juego
	
dibujar:	## Dibujar la barra |  -----  |
			li $v0, 4
			la $a0, Matrix
			syscall
			li $v0, 4
			la $a0, espacio
			syscall
			b ret3
			
#####################################################################				
#                   LISTA DE FUNCIONES EXCEPTION                    #
#####################################################################
			
# Calculo de Bytes a partir de una pos (i,j) de la Matrix
# Planificacion de registros
# $a0 Parametro de entrada: Fila i
# $a1 Parametro de entrada: Columna j
# $v0 Parametro de retorno que almacena la cantidad de Bytes hasta la pos de la Matrix
# $t0 Parametro local Auxiliar
CalcBytesExc:	li $t0, M
			addi $t0, $t0, 1
			mul $t0, $a0, $t0
			add $v0, $t0, $a1
			jr $ra
			
# Suma a la PosAct el Vector
# Planificacion de registros
# Parametro
# $t0 Parametro local: Coordenada  i
# $t1 Parametro local: Coordenada j
# $t2 Parametro local: Subindice
# $v0 Parametro de retorno: Coordena i del PosAct
# $v1 Parametro de retorno: Coordena j del PosAct
SumVecPosAct:	lw $t0, Vector+0($zero)
				lw $t1, PosAct+4($zero)
				add $t0, $t0, $t1
				sw $t0, PosAct+4($zero)
				lw $t0, Vector+4($zero)
				lw $t1, PosAct+0($zero)
				add $t0, $t0, $t1	
				sw $t0, PosAct+0($zero)
				jr $ra
				
# Suma a la PosAnt el Vector
# Planificacion de registros
# Parametro
# $t0 Parametro local: Coordenada  i
# $t1 Parametro local: Coordenada j
# $v0 Parametro de retorno: Coordena i del PosAnt
# $v1 Parametro de retorno: Coordena j del PosAnt
SumVecPosAnt:	lw $t0, Vector+0($zero)
				li $v0, 1
				move $a0, $t0
				syscall
				lw $t1, PosAnt+4($zero)
				add $t0, $t0, $t1
				sw $t0, PosAnt+4($zero)
				lw $t0, Vector+4($zero)
				lw $t1, PosAnt+0($zero)
				add $t0, $t0, $t1
				sw $t0, PosAnt+0($zero)
				jr $ra
					
ret:
# Return from (non-interrupt) exception. Skip offending instruction
# at EPC to avoid infinite loop.
#
	mfc0 $k0 $14		# Bump EPC register
	addiu $k0 $k0 4		# Skip faulting instruction
						# (Need to handle delayed branch case here)
	mtc0 $k0 $14

ret2:		## No es error de exception sino interrupt, solo hace falta hacer esta parte del código
# Restore registers and reset procesor state
#
	lw $v0 s1		# Restore other registers
	lw $a0 s2

	.set noat
	move $at $k1		# Restore $at
	.set at

	mtc0 $zero $13		# Clear Cause register
	
	mtc0 $zero $9		# Clear clock
	
	mfc0 $k0 $12		# Set Status register
	ori  $k0 0x1		# Interrupts enabled
	mtc0 $k0 $12

# Return from exception on MIPS32:
	eret
	
ret3:		## No es error de exception sino interrupt, solo hace falta hacer esta parte del código
# Restore registers and reset procesor state
#
	lw $v0 s1		# Restore other registers
	lw $a0 s2

	.set noat
	move $at $k1		# Restore $at
	.set at

	mtc0 $zero $13		# Clear Cause register
	
	mtc0 $t1 $9			# Restore clock
	
	mfc0 $k0 $12		# Set Status register
	ori  $k0 0x1		# Interrupts enabled
	mtc0 $k0 $12
	
	
		
# Return from exception on MIPS32:
	eret

# Return sequence for MIPS-I (R2000):
#	rfe			# Return from exception handler
				# Should be in jr's delay slot
#	jr $k0
#	 nop



# Standard startup code.  Invoke the routine "main" with arguments:
#	main(argc, argv, envp)
#
	
	.text
	.globl __start
__start:
	###########################################
	#	
	#	$s0 Posición Máxima de la barra
	#	$s1 Posición Actual, inicial (M-7)/2
	#
	###########################################
	
	## Código para inicializar mi programa, completar con lo que necesiten
	li $s0, M
	li $t0, T
	mtc0 $t0, $11
	mtc0 $zero, $9
	
	addi $s0, $s0, -7 	## Posición máxima de la barra, M - 2 (paredes) -5 (barra de 5 posiciones)
	sra $s1, $s0, 1		## Posición central máxima / 2
		
	## Habilitamos interrupciones
	mfc0 	$k0, $12  #Status
	ori		$k0, $k0, 0x1
	mtc0	$k0, $12

	## Habilitamos interrupciones del teclado
	la		$k0, 0xffff0000
	ori		$k0,$k0, 0x2
	sw		$k0, 0xffff0000
	
	## Bienvenida
	li $v0, 4
	la $a0, text_bienvenida
	syscall
	
###################################################################
#                INICIALIZACION DE LA MATRIX                      #
###################################################################
	
	InicMatrix:	li $t0, 0			## Inicializacion Techo
				move $a0, $t0
				jal paramTecho
				move $t0, $v0
				li $t1, 2			## Inicializacion Filas sin Bloques
				move $s4, $t1
				move $a0, $t0
				move $a1, $t1
				jal paramPared
				move $t0, $v0
				li $t1, N			## Inicializacion Filas con Bloques
				addi $t1, $t1, -10
				add $s4, $s4, $t1
				move $a0, $t0
				move $a1, $t1
				jal paramBloque
				move $t0, $v0		
				addi $s4, $s4, 2
				li $t1, N				## Inicializacion Filas sin Bloques
				sub $t1, $t1, $s4
				move $a0, $t0
				move $a1, $t1
				jal paramPared
				move $t0, $v0
				li $s4, 0
				li $t1, 1			## Inicializacion de Barra
				move $a0, $t0
				move $a1, $t1
				jal paramBarra

###################################################################
#                INICIALIZACION DE LA BOLA                        #
###################################################################
	
	jal InicBallFila		## Inic Ball
	move $a0, $v0
	move $a1, $v1
	jal CalcBytes			## Calcular posicion de la bola inicial
	move $s6, $v0
	move $s7, $v0
	lb $t9, bola
	sb $t9, Matrix+0($s6)	## Cargar Bola
				
####################################################################				
#				INICIALIZACION DE LA PANTALLA                      #
####################################################################		    
	
	li $v0, 4
	la $a0, Matrix
	syscall
	
	## Restaurar registro 
	
	li $s7, 0		# Restaurar registro usado para reinicio de juego
	
####################################################################	
# 	             INICIALIZACION DEL VECTOR                         #
####################################################################	
	
	jal Gen_Aleatoria
	move $t1, $v0
	lw $t0, Arreglo+0($t1) 
	sw $t0, Vector+0($zero)
	lw $t0, Arreglo+4($t1)
	sw $t0, Vector+4($zero)
					
#####################################################################				
#                LOOP INFINITO = JUEGO ACTIVO                       #
#####################################################################
loop_Infinito:
	li $t0, 1					# Condicion para reinicio de juego
	beq $t0, $s7, __start
	nop	
	b loop_Infinito
	
#####################################################################				
#                       LISTA DE FUNCIONES                          #
#####################################################################

# Generacion Aleatoria
# Planificacion de registros
# $v0 Parametro de retorno que almacena un numero aleatorio
# $t0 Parametro local Auxiliar

Gen_Aleatoria:	mfc0 $t0, $9
				andi $t0, $t0, 0x00000011
				li $t1, 10
				div $t0, $t1
				mfhi $t0
				li $t1, 2
				div $t0, $t1
				mfhi $t1
				beq $t1, 1, Caso_Impar
				mul $t0, $t0, 4
				b Epilogo
				
Caso_Impar:		addi $t0, $t0, -1
				mul $t0, $t0, 4
				b Epilogo
				
Epilogo:		move $v0, $t0
				jr $ra	
	
# Calculo de Bytes a partir de una pos (i,j) de la Matrix
# Planificacion de registros
# $a0 Parametro de entrada: Fila i
# $a1 Parametro de entrada: Columna j
# $v0 Parametro de retorno que almacena la cantidad de Bytes hasta la pos de la Matrix
# $t0 Parametro local Auxiliar

CalcBytes:	li $t0, M
			addi $t0, $t0, 1
			mul $t0, $a0, $t0
			add $v0, $t0, $a1
			jr $ra	

# Rutina para imprimir techo en pantalla
# Planificacion de registros
# $a0 Parametro de entrada: contador de la matrix
# $t0 Parametro local: auxiliar para contador de la matrix
# $t1 Parametro local: auxiliar para cargar "_" en la matrix
# $t2 Parametro local: auxiliar para cargar "\n" en la matrix

paramTecho:	move $t0, $a0
			lb $t1, techo		# Cargar caracter "_"
			lb $t2, espacio		# Cargar espacio en blanco
			b inicTecho

inicTecho:	sb $t1, Matrix + 0($t0)
			addi $t0, $t0, 1
			bne $t0, M, inicTecho
			sb $t2, Matrix + 0($t0)
			addi $t0, $t0, 1
			move $v0, $t0
			jr $ra

# Rutina para imprimir filas con espacios en blanco en pantalla
# Planificacion de registros
# $a0 Parametro de entrada: contador de la matrix
# $a1 Parametro de entrada: filas a guardar sin bloques
# $t0 Parametro local: auxiliar para contador de la matrix
# $t1 Parametro local: auxiliar de filas a guardar sin bloques
# $t2 Parametro local: auxiliar para cargar "|" en la matrix
# $t3 Parametro local: auxiliar para cargar "&" en la matrix
# $t4 Parametro local: auxiliar para cargar "\n" en la matrix
# $t5 Parametro local: auxiliar para contar numero de blancos almacenados
# $t6 Parametro local: auxiliar para contador de filas sin bloques actual
# $t7 Parametro local: auxiliar tope de blancos a imprimir
# $t8 Parametro local: auxiliar para columnas

paramPared:	move $t0, $a0
			move $t1, $a1
			lb $t2, pared		# Cargar caracter "|"
			lb $t3, blanco		# Cargar espacio en blanco
			lb $t4, espacio		# Cargar "\n" para salto de linea
			li $t5, 0
			li $t6, 0
			li $t8, M
			addi $t7, $t8, -2
			b inicParedInicial
			
inicParedInicial:	sb $t2, Matrix + 0($t0)
					addi $t0, $t0, 1
					
inicEspacio:	sb $t3, Matrix + 0($t0)
				addi $t0, $t0, 1
				addi $t5, $t5, 1
				bne $t5, $t7, inicEspacio
				
inicParedFinal:	sb 	$t2, Matrix + 0($t0)
				addi $t0, $t0, 1
				sb $t4, Matrix + 0($t0)		# Cargar salto de linea
				addi $t0, $t0, 1
				addi $t6, $t6, 1
				li $t5, 0
				bne $t6, $t1, inicParedInicial
				move $v0, $t0
				jr $ra	
				
# Rutina para imprimir filas con bloques en pantalla
# Planificacion de registros
# $a0 Parametro de entrada: contador de la matrix
# $a1 Parametro de entrada: filas a guardar con bloques
# $t0 Parametro local: auxiliar para contador de la matrix
# $t1 Parametro local: auxiliar de filas a guardar con bloques
# $t2 Parametro local: auxiliar para cargar "|" en la matrix
# $t3 Parametro local: auxiliar para cargar "&" en la matrix
# $t4 Parametro local: auxiliar para cargar "\n" en la matrix
# $t5 Parametro local: auxiliar para cargar "[" en la matrix
# $t6 Parametro local: auxiliar para cargar "]" en la matrix
# $t7 Parametro local: auxiliar de espacio entre pared y bloque
# $t8 Parametro local: auxiliar de contador de blancos / bloques / divisor
# $t9 Parametro local: auxiliar de numero de bloques a imprimir / Tamano real
# $s0 Parametro local: auxiliar para condicion de salida

paramBloque:	move $t0, $a0
				move $t1, $a1
				lb $t2, pared
				lb $t3, blanco
				lb $t4, espacio
				lb $t5, corchete1
				lb $t6, corchete2
				li $s0, 0
				b inicParedInicialBloque
				
inicParedInicialBloque:	sb $t2, Matrix + 0($t0)
						addi $t0, $t0, 1
						li $t7, 3
						li $t8, 0

inicEspacioBloque1:	sb $t3, Matrix + 0($t0)
					addi $t0, $t0, 1
					addi $t8, $t8, 1
					bne $t8, $t7, inicEspacioBloque1
					li $t9, M
					addi $t9, $t9, -3
					li $t8, 2
					div $t9, $t8
					mfhi $t8
					beq $t8, $zero, Bloquepar
					b Bloqueimpar

Bloquepar:	addi $t9, $t9, -2		# Impresion para bloques pares
			li $t8, 2
			div $t9, $t8
			mflo $t9
			addi $t9, $t9, -2
			li $t8, 50
			mul $t8, $t9, $t8
			mul $t8, $t1, $t8
			sw $t8, Score + 0($zero)
			li $t8, 0
			b inicBloque

Bloqueimpar:	addi $t9, $t9, -3	# Impresion para bloques impares
				li $t8, 2
				div $t9, $t8
				mflo $t9
				addi $t9, $t9, -1
				li $t8, 50
				mul $t8, $t9, $t8
				mul $t8, $t1, $t8
				sw $t8, Score + 0($zero)
				li $t8, 0
				b inicBloque
					
inicBloque:		sb $t5, Matrix + 0($t0)		# Almacena corchete 1
				addi $t0, $t0, 1
				sb $t6, Matrix + 0($t0)		# Almacena corchete 2
				addi $t0, $t0, 1
				addi $t8, $t8, 1
				bne $t8, $t9, inicBloque
				li $t8, 0
				mul $t9, $t9, 2
				add $t9, $t9, $t7
				li $t7, M
				addi $t7, $t7, -2
				sub $t7, $t7, $t9

inicEspacioBloque2:	sb $t3, Matrix + 0($t0)
					addi $t0, $t0, 1
					addi $t8, $t8, 1
					bne $t8, $t7, inicEspacioBloque2
					li $t8, 0

inicParedFinalBloque:	sb $t2, Matrix + 0($t0)
						addi $t0, $t0, 1
						sb $t4, Matrix + 0($t0)
						addi $t0, $t0, 1
						addi $s0, $s0, 1
						bne $s0, $t1, inicParedInicialBloque
						move $v0, $t0
						jr $ra

# Rutina para inicializacion de barra en pantalla
# Planificacion de registros
# $a0 Parametro de entrada: contador de la matrix
# $a1 Parametro de entrada: filas a guardar sin bloques
# $t0 Parametro local: auxiliar para contador de la matrix
# $t1 Parametro local: auxiliar de filas a guardar sin bloques
# $t2 Parametro local: auxiliar para cargar "|" en la matrix
# $t3 Parametro local: auxiliar para cargar "&" en la matrix
# $t4 Parametro local: auxiliar para cargar "\n" en la matrix
# $t5 Parametro local: auxiliar para cargar "=" en la matrix
# $t6 Parametro local: auxiliar para contador de blancos almacenados / filas
# $t7 Parametro local: auxiliar para almacenar las columnas 
# $t8 Parametro local: auxiliar tope de impresion de blancos
# $t9 Parametro local: auxiliar para contador / divisor

paramBarra:	move $t0, $a0
			move $t1, $a1
			lb $t2, pared
			lb $t3, blanco
			lb $t4, espacio
			lb $t5, barra
			li $t6, 0
			li $t9, 0
			li $t7, M
			addi $t8, $t7, -2
			b inicParedInicial3

inicParedInicial3:	sb $t2, Matrix + 0($t0)
					addi $t0, $t0, 1

inicEspacio3:	sb $t3, Matrix + 0($t0)
				addi $t0, $t0, 1
				addi $t6, $t6, 1
				bne $t6, $t8, inicEspacio3

inicParedFinal3:	sb $t2, Matrix + 0($t0)
					addi $t0, $t0, 1
					addi $t9, $t9, 1
					bne $t9, $t1, inicParedInicial3
					li $t6, N
					addi $t6, $t6, -1
					li $t7, M
					addi $t7, $t7, 1
					mul $t6, $t6, $t7
					li $t7, M
					li $t9, 2
					div $t7, $t9
					mflo $t9
					add $t6, $t6, $t9
					move $s5, $t6
					sb $t5, Matrix + 0($t6) 	# Almacenamiento de barra
					addi $t6, $t6, -1
					sb $t5, Matrix + 0($t6)
					addi $t6, $t6, -1
					sb $t5, Matrix + 0($t6) 
					addi $t6, $t6, 3
					sb $t5, Matrix + 0($t6)
					addi $t6, $t6, 1
					sb $t5, Matrix + 0($t6) 	# Fin almacenamiento de barra
					sb $t4, Matrix + 0($t0)
					addi $t0, $t0, 1
					addi $s1, $t9, -3
					addi $s2, $t9, 3
					jr $ra

# Rutina para inicializacion de la bola en pantalla
# Planificacion de registros
# $t0 Parametro local: auxiliar para almacenar filas
# $t1 Parametro local: auxiliar para almacenar columnas
# $t2 Parametro local: auxiliar para division

InicBallFila:	li $t0, N				# Fila en donde inicia la bola
				addi $t0, $t0, -2
				sw $t0, PosAct+0($zero)
				sw $t0, PosAnt+0($zero)
				b InicBallColum
					
InicBallColum:	li $t1, M		# Columna de inicio de la bola
				li $t2, 2
				div $t1, $t2
				mflo $t1
				sw $t1, PosAct+4($zero)
				sw $t1, PosAnt+4($zero)
				move $v0, $t0
				move $v1, $t1
				jr $ra			
				
## Cuando se pulse Q se ejecutara el main.s
fin_Juego: 
	lw $a0 0($sp)		# argc
	addiu $a1 $sp 4		# argv
	addiu $a2 $a1 4		# envp
	sll $v0 $a0 2
	addu $a2 $a2 $v0
	jal main
	nop

	li $v0 10
	syscall			# syscall 10 (exit)

	.globl __eoth
__eoth:
