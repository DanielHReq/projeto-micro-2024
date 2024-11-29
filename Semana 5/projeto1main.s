###
# Registradores utilizados e funcionalidades

# main é o caller
# aqui deve-se usar os registradores r8-16


# r8 - ponteiro para a jtag uart
# r9 - ponteiro para os leds vermelhos
# r10 - aux / teste do caractere 0
# r11 - aux / teste do caractere 1
# r12 - aux / teste do caractere 2
# r13 - leitura de caracteres
# r14 - armazena o primeiro dígito lido
# r15 - armazena o segundo dígito lido
# r16 - aux / soma dos dig n
# r17 - aux / dig 1
# r18 - aux / dig 2

###

.global _start

# Endereço base da JTAG UART e dos LEDs
.equ JTAG_UART_BASE, 0x10001000

_start:
    # Inicializa o ponteiro para o endereço da JTAG UART
    movia   r8, JTAG_UART_BASE

    movi    r10, 0x30      # Caractere '0'
    movi    r11, 0x31      # Caractere '1'
    movi    r12, 0x32      # Caractere '2'
  
loop:
    # Lê o primeiro caractere (comando principal)
    ldwio   r13, 0(r8)          # Lê o primeiro caractere (comando)

    andi    r16, r13, 0x8000
    beq     r16, r0, loop

    andi    r13, r13, 0xFF        # Máscara para manter os 8 bits


    mov     r14, r13              # Armazena o primeiro dígito do comando em r14
loop2:
    # Lê o segundo caractere (comando específico)
    ldwio   r13, 0(r8)          # Lê o segundo caractere (comando específico)
    
    andi    r16, r13, 0x8000
    beq     r16, r0, loop2


    andi    r13, r13, 0xFF
    mov     r15, r13              # Armazena o segundo dígito do comando em r15

    # Armazena o segundo valor para determinar a ação
    subi r4, r15, 0x30

    # Verifica o valor do primeiro caractere (seção)
    beq     r14, r10, secao_0      # Se r14 == 0, redireciona para a seção 0
    beq     r14, r11, secao_1      # Se r14 == 1, redireciona para a seção 1
    beq     r14, r12, secao_2      # Se r14 == 2, redireciona para a seção 2

    # Se o comando não for reconhecido, continua aguardando
    br loop

# Seção 1: Comandos de controle de LEDs (Entrada 0)

secao_0:
    # Verifica o segundo caractere e redireciona para a função correta
    
    beq     r15, r10, comando_0X   # Se r15 == 0, acende o LED
    beq     r15, r11, comando_0X   # Se r15 == 1, apaga o LED

    br loop                       # Se r15 não for 0 ou 1, aguarda novamente

comando_0X:  # Se o comando for '00', acende o LED
    call MUDALEDS

    br loop

# Seção 2: Comandos de animação (Entrada 1)

secao_1:
    beq     r15, r10, comando_1X   # Se r15 == 0, inicia a animação
    beq     r15, r11, comando_1X   # Se r15 == 1, para a animação
    
    br loop                       # Se r15 não for 0 ou 1, aguarda novamente

comando_1X:  # Se o comando for '10', acende o LED
    call ANIMALEDS

    br loop

# Seção 3: Comandos de cronômetro (Entrada 2)
secao_2:
    beq     r15, r10, comando_2X   # Se r15 == 0, inicia o cronometro
    beq     r15, r11, comando_2X   # Se r15 == 1, encerra o cronometro
    
    br loop                       # Se r15 não for 0 ou 1, aguarda novamente

comando_2X:  # Se o comando for '20', acende o LED

    # call cronometro

    br loop