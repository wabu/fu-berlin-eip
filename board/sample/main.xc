#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>
#include "ethernet_server.h"
#include "ethernet_rx_client.h"
#include "ethernet_tx_client.h"
#include "checksum.h"
#include "cam.h"
#include "udp.h"
#include "conf.h"
#include "averaging.h"

mii_interface_t mii = {
		XS1_CLKBLK_1,
		XS1_CLKBLK_2,
		XS1_PORT_1N,
		XS1_PORT_1O,
		XS1_PORT_4F,
		XS1_PORT_1M,

		XS1_PORT_1P,
		XS1_PORT_1I,
		XS1_PORT_4E
};

out port p_mii_resetn = XS1_PORT_1J;
smi_interface_t smi = {XS1_PORT_1H, XS1_PORT_1G, 0};


clock clk_smi = XS1_CLKBLK_5;


int main()
{
	chan rx[1], tx[1];
	streaming chan camData;
	streaming chan resData1;
	streaming chan udpData1;
	streaming chan udpData3;

	int mac_address[2];


	mac_address[0] = (MAC_SRC_3 << 24) |(MAC_SRC_2 << 16) | (MAC_SRC_1 << 8) | MAC_SRC_0;
	mac_address[1] = (MAC_SRC_5 << 8) | MAC_SRC_4;

	phy_init(clk_smi, portClk, p_mii_resetn, smi, mii);

	cam_Init();
	// AutoExposure aus
	cam_WriteRegValue(0x70, 0x00);
	// kein Flip, 4x4 Subsampling
	cam_WriteRegValue(0x01, 0x01);
	// IntegrationTime HIGH
	cam_WriteRegValue(0x73, 0x0D);
	// IntegrationTime MIDDLE
	cam_WriteRegValue(0x74, 0x40);
	// IntegrationTime LOW
	cam_WriteRegValue(0x75, 0x00);

	par
	{
		ethernet_server(mii, portClk, mac_address, rx, 1, tx, 1, null,null);
		udpTransmitter(tx[0], rx[0], udpData1, udpData3);
		averaging_FirstStep(camData, resData1);
		averaging_SecondStep(resData1, udpData1);
		cam_DataCapture(camData);
		while(1);

	}

	return 0;
}
