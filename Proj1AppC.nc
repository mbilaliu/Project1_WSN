#include <Timer.h>
#include "Proj1.h"


configuration Proj1AppC{
}
implementation{
	
	components MainC;
	components Proj1C as App;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components ActiveMessageC;
	components new AMSenderC (ASKED);
	
	components LedsC;
	components new AMReceiverC(ASKED);
	
	
	
	App.Boot -> MainC;
	App.Timer0 -> Timer0;
	App.Timer1 -> Timer1;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	App.PacketAck -> ActiveMessageC;
	
	App.Leds -> LedsC;
	App.Receive -> AMReceiverC;

}
