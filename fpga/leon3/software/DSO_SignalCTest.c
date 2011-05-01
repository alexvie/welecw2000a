/****************************************************************************
* Project        : Welec W2000A
*****************************************************************************
* File           : DSO_SignalCTest.c
* Author         : Alexander Lindert <alexander_lindert at gmx.at>
* Date           : 20.04.2009
*****************************************************************************
* Description	 : 
*****************************************************************************

*  Copyright (c) 2009, Alexander Lindert

*  This program is free software; you can redistribute it and/or modify
*  it under the terms of the GNU General Public License as published by
*  the Free Software Foundation; either version 2 of the License, or
*  (at your option) any later version.

*  This program is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.

*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software
*  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*  For commercial applications where source-code distribution is not
*  desirable or possible, I offer low-cost commercial IP licenses.
*  Please contact me per mail.

*****************************************************************************
* Remarks		: -
* Revision		: 0
****************************************************************************/


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "grcommon.h"
#include "DSO_SignalCapture.h"
#include "Leon3Uart.h"
#include "DSO_Remote_Slave.h"
#include "DSO_Remote.h"
#include "DSO_SFR.h"
#include "DSO_Screen.h"
#include "DSO_FrontPanel.h"
#include "Filter_I8.h"
#include "irqmp.h"
#include "DSO_Misc.h"
#include "DSO_GUI.h"
#include "rprintf.h"
#include "irq.h"
#include "timer.h"

#ifdef SIM_COMPILATION
#define SendStringBlock(A,B) 
#define rprintf(...)
#endif

#define FASTFS 1000000000
#define SLOWFS    500000

/* The generic uart is used normally by printf and scanf on LEON3 systems! 
 * So the SandboxX takes the generic uart with the DEBUG_UART_BASE_ADDR for 
 * the communication protocol. This is not possible for W2000A devices!
 * The W2000A devices do only have one uart, which is useable by the software.
 * So there is a need for a debug message header and therefore stdout 
 * must be redirected to another function. For this only _write_r and _read_r
 * need to be redirected */

#if 0
long _write_r ( struct _reent *ptr, int fd, const void *buf, size_t cnt ) {
#ifdef BOARD_COMPILATION
	register uint32_t i = 0;
	register char * buffer = (char*) buf;
	WRITE_INT(DSO_SFR_BASE_ADDR,7);
	DrawBox(COLOR_R3G3B3(cnt,7,7),30,470,39,479);
/*	SendStringBlock(GENERIC_UART_BASE_ADDR,buf);*/
#ifdef W2000A
//	SendStringBlock((uart_regs*)GENERIC_UART_BASE_ADDR,DSO_SEND_HEADER);
//	SendStringBlock((uart_regs*)GENERIC_UART_BASE_ADDR,DSO_MESSAGE_RESP);
#endif
/*	SendStringBlock((uart_regs*)GENERIC_UART_BASE_ADDR,buffer);*/
	for (i = 0; i < cnt; ++i){
		SendCharBlock((uart_regs*)GENERIC_UART_BASE_ADDR,*buffer);
		buffer++;
	}
#ifdef W2000A
//	SendCharBlock((uart_regs*)GENERIC_UART_BASE_ADDR,'\0');
#endif 
#endif
	return cnt;
}
/* do not use scanf or so, if you don't now exactly what you doing! */
long _read_r ( struct _reent *ptr, int fd, const void *buf, size_t cnt ) {
#ifdef BOARD_COMPILATION
	volatile int dummy = 0;
	register uint32_t i = 0;
	char * buffer = (char*)buf;
	WRITE_INT(DSO_SFR_BASE_ADDR,dummy);
/*	ReceiveStringBlock(GENERIC_UART_BASE_ADDR,buf,&cnt);*/
	for (i = 0; i < cnt; ++i){
		buffer[i] = ReceiveCharBlock((uart_regs*)GENERIC_UART_BASE_ADDR);
	}
#endif
	return cnt;

}
#endif 
#if 1
void rprintc(unsigned data){
	SendCharBlock(REMOTE_UART,(char)data);
}	
#endif

#ifdef SIM_COMPILATION
int __main__() {
	return 0;
}
#endif

uSample Data[CAPTURESIZE];

int main (void) 
{
	
	uart_regs * uart = (uart_regs *)GENERIC_UART_BASE_ADDR;
#ifdef SBX
	uart_regs * uart2 = (uart_regs *)DEBUG_UART_BASE_ADDR;
#endif
	uint32_t ReadData = 0;

#ifdef SIM_COMPILATION
	SetAnalog Analog[2];
	
//	uint32_t i = 0;
//	uint32_t Prefetch = 64;
//	char x = 0;

//	char ack[] = "success!\n";
//	char nak[] = "failed!\n";

	Analog[0].myVperDiv = 10000;
	Analog[0].AC = 0;
	Analog[0].Mode = normal;
	Analog[0].DA_Offset = 0xaa;
//	Analog[0].PWM_Offset = 0xf1;
	Analog[1].myVperDiv = 10000;
	Analog[1].AC = 1;
	Analog[1].Mode = normal;
	Analog[1].DA_Offset = 0xf1;
//	Analog[1].PWM_Offset = 0xf1;
#endif
	
	/* This is a workaround to share the serial port with the debug uart 
	 * and the generic uart on the W2000A! */
	WaitMs(100);
	WRITE_INT(CONFIGADCENABLE,0); /* selecting the generic uart for the W2000A */
	/*WaitMs(1000);*/
//	while(1);
	InitSignalCapture();
	UartInit(FIXED_CPU_FREQUENCY,DSO_REMOTE_UART_BAUDRATE, 
			FIFO_EN | ENABLE_RX | ENABLE_TX | RX_INT /*| LOOP_BACK*/, uart);
#ifdef SBX
	UartInit(FIXED_CPU_FREQUENCY,DSO_REMOTE_UART_BAUDRATE, 
			FIFO_EN | ENABLE_RX | ENABLE_TX | RX_INT /*| LOOP_BACK*/, uart2);
#endif
/*	InitIRQ();*/
//	while(1);


/* Uart communication test */
#ifdef SBX	
/*	for (i = 0; i < 256; ++i){
		SendStringBlock(uart2,"Test ");
	}
	for (i = 0; i < 1024; ++i){
		x = ReceiveCharBlock(uart2);
		SendCharBlock(uart2,x);
	}

	WRITE_INT(DSO_SFR_BASE_ADDR,x);
	x = ReceiveCharBlock(uart2);
	WRITE_INT(DSO_SFR_BASE_ADDR,x);
	WRITE_INT(DSO_SFR_BASE_ADDR,-1);*/
#endif
/*	SendStringBlock(uart,"Test console uart SendStringBlock send a letter received = ");
	x = ReceiveCharBlock(uart);
	SendCharBlock(uart,x);
	SendCharBlock(uart,'\n');
	WRITE_INT(DSO_SFR_BASE_ADDR,x);*/
/* The volatile read accesses do not work, this can be seen in simulation!
 * Look in the wave window and you will not find this two read accesses. 
 * To read volatile use the working function loadmem instead! */
/*	READ_INT(DSO_SFR_BASE_ADDR,x);
	READ_INT(DSO_SFR_BASE_ADDR,x);
	WRITE_INT(DSO_SFR_BASE_ADDR,-2);
	printf("Test console uart: write a letter\n");
	scanf("%c",&x);
	printf("Test console uart success received %c\n",x);
	while(1);*/

#ifdef W2000A
#ifdef BOARD_COMPILATION
	InitDisplay(WELEC2022);
//	DrawTest();
/*	while(1);*/
#endif 
#endif

	/* This is a basic function test of the SignalCapture part */
	/* turning all DSO interrupts off (RESET) */
	/* switching all DSO interrupts on */
	/* Enable the interrupt the interrupt controller */
	init_irq();

#ifdef SIM_COMPILATION
	printf("DSO Test programm: \nstart testing SetTriggerInput \n");
	if (SetTriggerInput(2,8,FASTFS,FIXED_CPU_FREQUENCY,0,0,0,1,2,3) == true){
		printf(ack);
	} else {
		printf(nak);
	}
	printf("testing SetTrigger\n");
	if (SetTrigger(4,0,0,64,3,0,30,1) == true){
		printf(ack);
	} else {
		printf(nak);
	}
/* The analog settings do not work for now!
 * If you want to simulate this, you need to change cAnSettStrobeRate 
 * at least to 1E6 in the target dependent DSOConfig-p.vhd 
 * to speed up the simulation */
	/*
	printf("testing SetAnalogInputRange\n");
	if (SetAnalogInputRange(2,Analog) == true){
		printf(ack);
	} else {
		printf(nak);
	}*/
	/* with filtering */
	SetTriggerInput(2,16,FASTFS/100,FIXED_CPU_FREQUENCY,0,4,0,1,2,3);
	ReadData = CaptureData(1000, true, false, 100, (uint32_t*)Data);

	/* without filtering */
	printf("testing FastCapture\n"); 
	WRITE_INT(DSO_SFR_BASE_ADDR,1);
	ReadData = CaptureData(1000, true, false, 100, (uint32_t*)Data);
	
	WRITE_INT(DSO_SFR_BASE_ADDR,2);
	SetTriggerInput(2,8,FASTFS/2,FIXED_CPU_FREQUENCY,0,0,0,1,2,3);
	ReadData = CaptureData(1000, true, false, 100, (uint32_t*)Data);

	WRITE_INT(DSO_SFR_BASE_ADDR,4);
	SetTriggerInput(2,8,FASTFS/4,FIXED_CPU_FREQUENCY,0,0,0,1,2,3);
	ReadData = CaptureData(1000, true, false, 100, (uint32_t*)Data);

	WRITE_INT(DSO_SFR_BASE_ADDR,8);
	SetTriggerInput(2,8,FASTFS/8,FIXED_CPU_FREQUENCY,0,0,0,1,2,3);
	ReadData = CaptureData(1000, true, false, 100, (uint32_t*)Data);

	WRITE_INT(DSO_SFR_BASE_ADDR,10);
	SetTriggerInput(2,8,FASTFS/10,FIXED_CPU_FREQUENCY,0,0,0,1,2,3);
	ReadData = CaptureData(1000, true, false, 100, (uint32_t*)Data);

	/* with filtering */
	SetTriggerInput(2,16,FASTFS/1,FIXED_CPU_FREQUENCY,0,4,0,1,2,3);
	ReadData = CaptureData(1000, true, false, 100, (uint32_t*)Data);

	SetTriggerInput(2,16,FASTFS/2,FIXED_CPU_FREQUENCY,0,4,0,1,2,3);
	ReadData = CaptureData(1000, true, false, 100, (uint32_t*)Data);

	SetTriggerInput(2,16,FASTFS/4,FIXED_CPU_FREQUENCY,0,4,0,1,2,3);
	ReadData = CaptureData(1000, true, false, 100, (uint32_t*)Data);

	SetTriggerInput(2,16,FASTFS/8,FIXED_CPU_FREQUENCY,0,4,0,1,2,3);
	ReadData = CaptureData(1000, true, false, 100, (uint32_t*)Data);

	SetTriggerInput(2,16,FASTFS/10,FIXED_CPU_FREQUENCY,0,4,0,1,2,3);
	ReadData = CaptureData(1000, true, false, CAPTURESIZE, (uint32_t*)Data);

	
	printf("testing NormalCapture\n");
	SetTriggerInput(2,8,SLOWFS,FIXED_CPU_FREQUENCY,0,0,0,1,2,3);
	SetTrigger(0,0,0,64,3,0,30,1);
	ReadData = CaptureData(10000, true, false, CAPTURESIZE, (uint32_t*)Data);


#endif


/*	ReadData = 3;
	printf(M6);
	ReceiveStringBlock(uart, M6, &ReadData);
	M6[ReadData] = '\0';
	printf(M6);
	SendCharBlock(uart,'\n');*/

/*	printf("\nStarting the remote control\n");
	RemoteSlave(REMOTE_UART,CAPTURESIZE,(uint32_t*)Data);*/

#ifdef W2000A
#ifdef BOARD_COMPILATION

	/* Test routine for SRAM write accesses */
	WRITE_INT(CONFIGADCENABLE,0); /* selecting the generic uart for the W2000A */
	ReadData = 0;
	while (ReadData == 0) { // no timeout error
		Data[0].c[0] = ReceiveChar(uart,1000,&ReadData);
	}
	DrawTest(); // clear cache
	SendStringBlock(uart,"Send back any letter to begin the test:\n");
	Data[0].c[0] = ReceiveCharBlock(uart);
	SendStringBlock(uart,"Test routine for 4 byte write access: MSB..LSB = 0000\n");
	Data[0].i = 0x30303030;
	SendCharBlock(uart,Data[0].c[0]);
	SendCharBlock(uart,Data[0].c[1]);
	SendCharBlock(uart,Data[0].c[2]);
	SendCharBlock(uart,Data[0].c[3]);
	DrawTest(); // clear cache
	SendStringBlock(uart,"\nTest routine for 2 byte write access: MSB..LSB = 1122\n");
	Data[0].s[0] = 0x3131;
	Data[0].s[1] = 0x3232;
	SendCharBlock(uart,Data[0].c[0]);
	SendCharBlock(uart,Data[0].c[1]);
	SendCharBlock(uart,Data[0].c[2]);
	SendCharBlock(uart,Data[0].c[3]);
	DrawTest(); // clear cache
	SendStringBlock(uart,"\nTest routine for 1 byte write access: MSB..LSB = 3456\n");
	Data[0].c[0] = 0x33;
	Data[0].c[1] = 0x34;
	Data[0].c[2] = 0x35;
	Data[0].c[3] = 0x36;
	SendCharBlock(uart,Data[0].c[0]);
	SendCharBlock(uart,Data[0].c[1]);
	SendCharBlock(uart,Data[0].c[2]);
	SendCharBlock(uart,Data[0].c[3]);

	rprintf("\nrprintf test 1234567 = %d\n",1234567);
	WaitMs(1000);

	WRITE_INT(CONFIGADCENABLE,1); /* selecting the debug uart for the W2000A */
//	printf("\nStartFrontPanelTest\n");
//	FrontPanelTest(uart);
//	printf("\nSignalTest\n");

    	GUI_Main();	
#endif	
#endif


/* UART baudrate test */
/*	while(1){
		SendCharBlock(REMOTE_UART,++x); 
	}*/

	
	return 0;
}

void TestRotNobs(){
//	static int32_t sl = 0;
	static int32_t nob = 0;
	static int32_t kl = 0;
	int32_t kc = 0;	
	int32_t move = 0;

	if ((READ_INT(KEYADDR1) & (1 << BTN_F3)) != 0){
		nob= 0;
	}
	if ((READ_INT(KEYADDR1) & (1 << BTN_F4)) != 0){
		nob= 1;
	}
	if ((READ_INT(KEYADDR1) & (1 << BTN_F5)) != 0){
		nob= 2;
	}
	if ((READ_INT(KEYADDR1) & (1 << BTN_F6)) != 0){
		nob= 3;
	}
	if ((READ_INT(KEYADDR1) & (1 << BTN_CURSORS)) != 0){
		nob= 4;
	}
	if ((READ_INT(KEYADDR1) & (1 << BTN_QUICKMEAS)) != 0){
		nob= 5;
	}
	if ((READ_INT(KEYADDR1) & (1 << BTN_EDGE)) != 0){
		nob= 6;
	}
	if ((READ_INT(KEYADDR1) & (1 << BTN_PULSEWIDTH)) != 0){
		nob= 7;
	}
        
	switch(nob){
		case 0: kc = (READ_INT(LEDADDR) >> EN_TIME_DIV) & 7;	break;
		case 1: kc = (READ_INT(LEDADDR) >> EN_LEFT_RIGHT) & 7;	break;
		case 2: kc = (READ_INT(LEDADDR) >> EN_LEVEL) & 7;	break;
		case 3: kc = (READ_INT(LEDADDR) >> EN_F) & 7;		break;
		case 4: kc = (READ_INT(KEYADDR0) >> EN_CH0_UPDN) & 7;	break;
		case 5: kc = (READ_INT(KEYADDR0) >> EN_CH1_UPDN) & 7;	break;
		case 6: kc = (READ_INT(KEYADDR0) >> EN_CH0_VDIV) & 7;	break;
		case 7: kc = (READ_INT(KEYADDR0) >> EN_CH1_VDIV) & 7;	break;

	}
	ROTARYMOVE(move,kc,kl);
	
	if (move != 0){
		rprintf("kc = %d kl = %d move = %d\n",kc,kl,move);
/*		SendStringBlock((uart_regs*)GENERIC_UART_BASE_ADDR,"kc = ");
		SendCharBlock((uart_regs*)GENERIC_UART_BASE_ADDR,'0' + kc);
		SendStringBlock((uart_regs*)GENERIC_UART_BASE_ADDR," kl = ");
		SendCharBlock((uart_regs*)GENERIC_UART_BASE_ADDR,'0' + kl);
		SendStringBlock((uart_regs*)GENERIC_UART_BASE_ADDR," move = ");
		if (move > 0){
			SendCharBlock((uart_regs*)GENERIC_UART_BASE_ADDR,'0' + move);
		} else {
			SendCharBlock((uart_regs*)GENERIC_UART_BASE_ADDR,'-');
			SendCharBlock((uart_regs*)GENERIC_UART_BASE_ADDR,'0' - move);
		}
		SendCharBlock((uart_regs*)GENERIC_UART_BASE_ADDR, '\n');*/
	}
	
}

