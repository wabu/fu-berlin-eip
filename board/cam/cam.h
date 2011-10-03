/*
 * cam.h
 *
 *  Created on: 11.02.2011
 *      Author: Michael
 */

#ifndef CAM_H_
#define CAM_H_

#define CAM_PIXEL_WIDTH 160
#define CAM_PIXEL_HEIGHT 120

// Kammerageschwindigkeit
// Kamerafrequenz = 100MHz / CAM_FREQ_DIV; (CAM_FREQ_DIV = 4,6,8,10...)
#define CAM_FREQ_DIV 6

void cam_WriteRegValue(unsigned char addr, unsigned char  val);
unsigned char cam_ReadRegValue(unsigned char addr);
void cam_Init();
void cam_DataCapture(streaming chanend data);

#endif /* CAM_H_ */
