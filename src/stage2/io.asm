section .text
bits 32

; void _cdecl outb(uint16_t port, uint8_t value);
global outb
outb:
    mov dx, [esp + 4]   ; port
    mov al, [esp + 8]   ; value
    out dx, al
    ret

; uint8_t _cdecl inb(uint16_t port);
global inb
inb:
    mov dx, [esp + 4]   ; port
    in al, dx
    ret

; void _cdecl outw(uint16_t port, uint16_t value);
global outw
outw:
    mov dx, [esp + 4]   ; port
    mov ax, [esp + 8]   ; value
    out dx, ax
    ret

; uint16_t _cdecl inw(uint16_t port);
global inw
inw:
    mov dx, [esp + 4]   ; port
    in ax, dx
    ret

; void _cdecl outl(uint16_t port, uint32_t value);
global outl
outl:
    mov dx, [esp + 4]   ; port
    mov eax, [esp + 8]   ; value
    out dx, eax
    ret

; uint32_t _cdecl inl(uint16_t port);
global inl
inl:
    mov dx, [esp + 4]   ; port
    in eax, dx
    ret
