#include <platform.h>
#include <stdlib.h>
#include <stdio.h>

#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include <ethernet_server.h>
#include <ethernet_rx_client.h>
#include <ethernet_tx_client.h>
#include <checksum.h>
#include <cam.h>
#include <i2c.h>
/* our codec implementation  */
#include <config.h>
#include "format.h"
#include "netconf.h"
#include "test.h"
#include "udp.h"

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
    int type;

    int w=VID_WIDTH;
    int h=VID_HEIGHT;

	chan rx[1], tx[1];
	streaming chan camData;
	streaming chan cmprData;
    streaming chan udpData;
    
    unsigned char x;

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
    tst_setup(w,h);
         
    type = UDP_DATA_TYPE_CMPR3;

    switch (type) {
    case UDP_DATA_TYPE_RAW:
        par {
            ethernet_server(mii, portClk, mac_address, rx, 1, tx, 1, null,null);

            udpCamTransmitter(tx[0], rx[0], camData);
            cam_DataCapture(camData);
        }
        break;
    case UDP_DATA_TYPE_CMPR:
        par
        {
            ethernet_server(mii, portClk, mac_address, rx, 1, tx, 1, null,null);

            udpCmprTransmitter(tx[0], rx[0], cmprData, type);
            cmpr_encoder(camData, cmprData, w, h);
            // cam_DataCapture(camData);
            tst_run_debug_video(camData);
        }
        break;
    case UDP_DATA_TYPE_CMPR3:
        par
        {
            ethernet_server(mii, portClk, mac_address, rx, 1, tx, 1, null,null);

            udpCmprTransmitter(tx[0], rx[0], cmprData, type);
            cmpr3_encoder(camData, cmprData, w, h);
            // cam_DataCapture(camData);
            tst_run_debug_video(camData);
            //tst_run_frame_statistics(udpData,w,h);
        }
        break;
    }
            //cmpr_encoder_with_bypass(camData, udpData, cmprData, w, h);
            //cmpr3_decoder(cmprData, udpData, w,h);
            //tst_run_debug_output(udpData);

	return 0;
}
