#include "compat.h"

int creadi(streaming chanend c) {
    int d;
    c :> d;
    return d;
}
char creadc(streaming chanend c) {
    char d;
    c :> d;
    return d;
}

void cwritei(streaming chanend c, int d) {
    c <: d;
}
void cwritec(streaming chanend c, char d){
    c <: d;
}

