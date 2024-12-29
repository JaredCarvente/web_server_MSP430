;*******************************************************************************
 .cdecls    c,list,  "msp430.h"

;-------------------------------------------------------------------------------
;           Variables Setup
;-------------------------------------------------------------------------------

            .data
MIDRAM      .equ    0x240   
X           .equ    R4
Y           .equ    R5
J           .equ    R6
RX          .equ    UCA0RXBUF
TX          .equ    UCA0TXBUF
FRX         .equ    UCA0RXIFG
FTX         .equ    UCA0TXIFG
NUM_OUTPUT  .equ    R7
OK_FLAG     .equ    R11
CHANNEL     .equ    R12
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

;------------------------------------------------------------------------------
;           BIOS Setup
;------------------------------------------------------------------------------

            .text
RESET       MOV     #MIDRAM,SP              
StopWDT     MOV     #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
            MOV.B   &CALBC1_1MHZ,&BCSCTL1
            MOV.B   &CALDCO_1MHZ,&DCOCTL

P1BIOS      MOV.B   #BIT1+BIT2,&P1SEL
            MOV.B   #BIT1+BIT2,&P1SEL2
            MOV.B   #0xFD,P1DIR             ;p1.1 is an input RX
            CLR.B   &P1IFG
            CLR.B   &P1OUT 

P2BIOS      CLR.B   &P2SEL
            CLR.B   &P2SEL2
            MOV.B   #0XFF,&P2DIR
            CLR.B   &P2OUT

UARTBIOS    BIS.B   #UCSWRST,&UCA0CTL1 
            BIS.B   #UCSSEL_2,&UCA0CTL1     ; Secondary clock
            CLR.B   &UCA0CTL0               ; 8 bits,no parity, 1 stop bit
            MOV.B   #8,&UCA0BR0             ; BAUD 1MHz 115200 
            CLR.B   &UCA0BR1
            MOV.B   #UCBRS_6,&UCA0MCTL
            BIC.B   #UCSWRST,&UCA0CTL1      ; Turn on UART
            MOV.B   #UCA0RXIE,&IE2          ; Enable UART reception interrupts

; SI PONGO LOS DATOS DE CONFIFG DE WIFI AQUI, LOS DATOS SE DISTORSIONAN COMPLETAMENTE
;------------------------------------------------------------------------------
;           Transmission of WIFI Connection Commands to ESP32
;------------------------------------------------------------------------------
              
            CALL    #DELAY_IN

            MOV     #WIFI_OP_MODE,X
            MOV     #FIN1,Y
            CALL    #DISPLAY
            CALL    #DELAY                  

            MOV     #MULTI_CONN_MODE,X
            MOV     #FIN2,Y
            CALL    #DISPLAY
            CALL    #DELAY
          
            MOV     #TCP_PORT_EN,X
            MOV     #FIN3,Y
            CALL    #DISPLAY
            CALL    #DELAY
            
            MOV     #GIE,SR 

            MOV.B   #0,OK_FLAG          ;WIFI Connection Test Algorithm
COMM_4      MOV     #WIFI_CONN,X
            MOV     #FIN4,Y
            CALL    #DISPLAY
            CALL    #DELAY
ST_CHECK4   CMP.B   #1,OK_FLAG          ;Repeat the process until WIFI is connected
            JNE     COMM_4                

            MOV.B   #0,OK_FLAG
            MOV     #CONN_CONFIRM,X
            MOV     #FIN5,Y
            CALL    #DISPLAY
            CALL    #DELAY
            BIS.B   #BIT2+BIT3,&P2OUT
            CALL    #T1S
            BIC.B   #BIT2+BIT3,&P2OUT
            CALL    #T1S
            
            BIS     #CPUOFF,SR
            NOP
;------------------------------------------------------------------------------
;           Transmission of WIFI Connection Commands to ESP32
;------------------------------------------------------------------------------

USCI0RX_ISR
CONN_ST     CMP.B   #'G',&RX             ;Confirmation of successful connection
            JNE     SUCCESS
            BIC.B   #FRX,&IFG2
LPG1        BIT.B   #FRX,&IFG2
            JZ      LPG1
            CMP.B   #'O',&RX
            JNE     SUCCESS
            BIC.B   #FRX,&IFG2
LPH1        BIT.B   #FRX,&IFG2
            JZ      LPH1
            CMP.B   #'T',&RX
            JNE     SUCCESS
            BIC.B   #FRX,&IFG2
            MOV     #GOT_RCV,X
            MOV     #FIN6,Y
            CALL    #DISPLAY
            MOV.B   #1,OK_FLAG
            RETI

SUCCESS     CMP.B   #'O',&RX
            JNE     C_ERROR
            BIC.B   #FRX,&IFG2
LPF         BIT.B   #FRX,&IFG2
            JZ      LPF
            CMP.B   #'K',&RX
            JNE     C_ERROR
            BIC.B   #FRX,&IFG2
            MOV     #OK_RCV,X
            MOV     #FIN8,Y
            CALL    #DISPLAY
            MOV.B   #1,OK_FLAG
            RETI

C_ERROR     CMP.B   #'F',&RX
            JNE     CL_REQUEST
            BIC.B   #FRX,&IFG2
LPG         BIT.B   #FRX,&IFG2
            JZ      LPG
            CMP.B   #'A',&RX
            JNE     CL_REQUEST
            BIC.B   #FRX,&IFG2
LPH         BIT.B   #FRX,&IFG2
            JZ      LPH
            CMP.B   #'I',&RX
            JNE     CL_REQUEST
            BIC.B   #FRX,&IFG2
LPJ         BIT.B   #FRX,&IFG2
            JZ      LPJ
            CMP.B   #'L',&RX
            JNE     CL_REQUEST
            BIC.B   #FRX,&IFG2
            MOV     #FAIL_RCV,X
            MOV     #FIN7,Y
            CALL    #DISPLAY 
            MOV.B   #0,OK_FLAG
            RETI

CL_REQUEST  MOV.B    &RX,&TX     
            CMP.B    #'+',&RX
            JNE      UNKNOWN
            BIC.B    #FRX,&IFG2
LKK         BIT.B    #FRX,&IFG2
            JZ       LKK
            MOV.B    &RX,&TX 
            CMP.B    #'I',&RX
            JNE      UNKNOWN
            BIC.B    #FRX,&IFG2
LKY         BIT.B    #FRX,&IFG2
            JZ       LKY 
            MOV.B    &RX,&TX            
            CMP.B    #'P',&RX
            JNE      UNKNOWN
            BIC.B    #FRX,&IFG2
LKH         BIT.B    #FRX,&IFG2
            JZ       LKH
            MOV.B    &RX,&TX 
            CMP.B    #'D',&RX
            JNE      UNKNOWN
            BIC.B    #FRX,&IFG2
LKJ         BIT.B    #FRX,&IFG2
            JZ       LKJ
            MOV.B    &RX,&TX  
            CMP.B    #',',&RX
            JNE      UNKNOWN
            BIC.B    #FRX,&IFG2
LKF         BIT.B    #FRX,&IFG2
            JZ       LKF
            MOV.B    &RX,CHANNEL
            MOV.B    CHANNEL,&TX
            BIC.B    #FRX,&IFG2
BODY        BIT.B    #FRX,&IFG2             ;Identify the request body
            JZ       BODY
            CMP.B    #'$',&RX
            JNE      BODY
            BIC.B    #FRX,&IFG2     ;LA BANDERA NO SE BORRA EN AUTOMATICO UNA VEZ LEIDO EL CARACTER?
BOD_NUM     BIT.B    #FRX,&IFG2             ;Identify the output number to be activated
            JZ       BOD_NUM
            MOV.B    &RX,NUM_OUTPUT                 
            MOV.B    NUM_OUTPUT,&TX
            BIC.B    #FRX,&IFG2
            CALL     #ACT_OUTPUT            ;Activate the requested output
            RETI
UNKNOWN     RETI
            ;MOV     #UNKNOWN_LABEL,X
            ;MOV     #FIN9,Y
            ;CALL    #DISPLAY 
;-----------------------------------------------------------------------------------
;           Definition of operational functions (display,outputs control,etc.)
;-----------------------------------------------------------------------------------
DISPLAY	    MOV.B   @X+,&TX              ;Display message  
TX0A        BIT.B   #FTX,&IFG2     
            JZ      TX0A                            
            CMP     Y,X                    
            JNE     DISPLAY                   
            BIC.B   #FRX,&IFG2
            RET

ACT_OUTPUT                              ;Outputs control
ONE         CMP.B   #'1',NUM_OUTPUT
            JNE     TWO
            BIS.B   #BIT3,&P2OUT
            ;BIS.B   #BIT0,&P1OUT
            CALL    #IPSEND
            CALL    #T1S
            CALL    #IPCLOSE
            RET

TWO         CMP.B   #'2',NUM_OUTPUT
            JNE     THREE
            BIC.B   #BIT3,&P2OUT
            ;BIC.B   #BIT0,&P1OUT
            CALL    #IPSEND
            CALL    #T1S
            CALL    #IPCLOSE
            RET
THREE       CMP.B   #'3',NUM_OUTPUT
            JNE     FOUR
            BIS.B   #BIT2,&P2OUT
            ;BIS.B   #BIT6,&P1OUT
            CALL    #IPSEND
            CALL    #T1S
            CALL    #IPCLOSE
            CALL    #T1S
            RET
FOUR        CMP.B   #'4',NUM_OUTPUT
            JNE     EIGHT
            BIC.B   #BIT2,&P2OUT
            ;BIC.B   #BIT6,&P2OUT
            CALL    #IPSEND
            CALL    #T1S
            CALL    #IPCLOSE
            CALL    #T1S
            RET
EIGHT       CMP.B   #'8',NUM_OUTPUT
            JNE     NINE
            BIS.B   #BIT3,&P2OUT
            BIS.B   #BIT2,&P2OUT
            ;BIS.B   #BIT0,&P1OUT
            ;BIS.B   #BIT6,&P1OUT
            CALL    #IPSEND
            CALL    #T1S
            CALL    #IPCLOSE
            CALL    #T1S
            RET
NINE        CMP.B   #'9',NUM_OUTPUT
            JNE     INVALID_NUM
            BIC.B   #BIT3,&P2OUT
            BIC.B   #BIT2,&P2OUT
            ;BIC.B   #BIT0,&P1OUT
            ;BIC.B   #BIT6,&P1OUT
            CALL    #IPSEND
            CALL    #T1S
            CALL    #IPCLOSE
            CALL    #T1S
            RET
INVALID_NUM RET

IPSEND      MOV     #RES_COMM,X         ;Server response
            MOV     #FIN10,Y
            CALL    #DISPLAY
            MOV     CHANNEL,&TX
CH_SND      BIT.B   #FTX,&IFG2
            JZ      CH_SND
            MOV     #NUM_BYTES,X
            MOV     #FIN11,Y
            CALL    #DISPLAY
            CALL    #T1S
SEL_HTML    CMP.B   #'1',NUM_OUTPUT
            JNE     HTML_L1_D
            MOV     #TL1A,X
            MOV     #FTL1A,Y
            CALL    #DISPLAY
HTML_L1_D   CMP.B   #'2',NUM_OUTPUT
            JNE     HTML_L2_A
            MOV     #TL1D,X
            MOV     #FTL1D,Y
            CALL    #DISPLAY
HTML_L2_A   CMP.B   #'3',NUM_OUTPUT
            JNE     HTML_L2_D
            MOV     #TL2A,X
            MOV     #FTL2A,Y
            CALL    #DISPLAY
HTML_L2_D   CMP.B   #'4',NUM_OUTPUT
            JNE     HTML_L_A
            MOV     #TL2D,X
            MOV     #FTL2D,Y
            CALL    #DISPLAY
HTML_L_A    CMP.B   #'8',NUM_OUTPUT
            JNE     HTML_L_D
            MOV     #TLA,X
            MOV     #FTLA,Y
            CALL    #DISPLAY
HTML_L_D    CMP.B   #'9',NUM_OUTPUT
            JNE     INV_HTML
            MOV     #TLD,X
            MOV     #FTLD,Y
            CALL    #DISPLAY
INV_HTML    RET
            RET 

IPCLOSE     MOV     #CLOSE_COMM,X         ;Server response
            MOV     #FIN12,Y
            CALL    #DISPLAY
            MOV     CHANNEL,&TX
CH_SND1     BIT.B   #FTX,&IFG2
            JZ      CH_SND1
            MOV     #END_CLOSE,X
            MOV     #FIN13,Y
            CALL    #DISPLAY
            RET

;-----------------------------------------------------------------------------------
;           Definition of time functions
;-----------------------------------------------------------------------------------
DELAY_IN    MOV     #5,R10
AUX3        CALL    #T1S
            DEC     R10
            JNZ     AUX3
            RET

DELAY       MOV     #4,R10
AUX2        CALL    #T1S
            DEC     R10
            JNZ     AUX2
            RET

T1S         MOV     #1000,R9
AUX1        CALL    #T1MS   ;1ms
            DEC     R9      ;1us
            JNZ     AUX1    ;2us 1.003ms per iteration
            RET

T1MS        MOV     #250,R8; 1us
AUX         NOP             ;1us
            DEC     R8      ;1us
            JNZ     AUX     ;2us
            RET             ;1us

;------------------------------------------------------------------------------
;           Setup for WIFI Connection Commands using ESP32 WIFI module 
;------------------------------------------------------------------------------

WIFI_OP_MODE        .string "AT+CWMODE=3",0x0D,0x0A     ;WIFI module works as a client and access point simultaneously
FIN1                .byte 0x00
MULTI_CONN_MODE     .string "AT+CIPMUX=1",0x0D,0x0A     ;WIFI module allows multiple connections
FIN2                .byte 0x00
TCP_PORT_EN         .string "AT+CIPSERVER=1,90",0x0D,0x0A   ;Set a TCP connection on port 90
FIN3                .byte 0x00
WIFI_CONN           .string "AT+CWJAP=",34,"Micros",34,",",34,"9876543210",34,0x0D,0x0A
FIN4                .byte 0x00
CONN_CONFIRM        .string "AT+CIFSR",0x0D,0x0A        ;Check if WIFI connection was successful if local IP is given
FIN5                .byte 0x00
RES_COMM            .string "AT+CIPSEND="
FIN10               .byte 0x00
NUM_BYTES           .byte ",178",0x0D,0x0A
FIN11               .byte 0x00
CLOSE_COMM          .string "AT+CIPCLOSE="
FIN12               .byte 0x00
END_CLOSE           .string 0DH,0AH
FIN13               .byte 0x00

;------------------------------------------------------------------------------
;           Possible module responses 
;------------------------------------------------------------------------------

GOT_RCV             .string "GOT RECEIVED",0x0D,0x0A     ;WIFI module works as a client and access point simultaneously
FIN6                .byte 0x00
FAIL_RCV            .string "FAIL, TRY AGAIN",0x0D,0x0A     ;WIFI module allows multiple connections
FIN7                .byte 0x00
OK_RCV              .string "OK,SUCCESSFUL",0x0D,0x0A   ;Set a TCP connection on port 90
FIN8                .byte 0x00
UNKNOWN_LABEL       .string "INVALID RESPONSE",0x0D,0x0A
FIN9                .byte 0x00

;------------------------------------------------------------------------------
;           HTML pages depending on the enabled output, server response
;------------------------------------------------------------------------------

TL1A    .string "HTTP/1.1 200 OK\r\n\r\n"                             ;19
        .string "Content-Type: text/html\r\n\r\n"                     ;27
        .string "<body style =",34,"background-color:blue;",34,">"    ;39
        .string "</body>"                                             ;07
        .string "<h1 style=",34,"color:white;"                        ;24
        .string "font-size: 48;",34,">"                                   ;15
        .string "<!DOCTYPE HTML>\r\n<html>\r\n\r\n, ,L1 1",0AH ;47/
FTL1A   .byte 0x00                                      ;/189/

TL1D    .string "HTTP/1.1 200 OK\r\n\r\n"                             ;19
        .string "Content-Type: text/html\r\n\r\n"                     ;27
        .string "<body style =",34,"background-color:blue;",34,">"    ;39
        .string "</body>"                                             ;07
        .string "<h1 style=",34,"color:white;"                        ;24
        .string "font-size: 48;",34                                   ;15
        .string "<!DOCTYPE HTML>\r\n<html>\r\n\r\n, ,L1 0",0AH ;47/
FTL1D   .byte 0x00                                      ;/189

TL2A    .string "HTTP/1.1 200 OK\r\n\r\n"                             ;19
        .string "Content-Type: text/html\r\n\r\n"                     ;27
        .string "<body style =",34,"background-color:blue;",34,">"    ;39
        .string "</body>"                                             ;07
        .string "<h1 style=",34,"color:white;"                        ;24
        .string "font-size: 48;",34,">"                                   ;15
        .string "<!DOCTYPE HTML>\r\n<html>\r\n\r\n, ,L2 1",0AH ;47/
FTL2A   .byte 0x00                                      ;/189/

TL2D    .string "HTTP/1.1 200 OK\r\n\r\n"                             ;19
        .string "Content-Type: text/html\r\n\r\n"                     ;27
        .string "<body style =",34,"background-color:blue;",34,">"    ;39
        .string "</body>"                                             ;07
        .string "<h1 style=",34,"color:white;"                        ;24
        .string "font-size: 48;",34                                   ;15
        .string "<!DOCTYPE HTML>\r\n<html>\r\n\r\n, ,L2 0",0AH ;47/
FTL2D   .byte 0x00 

TLA     .string "HTTP/1.1 200 OK\r\n\r\n"                             ;19
        .string "Content-Type: text/html\r\n\r\n"                     ;27
        .string "<body style =",34,"background-color:blue;",34,">"    ;39
        .string "</body>"                                             ;07
        .string "<h1 style=",34,"color:white;"                        ;24
        .string "font-size: 48;",34,">"                                   ;15
        .string "<!DOCTYPE HTML>\r\n<html>\r\n\r\n, ,LA 1",0AH ;47/
FTLA    .byte 0x00                                      ;/189/

TLD     .string "HTTP/1.1 200 OK\r\n\r\n"                             ;19
        .string "Content-Type: text/html\r\n\r\n"                     ;27
        .string "<body style =",34,"background-color:blue;",34,">"    ;39
        .string "</body>"                                             ;07
        .string "<h1 style=",34,"color:white;"                        ;24
        .string "font-size: 48;",34                                   ;15
        .string "<!DOCTYPE HTML>\r\n<html>\r\n\r\n, ,LA 0",0AH ;47/
FTLD    .byte 0x00 

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET               ;
            .sect   ".int07"
            .short  USCI0RX_ISR 
            .end

            



