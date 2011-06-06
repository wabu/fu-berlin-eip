#include <xs1.h>
#include <platform.h>
#include <stdlib.h>

#include "video.h"
#include "test.h"
#include "blink.h"
#include "downsample.h"
#include "compress.h"

int main(void) {
    streaming chan vid, cmpr, output;
    tst_setup(VID_WIDTH,VID_HEIGHT);

    par {
        tst_run_debug_video(vid);
        cmpr_encode(vid, cmpr);
        cmpr_decode(cmpr, output);
        tst_run_debug_output(output);
        // tst_run_frame_statistics(output,VID_WIDTH,VID_HEIGHT);
    }

    return 0;
}
