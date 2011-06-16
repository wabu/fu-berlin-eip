#ifndef COMPRESS_H
#define COMPRESS_H

#define C_BIT_MASK      0x01
#define H_BIT_MASK      0x02

#define DEFAULT_C       32
#define MIN_C           2
#define DEFAULT_PIXEL   DEFAULT_C
#define DEFAULT_HV      1

enum EncSpecialChar {
    /* markups */
    NewBits=0x0,
    EncEscape=0xff,
    EncStartOfLine=0xfe,
    EncNewFrame=0xfd,
    /* instead of #DEFINE */
 //   C_BIT_MASK = 0x01,
 //   H_BIT_MASK = 0x02
};
/**
 * 
 *
 */
void cmpr_encode(streaming chanend c_in, streaming chanend c_out);
void cmpr_decode(streaming chanend c_in, streaming chanend c_out);

void cmpr_rle_encode(streaming chanend c_in, streaming chanend c_out);
void cmpr_rle_decode(streaming chanend c_in, streaming chanend c_out);

#endif
