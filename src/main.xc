#include <xs1.h>

#include "test.h"

int main(void) {
    streaming chan vid;
    par {
        tst_setup(16,16);
    }
    par {
        tst_run_debug_video(vid);
        tst_run_debug_output(vid);
    }

    return 0;
}
