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
//#define IP_DES_0	192
//#define IP_DES_1	168
//#define IP_DES_2	0
//#define IP_DES_3	10
//Broadcast
#define IP_DES_0	0xFF
#define IP_DES_1	0xFF
#define IP_DES_2	0xFF
#define IP_DES_3	0xFF

// Ethernet Quell-MAC
#define MAC_SRC_0	0x00
#define MAC_SRC_1	0x04
#define MAC_SRC_2	0xAA
#define MAC_SRC_3	0xBB
#define MAC_SRC_4	0xCC
#define MAC_SRC_5	0xDD

// Ethernet Ziel-MAC
//#define MAC_DES_0	0x00
//#define MAC_DES_1	0xE0
//#define MAC_DES_2	0x52
//#define MAC_DES_3	0xBE
//#define MAC_DES_4	0x50
//#define MAC_DES_5	0xE8
//Broadcast
#define MAC_DES_0	0xFF
#define MAC_DES_1	0xFF
#define MAC_DES_2	0xFF
#define MAC_DES_3	0xFF
#define MAC_DES_4	0xFF
#define MAC_DES_5	0xFF

// Bildgröße
#define UDP_PIXEL_WIDTH 640


#endif
