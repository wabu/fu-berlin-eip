#include <print.h>
#include <stdlib.h>
#include <stdio.h>
#include <cam.h>
#include <delays.h>
#include <ethernet_tx_client.h>
#include <ethernet_rx_client.h>
#include <mii.h>

#include "udp.h"
#include "netconf.h"
#include "video.h"

unsigned char udpTxBuf[UDP_RAW_PACKET_LENGTH];
unsigned char cmpTxBuf[UDP_CMP_PACKET_LENGTH];

void udpConnect(chanend tx) {

	unsigned char own_mac_addr[6];

	printstr("Connecting...\n");
	{
		timer tmr;
		unsigned t;
		tmr :> t; tmr when timerafter(t + 600000000) :> t;}

	if (mac_get_macaddr(tx, own_mac_addr) != 0)
	{
		printstr("Get MAC address failed\n");
		exit(1);
	}
	printstr("Ethernet initialised\n");
}

void setIPCheckSum(unsigned char buff[]) {
	unsigned short word16;
	unsigned int sum = 0;
	unsigned short i;

	buff[24] = 0;
	buff[25] = 0;
	// make 16 bit words out of every two adjacent 8 bit words in the packet
	// and add them up
	for (i = 0; i < 20; i = i + 2) {
		word16 = ((buff[i + 14] << 8) & 0xFF00) + (buff[i + 15] & 0xFF);
		sum = sum + (unsigned int) word16;
	}

	// take only 16 bits out of the 32 bit sum and add up the carries
	while (sum >> 16)
		sum = (sum & 0xFFFF) + (sum >> 16);

	// one's complement the result
	sum = ~sum;

	buff[24] = sum >> 8;
	buff[25] = sum;

}

void udpBuildPacket(unsigned char txbuf[], unsigned short udp_payload) {
	// Ethernet Header
	// Ziel MAC (6Bytes)
	txbuf[0] = MAC_DES_0;
	txbuf[1] = MAC_DES_1;
	txbuf[2] = MAC_DES_2;
	txbuf[3] = MAC_DES_3;
	txbuf[4] = MAC_DES_4;
	txbuf[5] = MAC_DES_5;
	// Quell MAC (6Bytes)
	txbuf[6] = MAC_SRC_0;
	txbuf[7] = MAC_SRC_1;
	txbuf[8] = MAC_SRC_2;
	txbuf[9] = MAC_SRC_3;
	txbuf[10] = MAC_SRC_4;
	txbuf[11] = MAC_SRC_5;
	// Typ - IP (2 Bytes)
	txbuf[12] = 0x08;
	txbuf[13] = 0x00;
	// IP Header
	// Version (v4) / IP-Header-Length(5*32bit->20Byte) (4 + 4 Bit = 1 Byte)
	txbuf[14] = 0x45;
	// Type Of Service (0 - Normal) (1 Byte)
	txbuf[15] = 0x00;
	// Total Length = Länge IP Header + UDP Header + UDP_DATA_LENGTH = 20 + 8 + UDP Daten
	txbuf[16] = (udp_payload + 28) >> 8;
	txbuf[17] = (udp_payload + 28) & 0xFF;
	// Identification (2 Bytes) -Irgendeine Nummer
	txbuf[18] = 0x00;
	txbuf[19] = 0x40;
	// Flags / FragmentOffset -> 0, keine Fragmente (2 Bytes)
	txbuf[20] = 0x00;
	txbuf[21] = 0x00;
	// Time To Life -> Irgendwas (1 Byte)
	txbuf[22] = 0x80;
	// Folgeprotokoll (UDP = 0x11) (1 Byte)
	txbuf[23] = 0x11;
	// Header Checksum (2 Bytes)
	txbuf[24] = 0x79;
	txbuf[25] = 0x28;
	// Source Address
	txbuf[26] = IP_SRC_0;
	txbuf[27] = IP_SRC_1;
	txbuf[28] = IP_SRC_2;
	txbuf[29] = IP_SRC_3;
	// Destination Address
	txbuf[30] = IP_DES_0;
	txbuf[31] = IP_DES_1;
	txbuf[32] = IP_DES_2;
	txbuf[33] = IP_DES_3;
	// UDP Header
	// Quell-Port (2 Bytes)
	txbuf[34] = UDP_SRC_PORT >> 8;
	txbuf[35] = (UDP_SRC_PORT & 0xFF);
	// Ziel-Port 2 Bytes)
	txbuf[36] = UDP_DES_PORT >> 8;
	txbuf[37] = (UDP_DES_PORT & 0xFF);
	// Länge = Header + Daten = 8 + UDP_DATA_LENGTH = 1290 (2 Bytes)
	txbuf[38] = (udp_payload + 8) >> 8;
	txbuf[39] = (udp_payload + 8) & 0xFF;
	// Prüfsumme -> 0x0000 (Disabled) (2 Bytes)
	txbuf[40] = 0x00;
	txbuf[41] = 0x00;
	// Daten löschen
	for (int i = 0; i < udp_payload; i++)
		txbuf[42 + i] = 0;


}


void udpCmprTransmitter(chanend tx, chanend rx, streaming chanend cin, int type) {
    unsigned short seq = 0;
    unsigned short off = 0;

    udpConnect(tx);
    udpBuildPacket(cmpTxBuf, UDP_CMP_PAYLOAD_LENGTH);
	cmpTxBuf[24] = 0x78;
	cmpTxBuf[25] = 0xf8;
    cmpTxBuf[42] = type;
    // seq is implicit set to zero in initial udp packet
    off = 45;
    while(1) {
        cin :> cmpTxBuf[off++];
        if (off >= UDP_CMP_PACKET_LENGTH) {
            mac_tx(tx, (cmpTxBuf, unsigned int[]), UDP_CMP_PACKET_LENGTH, ETH_BROADCAST);
            seq++;
            cmpTxBuf[43] = seq >> 8;
            cmpTxBuf[44] = seq & 0xFF;
            off = 45;
        }
    }
}

void udpCamTransmitter(chanend tx, chanend rx, streaming chanend cin)
{
    unsigned short frame = 0;
	unsigned char line = 0;
	unsigned char off = 0;
	unsigned int data;
    vid_init(cin);

	udpConnect(tx);
	udpBuildPacket(udpTxBuf, UDP_RAW_PAYLOAD_LENGTH);
    udpTxBuf[42] = UDP_DATA_TYPE_RAW;

	set_thread_fast_mode_on();

    vid_with_frames(cin) {
        udpTxBuf[43] = frame >> 8;
        udpTxBuf[44] = frame & 0xFF;
        line = 0;

        vid_with_lines(cin) {
            vid_with_ints(data, cin) {
                if ((52 + off) > UDP_RAW_PACKET_LENGTH) {
                    printf("EE packet length exceeded\n");
                    continue;
                }
                // start line data at byte 49
                for (int p=3;p>=0;p--) {
                    udpTxBuf[48+off++] = (data >> 8*p) & 0xFF;
                }
            }
    		udpTxBuf[45] = line;
            mac_tx(tx, (udpTxBuf, unsigned int[]), UDP_RAW_PACKET_LENGTH, ETH_BROADCAST);
            //printf("INFO send RAW [f=%d,l=%d,o=%d]!?\n", frame, line, off*4);
  			off = 0;
            line++;
        }
        frame++;
    }
}

