/** @file config.h
 */

#ifndef VID_WIDTH
#define VID_WIDTH     160
#endif
#ifndef VID_HEIGHT
#define VID_HEIGHT    120
#endif

#define VID_FRAMERATE  20
#define VID_REFRATE    (5*VID_FRAMERATE)

#define SUB_WIDTH   (VID_WIDTH/4)
#define SUB_HEIGHT  (VID_WIDTH/4)

#define VID_NEW_FRAME 0xFEFEFEFE
#define VID_NEW_LINE  0xFFFFFFFF

#define CMPR_ESCAPE     0xFF
#define CMPR_NEW_LINE   0xFE
#define CMPR_NEW_FRAME  0xFD
#define CMPR_FRAME_SYNC 0xFF

#define CMPR_C_DEFAULT      32
#define CMPR_C_MIN          2
#define CMPR_B_DEFAULT      32
#define CMPR_HV_DEFAULT     HORIZONTAL
#define CMPR_HVP_DEFAULT    PREVIOUS

#ifndef CMPR_CHANGE_BIAS
#define CMPR_CHANGE_BIAS    13
#endif

#ifndef SUB_SAMPLERATE
#define SUB_SAMPLERATE  8
#endif

enum CmprHVP {
    VERTICAL   = 0,
    HORIZONTAL = 1,
    PREVIOUS   = 2
};

#define CMPR_C_BIT_MASK      0x01
#define CMPR_D_BIT_MASK      0x02


