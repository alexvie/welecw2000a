/****************************************************************************
* Project        : Welec W2000A
*****************************************************************************
* File           : DSO_FrontPanel.c
* Author		 : Alexander Lindert <alexander_lindert at gmx.at>
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

#include "DSO_SFR.h"
#include "DSO_Misc.h"
#include "Leon3Uart.h"
#include "stdio.h"
#include "string.h"

#define CLEN 40
void TestKeys(uart_regs * uart, int value , int change, char ** M, int size);


void FrontPanelTest(uart_regs * uart) {
	char Ml[][CLEN] = {
	{" LED_CH"},
	{" LED_CH1"},
	{" LED_CH2"},
	{" LED_CH3"},
	{" LED_MATH"},
	{" LED_QUICKMEAS"},
	{" LED_CURSORS"},
	{" LED_WHEEL"},
	{" LED_PULSEWIDTH"},
	{" LED_EDGE"},
	{" RUN_GREEN"},
	{" RUN_RED"},
	{" SINGLE_GREEN"},
	{" SINGE_RED"}};
	char k0[] =  {" ENX_LEFT_RIGHT"};
	char k1[] =  {" ENY_LEFT_RIGHT"};
	char k2[] =  {" ENX_LEVEL"};
	char k3[] =  {" ENY_LEVEL"};
	char k4[] =  {" ENX_CH_UPDN"};
	char k5[] =  {" ENY_CH_UPDN"};
	char k6[] =  {" ENX_CH1_UPDN"};
	char k7[] =  {" ENY_CH1_UPDN"};
	char k8[] =  {" ENX_CH2_UPDN"};
	char k9[] =  {" ENY_CH2_UPDN"};
	char k10[] = {" ENX_CH3_UPDN"};
	char k11[] = {" ENY_CH3_UPDN"};
	char k12[] = {" ENX_CH_VDIV"};
	char k13[] = {" ENY_CH_VDIV"};
	char k14[] = {" ENX_CH1_VDIV"};
	char k15[] = {" ENY_CH1_VDIV"};
	char k16[] = {" ENX_CH2_VDIV"};
	char k17[] = {" ENY_CH2_VDIV"};
	char k18[] = {" ENX_CH3_VDIV"};
	char k19[] = {" ENY_CH3_VDIV"};
	char * Mk[] = {
		k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, 
		k10, k11, k12, k13, k14, k15, k16, k17, k18, k19};

	char k20[] = {" BTN_F1"};
	char k21[] = {" BTN_F2"};
	char k22[] = {" BTN_F3"};
	char k23[] = {" BTN_F4"};
	char k24[] = {" BTN_F5"};
	char k25[] = {" BTN_F6"};
	char k26[] = {" BTN_MATH"};
	char k27[] = {" BTN_CH"};
	char k28[] = {" BTN_CH1"};
	char k29[] = {" BTN_CH2"};
	char k30[] = {" BTN_CH3"};
	char k31[] = {" BTN_MAINDEL"};
	char k32[] = {" BTN_RUNSTOP"};
	char k33[] = {" BTN_SINGLE"};
	char k34[] = {" BTN_CURSORS"};
	char k35[] = {" BTN_QUICKMEAS"};
	char k36[] = {" BTN_ACQUIRE"};
	char k37[] = {" BTN_DISPLAY"};
	char k38[] = {" BTN_EDGE"};
	char k39[] = {" BTN_MODECOUPLING"};
	char k40[] = {" BTN_AUTOSCALE"};
	char k41[] = {" BTN_SAVERECALL"};
	char k42[] = {" BTN_QUICKPRint"};
	char k43[] = {" BTN_UTILITY"};
	char k44[] = {" BTN_PULSEWIDTH"};
	char k45[] = {" BTN_X1"};
	char k46[] = {" BTN_X2"};
	char k47[] = {" ENX_TIME_DIV"};
	char k48[] = {" ENY_TIME_DIV"};
	char k49[] = {" ENX_F"};
	char k50[] = {" ENY_F"};
	char * Mk1[] = {
		k20, k21, k22, k23, k24, k25, k26, k27, k28, k29, 
		k30, k31, k32, k33, k34, k35, k36, k37, k38, k39,
		k40, k41, k42, k43, k44, k45, k46, k47, k48, k49, k50};
		

	volatile uint32_t * addr = (int *)LEDADDR;
	int i = 0;
	int c = -1;
	int c1 = -1;
	int value = 0;
	char M[80];
	
	/* led test */
	
	for (i = 0; i < 14; ++i){
//		sprintf(M,"Switching leds %s on!\n",&Ml[i*CLEN]);
//		SendStringBlock(GENERIC_UART_BASE_ADDR,M);
		WaitMs(20);
		*addr |= (1 << i);
	}

	for (i = 0; i < 14; ++i){
//		sprintf(M,"Switching leds %s off!\n",&Ml[i*CLEN]);
//		SendStringBlock(GENERIC_UART_BASE_ADDR,M);
		WaitMs(20);
		*addr &= ~(1 << i);
	}

	for (i = 0; i < 14; ++i){
//		sprintf(M,"Switching leds %s on!\n",&Ml[i*CLEN]);
//		SendStringBlock(GENERIC_UART_BASE_ADDR,M);
		WaitMs(20);
		*addr |= (1 << i);
	}

//	printf("Reporting key changes!\n");
/*	while(1) {
		addr = (int *)KEYADDR0;
		value = *addr;
		TestKeys(uart, value, c, (char*)Mk, sizeof(Mk)/CLEN);
		c = c ^ value;
		addr = (int *)KEYADDR1;
		value = *addr;
		TestKeys(uart, value, c, (char*)Mk1, sizeof(Mk1)/CLEN);
		c1 = c1 ^ value;
		
	}*/
}	

void TestKeys(uart_regs * uart, int value, int change, char ** M, int size) {
	int i = 0;
//	char Um[255];
	for (i = 0; i < size; ++i){
		if ((change & (1 << i)) != 0) {
			if ((value & (1 << i)) != 0){
//				sprintf(Um,"Key %s is on!\n",M[i]);
				printf("Key %d is on!\n", i);
//				SendStringBlock(GENERIC_UART_BASE_ADDR,"Key is on!\n");
			} else {
//				sprintf(Um,"Key %s is off!\n",M[i]);
				printf("Key %d is off!\n", i);
//				SendStringBlock(GENERIC_UART_BASE_ADDR, "Key is off!\n");
			}
		}
	}
}
