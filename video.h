#define VID_NEW_FRAME 0xFEFEFEFE
#define VID_NEW_LINE  0xFFFFFFFF

#define VID_WIDTH     240
#define VID_HEIGHT    180


#define vid_init(chan) \
    int __vid_##chan##_store = 0; \
    int __vid_##chan##_valid = 0

#define vid_fill(chan) __vid_fill(chan, __vid_##chan##_store, __vid_##chan##_valid)
__inline__ int __vid_fill(streaming chanend ch, int &st, int &vl) {
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

#define vid_read_byte(chan) \
    __vid_read_byte(chan, __vid_##chan##_store, __vid_##chan##_valid); \
    switch(__vid_##chan##_store)
__inline__ int __vid_read_byte(streaming chanend ch, int &st, int &vl) {
    if (vl<8 && __vid_fill(ch, st, vl)<0) {
        return st;
    }
    return (st>>(vl-=8))&0xff;
}

#define vid_next_byte(chan) \
    ((__vid_##chan##_valid >= 8) \
    ? ((__vid_##chan##_store >> (__vid_##chan##_valid-=8)) & 0xff) \
    : __vid_##chan##_store )


#define vid_with_frames(chan) \
    while (__vid_##chan##_store!=VID_NEW_FRAME) { chan:>__vid_##chan##_store; } \
    for (;;)

#define vid_with_lines(chan) \
    for (chan:>__vid_##chan##_store; __vid_##chan##_store != VID_NEW_FRAME; )

#define vid_with_bytes(var, chan) \
    for (chan:>__vid_##chan##_store; __vid_##chan##_store!=VID_NEW_FRAME && __vid_##chan##_store != VID_NEW_LINE; chan:>__vid_##chan##_store) \
    for (__vid_##chan##_valid=32, var = ((__vid_##chan##_store >> (__vid_##chan##_valid-=8)) & 0xff);\
         __vid_##chan##_valid>=0; var = ((__vid_##chan##_store >> (__vid_##chan##_valid-=8)) & 0xff))
#define vid_with_ints(var, chan) \
    for (chan:>__vid_##chan##_store, var=__vid_##chan##_store; \
         __vid_##chan##_store!=VID_NEW_FRAME && __vid_##chan##_store != VID_NEW_LINE; \
         chan:>__vid_##chan##_store, var=__vid_##chan##_store) \

