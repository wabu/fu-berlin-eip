#include <xs1.h>
#include "i2c.h"
#include "delays.h"
#include <xclib.h>

// i2c Port
port cam_sda_p = XS1_PORT_1L;
port cam_scl_p = XS1_PORT_1K;

clock portClk = XS1_CLKBLK_REF;

void delayloop16(unsigned int count)
{
	delayus(2);
}

void i2c_init(void) {
	unsigned char i;
	// SCL und SDA als Ausgang (auf Low)
	configure_out_port(cam_sda_p, portClk, 0);
	configure_out_port(cam_scl_p, portClk, 0);

	cam_sda_p <: 1;

	for (i = 0; i < 9; i++) {
		delayloop16(1);
		cam_scl_p <: 1;
		delayloop16(1);
		cam_scl_p <: 0;
	}
	delayloop16(1);
	cam_sda_p <: 0;

}
void i2c_start(void) {
	cam_sda_p <: 1;
	delayloop16(1);
	cam_scl_p <: 1;
	delayloop16(1);
	cam_sda_p <: 0;
	delayloop16(1);
	cam_scl_p <: 0;
	delayloop16(1);
}
void i2c_stop(void) {
	cam_scl_p <: 1;
	delayloop16(1);
	cam_sda_p <: 1;
	delayloop16(1);
	cam_scl_p <: 0;
	delayloop16(1);
	cam_sda_p <: 0;
	delayloop16(1);
}

unsigned char i2c_read(unsigned char ack) {
	unsigned char i, j, b;
	j = 0;
	// SDA als Input
	configure_in_port(cam_sda_p, portClk);

	for (i = 0; i < 8; i++) {
		cam_sda_p :> b;
		j = (j << 1) | b;
		delayloop16(1);
		cam_scl_p <: 1;
		delayloop16(1);
		cam_scl_p <: 0;
		delayloop16(1);
	}

	// SDA als Output
	configure_out_port(cam_sda_p, portClk, 0);
	delayloop16(1);
	cam_sda_p <: (unsigned char)(1 - ack);
	delayloop16(1);
	cam_scl_p <: 1;
	delayloop16(1);
	cam_scl_p <: 0;
	delayloop16(1);
	cam_sda_p <: 0;

	return j;
}

unsigned char i2c_write(unsigned char data) {
	unsigned char i, j;
	j = data;
	for (i = 0; i < 8; i++) {
		cam_sda_p <: bitrev(j) >> 24;

		delayloop16(1);
		cam_scl_p <: 1;
		delayloop16(1);
		cam_scl_p <: 0;
		delayloop16(1);
		cam_sda_p <: 0;
		delayloop16(1);
		j = j << 1;
	}
	// SDA als Input
	configure_in_port(cam_sda_p, portClk);
	delayloop16(1);
	cam_scl_p <: 1;
	delayloop16(1);
	cam_scl_p <: 0;
	delayloop16(1);
	cam_sda_p :> j;
	// SDA als Output
	configure_out_port(cam_sda_p, portClk, 0);
	return (j == 0);
}
