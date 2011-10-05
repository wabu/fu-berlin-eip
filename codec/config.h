/** @file config.h
 * the defined values for WIDTH/HEIGHT are the maximum values allow
 * it's no problem if you use smaller pictures, it only vastes some memory
 */

#define VID_WIDTH     160
#define VID_HEIGHT    120
#define VID_FRAMERATE  30
#define VID_REFRATE    (5*VID_FRAMERATE)

#define SUB_WIDTH   (VID_WIDTH/4)
#define SUB_HEIGHT  (VID_WIDTH/4)

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


