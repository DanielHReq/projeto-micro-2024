# Mudança no estado de um LED vermelho
# Funcionando, isolado e melhorado - Semana 4

/* 
Registradores utilizados e funcionalidades:

r16 - ponteiro para a jtag uart
r17 - ponteiro para os leds vermelhos
r18 - leitura da jtag uart / aux para testes / valor principal dos leds
r19 - armazena primeira leitura de r18 / aux para testes / indice de deslocamento
r20 - armazena segunda leitura de r18

*/

# Endereços base da JTAG UART e dos LEDs
.equ JTAG_UART_BASE, 0x10001000
.equ RED_LEDS, 0x10000000  # Endereço para controlar os LEDs (18 LEDs)

.global MUDALEDS

MUDALEDS:
    # Inicializa o ponteiro para o endereço da JTAG UART
    movia   r16, JTAG_UART_BASE
    movia   r17, RED_LEDS

read1:
    # Lê o número do LED (dois caracteres seguintes)
    ldwio   r18, 0(r16)         # Lê o terceiro caractere (número do LED) em r18

    andi    r20, r18, 0x8000    # Volta se a entrada é inválida
    beq     r20, r0, read1

    andi    r18, r18, 0xFF      # Pega apenas os 8 bits necessários
    subi    r18, r18, 0x30      # Converte de ASCII para valor numérico
    mov     r19, r18            # Armazena o primeiro dígito do número do LED em r19

read2:
    ldwio   r18, 0(r16)         # Lê o quarto caractere (número do LED) em r18
    
    andi    r20, r18, 0x8000    # Volta se a entrada é inválida
    beq     r20, r0, read2

    andi    r18, r18, 0xFF      # Pega apenas os 8 bits necessários
    subi    r18, r18, 0x30      # Converte de ASCII para valor numérico
    mov     r20, r18            # Armazena o segundo dígito do número do LED em r20

    # Junta os dois dígitos para formar o número completo do LED
    slli    r18, r19, 3        # Multiplica o primeiro dígito por 10 e salva em r18
    add     r18, r18, r19
    add     r18, r18, r19
    add     r18, r18, r20       # Soma o segundo dígito para formar o número do LED (1-18)

    # Verifica se o número do LED é válido (de 1 a 18)
    # Verifica se o número do LED é menor que 1
    subi    r19, r18, 1         # Subtrai 1 de r18 e salva em r19
    blt     r19, r0, OUT_OF_RANGE       # Testa r19 e se for menor que 1 não faz nada

    # Verifica se o número do LED é maior que 18
    subi    r19, r18, 18        # Subtrai 18 de r18 e salva em r19
    bgt     r19, r0, OUT_OF_RANGE       # Testa r19 e se for maior que 18 não faz nada

    # Ajusta o número para o índice de 0 a 17 (para LEDs de 1 a 18)
    subi    r18, r18, 1         # Ajusta r18 para manter o número do LED de 0 a 17

    # Desloca o bit para a posição correta (1 a 18) em r20
    movi    r19, 1              # Carrega 1 em r19

    # Determina ação de acordo com o valor de r4
    beq     r4, r0, MUDALEDS_ACENDE

MUDALEDS_APAGA: # Se o comando for
    nor     r19, r19, r19       # Inverte r19
    rol     r19, r19, r18       # Desloca 0 para a posição do LED correspondente

    # Lê o valor atual dos LEDs
    ldwio   r18, 0(r17)         # Lê o valor atual dos LEDs (r18)

    # Apaga o LED (fazendo um bit AND com 1)
    and     r18, r18, r19       # Apaga o LED correspondente ao bit

    br end

MUDALEDS_ACENDE:
    sll     r19, r19, r18       # Desloca 1 para a posição do LED correspondente

    # Lê o valor atual dos LEDs
    ldwio   r18, 0(r17)         # Lê o valor atual dos LEDs (r18)

    # Acende o LED (fazendo um bit OR com 1)
    or      r18, r18, r19       # Acende o LED correspondente ao bit

end: 
    stwio   r18, 0(r17)         # Escreve no endereço dos LEDs (acende o LED)

    ret

OUT_OF_RANGE:
    ret
