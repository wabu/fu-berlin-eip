#include <stdlib.h>

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
    int x,y;

    int dir;

    unsigned char *b_vert;
    unsigned char b_hori;

    signed char *c_vert;
    signed char c_hori;
} cmpr;


/**
 * frees resources allocated by p.
 * Note: p itself is not freed
 * \param p pointer to p struct
 */
void cmpr_free(cmpr *p) {
    if (!p) return;

    if (p->b_vert) free(p->b_vert);
    if (p->c_vert) free(p->c_vert);

    p->b_vert = 0;
    p->c_vert = 0;
}

/** 
 * initialices cmpr struct, frees p on falure
 * @param p pointer to allocated struct
 * @return  p on success, frees p and returns 0 on failure 
 */
cmpr *cmpr_init(cmpr *p, int w, int h) {
    if (!p) 
        return 0;

    p->b_vert = (unsigned char*)malloc(sizeof(char) * w);
    p->c_vert = (signed char*)malloc(sizeof(char) * w);

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

/**
 * frees resources allocated by q.
 * Note: q itself is not freed
 * \param q pointer to p struct
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

inline int update_c(int *c, const int incr_flag) {
    if (incr_flag) {
        *c = *c+*c/2;
    } else {
        *c=-*c;
        if (abs(*c)>=CMPR_C_MIN*2) *c=*c/2;
    }
    return incr_flag;
}

inline void cmpr_context_load(cmpr *p, compr_context *c, int pixel) {
    c->bv = p->b_vert[p->x];
    c->bh = p->b_hori;

    c->cv = p->c_vert[p->x];
    c->ch = p->c_hori;

    c->dh = c->bh+c->ch - pixel;
    c->dv = c->bv+c->cv - pixel;
}

inline void cmpr_context_select_dir(cmpr *p, compr_context *c) {
	switch (p->dir) {
	case HORIZONTAL:
        c->d = c->dh;
        c->c = c->ch;
        c->b = c->bh+c->c;
		break;
	case VERTICAL:
        c->d = c->dv;
        c->c = c->cv;
        c->b = c->bv+c->c;
		break;
    }
}


blafoo() {
   cmpr_context c;
   cmpr_fill_context(p, &c, pixel);

	if (p->dir == VERTICAL && abs(dh) < abs(dv)+CMPR_CHANGE_BIAS) {
	    p->dir = HORIZONTAL;
	} else 
	if (p->dir == HORIZONTAL && abs(dv) < abs(dh)+CMPR_CHANGE_BIAS) {
	    p->dir = VERTICAL;
	}
	
	cmpr_context_select_dir()
	cf = update_c(&c, (d*c<0));


}




        out <<= 2;
        out |= (p->dir<<1) || cf;
        
        p->b_vert[p->x] = b;
        p->b_hori = b;
        p->c_vert[p->x] = c;
        p->c_hori = c;

        p->x++;



////
/// Interface Implementation
//

cmpr_ref cmpr_create(int w, int h) {
    cmpr_ref ref; 
    cmpr *p;

    p = (cmpr*)malloc(sizeof(cmpr));
    ref.p = cmpr_init(p, w, h);

    return ref;
}

void cmpr_delete(cmpr_ref ref) {
    if (!ref.p) return 0;
    cmpr_free(ref.p);
    free(ref.p);
    ref.p = 0;
}

cmpr3_ref cmpr3_create(int w, int h, int sub, int sync) {
    cmpr3_ref ref; 
    cmpr3 *q; 

    q = (cmpr3*)malloc(sizeof(cmpr3));
    ref.q = cmpr3_init(q, w, h, sub, sync);

    return ref;
}

void cmpr3_delete(cmpr3_ref ref) {
    if (!ref.q) return 0;
    cmpr3_free(ref.q);
    free(ref.q);
    ref.q = 0;
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

__inline__ void cmpr3_enc_push(cmpr3_ref ref, int raw);
__inline__ void cmpr3_enc_finish_line(cmpr3_ref ref);
__inline__ int cmpr3_enc_pull(cmpr3_ref ref, char *enc);
__inline__ void cmpr3_enc_finish_fame(cmpr3_ref ref);


