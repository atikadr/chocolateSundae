/*
* connections:
* shield->araduino mega
* pin11->pin51
* pin12->pin50
* pin13->pin52
*/ 

#include <SoftwareSerial.h>
#include <SD.h>
#include "WiFly.h"
#include "Credentials.h"
#include "Timer.h"

#define PERIOD_READ_PH 2000 // 5 mins
#define RECEIVE_MOTOR_PERIOD 1000 //check user interface every 1 seconds
#define RECEIVE_CAMERA_PERIOD 5000 //check camera data every 1 min
#define MOTOR_PERIOD 1000 //turn on/off motor every second
#define MOTOR_OFF_PERIOD 15 //in seconds, only for testing
#define MOTOR_ROTATING_DURATION 3000 //duration in which motor is turned on
#define MOTOR_SPEED 255 // 0 is completely off, 255 is maximum speed


//hard code this before everyupload
#define MONTH 10
#define DAY 24
#define HOUR 14 //out of 24
#define MINUTE 33

#define LowerPhLimit 6.0
#define UpperPhLimit 8.0
#define Zero 0.00000001

#define Endpoint "/~Ben/chocolateSundae/"
byte localhost[] = {192,168,43,60};
Client client(localhost, 80);
char c;

Timer t;

char name[] = "Test.txt";     //Create an array that contains the name of our file.
char contents[256];           //This will be a data buffer for writing contents to the file.
char in_char=0;
int index=0;  

// Chip Select pin is tied to pin 8 on the SparkFun SD Card Shield
const int chipSelect = 8;  

//for calibration prompts:
char x = '0';
char y = '0';

#define MOTOR_PIN 12
String motorResponse; //1 indicates motor is on manual ON mode, 0 indicates motor is AUTO mode
String cameraResponse;
enum motorState {ON, OFF, AUTO};
motorState MOTOR_STATE = AUTO;
int motorSecond = 0; //indicates how many seconds have passed since motor was turned on
boolean motorOn; //indicates whether camera says motor should be turned on or not



void setup(){
  Serial.begin(9600);
  Serial1.begin(38400);

  //start continuous pH reading
  Serial1.print("C\r");
  Serial.print("in continuous\n");
  while(true){
    delay(300);
    printSerial1Reading();
  }
  initSD();
  
  analogWrite(MOTOR_PIN, 0); //turn off motor first
  motorSecond = 0;
  motorOn=false;
  
    WiFly.begin();
  if (!WiFly.join(ssid, passphrase)) {
    Serial.println("Association failed.");
    while (1) {
      // Hang on failure.
    }
  }  
  Serial.println(WiFly.ip()); 
  if (client.connect()) {
    Serial.println("connected");
  }
  else {
    Serial.println("connection failed");
  }
  
  delay(1000); //1 second delay for setup
  
  //t.every(RECEIVE_MOTOR_PERIOD, receiveMotor);
  //t.every(RECEIVE_CAMERA_PERIOD, receiveCamera);
  //t.every(MOTOR_PERIOD, motor);  
  t.every(500, runLogging);
}

/* send a read command, expect one single reading
*  from Serial1, cr terminated
*/
String readPh(){
  String phReading = "";
  char digit;
  Serial1.print("R\r");
  delay(5000);
  if(Serial1.available()>0){
    while(Serial1.available()){
      digit = Serial1.read();
      if(digit==13) break;
      phReading += digit;
    }
  }
  Serial.print("reading\n");
  Serial.print(phReading);
  Serial.println();
  return phReading;
}


void runLogging(){
  String pHValue = readPh();
  if(isOutOfRange(pHValue))
    sendAlert(pHValue); 
  logPh(pHValue);
}

bool isOutOfRange(String pH){
  char pHChar[pH.length()];
  pH.toCharArray(pHChar, pH.length());
  float pHFloat = atof(pHChar);
  if(pHFloat-LowerPhLimit<Zero || UpperPhLimit-pHFloat>Zero)
    return true;
  else return false;
}

void sendAlert(String ph){
  if (!client.connected()) {client.connect();}
  client.println("GET /~Ben/chocolateSundae/sendsms.php?ph="+ ph);
  client.println();
}

void initSD(){
  //init sd card:
  Serial.print("Initializing SD card...");
  // make sure that the default chip select pin is set to
  // output, even if you don't use it:
  pinMode(53, OUTPUT); 
  

  // see if the card is present and can be initialized:
  if (!SD.begin(chipSelect)) {
    Serial.println("Card failed, or not present");
    // don't do anything more:
    return;
  }
  Serial.println("card initialized.");
}


/* logs the value pHdata into the file datalog.txt
*/
void logPh(String pHdata){
   // this opens the file and appends to the end of file
  // if the file does not exist, this will create a new file.
  File dataFile = SD.open("datalog.txt", FILE_WRITE);

  // if the file is available, write to it:
  if (dataFile) 
  {  
    long timeStamp = getCurrentTime();
    dataFile.print(timeStamp);
    dataFile.print(", ");
    Serial.print(timeStamp);
    Serial.print(", ");

    // read three sensors and append to the String:
    dataFile.print(pHdata);
    Serial.print(pHdata);
    
    dataFile.println();
    dataFile.close();
    Serial.println();
    // print to the serial port too:
  }  
  // if the file isn't open, pop up an error:
  else
  {
    Serial.println("error opening datalog.txt");
  } 
}

long getCurrentTime(){
  long eMin = millis()/60000;
  long curMin = MINUTE + eMin;
 // Serial.println();
 // Serial.print(MINUTE);
 // Serial.println();
  long curHrs = HOUR + curMin/60;

  curMin %= 60;
  long curDay = DAY + curHrs/24;
  curHrs %= 24;
  curDay %= 31;

  long ans = curDay*10000 + curHrs*100 + curMin;
  return ans;
}
  
  
  

void turnPhLedOn(){
  while(true){
    x = Serial.read();
    Serial1.print("l1\r");
  }
}

void printSerial1Reading(){
  char digit;
  if(Serial1.available()>0){
    while(Serial1.available()){
      digit = Serial1.read();
      Serial.print(digit);
      if(digit==13)Serial.print(" \n");
    }
  }
}


void calibrate10(){
  //read for pH 10
  Serial1.print("C\r");
  Serial.print("in continuous\n");
  delay(400);
  printSerial1Reading();

  Serial.println("starting 10\n");
  delay(120000);
  Serial1.print("T\r");  
  delay(400);
  printSerial1Reading();
  Serial.println("finish 10\n");
  Serial1.print("E\r");
}


void calibratePH(){  
  char digit;
  //read for pH 7
  Serial1.print("C\r");
  Serial.print("in continuous\n");
  delay(400);
  printSerial1Reading();

  Serial.println("starting 7\n");
  delay(120000);
  Serial1.print("S\r");  
  delay(400);
  printSerial1Reading();
  Serial.println("finish 7\n");
  
  while(true){
    x = Serial.read();
    if (x == '1') break;
  }
  
  //read for pH 4
  Serial1.print("C\r");
  delay(100);
  printSerial1Reading();
  
  delay(120000);
  Serial1.print("F\r");  
  delay(100);
  printSerial1Reading();
  Serial.println("finish 4");
  
  while(true){
    y = Serial.read();
    if (y == '1') break;
  }
    
  //read for pH 10
  Serial1.print("C\r");
  delay(100);
  printSerial1Reading();
  Serial.println("starting 10\n");
  
  delay(120000);
  Serial1.print("T\r");  
  delay(100);
  printSerial1Reading();
  Serial.println("finish 10");


  Serial1.print("E\r");  
  delay(100);
  printSerial1Reading();
  Serial.print("Finish saving\n");
}

void receiveMotor(){
  Serial.println("in receive motor");
  if (!client.connected()) {client.connect();}
  client.println("GET /~Ben/dcc/getMotorData.php");
  client.println();
  
  delay(500);
  if (client.connected()) {/*Serial.println("still connected");*/}
  
  motorResponse = "";
  while(client.available()){
    c = client.read();
    //Serial.print(c);
    motorResponse += c;
  }
  
  //Serial.println("receive motor " + motorResponse);
  if (motorResponse == "*CLOS*ON" || motorResponse == "ON") {Serial.println("motor ON!"); MOTOR_STATE = ON; analogWrite(MOTOR_PIN, MOTOR_SPEED);}
  if (motorResponse == "*CLOS*OFF" || motorResponse == "OFF") {Serial.println("motor OFF!"); MOTOR_STATE = OFF; analogWrite(MOTOR_PIN, 0);}
  if (motorResponse == "*CLOS*Auto" || motorResponse == "Auto") {/*Serial.println("motor AUTO")*/; MOTOR_STATE = AUTO; analogWrite(MOTOR_PIN, 0);}
}

void receiveCamera(){
  Serial.println("in receive camera");
  if (!client.connected()) {client.connect();}
  client.println("GET /~Ben/dcc/imageProc.php");
  client.println();
  
  delay(3000);
  if (client.connected()) {/*Serial.println("still connected");*/}
  
  cameraResponse = "";
  while(client.available()){
    c = client.read();
    //Serial.print(c);
    cameraResponse += c;
  }
  
  //Serial.println("receive camera " + cameraResponse);
  if (cameraResponse == "*CLOS*\nON" || cameraResponse == "ON" || cameraResponse == "\nON") {/*Serial.println("camera says OK")*/; motorOn=true;}
  else {motorOn=false;}

}

void motor(){
  //Serial.println("in motor");
  //do this only if motor is in AUTO state
  if (MOTOR_STATE == AUTO) {
    //motorSecond += MOTOR_PERIOD/1000;
    Serial.println(motorSecond);
    if(motorOn==true){
      //Serial.println("motorOn is true");
      analogWrite(MOTOR_PIN, MOTOR_SPEED);
      delay(MOTOR_ROTATING_DURATION);
      motorSecond = 0;
      Serial.println(motorSecond);
      motorOn = false;
    }
    
    //actual code
    
    if (motorSecond > MOTOR_ROTATING_DURATION){
      Serial.println("motorSecond: " + motorSecond);
      analogWrite(MOTOR_PIN, 0);
    }
    
    /*
     //TESTING PART
    //if it's time to turn on the motor
    if (motorSecond == MOTOR_OFF_PERIOD){
      analogWrite(MOTOR_PIN, MOTOR_SPEED);
    }
    //if it's time to turn off the motor
    if (motorSecond >= MOTOR_OFF_PERIOD + MOTOR_ROTATING_DURATION){
      analogWrite(MOTOR_PIN, 0);
      motorSecond = 0;
    }*/
    
  }
}


void loop(){
  t.update();
}

