#include <xs1.h>
#include <platform.h>

#include "test.h"
#include "downsample.h"

int main(void) {
    streaming chan vid, output;
    par {
        on stdcore[0] : {
            tst_setup(64,64);
            tst_run_debug_video(vid);
        }
        on stdcore[0] : downsample(4, vid, output);
        on stdcore[1] : tst_run_debug_output(output);
    }

    return 0;
}
