#include <print.h>
#include <stdlib.h>
#include "udp.h"
#include "ethernet_tx_client.h"
#include "ethernet_rx_client.h"
#include "delays.h"
#include "conf.h"
#include "print.h"

unsigned int udpTxBuf[380];

void set_filter(chanend tx, chanend rx, const unsigned char own_mac_addr[6]) {
	struct mac_filter_t f;

	// ARP
	f.opcode = OPCODE_AND;
	for (int i = 0; i < 6; i++) {
		f.dmac_msk[i] = 0xFF;
		f.dmac_val[i] = 0xFF;
		f.vlan_msk[i] = 0;
	}
	f.vlan_val[0] = 0x08;
	f.vlan_val[1] = 0x06;
	f.vlan_msk[0] = 0xFF;
	f.vlan_msk[1] = 0xFF;
	if (mac_set_filter(rx, 0, f) == -1) {
		printstr("Filter configuration failed (1)\n");
		exit(1);
	}

	// IP (ICMP/UDP)
	f.opcode = OPCODE_AND;
	for (int i = 0; i < 6; i++) {
		f.dmac_msk[i] = 0xFF;
		f.dmac_val[i] = own_mac_addr[i];
		f.vlan_msk[i] = 0;
	}
	f.vlan_val[0] = 0x08;
	f.vlan_val[1] = 0x00;
	f.vlan_msk[0] = 0xFF;
	f.vlan_msk[1] = 0xFF;
	if (mac_set_filter(rx, 1, f) == -1) {
		printstr("Filter configuration failed (2)\n");
		exit(1);
	}

	printstr("Filter configured\n");
}

void udpConnect(chanend tx) {

	unsigned char own_mac_addr[6];

	own_mac_addr[0] = MAC_SRC_0;
	own_mac_addr[1] = MAC_SRC_1;
	own_mac_addr[2] = MAC_SRC_2;
	own_mac_addr[3] = MAC_SRC_3;
	own_mac_addr[4] = MAC_SRC_4;
	own_mac_addr[5] = MAC_SRC_5;

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

void setUDPData(unsigned char txbuf[], unsigned short lineNum,
		unsigned char data[]) {
	txbuf[42] = lineNum;
	txbuf[43] = (lineNum >> 8);

	//txbuf[19] = lineNum;
	//txbuf[18] = (lineNum >> 8);


	for (int i = 0; i < 1280; i++)
		txbuf[44 + i] = data[i];

	//setIPCheckSum(txbuf);

}

void udpBuildPacket(unsigned char txbuf[]) {

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
	txbuf[16] = (UDP_DATA_LENGTH + 28) >> 8;
	txbuf[17] = (UDP_DATA_LENGTH + 28) & 0xFF;
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
	txbuf[24] = 0xB8;
	txbuf[25] = 0x79;
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
	txbuf[38] = (UDP_DATA_LENGTH + 8) >> 8;
	txbuf[39] = (UDP_DATA_LENGTH + 8) & 0xFF;
	// Prüfsumme -> 0x0000 (Disabled) (2 Bytes)
	txbuf[40] = 0x00;
	txbuf[41] = 0x00;
	// Daten löschen
	for (int i = 0; i < UDP_DATA_LENGTH; i++)
		txbuf[42 + i] = 0;

	setIPCheckSum(txbuf);

}
#pragma unsafe arrays
void udpTransmitter(chanend tx, chanend rx, streaming chanend data1, streaming chanend data2)
{
	int y = 0;
	int i = 0;
	unsigned int t = 0;
	unsigned int data;
	int pUdpBuff = 11;
	udpConnect(tx);
	//set_filter(tx, rx, own_mac_addr);
	udpBuildPacket((udpTxBuf, unsigned char[]));

	set_thread_fast_mode_on();
	while (1)
	{
		select
		{
			case data1 :> udpTxBuf[pUdpBuff++]:
				break;
			case data2 :> data:
				if (data == 0xFEFEFEFE)
				{
					i = 1;
				}
				else if (data == 0xFFFFFFFF)
				{
					(udpTxBuf, unsigned short[]) [21] = 0xFFFF;
					(udpTxBuf, unsigned short[]) [22] = t;
					mac_tx(tx, udpTxBuf, UDP_PACKET_LENGTH, ETH_BROADCAST);
					i = 0;
					t = 0;
				}
				else if (i == 1)
				{
					udpTxBuf[12+t] = data;
					t++;
				}
				break;
			default:
				if ( pUdpBuff == (CAM_PIXEL_WIDTH + 11) )
				{
					pUdpBuff = 11;
					(udpTxBuf, unsigned short[]) [21] = y++;
					mac_tx(tx, udpTxBuf, UDP_PACKET_LENGTH, ETH_BROADCAST);
					if (y == CAM_PIXEL_HEIGHT)
						y = 0;
				}
			break;
		}
	}
}
