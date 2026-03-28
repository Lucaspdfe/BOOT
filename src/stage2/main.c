#include <stdint.h>
#include "io.h"
#include "stdio.h"
#include "mbr.h"

uint16_t* vgaBuffer = (uint16_t*)0xB8000;

void puts_uint32(uint32_t value) {
    char buf[11];   // max 10 digits + null terminator
    int i = 10;
    buf[10] = '\0';

    if (value == 0) {
        puts("0");
        return;
    }

    while (value > 0 && i > 0) {
        buf[--i] = '0' + (value % 10);
        value /= 10;
    }

    puts(buf + i);
}

void __attribute__((cdecl)) start(uint16_t bootDrive) {
    clearScreen();
    puts("Hello, World!\n");
    uint32_t bootLBA = MBR_GetBootablePartition(bootDrive);
    puts("bootLBA: ");
    puts_uint32(bootLBA);
    puts("\n");
end:
    for (;;);
}
