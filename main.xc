#include <xs1.h>
#include <platform.h>
#include <stdlib.h>

#include "video.h"
#include "test.h"
#include "blink.h"
#include "downsample.h"

int main(void) {
    int w=VID_WIDTH;
    int h=VID_HEIGHT;
    streaming chan vid, output;
    tst_setup(w,h);

    par {
        tst_run_debug_video(vid);
        downsample(4, vid, output);
        //tst_run_debug_output(output);
        tst_run_frame_statistics(output,w/4,h/4);
    }

    return 0;
}
