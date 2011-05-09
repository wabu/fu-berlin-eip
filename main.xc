#include <xs1.h>

#include "test.h"
#include "downsample.h"

int main(void) {
    streaming chan vid, output;
    par {
        tst_setup(64,64);
    }
    par {
        tst_run_debug_video(vid);
        downsample(4, vid, output);
        tst_run_debug_output(output);
    }

    return 0;
}
