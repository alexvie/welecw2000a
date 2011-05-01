/****************************************************************************
* Project        : Welec W2000A
*****************************************************************************
* File           : Request.cpp
* Author         : Alexander Lindert <alexander_lindert at gmx.at>
* Date           : 28.06.2009
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
#include "Request.h"
#include "DSO_Remote.h"
#include "ImageTypes.h"

Request::Request(CPUComm * Comm) : mComm(Comm){}
Request::~Request(){
	delete mComm;
}

uint32_t Request::InitComm(
		char * Device, 
		const uint32_t TimeoutMS, 
		const uint32_t Baudrate,
		char * IPAddr)  
{
	return mComm->Init(Device,TimeoutMS,Baudrate,IPAddr);
}

uint32_t Request::SendTriggerInput (
			const uint32_t noChannels, 
			const uint32_t SampleSize, 
			const uint32_t SamplingFrequency,
			const uint32_t AACFilterStart,
			const uint32_t AACFilterStop,
			const uint32_t Ch0, 
			const uint32_t Ch1, 
			const uint32_t Ch2, 
			const uint32_t Ch3){
	uint32_t data[] = {		
		SET_TRIGGER_INPUT, noChannels, SampleSize, SamplingFrequency, 
		AACFilterStart,AACFilterStop, Ch0, Ch1, Ch2, Ch3};
	mComm->Send(data,sizeof(data)/sizeof(uint32_t));
	return mComm->GetACK();
}

uint32_t Request::SendTrigger(
		const uint32_t Trigger, 
		const uint32_t ExtTrigger,
		const uint32_t TriggerChannel,
		const uint32_t TriggerPrefetchSamples,
		const int  LowReference,
		const uint32_t  LowReferenceTime,
		const int HighReference,
		const uint32_t HighReferenceTime){
	uint32_t data[] = {
		SET_TRIGGER, Trigger, ExtTrigger, TriggerChannel, TriggerPrefetchSamples,
		LowReference, LowReferenceTime, HighReference, HighReferenceTime};
	mComm->Send(data,sizeof(data)/sizeof(uint32_t));
	return mComm->GetACK(); 
}


typedef struct {
	uint32_t cmd;
	uint32_t NoCh;
	SetAnalog data[4];
} xAnalog;

uint32_t Request::SendAnalogInput(
			const uint32_t NoCh, 
			const SetAnalog * Settings){
	uint32_t i = 0;
	xAnalog crcA;
	for(i = 0; i < NoCh; ++i){
		crcA.data[i] = Settings[i];
	}
	crcA.cmd = SET_ANALOG_INPUT;
	crcA.NoCh = NoCh;
	mComm->Send((uint32_t*)&crcA, 2+(NoCh*sizeof(SetAnalog)/sizeof(uint32_t)));
	return mComm->GetACK();
}

uint32_t Request::ReceiveSamples(
			const uint32_t WaitTime, /* just a integer */
			const uint32_t Start,
			uint32_t CaptureSize,    /* size in DWORDs*/
			uint32_t * FastMode,
			uint32_t * RawData){
	uint32_t data[] ={CAPTURE_DATA, WaitTime, Start, *FastMode, CaptureSize};
	PrintSFR();
	if (mComm->Send(data,sizeof(data)/sizeof(uint32_t))){
		uint32_t * SendData = new uint32_t[CaptureSize+2];
		
		uint32_t Length = mComm->Receive(SendData,CaptureSize+2);
		if (Length < 2){
			return 0;
		}
		memcpy(RawData,&SendData[2],Length-2);
		uint32_t Ret = SendData[1];
		*FastMode = SendData[0];
		delete SendData;
		return Ret;
	} else {
		return 0;
	}

}

void Request::PrintSFR(){
/*	uint32_t data[DSO_REG_SIZE/sizeof(uint32_t)+2] = 
		{LOAD_DWORDS, DSO_SFR_BASE_ADDR, DSO_REG_SIZE/sizeof(uint32_t)};
	uint32_t Length = 3;
	uint32_t Dummy = 0;
	mComm->Send(data,Length);
	
	data[0] = DSO_REG_SIZE/sizeof(uint32_t)+1;//length
	Length = mComm->Receive(data,data[0]);
	if (Length > 1){
		PrintDesc(&data[1], data[0]);
	}*/
}

uint32_t Request::Receive(
		uint32_t addr,
		uint32_t size){
	return FALSE;
}


void Request::PrintDesc(uint32_t *Data, uint32_t Length){
	
}

uint32_t Request::LoadProgram( 
		const char * FileName, 
		uint32_t StartAddr,
		uint32_t StackAddr){
	return FALSE;
}

uint32_t Request::Debug(){
	return FALSE;
}


uint32_t Request::SendRAWFile(
		uint32_t StartAddr,
		const char * FileName){
	return FALSE;
}


uint32_t Request::Send(
		uint32_t Addr, 
		uint32_t *Data, 
		uint32_t & Length){
	return FALSE;
}


uint32_t Request::Receive(
		uint32_t Addr, 
		uint32_t *Data, 
		uint32_t & Length){
	return FALSE;
}

#include <iostream>
#include <fstream>
using namespace std;

void Request::make_bmp(const char *filename)
{
	uint16_t c=0;
	uint16_t incount=0, i;			//Anzahl verarbeiteter Zeichen
	uint16_t llength=0;				//Lauflänge
	uint8_t red,green,blue;	//Farbkomponenten
		
	sBMP_file_header fileheader; 
	sBMP_info_header infoheader;

	fileheader.bfType = 0x4D42;
//	fileheader.bfSize = sizeof(fileheader); does only work under windows
	fileheader.bfSize = 921654; // TODO: does only work for this colored 640x480 size 
	fileheader.bfReserved1 = 0;
	fileheader.bfReserved2 = 0;
	fileheader.bfOffBits =  sizeof(fileheader)+sizeof(infoheader);

	infoheader.biSize =  sizeof(infoheader);
	infoheader.biWidth = 640;
	infoheader.biHeight = -480;
	infoheader.biPlanes = 1;
	infoheader.biBitCount = 24;  
	infoheader.biCompression = 0;
	infoheader.biSizeImage = 0;
	infoheader.biXPelsPerMeter = 0;
	infoheader.biYPelsPerMeter = 0;
	infoheader.biClrUsed = 0;
	infoheader.biClrImportant = 0;
		
	ofstream fScreenshot;
	string f_name(filename);
	f_name += ".bmp";
	fScreenshot.open(f_name.c_str(),ios::out | ios::binary);  
		
	//Write BMP Header
	fScreenshot.write ((char*) &fileheader,sizeof(fileheader)); 
	fScreenshot.write ((char*) &infoheader,sizeof(infoheader));

	while (1)
	{
		c = mComm->ReceiveByte() << 8;	//Farbwert des Pixels zusammensetzen
		c |= mComm->ReceiveByte();

		if(c==0x73aa) break;				//Abbrechen wenn Stoppmarker erkannt wurde

		llength = mComm->ReceiveByte();
		
		//Farben decodieren
		blue = (uint8_t) (c & 0x7F)<<3;
		green = (uint8_t) ((c & 0x7C0) >> 6)<<3;
		red = (uint8_t) ((c & 0xF800) >> 11)<<3;
		if(blue & 0x20)
		{
			blue |= 0x1C;
		}
		if(green & 0x20)
		{
			green |= 0x1C;
		}
		if(red & 0x20)
		{
			red |= 0x1C;
		}
		
		for(i=0;i<llength;i++)			//Pixel schreiben x-mal schreiben
		{
			fScreenshot << blue;
			fScreenshot << green;
			fScreenshot << red;
		}
	}
		
	fScreenshot.close();
}

void Request::make_ppm(const char *filename)
{
	printf("PPM not yet supported yet\n");
}

void Request::make_bw_bmp(const char *filename)
{
	printf("BW BMP not yet supported yet\n");
}

void Request::make_pbm(const char *filename)
{
	printf("PBM not yet supported yet\n");
}



uint32_t Request::Screenshot(const char *filename)
{
	uint8_t  c = 0, type;
	uint8_t l = 0;
	
	printf("Screenshot from Leon\n");

	while (1)	//wait for data header
	{
		c = mComm->ReceiveByte();
		if (c == 255 && l == 'S') break;
		l = c;	
	}
	
	type = mComm->ReceiveByte();
	printf("Receiving image Type %d\n", type);

	switch (type)
	{
		case 0:
			make_ppm(filename);	//colour screenshot
		break;

		case 1:	
			make_bmp(filename);	//color screenshot
		break;

		case 2:
			make_bw_bmp(filename); //S/W screenshot
		break;

		case 3:
			make_pbm(filename); //S/W screenshot
		break;
	}
	return 1;
}
	



