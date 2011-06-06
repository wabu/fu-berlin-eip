#include "video.h"
#include "compress.h"
#include <string.h>
#include "io.h"

enum CprParams {
    HVDefault = 1,
    CDefault = 24,
};

enum PixelType {
    NewFrame,
    NewLine,
    NewPixel,
};

inline int abs(int a) {
    return a>=0 ? a : -a;
}
/**
 * 
 *
 * @return {bits, type_flag}
 */
{char, char} read_bits(int &off, int &data, streaming chanend c_in) {
    if (off==0) {
        char inData = 0;

        c_in :> inData;
        data = inData;

        if (data == EncEscape) {
            c_in :> inData;
            switch(inData) {
              case EncEscape:
                data = inData;
                off = 8;
                /* read from data and return values after switch */
                break;
              case EncStartOfLine:  return {0, EncStartOfLine};
              case EncNewFrame: return {0, EncNewFrame};
              default:
                data = (data << 8) | inData;
                off = 16;
                break;
            }
        } else {
            off = 8;
        }
    }
    off -= 2;
    return {(data >> off) & 0x02, NewBits};
}

#include <stdio.h>

void cmpr_encode(streaming chanend c_in, streaming chanend c_out) {
    int pixel;

    rd_init(c_in);
    wt_init(c_out, EncEscape);

    rd_with_frames(c_in) {
        // hv: horizontal-vertical flag 
        int hv = HVDefault;

        // b: reconstructed picture values
        int bv, bh, b;
        int buff_bv[VID_WIDTH/*/n*/];
        int buff_bh;

        // c: change value in encoded picture
        int cv, ch, c;
        int buff_cv[VID_WIDTH/*/n*/];
        int buff_ch;

        // d: distance reconstructed to original
        int dh, dv, d;

        printf("\nnew frame\n");
        wt_escape(c_out, EncNewFrame);

        for (int i=0; i<VID_WIDTH; i++) {
            buff_bv[i] = 0;
            buff_cv[i] = CDefault;
        }

        rd_with_lines(c_in) {
            int x=0;

            printf("new line\n");

            wt_escape(c_out, EncStartOfLine);

            buff_bh = 0;
            buff_ch = CDefault;

            rd_with_bytes(pixel, c_in) {
                bv = buff_bv[x];
                bh = buff_bh;
                cv = buff_cv[x];
                ch = buff_ch;

                dh = bh+ch-pixel;
                dv = bv+cv-pixel;

                printf("in: px=%d, hv=%d, bv=%d, bh=%d, cv=%d, ch=%d, dv=%d, dh=%d\n", pixel, hv, bv, bh, cv, ch, dv, dh);

                // better to switch hv-flag?
                if (hv && abs(dh)<abs(dv)-10) {
                    hv = 1;
                } else if (!hv && abs(dh) > abs(dv)+10) {
                    hv = 0;
                }
                wt_bit(c_out, hv);

                if (hv) {
                    d = dh;
                    c = ch;
                    b = bh+c;
                } else {
                    d = dv;
                    c = cv;
                    b = bv+c;
                }

                if (d*c > 0) {
                    c=-c;
                    if (abs(c)>=4) c=c/2;
                    wt_bit(c_out, 0);
                } else {
                    c = c+c/2;
                    wt_bit(c_out, 1);
                }

                printf("out: hv=%d, c=%d, d=%d, b=%d\n", hv, c, d, b);

                buff_bv[x] = b;
                buff_bh = b;
                buff_cv[x] = c;
                buff_ch = c;

                x++;
            }
            wt_flush(c_out);
        }
        wt_flush(c_out);
    }
}


void cmpr_decode(streaming chanend c_in, streaming chanend c_out) {
    int data = 0, off = 0, x = 0, y;
    char bits, ret_type, pixel, hv, c;

    //   tooooooooo loooong
    char buff_pixel_verti[VID_WIDTH];
    char buff_pixel_hori;
    char buff_c_verti[VID_WIDTH];
    char buff_c_hori;

    /* read from input stream */
    while(1) {
        {bits, ret_type} = read_bits(off, data, c_in);
        
        switch(ret_type) {
            case EncNewFrame:
                y = -1;
                c_out <: NewFrame;
                break;
            case EncStartOfLine:
                x = 0;
                /* horizontal reference is black */

                buff_pixel_hori = 0;
                y++;
                break;
            case NewBits:
                c  = bits & C_BIT_MASK;
                hv = bits & H_BIT_MASK;
                if (hv) {

                }

                // x=0? buff_c_vert[x-1] = buff_c_hori;
                break;
        }

    }

}
