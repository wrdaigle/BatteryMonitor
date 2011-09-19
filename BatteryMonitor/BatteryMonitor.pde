
//Data visulize ver1.7 jerry Aug2011 
//New window management

#define cs 10   // for MEGAs you probably want this to be pin 53
#define dc 9
#define rst 8  // you can also connect this to the Arduino reset

// Color definitions
#define	BLACK           0x0000
#define	BLUE            0x001F
#define	RED             0xF800
#define	GREEN           0x07E0
#define CYAN            0x07FF
#define MAGENTA         0xF81F
#define YELLOW          0xFFE0  
#define WHITE           0xFFFF
#include <Wire.h>
#include <RTClib.h>
#include <ST7735.h>
#include <SPI.h>
RTC_DS1307 RTC;
ST7735 tft = ST7735(cs, dc, rst);   
// variables for A
long lastMilli;
const byte sampleSize = 128;
const long bSize = 34128000; //Battery Size in watt-seconds=9.48 kwHrs
int ampsInPin = 0;
int voltsInPin = 1;
int volts, amps;
long power, powerSum;
float bCharge;
char StrVA[ ] = "Bat 2V.V v sAA amps";
//inputs for windowA
int traceA[sampleSize];  //size of array that hold traceA data
int sampleTimeA = 1000;  //time in ms to samlple A/D inputs for new data
int sampleAidx = 0;  //index to keep track of array time order
int wAx=12;  //x valule for window corner
int wAy=9;  //y value for window corner
int wAw=128-wAx;  //width of window
int wAh=60;  //height of window
int fillA=BLACK;
int borderA=MAGENTA;
int zeroLoc=128;   //0-255  128 is middle of window
int zeroAcolor=YELLOW;
//inputs for windowB
int traceB[sampleSize];  //size of array that hold traceB data
int sampleBnum=20;  //Number of A samples for each B value intergrate
int sampleBidx=0;  //B array index
int sampleBsum=0;  //temp sum for intergrator
int sampleBctr=0;  //counter of number of B samples collected
int wBx=12;
int wBy=wAy + wAh;
int wBw=128-wBx;
int wBh=50;
int fillB=BLACK;
int borderB=MAGENTA;
int zeroBcolor=YELLOW;
//inputs for window C
int traceC[sampleSize];  //size of array that hold traceA data
int sampleTimeC = 1000;  //time in ms to samlple A/D inputs for new data
int sampleCidx = 0;  //index to keep track of array time order
int wCx=128-100;  //x valule for window corner
int wCy=160-30;  //y value for window corner
int wCw=100;  //width of window
int wCh=30;  //height of window
int fillC=BLACK;
int borderC=BLUE;
int sampleCnum=0;  //nunber of C samples to count before update
int sampleCctr=0;  //counter of number of C samples 

void setup(void) {
  Serial.begin(9600);
  Wire.begin();
  RTC.begin();
  Serial.print("hello!");
  tft.initR();               // initialize a ST7735R chip
  Serial.println("init");
  tft.writecommand(ST7735_DISPON);
  Serial.println("done");
  // initalize data arrays with some values
  for(int i=0; i<sampleSize; i++){
    traceA[i]=128;
    traceB[i]=128;
    traceC[i]=75;
  }
  //display version number
  tft.fillScreen(WHITE);
  tft.drawString(0, 0,"tft_Osc Ver1.9", BLACK);
  tft.drawString(0, 10,"Jerry Jeffress", BLACK);
  tft.drawString(0, 20,"Sept 2011", BLACK);
  delay(1000);
  tft.fillScreen(BLACK);
  power = 0;
  powerSum = 0;
  sampleCnum=20;
  bCharge = 33000000;  //about (9 kwHr in watt-seconds
  drawWindow(wAx, wAy, wAw, wAh, fillA, borderA);
  gridA();
  drawWindow(wBx, wBy, wBw, wBh, fillB, borderB);
  gridB();
  traceBupdate();
  drawWindow(wCx, wCy, wCw, wCh, fillC, borderC);
  barGraph(0);
  // batVA(46, 0, GREEN);
}

void loop() {
  if(millis()>lastMilli + sampleTimeA){

    updateTrace(sampleAidx, 0, traceA, wAx, wAy, wAh); //erase last traceA
    gridA();
    sampleAidx = sampleAidx+1;
    if(sampleAidx>sampleSize-1)
      sampleAidx=0;
    amps = analogRead(ampsInPin);
    traceA[sampleAidx] = amps/4;
    volts = analogRead(voltsInPin);

    updateTrace(sampleAidx, 1, traceA, wAx, wAy, wAh);  //newtraceA bicolor
    sampleBsum = sampleBsum + traceA[sampleAidx];
    if(sampleBctr>sampleBnum-1)
      traceBupdate();
    sampleBctr = sampleBctr + 1;

    batVA(GREEN);
    calcVA();
    sampleCctr = sampleCctr + 1;
    if (sampleCctr>sampleCnum){
      sampleCidx = sampleCidx+1;
      if(sampleCidx>sampleSize-1)
        sampleCidx=0;
      traceC[sampleCidx]= int(100*bCharge/bSize);
      drawWindow(wCx, wCy, wCw, wCh, fillC, borderC);
      barGraph(sampleCidx);
      sampleCctr = 0;
      Serial.print("inside C loop  c= ");
      Serial.println(traceC[sampleCidx]);
    }
    lastMilli = millis();
  }
  //Outside the timer loop, this loops fast!
  //Later this is where to sample A/D, as many times as you can with
  //about a 2ms delay for each sample. Sum them;  when the above update 
  //occurs, average the sum and pass the AVERAGE value to the trace array.
  //No way to tell how many samples this is;  so count them!!
  // This to reduce noise at the iputs as much as possible.
  /* sort of like this
   ampSum = ampSum + analogRead(ampsInPin);
   delay(2);
   voltSum = voltSum + analogRead(voltsInPin);
   delay(2);
   sampleCtr += 1;
   When you average this ampSum, divide by sampleCtr, then set it to 0
   sampleCtr will NOT be the same for each loop!
   */
}







