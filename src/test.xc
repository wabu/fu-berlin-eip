#include "test.h"
#include "video.h"

#include <stdlib.h>
#include <stdio.h>

int width, height;
int counter; 

int bg = 0xAA;
int fg = 0x11;

// rect parameters;
int rx, ry, hw, hh;
int dx, dy;

void update_frame() {
    rx+=dx;
    ry+=dy;

    if (rx+hw >= width)
        dx=-dx;
    if (rx-hw <= 0)
        dx=-dx;
    if (ry+hh >= height)
        dy=-dy;
    if (ry-hh <= 0)
        dy=-dy;
}

int get_color(int x, int y) {
    int dx = abs(rx-x);
    int dy = abs(ry-y);

    if(dx <= hw && dy <= hh) {
        return fg;
    }
    return bg;
}


/**
  * this function sets up the test video paramters.
  * w must be dividable throught 8, returns 0 on success.
  *
  * NOTE: as the test code could get more complicated, parameters may change in
  *       the future
  */
int tst_setup(int w, int h) {
    width = w;
    height = h;
    counter = 0;

    rx = w/2;
    ry = w/2;

    hh = w/8;
    hw = w/4;

    dx=1;
    dy=2;

    if (w%8) {
        return -1;
    } 
    return 0;
}

void tst_run_debug_video(streaming chanend c_in) {
    while (1) {
        update_frame();

        c_in <: VID_NEW_FRAME;
        for (int y=0; y<height; y++) {
            int col = 0, off = 32;
            c_in <: VID_NEW_LINE;

            for (int x=0; x<width; x++) {
                off -= 8;
                col |= get_color(x,y)<<off;
                if (off==0) {
                    c_in <: col;
                    off=32;
                    col=0;
                }
            }
        }
    }
}

void tst_run_debug_output(streaming chanend c_out) {
    int i;
    while (1) {
        c_out :> i;
        if (i==VID_NEW_FRAME) {
            printf("\v\n");
        } else if (i==VID_NEW_LINE) {
            printf("\n");
        } else {
            printf("%x", i);
        }
    }
}

