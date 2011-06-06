#include "video.h"
#include "compress.h"
#include <string.h>
#include <stdio.h>

#define enc_init(chan) \
    char __enc_##chan##_store = 0; \
    char __enc_##chan##_valid = 0
#define enc_flush(chan) \
    if (__enc_##chan##_valid) { chan <: __enc_##chan##_store; __enc_##chan##_valid=0; }
#define enc_put(chan, val) \
    chan <: (char)val;
#define enc_escape(chan, val) \
    chan <: (char)EncEscape; chan <: (char)val;
__inline__ void __enc_bit(streaming chanend ch, int b, char &s, char &v) {
    s = (s<<1) | (b&0x1);
    v++;

    if (v==8) {
        if (s == EncEscape)
            enc_put(ch, EncEscape);
        enc_put(ch, s);
        v = 0;
    }
}
#define enc_bit(chan, b) __enc_bit(chan, b, __enc_##chan##_store, __enc_##chan##_valid)

inline int abs(int a) {
    return a>=0 ? a : -a;
}

/**
 * update logic for 'c'
 */
inline int update_c(int &c, const int incr_flag) {
    if (incr_flag) {
        c = c+c/2;
    } else {
        c=-c;
        if (abs(c)>=4) c=c/2;
    }
    return incr_flag;
}

#define printf(...)

void cmpr_encode(streaming chanend c_in, streaming chanend c_out) {
    int pixel;

    vid_init(c_in);
    enc_init(c_out);

    vid_with_frames(c_in) {
        // hv: horizontal-vertical flag 
        int hv = DEFAULT_HV;

        // b: reconstructed picture values
        int bv, bh, b;
        int buff_bv[VID_WIDTH/*/n*/];
        int buff_bh;

        // c: change value in encoded picture
        int cv, ch, c, cf;
        int buff_cv[VID_WIDTH/*/n*/];
        int buff_ch;

        // d: distance reconstructed to original
        int dh, dv, d;

        printf("\nEE new frame\n");
        enc_escape(c_out, EncNewFrame);

        for (int i=0; i<VID_WIDTH; i++) {
            buff_bv[i] = DEFAULT_PIXEL;
            buff_cv[i] = DEFAULT_C;
        }

        vid_with_lines(c_in) {
            int x=0;

            printf("EE new line\n");

            enc_escape(c_out, EncStartOfLine);

            buff_bh = DEFAULT_PIXEL;
            buff_ch = DEFAULT_C;

            vid_with_bytes(pixel, c_in) {
                bv = buff_bv[x];
                bh = buff_bh;
                cv = buff_cv[x];
                ch = buff_ch;

                dh = bh+ch-pixel;
                dv = bv+cv-pixel;

                printf("EE in: px=%d, hv=%d, bv=%d, bh=%d, cv=%d, ch=%d, dv=%d, dh=%d\n", pixel, hv, bv, bh, cv, ch, dv, dh);

                // better to switch hv-flag?
                if (!hv && abs(dh)<abs(dv)-10) {
                    hv = 1;
                } else if (hv && abs(dh) > abs(dv)+10) {
                    hv = 0;
                }

                if (hv) {
                    d = dh;
                    c = ch;
                    b = bh+c;
                } else {
                    d = dv;
                    c = cv;
                    b = bv+c;
                }

                
                cf = update_c(c, (d*c<0));

                enc_bit(c_out, hv);
                enc_bit(c_out, cf);
                printf("EE out: hv=%d, cf=%d, c=%d, d=%d, b=%d\n", hv, cf, c, d, b);

                buff_bv[x] = b;
                buff_bh = b;
                buff_cv[x] = c;
                buff_ch = c;

                x++;
            }
            enc_flush(c_out);
        }
        enc_flush(c_out);
    }
}

{int, int} read_bits(int &off, int &data, streaming chanend c_in) {
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
    return {(data >> off) & 0x03, NewBits};
}

void cmpr_decode(streaming chanend c_in, streaming chanend c_out) {
    int data = 0, off = 0, x;
    /* values derived from stream */
    int bits, ret_type, hv, c_flag;
    /* some buffers */
    // rebuild image
    int buff_pixel_verti[VID_WIDTH];
    int buff_pixel_hori, pixel;
    // history 'c'
    int buff_c_verti[VID_WIDTH];
    int buff_c_hori;
    int c = 1;

    /* read from input stream */
    while(1) {
        {bits, ret_type} = read_bits(off, data, c_in);
        
        switch(ret_type) {
        case EncNewFrame:
            printf("\nDD new frame\n");
            /* fill history buffers with default values, cause there
             * is no reference in first line of image                    */
            for(int i=0; i < VID_WIDTH; i++) {
                buff_c_verti[i]      = DEFAULT_C;
                buff_pixel_verti[i]  = DEFAULT_PIXEL;
            }
            c_out <: VID_NEW_FRAME;
            break;
        case EncStartOfLine:
            printf("DD new line\n");
            x = 0;
            /* horizontal reference is black */
            buff_pixel_hori = DEFAULT_PIXEL;
            buff_c_hori     = DEFAULT_C;
            c_out <: VID_NEW_LINE;
            break;
        case NewBits:
            c_flag = bits & C_BIT_MASK;
            hv     = (bits & H_BIT_MASK) >> 1;
            printf("DD in: c=%d, hv=%d, cv=%d, ch=%d, bv=%d, bh=%d\n", c_flag, hv, buff_c_verti[x], buff_c_hori, buff_pixel_verti[x], buff_pixel_hori);
            /* horizontal vertical flag: 0=horizontal 1=vertical */
            if (hv) {
                c = buff_c_hori;
                pixel = buff_pixel_hori + c; 
            } else {
                c = buff_c_verti[x];
                pixel = buff_pixel_verti[x] + c;
            }

            c_out <: (char)pixel;

            /* update c depends on c_flag */
            update_c(c, c_flag);
            printf("DD out: pix=%d, c=%d\n", pixel, c);

            /* update buffers */
            buff_c_verti[x] = c;
            buff_c_hori = c;
            buff_pixel_verti[x] = pixel;
            buff_pixel_hori = pixel;
            x++;
            break;
        }

    }

}
