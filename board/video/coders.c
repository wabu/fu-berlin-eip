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

void cmpr3_encoder(chanend cin, chanend cout, int w, int h) {
    cmpr3 c;
    cmpr3 *p = &c;
    int raw;
    int sync, cnt=0;
    
    cmpr3_init(p, w, h, 4);

    for (;;) {
        raw = chan_readi(cin);
        switch (raw) {
        case VID_NEW_FRAME:
            sync = (cnt++%300==0);
            chan_writec(cout, sync ? CMPR_FRAME_SYNC : CMPR_NEW_FRAME);

            cmpr3_start_frame(p, sync);
            break;

        case VID_NEW_LINE:

            chan_writec(cout, CMPR_NEW_LINE);
            cmpr3_start_line(p);
            break;

        default:
            if (!cmpr3_enc_push(p, raw)) {
                int n;
                const char *buf;

                buf = cmpr3_enc_get_cs(p, &n);
                for (int i=0; i<n; i++) {
                    chan_writec(cout, buf[i]);
                }
                buf = cmpr3_enc_get_dirs(p, &n);
                for (int i=0; i<n; i++) {
                    //printf(">>%d:%d", buf[i]>>1, buf[i]&0x1);
                    chan_writec(cout, buf[i]);
                }
            }
            break;
        }
    }
}

void cmpr3_decoder(chanend cin, chanend cout, int w, int h) {
    cmpr3 c;
    cmpr3 *p = &c;

    char enc;
    int state = 0;
    int raw;
    
    cmpr3_init(p, w, h, 4);

    for (;;) {
        enc = chan_readc(cin);
        switch (enc) {
        case CMPR_FRAME_SYNC:
        case CMPR_NEW_FRAME:
            chan_writei(cout, VID_NEW_FRAME);
            cmpr3_start_frame(p, enc == CMPR_FRAME_SYNC);
            break;

        case CMPR_NEW_LINE:
            chan_writei(cout, VID_NEW_LINE);
            cmpr3_start_line(p);

            do {
                enc = chan_readc(cin);
            } while (cmpr3_dec_push_cs(p, enc));
            do {
                enc = chan_readc(cin);
            } while (cmpr3_dec_push_dir(p, enc));

            while (p->x < p->w) {
                raw = cmpr3_dec_pull(p);
                if (raw >= 0xFEFEFEFE)  raw=0xFEFEFEFD;
                chan_writei(cout, raw);
            }
            break;

        default:
            printf("\n!! %x\n", enc);
        }
    }
}


