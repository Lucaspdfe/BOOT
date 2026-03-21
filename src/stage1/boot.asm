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
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [BPB_DRIVE_NUMBER], dl

    mov ah, 0
    mov al, 0x03
    int 10h

    mov eax, [BPB_HIDDEN_SECTORS]
    add eax, 1
    mov [DAP_LBA_QWORD], eax
    xor eax, eax
    mov ax, [BPB_RESERVED_SECTORS]
    sub ax, 1
    mov word [DAP_COUNT_WORD], ax

    mov si, DAP
    mov ah, 42h
    mov dl, [BPB_DRIVE_NUMBER]
    int 13h
    jc .disk_error

    mov si, MSG_LOADING
    call puts

    jmp after

    cli
    hlt

.disk_error:
    mov si, DISK_ERROR
    call puts

    mov al, ah
    add al, '0'
    mov ah, 0x0e
    int 10h
    cli
    hlt

DAP:
                      db 16       ; size of DAP (always 16)
                      db 0        ; reserved, must be 0
DAP_COUNT_WORD:       dw 1        ; number of sectors to read
DAP_OFFSET_WORD:      dw 0x7E00   ; offset  ] destination
DAP_SEGMENT_WORD:     dw 0x0000   ; segment ] segment:offset
DAP_LBA_QWORD:        dq 0        ; 64-bit LBA address

DISK_ERROR:          db 'Disk read Failed: ', 0
STAGE2_NOT_FOUND:    db 'STAGE2.BIN not found!', 0

times 510-($-$$) db 0
dw 0xAA55

times 1024-($-$$) db 0

puts:
    push ax
    mov ah, 0x0e
.loop:
    mov al, [si]
    cmp al, 0
    je .done
    int 10h
    inc si
    jmp .loop
.done:
    pop ax
    ret

after:
    ; first_data_sector = fat_boot->reserved_sector_count + (fat_boot->table_count * fat_boot_ext_32->table_size_32)
    movzx eax, byte [BPB_FAT_COUNT]
    imul eax, dword [BPB_SECTORS_PER_FAT32]             ; eax = fat_boot->table_count * fat_boot_ext_32->table_size_32
    movzx ebx, word [BPB_RESERVED_SECTORS]
    add eax, ebx                                        ; eax = fat_boot->reserved_sector_count + (fat_boot->table_count * fat_boot_ext_32->table_size_32), first_data_sector
    add eax, [BPB_HIDDEN_SECTORS]                       ; adds forgotten hidden lba...
    mov [FIRST_DATA_SECTOR], eax

    ; cluster_to_sector calculation: first_sector_of_cluster = ((cluster - 2) * fat_boot->sectors_per_cluster) + first_data_sector
    mov eax, [BPB_ROOT_CLUSTER]
    sub eax, 2                                          ; eax = cluster - 2
    movzx ebx, byte [BPB_SECTORS_PER_CLUSTER]
    imul eax, ebx                                       ; eax = (cluster - 2) * fat_boot->sectors_per_cluster
    add eax, [FIRST_DATA_SECTOR]                        ; eax = ((cluster - 2) * fat_boot->sectors_per_cluster) + first_data_sector, first_sector_of_cluster
    
    ; read root directory (reads only one cluster because no way I'm reading everything)
    mov [DAP_LBA_QWORD], eax                            ; LBA = eax
    mov dword [DAP_LBA_QWORD+4], 0 
    mov word [DAP_COUNT_WORD], 1                        ; Count = 1 cluster
    mov word [DAP_OFFSET_WORD],  0x7E00
    mov word [DAP_SEGMENT_WORD], 0x0000                 ; address = 0x0000:0x7E00
    mov si, DAP
    mov ah, 42h
    mov dl, [BPB_DRIVE_NUMBER]
    int 13h
    jc .disk_error

    cld

    mov bx, 0x7E00
.search_loop:
    mov si, STAGE2_NAME
    mov di, bx
    mov cx, 11
    repe cmpsb
    jz .done_search
    add bx, 32
    cmp byte [bx], 0
    je .not_found
    jmp .search_loop
.done_search:
    movzx eax, word [bx+26]
    movzx edx, word [bx+20]
    shl edx, 16
    or eax, edx
    and eax, 0x0FFFFFFF                                 ; FAT32 uses only 28 bits
    mov [CURRENT_CLUSTER], eax

    mov bx, STAGE2_LOAD_OFFSET
    ; CURRENT_CLUSTER = current cluster, ebx = load offset (add BPB_SECTORS_PER_CLUSTER * BPB_BYTES_PER_SECTOR) per loop
.load_loop:
    ; cluster_to_sector calculation: first_sector_of_cluster = ((cluster - 2) * fat_boot->sectors_per_cluster) + first_data_sector
    mov eax, [CURRENT_CLUSTER]
    sub eax, 2                                          ; eax = cluster - 2
    movzx ecx, byte [BPB_SECTORS_PER_CLUSTER]
    imul eax, ecx                                       ; eax = (cluster - 2) * fat_boot->sectors_per_cluster
    add eax, [FIRST_DATA_SECTOR]                        ; eax = ((cluster - 2) * fat_boot->sectors_per_cluster) + first_data_sector, first_sector_of_cluster

    ; read file
    mov [DAP_LBA_QWORD], eax                            ; LBA = eax
    mov dword [DAP_LBA_QWORD+4], 0
    movzx ax, byte [BPB_SECTORS_PER_CLUSTER]
    mov [DAP_COUNT_WORD], ax                            ; Count = 1 cluster
    mov [DAP_OFFSET_WORD], bx
    mov word [DAP_SEGMENT_WORD], STAGE2_LOAD_SEGMENT    ; address = STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET
    mov si, DAP
    mov ah, 42h
    mov dl, [BPB_DRIVE_NUMBER]
    int 13h
    jc .disk_error

    ; get FAT sector: fat_sector = (hidden_sectors + reserved_sectors) + ((active_cluster * 4) / sector_size);
    mov eax, [CURRENT_CLUSTER]
    shl eax, 2                                          ; eax = active_cluster * 4
    movzx ecx, word [BPB_BYTES_PER_SECTOR]
    xor edx, edx
    div ecx                                             ; eax = (active_cluster * 4) / sector_size
    add eax, dword [BPB_HIDDEN_SECTORS]                 ; eax = hidden_sectors + ((active_cluster * 4) / sector_size)
    movzx ecx, word [BPB_RESERVED_SECTORS]
    add eax, ecx                                        ; eax = (hidden_sectors + reserved_sectors) + ((active_cluster * 4) / sector_size), fat_sector

    mov [DAP_LBA_QWORD], eax                            ; LBA = eax
    mov dword [DAP_LBA_QWORD+4], 0
    mov word [DAP_COUNT_WORD], 1                             ; Count = 1 sector
    mov word [DAP_OFFSET_WORD], 0x7E00
    mov word [DAP_SEGMENT_WORD], 0x0000                 ; address = 0x0000:0x7E00
    mov si, DAP
    mov ah, 42h
    mov dl, [BPB_DRIVE_NUMBER]
    int 13h
    jc .disk_error

    ; get byte of the entry
    mov eax, [CURRENT_CLUSTER]
    shl eax, 2                                          ; eax = active_cluster * 4
    movzx ecx, word [BPB_BYTES_PER_SECTOR]
    xor edx, edx
    div ecx                                             ; edx = (active_cluster * 4) % sector_size
    add edx, 0x7E00
    mov si, dx
    mov eax, dword [si]
    cmp eax, 0x0FFFFFF8
    jae .done_loading
    mov [CURRENT_CLUSTER], eax
    movzx cx, byte [BPB_SECTORS_PER_CLUSTER]
    imul cx, word [BPB_BYTES_PER_SECTOR]
    add bx, cx
    jmp .load_loop
.done_loading:
    mov dl, [BPB_DRIVE_NUMBER]
    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

    cli
    hlt

.not_found:
    mov si, STAGE2_NOT_FOUND
    call puts

    cli
    hlt

.disk_error:
    mov si, DISK_ERROR
    call puts

    mov al, ah
    add al, '0'
    mov ah, 0x0e
    int 10h
    cli
    hlt

MSG_LOADING:        db 'Loading...', 0x0D, 0x0A, 0
STAGE2_NAME:        db "STAGE2  BIN"
FIRST_DATA_SECTOR:  dd 0
CURRENT_CLUSTER:    dd 0

STAGE2_LOAD_SEGMENT equ 0
STAGE2_LOAD_OFFSET  equ 0x500

%if ($-$$) > (6*512)
    %error "Stage1.5 too big! Exceeds 6 sectors"
%endif
times (6*512)-($-$$) db 0