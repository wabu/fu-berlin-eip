#include <xs1.h>
#include <platform.h>
#include <stdlib.h>

#include "video.h"
#include "test.h"
#include "blink.h"
#include "downsample.h"

int main(void) {
    streaming chan vid, output;
    tst_setup(VID_WIDTH,VID_HEIGHT);

    par {
        tst_run_debug_video(vid);
        downsample(4, vid, output);
        tst_run_frame_statistics(output,VID_WIDTH/4,VID_HEIGHT/4);
    }

    return 0;
}
