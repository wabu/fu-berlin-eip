#define rd_init(chan) \
    int __rd_##chan##_store = 0; \
    int __rd_##chan##_valid = 0

#define rd_fill(chan) __rd_fill(chan, __rd_##chan##_store, __rd_##chan##_valid)
__inline__ int __rd_fill(streaming chanend ch, int &st, int &vl) {
    ch:>st;
    switch(st) {
    case VID_NEW_FRAME:
        vl=-2;
        break;
    case VID_NEW_LINE:
        vl=-1;
        break;
    default:
        vl=32;
        break;
    }
    return vl;
}

#define rd_read_byte(chan) \
    __rd_read_byte(chan, __rd_##chan##_store, __rd_##chan##_valid); \
    switch(__rd_##chan##_store)
__inline__ int __rd_read_byte(streaming chanend ch, int &st, int &vl) {
    if (vl<8 && __rd_fill(ch, st, vl)<0) {
        return st;
    }
    return (st>>(vl-=8))&0xff;
}

#define rd_next_byte(chan) \
    ((__rd_##chan##_valid >= 8) \
    ? ((__rd_##chan##_store >> (__rd_##chan##_valid-=8)) & 0xff) \
    : __rd_##chan##_store )


#define rd_with_frames(chan) \
    while (__rd_##chan##_store!=VID_NEW_FRAME) { chan:>__rd_##chan##_store; } \
    for (;;)

#define rd_with_lines(chan) \
    for (chan:>__rd_##chan##_store; __rd_##chan##_store != VID_NEW_FRAME; )

#define rd_with_bytes(var, chan) \
    for (chan:>__rd_##chan##_store; __rd_##chan##_store!=VID_NEW_FRAME && __rd_##chan##_store != VID_NEW_LINE; chan:>__rd_##chan##_store) \
    for (__rd_##chan##_valid=32, var = ((__rd_##chan##_store >> (__rd_##chan##_valid-=8)) & 0xff);\
         __rd_##chan##_valid>=0; var = ((__rd_##chan##_store >> (__rd_##chan##_valid-=8)) & 0xff))
#define rd_with_ints(var, chan) \
    for (chan:>__rd_##chan##_store, var=__rd_##chan##_store; \
         __rd_##chan##_store!=VID_NEW_FRAME && __rd_##chan##_store != VID_NEW_LINE; \
         chan:>__rd_##chan##_store, var=__rd_##chan##_store) \



#define wt_init(chan, esc) \
    char __wt_##chan##_esc = esc; \
    char __wt_##chan##_store = 0; \
    char __wt_##chan##_valid = 0

__inline__ void __wt_bit(streaming chanend ch, int b, char &s, char &v, char &esc) {
    s <<= 1;
    s |= b&0x1;
    v++;

    if (v==8) {
        if (s == esc)
            ch <: esc;
        ch <: s;
        v = 0;
    }
}
#define wt_bit(chan, b) __wt_bit(chan, b, __wt_##chan##_store, __wt_##chan##_valid, __wt_##chan##_esc)
#define wt_flush(chan) \
    if (__wt_##chan##_valid) { chan <: __wt_##chan##_store; __wt_##chan##_valid=0; }
#define wt_put(chan, val) \
    chan <: (char)val;
#define wt_escape(chan, val) \
    chan <: (char)__wt_##chan##_esc; chan <: (char)val;
