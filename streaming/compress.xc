#include "video.h"
#include "compress.h"

#include "../common/compress.h"

#include <string.h>
#include <stdio.h>

// TODO: use logging lib instead of printf
#define printf(...)

#define enc_init(chan) \
    char __enc_##chan##_store = 0; \
    int  __enc_##chan##_valid = 0
#define enc_put(chan, val) \
    if (val == EncEscape) chan <: (char)EncEscape; \
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

void cmpr_encode(streaming chanend c_in, streaming chanend c_out) {
    cmpr_ref r = cmpr_create(VID_WIDTH, VID_HEIGHT);

    int raw;
    vid_init(c_in);
    enc_init(c_out);

    vid_with_frames(c_in) {
        cmpr_start_frame(r);
        enc_escape(c_out, EncNewFrame);

        vid_with_lines(c_in) {
            int i = 0;
            cmpr_start_line(r);
            enc_escape(c_out, EncStartOfLine);

            vid_with_ints(raw, c_in) {
                char enc = cmpr_enc(r, raw);
                enc_put(c_out, enc);
            }
        }
    }
}

void cmpr_decode(streaming chanend c_in, streaming chanend c_out) {
    cmpr_ref r = cmpr_create(VID_WIDTH, VID_HEIGHT);

    int bits;
    dec_init(c_in);

    dec_with_frames(c_in) {
        cmpr_start_frame(r);
        vid_start_frame(c_out);

        dec_with_lines(c_in) {
            cmpr_start_line(r);
            vid_start_line(c_out); 

            dec_with_bytes(bits, c_in) {
                int raw = cmpr_dec(r, bits);
                vid_put_raw(c_out, raw);
            }
        }
    }
}
