/** @file codec.h
 * interface for video de/encoding
 */

/** 
 * cmpr encoder/decoder storage.
 *
 * Note that on the xmos hardware, the code is more efficiently executed with
 * the struct on the stack (we don't know why).
 */
typedef struct cmpr {
    int w,h; /**< size of the pictures */
    int x;   /**< x coordinate of current line */

    int dir; /**< last reference direction */

    unsigned char b_hori; /**< reference pixel value for last horizontal pixel*/
    signed   char c_hori; /**< reference change value for last horizontal pixel */

    unsigned char b_vert[VID_WIDTH]; /**< reference pixel values for last line */
    signed   char c_vert[VID_WIDTH]; /**< reference change values for last line */
} cmpr;

/** 
 * @brief cmpr3 encoder/decoder storage 
 */
typedef struct cmpr3 {
    struct cmpr;

    int sync_cnt, sync_val;     /** syncronistation counter and value */

    int sub; /**< subsampling size */
    int y, sx, sy; /**< subsample coordinates */

    unsigned char b_sampling_sum[SUB_WIDTH]; /**< subsample buffer sums up the b values of #sub lines */
    signed char c_sampling_sum[SUB_HEIGHT];  /**< subsample buffer sums up the c values of #sub lines */

    // { rle sutff
    int c_index, dir_index, dir_cnt, dir_next;
    char enc_buff_c[VID_WIDTH/8+1];
    char enc_buff_dir[VID_WIDTH];
    // }
    
    // TODO check if 1d array is more efficient
    unsigned char b_prev[SUB_HEIGHT][SUB_WIDTH]; /**< subsampled reference pixel values for last frame */
    signed char c_prev[SUB_HEIGHT][SUB_WIDTH];   /**< subsampled reference change values for last frame */
} cmpr3;

/** 
 * initialises cmpr encoder
 * @param p pointer to allocated struct
 * @param w     picture width
 * @param h     picture height
 */
void cmpr_init(cmpr *p, int w, int h);

/** 
 * initialises cmpr3 encoder
 * @param p pointer to allocated struct
 * @param w     picture width
 * @param h     picture height
 * @param sub   subsample size for reference picture
 * @param sync  syncronisation frame interval
 */
void cmpr3_init(cmpr3* p, int w, int h, int sub, int sync);

extern inline void cmpr_start_frame(cmpr *p);
extern inline void cmpr_start_line(cmpr *p);
extern inline char cmpr_enc(cmpr *p, int raw);
extern inline int cmpr_dec(cmpr *p, char enc);

extern inline void cmpr3_start_frame(cmpr3 *p);
extern inline void cmpr3_start_line(cmpr3 *p);

/**
 * Give an int of data (4 pixels) to codec
 * @param p     pointer to cmpr struct
 * @param raw   4 pixel of picture data
 * @see cmpr3_get_enc_buffer
 */
extern inline void cmpr3_enc_push(cmpr3 *p, int raw);

/**
 * returns the buffer of encoded c data
 * @param p     pointer to cmpr3 struct
 * @param n     output param for size of buffer
 * @return      buffer of c-flags as bitstring
 */
extern inline const char *cmpr3_enc_get_cs(cmpr3 *p, int *n);
/**
 * returns the buffer of encoded dir data
 * @param p     pointer to cmpr3 struct
 * @param n     output param for size of buffer
 * @return      buffer of rle encoded dir data
 */
extern inline const char *cmpr3_enc_get_dirs(cmpr3 *p, int *n);



/**
 * pushes c-flags to decoder (8 bits)
 * @param p     pointer to cmpr3 struct
 * @param raw   bits of 8 c-flags
 * @return      0 if all c-flags have been received, 1 otherwise
 */
extern inline int cmpr3_dec_push_cs(cmpr3 *p, char raw);
/**
 * pushes rle-encoded dir changes to decoder (8 bits)
 * @param p     pointer to cmpr3 struct
 * @param raw   an rle-encoded dir change
 * @return      0 if all dir-changes have been received, 1 otherwise
 */
extern inline int cmpr3_dec_push_dir(cmpr3 *p, char raw);

/**
 * pulls raw video data form decoder (4 pixels)
 * @param p     pointer to cmpr3 struct
 * @return      an int (4 pixels) of raw video data
 */
extern inline int cmpr3_dec_pull(cmpr3 *p);

