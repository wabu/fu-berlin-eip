typedef struct cmpr_ref {
#ifdef __XC__
    int p;
#else
    struct cmpr* p;
#endif
} cmpr_ref;

/**
 * creates an cmpr encoder object
 * @param w width of frames
 * @param h height of frames
 * @return  encoder object reference
 */
cmpr_ref cmpr_create(int w, int h);
void cmpr_delete(cmpr_ref ref);

// TODO: check signed/unsigned for chars
// TODO: check where we really want to use chars and where ints are better

__inline__ void cmpr_start_frame(cmpr_ref ref);
__inline__ void cmpr_start_line(cmpr_ref ref);
/**
 * encode an int (4 pixels) raw data into a byte encoded data (4 c,h pairs)
 * @param ref   referenc to the encoder object
 * @param raw   pixel data   (0x<hue><hue><hue><hue>)
 * @return      encoded data (0b<c><h><c><h><c><h><c><h>)
 */
__inline__ char cmpr_enc(cmpr_ref ref, int raw);

/**
 * dencode a byte of encoded data (4 c,h pairs) into an int (4 pixels) raw data
 * @param ref   referenc to the encoder object
 * @param enc   encoded data (0b<h><c><h><c><h><c><h><c>)
 * @return      pixel data   (0x<hue><hue><hue><hue>)
 */
__inline__ int  cmpr_dec(cmpr_ref ref, char enc);


typedef struct cmpr3_ref {
#ifdef __XC__
    int p;
#else
    union {
        struct cmpr *p;
        struct cmpr3 *q;
    };
#endif
} cmpr3_ref;

/**
 * creates an cmpr3 encoder object
 * @param ref   referenc to the encoder object
 * @param w width of frames
 * @param h height of frames
 * @param sub   subsample rate to save reference frame
 * @param sync  rate of syncronisation (in frames/sync)
 * @return  encoder object reference
 */
cmpr3_ref cmpr3_create(int w, int h, int sub, int sync);
void cmpr3_delete(cmpr3_ref ref);

/**
 * push raw pixel data (4 pixels) into the encoder.
 * Push one line of data to the encoder, call cmpr3_finish_line and
 * get the encoded data with cmpr3_enc_pull calls.
 * @param ref   referenc to the encoder object
 * @param raw   (4 pixels of data)
 */
__inline__ void cmpr3_enc_push(cmpr3_ref ref, int raw);

/** 
 * finish encoding of current line
 * @param ref   referenc to the encoder object
 */
__inline__ void cmpr3_enc_finish_line(cmpr3_ref ref);

/**
 * pull encoded data, returns 0 when finished
 * @param ref   referenc to the encoder object
 * @return      status
 */
#ifdef __XC__
__inline__ int cmpr3_enc_pull(cmpr3_ref ref, char &enc);
#else
__inline__ int cmpr3_enc_pull(cmpr3_ref ref, char *enc);
#endif

/*
 * finish current frame
 * @param ref   referenc to the encoder object
 */
__inline__ void cmpr3_enc_finish_fame(cmpr3_ref ref);


