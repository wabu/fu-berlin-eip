#include <xs1.h>
#include <platform.h>

on stdcore[0] : clock clk = XS1_CLKBLK_1;
on stdcore[0] : port clockP = XS1_PORT_1B;
on stdcore[0] : port inP = XS1_PORT_8A;
on stdcore[1] : port outP = XS1_PORT_8A;

void dataRecv(port inP, streaming chanend s1) {
    int x;
    inP :> x;
    s1 <: x;
}
void dataSend(port outP, streaming chanend s2) {
    int x;
    s2 :> x;
    outP <: x;
}
void downsample(int n, streaming chanend s1, streaming chanend s2) {
    for(int i=0; i<n; i++) {
        int x;
        s1 :> x;
        s2 <: x;
    }
}

void setup_clock(clock clk, port clockP, port inP) {
    configure_clock_src(clk, clockP);
    configure_in_port(inP, clk);
    start_clock(clk);
}

int main(void) {
    streaming chan s1, s2;

    par {
        on stdcore[0] : {
            setup_clock(clk, clockP, inP);
            dataRecv(inP, s1);
        }
        on stdcore[0] : downsample(4, s1, s2);
        on stdcore[1] : dataSend(outP, s2);
    }
    return 0;
}
