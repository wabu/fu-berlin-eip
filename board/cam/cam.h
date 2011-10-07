/*
 * cam.h
 *
 *  Created on: 11.02.2011
 *      Author: Michael
 */

#ifndef CAM_H_
#define CAM_H_

#include <config.h>

#define CAM_PIXEL_WIDTH  VID_WIDTH
#define CAM_PIXEL_HEIGHT VID_HEIGHT

// Kammerageschwindigkeit
// Kamerafrequenz = 100MHz / CAM_FREQ_DIV; (CAM_FREQ_DIV = 4,6,8,10...)
#define CAM_FREQ_DIV 12

void cam_WriteRegValue(unsigned char addr, unsigned char  val);
unsigned char cam_ReadRegValue(unsigned char addr);
void cam_Init();
void cam_DataCapture(streaming chanend data);

#endif /* CAM_H_ */
