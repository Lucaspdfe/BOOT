org 500h
bits 16

global main

main:
    ; set up stack and segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 7C00h

    mov [g_BootDrive], dl

    mov ah, 0
    mov al, 3
    int 10h                     ; set video mode to 80x25 color text

    ; welp, no fast a20 for me ): some bioses don't support it

    ; keyboard controller a20 method (most compatible method)
    cli                         ; disable interrupts
    call .a20wait
    mov al,0xAD
    out 0x64,al                 ; disable keyboard
    call .a20wait
    mov al,0xD0
    out 0x64,al                 ; read controller output port
    call .a20wait2
    in al,0x60                  ; save response byte
    push eax
    call .a20wait
    mov al,0xD1
    out 0x64,al                 ; write next byte into controller output port
    call .a20wait
    pop eax
    or al,2                     ; set controller output bit for A20 on
    out 0x60,al                 ; activate A20
    call .a20wait
    mov al,0xAE
    out 0x64,al                 ; reactivate keyboard
    call .a20wait
    sti                         ; reactivate interrupts
    jmp .a20after
.a20wait:                       ; wait until input buffer is clear
    in al,0x64
    test al,2
    jnz .a20wait
    ret  
.a20wait2:                      ; wait until response byte has arrived
    in      al,0x64
    test    al,1
    jz      .a20wait2
    ret
.a20after:
    cli                         ; disable interrupts
    lgdt [g_GDTDesc]            ; load GDT register with start address of Global Descriptor Table
    mov eax, cr0 
    or al, 1                    ; set PE (Protection Enable) bit in CR0 (Control Register 0)
    mov cr0, eax

    ; Perform far jump to selector 08h (offset into GDT, pointing at a 32bit PM code segment descriptor) 
    ; to load CS with proper PM32 descriptor)
    jmp 08h:PModeMain

[bits 32]
PModeMain:
    ; set up stack and segments
    mov ax, 10h
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 7C00h

    mov [0xB8000], 0x0F41               ; print 'A'

    jmp $

[bits 16]
g_GDT:      ; NULL descriptor
            dq 0

            ; 32-bit code segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
            db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 32-bit data segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
            db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 16-bit code segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
            db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 16-bit data segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
            db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

g_GDTDesc:  dw g_GDTDesc - g_GDT - 1    ; limit = size of GDT
            dd g_GDT                    ; address of GDT

g_BootDrive: db 0
