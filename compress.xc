#include "video.h"
#include "compress.h"
#include <string.h>
#include <stdio.h>

#define printf(...)


#define enc_init(chan) \
    char __enc_##chan##_store = 0; \
    int  __enc_##chan##_valid = 0
#define enc_flush(chan) \
    if (__enc_##chan##_valid) { chan <: __enc_##chan##_store; __enc_##chan##_valid=0; }
#define enc_put(chan, val) \
    chan <: (char)val
#define enc_escape(chan, val) \
    chan <: (char)EncEscape; chan <: (char)val
#define enc_bits(chan, b, n) \
    __enc_##chan##_store = (__enc_##chan##_store<<n) | (b&((1<<n)-1)); \
    if ((__enc_##chan##_valid+=n)==8) { \
        if (__enc_##chan##_store == EncEscape) chan <: (char)EncEscape; \
        chan <: __enc_##chan##_store; \
        __enc_##chan##_valid = 0; \
    }


#define dec_init(chan) \
    char __dec_##chan##_store = 0; \
    int  __dec_##chan##_valid = 0; \
    char __dec_##chan##_type = 0
inline int __dec_chan_fill(streaming chanend ch, char &d) {
    ch :> d;
    if (d==EncEscape) {
        ch :> d;
        switch (d) {
            case EncNewFrame:
            case EncStartOfLine:
                return d;
            default:
                break;
        }
    }
    return 0;
}
#define dec_with_frames(chan) \
    while (__dec_##chan##_type!=EncNewFrame) {__dec_##chan##_type=__dec_chan_fill(chan,__dec_##chan##_store);} \
    for (;;)
#define dec_with_lines(chan) \
    for (__dec_##chan##_type=__dec_chan_fill(chan,__dec_##chan##_store); __dec_##chan##_type!=EncNewFrame; )
#define dec_with_bits(var, chan) \
    for (__dec_##chan##_type=__dec_chan_fill(chan,__dec_##chan##_store); \
         __dec_##chan##_type!=EncNewFrame && __dec_##chan##_type!=EncStartOfLine; \
         __dec_##chan##_type=__dec_chan_fill(chan,__dec_##chan##_store)) \
    for (__dec_##chan##_valid= 8, var = ((__dec_##chan##_store >> (__dec_##chan##_valid-=2)) & 0x3);\
         __dec_##chan##_valid>=0; var = ((__dec_##chan##_store >> (__dec_##chan##_valid-=2)) & 0x3))


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
        if (abs(c)>=MIN_C*2) c=c/2;
    }
    return incr_flag;
}

void cmpr_encode(streaming chanend c_in, streaming chanend c_out) {
    int pixel;

    vid_init(c_in);
    enc_init(c_out);

    vid_with_frames(c_in) {
        // hv: horizontal-vertical flag 
        int hv = DEFAULT_HV;

        // b: reconstructed picture values
        int bv, bh, b;
        char buff_bv[VID_WIDTH/*/n*/];
        char buff_bh;

        // c: change value in encoded picture
        int cv, ch, c, cf;
        signed char buff_cv[VID_WIDTH/*/n*/];
        signed char buff_ch;

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

                enc_bits(c_out, ((hv<<1)| cf), 2);
                printf("EE out: hv=%d, cf=%d, c=%d, d=%d, b=%d\n", hv, cf, c, d, b);

                buff_bv[x] = b;
                buff_bh = b;
                buff_cv[x] = c;
                buff_ch = c;

                x++;
            }
            //enc_flush(c_out);
        }
        //enc_flush(c_out);
    }
}

void cmpr_decode(streaming chanend c_in, streaming chanend c_out) {
    /* values derived from stream */
    int bits, hv, c_flag;
    /* some buffers */
    // rebuild image
    char buff_pixel_verti[VID_WIDTH];
    char buff_pixel_hori, pixel;
    // history 'c'
    signed char buff_c_verti[VID_WIDTH];
    signed char buff_c_hori;
    int c = 1;

    /* read from input stream */
    dec_init(c_in);
    dec_with_frames(c_in) {
        printf("\nDD new frame\n");
        vid_start_frame(c_out);

        for(int i=0; i < VID_WIDTH; i++) {
            buff_c_verti[i]      = DEFAULT_C;
            buff_pixel_verti[i]  = DEFAULT_PIXEL;
        }


        dec_with_lines(c_in) {
            int x;

            printf("DD new line\n");
            vid_start_line(c_out); 

            buff_pixel_hori = DEFAULT_PIXEL;
            buff_c_hori     = DEFAULT_C;

            x = 0;
            dec_with_bits(bits, c_in) {
                printf("DD valid %d\n", __dec_c_in_valid);
                c_flag =  bits & C_BIT_MASK;
                hv     = (bits & H_BIT_MASK) >> 1;
                printf("DD in: c=%d, hv=%d, cv=%d, ch=%d, bv=%d, bh=%d\n",
                        c_flag, hv, buff_c_verti[x], buff_c_hori, buff_pixel_verti[x], buff_pixel_hori);

                /* horizontal vertical flag: 0=horizontal 1=vertical */
                if (hv) {
                    c = buff_c_hori;
                    pixel = buff_pixel_hori + c; 
                } else {
                    c = buff_c_verti[x];
                    pixel = buff_pixel_verti[x] + c;
                }

                vid_put_pixel(c_out, pixel);

                /* update c depends on c_flag */
                update_c(c, c_flag);
                printf("DD out: pix=%d, c=%d\n", pixel, c);

                /* update buffers */
                buff_c_verti[x] = c;
                buff_c_hori = c;
                buff_pixel_verti[x] = pixel;
                buff_pixel_hori = pixel;

                x++;
            }
        }
    }
}
