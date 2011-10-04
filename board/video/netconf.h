#ifndef CONF_H_
#define CONF_H_

// UDP Quellport
#define UDP_SRC_PORT 	1060
// UDP Zielport
#define UDP_DES_PORT 	12345

// UDP Quell-IP
#define IP_SRC_0	192
#define IP_SRC_1	168
#define IP_SRC_2	0
#define IP_SRC_3	27

// UDP Ziel-IP
#define IP_DES_0	192
#define IP_DES_1	168
#define IP_DES_2	0
#define IP_DES_3	10
//Broadcast
//#define IP_DES_0	0xFF
//#define IP_DES_1	0xFF
//#define IP_DES_2	0xFF
//#define IP_DES_3	0xFF

// Ethernet Quell-MAC
#define MAC_SRC_0	0x00
#define MAC_SRC_1	0x04
#define MAC_SRC_2	0xAA
#define MAC_SRC_3	0xBB
#define MAC_SRC_4	0xCC
#define MAC_SRC_5	0xDD
// Ethernet Ziel-MAC
#define MAC_DES_0	0x00
#define MAC_DES_1	0x22
#define MAC_DES_2	0x68
#define MAC_DES_3	0x0c
#define MAC_DES_4	0x9f
#define MAC_DES_5	0x19
//Broadcast
//#define MAC_DES_0	0xFF
//#define MAC_DES_1	0xFF
//#define MAC_DES_2	0xFF
//#define MAC_DES_3	0xFF
//#define MAC_DES_4	0xFF
//#define MAC_DES_5	0xFF

// Bildgröße
#define UDP_PIXEL_WIDTH 160


#endif
