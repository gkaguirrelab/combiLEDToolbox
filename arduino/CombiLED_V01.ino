#include  <Wire.h>
#define Wavelength 57600.0  // temporal wavelength in [micro-sec]  (Freq = 1000000/Wavelength =~ 69 Hz)
#define offsetLED 100       // minimal DAC 0-4095 normally shall be lower than maxPower for each one of LEDs
int maxPower[8]={4095,4095,4095,4095,4095,4095,4095,4095};  //maximum DAC for each LED (0-4095) 
#define numLEDs  8         // number of LED in work {1-8}

//------------------------------------------------- 
#define  TimeBetween (numLEDs*360)
#define  nmLoops (int)(Wavelength/TimeBetween)
int OneTimeD[8];
int OneTime,CurLoop; 
double Last=0; 
bool isStarted = false;

//For wave profile 2D Array to store LED levels
//Row is for the LED, Column is the 12- bit DAC levels, the size of column depends on the wavelength
int wave[8][nmLoops] = {{0,100,391,844,1414,2047,2680,3250,3703,3994,4095,3994,3703,3250,2680,2047,1414,844,391,100},               //LED1
                        {2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047},      //LED2
                        {2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2367,2680,2977,3250,3495,3703,3871,3994,4069,4095},      //LED3
                        {2047,2680,3250,3703,3994,4095,3994,3703,3250,2680,2047,1414,844,391,100,0,100,391,844,1414},               //LED4
                        {2047,2363,2649,2875,3021,3071,3021,2875,2649,2363,2047,1731,1445,1219,1073,1023,1073,1219,1445,1731},      //LED5
                        {2047,3250,3994,3994,3250,2047,844,100,100,844,2047,3250,3994,3994,3250,2047,844,100,100,844},              //LED6
                        {2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047,2047},      //LED7
                        {0,25,100,223,391,599,844,1117,1414,1727,2047,2367,2680,2977,3250,3495,3703,3871,3994,4069}};               //LED8

//For Serial Communication
String inputString = "";         // a String to hold incoming data
bool stringComplete = false;  // whether the string is complete

void setup()
{
    OneTime= Wavelength/nmLoops;
    CurLoop=0;
    Serial.begin(57600);
    for(int i=0;i< 8;i++)maxPower[i]=maxPower[i]-offsetLED;
    //Serial.println(nmLoops);
    for(int i=0;i< 8;i++)
    {
      OneTimeD[i]=maxPower[i]/nmLoops;
    }  
    Wire.begin();
    Wire.setClock(400000);
    CloseAllLeds();
}

void loop() {
    //Check Any serial command received
    if (stringComplete) {
        //Serial.println(inputString);
        if(inputString.indexOf("start") >= 0) {
            Serial.println("starting");
            isStarted = true;
        }
        else if(inputString.indexOf("stop") >= 0) {
            isStarted = false;
            CloseAllLeds();
        }
        // clear the string:
        inputString = "";
        stringComplete = false;
    }


    if(isStarted) {
        double currentMicro = micros ();      
        if(currentMicro-Last <= TimeBetween) return;
        Last=currentMicro;
        sinWave(CurLoop);
        // sawTooth();
        CurLoop++;
        if(CurLoop>= nmLoops) CurLoop=0; 
    }
}

void sawTooth(int CurLoop){
    for( int i=0;i<numLEDs;i++)
    {                               
        WriteToLED(OneTimeD[i]*CurLoop+offsetLED,i);
    }
}

void sinWave(int CurLoop) { 
    for( int i=0;i<numLEDs;i++)
    {                               
        WriteToLED(wave[i][CurLoop],i);
    }
    //debug use
    //printLine(Last, "; ", wave[CurLoop]);
}

void CloseAllLeds()
{
  for( int i=0;i<8;i++)

         {
            WriteToLED(0,i);
         }
}

void WriteToLED(int level,int numberLED)
{
      Wire.beginTransmission(0x70);
      Wire.write(1<<numberLED);
      Wire.endTransmission(); 
      Wire.beginTransmission(0x61);        
      Wire.write(0b01011000);   
      Wire.write((uint8_t) (highByte(level<<4)));
      Wire.write((uint8_t) (lowByte(level<<4)));
      Wire.endTransmission(1);
}

//For Serial Function
/*
  SerialEvent occurs whenever a new data comes in the hardware serial RX. This
  routine is run between each time loop() runs, so using delay inside loop can
  delay response. Multiple bytes of data may be available.
*/
void serialEvent() {
  while (Serial.available()) {
    // get the new byte:
    char inChar = (char)Serial.read();
    // add it to the inputString:
    inputString += inChar;
    // if the incoming character is a newline, set a flag so the main loop can
    // do something about it:
    if (inChar == '\n') {
      stringComplete = true;
    }
  }
}

//For printLine
void printLine() {
    Serial.println();
}

template <typename T, typename... Types>
void printLine(T first, Types... other) {
    Serial.print(first);
    printLine(other...) ;
}
