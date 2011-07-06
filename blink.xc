#include "blink.h"

#include <platform.h>
#include <stdlib.h>

out port led = PORT_LED;
timer tmr;

#define FLASH_INTERVAL 10000000

void blink1() {
    int off = 3;
    unsigned t;

    tmr :> t;

    while(1) {
        if (++off==8)
            off = 0;
        t += FLASH_INTERVAL;
        tmr when timerafter(t) :> void;
        led <: (off%2 ? 0 : 0b1111);
    }
}
void blink2() {
    int off = 3;
    unsigned t;
    tmr :> t;

    while(1) {
        if (++off==5)
            off = 0;
        t += FLASH_INTERVAL;
        tmr when timerafter(t) :> void;
        led <: 0xf >> off;
    }
}
void blink3() {
    unsigned t;
    tmr :> t;

    while(1) {
        for (int i=0; i<7; i++) {
            t += FLASH_INTERVAL;
            tmr when timerafter(t) :> void;
            led <: i%2 ? 0b0001 : 0b0010;
        }
        for (int i=0; i<7; i++) {
            t += FLASH_INTERVAL;
            tmr when timerafter(t) :> void;
            led <: i%2 ? 0b1000 : 0b0100;
        }
    }
}
void blink4() {
    unsigned t;
    tmr :> t;

    while(1) {
        int r = rand()%16;
        t += FLASH_INTERVAL*(rand()%8);
        tmr when timerafter(t) :> void;
        led <: r;
    }
}
