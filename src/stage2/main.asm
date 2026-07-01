org 500h
bits 16

main:
    ; set up stack and segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 7C00h

    ; print 2 to the screen signifying that stage2 has been loaded
    mov ah, 0x0e
    mov al, '2'
    int 10h

    jmp $
    