#define VID_NEW_FRAME 0xFEFEFEFE
#define VID_NEW_LINE  0xFFFFFFFF

#define VID_WIDTH     160
#define VID_HEIGHT    120

#define chan_init(name, type, chan) \
    type __##name##_##chan##_type = 0; \
    type __##name##_##chan##_store = 0; \
    int __##name##_##chan##_valid = 0

#define vid_init(chan) \
    int __vid_##chan##_store = 0; \
    int __vid_##chan##_valid = 0

#define vid_with_frames(chan) \
    while (__vid_##chan##_store!=VID_NEW_FRAME) { chan:>__vid_##chan##_store; } \
    for (;;)

#define vid_with_lines(chan) \
    for (chan:>__vid_##chan##_store; __vid_##chan##_store != VID_NEW_FRAME; )

#define vid_with_ints(var, chan) \
    for (__vid_##chan##_valid=0, chan:>__vid_##chan##_store, var=__vid_##chan##_store; \
         __vid_##chan##_store!=VID_NEW_FRAME && __vid_##chan##_store != VID_NEW_LINE; \
         chan:>__vid_##chan##_store, var=__vid_##chan##_store)
#define vid_with_bytes(var, chan) \
    for (__vid_##chan##_valid=32, var = ((__vid_##chan##_store >> (__vid_##chan##_valid-=8)) & 0xff);\
         __vid_##chan##_valid>=0; var = ((__vid_##chan##_store >> (__vid_##chan##_valid-=8)) & 0xff))


#define vid_start_frame(chan) chan <: VID_NEW_FRAME
#define vid_start_line(chan) chan <: VID_NEW_LINE
#define vid_put_pixel(chan, val) chan <: (char)(val)
