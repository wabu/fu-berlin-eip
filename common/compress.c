#include <stdlib.h>

#include "compat.h"
#include "compress.h"
#include "config.h"

////
/// cmpr2 Storage Class
//

/**
 * holding state for cmpr encoder/decoder
 */
typedef struct cmpr {
    int w,h;

    int dir;
    int x;

    unsigned char b_hori;
    signed   char c_hori;

    unsigned char b_vert[VID_WIDTH];
    signed   char c_vert[VID_WIDTH];
} cmpr;

/** context for codec comptations */
typedef struct cmpr_context {
    int b_val, b_vert, b_hori;
    int c_vert, c_hori, c_flag, c_val;
    int d_val, d_vert, d_hori;
    int dir;
} cmpr_context;

/**
 * frees resources allocated by p.
 * Note: p itself is not freed
 *
 */
void cmpr_free(cmpr *p) {
    if (!p) return;

    if (p->b_vert) free(p->b_vert);
    if (p->c_vert) free(p->c_vert);

    //p->b_vert = 0;
    //p->c_vert = 0;
}

/** 
 * initialices cmpr struct, frees p on falure
 * @param p pointer to allocated struct
 * TODO docu for w, h
 * @return  p on success, frees p and returns 0 on failure 
 */
cmpr *cmpr_init(cmpr *p, int w, int h) {
    if (!p) 
        return 0;

    //p->b_vert = (unsigned char*)malloc(sizeof(char) * w);
    //p->c_vert = (signed char*)malloc(sizeof(char) * w);

    if (!p->b_vert || !p->c_vert) {
        cmpr_free(p);
        free(p);
        return 0;
    }

    p->w = w;
    p->h = h;

    return p;
}



////
/// cmpr3 Storage Class
//

/**
 * holding state for cmpr3 encoder/decoder. 
 * subclass of cmpr enocder/decoder
 * @see cmpr
 */
typedef struct cmpr3 {
    cmpr super;

    int sub;  /**< subsample rate */
    int sync_cnt, sync_val;     /** syncronistation counter and value */

    unsigned char **b_prev;
    signed char **c_prev;

    unsigned char *b_prevp; /**< pointer to current subsampling b-cell */
    signed char *c_prevp;   /**< pointer to current subsampling c-cell */
} cmpr3;

/** context for codec calculations */
typedef struct cmpr3_context {
    cmpr_context c;
    // TODO: can we use chars for this
    int b_prev, c_prev, d_prev;
} cmpr3_context;

/**
 * frees resources allocated by q.
 * Note: q itself is not freed
 *param q pointer to p struct
 */
void cmpr3_free(cmpr3 *q) {
    if (!q) return;

    cmpr_free(&(q->super));

    if(q->b_prev) free(q->b_prev);
    if(q->c_prev) free(q->c_prev);

    q->b_prev = 0;
    q->c_prev = 0;
}

/** 
 * initialices cmpr struct, frees q on falure
 * @param q pointer to allocated struct
 * @return  q on success, frees p and returns 0 on failure 
 */
cmpr3 *cmpr3_init(cmpr3* q, int w, int h, int sub, int sync) {
    if (!cmpr_init(&(q->super), w, h))
        return 0;

    q->b_prev = malloc(sizeof(char)*w*h/sub/sub);
    q->c_prev = malloc(sizeof(char)*w*h/sub/sub);

    if (!q->b_prev || !q->c_prev) {
        cmpr3_free(q);
        free(q);

        return 0;
    }

    q->sub = sub;
    q->sync_val = sync;
    q->sync_cnt = 0;

    return q;
}

////
/// Codec's Functionality
//


static inline void cmpr_context_load(cmpr *p, cmpr_context *c, int pixel) {
    c->dir = p->dir;
    c->b_vert = p->b_vert[p->x];
    c->b_hori = p->b_hori;

    c->c_vert = p->c_vert[p->x];
    c->c_hori = p->c_hori;

    if (c->c_vert +  c->b_vert <= 0)
        c->c_vert = -c->b_vert;
    if (c->c_hori +  c->b_hori <= 0)
        c->c_hori = -c->b_hori;

    c->d_hori = c->b_hori + c->c_hori - pixel;
    c->d_vert = c->b_vert + c->c_vert - pixel;
}

static inline void cmpr_context_update_c(cmpr_context *ctx) {
    int *c = &(ctx->c_val);
    if (ctx->c_flag) {
        (*c) = (*c) + (*c)/2;
    } else {
        (*c) = -(*c);
        if ( abs(*c)>=CMPR_C_MIN*2) (*c)=(*c)/2;
    }
}


static inline void cmpr_context_select_dir(cmpr_context *c) {
    switch (c->dir) {
    case HORIZONTAL:
        c->d_val = c->d_hori;
        c->c_val = c->c_hori;
        c->b_val = c->b_hori + c->c_hori;
        break;

    case VERTICAL:
        c->d_val = c->d_vert;
        c->c_val = c->c_vert;
        c->b_val = c->b_vert + c->c_vert;
        break;
    }
}

static inline void cmpr_context_store(cmpr *p, cmpr_context *c) {
    p->b_vert[p->x] = c->b_val;
    p->b_hori = c->b_val;
    p->c_vert[p->x] = c->c_val;
    p->c_hori = c->c_val;
    p->dir = c->dir;
}



////
/// Interface Implementation
//

cmpr_ref cmpr_create(int w, int h) {
    cmpr_ref ref; 
    cmpr *p;

    p = (cmpr*)malloc(sizeof(cmpr));
    ref.p = (int)cmpr_init(p, w, h);

    return ref;
}

void cmpr_delete(cmpr_ref ref) {
    if (!ref.p) return;
    cmpr_free((cmpr*)ref.p);
    free((cmpr*)ref.p);
    ref.p = 0;
}

cmpr3_ref cmpr3_create(int w, int h, int sub, int sync) {
    cmpr3_ref ref; 
    cmpr3 *p; 

    p = (cmpr3*)malloc(sizeof(cmpr3));
    ref.p = (int)cmpr3_init(p, w, h, sub, sync);

    return ref;
}

void cmpr3_delete(cmpr3_ref ref) {
    if (!ref.p) return;
    cmpr3_free((cmpr3*)ref.p);
    free((cmpr3*)ref.p);
    ref.p = 0;
}

void cmpr_start_frame(cmpr *const p) {
    p->dir = CMPR_HV_DEFAULT;

    for (int i=0; i<p->w; i++) {
        p->b_vert[i] = CMPR_B_DEFAULT;
        p->c_vert[i] = CMPR_C_DEFAULT;
    }
}
void cmpr_start_line(cmpr *const p) {
    p->b_hori = CMPR_B_DEFAULT;
    p->c_hori = CMPR_C_DEFAULT;

    p->x = 0;
}

static inline char cmpr_enc(cmpr *const p, int raw) {
    cmpr_context c;
    char out;

    for (int valid=32, pixel = (raw >> (valid-=8)) & 0xff;
             valid>=0; pixel = (raw >> (valid-=8)) & 0xff) {

        cmpr_context_load(p, &c, pixel);

        if (c.dir == VERTICAL && abs(c.d_hori) < abs(c.d_vert)+CMPR_CHANGE_BIAS) {
            c.dir = HORIZONTAL;
        } else 
        if (c.dir == HORIZONTAL && abs(c.d_vert) < abs(c.d_hori)+CMPR_CHANGE_BIAS) {
            c.dir = VERTICAL;
        }
        
        cmpr_context_select_dir(&c);

        c.c_flag = (c.d_val * c.c_val < 0);

        cmpr_context_update_c(&c);

        cmpr_context_store(p, &c);

        out <<= 2;
        out |= (c.dir<<1) | c.c_flag;

        p->x++;
    }
    return out;
}

static inline int cmpr_dec(cmpr *const p, char enc) {
    int out = 0;
    cmpr_context c;

    for (int valid= 8, ch = (enc >> (valid-=2));
             valid>=0; ch = (enc >> (valid-=2))) {
        c.c_flag = ch & 0x1;
        c.dir    = (ch>>1) & 0x1;
        
        cmpr_context_load(p, &c, 0);
	cmpr_context_select_dir(&c);

        //printf("(%d,%d:%d)", dir, c_flag, c_val);

        out <<= 8;
        out |= c.b_val;

        cmpr_context_update_c(&c);
        cmpr_context_store(p, &c);

        p->x++;
    }

    return out;
}

void cmpr_encoder(streaming chanend cin, streaming chanend cout) {
    cmpr c;
    cmpr *p = cmpr_init(&c, VID_WIDTH, VID_HEIGHT);

    int raw;
    char enc;

    for (;;) {
        raw = creadi(cin);
        switch (raw) {
            case VID_NEW_FRAME:
                cwritec(cout, CMPR_ESCAPE);
                cwritec(cout, CMPR_NEW_FRAME);
                cmpr_start_frame(p);
                break;
            case VID_NEW_LINE:
                cwritec(cout, CMPR_ESCAPE);
                cwritec(cout, CMPR_NEW_LINE);
                cmpr_start_line(p);
                break;
            default:
                enc = cmpr_enc(p, raw);
                if (enc == CMPR_ESCAPE) { 
                    cwritec(cout, CMPR_ESCAPE);
                }
                cwritec(cout, enc);
                break;
        }
    }
}

void cmpr_decoder(streaming chanend cin, streaming chanend cout) {
    cmpr c;
    cmpr *p = cmpr_init(&c, VID_WIDTH, VID_HEIGHT);
    int raw;
    char enc;

    for (;;) {
        enc = creadc(cin);
        if (enc == CMPR_ESCAPE) {
            enc = creadc(cin);
            switch (enc) {
            case CMPR_NEW_FRAME:
                cwritei(cout, VID_NEW_FRAME);
                cmpr_start_frame(p);
                continue;
            case CMPR_NEW_LINE:
                cwritei(cout, VID_NEW_LINE);
                cmpr_start_line(p);
                continue;
            }
        }

        raw = cmpr_dec(p, enc);
        cwritei(cout, raw);
    }
}


inline void cmpr3_enc_push(cmpr3_ref ref, int raw);
inline void cmpr3_enc_finish_line(cmpr3_ref ref);
inline int cmpr3_enc_pull(cmpr3_ref ref, char *enc);
inline void cmpr3_enc_finish_fame(cmpr3_ref ref);


