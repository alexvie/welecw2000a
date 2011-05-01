/*****************************************************************************
 * File           : DSO_Signal.c
 * Author         : Alexander Lindert <alexander_lindert at gmx.at>
 * Date           : 04.09.2010
 *****************************************************************************
 * Description	 :
 *****************************************************************************

 *  Copyright (c) 2010, Alexander Lindert

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

#include "DSO_Main.h"
#include "DSO_Misc.h"
#include "DSO_Signal.h"
#include "Filter_I8.h"
#include "DSO_SignalCapture.h"

#ifdef LEON3
#include "rprintf.h"
#include "GUI.h"

#define SIGNAL_HSTART 20
#define SIGNAL_HSTOP  HLEN-20
#define BG_COLOR COLOR_R3G3B3(0,0,0)
#define PREFETCH_OFFSET 32

#ifdef BOARD_COMPILATION
void DrawSignal(
		uint32_t Voffset,
		uSample * PrevData,
		uSample * CurrData,
		uint16_t PrevColor,
		uint16_t CurrColor)
{

	register uint32_t i = SIGNAL_HSTART+1;
	register SampleRet Prev;
	register SampleRet Curr;

	Prev.C = CurrData[SIGNAL_HSTART].i + Voffset;

	if (Prev.C <= GRID_RECT_START_Y) Prev.C = GRID_RECT_START_Y+1;
	if (Prev.C >= GRID_RECT_END_Y) Prev.C = GRID_RECT_END_Y-1;

	Prev.P = PrevData[SIGNAL_HSTART].i + Voffset;

	if (Prev.P <= GRID_RECT_START_Y) Prev.P = GRID_RECT_START_Y+1;
	if (Prev.P >= GRID_RECT_END_Y) Prev.P = GRID_RECT_END_Y-1;

	for (; i < SIGNAL_HSTOP; ++i)
	{
		/*		Prev = PrevData[i].i + Voffset;
		 lastPrev = DrawSample(PrevColor,i,Prev,lastPrev);
		 Curr = CurrData[i].i + Voffset;
		 lastCurr = DrawSample(CurrColor,i,Curr,lastCurr);*/
		Curr.P = PrevData[i].i + Voffset;
		Curr.C = CurrData[i].i + Voffset;
		/* avoid drawing out of grid only once per sample (return value)*/
		if (Curr.P <= GRID_RECT_START_Y) Curr.P = GRID_RECT_START_Y+1;
		if (Curr.P >= GRID_RECT_END_Y) Curr.P = GRID_RECT_END_Y-1;

		if (Curr.C <= GRID_RECT_START_Y) Curr.C = GRID_RECT_START_Y+1;
		if (Curr.C >= GRID_RECT_END_Y) Curr.C = GRID_RECT_END_Y-1;

		DrawSample(PrevColor, CurrColor, i, Prev, Curr);
		Prev = Curr;

	}

}

/* drawing uninterrupted lines in a race condition framebuffer */
void DrawSample(uint16_t ColorBack, uint16_t ColorSignal, uint32_t v, SampleRet hp, SampleRet hc)
{
	register uint32_t pl = 0;
	register uint32_t ph = 0;
	register uint32_t cl = 0;
	register uint32_t ch = 0;

	if (hp.P < hc.P)
	{
		pl = hp.P;
		ph = hc.P;
	}
	else
	{
		pl = hc.P;
		ph = hp.P;
	}

	if (hp.C < hc.C)
	{
		cl = hp.C;
		ch = hc.C;
	}
	else
	{
		cl = hc.C;
		ch = hp.C;
	}

	ClearVLineClipped(ColorBack,v,pl,ph);
	DrawVLineClipped(ColorSignal,v,cl,ch);
}
#endif
#endif

int32_t Sum(
	int32_t * src,
	uint32_t size) {
	uint32_t i = 0;
	uint32_t ret = 0;
	for(;i<size;++i){
		ret = ret + src[i];
	}
	return ret;
}

int32_t GetMin(
	int32_t * src,
	uint32_t size) {
	uint32_t i = 1;
	int32_t ret = 0;
	if (size < 1) return 0x7fffffff;
	ret = src[0];
	for(;i<size;++i){
		if (ret > src[i]){
			ret = src[i];
		}	
	}
	return ret;
}

int32_t GetMax(
	int32_t * src,
	uint32_t size) {
	uint32_t i = 1;
	int32_t ret = 0;
	if (size < 1) return 0x7fffffff;
	ret = src[0];
	for(;i<size;++i){
		if (ret < src[i]){
			ret = src[i];
		}	
	}
	return ret;
}


#ifdef LEON3
void ConvSample (
		int32_t * dst,
		int32_t * src,
		int32_t const * const fir)
{

	register int fir_idx = 0;
	register int32_t result = 0;

	for(fir_idx = 0; fir_idx < POLYPHASE_COEFFS; fir_idx+= 1)
	{
		result += src[fir_idx] * fir[POLYPHASE_COEFFS-1-fir_idx];
	}
	*dst = result/(32768);
}

void Interpolate (
		uint32_t dstSamples,
		uSample *Dst,
		uSample *Src,
		uint32_t type)
{

	register uint32_t i = 0;
	register uint32_t j = 0;
	register uint32_t dst_idx = 0;
	register int32_t * fir;

	register uint32_t srcSamples = dstSamples/POLYPHASES;

	for (i = 0; i < srcSamples; ++i)
	{
		for (j = 0; j < POLYPHASES; ++j)
		{
			fir = (int32_t*)&Filter_I8[j][0];
			ConvSample(&Dst[dst_idx].i,&Src[i].i,fir);
			/*	Dst[dst_idx] = Src[i];*/
			dst_idx++;
		}
	}
}
#endif

void GetCh(
		uint32_t ch,
		uint32_t size,
		uSample * dst,
		uSample * src,
		uint32_t srcSamples,
		sHWFilterGain AnalogGain,
		sHWFilterGain FilterGain)
{

	register uint32_t i = 0;
	register int32_t data = 0;
	sHWFilterGain Gain;
	Gain.num = -AnalogGain.num * FilterGain.num;
	Gain.den =  AnalogGain.den * FilterGain.den;
	switch (size)
	{
		case 8:
		for (; i < srcSamples; ++i)
		{
			data = (int32_t)src[i].c[ch];
			dst[i].i = (data*Gain.num)/Gain.den;
		}
		break;
		case 16:
		Gain.den *= 256;
		for (; i < srcSamples; ++i)
		{	                  
			data =  src[i].c[ch+2] & 0xff; // must be unsigned!!!
			data |= (int32_t)((src[i].c[ch] << 8));
			dst[i].i = (data*Gain.num)/Gain.den;
		}
		break;
		default:
		for (; i < srcSamples; ++i)
		{
			dst[i].i = src[i].i;
		}
		break;
	}
}


/* this Offset is the calibrated DCOffset and has nothing to do with the Offset of the rotary nob */
int32_t AnCalOffset[NO_CH][NO_ANALOGRANGES];
uint32_t myVperDiv[NO_CH];
#define DCOFFIDX_5V      0
#define DCOFFIDX_2V      1
#define DCOFFIDX_1V      2
#define DCOFFIDX_500mV   3
#define DCOFFIDX_200mV   4
#define DCOFFIDX_100mV   5
#define DCOFFIDX_50mV    6
#define DCOFFIDX_20mV    7
#define DCOFFIDX_10mV    8
#define DCOFFIDX_5mV     9
#define DCOFFIDX_2mV    10
#define DCOFFIDX_1mV    11
#define DCOFFIDX_500uV  12
#define DCOFFIDX_200uV  13
#define DCOFFIDX_100uV  14

void UpdateCalOffsetPointer(
		uint32_t ch,  
		uint32_t myVperDivCurr) {
	switch(myVperDivCurr) {
		case 5000000: myVperDiv[ch] = DCOFFIDX_5V;
		case 2000000: myVperDiv[ch] = DCOFFIDX_2V;
		case 1000000: myVperDiv[ch] = DCOFFIDX_1V;
		case  500000: myVperDiv[ch] = DCOFFIDX_500mV;
		case  200000: myVperDiv[ch] = DCOFFIDX_200mV;
		case  100000: myVperDiv[ch] = DCOFFIDX_100mV;
		case   50000: myVperDiv[ch] = DCOFFIDX_50mV;
		case   20000: myVperDiv[ch] = DCOFFIDX_20mV;
	}
	myVperDiv[ch] = DCOFFIDX_10mV;
}

void InitCalOffset() {
	uint32_t i = 0;
	uint32_t j = 0;
	for (;i < NO_CH; ++i){
		for (;j < NO_ANALOGRANGES; ++j){
			AnCalOffset[i][j] = -7250;
		}
		myVperDiv[i] = 0; 
		GUI_DACOffset(i, 0);

	}
}

/* 12 bit DAC compability with the 16 bit DACs of this family */
#define MIN_DAC_COUNT 4
#define CALBUFFERSIZE 16

#ifdef LEON3
extern uSample Data[CAPTURESIZE];
#else
uSample Data[CAPTURESIZE];
#endif

void CalAnalogOffset(
		uint32_t ch, 
		uint32_t myVperDivCurr){
	int32_t mean = 0;
	int32_t lastmean = 0;
	int32_t step = 4096;
	uint32_t read = 0;
	SetAnalog Analog = {myVperDivCurr, TRUE, 0, 0, FALSE, normal};
	uSample Buffer[CALBUFFERSIZE*4];
	sHWFilterGain Gain = {1,1};
	/* Following settings must be independend from the GUI settings!
         * Take care to set these 3 calls after the calibration was done back to the gui settings */
	SetAnalogInputRange(ch, &Analog);
	SetTriggerInput(ch,8,FS_MAX,FIXED_CPU_FREQUENCY,0,0,0,1,2,3);
	SetTrigger(EXTTRIGGER_LH,FORCETOGGE,0,64,0,0,0,0);
	myVperDiv[ch] = myVperDivCurr;

	while(step != 0) {
		read = 0;
//		read = CaptureData(1000,TRUE,TRUE,32786, (uint32_t*)Data);

		while (read < CALBUFFERSIZE) {
			read = CaptureData(10000,TRUE,TRUE,CALBUFFERSIZE+10, (uint32_t*)Data);
			
			if (read == 0) {
			}
	
		}

		lastmean = mean;
		GetCh(ch,8, &Buffer[0], &Data[0], CALBUFFERSIZE, Gain,Gain);
		mean = Sum((int32_t*)&Buffer[0],CALBUFFERSIZE);
		lastmean = myVperDivCurr;
 		AnCalOffset[ch][myVperDivCurr] = AnCalOffset[ch][myVperDivCurr] - step;
		GUI_DACOffset(ch,0 /* gui offset! */); 
		if (mean == 0) {
			return;
		}
		if (step > 0) {
			if (mean > 0){	
				step = -(step/2);
			}
		} else {
			if (mean < 0){
				step = -(step/2);
			}
		}
	}
}

uint32_t CalibrateDAC()
{
	/* set the Trigger tempoarly to force triggering 
	 * set the analog ch tempoarly to AC 
	 * capture data 
	 * sum of data / data samples
	 * set the DAC
	 * goto capture data until sum of data is exeptable low */
/*	uint32_t myVperDiv[] = {
		5000000, 2000000, 1000000,
		500000,  200000,  100000,
		50000,   20000,   10000};
	uint32_t i = 0;
	uint32_t j = 0;*/
	InitCalOffset();
/*
As long the DC Calibration does not work it is not used
	for (i = 0; i < NoCh; i++){
		for (j = 0; i < 9; j++){
			CalAnalogOffset(i, myVperDiv[j]);		
		}
	}
*/
	return TRUE;
}

void GUI_DACOffset(
		uint32_t ch, 
		int32_t Offset)
{
	SetDACOffset(ch, (Offset * MIN_DAC_COUNT) + AnCalOffset[ch][myVperDiv[ch]] - GUI_DAC_MIN);	
}

