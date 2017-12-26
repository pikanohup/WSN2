
#include "Calculate.h"

module RandomSenderP
{
	uses interface Boot;
	uses interface Leds;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl;
	uses interface Timer<TMilli> as Timer0;
	uses interface Random;
	uses interface ParameterInit<uint16_t> as SeedInit;
	uses interface Read<uint16_t>;
}
implementation
{
	event void Boot.booted()
	{
		while(SUCCESS != call Read.read())
			;
	}
	
	event void Read.readDone(error_t result, uint16_t data)
	{
		call SeedInit.init(data);
		while(SUCCESS != call SplitControl.start())
			;
	}
	
	event void SplitControl.startDone(error_t err)
	{
		if(err != SUCCESS)
			call SplitControl.start();
		else
			call Timer0.startPeriodic(10);
	}
	
	event void SplitControl.stopDone(error_t err) { }
	
	message_t queue[12];
	int qh = 0, qt = 0;
	
	void queue_in(data_packge* dp)
	{
		if((qh+1)%12 == qt)
			return;
		memcpy(
			call Packet.getPayload(&queue[qh], sizeof(data_packge))
			, dp, sizeof(data_packge));
		qh = (qh+1)%12;
	}
	
	task void senddp()
	{
		if(SUCCESS != call
			AMSend.send(AM_BROADCAST_ADDR, &queue[qt], sizeof(data_packge))
			)
			post senddp();
	}
	
	uint16_t count = 0;
	uint32_t nums[2000];
	uint32_t seed = 1;
	
	event void Timer0.fired()
	{
		data_packge dp;
		dp.sequence_number = count%2000 + 1;
        //send from 1 ... 2000
		if(count < 2000)
		{
			nums[count] = seed % 5000;
			seed = seed + 1;
		}
		dp.random_integer = nums[count%2000];
		queue_in(&dp);
		post senddp();
		count++;
		if(count%100 == 0)
			call Leds.led0Toggle();
		if(count % 2000 == 0)
			call Leds.led1Toggle();
	}
	
	event void AMSend.sendDone(message_t* msg, error_t err)
	{
		if(msg == &queue[qt] && err == SUCCESS)
			qt = (qt+1)%12;
		if(qt != qh)
			post senddp();
	}
}
