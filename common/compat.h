#include <xccompat.h>

#ifndef __XC__
#define streaming
#endif

int creadi(streaming chanend c);
char creadc(streaming chanend c);

void cwritei(streaming chanend c, int d);
void cwritec(streaming chanend c, char d);

