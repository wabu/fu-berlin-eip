#include <xs1.h>
#include <platform.h>
#include <stdlib.h>

#include "test.h"
#include "blink.h"
#include "downsample.h"

int main(void) {
    streaming chan vid, output;
    tst_setup(16,16);

    par {
        blink4();
        tst_run_debug_video(vid);
        downsample(2, vid, output);
        tst_run_debug_output(output);
    }

    return 0;
}
