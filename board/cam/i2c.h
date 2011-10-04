#ifndef I2C_H_
#define I2C_H_

#include <xs1.h>

extern clock portClk;

void i2c_init(void);
void i2c_start(void);
void i2c_stop(void);
unsigned char i2c_read(unsigned char ack);
unsigned char i2c_write(unsigned char data);

#endif
