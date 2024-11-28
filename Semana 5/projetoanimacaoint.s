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

# Constantes para temporizador
.equ FREQUENCY, 27000000          # Frequência do sistema em Hz
.equ DELAY_MS, 60                 # Atraso em milissegundos (testado na placa, gera aprox 200 ms de delay)
.equ TICKS, (FREQUENCY / 1000) * DELAY_MS # Ticks para 200ms

/*
# Área de interrupções
.org    0x20
RTI:
    rdctl   et,     ipending
    beq     et,     r0,     OTHER_EXCEPTIONS
    subi    ea,     ea,     4

    # Tratamento

    # Fim tratamento

    andi    r13,    et,     2
    beq     r13,    r0,     OTHER_INTERRUPTS
    # call  EXT_IRQ1
OTHER_INTERRUPTS:
    br      END_HANDLER
OTHER_EXCEPTIONS:

END_HANDLER:
    eret


.org    0x100
EXT_IRQ1:
    ret


.org    0x500   */
.global ANIMALEDS

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
    
 */
ANIMALEDS:
    
loop:
    bne r4, r0, end                 # Representa implementação em memória caso receba sinal de parada

    movia r17, RED_LEDS			    # Inicializando LEDs
    ldwio r20, 0(r17)               # Lê o estado dos leds

    movia r16, SWITCHES			    # Inicializando Switches
    ldwio r18, 0(r16)               # Lê o estado dos switches
    andi r19, r18, 0x1 			    # Testa o estado do Switch SW0
    beq r19, r0, move_left          # Se sw0 estiver abaixado, move para a esquerda    
    br move_right                   # Se sw0 estiver levantado, move para a direita


move_left:
    movi    r22,    0x20000         #   Máscara: 18º LED HIGH, resto LOW
    and     r16,    r20,    r22     #   and de estado dos leds com a máscara

    srli    r16,    r16,    17      #   Move total_de_LEDs - 1 para a direita

    slli    r20,    r20,    1       #   Shift left 1 no estado dos leds

    or      r20,    r20,    r16     #   Assimila resultado da rotação

    stwio   r20,    0(r17)          #   Atualiza LEDs

    br      delay


move_right:
    movi    r22,    0x1             #   Máscara: 1º LED HIGH, resto LOW
    and     r16,    r20,    r22     #   and de estado dos leds com a máscara

    slli    r16,    r16,    17      #   Move total_de_LEDs - 1 para a esquerda

    srli    r20,    r20,    1       #   Shift left 1 no estado dos leds

    or      r20,    r20,    r16     #   Assimila resultado da rotação

    stwio   r20,    0(r17)          #   Atualiza LEDs

    br      delay


# Função de atraso de 200 ms
delay:
    movia r21, TICKS              # Carrega o número de ticks
delay_loop:
    subi r21, r21, 1              # Decrementa o contador
    bne r21, r0, delay_loop       # Continua até que r1 seja zero
	
    br loop

end:
    ret                             # Retorna da chamada