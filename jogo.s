#OBS:
# t6 = tecla pressionada
# s0 = nivel
# s1 = qtd vidas
# s2 = score
# s3 = high score
# s4 = pos x do boneco

.data
# recursos externos
FUNDO: .string "sprites/map_sp.bin"
BONECO: .string "sprites/b_med_open.bin"
BONECO_SP: .space 225

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

#----------------------------------------------
# Seta os valores iniciais. Utilizar caso dê game over
#----------------------------------------------
RESET:
	add t6, zero,zero # seta t6 = 0 (tecla pressionada)
	addi s0, zero, 1 # seta s0 = 1 (mapa atual, no caso, o primeiro mapa)
	addi s1, zero, 3 # seta s1 = 0 (qtd de vidas)
	addi s4, zero, 100 # seta s4 = 110 (posicao x inicial do pac man)
	addi s5, zero, 180 # seta s5 = 180 (posicao y inicial do pac man)
#----------------------------------------------
# Menu principal do jogo
# Qualquer tecla inicia
#----------------------------------------------

STATIC_MENU: # parte estatica do menu
	# printa as vidas
	mv a0,s1 # coloca a qtd de vidas em a0
	li a1,38 # posicao x do texto
	li a2,10 # posicao y do texto
	li a3,0x00ff # 00 = cor de fundo; ff = cor da letra
	li a7,101 # chama o syscall 101, de print int do SYSTEMv11.s
	ecall
	
	la a0,up # coloca o texto UP em a0
	li a1,56 # posicao x do texto
	li a2,10 # posicao y do texto
	li a3,0x00ff # 00 = cor de fundo; ff = cor da letra
	li a7,104 # chama o syscall 104, de print string do SYSTEMv11.s
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
	j DYN_MENU # cria o loop para sempre esperar alguma tecla ser pressionada
	
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
	jal SPAWN
	
	
SPAWN: # spawna o pac man pela primeira vez
	la a0,BONECO 
	li a1,0
	li a7,1024
	ecall # carrega o pac man em a0 (open)
	
	mv t0,a0
	la a1,BONECO_SP
	li a2,225
	li a7,63
	ecall # usa a0 para abrir a img 
	
	mv a0,t0
	li a7,57
	ecall # fecha o arquivo
	
	jal SPAWN2 # chama a funcao para gerar o pac man corretamente
	jr ra,0 # retorna
	
#----------------------------------------------
# Funcao que gera objetos no mapa
# To-do-List:
#   Adaptar para servir para qualquer objeto, bastando setar a posicao anteriormente e qual o sprite a ser utilizado
# Por enquanto, só funciona com o primeiro pac man
#----------------------------------------------
SPAWN2:
	li t0,15 # altura do objeto
	li t1,15 # largura do objeto
	li a1,0xff000000 # endereco inicial para desenhar o obj
	la a2,BONECO_SP # espaco
	SPAWN2_LOOP: beqz t0,SPAWN2_LOOP2 # caso t0 seja 0, pula para a prox linha
		lb t3,0(a2) # caso contrario, decrementa t0 e repete, até terminar os 15px horizontais da imagem.
		sb t3,0(a1)
		addi t0,t0,-1 # decrementa t0
		addi a2,a2,1 # aumenta a2 (tamanho do espaço BONECO_SP)
		addi a1,a1,1 # aumenta a1 (endereco a ser desenhado)
		j SPAWN2_LOOP
		
 		SPAWN2_LOOP2:beqz t1,FIM_SPAWN2 # caso esteja na ultima linha, para a execucao do loop
			addi t1,t1,-1 # caso contrario, pula uma linha e dá o espacamento necessario até chegar na posicao necessaria
			addi a1,a1,305
			addi t0,t0,15
			j SPAWN2_LOOP # volta para o primeiro loop, para desenhar a proxima linha
			
			FIM_SPAWN2:
				jr ra,0 # retorna
				
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
	lw t3,0(t2) # coloca a tecla em t3
	beq t3,zero,RETORNA # se nao houver tecla pressionada, volta
	lw t6,4(t2) # le a tecla pressionada em t6
# Retorna para o antigo PC
RETORNA: jr ra,0	

CALC_POS: # calcula as posicoes, de px para o endereco desejado
	# a ser implementado

.include "assets/SYSTEMv11.s"
