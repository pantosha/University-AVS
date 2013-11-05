    .686                       ; create 32 bit code
    .mmx
    .model flat, stdcall       ; 32 bit memory model
    option casemap :none       ; case sensitive
 
    __UNICODE__ equ 1
    
    ARRAY_LENGTH equ  8 
    
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
    
; ariphmetic operations
    mmx PROTO
    print_array PROTO :DWORD

    .data
    
    array_A     db      0Fh, 19h, 42h, 0A8h, 1Dh, 99h, 01h, 00h 
    array_B     db      5Bh, 12h, 09h, 02h, 12h, 0D3h, 72h, 15h
    array_C     db      12h, 03h, 0Bh, 80h, 5Ah, 36h, 0B0h, 21h
    array_D     dw      0FFFh, 09h, 1DE0h, 0FDh, 1101h, 4321h, 8A3Ah, 091Ch  
    
    .data?
    
    array_F     dw      ARRAY_LENGTH dup (?)
    
    .code

start:
 
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

main proc
    
    invoke mmx    
    invoke print_array, ADDR array_F    

  close:
    invoke ExitProcess,0
    
    ret

main endp


print_array proc array: DWORD
    
    mov ECX, ARRAY_LENGTH
    xor EBX, EBX
    mov ESI, array
    
    @@:
    push ECX
    xor EAX, EAX
    lodsw
    printf("F[%d] = %d\n", EBX, EAX)
    inc EBX
    pop ECX
    loop @B
	
	ret
	
print_array endp


mmx proc
; F[i] = (A[i] - B[i]) + (C[i] * D[i])
; A - B
    movq MM0, qword ptr [array_A]
    movq MM1, qword ptr [array_B]
    psubsb MM0, MM1
    movq MM7, MM0
    
;convert 8 -> 16
    movq MM3, MM7 ; !
    pxor MM4, MM4 ; !
    pcmpgtb MM3, MM4 ; !
    
    punpcklbw MM0, MM3
    movq qword ptr [array_F], MM0

    movq MM0, MM7
    punpckhbw MM0, MM3
    movq qword ptr [array_F + 8], MM0

; C * D
    movq MM0, qword ptr [array_C]
    
    movq MM3, MM0 ; !
    pxor MM4, MM4 ; !
    pcmpgtb MM3, MM4 ; !
    
; low
    punpcklbw MM0, MM3
    pmullw MM0, qword ptr [array_D] 
    paddsw MM0, qword ptr [array_F]
    movq qword ptr [array_F], MM0
; high
    movq MM0, qword ptr [array_C]
    punpckhbw MM0, MM3
    pmullw MM0, qword ptr [array_D + 8]
    paddsw MM0, qword ptr [array_F + 8]
    movq qword ptr [array_F + 8], MM0
    
    emms
	ret
	
mmx endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

end start