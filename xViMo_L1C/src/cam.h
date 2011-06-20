/*
 * cam.h
 *
 *  Created on: 11.02.2011
 *      Author: Michael
 */

#ifndef CAM_H_
#define CAM_H_

#include <xs1.h>

void cam_WriteRegValue(unsigned char addr, unsigned char  val);
unsigned char cam_ReadRegValue(unsigned char addr);
void cam_Init();
void cam_DataCapture(streaming chanend data);

#endif /* CAM_H_ */
