section .text
bits 32

extern LoadGDT

%macro x86_EnterRealMode 0
    [bits 32]
    jmp word 18h:.pmode16         ; 1 - jump to 16-bit protected mode segment

.pmode16:
    [bits 16]
    ; 2 - disable protected mode bit in cr0
    mov eax, cr0
    and al, ~1
    mov cr0, eax

    ; 3 - jump to real mode
    jmp word 00h:.rmode

.rmode:
    ; 4 - setup segments
    mov ax, 0
    mov ds, ax
    mov ss, ax

    ; 5 - enable interrupts
    sti

%endmacro

%macro x86_EnterProtectedMode 0
    cli
    call LoadGDT

    ; 4 - set protection enable flag in CR0
    mov eax, cr0
    or al, 1
    mov cr0, eax

    ; 5 - far jump into protected mode
    jmp dword 08h:.pmode


.pmode:
    ; we are now in protected mode!
    [bits 32]
    
    ; 6 - setup segment registers
    mov ax, 0x10
    mov ds, ax
    mov ss, ax

%endmacro

; Convert linear address to segment:offset address
; Args:
;    1 - linear address
;    2 - (out) target segment (e.g. es)
;    3 - target 32-bit register to use (e.g. eax)
;    4 - target lower 16-bit half of #3 (e.g. ax)

%macro LinearToSegOffset 4

    mov %3, %1      ; linear address to eax
    shr %3, 4
    mov %2, %4
    mov %3, %1      ; linear address to eax
    and %3, 0xf

%endmacro

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

; bool _cdecl DISK_Read(uint8_t drive, uint64_t lba, uint8_t count, void* lowerDataOut);
; use int 13h extended read (AH=42h) to read from disk
global DISK_Read
DISK_Read:
    [bits 32]
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ; Stack layout (cdecl, after push ebp):
    ; [ebp+8]  = drive       (uint8_t,  padded to 4 bytes by compiler)
    ; [ebp+12] = lba low     (lower 32 bits of uint64_t)
    ; [ebp+16] = lba high    (upper 32 bits of uint64_t)
    ; [ebp+20] = count       (uint8_t,  padded to 4 bytes)
    ; [ebp+24] = lowerDataOut (void*)

    ; Stash args into our DAP and scratch vars before switching modes
    mov al, [ebp+8]
    mov [DISK_drive], al

    mov eax, [ebp+12]           ; lba low 32
    mov [DAP_lba_lo], eax
    mov eax, [ebp+16]           ; lba high 32
    mov [DAP_lba_hi], eax

    mov al, [ebp+20]
    mov [DAP_count], al

    ; Convert lowerDataOut linear address → segment:offset for DAP
    ; DAP wants a far pointer (offset at +4, segment at +6)
    mov eax, [ebp+24]
    and eax, 0xf                ; offset = linear & 0xf
    mov [DAP_buf_off], ax

    mov eax, [ebp+24]
    shr eax, 4                  ; segment = linear >> 4
    mov [DAP_buf_seg], ax

    x86_EnterRealMode

    [bits 16]

    ; SI = pointer to DAP
    mov si, DAP
    mov dl, [DISK_drive]
    mov ah, 0x42
    int 13h

    mov byte [DISK_result], 0
    jc .done
    mov byte [DISK_result], 1

.done:
    x86_EnterProtectedMode

    [bits 32]
    movzx eax, byte [DISK_result]

    pop edi
    pop esi
    pop ebx
    pop ebp
    ret


section .data

DISK_drive  db 0
DISK_result db 0

; Disk Address Packet (DAP) for INT 13h AH=42h
; Must be in a real-mode-accessible location (below 1MB)
align 2
DAP:
    db 0x10         ; size of DAP (16 bytes)
    db 0            ; reserved, must be 0
DAP_count:
    dw 0            ; number of sectors to read
DAP_buf_off:
    dw 0            ; buffer offset
DAP_buf_seg:
    dw 0            ; buffer segment
DAP_lba_lo:
    dd 0            ; LBA bits [31:0]
DAP_lba_hi:
    dd 0            ; LBA bits [63:32]