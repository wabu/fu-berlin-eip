#include <xccompat.h>

#ifndef __XC__
#define streaming
#endif

static inline int creadi(streaming chanend c) {
    int data;
    __asm__ ( "in %0, res[%1]"
            : "=r" (data)
            : "r" (c)
            : "r0");
    return data;
}

static inline char creadc(streaming chanend c) {
    char data;
    __asm__ ( "int %0, res[%1]"
            : "=r" (data)
            : "r" (c)
            : "r0");
    return data;
}

static inline void cwritei(streaming chanend c, int d) {
    __asm__ ( "out res[%0], %1"
            :
            : "r" (c), "r" (d)
            : "r0", "r1");
}

static inline void cwritec(streaming chanend c, char d) {
    __asm__ ( "outt res[%0], %1"
            :
            : "r" (c), "r" (d)
            : "r1", "r0");
}

