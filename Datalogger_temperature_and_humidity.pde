/***
*	This program can be used to query a temperature and humidity sensor and store those values onto a SD card
*	wingston.sharon@gmail.com
*
***/


#include <string.h>
#include <ctype.h>
#include <Sensirion.h>
#include <SD.h>

 int ledPin = 13;                  // LED test pin
 int rxPin = 19;                    // RX PIN 
 int txPin = 18;                    // TX TX
 int byteGPS=-1;
 char linea[300] = "";
 char comandoGPR[7] = "$GPRMC";
 int cont=0;
 int bien=0;
 int conta=0;
 int indices[13];

const byte dataPin =  10;                 // SHTxx serial data
const byte sclkPin =  11;                 // SHTxx serial clock

const unsigned long TRHSTEP   = 300UL;  // Sensor query period
const unsigned long BLINKSTEP =  250UL;  // LED blink period

Sensirion sht = Sensirion(dataPin, sclkPin);

unsigned int rawData;
float temperature;
float humidity;
float dewpoint;

byte ledState = 0;
byte measActive = false;
byte measType = TEMP;

unsigned long trhMillis = 0;             // Time interval tracking
unsigned long blinkMillis = 0;
File dataFile;
const int chipSelect = 8;

 void setup() {
   pinMode(ledPin, OUTPUT);       // Initialize LED pin
   pinMode(rxPin, INPUT);
   pinMode(txPin, OUTPUT);
   Serial.begin(9600);
   Serial1.begin(9600);
   for (int i=0;i<300;i++){       // Initialize a buffer for received data
     linea[i]=' ';
   }   
   
   
   byte stat;
  byte error = 0;
  Serial.begin(9600);
  pinMode(ledPin, OUTPUT);
  pinMode(53, OUTPUT);
  delay(15);                             // Wait >= 11 ms before first cmd
// Demonstrate status register read/write
  sht.readSR(&stat);                     // Read sensor status register
  Serial.print("Status reg = 0x");
  Serial.println(stat, HEX);
  sht.writeSR(LOW_RES);                  // Set sensor to low resolution
  sht.readSR(&stat);                     // Read sensor status register again
  Serial.print("Status reg = 0x");
  Serial.println(stat, HEX);
  
  while(!SD.begin(chipSelect)) {
    Serial.println("Card failed, or not present");
    // don't do anything more:
  }
  Serial.println("card present and OK! :)");
  dataFile = SD.open("datalog.txt", FILE_WRITE);
  
 }
void dotemp() {
  unsigned long curMillis = millis();          // Get current time

  // Rapidly blink LED.  Blocking calls take too long to allow this.
  if (curMillis - blinkMillis >= BLINKSTEP) {  // Time to toggle the LED state?
    ledState ^= 1;
    digitalWrite(ledPin, ledState);
    blinkMillis = curMillis;
  }

  // Demonstrate non-blocking calls
  if (curMillis - trhMillis >= TRHSTEP) {      // Time for new measurements?
    measActive = true;
    measType = TEMP;
    sht.meas(TEMP, &rawData, NONBLOCK);        // Start temp measurement
    trhMillis = curMillis;
  }
  if (measActive && sht.measRdy()) {           // Check measurement status
    if (measType == TEMP) {                    // Process temp or humi?
      measType = HUMI;
      temperature = sht.calcTemp(rawData);     // Convert raw sensor data
      sht.meas(HUMI, &rawData, NONBLOCK);      // Start humi measurement
    } else {
      measActive = false;
      humidity = sht.calcHumi(rawData, temperature); // Convert raw sensor data
      dewpoint = sht.calcDewpoint(humidity, temperature);
      logData();
    }
  }
}

void gps()
{
digitalWrite(ledPin, HIGH);
   byteGPS=Serial1.read();         // Read a byte of the serial port
    if (!dataFile) Serial.println("ERRRRROR!");
   if (byteGPS == -1) {           // See if the port is empty yet
     delay(100); 
   } else {
     linea[conta]=byteGPS;        // If there is serial port data, it is put in the buffer
     conta++;                      
    // Serial.print(byteGPS, BYTE); 
     if (byteGPS==13){            // If the received byte is = to 13, end of transmission
       digitalWrite(ledPin, LOW); 
       cont=0;
       bien=0;
       for (int i=1;i<7;i++){     // Verifies if the received command starts with $GPR
         if (linea[i]==comandoGPR[i-1]){
           bien++;
         }
       }
       if(bien==6){               // If yes, continue and process the data
         for (int i=0;i<300;i++){
           if (linea[i]==','){    // check for the position of the  "," separator
             indices[cont]=i;
             cont++;
           }
           if (linea[i]=='*'){    // ... and the "*"
             indices[12]=i;
             cont++;
           }
         }
     // ... and write to the serial port
      //  Serial.print("***");
        dataFile.print("***");
         //Serial.println("---------------");
         for (int i=0;i<12;i++){
           
           for (int j=indices[i];j<(indices[i+1]-1);j++){
             //Serial.print(linea[j+1]); 
            // Serial.print(",");
             
            dataFile.print(linea[j+1]); 
             dataFile.print(" ");
           }
           
         }
        // Serial.println("\n---------------");
        //Serial.println(" OK");
        dataFile.println("OK");
         Serial.println("GPS-OK");
       }
       conta=0;                    // Reset the buffer
       for (int i=0;i<300;i++){    //  
         linea[i]=' ';             
       }                 
     }
   }
   
}

void logData() {
  Serial.print("###");   Serial.print(temperature);
  Serial.print(",");  Serial.print(humidity);
  Serial.print(",");  Serial.print(dewpoint);
   Serial.print(",");  Serial.print(millis()/1000);
 Serial.println(" OK");
  
  dataFile.print("###");   dataFile.print(temperature);
  dataFile.print(",");  dataFile.print(humidity);
  dataFile.print(","); dataFile.print(dewpoint);
  dataFile.print(","); dataFile.print(millis()/1000);
 dataFile.println(" OK");
 Serial.println("Temp-OK");
}

 void loop() {
   //gps();
   dotemp();
 }

