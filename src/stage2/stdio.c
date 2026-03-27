#include "io.h"
#include <stdint.h>

#define VGA_X 80
#define VGA_Y 25

uint16_t* vga = (uint16_t*)0xB8000;
uint16_t cursorX, cursorY;

void updateCursor() {
    uint16_t pos = cursorY * 80 + cursorX;
    outb(0x3D4, 0x0F);
    outb(0x3D5, (uint8_t)(pos & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));
}

void clearScreen() {
    for (uint16_t i = 0; i < VGA_X * VGA_Y; i++) {
        vga[i] = ' ' | (0x0F << 8); // Clear the screen with spaces
    }
    cursorX = cursorY = 0;
    updateCursor();
}

void putchar(char c, uint16_t x, uint16_t y) {
    if (x >= VGA_X || y >= VGA_Y) return; // Out of bounds
    vga[y * VGA_X + x] = c | (0x0F << 8); // Character with white on black
}

void putc(char c) {
    if (c == '\n') {
        cursorX = 0;
        cursorY++;
    } else {
        putchar(c, cursorX, cursorY);
        cursorX++;
        if (cursorX >= VGA_X) {
            cursorX = 0;
            cursorY++;
        }
    }
    if (cursorY >= VGA_Y) {
        clearScreen(); // Clear screen if we go beyond the last line
    }
    updateCursor();
}

void puts(const char* str) {
    while (*str) {
        putc(*str++);
    }
}
