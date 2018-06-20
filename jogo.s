
.data
FUNDO: .string "sprites/map_sp.bin"
.text
#OBS:
# a0 : endereço onde o syscall chama
# a7 : onde indicar qual o syscall será utilizado

	# seta o exception handler
 	la t0,exceptionHandling		# carrega em t0 o endere?o base das rotinas do sistema ECALL
 	csrrw zero,5,t0 		# seta utvec (reg 5) para o endere?o t0
 	csrrsi zero,0,1 		# seta o bit de habilita��oo de interrup��oo em ustatus (reg 0)
 	
FUNDO:
	la a0, FUNDO # carrega o arquivo para o a0, onde vai ser chamado pelo syscall
	li a7, 1024 # syscall de read file
	ecall
	
	li a1,0xff000000 # indica o endereço da VGA a ser carregada a imagem de fundo
	li a2,76800 # tamanho do arquivo, em bytes
	li a7,63 # SYSCALL de Read File
	ecall
	
	li a7,57 # syscall de close file
	ecall
	
FIM:
	li a7,10 # syscall de exit
	ecall

.include "assets/SYSTEMv11.s"
