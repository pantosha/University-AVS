    .486                       ; create 32 bit code
    .model flat, stdcall       ; 32 bit memory model
    option casemap :none       ; case sensitive
 
    __UNICODE__ equ 1
    
    E_RANGE      equ  1
    E_OPNOTSUPP  equ  2
    E_SYNTAX     equ  3
    E_NOTQUAD    equ  4
    E_BADDIS     equ  5
 
    include \masm32\include\windows.inc
    include \masm32\include\masm32.inc
    include \masm32\include\kernel32.inc
    include \masm32\include\shell32.inc
    include \masm32\include\msvcrt.inc
    include \masm32\macros\macros.asm

    includelib \masm32\lib\masm32.lib
    includelib \masm32\lib\kernel32.lib
    includelib \masm32\lib\shell32.lib
    includelib \masm32\lib\msvcrt.lib

    print_error PROTO
    
; ariphmetic operations
    make_table PROTO
    
    function_Y PROTO :REAL8
    function_S PROTO :REAL8

    .data
    errno       dd   0
    two         dd   2
    four        dd   4
    h           REAL8   1.0
    e           REAL8   0.00001
    t           REAL8   1000.0
    
    .data?
    x1          REAL8   ?
    x2          REAL8   ?
    
    tempYx      REAL8   ?
    tempSx      REAL8   ?
   
    .code

start:
 
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

main proc
    
    print "Hello, Lab 7 is here."
    print chr$(13,10,13,10)
    print "Please enter x1: "
    invoke crt_wscanf, cfm$("%8lf"), offset x1
    cmp EAX, 1
    jne input_error
    
    print "Please enter x2: "
    invoke crt_wscanf, cfm$("%8lf"), offset x2
    cmp EAX, 1
    jne input_error
    
    finit
    fld x1
    fld x2
    fcompp
    fstsw AX
    sahf
    jb input_error
    
    print "Please enter h: "
    invoke crt_wscanf, cfm$("%8lf"), offset h
    cmp EAX, 1
    jne input_error
    
    print "Please enter e: "
    invoke crt_wscanf, cfm$("%8lf"), offset e
    cmp EAX, 1
    jne input_error
    
    invoke make_table
    
    jmp close
    
  input_error:
    mov errno, E_RANGE
    invoke print_error
  close:
    invoke ExitProcess,0
    
    ret

main endp


print_error proc

    .IF errno == E_RANGE
        print "Error: out of range."
    .ENDIF
	ret
	
print_error endp

make_table proc
    
    LOCAL x: REAL8
    LOCAL n: DWORD
    
    clc
    print "================================================================================"
    print "|       x       |      Y(x)      |      S(x)      |      n      |       e      |"
    print "================================================================================"
    
    fld x1
    fstp x
  @@:
    invoke function_Y, x
    invoke function_S, x
    mov n, EAX     
    printf("|%15lf|%16lf|%16lf|%13d|%14lf|", x, tempYx, tempSx, n, e)
    finit
    fld x
    fadd h
    fcom x2
    fstsw AX
    sahf
    ja close
    fstp x
    jmp @B
  close:
    print "================================================================================"
	ret
make_table endp

function_Y proc x:REAL8
 
; Y(x) = (1 - (x^2)/2)*cos(x) - x/2*sin(x)
    finit
; (1 - (x^2)/2)*cos(x)
    fld1
    fld x
    fmul x
    fidiv two
    fsub
    fld x
    fcos
    fmul
; x/2*sin(x)
    fld x
    fsin
    fmul x
    fidiv two
; (1 - (x^2)/2)*cos(x) - x/2*sin(x)
    fsub
    fstp tempYx 
  close:
	ret
	
function_Y endp

function_S proc x:REAL8
 
; S_p(x) = (-1)^k * (2k^2 + 1)/((2k)!) * x^(2k)    
    LOCAL k: DWORD
    mov k, 0
    invoke function_Y, x
    
    finit
    fld x
    fmul ST, ST ; x*x
    fld1
    fld1
  cycle:
    fld ST(1)
    fld tempYx
    fsub
    fabs
    fcomp e
    fstsw AX
    sahf
    jb close
    
    fchs ; ST(0): N = -x^(2k)/(2k)! 
  @@:
    fmul ST, ST(2) ; N = N*x^2
    inc k
    fidiv k
    inc k
    fidiv k ; N = N*x^2/(k+1)/(k+2)
    
    fld1
    fild k
    fmul ST, ST
    fidiv two
    fadd ; ST(0): 2k^2 + 1
    fmul ST, ST(1) ; p = N * (2k^2 + 1)
    fadd ST(2), ST ; S = S + p
    ffree ST
    fincstp
    jmp cycle
  close:
    fxch st(1)
    fstp tempSx 
    mov EAX, k
    shr EAX, 1
    ret
    
function_S endp 

end start