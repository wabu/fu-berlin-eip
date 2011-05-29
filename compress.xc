
#include "compress.h"

/**
 *
 * @return {c, h} values
 */
{char, char} read_bits(int &off, int &data, streaming chanend c_in) {
    if (off==0) {
        char in;

        c_in :> in;
        data = in;

        if (data == EncEscape) {
            c_in :> in;
            switch(in) {
              case EncEscape:
                data = in;
                off = 8;
                /* read from data and return values after switch */
                break;
              case EncNewLine:  return {0, EncNewLine};
              case EncNewFrame: return {0, EncNewFrame};
              case:
                data = (data << 8) | in;
                off = 16;
                break;
            }
        } else {
            off = 8;
        }
    }
    off -= 2;
    return {(data >> off) & 0x02, NewBits};
}


void compr_decode(streaming chanend c_in, streaming chanend c_out) {


}
