#include "video.h"
#include "compress.h"
#include <string.h>
#include <stdio.h>

// TODO: use logging lib instead of printf
#define printf(...)

#define enc_init(chan) \
    char __enc_##chan##_store = 0; \
    int  __enc_##chan##_valid = 0
#define enc_put(chan, val) \
    chan <: (char)val
#define enc_escape(chan, val) \
    chan <: (char)EncEscape; chan <: (char)val

#define enc_add(chan, b, n) \
    __enc_##chan##_store = (__enc_##chan##_store<<n) | (b&((1<<n)-1)); \
    __enc_##chan##_valid+=n; \
    if (__enc_##chan##_valid == 8)
#define enc_filled(chan) \
    (__enc_##chan##_valid == 8)

#define enc_flush(chan) \
    if (__enc_##chan##_store == EncEscape) chan <: (char)EncEscape; \
    chan <: __enc_##chan##_store; \
    __enc_##chan##_valid = 0

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
                return EncEscape;
        }
    }
    return NewBits;
}
#define dec_is_escaped(chan) \
    (__dec_##chan##_type == EncEscape && __dec_##chan##_store != EncEscape)
#define dec_with_frames(chan) \
    while (__dec_##chan##_type!=EncNewFrame) {__dec_##chan##_type=__dec_chan_fill(chan,__dec_##chan##_store);} \
    for (;;)
#define dec_with_lines(chan) \
    for (__dec_##chan##_type=__dec_chan_fill(chan,__dec_##chan##_store); __dec_##chan##_type!=EncNewFrame; )
#define dec_with_bytes(var, chan) \
    for (__dec_##chan##_type=__dec_chan_fill(chan,__dec_##chan##_store), \
         var = __dec_##chan##_store; \
         __dec_##chan##_type!=EncNewFrame && __dec_##chan##_type!=EncStartOfLine; \
         __dec_##chan##_type=__dec_chan_fill(chan,__dec_##chan##_store), \
        var = __dec_##chan##_store)
#define dec_with_bits(var, chan, n) \
    for (__dec_##chan##_valid= 8, var = ((__dec_##chan##_store >> (__dec_##chan##_valid-=n)) & ((1<<n)-1));\
         __dec_##chan##_valid>=0; var = ((__dec_##chan##_store >> (__dec_##chan##_valid-=n)) & ((1<<n)-1)))


inline int abs(int a) {
    return a>=0 ? a : -a;
}

inline int update_c(int &c, const int incr_flag) {
    if (incr_flag) {
        c = c+c/2;
    } else {
        c=-c;
        if (abs(c)>=MIN_C*2) c=c/2;
    }
    return incr_flag;
}

/**
 * Variable Initialisation for the compression algorithm
 * hv: horizontal-vertical flag 
 * b: reconstructed picture values
 * c: change value in encoded picture
 * d: distance reconstructed to original
 */
#define cmpr_logic_vars_init() \
    int hv, hvt; \
    int bv, bh, b; \
    char buff_bv[VID_WIDTH/*/n*/]; \
    char buff_bh; \
    int cv, ch, c, cf; \
    signed char buff_cv[VID_WIDTH/*/n*/]; \
    signed char buff_ch; \
    int dh, dv, d; \
    int x

/**
 * compression code to be executed every start of a frame
 */
#define cmpr_logic_frame_init() \
    hv = DEFAULT_HV; \
    for (int i=0; i<VID_WIDTH; i++) { \
        buff_bv[i] = DEFAULT_PIXEL; \
        buff_cv[i] = DEFAULT_C; \
    }

/**
 * compression code to be executed every start of a line
 */
#define cmpr_logic_line_init() \
    buff_bh = DEFAULT_PIXEL; \
    buff_ch = DEFAULT_C; \
    x=0

#define cmpr_logic_enc(pixel) \
    bv = buff_bv[x]; \
    bh = buff_bh; \
    cv = buff_cv[x]; \
    ch = buff_ch; \
     \
    dh = bh+ch-pixel; \
    dv = bv+cv-pixel; \
     \
    hvt = 0; \
    if (!hv && abs(dh)<abs(dv)-10) { \
        hv = 1; \
        hvt = 1; \
    } else if (hv && abs(dh) > abs(dv)+10) { \
        hv = 0; \
        hvt = 1; \
    } \
     \
    if (hv) { \
        d = dh; \
        c = ch; \
        b = bh+c; \
    } else { \
        d = dv; \
        c = cv; \
        b = bv+c; \
    } \
     \
    cf = update_c(c, (d*c<0)); \
     \
    buff_bv[x] = b; \
    buff_bh = b; \
    buff_cv[x] = c; \
    buff_ch = c; \
     \
    x++

#define cmpr_logic_dec(cf_in, hv_in) \
    hvt=0; /*unused*/ \
    dh = 0; /*unused*/ \
    dv = 0; /*unused*/ \
    d = 0; /*unused*/ \
    cf = cf_in; \
    hv = hv_in; \
     \
    bh = buff_bh; \
    bv = buff_bv[x]; \
    ch = buff_ch; \
    cv = buff_cv[x]; \
     \
    if (hv) { \
        c = ch; \
        b = bh + c; \
    } else { \
        c = cv; \
        b = bv + c; \
    } \
     \
    update_c(c, cf); \
     \
    buff_cv[x] = c; \
    buff_ch = c; \
    buff_bv[x] = b; \
    buff_bh = b; \
     \
    x++

void cmpr_encode(streaming chanend c_in, streaming chanend c_out) {
    int pixel;

    vid_init(c_in);
    enc_init(c_out);
    cmpr_logic_vars_init();

    vid_with_frames(c_in) {
        printf("\nEC new frame\n");
        enc_escape(c_out, EncNewFrame);
        cmpr_logic_frame_init();

        vid_with_lines(c_in) {
            printf("EC new line\n");
            enc_escape(c_out, EncStartOfLine);
            cmpr_logic_line_init();

            vid_with_ints(pixel, c_in) {
                vid_with_bytes(pixel, c_in) {
                    cmpr_logic_enc(pixel);

                    printf("EC in: px=%d, hv=%d, bv=%d, bh=%d, cv=%d, ch=%d, dv=%d, dh=%d\n", pixel, hv, bv, bh, cv, ch, dv, dh);
                    printf("EC out: hv=%d, cf=%d, c=%d, d=%d, b=%d\n", hv, cf, c, d, b);

                    enc_add(c_out, ((hv<<1)| cf), 2);
                }
                enc_flush(c_out);
            }
        }
    }
}

void cmpr_decode(streaming chanend c_in, streaming chanend c_out) {
    dec_init(c_in);
    cmpr_logic_vars_init();
    int bits;

    dec_with_frames(c_in) {
        printf("\nDC new frame\n");
        vid_start_frame(c_out);
        cmpr_logic_frame_init();

        dec_with_lines(c_in) {
            printf("DC new line\n");

            vid_start_line(c_out); 
            cmpr_logic_line_init();

            dec_with_bytes(bits, c_in) {
                dec_with_bits(bits, c_in, 2) {
                    printf("DC valid %d\n", __dec_c_in_valid);

                    cmpr_logic_dec(bits&C_BIT_MASK, (bits&H_BIT_MASK)>>1);

                    printf("DC in: c=%d, hv=%d, cv=%d, ch=%d, bv=%d, bh=%d\n",
                            cf, hv, buff_cv[x], buff_ch, buff_bv[x], buff_bh);
                    printf("DC out: pix=%d, c=%d\n", b, c);

                    vid_put_pixel(c_out, b);
                }
            }
        }
    }
}


void cmpr_rle_encode(streaming chanend c_in, streaming chanend c_out) {
    int pixel;
    char hv_enc;

    vid_init(c_in);
    enc_init(c_out);
    cmpr_logic_vars_init();

    vid_with_frames(c_in) {
        printf("\nEC new frame\n");
        enc_escape(c_out, EncNewFrame);
        cmpr_logic_frame_init();

        vid_with_lines(c_in) {
            printf("EC new line\n");
            enc_escape(c_out, EncStartOfLine);
            cmpr_logic_line_init();

            vid_with_ints(pixel, c_in) {
                vid_with_bytes(pixel, c_in) {
                    cmpr_logic_enc(pixel);

                    printf("EC in: px=%d, hv=%d, bv=%d, bh=%d, cv=%d, ch=%d, dv=%d, dh=%d\n", pixel, hv, bv, bh, cv, ch, dv, dh);
                    printf("EC out: hv=%d, cf=%d, c=%d, d=%d, b=%d\n", hv, cf, c, d, b);

                    hv_enc = (hv_enc<<1) | hvt;

                    enc_add(c_out, cf, 1);
                }
                if (enc_filled(c_out)) {
                    if (hv_enc) {
                        if (hv_enc == 0xff) hv_enc = 0;
                        printf("EC rle flag set, hv_enc=%x\n", hv_enc);
                        enc_escape(c_out, hv_enc);
                        hv_enc = 0;
                    }
                    enc_flush(c_out);
                }
            }
        }
    }
}
void cmpr_rle_decode(streaming chanend c_in, streaming chanend c_out) {
    dec_init(c_in);
    cmpr_logic_vars_init();
    char cbit, rle;

    char hv_enc;
    char hv_valid;
    char hv_flag;

    dec_with_frames(c_in) {
        printf("\nDC new frame\n");
        vid_start_frame(c_out);
        cmpr_logic_frame_init();
        hv_flag = DEFAULT_HV;

        dec_with_lines(c_in) {
            vid_start_line(c_out); 
            cmpr_logic_line_init();

            printf("DC new line\n");

            dec_with_bytes(rle, c_in) {
                if (dec_is_escaped(c_in)) {
                    hv_enc = rle;
                    if (hv_enc == 0) hv_enc = 0xff;
                    printf("DC reading rle %x\n", hv_enc);
                    hv_valid = 8;
                    continue;
                }

                dec_with_bits(cbit, c_in, 1) {
                    printf("DC valid %d, %d, %x\n", __dec_c_in_valid, cbit, __dec_c_in_store);

                    if (hv_valid && ((hv_enc >> (--hv_valid)) & 1) ) {
                        hv_flag = !hv_flag;
                        printf("DC rle toggled hv to %d, v=%d, e=%x\n", hv_flag, hv_valid, hv_enc);
                    }
                    cmpr_logic_dec(cbit, hv_flag);

                    printf("DC in: c=%d, hv=%d, cv=%d, ch=%d, bv=%d, bh=%d\n",
                            cf, hv, buff_cv[x], buff_ch, buff_bv[x], buff_bh);
                    printf("DC out: pix=%d, c=%d\n", b, c);

                    vid_put_pixel(c_out, b);
                }
            }
        }
    }
}

