#include <stdlib.h>

#include "compress.h"
#include "config.h"

inline int update_c(int *c, const int incr_flag) {
    if (incr_flag) {
        *c = *c+*c/2;
    } else {
        *c=-*c;
        if (abs(*c)>=CMPR_C_MIN*2) *c=*c/2;
    }
    return incr_flag;
}


typedef struct cmpr {
    int w,h;
    int x,y;

    int dir;

    unsigned char *b_vert;
    unsigned char b_hori;

    signed char *c_vert;
    signed char c_hori;
} cmpr;

cmpr_ref cmpr_create(int w, int h) {
    cmpr_ref ref; 
    cmpr *p;

    ref.p = (cmpr*)malloc(sizeof(cmpr));
    if (!ref.p)
        return ref;

    p = ref.p;

    p->b_vert = (unsigned char*)malloc(sizeof(char) * w);
    p->c_vert = (signed char*)malloc(sizeof(char) * w);

    if (!p->b_vert || !p->c_vert) {
        if (p->b_vert) free(p->b_vert);
        if (p->c_vert) free(p->c_vert);
        free(p);
        ref.p = 0;
        return ref;
    }

    p->w = w;
    p->h = h;

    return ref;
}

void cmpr_delete(cmpr_ref ref) {
    free(ref.p);
    ref.p = 0;
}

__inline__ void cmpr_start_frame(cmpr_ref ref) {
    cmpr *p = ref.p;

    p->dir = CMPR_HV_DEFAULT;
    p->y = -1;

    for (int i=0; i<p->w; i++) {
        p->b_vert[i] = CMPR_B_DEFAULT;
        p->c_vert[i] = CMPR_C_DEFAULT;
    }
}
__inline__ void cmpr_start_line(cmpr_ref ref) {
    cmpr *p = ref.p;

    p->b_hori = CMPR_B_DEFAULT;
    p->c_hori = CMPR_C_DEFAULT;

    p->x = 0;
    p->y++;
}

__inline__ char cmpr_enc(cmpr_ref ref, int raw) {
    char out = 0;
    cmpr *p = ref.p;

    for (int valid=32, pixel = (raw >> (valid-=8)) & 0xff;
             valid>=0; pixel = (raw >> (valid-=8)) & 0xff) {
        int d,c,b, cf;
        int bv = p->b_vert[p->x];
        int bh = p->b_hori;

        int cv = p->c_vert[p->x];
        int ch = p->c_hori;

        int dh = bh+ch - pixel;
        int dv = bv+cv - pixel;

        if (p->dir == VERTICAL && abs(dh) < abs(dv)+CMPR_CHANGE_BIAS) {
            p->dir = HORIZONTAL;
        } else 
        if (p->dir == HORIZONTAL && abs(dv) < abs(dh)+CMPR_CHANGE_BIAS) {
            p->dir = VERTICAL;
        }

        if (p->dir == HORIZONTAL) {
            d = dh;
            c = ch;
            b = bh+c;
        } else {
            d = dv;
            c = cv;
            b = bv+c;
        }

        cf = update_c(&c, (d*c<0));

        out <<= 2;
        out |= (p->dir<<1) || cf;
        
        p->b_vert[p->x] = b;
        p->b_hori = b;
        p->c_vert[p->x] = c;
        p->c_hori = c;

        p->x++;
    }

    return out;
}

__inline__ int  cmpr_dec(cmpr_ref ref, char enc) {
    int out = 0;
    cmpr *p = ref.p;

    for (int valid= 8, ch = (enc >> (valid-=2));
             valid>=0; ch = (enc >> (valid-=2))) {
        int c,b;
        int cf =  ch & CMPR_C_BIT_MASK;
        int dir = ch & CMPR_H_BIT_MASK;

        int bv = p->b_vert[p->x];
        int bh = p->b_hori;

        int cv = p->c_vert[p->x];
        int ch = p->c_hori;

        if (dir == HORIZONTAL) {
            c = ch;
            b = bh+c;
        } else {
            c = cv;
            b = bv+c;
        }

        out <<= 8;
        out |= b;

        update_c(&c, cf);

        p->dir = dir;

        p->b_vert[p->x] = b;
        p->b_hori = b;
        p->c_vert[p->x] = c;
        p->c_hori = c;

        p->x++;
    }

    return out;
}


typedef struct cmpr3 {
} cmpr3;

cmpr3_ref cmpr3_init(int w, int h, int sync);
void cmpr3_delete(cmpr3_ref ref);

__inline__ void cmpr3_enc_push(cmpr3_ref ref, int raw);
__inline__ void cmpr3_enc_finish_line(cmpr3_ref ref);
__inline__ int cmpr3_enc_pull(cmpr3_ref ref, char *enc);
__inline__ void cmpr3_enc_finish_fame(cmpr3_ref ref);


