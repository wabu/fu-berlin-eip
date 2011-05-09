#include "video.h"

#include <string.h>

enum PixelType {
    NewPixel,
    NewFrame,
    NewLine,
};

{int, int} read_pixel(int &off, int &data, streaming chanend c_in) {
    if (off==0) {
        c_in :> data;
        if (data == VID_NEW_FRAME) {
            return {0, NewFrame};
        } else if (data == VID_NEW_LINE) {
            return {0, NewLine};
        }
        off = 32;
    }
    off -= 8;
    return {(data >> off) & 0xff, NewPixel};
}

void output_buffer(int buffer[], int size, int n, streaming chanend c_out) {
    c_out <: VID_NEW_LINE;
    for (int i=0; i<size; i++) {
        c_out <: buffer[i]/(n*n);
        buffer[i]=0;
    }
}

void downsample(int n, streaming chanend c_in, streaming chanend c_out) {
    int p, t, data, off = 0, x=0, j=0, i=0;
    int buffer[VID_WIDTH];

    // FIXME: clear buffer

    while (1) {
        {p, t} = read_pixel(off, data, c_in);

        if (t==NewPixel) {
            buffer[x] += p;

            if (++i==n) {
                x++;
                i=0;
            }
        } else if (t==NewLine) {
            if (++j==n) {
                j=0;
                i=0;
                output_buffer(buffer, x, n, c_out);
            }
            x=0;
        } else if (t==NewFrame) {
            j=n-1; // hack to assure that buffer is outputed on next NewLine
            c_out <: VID_NEW_FRAME;
        }
    }
}
