#include "test.h"
#include "video.h"

#include <stdlib.h>
#include <stdio.h>
#include <xs1.h>

int width, height;
int counter; 

int bg = 0xAA;
int fg = 0xFC;

// rect parameters;
int rx, ry, hw, hh;
int dx, dy;

void update_frame() {
    rx+=dx;
    ry+=dy;

    if (rx+hw >= width) {
        dx=-dx;
        rx = width-hw-1;
    }
    if (rx-hw <= 0) {
        dx=-dx;
        rx = hw;
    }
    if (ry+hh >= height) {
        dy=-dy;
        ry = height-hh-1;
    }
    if (ry-hh <= 0) {
        dy=-dy;
        ry = hh;
    }
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
    timer t;
    unsigned int time;
    int cnt = 0;

    t :> time;
    while (1) {
        if (cnt++%4 == 0) {
        }
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
        time += 5000000;
        t when timerafter(time) :> void;
    }
}


void tst_run_debug_output(streaming chanend c_out) {
    int i;

    vid_init(c_out);
    vid_with_frames(c_out) {
        vid_with_lines(c_out) {
            vid_with_ints(i, c_out) {
                printf("%08x", i);
            }
            printf("\n");
        }
        printf("\v\n");
    }
}

void tst_run_dump_stream(streaming chanend c_out) {
    int buffer[4];

    for(;;) {
        for(int i=0; i<4; i++) {
            c_out :> buffer[i];
        }
        printf("%08x %08x %08x %08x\n", buffer[0],buffer[1],buffer[2],buffer[3]);
    }
}

void tst_run_frame_statistics(streaming chanend c_out, int ex, int ey) {
    int t, bt;
    int n=0;

    timer tmr;

    vid_init(c_out);
    vid_with_frames(c_out) {
        int y=0;

        vid_with_lines(c_out) {

            // count pixels
            int x=0, p;
            vid_with_ints(p, c_out) {
                x+=4;
            }

            if (x != ex) {
                printf("lost pixels %d/%d in line %d\n", x, ex, y);
            }
            x=0;

            y++;
        }
        if (y != ey)
            printf("lost line %d/%d in frame %d\n", y, ey, n);

        // fps
        n++;
        tmr :> t;
        if (t-bt > 5*XS1_TIMER_HZ) {
            printf("frame rate is %d\n", n/5);
            n=0;
            bt=t;
        }
    }
}

