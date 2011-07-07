/*
 * cam.xc
 *
 *  Created on: 11.02.2011
 *      Author: Michael
 */
#include <xs1.h>
#include "cam.h"
#include "i2c.h"
#include "delays.h"
#include <xclib.h>
#include "conf.h"

#define DATA_TIMER_DELAY (CAM_FREQ_DIV*8)

in port cam_port = XS1_PORT_32A;
// Data 	-> Bit0 - Bit7
// VClk		-> Bit10
#define VCLK_MASK (1<<10)
// VSync	-> Bit11
#define VSYNC_MASK (1<<11)
// HSync	-> Bit12
#define HSYNC_MASK (1<<12)

//out port cam_reset_p = XS1_PORT_1J;
out port cam_mclk_p = XS1_PORT_1E;

clock mclk = XS1_CLKBLK_3;

void cam_WriteRegValue(unsigned char addr, unsigned char val) {
	i2c_stop();
	i2c_start();
	i2c_write(0x22);
	i2c_write(addr);
	i2c_write(val);
	i2c_stop();
}

unsigned char cam_ReadRegValue(unsigned char addr) {
	unsigned char data;

	i2c_stop();
	i2c_start();
	i2c_write(0x22);
	i2c_write(addr);
	i2c_start();
	i2c_write(0x23);
	data = i2c_read(0);
	i2c_stop();

	return data;
}

void cam_Init() {
	// Vsync extra Port
	// Hsync, PClk 1 Bit Port
	//	configure_clock_src(vCLK, cam_vclk_p);
	//	configure_in_port_strobed_slave(cam_data_p, cam_hsync_p, vCLK);
	//	set_port_inv(cam_vclk_p);
	//	clearbuf(cam_data_p);
	//	start_clock(vCLK);

	// Vsync, Hsync in einem Port
	// PClk 1 Bit Port
	//	configure_clock_src(vCLK, cam_vclk_p);
	//	set_port_inv(cam_vclk_p);
	//	clearbuf(cam_data_p);
	//	start_clock(vCLK);

	// Vsync, Hsync, PClk in einem Port
	//configure_in_port(cam_port, mclk);
	//set_port_sample_delay(cam_port);


	// MCLK Init
	configure_clock_rate(mclk, 100, CAM_FREQ_DIV);
	configure_port_clock_output(cam_mclk_p, mclk);
	start_clock(mclk);

	delayms(10);

	//cam_reset_p <: 0;
	delayms(10);

	//cam_reset_p <: 1;
	delayms(1);

	//cam_reset_p <: 0;
	delayms(1);

	//cam_reset_p <: 1;
	delayms(20);

	i2c_init();
}

void cam_DataCapture(streaming chanend dataOut) {
	unsigned char d;
	int x;
	int j;
	int i;
	int c;
	unsigned y;
	while (1) {
		// warten bis Vsync High -> neues Frame
		cam_port when pinsneq(x) :> x;
		if (x & VSYNC_MASK)
		{
			for (i = (CAM_PIXEL_HEIGHT + 1); --i != 0;)
			{

				// j = Anzahl der ankommenden Y's pro Zeile
				j = CAM_PIXEL_WIDTH;
				do
				{
					cam_port when pinsneq(y)  :> y @ c;
				}while( !(y & HSYNC_MASK)  );

				do
				{
					// Pixelgrauwert
					c += DATA_TIMER_DELAY;
					cam_port @ c :> d;
					dataOut <: d;
				}while (--j);

				do
				{
					cam_port when pinsneq(y)  :> y;
				}while( (y & HSYNC_MASK)  );
			}
		}
	}

}
