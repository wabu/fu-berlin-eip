#include "video.h"

#include <string.h>

enum PixelType {
    NewFrame = -1,
    NewLine  = -2,
};

inline int read_pixel(int &off, int &data, streaming chanend c_in) {
    if (off==0) {
        c_in :> data;
        switch (data) {
        case VID_NEW_FRAME:
            return NewFrame;
        case VID_NEW_LINE:
            return NewLine;
        default:
            off=32;
            break;
        }
    }
    off -= 8;
    return (data >> off) & 0xff;
}

void downsample(const int n, streaming chanend c_in, streaming chanend c_out) {
    int p, data, off = 0; 

    // idea: in each line, sum up n pixel values in a buffer postion
    //       on the n-th line at each n-th pixel, output the downsampled value and clear the buffer position

    int buffer[VID_WIDTH/*/n*/]; // no dynamic memory ... :/

    int x=0; // offset for downsampled buffer
    int col_sw=0; // counter for pixels currently in buffer at position x for the current line
    int row_sw=0; // counter for lines currently in buffer

    for (int i=0; i<VID_WIDTH; i++) {
        buffer[i]=0;
    }

    while (1) {
        c_in :> data;

        switch (data) {
        case VID_NEW_FRAME:
            row_sw=4;
            c_out <: VID_NEW_FRAME;
            continue;
            break;

        case VID_NEW_LINE:
            if (row_sw++ == n) {
                row_sw=1;
                c_out <: VID_NEW_LINE;
            }
            col_sw=0;
            x=0;
            continue;
            break;

        default:
            for (off=24; off>=0; off-=8) {
                p = (data >> off) & 0xff;

                buffer[x] += p;
                if (++col_sw==n) {
                    if (row_sw==n) { // we sumed nxn pixels in buffer[x]
                        c_out <: (char)(buffer[x]/(n*n));
                        buffer[x] = 0;
                    }
                    x++;
                    col_sw=0;
                }
            }
            break;
        }
    }
}
