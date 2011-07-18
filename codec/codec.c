#define printf(...)
/**
 * @file codec.c
 * This file contains an implementation of an compression/codec algorithm.
 *
 * The basic idea is to encode a pixel as reference direction and change
 * value: $b = ref + c$. 
 * The reference direction can be the horizontal or vertical pixel (cmpr), or
 * for 3d compression (cmpr3) the previouse picture, which can be encoded as
 * one bit.
 * The value of the change value is also encoded as a one bit flag, either the
 * change value is increased or decreased and inverted.
 *
 * The encoding/decoding process is splited into different subtasks.
 * - reference values are loaded out of the codecs storage into the context.
 *   it also calculates the distance of each reference value to the actual pixel
 *   @see cmpr_context_load
 * - when the direction is choosen, the vals are selected in the context
 *   @see cmpr_context_select_dir
 * - the change value is updated
 *   @see cmpr_context_update_c
 * - the new reconstructed pixel and change values are stored in the codecs storage
 *   @see cmpr_context_store
 *
 * @see cmpr_enc_pixel, cmpr_dec_pixel, cmpr3_enc_pixel, cmpr3_dec_pixel
 *
 * For 3d compression, we have to subsample the reference picture and change
 * value to fit into the memory of the device.
 *
 * @see cmpr3_subsample_line
 */
#include "config.h"
#include "codec.h"

#include <stdio.h>


static inline int abs(int i) {
    return i>0 ? i : -i;
}
static inline int max(int a, int b) {
    return a>b ? a : b;
}
static inline int maxabs(int a, int b) {
    return abs(a) > abs(b) ? a : b;
}

/** holds context for comptation of one pixel shared by the subtasks*/
typedef struct cmpr_context {
    int b_val , b_vert, b_hori;        /**< reconstructed picture values */
    int c_vert, c_hori, c_flag, c_val; /**< change values */
    int d_val, d_vert, d_hori; /**< distance values */
    int dir; /**< direction */
} cmpr_context;


/** holds context for comptation of one pixel shared by the subtasks*/
typedef struct cmpr3_context {
    struct cmpr_context;

    int b_prev, c_prev, d_prev;
} cmpr3_context;


/**
 * fills the pixel context with data from codec storage 
 * @param p     pointer to codec storage
 * @param x     pointer to context
 * @param pixel actual value of the pixel, use zero for decoder
 */
static inline void cmpr_context_load(cmpr *p, cmpr_context *x, int pixel) {
    x->dir    = p->dir;
    x->b_vert = p->b_vert[p->x];
    x->b_hori = p->b_hori;

    x->c_vert = p->c_vert[p->x];
    x->c_hori = p->c_hori;

    if (x->c_vert +  x->b_vert <= 0)
        x->c_vert = -x->b_vert;
    if (x->c_hori +  x->b_hori <= 0)
        x->c_hori = -x->b_hori;

    x->d_hori = x->b_hori + x->c_hori - pixel;
    x->d_vert = x->b_vert + x->c_vert - pixel;
}

/**
 * fills the pixel context with data from codec storage 
 * @param p     pointer to codec storage
 * @param x     pointer to context
 * @param pixel actual value of the pixel, use zero for decoder
 */
static inline void cmpr3_context_load(cmpr3 *p, cmpr3_context *x, int pixel) {
    cmpr_context_load((cmpr*)p, (cmpr_context*)x, pixel);

    if (p->sync) {
        x->b_prev = CMPR_B_DEFAULT;
        x->c_prev = CMPR_C_DEFAULT;
    } else {
        x->b_prev = p->b_prev[p->sy][p->sx];
        x->c_prev = p->c_prev[p->sy][p->sx];
    }

    if (x->c_prev +  x->b_prev <= 0)
        x->c_prev = -x->b_prev;

    x->d_prev = x->b_prev + x->c_prev - pixel;
}

/** 
 * updates the c_val according to the c-flag in context
 */
static inline void cmpr_context_update_c(cmpr_context *x, int flag) {
    int *c = &(x->c_val);
    x->c_flag = flag;

    if (flag) {
        (*c) = (*c) + (*c)/2;
    } else {
        (*c) = -(*c);
        if (abs(*c)>=CMPR_C_MIN*2) (*c)=(*c)/2;
    }
}
/** updates the c_val according to the c_flag in context*/
static inline void cmpr3_context_update_c(cmpr3_context *x, int flag) {
    cmpr_context_update_c((cmpr_context*)x, flag);
}

/** Sets values in context according to dir. */
static inline void cmpr_context_select_dir(cmpr_context *x, int dir) {
    x->dir = dir;

    switch (dir) {
    case HORIZONTAL:
        x->d_val = x->d_hori;
        x->c_val = x->c_hori;
        x->b_val = x->b_hori + x->c_hori;
        break;

    case VERTICAL:
        x->d_val = x->d_vert;
        x->c_val = x->c_vert;
        x->b_val = x->b_vert + x->c_vert;
        break;
    }
}
/** Updates values according to dir in context. */
static inline void cmpr3_context_select_dir(cmpr3_context *x, int dir) {
    x->dir = dir;

    switch (dir) {
    case PREVIOUS:
        x->d_val = x->d_prev;
        x->c_val = x->c_prev;
        x->b_val = x->b_prev + x->c_prev;
        break;

    default:
        cmpr_context_select_dir((cmpr_context*)x, dir);
        break;
    }
}

/**
 * Encodes change of directon.
 *
 * Since we just commit changes in dir we need one transmission bit:
 * current -> change to : bit value
 * h -> v : 0
 * h -> p : 1
 * v -> h : 0
 * v -> p : 1
 * p -> h : 0
 * p -> v : 1
 * @param from  old direction
 * @param to    new direction
 * @return      direction flag or -1 if direction does not change
 *
 * @see cmpr3_decode_dir
 */
static inline signed char cmpr3_encode_dir(int from, int to) {
    return from == to ? -1 : (from != PREVIOUS ? to == PREVIOUS : to == VERTICAL);
}

/**
 * Decodes change of directon.
 * @parma old   old direction
 * @param flag  direction flag
 * @return      new direction
 *
 * @see cmpr3_encode_dir
 */
static inline int cmpr3_decode_dir(int old, char flag) {
    return flag ? (old == PREVIOUS ? VERTICAL : PREVIOUS) : (old == HORIZONTAL ? VERTICAL : HORIZONTAL);
}


/** stores info of context back to codec's permanent storage */
static inline void cmpr_context_store(cmpr *p, cmpr_context *x) {
    p->b_vert[p->x] = x->b_val;
    p->b_hori = x->b_val;
    p->c_vert[p->x] = x->c_val;
    p->c_hori = x->c_val;
    p->dir = x->dir;
}

/** stores info of context back to codec's permanent storage */
static inline void cmpr3_context_store(cmpr3 *p, cmpr3_context *x) {
    cmpr_context_store((cmpr*)p, (cmpr_context*)x);

    p->b_sampling_sum[p->sx] += x->b_val;
    p->c_sampling_max[p->sx] = maxabs(p->c_sampling_max[p->sx], x->c_val);
}

/**
 * Uses the subsample buffers to fill b_prev buffer with sampled values, clears
 * subsample buffers.
 * @param p     pointer to storage for prev buffers
 * @param sy    y-coordinate for subsampling buffers
 */
static inline void cmpr3_subsample_line(cmpr3 *p, int sy) {
    int sw = p->w/p->sub;
    int ss = p->sub*p->sub;

    for (int sx=0; sx < sw; sx++) {
        p->b_prev[sy][sx] = p->b_sampling_sum[sx] / ss;
        p->c_prev[sy][sx] = p->c_sampling_max[sx];

        //printf("|%d,%d: b=%x, c=%d\n", sy, sx, p->b_prev[sy][sx], p->c_prev[sy][sx]);

        p->b_sampling_sum[sx] = 0;
        p->c_sampling_max[sx] = 0;
    }
}

/**
 * encodes one pixel
 * @param pixel hue value for pixel
 * @return      dir and c-flag for pixel as 0b000000<dir><c>
 */
static inline char cmpr_enc_pixel(cmpr *p, int pixel) {
    cmpr_context x;
    int dir = p->dir;

    cmpr_context_load(p, &x, pixel);

    switch (dir) {
    case VERTICAL:
        if (abs(x.d_hori) < abs(x.d_vert)-CMPR_CHANGE_BIAS) {
            dir = HORIZONTAL;
        }
        break;
    case HORIZONTAL:
        if (abs(x.d_vert) < abs(x.d_hori)-CMPR_CHANGE_BIAS) {
            dir = VERTICAL;
        }
        break;
    }

    cmpr_context_select_dir(&x, dir);
    cmpr_context_update_c(&x, (x.d_val * x.c_val < 0));

    cmpr_context_store(p, &x);

    return (x.dir<<1) | (x.c_flag<<0);
}

/**
 * decode one pixel
 * @parma dir   direction
 * @parma c     c flag
 * @return      hue value for pixel
 */
static inline int cmpr_dec_pixel(cmpr *p, int dir, int c) {
    cmpr_context x;

    cmpr_context_load(p, &x, 0);
    cmpr_context_select_dir(&x, dir);
    cmpr_context_update_c(&x, c);
    cmpr_context_store(p, &x);

    return x.b_val;
}

/**
 * encodes one pixel
 * @param pixel hue value for pixel
 * @param c     c-flag
 * @param hvp   dir-flag
 * @return      dir-flag and c-flag for pixel as 0b000000<dir><c>
 * @see         cmpr3_encode_dir
 */
static inline void cmpr3_enc_pixel(cmpr3 *p, int pixel, char *c_flag, signed char *dir_flag) {
    cmpr3_context x;
    int dir = p->dir;
    int cur;

    cmpr3_context_load(p, &x, pixel);
    //printf("%d, p=%d, h=%d, v=%d\n", p->dir, x.d_prev, x.d_hori, x.d_vert);

    switch (dir) {
    case PREVIOUS:
        cur = abs(x.d_prev) - CMPR_CHANGE_BIAS;
        if (abs(x.d_hori) < cur) {
            cur = abs(x.d_hori);
            dir = HORIZONTAL;
        }
        if (abs(x.d_vert) < cur) {
            cur = abs(x.d_vert);
            dir = VERTICAL;
        }
        break;
    case HORIZONTAL:
        cur = abs(x.d_hori) - CMPR_CHANGE_BIAS;
        if (abs(x.d_prev) < cur) {
            cur = abs(x.d_prev);
            dir = PREVIOUS;
        }
        if (abs(x.d_vert) < cur) {
            cur = abs(x.d_vert);
            dir = VERTICAL;
        }
        break;
    case VERTICAL:
        cur = abs(x.d_vert) - CMPR_CHANGE_BIAS;
        if (abs(x.d_prev) < cur) {
            cur = abs(x.d_prev);
            dir = PREVIOUS;
        }
        if (abs(x.d_hori) < cur) {
            cur = abs(x.d_hori);
            dir = HORIZONTAL;
        }
        break;
    }
    if(x.dir != dir) {
            switch (dir) {
            case HORIZONTAL:
                printf("->h[%d,%d]", p->y, p->x);
                break;
            case VERTICAL:
                printf("->v[%d,%d]", p->y, p->x);
                break;
            case PREVIOUS:
                printf("->p[%d,%d]", p->y, p->x);
                break;
            }
    }
    *dir_flag = cmpr3_encode_dir(x.dir, dir);
    cmpr3_context_select_dir(&x, dir);

    //printf("d=%d, c=%d\n", x.d_val, x.c_val);
    cmpr3_context_update_c(&x, (x.d_val * x.c_val < 0));

    cmpr3_context_store(p, &x);

    *c_flag = x.c_flag;
}

/**
 * decode one pixel
 * @parma dir   direction flag
 * @parma c     c flag
 * @return      hue value for pixel
 */
static inline int cmpr3_dec_pixel(cmpr3 *p, int dir, int c) {
    cmpr3_context x;

    cmpr3_context_load(p, &x, 0);
    cmpr3_context_select_dir(&x, dir);
    cmpr3_context_update_c(&x, c);
    cmpr3_context_store(p, &x);

    return x.b_val;
}




void cmpr_init(cmpr *p, int w, int h) {
    p->w = w;
    p->h = h;
}

void cmpr3_init(cmpr3* p, int w, int h, int sub) {
    cmpr_init((cmpr*)p, w, h);

    p->sub = sub;
}
void cmpr_start_frame(cmpr *p) {
    p->dir = CMPR_HV_DEFAULT;

    for (int i=0; i<p->w; i++) {
        p->b_vert[i] = CMPR_B_DEFAULT;
        p->c_vert[i] = CMPR_C_DEFAULT;
    }
}

void cmpr_start_line(cmpr *p) {
    p->b_hori = CMPR_B_DEFAULT;
    p->c_hori = CMPR_C_DEFAULT;

    p->x = 0;
}

void cmpr3_start_frame(cmpr3 *p, int sync) {
    //printf("start frame %d\n", sync);
    cmpr_start_frame((cmpr*)p);

    p->sync = sync;
    p->dir = sync ? CMPR_HV_DEFAULT : CMPR_HVP_DEFAULT;
    p->y = p->sy = 0;
}

void cmpr3_start_line(cmpr3 *p) {
    cmpr_start_line((cmpr*)p);

    p->c_index = 0;
    p->dir_index = 0;
    p->dir_cnt = 0;
    p->dir_next = p->dir;

    if ( ++p->y % p->sub == 0) {
        cmpr3_subsample_line(p, p->sy);
        p->sy++;
    }
}

char cmpr_enc(cmpr *p, int raw) {
    char out;

    for (int valid=32, pixel = (raw >> (valid-=8)) & 0xff;
             valid>=0; pixel = (raw >> (valid-=8)) & 0xff) {

        out<<= 2;
        out |= cmpr_enc_pixel(p, pixel);

        p->x++;
    }
    return out;
}

int cmpr_dec(cmpr *p, char enc) {
    int out = 0;

    for (int valid= 8, ch = (enc >> (valid-=2));
             valid>=0; ch = (enc >> (valid-=2))) {
        out <<= 8;
        out |= cmpr_dec_pixel(p, (ch&CMPR_D_BIT_MASK)>>1, ch&CMPR_C_BIT_MASK);

        p->x++;
    }

    return out;
}

int cmpr3_enc_push(cmpr3 *p, int raw) {
    char c_flag, c_bits=0; 
    signed char dir_flag;

    for (int valid=32, pixel = (raw >> (valid-=8)) & 0xff;
             valid >=0; pixel = (raw >> (valid-=8)) & 0xff) {
        p->sx = p->x / p->sub;

        cmpr3_enc_pixel(p, pixel, &c_flag, &dir_flag);
        //printf("(%d,%d)\n", c_flag, dir_flag);

        c_bits<<= 1;
        c_bits |= c_flag;

        // rle...
        if (dir_flag >= 0) {
            printf("[%d:%d[%d]]", p->dir_cnt, dir_flag, p->dir_index);
            p->enc_buff_dir[p->dir_index++] = (p->dir_cnt << 1) | dir_flag; 
            p->dir_cnt = 1;
        } else { 
            p->dir_cnt++;
            if (p->dir_cnt == 127) {
                p->enc_buff_dir[p->dir_index++] = 0xff;
                p->dir_cnt = 0;
            }
        }

        p->x++;
    }
    if (p->x%8 == 0) {
        p->enc_buff_c[p->c_index++] |= c_bits;
    } else {
        p->enc_buff_c[p->c_index] = c_bits<<4;
    }

    return (p->x < p->w);
}

const char *cmpr3_enc_get_cs(cmpr3 *p, int *n) {
    *n = p->c_index;
    return p->enc_buff_c;
}

const char *cmpr3_enc_get_dirs(cmpr3 *p, int *n) {
    // XXX now we only can call this once ... 
    p->enc_buff_dir[p->dir_index++] = (p->dir_cnt+1) << 1; 
    *n = p->dir_index;
    return p->enc_buff_dir;
}



int cmpr3_dec_push_cs(cmpr3 *p, char raw) {
    p->enc_buff_c[p->c_index++] = raw;
    //printf("pushed cs %x (%d)\n", raw, p->c_index);

    if (p->c_index >= p->w/8) { // received all c flags
        p->c_index = 0;
        return 0;
    }
    return 1;
}

int cmpr3_dec_push_dir(cmpr3 *p, char raw) {
    p->enc_buff_dir[p->dir_index++] = raw;
    //printf("pushed dirs %x (%d)\n", raw, p->dir_index);
    p->dir_cnt += raw >> 1;

    // XXX refactor dir_update out into own function
    if (p->dir_cnt >= p->w) { // received all dir changes
        p->dir_index = 0;
        p->dir_cnt = p->enc_buff_dir[p->dir_index++];
        p->dir_next = p->dir_cnt==0xff ? p->dir : cmpr3_decode_dir(p->dir, p->dir_cnt & 0x1);
        p->dir_cnt >>= 1;

        return 0;
    }
    return 1;
}

int cmpr3_dec_pull(cmpr3 *p) {
    int raw;
    char c_bits;
    if (p->x%8 == 0) {
        c_bits = p->enc_buff_c[p->c_index] >> 4;
    } else {
        c_bits = p->enc_buff_c[p->c_index++] & 0xf;
    }
        
    for (int valid= 4, c_flag = (c_bits >> (--valid))&0x1;
             valid>=0; c_flag = (c_bits >> (--valid))&0x1) {
        p->sx = p->x / p->sub;

        // XXX refactor dir_update out into own function
        if (p->dir_cnt == 0) {
            p->dir = p->dir_next;

            p->dir_cnt = p->enc_buff_dir[p->dir_index++];
            p->dir_next = p->dir_cnt==0xff ? p->dir : cmpr3_decode_dir(p->dir, p->dir_cnt & 0x1);
            p->dir_cnt >>= 1;
            switch (p->dir) {
            case HORIZONTAL:
                printf("<-h[%d,%d]", p->y, p->x);
                break;
            case VERTICAL:
                printf("<-v[%d,%d]", p->y, p->x);
                break;
            case PREVIOUS:
                printf("<-p[%d,%d]", p->y, p->x);
                break;
            }
        }

        raw <<= 8;
        raw |= cmpr3_dec_pixel(p, p->dir, c_flag);

        p->dir_cnt--;
        p->x++;
    }

    return raw;
}


