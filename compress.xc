#include "video.h"
#include "compress.h"
#include <string.h>

enum PixelType {
    NewFrame,
    NewLine,
    NewPixel,
};

inline int abs(int a) {
    return a>=0 ? a : -a;
}
/**
 * update logic for 'c'
 */
inline void update_c(char &c, const int incr_flag) {
    if (incr_flag) {
        c = c+c/2;
    } else {
        c=-c;
        if (abs(c)>=2) c=c/2;
    }
}

{int, int} read_pix(int &off, int &data, streaming chanend c_in) {
    if (off==0) {
        c_in :> data;
        if (data == VID_NEW_FRAME) {
            return {0, NewFrame};
        } else if (data == VID_NEW_LINE) {
            return {0, NewLine};
        }
        off = 32;
    }
    off -= 8;
    return {(data >> off) & 0xff, NewPixel};
}

/**
 * 
 *
 * @return {bits, type_flag}
 */
{char, char} read_bits(int &off, int &data, streaming chanend c_in) {
    if (off==0) {
        char inData = 0;

        c_in :> inData;
        data = inData;

        if (data == EncEscape) {
            c_in :> inData;
            switch(inData) {
              case EncEscape:
                data = inData;
                off = 8;
                /* read from data and return values after switch */
                break;
              case EncStartOfLine:  return {0, EncStartOfLine};
              case EncNewFrame: return {0, EncNewFrame};
              default:
                data = (data << 8) | inData;
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


void cmpr_encode(streaming chanend c_in, streaming chanend c_out) {
    int off=0, data=0;
    int p, t, b, d;
    int bv, bh, cv, ch, hv;
    int dh, dv;

    char buff_b_vert[VID_WIDTH/*/n*/]; // no dynamic memory ... :/
    char buff_b_hori;
    char buff_c_vert[VID_WIDTH/*/n*/];
    char buff_c_hori;
    char c;

    int x=0; // offset for downsampled buff_vert

    char n=0;
    char send=0;

    while (1) {
        {p, t} = read_pix(off, data, c_in);

        switch (t) {
        case NewPixel:
            bv = buff_b_vert[x];
            bh = buff_b_hori;
            cv = buff_c_vert[x];
            ch = buff_c_hori;

            dh = bh+ch-p;
            dv = bv+cv-p;

            if (hv && abs(dh)<abs(dv)-10) {
                hv = 0;
            } else if (!hv && abs(dh) > abs(dv)+10) {
                hv = 1;
            }

            // send
            send |= hv;
            send <<= 1;
            ++n;

            if (hv==0) {
                d = dh;
                c = ch;
                b = bh+c;
            } else {
                d = dv;
                c = cv;
                b = bv+c;
            }

            if (c==0) c=1;
            send |= !(d*c > 0);
            update_c(c, send & 1);

            // magic number 8bit=1byte 
            if (++n==sizeof(send)*8) {
                if (send == EncEscape) c_out <: EncEscape;
                c_out <: send;
                n=0;
            }
            send <<= 1;

            buff_b_vert[x++] = b;
            buff_b_hori = b;
            buff_c_vert[x] = c;
            buff_c_hori = c;
            break;

        case NewLine:
            x = 0;

            if (n) { // send remaining data
                c_out <: send;
                send <<= 1;
                n=0;
            }

            c_out <: EncStartOfLine;

            buff_b_hori = DEFAULT_PIXEL;
            buff_c_hori = DEFAULT_C;
            break;

        case NewFrame:
            if (n) { // send remaining data
                c_out <: (char)(send<<(8-n));
                send <<= 1;
                n=0;
            }

            c_out <: EncNewFrame;

            for (int i=0; i<VID_WIDTH; i++) {
                buff_b_vert[i] = DEFAULT_PIXEL;
                buff_c_vert[i] = DEFAULT_C;
            }
            break;
        }
    }
}


void cmpr_decode(streaming chanend c_in, streaming chanend c_out) {
    int data = 0, off = 0, x;
    /* values derived from stream */
    char bits, ret_type, hv, c_flag;
    /* some buffers */
    // rebuild image
    char buff_pixel_verti[VID_WIDTH];
    char buff_pixel_hori, pixel;
    // history 'c'
    char buff_c_verti[VID_WIDTH];
    char buff_c_hori;
    char c = 1;

    /* read from input stream */
    while(1) {
        {bits, ret_type} = read_bits(off, data, c_in);
        
        switch(ret_type) {
        case EncNewFrame:
            /* fill history buffers with default values, cause there
             * is no reference in first line of image                    */
            for(int i=0; i < VID_WIDTH; i++) {
                buff_c_verti[x]      = DEFAULT_C;
                buff_pixel_verti[x]  = DEFAULT_PIXEL;
            }
            c_out <: NewFrame;
            break;
        case EncStartOfLine:
            x = 0;
            /* horizontal reference is black */
            buff_pixel_hori = DEFAULT_PIXEL;
            buff_c_hori     = DEFAULT_C;
            c_out <: NewLine;
            break;
        case NewBits:
            c_flag = bits & C_BIT_MASK;
            hv     = bits & H_BIT_MASK;
            /* horizontal vertical flag: 0=horizontal 1=vertical */
            if (hv) {
                c = buff_c_verti[x];
                pixel = buff_pixel_verti[x] + c;
            } else {
                c = buff_c_hori;
                pixel = buff_pixel_hori + c; 
            }
            /* update c depends on c_flag */
            update_c(c, c_flag);

            /* update buffers */
            buff_c_verti[x] = c;
            buff_c_hori = c;
            buff_pixel_verti[x] = pixel;
            buff_pixel_hori = pixel;
            x++;
            break;
        }

    }

}
