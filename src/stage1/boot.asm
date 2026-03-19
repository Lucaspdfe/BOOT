org 0x7C00
bits 16

jmp short start
nop

times 90-($-$$) db 0

; ------------------------------------------------
; FAT32 BPB / EBR offsets (relative to 0x7C00)
; ------------------------------------------------

%define BOOT_BASE 0x7C00

; Jump + OEM
BPB_OEM                 equ BOOT_BASE + 3

; ----- BPB -----

BPB_BYTES_PER_SECTOR    equ BOOT_BASE + 11
BPB_SECTORS_PER_CLUSTER equ BOOT_BASE + 13
BPB_RESERVED_SECTORS    equ BOOT_BASE + 14
BPB_FAT_COUNT           equ BOOT_BASE + 16
BPB_ROOT_ENTRIES        equ BOOT_BASE + 17
BPB_TOTAL_SECTORS_16    equ BOOT_BASE + 19
BPB_MEDIA_DESCRIPTOR    equ BOOT_BASE + 21
BPB_SECTORS_PER_FAT16   equ BOOT_BASE + 22
BPB_SECTORS_PER_TRACK   equ BOOT_BASE + 24
BPB_HEADS               equ BOOT_BASE + 26
BPB_HIDDEN_SECTORS      equ BOOT_BASE + 28
BPB_TOTAL_SECTORS_32    equ BOOT_BASE + 32

; ----- FAT32 EBR -----

BPB_SECTORS_PER_FAT32   equ BOOT_BASE + 36
BPB_EXT_FLAGS           equ BOOT_BASE + 40
BPB_FS_VERSION          equ BOOT_BASE + 42
BPB_ROOT_CLUSTER        equ BOOT_BASE + 44
BPB_FSINFO              equ BOOT_BASE + 48
BPB_BACKUP_BOOT         equ BOOT_BASE + 50

BPB_DRIVE_NUMBER        equ BOOT_BASE + 64
BPB_BOOT_SIGNATURE      equ BOOT_BASE + 66
BPB_VOLUME_ID           equ BOOT_BASE + 67
BPB_VOLUME_LABEL        equ BOOT_BASE + 71
BPB_FS_TYPE             equ BOOT_BASE + 82

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [BPB_DRIVE_NUMBER], dl

    mov ah, 0
    mov al, 0x03
    int 10h

    movzx eax, byte [BPB_FAT_COUNT]
    imul eax, dword [BPB_SECTORS_PER_FAT32]
    movzx ecx, word [BPB_RESERVED_SECTORS]
    add eax, ecx
    add eax, [BPB_HIDDEN_SECTORS]
    mov [first_data_sector], eax

    mov eax, [BPB_ROOT_CLUSTER]
    sub eax, 2
    movzx ecx, byte [BPB_SECTORS_PER_CLUSTER]
    imul eax, ecx
    add eax, [first_data_sector]

    mov [DAP_LBA], eax
    mov dword [DAP_LBA+4], 0
    mov word [DAP_SECTORS], 1
    mov si, DAP
    mov ah, 42h
    int 13h
    jc disk_error

    cld

    mov bx, 0x7E00
.find_loop:
    mov si, STAGE2_NAME
    mov di, bx
    mov cx, 11
    repe cmpsb
    jz .done
    add bx, 32
    cmp byte [bx], 0
    je not_found
    jmp .find_loop
.done:
    ; bx = address of entry

    xor eax, eax
    mov ax, [bx+26]
    sub eax, 2
    movzx ecx, byte [BPB_SECTORS_PER_CLUSTER]
    imul eax, ecx
    add eax, [first_data_sector]

    mov [DAP_LBA], eax
    mov dword [DAP_LBA+4], 0
    xor ax, ax
    mov al, [BPB_SECTORS_PER_CLUSTER]
    mov [DAP_SECTORS], ax
    mov word [DAP_OFFSET], STAGE2_LOAD_OFFSET
    mov word [DAP_SEGMENT], STAGE2_LOAD_SEGMENT
    mov si, DAP
    mov ah, 42h
    mov dl, [BPB_DRIVE_NUMBER]
    int 13h
    jc disk_error

    mov dl, [BPB_DRIVE_NUMBER]
    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

    cli
    hlt

disk_error:
    mov ah, 0x0e
    mov al, 'd'
    int 10h
    jmp reset_when_key_pressed
not_found:
    mov ah, 0x0e
    mov al, 'n'
    int 10h
reset_when_key_pressed:
    mov ah, 0
    int 16h
    jmp 0FFFFh:0

    cli
    hlt

puts:
    mov ah, 0x0e
.loop:
    mov al, [si]
    cmp al, 0
    je .done
    int 10h
    inc si
    jmp .loop
.done:
    ret
    

first_data_sector: dd 0

DAP:
                    db 16
                    db 0
DAP_SECTORS:        dw 1
DAP_OFFSET:         dw 0x7E00
DAP_SEGMENT:        dw 0
DAP_LBA:            dq 0

STAGE2_NAME:        db "STAGE2  BIN"

STAGE2_LOAD_SEGMENT equ 0
STAGE2_LOAD_OFFSET  equ 0x500

times 510-($-$$) db 0
dw 0xAA55