#OBS:
# t6 = tecla pressionada
# s0 = nivel
# s1 = qtd vidas
# s2 = score
# s3 = high score

.data
# recursos externos
FUNDO: .string "sprites/map_sp.bin"
BONECO: .string "sprites/banana.bin"

#strings do jogo
titulo: .string "MS PACMAN"
highscore: .string "HIGH SCORE"
estrelando: .string "ESTRELANDO"
up: .string "UP"
pbotao: .string "PRESSIONE QUALQUER BOTAO PARA JOGAR"

.text
	# seta o exception handler
 	la t0,exceptionHandling		# carrega em t0 o endereco base das rotinas do sistema ECALL
 	csrrw zero,5,t0 		# seta utvec (reg 5) para o endere?o t0
 	csrrsi zero,0,1 		# seta o bit de habilitacao de interrupcao em ustatus (reg 0)
	
	#seta os valores iniciais:
	# t6 = 0, pra checar o botao no menu
	# nivel 1, 3 vidas, 0 score, 0 high score
	add t6, zero,zero
	addi s0, zero, 1
	addi s1, zero, 3
	addi s4, zero, 110
#----------------------------------------------
# Menu principal do jogo
# Qualquer tecla inicia
#----------------------------------------------

STATIC_MENU: # parte estatica do menu
	# printa as vidas
	mv a0,s1
	li a1,38
	li a2,10
	li a3,0x00ff
	li a7,101
	ecall
	
	la a0,up
	li a1,56
	li a2,10
	li a3,0x00ff
	li a7,104
	ecall
	
	# printa o high score
	mv a0,s3
	li a1,170
	li a2,10
	li a3,0x00ff
	li a7,101
	ecall
	
	la a0,highscore
	li a1,188
	li a2,10
	li a3,0x00ff
	li a7,104
	ecall
	
	# printa o titulo MS PACMAN
	la a0,titulo
	li a1,120
	li a2,60
	li a3,0x0027
	li a7,104
	ecall
	
	# printa o estrelando ms pacman
	la a0,estrelando
	li a1,120
	li a2,100
	li a3,0x00ff
	li a7,104
	ecall
	la a0,titulo
	li a1,122
	li a2,110
	li a3,0x0037
	li a7,104
	ecall
	
	# printa o 'pressione qualquer botao'
	la a0,pbotao
	li a1,20
	li a2,180
	li a3,0x00ff
	li a7,104
	ecall
	
DYN_MENU: # parte dinamica do menu
	jal TECLADO	# checa se o user apertou algum botao
	bne t6,zero,BACKGROUND # se t6 for diferente de zero, executa o jogo, caso contrario, continua no loop
	j DYN_MENU
	
#----------------------------------------------
# Execucao do jogo
#----------------------------------------------
BACKGROUND:  #background do jogo
	la a0,FUNDO # carrega o arquivo para o a0, onde vai ser chamado pelo syscall
	li a1,0
	li a2,0
	li a7,1024 # syscall de open file
	ecall
	
	li a1,0xff000000 # indica o endereço da VGA a ser carregada a imagem de fundo
	li a2,76800 # tamanho do arquivo,em bytes
	li a7,63 # syscall de Read File
	ecall
	
	li a7,57 # syscall de close file
	ecall

#----------------------------------------------
# Finaliza a execucao
#----------------------------------------------
FIM:
	li a7,10 # syscall de exit
	ecall

#----------------------------------------------
# Bind do teclado. Salva a tecla em t6
#----------------------------------------------
TECLADO:
	li t2,0xff200000 # endereco do MIMO
	lw t3,0(t2) #salva a tecla em t0
	beq t3,zero,RETORNA
	lw t6,4(t2) # le a tecla pressionada em t6
# Retorna para o antigo PC
RETORNA: jr ra,0	

.include "assets/SYSTEMv11.s"
#180x100 o pacman
