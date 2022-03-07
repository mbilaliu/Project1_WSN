#ifndef PROJ1_H
#define PROJ1_H

enum 
{
	ASKED = 6,
	TIMER_PERIOD_MILLI = 2048,
	TIMER_PERIOD_MILLI_NEW = 5240
};

typedef nx_struct ProjMsg
{
	nx_uint16_t nodeid;
	nx_uint16_t counter;
	nx_uint16_t lostpackets;
} ProjMsg;

#endif /* PROJ1_H */
