.MODEL SMALL
.STACK 100
.DATA
ORG 200H



PORT_A EQU 00H  
PORT_B EQU 02H  
PORT_C EQU 04H
PORT_CONFIG EQU 06H
   
 ;TIMER Ports
 TPORT_C_0	EQU 	10H
 TPORT_C_1	EQU		12H
 TPORT_C_2	EQU		14H
 TPORT_CONFIG 	EQU	16H
  
 ;interrupt Ports
 IPORTS_i1	EQU		20H
 IPORTS_i2	EQU		22H
 IPORTS_o3	EQU		22H
 IPORTS_o4	EQU		20H
 
 
.code
   org 300h
   

DOWN_INT proc far
      push ax
      push ds
      
      mov ax,@data
      mov ds,ax
      
      
      call DOWN_ONE
      

      pop ds
      pop ax
      sti
      iret
      
DOWN_INT endp


UP_INT proc far
      push ax
      push ds
      
      mov ax,@data
      mov ds,ax
      
      
      call UP_ONE

      pop ds
      pop ax
      sti
      iret
      
UP_INT endp



START_INT proc far
      push ax
      push ds
      
      mov ax,@data
      mov ds,ax
      
      
      call  DOWN_ONE
      call  CHECK_ZERO_LED_ON 

      pop ds
      pop ax
      sti
      iret
      
START_INT endp

;----------------------------------------------------------------------------------------------------------------
main  proc far

    mov ax,@data
    mov ds,ax
    
;==============================================================   

    ;8255	/config
   mov dx , port_config
   mov al, 10000001b  ;init port_a as an output also port_b as an output and port_c as an input  and move
   out dx , al
   
   ;5052	/config and first initialization
   mov al, 00010111b
   mov dx, tport_config
   out dx, al
   mov al, 01h
   out tport_c_0, al
   
   
   ;8259 /config
   ;DOWN_INTERRUPT
  ;1_ 
   mov al , 00010011b	;a0 = 0 for icw1 -> d7-d5 always 0 ->  d4=1 always ->  d3  =  0  for h t-igger	-> 0 1 - > d0 = 1 enabling icw4
   mov dx ,  DOWN_INT
   out  dx , al
   ;2_ interupt numebr
   mov al ,40h		;adress of ip and  cs interupt 64 * (4) = 256 *(line :58)
   mov dx ,  iports_i2
   out dx , al
   ;3_ enabling icw4 (iret) in interupt
   mov al , 00000011b
   mov dx , iports_i2
   out dx , al
   ;4_config cdintr40 
   mov ax , 0		;accessing base of mem
   mov es , ax 
   cli
   mov ax , offset  DOWN_INT		;count down interupt
   mov es:[256] , ax	
   mov es:[258] , cs  
   sti
   
   ;UP_INTERRUPT
   ;1_  
   mov al , 00010011B
   mov dx ,  iports_i1
   out  dx , al
   ;2_ interupt numebr
   mov al ,41h		
   mov dx ,  iports_i2
   out dx , al
   ;3_ enabling icw4 (iret) in interupt
   mov al , 00000011b
   mov dx , iports_i2
   out dx , al
   ;4_config cdintr40 
   mov ax , 0		
   mov es , ax 
   cli
   mov ax , offset  UP_INT		
   mov es:[260] , ax	
   mov es:[262] , cs  
   sti
   
     

   
  ;COUNT_DOWN_INTERRUPT
  ;1_
   mov al , 00010011b	;
   mov dx ,  iports_i1
   out  dx , al
   ;2_ interupt numebr
   mov al ,42h		
   mov dx ,  iports_i2
   out dx , al
   ;3_ enabling icw4 (iret) in interupt
   mov al , 00000011b
   mov dx , iports_i2
   out dx , al   
   ;4_config cdintr40 
   mov ax , 0		;accessing base of mem
   mov es , ax 
  ; cli
   mov ax , offset  START_INT		;count down interupt
   mov es:[264] , ax	
   mov es:[266] , cs  
  ;sti
     

;========================================================================   
   
    ;initialize twi 7seg-bcd to 10
   mov dx,  port_a
   mov al, 00000001b ; port_a is the 4th lowest btis represent 1 (tens)
   out dx , al
    
   mov dx,  port_b
   mov al, 00000000b ; port_b is the 4th lowest btis represent (units) 
   mov dx,  port_b
   ;call make_delay


; a loop to run the proggram
main_loop:

   
jmp main_loop
   


      	mov ax , 4c00h
	int 21h
main endp
   
   
;-------------------------------------------------------functions---------------------------------------------------

CHECK_ZERO_LED_ON proc
      mov dx , port_a
      in al , port_a
      cmp al , 0
      je chk_b
      jmp rett
      chk_b:
      mov dx , port_b
      in al , port_b
      cmp al, 0
      je led_on
      jmp rett
      led_on:
      mov dx , port_c
      in al , port_c
      mov  al ,10001111b
      out dx ,al
      
      mov dx,  port_a
      mov al, 00000000b ; 0
      out dx , al
    
      mov dx,  port_b
      mov al, 00000000b ; 0      
      out dx,  al
      

   

 rett:
 
 ret
 CHECK_ZERO_LED_ON endp

 

DOWN_ONE proc
		
     mov dx , port_b   		 ;if port_b is 0 => port_b = 9 & port_a=port_a - 1
     in al ,port_b
     cmp al , 00000000b
     je down_cone_loop1		;if port_a eq to 0
     jmp down_cone_loop2		;decresce port_b
     
 down_cone_loop1:
 
      mov dx , port_b		;port_b = 9
      in al ,port_b  
      mov al , 00001001b   
      out dx ,al

      
      mov dx , port_a
      in al ,port_a  
      sub al , 1b   	 ;port_a=port_a -1
      out dx ,al
      jmp qwe

      
 down_cone_loop2:       ;if port_a = 0 ; means 00 so exit
   

      mov dx, port_b    ;else port_b = port_b - 1 and jump back
      in al ,port_b
      sub al , 1b
      out dx ,al
qwe:   
ret
DOWN_ONE  endp


 UP_ONE proc   	
     mov dx , port_b   	    ;if port_b is 9=> port_a= 0 
     in al ,port_b
     cmp al , 00001001b
     je up_one_loop1		;if port_a eq to 9
     jmp up_one_loop2		;increace port_b
     
 up_one_loop1:
 
      mov dx , port_b		;port_b = 0
      in al ,port_b 
      mov al , 00000000b   
      out dx ,al
      ;;call make_delay
      
      mov dx , port_a
      in al ,port_a  
      add al , 1b   	 ;port_a=port_a +1
      out dx ,al
      jmp uip   
 up_one_loop2:           ;if port_b != 9 ; 
   

      mov dx, port_b     ;else port_b = port_b  + 1 
      in al ,port_b
      add al , 1b
      out dx ,al    
 uip: 
   ret
UP_ONE  endp

COUNT_DOWN	proc
rtt:
      ;mov dx  , port_c
      ;in al , port_c
     ; cmp al , 	00001011b 	; start_down
    ;  je start_btnl
   ;   jmp rtt
   ;   start_btnl:			;if start btn is pressed
      call DOWN_ONE 
 
ret
COUNT_DOWN  endp


end main