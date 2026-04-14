#include "string.h"

// =====================
// Memory functions
// =====================

void *memcpy(void *dest, const void *src, size_t n) {
    uint8_t *d = (uint8_t*)dest;
    const uint8_t *s = (const uint8_t*)src;

    for (size_t i = 0; i < n; i++) {
        d[i] = s[i];
    }

    return dest;
}

void *memset(void *dest, int value, size_t n) {
    uint8_t *d = (uint8_t*)dest;

    for (size_t i = 0; i < n; i++) {
        d[i] = (uint8_t)value;
    }

    return dest;
}

int memcmp(const void *a, const void *b, size_t n) {
    const uint8_t *p1 = (const uint8_t*)a;
    const uint8_t *p2 = (const uint8_t*)b;

    for (size_t i = 0; i < n; i++) {
        if (p1[i] != p2[i]) {
            return p1[i] - p2[i];
        }
    }

    return 0;
}

// =====================
// String functions
// =====================

size_t strlen(const char *str) {
    size_t len = 0;

    while (str[len]) {
        len++;
    }

    return len;
}

int strcmp(const char *a, const char *b) {
    while (*a && (*a == *b)) {
        a++;
        b++;
    }

    return (unsigned char)*a - (unsigned char)*b;
}

int strncmp(const char *a, const char *b, size_t n) {
    for (size_t i = 0; i < n; i++) {
        if (a[i] != b[i] || a[i] == '\0' || b[i] == '\0') {
            return (unsigned char)a[i] - (unsigned char)b[i];
        }
    }

    return 0;
}

char *strcpy(char *dest, const char *src) {
    char *ret = dest;

    while ((*dest++ = *src++)) {
        // copy including null terminator
    }

    return ret;
}

char *strncpy(char *dest, const char *src, size_t n) {
    size_t i;

    for (i = 0; i < n && src[i]; i++) {
        dest[i] = src[i];
    }

    for (; i < n; i++) {
        dest[i] = '\0';
    }

    return dest;
}
