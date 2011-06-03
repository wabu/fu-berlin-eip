#define rd_init(chan) \
    int __rd_##chan##_store = 0; \
    int __rd_##chan##_valid = 0;

inline static int rd_byte(streaming chanend ch, int &st, int &vl) {
    if (vl<8) {
        ch:>st;
        switch(st) {
        case VID_NEW_FRAME:
        case VID_NEW_LINE:
            vl=0;
            return 0;
        default:
            vl=32;
            break;
        }
    }
    return (st>>(vl-=8))&&0xff;
}

/* int val = rd_read_byte(chan) {
 * case VID_NEW_FRAME:
 * case VID_NEW_LINE:
 *     break;
 * default:
 *     // do something with val
 *     break;
 * } 
 */
#define rd_read_byte(chan) \
    rd_byte(chan, __rd_##chan##_store, __rd_##chan##_valid); \
    switch(__rd_##chan##_store)


/* rd_with_frames(chan) {
 *   rd_with_lines(chan) {
 *     rd_with_bytes(var, chan) {
 *       // do something with var
 *     }
 *   }
 * }
 */
#define rd_with_frames(chan) \
    while (__rd_##chan##_store!=VID_NEW_FRAME) { chan:>__rd_##chan##_store; } \
    for (;;)
#define rd_with_lines(chan) \
    for (chan:>__rd_##chan##_store; __rd_##chan##_store != VID_NEW_FRAME; )
#define rd_with_bytes(var, chan) \
    for (chan:>__rd_##chan##_store; __rd_##chan##_store!=VID_NEW_FRAME && __rd_##chan##_store != VID_NEW_LINE; chan:>__rd_##chan##_store) \
    for (__rd_##chan##_valid=32, var = ((__rd_##chan##_store >> (__rd_##chan##_valid-=8)) & 0xff);\
         __rd_##chan##_valid>=0; var = ((__rd_##chan##_store >> (__rd_##chan##_valid-=8)) & 0xff))

