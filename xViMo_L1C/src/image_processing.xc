#include "image_processing.h"
#include "conf.h"
#include "stdlib.h"
#include "ethernet_tx_client.h"
#include "ethernet_rx_client.h"
#include "udp.h"


#pragma unsafe arrays
void imgproc_FirstStep(streaming chanend dataIn, streaming chanend dataOut, streaming chanend udpDataOut)
{
	unsigned char camPix;
	unsigned char result = 0;

	set_thread_fast_mode_on();
	while(1)
	{
		// Kamerapixel aus 8 Bit dataIn-Channel holen
		// Pixel befindet sich dann in camPix
		dataIn :> camPix;

		//.....Bild-Pixelverarbeitung

		// Verarbeitungsergebnis evtl. zum nächsten Verarbeitungsschritt schicken
		dataOut <: result;
		// Original Kamerapixel (Bit0:7) und Verarbeitungsergebnis(Bit8:15) an udpDaten hängen
		udpDataOut <: (unsigned int)camPix || ((unsigned int)result << 8);
	}
}

