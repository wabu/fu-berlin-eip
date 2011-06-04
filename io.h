#define rd_init(chan) \
    int __rd_##chan##_store = 0; \
    int __rd_##chan##_valid; \
    __rd_##chan##_valid=0;

#define rd_fill(chan) __rd_fill(chan, __rd_##chan##_store, __rd_##chan##_valid)
inline static int __rd_fill(streaming chanend ch, int &st, int &vl) {
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

