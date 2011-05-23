#include "video.h"

#include <string.h>

enum PixelType {
    NewFrame,
    NewLine,
    NewPixel,
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

void downsample(const int n, streaming chanend c_in, streaming chanend c_out) {
    int p, t, data, off = 0; 

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
        {p, t} = read_pixel(off, data, c_in);

        switch (t) {
        case NewPixel:
            buffer[x] += p;
            if (++col_sw==n) {
                if (row_sw==n) { // we sumed nxn pixels in buffer[x]
                    c_out <: (char)(buffer[x]/(n*n));
                    buffer[x] = 0;
                }
                x++;
                col_sw=0;
            }
            break;

        case NewLine:
            if (row_sw++ == n) {
                row_sw=1;
                c_out <: VID_NEW_LINE;
            }
            col_sw=0;
            x=0;

            break;

        case NewFrame:
            row_sw=4;
            c_out <: VID_NEW_FRAME;
            break;
        }
    }
}
