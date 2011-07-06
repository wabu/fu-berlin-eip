#include "video.h"
#include "compress.h"
#include <string.h>
#include <stdio.h>

#define SUB_SAMPLE_HEIGHT VID_HEIGHT/SUB_SAMPLERATE
#define SUB_SAMPLE_WIDTH  VID_WIDTH/SUB_SAMPLERATE 

// TODO: use logging lib instead of printf
#define printf(...)

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
#define enc_flush_raw(chan) \
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

inline int __dec_raw_read(streaming chanend ch, char &d) {
    ch :> d;
    return d;
}
#define dec_raw_read(chan) \
    __dec_raw_read(chan, __dec_##chan##_store)
#define dec_with_raw_n_bytes(var, n, chan) \
    for (int i=0; \
         i<n && ((var = __dec_raw_read(chan,__dec_##chan##_store))||1); \
         i++)

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
inline char switch_dir(char from, char to) {
    return from != PREVIOUS ? to == PREVIOUS : to == VERTICAL;
}
inline char calc_dir(char old, char flag) {
    return flag ? (old == PREVIOUS ? VERTICAL : PREVIOUS) : (old == HORIZONTAL ? VERTICAL : HORIZONTAL);
}

/**
 * Variable Initialisation for the compression algorithm
 * dir: horizontal-vertical flag 
 * b: reconstructed picture values
 * c: change value in encoded picture
 * d: distance reconstructed to original
 */
#define cmpr_logic_vars_init() \
    int dir, dir_toggled; \
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
    dir = DEFAULT_HV; \
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
    dir_toggled = 0; \
    if (!dir && abs(dh)<abs(dv)-10) { \
        dir = 1; \
        dir_toggled = 1; \
    } else if (dir && abs(dh) > abs(dv)+10) { \
        dir = 0; \
        dir_toggled = 1; \
    } \
     \
    if (dir) { \
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

#define cmpr3_logic_enc(pixel) \
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
    dir_toggled = 0; \
    if (dir == HORIZONTAL) { \
      d = dh; \
      if(abs(dv) < abs(d)-10) { \
        dir = VERTICAL; \
        dir_toggled = 1; \
        d = dv; \
      } \
      if(abs(dp) < abs(d) - (dir_toggled ? 0 : 10)) { \
        dir = PREVIOUS; \
        dir_toggled = 1; \
        d = dp; \
      } \
    } else if (dir == VERTICAL) { \
      d = dv; \
      if(abs(dh) < abs(d)-10) { \
        dir = HORIZONTAL; \
        dir_toggled = 1; \
        d = dh; \
      } \
      if(abs(dp) < abs(d) - (dir_toggled ? 0 : 10)) { \
        dir = PREVIOUS; \
        dir_toggled = 1; \
        d = dp; \
      } \
    } else if (dir == PREVIOUS) { \
      d = dp; \
      if(abs(dh) < abs(d)-10) { \
        dir = HORIZONTAL; \
        dir_toggled = 1; \
        d = dh; \
      } \
      if(abs(dv) < abs(d) - (dir_toggled ? 0 : 10)) { \
        dir = VERTICAL; \
        dir_toggled = 1; \
        d = dv; \
      } \
    } \
     \
    switch (dir) { \
    case HORIZONTAL: \
        c = ch; \
        b = bh+c; \
        break; \
    case VERTICAL: \
        c = cv; \
        b = bv+c; \
        break; \
    default: \
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
    dir_toggled=0; /*unused*/ \
    dh = 0; /*unused*/ \
    dv = 0; /*unused*/ \
    d = 0; /*unused*/ \
    cf = cf_in; \
    dir = hv_in; \
     \
    bh = buff_hori_b; \
    bv = buff_vert_b[x]; \
    ch = buff_hori_c; \
    cv = buff_vert_c[x]; \
     \
    if (dir) { \
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

                    printf("EC in: px=%d, dir=%d, bv=%d, bh=%d, cv=%d, ch=%d, dv=%d, dh=%d\n", pixel, dir, bv, bh, cv, ch, dv, dh);
                    printf("EC out: dir=%d, cf=%d, c=%d, d=%d, b=%d\n", dir, cf, c, d, b);

                    enc_add(c_out, ((dir<<1)| cf), 2);
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

                    printf("DC in: c=%d, dir=%d, cv=%d, ch=%d, bv=%d, bh=%d\n",
                            cf, dir, buff_vert_c[x], buff_hori_c, buff_vert_b[x], buff_hori_b);
                    printf("DC out: pix=%d, c=%d\n", b, c);

                    vid_put_pixel(c_out, b);
                }
            }
        }
    }
}




// We use something like rle for the dir flag:
// - send c-bits in normal byte stream
// - escape dir-changes:
//   if the dir-flag changes for the next byte of c-data, insert an 0xff 0x..
//   where a bit in 0x.. means, that dir should toggle on that bit.

void cmpr_rle_encode(streaming chanend c_in, streaming chanend c_out) {
    int pixel;
    char hv_enc;

    vid_init(c_in);
    enc_init(c_out);
    cmpr_logic_vars_init();

    vid_with_frames(c_in) {
        int cnt=0;
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

                    printf("EC in: px=%d, dir=%d, bv=%d, bh=%d, cv=%d, ch=%d, dv=%d, dh=%d\n", pixel, dir, bv, bh, cv, ch, dv, dh);
                    printf("EC out: dir=%d, cf=%d, c=%d, d=%d, b=%d\n", dir, cf, c, d, b);

                    hv_enc = (hv_enc<<1) | dir_toggled/**<dir toggle*/;

                    enc_add(c_out, cf, 1);
                }
                if (enc_filled(c_out)) {
                    if (hv_enc) {
                        if (hv_enc == 0xff) hv_enc = 0;
                        printf("EC rle flag set, hv_enc=%x\n", hv_enc);
                        cnt+=2;
                        enc_escape(c_out, hv_enc);
                        hv_enc = 0;
                    }
                    cnt++;
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
                        printf("DC rle toggled dir to %d, v=%d, e=%x\n", hv_flag, hv_valid, hv_enc);
                    }
                    cmpr_logic_dec(cbit, hv_flag);

                    printf("DC in: c=%d, dir=%d, cv=%d, ch=%d, bv=%d, bh=%d\n",
                            cf, dir, buff_vert_c[x], buff_hori_c, buff_vert_b[x], buff_hori_b);
                    printf("DC out: pix=%d, c=%d\n", b, c);

                    vid_put_pixel(c_out, b);
                }
            }
        }
    }
}

void cmpr3_encode(streaming chanend c_in, streaming chanend c_out) {
// what do we need?
// frame counter for sync
// sub sampled image 8x8 4x4?
// dir is now hvp used as horizontal vertical previous flag


// hvp-pixel counter as we submit hvp at the end of each line
// dir-encoding-rle-logic in buffer

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
    
    char        buff_dir[VID_WIDTH];
    int         dir_bin, dir_current, dir_cnt;

    vid_init(c_in);
    enc_init(c_out);
    cmpr_logic_vars_init();

    for (int i=0; i<SUB_SAMPLE_WIDTH; i++)
        new_buff_b[i] = new_buff_c[i] = 0;


    vid_with_frames(c_in) {
        printf("\nEC new frame\n");
        enc_escape(c_out, EncNewFrame);
        // number of pixels per line
        enc_put(c_out, 48);//VID_WIDTH); // FIXME real calculated value !!!!
        // synchronization flag 
        enc_put(c_out, (frames_to_next_sync == 0));
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
        } else {
            frames_to_next_sync--;
        }
        cmpr_logic_frame_init();

        dir_current = dir;

        vid_with_lines(c_in) {
            enc_escape(c_out, EncStartOfLine);
            printf("EC new line\n");
            cmpr_logic_line_init();
            
            dir_bin = 0;
            dir_cnt = 0;

            vid_with_ints(pixel, c_in) {
                vid_with_bytes(pixel, c_in) {
                    cmpr3_logic_enc(pixel); 
                    enc_add(c_out, cf, 1);

                    printf("d%1d ", dir);
                    if (dir_toggled) {
                       buff_dir[dir_bin++] = ((dir_cnt << 1) | switch_dir(dir_current, dir));
                       dir_current = dir;
                       dir_cnt = 1;
                    } else {
                        dir_cnt++;
                        // check against 2^7+1 to avoid problems if hvp toggles 
                        // at next pixel
                        if (dir_cnt == 127) {
                            buff_dir[dir_bin++] = (char) EncEscape;
                            dir_cnt = 0;
                        }
                    }
                    
                    // sub sampling of decoded imate
                    new_buff_b[(x-1)/SUB_SAMPLERATE] += b;
                    if (abs(new_buff_c[(x-1)/SUB_SAMPLERATE]) < abs(c)) new_buff_c[(x-1)/SUB_SAMPLERATE] = c;
                }
                if(enc_filled(c_out)) {
                    enc_flush_raw(c_out);
                }
            }
            buff_dir[dir_bin++] = ((dir_cnt+1) << 1);

            printf("EC hvp\n");
            for(int i = 0; i < dir_bin;i++) {
                enc_put(c_out, buff_dir[i]);
            }
            // sub sampling logic: 'close' sub sampling windows ;)
            if (y % SUB_SAMPLERATE == (SUB_SAMPLERATE-1)) {
                printf("EC subsampling\n");
                for(int i=0; i<SUB_SAMPLE_WIDTH; i++) {
                    buff_prev_c[sub_y][i] = new_buff_c[i];
                    buff_prev_b[sub_y][i] = new_buff_b[i]/(SUB_SAMPLERATE*SUB_SAMPLERATE);
                    new_buff_b[i] = new_buff_c[i] = 0;
                }
            }
            // TODO warning if x does not match expected VID_WIDTH?
        }
        // 
    }
}

//#undef printf
void cmpr3_decode(streaming chanend c_in, streaming chanend c_out) {
    char b_vert_buff[VID_WIDTH]; \
    char b_hori_buff; \
    signed char c_vert_buff[VID_WIDTH]; \
    signed char c_hori_buff; \

    unsigned char b_prev_buff[SUB_SAMPLE_HEIGHT][SUB_SAMPLE_WIDTH];
    signed   char c_prev_buff[SUB_SAMPLE_HEIGHT][SUB_SAMPLE_WIDTH];
    signed   char c_buff[VID_WIDTH/8];

    int c_sampled[SUB_SAMPLE_WIDTH];
    int b_sampled[SUB_SAMPLE_WIDTH];

    unsigned char rle_buff[VID_WIDTH];
    int rle_cnt;
    int x,y, sub_x, sub_y;

    dec_init(c_in);

    for (int i=0; i<SUB_SAMPLE_WIDTH; i++) 
        b_sampled[i] = c_sampled[i] = 0;

    dec_with_frames(c_in) {
        int width = dec_raw_read(c_in);
        char sync = dec_raw_read(c_in);

        char c_flag, c_bin, dir_val, dir_next, rle;

        printf("DC new frame\n", c_flag);

        if (sync) {
            for(int j = 0; j < SUB_SAMPLE_HEIGHT; j++) {
                for( int i = 0; i < SUB_SAMPLE_WIDTH; i++) {
                    c_prev_buff[j][i] = DEFAULT_C;
                    b_prev_buff[j][i] = DEFAULT_PIXEL;
                }
            }
        }
        dir_val = DEFAULT_HV;

        vid_start_frame(c_out);

        for (int i=0; i<VID_WIDTH; i++) {
            b_vert_buff[i] = DEFAULT_PIXEL;
            c_vert_buff[i] = DEFAULT_C;
        }

        y=0;
        sub_y = 0;
        for(dec_raw_read(c_in); dec_raw_read(c_in) == EncStartOfLine; dec_raw_read(c_in)) {
            printf("DC filling c_buff ... \n", c_flag);
            dec_with_raw_n_bytes(c_flag, width/8, c_in) {
                c_buff[i]=c_flag;
            }

            rle_cnt = 0;
            for (int i=0; i<width; i+=rle) {
                rle = dec_raw_read(c_in);
                rle_buff[rle_cnt++] = rle;
                rle = rle >> 1;
            }

            vid_start_line(c_out);

            b_hori_buff = DEFAULT_PIXEL;
            c_hori_buff = DEFAULT_C;

            rle_cnt = 0;

            rle = rle_buff[rle_cnt++];

            dir_next = rle==0xff ? dir_val : calc_dir(dir_val, rle & 0x1);
            rle = rle >> 1;

            x = 0;
            sub_x=0;
            for (int i=0; i<width/8; i++) {
                c_bin = c_buff[i];
                for (int j=0; j<8; j++) {
                    int c, b;
                    c_flag = (c_bin&0xa0) >> 7;
                    c_bin = c_bin << 1;

                    if (rle == 0) {
                        dir_val = dir_next;

                        rle = rle_buff[rle_cnt++];
                        dir_next = rle==0xff ? dir_val : calc_dir(dir_val, rle & 0x1);
                        rle = (rle>>1);
                    }
                    rle--;

                    printf("DC in: c_flag=%d, dir_val=%d\n", c_flag, dir_val);
                    switch(dir_val) {
                    case HORIZONTAL:
                        c = c_hori_buff;
                        b = b_hori_buff + c;
                        break;
                    case VERTICAL:
                        c = c_vert_buff[x];
                        b = b_vert_buff[x] + c;
                        break;
                    case PREVIOUS:
                        c = c_prev_buff[sub_y][sub_x];
                        b = b_prev_buff[sub_y][sub_x] + c;
                        break;
                    }

                    update_c(c, c_flag);

                    vid_put_pixel(c_out, b>0xfd ? 0xfd : b);

                    b_hori_buff = b;
                    c_hori_buff = c;
                    b_vert_buff[x] = b;
                    c_vert_buff[x] = c;
                    b_sampled[sub_x] += b;
                    if (abs(c_sampled[sub_x]) < abs(c)) c_sampled[sub_x] = c;

                    if (!(++x%SUB_SAMPLERATE)) sub_x++;
                }
            }

//#undef printf
            if (!(++y%SUB_SAMPLERATE)) {
                printf("\nsub");
                for(int i=0; i<SUB_SAMPLE_WIDTH; i++) {
                    b_prev_buff[sub_y][i] = b_sampled[i]/(SUB_SAMPLERATE*SUB_SAMPLERATE);
                    c_prev_buff[sub_y][i] = c_sampled[i];
                    printf(".%02x", c_prev_buff[sub_y][i]);
                    b_sampled[i] = c_sampled[i] = 0;
                }
                printf("bus\n");
                sub_y++;
            }
        }
    }
}

