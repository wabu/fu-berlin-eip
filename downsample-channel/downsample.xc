#include <xs1.h>
#include <platform.h>

void downsample(int n, streaming chanend ichan, streaming chanend ochan) {
    //FIXME: rgb components?
    int sum = 0;
    for(int i=0; i<n; i++) {
        int x;
        ichan :> x;
        sum += x;
    }
    ochan <: sum;
}

void vid_generate(streaming chanend ochan) {
}
void vid_output(streaming chanend ichan) {
}

int main(void) {
    streaming chan s1, s2;

    par {
        vid_generate(s1);
        downsample(4, s1, s2);
        vid_output(s2);
    }
    return 0;
}
