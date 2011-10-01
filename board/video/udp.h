#ifndef UDP_H_
#define UDP_H_

#include <xs1.h>
#include "netconf.h"

// Länge der Nutzdaten = 2 (Zeilennummer) + UDP_CAM_WIDTH Bytes
#define UDP_DATA_LENGTH (2 + UDP_PIXEL_WIDTH)

// EthernetHeader (14 Bytes) + IPHeader (20 Bytes) +
// UDPHeader (8 Bytes) + UDP_DATA_LENGTH
#define UDP_PACKET_LENGTH (42 + UDP_DATA_LENGTH)

extern unsigned int udpTxBuf[380];

void setUDPData(unsigned char txbuf[], unsigned short lineNum, unsigned char data[]);
void udpBuildPacket(unsigned char txbuf[]);
void udpTransmitter(chanend tx, chanend rx, streaming chanend data1, streaming chanend data2);
void udpConnect(chanend tx);
#endif
