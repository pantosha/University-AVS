    .486                       ; create 32 bit code
    .model flat, stdcall       ; 32 bit memory model
    option casemap :none       ; case sensitive
 
    __UNICODE__ equ 1
    
    E_RANGE      equ  1
    E_OPNOTSUPP  equ  2
    E_SYNTAX     equ  3
 
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

    apply_operation PROTO :REAL8, :REAL8
    print_help PROTO
    print_error PROTO
    
; ariphmetic operations

    addition PROTO :REAL8, :REAL8
    subtraction PROTO :REAL8, :REAL8
    multiply PROTO :REAL8, :REAL8
    division PROTO :REAL8, :REAL8

    .data
    errno       dd   0
    operation   dd   0
    result      REAL8   ?
    
    .code

start:
 
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

main proc

    LOCAL args: LPWSTR
    LOCAL nArgs: DWORD
    LOCAL ArgList: DWORD
    LOCAL x: REAL8
    LOCAL y: REAL8
    
    invoke GetCommandLineW
    mov args, EAX
    invoke CommandLineToArgvW, args, addr nArgs
    mov ArgList, EAX
    .IF ArgList == 0
        print "Error: can't get command line arguments."
        jmp close
    .ENDIF
    cmp nArgs, 4
    jne command_line_error 
    
    mov ESI, ArgList

    add ESI, 4
    invoke crt_swscanf, dword ptr [ESI], cfm$("%8lf"), ADDR x
    cmp EAX, 1    
    jne command_line_error
    
    add ESI, 4
    invoke crt_swscanf, dword ptr [ESI], cfm$("%c"), ADDR operation
    cmp EAX, 1
    jne command_line_error
    
    add ESI, 4
    invoke crt_swscanf, dword ptr [ESI], cfm$("%8lf"), ADDR y
    cmp EAX, 1
    jne command_line_error
    
    invoke apply_operation, x, y

    .IF errno != 0
        invoke print_error
    .ELSEIF
        printf("%lf %c %lf = %lf", x, operation, y, result)
    .ENDIF
    
    jmp close
    
  command_line_error:
    mov errno, E_SYNTAX
    invoke print_error
  close:
; free memory
    invoke LocalFree, ArgList
    invoke ExitProcess,0
    
    ret

main endp


print_help proc

    print "AVS Labs, 2013"
    print chr$(13,10,13,10)
    print "SYNTAX: avs-labs [first number] [operation] [second number]"
    print chr$(13,10)
    print "        first number : first number"
    print chr$(13,10)
    print "        operation    : operation that be applied to expression"
    print chr$(13,10)
    print "        second number: another number."
    print chr$(13,10,13,10)
    print "        Output is to STDOUT. It can redirected to a file."
    print chr$(13,10)
	ret
	
print_help endp


print_error proc

    .IF errno == E_RANGE
        print "Error: out of range."
    .ELSEIF errno == E_OPNOTSUPP
        print "Error: operation not supported."
    .ELSEIF errno == E_SYNTAX
        invoke print_help
    .ENDIF
	ret
	
print_error endp

apply_operation proc x:REAL8, y:REAL8 
    
    .IF operation == "+"
        invoke addition, x, y
    .ELSEIF operation == "-"
        invoke subtraction, x, y
    .ELSEIF operation == "*"
        invoke multiply, x, y
    .ELSEIF operation == "/"
        invoke division, x, y
    .ELSEIF
        mov errno, E_OPNOTSUPP
    .ENDIF
	ret
	
apply_operation endp

addition proc x:REAL8,y:REAL8
    
    fld x
    fld y
    fadd
    fstp result
    ret
    
addition endp

subtraction proc x:REAL8,y:REAL8
    
    fld x
    fld y
    fsub
    fstp result
    ret
    
subtraction endp

multiply proc x:REAL8,y:REAL8
    
	fld x
    fld y
    fmul
    fstp result
    ret
    
multiply endp

division proc x:REAL8,y:REAL8
    
    fld x
    fld y
    fdiv
    fstp result
    ret
   
division endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

end start