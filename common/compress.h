typedef struct cmpr_ref {
    int p;
} cmpr_ref;

typedef struct cmpr3_ref {
    int p;
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
inline void cmpr3_enc_push(cmpr3_ref ref, int raw);

/** 
 * finish encoding of current line
 * @param ref   referenc to the encoder object
 */
inline void cmpr3_enc_finish_line(cmpr3_ref ref);

/**
 * pull encoded data, returns 0 when finished
 * @param ref   referenc to the encoder object
 * @return      status
 */
#ifdef __XC__
inline int cmpr3_enc_pull(cmpr3_ref ref, char &enc);
#else
inline int cmpr3_enc_pull(cmpr3_ref ref, char *enc);
#endif

/*
 * finish current frame
 * @param ref   referenc to the encoder object
 */
inline void cmpr3_enc_finish_fame(cmpr3_ref ref);

void cmpr_encoder(streaming chanend cin, streaming chanend cout);
void cmpr_decoder(streaming chanend cin, streaming chanend cout);


