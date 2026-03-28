#include "mbr.h"
#include "io.h"
#include "stdio.h"

uint32_t MBR_GetBootablePartition(uint16_t drive) {
    uint8_t mbr[512];
    DISK_Read(drive, 0, 1, mbr);
    for (int i = 0; i < 4; i++) {
        uint8_t* partitionEntry = mbr + 446 + (i * 16);
        if (partitionEntry[4] == 0x00) {
            continue; // not bootable
        }
        uint64_t lba = ((uint64_t)partitionEntry[11] << 24) | ((uint64_t)partitionEntry[10] << 16) | ((uint64_t)partitionEntry[9] << 8) | partitionEntry[8];
        return lba;
    }
    return 0; // no bootable partition found
}
