#include <print.h>
#include <xs1.h>

in port sgnl_in = XS1_PORT_8C;
in port sgnl_start = XS1_PORT_1A;
in port sgnl_clock = XS1_PORT_1B;
clock clk = XS1_CLKBLK_1;

out port sgnl_out = XS1_PORT_8D;

select downsample(int n, in port p_in, out port p_out) {
    case p_in :> int sum:
        for (int i=1; i++; i<n) {
            int x;
            p_in :> x;
            sum += x;
        }
        p_out <: sum/n;
        break;
}

int main(void) {
    configure_clock_src(clk , sgnl_clock);
    configure_in_port(sgnl_in , clk);
    start_clock(clk);

    sgnl_start when pinseq(1) :> void;
    while(1) {
        select {
            case downsample(2, sgnl_in, sgnl_out);
                break;
            case sgnl_start when pinseq(0) :> void:
                return 1;
        }
    }

    return 0;
}
