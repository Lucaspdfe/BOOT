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
    ; set up stack and segments
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; put drive number into bpb (never trust the contents there)
    mov [BPB_DRIVE_NUMBER], dl

    ; clear the display (why do BIOSes not do this :/)
    mov ah, 0
    mov al, 0x03
    int 10h

    ; print hello world message
    mov si, HELLO_MSG
    mov ah, 0x0E              
    cld                       
.loop:
    lodsb                     
    cmp al, 0                 
    je .done                  
    int 10h                   
    jmp .loop
.done:
    ; loop infinetly
    jmp $

DAP:
                    db 16       ; size of DAP (always 16)
                    db 0        ; reserved, must be 0
DAP_COUNT_WORD:     dw 1        ; number of sectors to read
DAP_OFFSET_WORD:    dw 0x7E00   ; offset  ] destination
DAP_SEGMENT_WORD:   dw 0x0000   ; segment ] segment:offset
DAP_LBA_QWORD:      dq 0        ; 64-bit LBA address

HELLO_MSG:          db "Hello, world!", 0xA, 0xD, 0  

times 510-($-$$) db 0
dw 0xAA55