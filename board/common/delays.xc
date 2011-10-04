#include <xs1.h>
#include "delays.h"

#define TIME_US 98
#define TIME_MS 999998

timer xTimer;

void delayus(unsigned int us)
{
	unsigned time, i;
	xTimer :> time; /* save current time */
	
	for (i=0;i<us;i++) {
		time += TIME_US;
		xTimer when timerafter(time) :> void;
	}
}
void delayms(unsigned int ms)
{
	unsigned time, i;
	xTimer :> time; /* save current time */
	
	for (i=0;i<ms;i++) {
		time += TIME_MS;
		xTimer when timerafter(time) :> void;
	}
}
