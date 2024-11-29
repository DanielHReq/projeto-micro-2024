# Animação usando temporizador com interrupção
# Funcionando, isolado e melhorado - Semana 4

/*
Registradores utilizados e funcionalidades:

r16 - armazena ponteiro que recebe o endereço dos switches
r17 - armazena ponteiro que recebe o endereço dos leds vermelhos
r18 - variável auxiliar de leitura do estado do switch SW0
r19 - variável auxiliar para testar estado do switch SW0
r20 - variável que recebe o valor inicial do bit que será deslocado na animação
r21 - contador utilizado para produzir o atraso de 200ms
r22 - variável auxiliar para testar os limites inferior e superior

 */

# Endereços base dos LEDs vermelhos e dos Switches
.equ RED_LEDS, 0x10000000         # Endereço dos LEDs vermelhos
.equ SWITCHES, 0x10000040         # Endereço dos switches
.equ TIMER,		0X10002000	# Endereço do temporizador

# Constantes para temporizador
.equ FREQUENCY, 270000000          # Frequência do sistema em Hz
.equ DELAY_MS, 60                 # Atraso em milissegundos (testado na placa, gera aprox 200 ms de delay)
.equ TICKS, (FREQUENCY / 1000) * DELAY_MS # Ticks para 200ms

.equ TICKS2, (FREQUENCY / 5)	# Ticks para 200ms

# Área de interrupções
.org    0x20
RTI:
    rdctl   et,     ipending
    beq     et,     r0,     OTHER_EXCEPTIONS
    subi    ea,     ea,     4

    # Tratamento

 	# Confere se a interrupção é do timer
  	andi	r22,	et,	0b1
	beq		r22,	r0,	OTHER_INTERRUPTS	# mudar para lidar com outros tipos de interrupção
	call	ANIMALEDS_INTERRUPT
 	br		END_HANDLER		# avaliar se os dados estão sendo devidamente recuperados
 
    # Fim tratamento

    andi    r22,    et,     2
    beq     r22,    r0,     OTHER_INTERRUPTS
    # call  EXT_IRQ1
OTHER_INTERRUPTS:
    br      END_HANDLER
OTHER_EXCEPTIONS:

END_HANDLER:
    eret


.org    0x100
EXT_IRQ1:
    ret


.org    0x500
.global ANIMALEDS

/*

    Inicia a animação, ou a encerra

    Para iniciar:
        Configura o temporizador
    
    Para encerrar:
        Muda a configuração do temporizador para que CONT=0
    
*/
ANIMALEDS:

	# Configurando o temporizador
 	movia	r16,	TIMER
	movia	r17,	TICKS2	# 1/5 segundos
 	stwio	r17,	8(r16)	#	0x10002008 - valor baixo
  	srli	r17,	r17,	16
	stwio	r17,	12(r16)	#	0x1000200C - valor alto

 	# Iniciando timer e permitindo suas interrupções
  	movi	r17,	0b0111	#	START=1, CONT=1, ITO=1
   	sthio	r17,	4(r16)

 	# Habilitando interrupções
  	addi	r17,	r0,	1	#	máscara de interrupção para intervalo do temporizador
   	wrctl	ienable,	r17
    movi    r17,    1
	wrctl	status,		r17

    br end

/*

    A cada interrupção, itera:
        Adquire fila de leds vermelhos
        Adquire valor do switch
        Rotaciona fila de leds com base no valor do switch


    movia r17, RED_LEDS			    # Inicializando LEDs
    ldwio r20, 0(r17)               # Lê o estado dos leds

    movia r16, SWITCHES			    # Inicializando Switches
    ldwio r18, 0(r16)               # Lê o estado dos switches
    andi r19, r18, 0x1 			    # Testa o estado do Switch SW0
    beq r19, r0, move_left          # Se sw0 estiver abaixado, move para a esquerda    
    br move_right                   # Se sw0 estiver levantado, move para a direita

    linhas marcadas com ### são as que diferem entre as rotinas
    move_left:
        10001010    <   00010100    ###
        10000000            |       ###
        --------            |
    ...010000000            |
        >>>>>>>             |       ###
    ...000000001            |
        00010100        <---*
        --------
        00010101

    move_right:
        10001010    >   01000101    ###
        00000001            |       ###
        --------            |
    ...000000000            |
         <<<<<<<            |       ###
    ...000000000            |
        01000101        <---*
        --------
        01000101

    Parametro 1 (r4):
        se 0, iniciar animação
        senão, parar animação
    

    OBS:    é necessário salvar os registradores no início da subrotina
            e recuperá-los ao final

 */
ANIMALEDS_INTERRUPT:

    # Salvar registradores
    subi    sp, sp, 32  #   reserva espaço
    stw     ra, 0(sp)
    stw     fp, 4(sp)
    stw     r16,    8(sp)
    stw     r17,    12(sp)
    stw     r18,    16(sp)
    stw     r19,    20(sp)
    stw     r20,    24(sp)
    stw     r21,    28(sp)


    # Reset no Status (TO) do temporizador
    movia	r16,	TIMER
    addi    r17,    r0, 1
 	stwio	r17,	0(r16)	#	0x10002000 - valor baixo

    bne r4, r0, end                 # Representa implementação em memória caso receba sinal de parada

    movia r17, RED_LEDS			    # Inicializando LEDs
    ldwio r20, 0(r17)               # Lê o estado dos leds

    movia r16, SWITCHES			    # Inicializando Switches
    ldwio r18, 0(r16)               # Lê o estado dos switches
    andi r19, r18, 0x1 			    # Testa o estado do Switch SW0
    beq r19, r0, move_left          # Se sw0 estiver abaixado, move para a esquerda    
    br move_right                   # Se sw0 estiver levantado, move para a direita


move_left:
    movi    r21,    0x20000         #   Máscara: 18º LED HIGH, resto LOW
    and     r16,    r20,    r21     #   and de estado dos leds com a máscara

    srli    r16,    r16,    17      #   Move total_de_LEDs - 1 para a direita

    slli    r20,    r20,    1       #   Shift left 1 no estado dos leds

    or      r20,    r20,    r16     #   Assimila resultado da rotação

    stwio   r20,    0(r17)          #   Atualiza LEDs

    br      END_ANIMALEDS_INTERRUPT


move_right:
    movi    r21,    0x1             #   Máscara: 1º LED HIGH, resto LOW
    and     r16,    r20,    r21     #   and de estado dos leds com a máscara

    slli    r16,    r16,    17      #   Move total_de_LEDs - 1 para a esquerda

    srli    r20,    r20,    1       #   Shift left 1 no estado dos leds

    or      r20,    r20,    r16     #   Assimila resultado da rotação

    stwio   r20,    0(r17)          #   Atualiza LEDs


END_ANIMALEDS_INTERRUPT:

    # Recuperar registradores
    ldw     ra, 0(sp)
    ldw     fp, 4(sp)
    ldw     r16,    8(sp)
    ldw     r17,    12(sp)
    ldw     r18,    16(sp)
    ldw     r19,    20(sp)
    ldw     r20,    24(sp)
    ldw     r21,    28(sp)

    addi    sp, sp, 32  # libera espaço

end:
    ret                             # Retorna da chamada
