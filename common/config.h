#define VID_WIDTH     160
#define VID_HEIGHT    120
#define VID_RATE       30

#define VID_NEW_FRAME 0xFEFEFEFE
#define VID_NEW_LINE  0xFFFFFFFF

#define CMPR_NEW_FRAME      0xfd
#define CMPR_NEW_LINE       0xfe
#define CMPR_ESCAPE         0xff
#define CMPR_NEW_BITS       0x00

#define CMPR_C_DEFAULT      32
#define CMPR_C_MIN          2
#define CMPR_B_DEFAULT      32
#define CMPR_HV_DEFAULT     HORIZONTAL
#define CMPR_HVP_DEFAULT    HORIZONTAL

#ifndef CMPR_CHANGE_BIAS
#define CMPR_CHANGE_BIAS    10
#endif

#ifndef SYNC_INTERVAL
#define SYNC_INTERVAL   50
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
#define CMPR_H_BIT_MASK      0x02


