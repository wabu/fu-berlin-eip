#include <config.h>

#include <codec.h>
#include <channel.h>

#include "video.h"

void cmpr_encoder(chanend cin, chanend cout, int w, int h) {
    cmpr c;
    cmpr *p = &c;
    
    cmpr_init(p, w, h);

    int raw;
    char enc;

    for (;;) {
        raw = chan_readi(cin);
        switch (raw) {
            case VID_NEW_FRAME:
                chan_writec(cout, CMPR_ESCAPE);
                chan_writec(cout, CMPR_NEW_FRAME);
                cmpr_start_frame(p);
                break;
            case VID_NEW_LINE:
                chan_writec(cout, CMPR_ESCAPE);
                chan_writec(cout, CMPR_NEW_LINE);
                cmpr_start_line(p);
                break;
            default:
                enc = cmpr_enc(p, raw);
                if (enc == CMPR_ESCAPE) { 
                    chan_writec(cout, CMPR_ESCAPE);
                }
                chan_writec(cout, enc);
                break;
        }
    }
}

void cmpr_decoder(chanend cin, chanend cout, int w, int h) {
    cmpr c;
    cmpr *p = &c;

    cmpr_init(&c, w, h);

    int raw;
    char enc;

    for (;;) {
        enc = chan_readc(cin);
        if (enc == CMPR_ESCAPE) {
            enc = chan_readc(cin);
            switch (enc) {
            case CMPR_NEW_FRAME:
                chan_writei(cout, VID_NEW_FRAME);
                cmpr_start_frame(p);
                continue;
            case CMPR_NEW_LINE:
                chan_writei(cout, VID_NEW_LINE);
                cmpr_start_line(p);
                continue;
            }
        }

        raw = cmpr_dec(p, enc);
        chan_writei(cout, raw);
    }
}
