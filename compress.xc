#include "video.h"
#include "compress.h"
#include <string.h>
#include <stdio.h>

#define SUB_SAMPLE_HEIGHT VID_HEIGHT/SUB_SAMPLERATE
#define SUB_SAMPLE_WIDTH  VID_WIDTH/SUB_SAMPLERATE 

// TODO: use logging lib instead of printf
//#define printf(...)

#define enc_init(chan) \
    char __enc_##chan##_store = 0; \
    int  __enc_##chan##_valid = 0
#define enc_put(chan, val) \
    chan <: (char)val
#define enc_escape(chan, val) \
    chan <: (char)EncEscape; chan <: (char)val

#define enc_add(chan, val, n) \
    __enc_##chan##_store = (__enc_##chan##_store<<n) | (val&((1<<n)-1)); \
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
 * since we just commit changes in hvp we need one transmission bit:
 * current --> change_to   :   bit value
 * h -> v : 0
 * h -> p : 1
 * v -> h : 0
 * v -> p : 1
 * p -> h : 0
 * p -> v : 1
 */
inline char switch_hvp(char from, char to) {
    return from != PREVIOUS ? to == PREVIOUS : to == VERTICAL;
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
    int bv, bh, bp, b; \
    char buff_vert_b[VID_WIDTH/*/n*/]; \
    char buff_hori_b; \
    int cv, ch, cp, c, cf; \
    signed char buff_vert_c[VID_WIDTH/*/n*/]; \
    signed char buff_hori_c; \
    int dh, dv, dp, d; \
    int x,y, sub_y

/**
 * compression code to be executed every start of a frame
 */
#define cmpr_logic_frame_init() \
    bp = dp = cp = 0; \
    hv = DEFAULT_HV; \
    y = -1; \
    for (int i=0; i<VID_WIDTH; i++) { \
        buff_vert_b[i] = DEFAULT_PIXEL; \
        buff_vert_c[i] = DEFAULT_C; \
    }

/**
 * compression code to be executed every start of a line
 */
#define cmpr_logic_line_init() \
    buff_hori_b = DEFAULT_PIXEL; \
    buff_hori_c = DEFAULT_C; \
    x=0; \
    sub_y = ++y/SUB_SAMPLERATE

#define cmpr_logic_enc(pixel) \
    bv = buff_vert_b[x]; \
    bh = buff_hori_b; \
    cv = buff_vert_c[x]; \
    ch = buff_hori_c; \
     \
    dh = bh+ch-pixel; \
    dv = bv+cv-pixel; \
    dp = 0; \
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
    buff_vert_b[x] = b; \
    buff_hori_b = b; \
    buff_vert_c[x] = c; \
    buff_hori_c = c; \
     \
    x++

#define cmpr_logic_enc_3d(pixel) \
    bv = buff_vert_b[x]; \
    bh = buff_hori_b; \
    bp = buff_prev_b[sub_y][x/SUB_SAMPLERATE]; \
    cv = buff_vert_c[x]; \
    ch = buff_hori_c; \
    cp = buff_prev_c[sub_y][x/SUB_SAMPLERATE]; \
     \
    dh = bh+ch-pixel; \
    dv = bv+cv-pixel; \
    dp = bp+cp-pixel; \
     \
    hvt = 0; \
    if (hv == HORIZONTAL) { \
      if(abs(dh)<abs(dv)-10) { \
        hv = VERTICAL; \
        hvt = 1; \
      } \
      if(abs(dh) < abs(dp)-10) { \
        hv = PREVIOUS; \
        hvt = 1; \
      } \
    } else if (hv == VERTICAL) { \
        if ( abs(dv) < abs(dh)-10) { \
            hv = HORIZONTAL; \
            hvt = 1; \
        } \
        if (abs(dv) < abs(dp)-10) { \
            hv = PREVIOUS; \
            hvt = 1; \
        } \
    } else if (hv == PREVIOUS) { \
        if ( abs(dp) < abs(dh)-10) { \
            hv = HORIZONTAL; \
            hvt = 1; \
        } \
        if (abs(dp) < abs(dv)-10) { \
            hv = VERTICAL; \
            hvt = 1; \
        } \
    } \
     \
    switch (hv) { \
    case HORIZONTAL: \
        d = dh; \
        c = ch; \
        b = bh+c; \
        break; \
    case VERTICAL: \
        d = dv; \
        c = cv; \
        b = bv+c; \
        break; \
    default: \
        d = dp; \
        c = cp; \
        b = bp + c;\
        break; \
    } \
     \
    cf = update_c(c, (d*c<0)); \
     \
    buff_vert_b[x] = b; \
    buff_hori_b = b; \
    buff_vert_c[x] = c; \
    buff_hori_c = c; \
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
    bh = buff_hori_b; \
    bv = buff_vert_b[x]; \
    ch = buff_hori_c; \
    cv = buff_vert_c[x]; \
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
    buff_vert_c[x] = c; \
    buff_hori_c = c; \
    buff_vert_b[x] = b; \
    buff_hori_b = b; \
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
                            cf, hv, buff_vert_c[x], buff_hori_c, buff_vert_b[x], buff_hori_b);
                    printf("DC out: pix=%d, c=%d\n", b, c);

                    vid_put_pixel(c_out, b);
                }
            }
        }
    }
}


void cmpr_encode_3d(streaming chanend c_in, streaming chanend c_out) {
// what do we need?
// frame counter for sync
// sub sampled image 8x8 4x4?
// hv is now hvp used as horizontal vertical previous flag


// hvp-pixel counter as we submit hvp at the end of each line
// hv-encoding-rle-logic in buffer

// steps:
// frame_init 
//   sub sampled image with DEFAULT_PIXEL values: buff_prev_b;
//   sub sampled c values                         buff_prev_c
//   hvp is 'p'
//   c = DEFAULT_C

// receive pixel p(x,y)
// do parallel sub sampling (buffer, counter needed)
// > distances: d_h, d_v, d_p
// >   choose bias best distance
// > calculate 'c' value with update_flag


// replace prev_img_buffer with sub sampled image

    int pixel;

    int frames_to_next_sync = 0;

    signed char buff_prev_c[SUB_SAMPLE_HEIGHT][SUB_SAMPLE_WIDTH];
    char        buff_prev_b[SUB_SAMPLE_HEIGHT][SUB_SAMPLE_WIDTH];
    int         new_buff_c[SUB_SAMPLE_WIDTH];
    int         new_buff_b[SUB_SAMPLE_WIDTH];
    
    char        buff_hvp[VID_WIDTH];
    char        hvp_bin, hvp_current, hvp_cnt;

    vid_init(c_in);
    enc_init(c_out);
    cmpr_logic_vars_init();

    vid_with_frames(c_in) {
        printf("\nEC new frame\n");
        enc_escape(c_out, EncNewFrame);
        // number of pixels per line
        enc_put(c_out, VID_WIDTH);
        // synchronization flag 
        enc_put(c_out, frames_to_next_sync == 0);
        // if synchronization is forced, our previous anchor is set to
        // default values instead of expected decoded values
        if (frames_to_next_sync == 0) {
            frames_to_next_sync = SYNC_INTERVAL;
            for(int j = 0; j < SUB_SAMPLE_HEIGHT; j++) {
                for( int i = 0; i < SUB_SAMPLE_WIDTH; i++) {
                    buff_prev_c[j][i] = DEFAULT_C;
                    buff_prev_b[j][i] = DEFAULT_PIXEL;
                }
            }
        }
        cmpr_logic_frame_init();

        hvp_current = hv;
        hvp_cnt = 0;

        vid_with_lines(c_in) {
            printf("\nEC new line\n");
            cmpr_logic_line_init();
            
            hvp_bin = 0;

            vid_with_ints(pixel, c_in) {
                vid_with_bytes(pixel, c_in) {
                    cmpr_logic_enc_3d(pixel); 
                    enc_add(c_out, cf, 1);

                    if (hvt) {
                       buff_hvp[hvp_bin++] = ((hvp_cnt << 1) | switch_hvp(hvp_current, hv));
                       hvp_cnt = 1;
                    } else {
                        hvp_cnt++;
                        // check against 2^7+1 to avoid problems if hvp toggles 
                        // at next pixel
                        if (hvp_cnt == 127) {
                            buff_hvp[hvp_bin++] = (char) EncEscape;
                            hvp_cnt = 0;
                        }
                    }
                    
                    // sub sampling of decoded imate
                    new_buff_b[(x-1)/SUB_SAMPLERATE] += b;
                    new_buff_c[(x-1)/SUB_SAMPLERATE] += c;
                }
            }
            // FIXME use <= ???
            for(int i = 0; i < hvp_bin;i++) {
                enc_put(c_out, buff_hvp[i]);
            }
            // sub sampling logic: 'close' sub sampling windows ;)
            if (y % SUB_SAMPLERATE == (SUB_SAMPLERATE-1)) {
                printf("\nEC subsampling\n");
                c_out <: VID_NEW_LINE;
                for(int i=0; i<SUB_SAMPLE_WIDTH; i++) {
                    buff_prev_c[y/SUB_SAMPLERATE][i] = new_buff_c[i]/(SUB_SAMPLERATE*SUB_SAMPLERATE);
                    buff_prev_b[y/SUB_SAMPLERATE][i] = new_buff_b[i]/(SUB_SAMPLERATE*SUB_SAMPLERATE);
                    new_buff_b[i] = new_buff_c[i] = 0;
                }
            }
            // TODO warning if x does not match expected VID_WIDTH?
            y++;
        }
        // 
    }
}


// We use something like rle for the hv flag:
// - send c-bits in normal byte stream
// - escape hv-changes:
//   if the hv-flag changes for the next byte of c-data, insert an 0xff 0x..
//   where a bit in 0x.. means, that hv should toggle on that bit.

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

                    hv_enc = (hv_enc<<1) | hvt/**<hv toggle*/;

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
                            cf, hv, buff_vert_c[x], buff_hori_c, buff_vert_b[x], buff_hori_b);
                    printf("DC out: pix=%d, c=%d\n", b, c);

                    vid_put_pixel(c_out, b);
                }
            }
        }
    }
}

