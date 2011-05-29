#ifndef COMPRESS_H
#define COMPRESS_H
/**
 *
 */
enum EncSpecialChar {
    EncEscape=0xff,
    EncNewLine=0xfe,
    EncNewFrame=0xfd,
    EncNewBits
};
/**
 * 
 *
 */
void cmpr_decode(streaming chanend c_in, streaming chanend c_out);

void cmpr_decode(streaming chanend c_in, streaming chanend c_out);

#endif
