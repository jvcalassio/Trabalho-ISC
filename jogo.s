#OBS:
# s0 = nivel
# s1 = qtd vidas
# s2 = score
# s3 = highscore
# s4 = pos x do boneco
# s5 = pos y do boneco
# s6 = tecla pressionada
# s7 = status da boca (0 = fechado; 1 = meio (abrindo); 2 = meio (fechando); 3 = aberto)

.data
# recursos externos
FUNDO: .string "sprites/map_cp.bin"

PACMAN_RIGHT: .string "sprites/b_med_open_right.bin" #pac man base, com a boca meio aberta
PACMAN_RIGHT_OPEN: .string "sprites/b_full_open_right.bin"
PACMAN_RIGHT_CLOSED: .string "sprites/b_closed_right.bin"
PACMAN_LEFT: .string "sprites/b_med_open_left.bin"
PACMAN_LEFT_OPEN: .string "sprites/b_full_open_left.bin"
PACMAN_LEFT_CLOSED: .string "sprites/b_closed_left.bin"
PACMAN_UP: .string "sprites/b_med_open_up.bin"
PACMAN_UP_OPEN: .string "sprites/b_full_open_up.bin"
PACMAN_UP_CLOSED: .string "sprites/b_closed_up.bin"
PACMAN_DOWN: .string "sprites/b_med_open_down.bin"
PACMAN_DOWN_OPEN: .string "sprites/b_full_open_down.bin"
PACMAN_DOWN_CLOSED: .string "sprites/b_closed_down.bin"

INKY: .string "sprites/blu_1.bin" # fantasma azul base, inky
PINKY: .string "sprites/pink_1.bin" # fantasma rosa base, pinky
SUE: .string "sprites/orang_1.bin" # fantasma laranja, sue
BLINKY: .string "sprites/red_1.bin" # fantasma vermelho, blinky
BANANA: .string "sprites/banana.bin"

BLACK: .string "sprites/black.bin" # tela preta, 15x15
SPRITE_SP: .space 225

#strings do jogo
titulo: .string "MS PACMAN"
highscore: .string "HIGH SCORE"
estrelando: .string "ESTRELANDO"
up: .string "UP"
pbotao: .string "PRESSIONE QUALQUER BOTAO PARA JOGAR"
score: .string "SCORE"

tempX: .word 0
tempY: .word 0
tempObj: .word 0

tempRet0: .word 0
tempRet1: .word 0
tempRet2: .word 0
tempRet3: .word 0

.text
	# seta o exception handler
 	la t0,exceptionHandling		# carrega em t0 o endereco base das rotinas do sistema ECALL
 	csrrw zero,5,t0 		# seta utvec (reg 5) para o endere?o t0
 	csrrsi zero,0,1 		# seta o bit de habilitacao de interrupcao em ustatus (reg 0)

#----------------------------------------------
# Seta os valores iniciais. Utilizar caso dê game over
#----------------------------------------------
RESET:
	add s6, zero,zero # seta s6 = 0 (tecla pressionada)
	addi s0, zero, 1 # seta s0 = 1 (mapa atual, no caso, o primeiro mapa)
	addi s1, zero, 3 # seta s1 = 3 (qtd de vidas)
	addi s4, zero, 103 # seta s4 = 103 (posicao x inicial do pac man)
	addi s5, zero, 175 # seta s5 = 175 (posicao y inicial do pac man)
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
	bne s6,zero,BACKGROUND # se s6 for diferente de zero, executa o jogo, caso contrario, continua no loop
	j DYN_MENU # cria o loop para sempre esperar alguma tecla ser pressionada
	
#----------------------------------------------
# Execucao do jogo
# BACKGROUND: gera o bg e chama a geracao das partes estaticas/iniciais da tela
# MAIN_LOOP: faz a chamada das funcoes que geram as partes dinamicas da tela
#----------------------------------------------
BACKGROUND:  #background do jogo
	li s6,0
	la a0,FUNDO # carrega o arquivo para o a0, onde vai ser chamado pelo syscall
	li a1,0
	li a2,0
	li a7,1024 # syscall de open file
	ecall
	
	mv t0,a0
	li a1,0xff000000 # indica o endereço da VGA a ser carregada a imagem de fundo
	li a2,76800 # tamanho do arquivo,em bytes
	li a7,63 # syscall de Read File
	ecall
	
	mv a0,t0
	li a7,57 # syscall de close file
	ecall
	jal SPAWN_OBJECTS
	j MAIN_LOOP # colocar nesse loop as chamadas para as funcoes principais
	j FIM

	
# Spawna os objetos pela primeira vez
SPAWN_OBJECTS:
	la t0,tempRet0 # salva o return adress original (porque essa funcao chama outras, mudando o RA)
	sw ra,0(t0) # Salva o endereco da funcao que o chamou originalmente
	#---------------
	# Gera o Pac Man
	#---------------
	la a0,PACMAN_RIGHT
	li a1,0
	li a7,1024
	ecall # carrega o pac man em a0 (open)
	
	mv t0,a0
	la a1,SPRITE_SP
	li a2,225
	li a7,63
	ecall # usa a0 para abrir a img 
	
	mv a0,t0
	li a7,57
	ecall # fecha o arquivo
	
	mv a0,s4 # copia a pos x do boneco para a0
	mv a1,s5 # copia a pos y do boneco para a1
	jal CALC_POS # calcula a posicao do endereco e retorna em a2
	
	mv a0,t0
	jal SPAWN2 # chama a funcao para gerar o pac man corretamente
	
	#---------------------------
	# Gera o fantasma azul, INKY
	#---------------------------
	la a0,INKY 
	li a1,0
	li a7,1024
	ecall # carrega o fantasma em a0 (open)
	
	mv t0,a0
	la a1,SPRITE_SP
	li a2,225
	li a7,63
	ecall # usa a0 para abrir a img 
	
	mv a0,t0
	li a7,57
	ecall # fecha o arquivo
	
	li a0,87 # copia a pos x do boneco para a0
	li a1,107 # copia a pos y do boneco para a1
	jal CALC_POS # calcula a posicao do endereco e retorna em a2
	
	mv a0,t0
	jal SPAWN2 # chama a funcao para gerar o fantasma corretamente
	
	#----------------------------
	# Gera o fantasma rosa, PINKY
	#----------------------------
	la a0,PINKY 
	li a1,0
	li a7,1024
	ecall # carrega o fantasma em a0 (open)
	
	mv t0,a0
	la a1,SPRITE_SP
	li a2,225
	li a7,63
	ecall # usa a0 para abrir a img 
	
	mv a0,t0
	li a7,57
	ecall # fecha o arquivo
	
	li a0,103 # copia a pos x do boneco para a0
	li a1,107 # copia a pos y do boneco para a1
	jal CALC_POS # calcula a posicao do endereco e retorna em a2
	
	mv a0,t0
	jal SPAWN2 # chama a funcao para gerar o fantasma corretamente
	
	#-----------------------------
	# Gera o fantasma laranja, SUE
	#-----------------------------
	la a0,SUE
	li a1,0
	li a7,1024
	ecall # carrega o fantasma em a0 (open)
	
	mv t0,a0
	la a1,SPRITE_SP
	li a2,225
	li a7,63
	ecall # usa a0 para abrir a img 
	
	mv a0,t0
	li a7,57
	ecall # fecha o arquivo
	
	li a0,118 # copia a pos x do boneco para a0
	li a1,107 # copia a pos y do boneco para a1
	jal CALC_POS # calcula a posicao do endereco e retorna em a2
	
	mv a0,t0
	jal SPAWN2 # chama a funcao para gerar o fantasma corretamente
	
	#----------------------------
	# Gera o fantasma red, BLINKY
	#----------------------------
	la a0,BLINKY
	li a1,0
	li a7,1024
	ecall # carrega o fantasma em a0 (open)
	
	mv t0,a0
	la a1,SPRITE_SP
	li a2,225
	li a7,63
	ecall # usa a0 para abrir a img 
	
	mv a0,t0
	li a7,57
	ecall # fecha o arquivo
	
	li a0,103 # copia a pos x do boneco para a0
	li a1,85 # copia a pos y do boneco para a1
	jal CALC_POS # calcula a posicao do endereco e retorna em a2
	
	mv a0,t0
	jal SPAWN2 # chama a funcao para gerar o fantasma corretamente
	
	#----------------------------
	# Gera os textos à esquerda, de score, high score, vidas
	#---------------------------
	# Numero de vidas
	mv a0,s1 # coloca a qtd de vidas em a0
	li a1,230 # x a ser impresso
	li a2,13 # y a ser impresso
	li a3,0x00ff # cor de fundo e letra
	li a7,101
	ecall
	# Texto de vidas
	la a0,up
	li a1,240
	li a2,13
	li a3,0x00ff
	li a7,104
	ecall
	# Numero do score
	mv a0,s2
	li a1,230
	li a2,30
	li a7,101
	ecall
	# Texto do score
	la a0,score
	li a2,39
	li a7,104
	ecall
	# Numero do highscore
	mv a0,s3
	li a2,52
	li a7,101
	ecall
	# Texto do highscore
	la a0,highscore
	li a2,61
	li a7,104
	ecall
	
	lw t0,tempRet0 # Carrega o endereço original da memoria
	jr t0,0 # volta para a execucao de BACKGROUND
	
#------------------------------------------------------------------------
# Loop principal do jogo
# Colocar aqui todas as funções de repetição para o funcionamento do jogo
#-------------------------------------------------------------------------
MAIN_LOOP:
	j CHECK_MOV
	j MAIN_LOOP

# Verifica se há tecla pressionada, e move o pac man
CHECK_MOV:
	#la t0,tempRet1 # Salva o endereco da funcao que o chamou originalmente
	#sw ra,0(t0)
	
	jal TECLADO
	li t1,97 # A - seta pra esquerda
	li t2,100 # D - seta pra direita
	li t3,119 # W - seta pra cima
	li t4,115 # S - seta pra baixo
	
	li a0,35 # Sleep, pro jogo nao correr
	li a7,32
	ecall
	
	mv a1,s4
	mv a2,s5
	beq s6,t4,MOV_BAIXO
	beq s6,t3,MOV_CIMA
	beq s6,t2,MOV_DIREITA
	beq s6,t1,MOV_ESQUERDA
	j MAIN_LOOP
	
# Movimenta o pac man para a esquerda
# Parametros:
# a1 = posicao x atual
# a2 = posicao y atual
# A implementar: mover qualquer objeto
MOV_ESQUERDA:
	#la t0,tempRet2 # Salva o endereco da funcao que o chamou originalmente
	#sw ra,0(t0)
	
	li t0,13 # limite de colisao do ponto de referencia
	ble s4,t0,STOP_PACMAN
	jal BLACK_BLOCK # Muda o local atual para preto
	
	la t0,tempObj
	sw a0,0(t0) # Salva o objeto (a ser movimentado) na memoria
	
	# Realiza o movimento para a esquerda
	li t0,1
	li t1,2
	li t2,3
	beq s7,zero,ABRE_BOCA_ESQUERDA_1
	beq s7,t0,ABRE_BOCA_ESQUERDA_2
	beq s7,t1,FECHA_BOCA_ESQUERDA_2
	beq s7,t2,FECHA_BOCA_ESQUERDA_1
	VOLTA_MOV_ESQUERDA:
	li a1,0
	li a7,1024
	ecall # abre o arquivo
	
	mv t0,a0 # copia o file descriptor para t0 (pois o ecall 63 muda a0)
	la a1,SPRITE_SP
	li a2,225
	li a7,63
	ecall # carrega no sp
	
	mv a0,t0 # devolve o FD para fechar o arquivo
	li a7,57
	ecall # fecha o arquivo
	
	lw a0,tempX
	lw a1,tempY
	addi a0,a0,-8
	jal CALC_POS # retorna a posicao do endereco, em a2
	
	jal SPAWN2
	addi s4,s4,-8
	
	j MAIN_LOOP

ABRE_BOCA_ESQUERDA_1:
	la a0,PACMAN_LEFT
	li s7,1
	j VOLTA_MOV_ESQUERDA
ABRE_BOCA_ESQUERDA_2:
	la a0,PACMAN_LEFT_OPEN
	li s7,3
	j VOLTA_MOV_ESQUERDA

FECHA_BOCA_ESQUERDA_1:
	la a0,PACMAN_LEFT
	li s7,2
	j VOLTA_MOV_ESQUERDA
FECHA_BOCA_ESQUERDA_2:
	la a0,PACMAN_LEFT_CLOSED
	li s7,0
	j VOLTA_MOV_ESQUERDA
	
# Movimenta o pac man para a direita
# Parametros:
# a1 = posicao x atual
# a2 = posicao y atual
# A implementar: mover qualquer objeto
MOV_DIREITA:
	#la t0,tempRet2 # Salva o endereco da funcao que o chamou originalmente
	#sw ra,0(t0)
	
	li t0,196 # limite de colisao do ponto de referencia
	bge s4,t0,STOP_PACMAN
	jal BLACK_BLOCK # Muda o local atual para preto
	
	#la t0,tempObj
	#sw a0,0(t0) # Salva o objeto (a ser movimentado) na memoria
	
	# Realiza o movimento para a direita
	li t0,1
	li t1,2
	li t2,3
	beq s7,zero,ABRE_BOCA_DIREITA_1
	beq s7,t0,ABRE_BOCA_DIREITA_2
	beq s7,t1,FECHA_BOCA_DIREITA_2
	beq s7,t2,FECHA_BOCA_DIREITA_1
	VOLTA_MOV_DIREITA:
	li a1,0
	li a7,1024
	ecall # abre o arquivo
	
	mv t0,a0 # copia o file descriptor para t0 (pois o ecall 63 muda a0)
	la a1,SPRITE_SP
	li a2,225
	li a7,63
	ecall # carrega no sp
	
	mv a0,t0 # devolve o FD
	li a7,57
	ecall # fecha o arquivo
	
	lw a0,tempX
	lw a1,tempY
	addi a0,a0,+8
	jal CALC_POS # retorna a posicao do endereco, em a2
	
	jal SPAWN2
	addi s4,s4,+8
	
	j MAIN_LOOP

ABRE_BOCA_DIREITA_1:
	la a0,PACMAN_RIGHT
	li s7,1
	j VOLTA_MOV_DIREITA
ABRE_BOCA_DIREITA_2:
	la a0,PACMAN_RIGHT_OPEN
	li s7,3
	j VOLTA_MOV_DIREITA

FECHA_BOCA_DIREITA_1:
	la a0,PACMAN_RIGHT
	li s7,2
	j VOLTA_MOV_DIREITA
FECHA_BOCA_DIREITA_2:
	la a0,PACMAN_RIGHT_CLOSED
	li s7,0
	j VOLTA_MOV_DIREITA
	
# Movimenta o pac man para cima
# Parametros:
# a1 = posicao x atual
# a2 = posicao y atual
# A implementar: mover qualquer objeto
MOV_CIMA:
	#la t0,tempRet2 # Salva o endereco da funcao que o chamou originalmente
	#sw ra,0(t0)
	
	li t0,13 # limite de colisao do ponto de referencia
	bge t0,s5,STOP_PACMAN
	jal BLACK_BLOCK # Muda o local atual para preto
	
	#la t0,tempObj
	#sw a0,0(t0) # Salva o objeto (a ser movimentado) na memoria
	
	# Realiza o movimento para a direita
	li t0,1
	li t1,2
	li t2,3
	beq s7,zero,ABRE_BOCA_CIMA_1
	beq s7,t0,ABRE_BOCA_CIMA_2
	beq s7,t1,FECHA_BOCA_CIMA_2
	beq s7,t2,FECHA_BOCA_CIMA_1
	VOLTA_MOV_CIMA:
	li a1,0
	li a7,1024
	ecall # abre o arquivo
	
	mv t0,a0 # copia o file descriptor para t0 (pois o ecall 63 muda a0)
	la a1,SPRITE_SP
	li a2,225
	li a7,63
	ecall # carrega no sp
	
	mv a0,t0 # devolve o FD
	li a7,57
	ecall # fecha o arquivo
	
	lw a0,tempX
	lw a1,tempY
	addi a1,a1,-8
	jal CALC_POS # retorna a posicao do endereco, em a2
	
	jal SPAWN2
	addi s5,s5,-8
	
	j MAIN_LOOP

ABRE_BOCA_CIMA_1:
	la a0,PACMAN_UP
	li s7,1
	j VOLTA_MOV_CIMA
ABRE_BOCA_CIMA_2:
	la a0,PACMAN_UP_OPEN
	li s7,3
	j VOLTA_MOV_CIMA

FECHA_BOCA_CIMA_1:
	la a0,PACMAN_UP
	li s7,2
	j VOLTA_MOV_CIMA
FECHA_BOCA_CIMA_2:
	la a0,PACMAN_UP_CLOSED
	li s7,0
	j VOLTA_MOV_CIMA

# Movimenta o pac man para cima
# Parametros:
# a1 = posicao x atual
# a2 = posicao y atual
# A implementar: mover qualquer objeto
MOV_BAIXO:
	#la t0,tempRet2 # Salva o endereco da funcao que o chamou originalmente
	#sw ra,0(t0)
	
	li t0,219 # limite de colisao do ponto de referencia
	bge s5,t0,STOP_PACMAN
	jal BLACK_BLOCK # Muda o local atual para preto
	
	#la t0,tempObj
	#sw a0,0(t0) # Salva o objeto (a ser movimentado) na memoria
	
	# Realiza o movimento para a direita
	li t0,1
	li t1,2
	li t2,3
	beq s7,zero,ABRE_BOCA_BAIXO_1
	beq s7,t0,ABRE_BOCA_BAIXO_2
	beq s7,t1,FECHA_BOCA_BAIXO_2
	beq s7,t2,FECHA_BOCA_BAIXO_1
	VOLTA_MOV_BAIXO:
	li a1,0
	li a7,1024
	ecall # abre o arquivo
	
	mv t0,a0 # copia o file descriptor para t0 (pois o ecall 63 muda a0)
	la a1,SPRITE_SP
	li a2,225
	li a7,63
	ecall # carrega no sp
	
	mv a0,t0 # devolve o FD
	li a7,57
	ecall # fecha o arquivo
	
	lw a0,tempX
	lw a1,tempY
	addi a1,a1,+8
	jal CALC_POS # retorna a posicao do endereco, em a2
	
	jal SPAWN2
	addi s5,s5,+8
	
	j MAIN_LOOP

ABRE_BOCA_BAIXO_1:
	la a0,PACMAN_DOWN
	li s7,1
	j VOLTA_MOV_BAIXO
ABRE_BOCA_BAIXO_2:
	la a0,PACMAN_DOWN_OPEN
	li s7,3
	j VOLTA_MOV_BAIXO

FECHA_BOCA_BAIXO_1:
	la a0,PACMAN_DOWN
	li s7,2
	j VOLTA_MOV_BAIXO
FECHA_BOCA_BAIXO_2:
	la a0,PACMAN_DOWN_CLOSED
	li s7,0
	j VOLTA_MOV_BAIXO
	
# Para o movimento do pac man
STOP_PACMAN:
	li s6,0
	j CHECK_MOV
	
BLACK_BLOCK: # Deixa o local preto
	la t0,tempRet3 # Salva o endereco da funcao que o chamou originalmente
	sw ra,0(t0)
	
	la t1,tempX
	sw a1,0(t1) # salva o x recebido na memoria
	la t1,tempY
	sw a2,0(t1) # salva o y recebido na memoria
	
	la a0,BLACK
	li a1,0
	li a7,1024
	ecall # abre o arquivo
	
	mv t0,a0
	la a1,SPRITE_SP
	li a2,225
	li a7,63
	ecall # carrega no sp
	
	mv a0,t0
	li a7,57
	ecall # fecha o arquivo
	
	lw a0,tempX
	lw a1,tempY
	jal CALC_POS
	
	la a0,BLACK
	jal SPAWN2
	
	lw t0,tempRet3 # Carrega o endereço original da memoria
	jr t0,0 # Retorna para a funcao que o chamou originalmente
	
#--------------------------------------------------------------
# Gera objetos no mapa
# Funciona com qualquer objeto
# Usar CALC_POS para gerar qual a posicao a ser desenhada
# Carregue a imagem com o open em a0, e de o read em SPRITE_SP
# a0 = Imagem carregada pelo Open
# a2 = resultado do CALC_POS
#--------------------------------------------------------------
SPAWN2:
	li t0,15 # altura do objeto
	li t1,14 # largura do objeto
	mv a1,a2 # define a posicao inicial a ser desenhado o boneco (em a2, gerado pela funcao CALC_POS)
	la a2,SPRITE_SP # muda a2 para o vet 225
	SPAWN2_LOOP: beqz t0,SPAWN2_LOOP2 # caso t0 seja 0, pula para a prox linha
		lb t3,0(a2) # caso contrario, decrementa t0 e repete, até terminar os 15px horizontais da imagem.
		sb t3,0(a1)
		addi t0,t0,-1 # decrementa t0
		addi a2,a2,1 # aumenta a2 (tamanho do espaço vet)
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
# Bind do teclado. Salva a tecla em s6
#----------------------------------------------
TECLADO:
	li t2,0xff200000 # endereco do MIMO
	lw t3,0(t2) # coloca a tecla em t3
	beq t3,zero,RETORNA # se nao houver tecla pressionada, volta
	lw s6,4(t2) # le a tecla pressionada em s6
# Retorna para o antigo PC
RETORNA: jr ra,0	

CALC_POS: # calcula as posicoes, de px para o endereco desejado
	# ARGUMENTOS:
	# a0 = pos x desejada, em px
	# a1 = pos y desejada, em px
	# a2 = resultado
	# 0xff000000 é sempre o endereco base
	li t0,320
	li t1,240
	addi a0,a0,-1 # a0--; porque a faixa do x é de 0 a 319
	addi a1,a1,-1 # a1--; porque a faixa do y é de 0 a 239
	mul t0,t0,a1 # a3 = y * 320
	add a2,t0,a0 # a3 = (y * 320) + x
	li t0,0xff000000
	add a2,a2,t0 # a3 = end. base + (y*320) + x
	jr ra,0

#----------------------------------------------
# Finaliza a execucao
#----------------------------------------------
FIM:
	li a7,10 # syscall de exit
	ecall
.include "assets/SYSTEMv11.s"
