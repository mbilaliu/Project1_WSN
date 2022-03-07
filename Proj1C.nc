#include <Timer.h>
#include "Proj1.h"


module Ack{
	
	uses interface Boot;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface PacketAcknowledgements as PacketAck;
	 
	uses interface Leds;
	uses interface Receive;
		
}

implementation{
	
	uint16_t counter;
	uint16_t new_counter;
	uint16_t LostPackets = 0;
	
	message_t pkt;
	
	bool busy = FALSE;
	bool COUNTER = TRUE;
	
	uint8_t node1 = 0x03;
	uint8_t node2 = 0x04;
	uint8_t node3 = 0x99;
	
	
	event void Boot.booted()
	{
		//dbg_clear ("Application is starting.")		
		call AMControl.start(); //starting the radio 
		call Timer1.startPeriodic(TIMER_PERIOD_MILLI_NEW);
	}
	
	event void AMControl.startDone(error_t err) //starting is successful?
	{
		if (err == SUCCESS)
		{
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
		}
		
		else 
		{
			call AMControl.start();
		}
	}
	
	event void AMControl.stopDone(error_t err)
	{}
	
	event void Timer1.fired()
	{
		node3 = node2;
		node2 = node1;
		node1 = node3;
		//switching nodes roles
		
		dbg("Boot", "SWITCH nodes switched\n");
	}
	
		
	task void DoNothing()
	{}
		
	task void SendMsg()
	{
		ProjMsg* atpkt = (ProjMsg*)(call Packet.getPayload(&pkt, sizeof(ProjMsg)));
		
		if (atpkt == NULL) //check if the atpkt message has been created.
		{
			return;
		}
		
		atpkt->nodeid = TOS_NODE_ID;
		atpkt->counter  = counter;
		atpkt->lostpackets = LostPackets;
		if (atpkt->counter % 0x02 == 0) //checking the node 
		{
			call PacketAck.requestAck(&pkt);
			if (node1 != TOS_NODE_ID) //if both nodes are different
			{
				if (call AMSend.send(node1, &pkt, sizeof (ProjMsg)) == SUCCESS)
			    {
			    	busy = TRUE; 
			    }
			}
			else
			{
				post DoNothing();
			}
		}
		
		else
		{
			call PacketAck.requestAck(&pkt);
			if (node2 != TOS_NODE_ID)
			{
				if (call AMSend.send(node2, &pkt, sizeof(ProjMsg)) == SUCCESS)
			    {
			    	busy = TRUE;
			    }
			}			
			else 
			{
				post DoNothing();
			}
		}
	}
	
	event void Timer0.fired()
	{
		if (COUNTER == TRUE)
		{
			counter++;
		}
		
		if (!busy)
		{
			post SendMsg();
		}
	}
	
	event void AMSend.sendDone(message_t* msg, error_t err)
	{
		if (&pkt == msg && err == SUCCESS)
		{
			busy = FALSE;
			dbg("Ack", "SENTDONE Message was sent @ %s, \n", sim_time_string());
		}
		
		if (call PacketAck.wasAcked(msg))
		{
			COUNTER = TRUE;
			dbg("Ack", "ACKED Acknowledgment recv'ed @ %s, \n", sim_time_string());
			call AMControl.start();
		}
		else
		{
			LostPackets++;
			COUNTER = FALSE;
			dbg("Ack", "LOSTPACKET Packet Lost %s, \n", sim_time_string());
			post SendMsg();
		}
		
	}	
	
	
	
	message_t rpkt;
	
	
	void setLeds(uint16_t val)
	{
		if (val & 0x01)
		     call Leds.led0On();
	    else
	         call Leds.led0Off();
	    if (val & 0x02)
	         call Leds.led1On();
	    else
	         call Leds.led1Off();
	 }
	 
	 event message_t* Receive.receive(message_t* rmsg, void* payload, uint8_t len)
	 {
	 	dbg("Ack", "RECV Received a packet of length %hhu @ %s with payload : %hhu \n", len, sim_time_string(), payload);
	 	
	 	if (len == sizeof(ProjMsg))
	 	{
	 		ProjMsg* atrpkt = (ProjMsg*)payload;
	 		setLeds(atrpkt->counter);
	 	    dbg("Boot", "LED node : %hhu has a counter: %hhu with the number of lost packets: %hhu \n", atrpkt->nodeid, atrpkt->counter, atrpkt->lostpackets);
	 	}
	 	
	 	return rmsg;
	 }
	 
	 
}
