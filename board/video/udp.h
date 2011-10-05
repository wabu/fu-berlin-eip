#ifndef UDP_H_
#define UDP_H_

#include <xs1.h>
#include "netconf.h"

#define UDP_DATA_TYPE_RAW 1
#define UDP_DATA_TYPE_CMP 2


// Payload = TYPE (1 byte) + FRAME_SEQ_ID (2 byte) + Line (1 byte) + one line camera pixel
#define UDP_RAW_PAYLOAD_LENGTH (6 + UDP_PIXEL_WIDTH)
#define UDP_CMP_PAYLOAD_LENGTH (214)

// EthernetHeader (14 Bytes) + IPHeader (20 Bytes) +
// UDPHeader (8 Bytes) + UDP_DATA_LENGTH
#define UDP_RAW_PACKET_LENGTH (42 + UDP_RAW_PAYLOAD_LENGTH)
#define UDP_CMP_PACKET_LENGTH (42 + UDP_CMP_PAYLOAD_LENGTH)

extern unsigned char udpTxBuf[UDP_RAW_PACKET_LENGTH];
extern unsigned char cmpTxBuff[UDP_CMP_PACKET_LENGTH];

void udpBuildPacket(unsigned char txbuf[], unsigned short udp_payload);
void udpCamTransmitter(chanend tx, chanend rx, streaming chanend cin);
void udpCmprTransmitter(chanend tx, chanend rx, streaming chanend cin);
void udpConnect(chanend tx);
#endif
