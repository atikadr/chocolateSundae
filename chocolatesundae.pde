#include "WiFly.h"
#include "Credentials.h"
#include "Timer.h"

/***************************************
  FUNCTIONS IN THIS CODE:
    - sendSlurrp()
        sends sensor data to server
        only for testing
    - receiveMotor()
        receives motor ON OFF AUTO mode
    - receiveCamera()
        receives reading based on camera
    - motor()
        turn on motor every 5 minutes if it's in AUTO mode
        contains functionality for testing motor (commented out)
    - readpH()
        reads pH sensor and sends it to server
        connect pH sensor to Serial3
    - readRFID()
        get data from the RFID reader and send it to the server
        connect RFID reader to Serial1
    - ASCIItable(byte)
        turn bytes into ASCII character
*****************************************/


/****************************************
  DEFINE ALL THE PERIOD IN MILLISECONDS
*****************************************/
Timer t;
//#define SEND_DATA_PERIOD 10000
#define RECEIVE_MOTOR_PERIOD 5000
#define READ_PH_SENSOR_PERIOD 2000 //1 hour
#define MOTOR_PERIOD 5000 //check motor every 5 seconds
#define MOTOR_OFF_PERIOD 270 //in seconds, only for testing
#define MOTOR_ROTATING_DURATION 30 //in seconds
#define MOTOR_SPEED 255 // 0 is completely off, 255 is maximum speed
#define RFID_PERIOD 3000

/****************************************
  DECLARATIONS
*****************************************/

byte localhost[] = {192,168,43,60};
Client client(localhost, 80);
char c;

#define MOTOR_PIN 13
String motorResponse; //1 indicates motor is on manual ON mode, 0 indicates motor is AUTO mode
String cameraResponse;
enum motorState {ON, OFF, AUTO};
motorState MOTOR_STATE = AUTO;
int motorSecond = 0; //indicates how many seconds have passed since motor was turned on
boolean motorOn; //indicates whether camera says motor should be turned on or not

String pHreading;
String toSendpH;
String pH;
byte _pH;

#define RFID_pin 22
String RFID;
String toSendRFID;
byte _rfid;


/****************************************
  SETUP
*****************************************/

void setup() {
  analogWrite(MOTOR_PIN, 0); //turn off motor first
  motorSecond = 0;
  motorOn=false;
  pinMode(RFID_pin, OUTPUT);
  digitalWrite(RFID_pin, HIGH); //turn off RFID first
  
  Serial.begin(9600);
  Serial1.begin(2400);
  Serial3.begin(38400);
  
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
  
  //t.every(READ_PH_SENSOR_PERIOD, readpH);
  t.every(RECEIVE_MOTOR_PERIOD, receiveMotor);
  t.every(MOTOR_PERIOD, motor);
  t.every(RFID_PERIOD, readRFID);
  
}


/****************************************
  FUNCTIONS
*****************************************/

void receiveMotor(){
  Serial.println("in receive motor");
  if (!client.connected()) {client.connect();}
  client.println("GET /~Ben/chocolateSundae/whipcream.php?");
  client.println();
  
  delay(1000);
  if (client.connected()) {Serial.println("still connected");}
  
  motorResponse = "";
  while(client.available()){
    c = client.read();
    Serial.print(c);
    motorResponse += c;
  }
  
  Serial.print(motorResponse);
  if (motorResponse == '1') {analogWrite(MOTOR_PIN, MOTOR_SPEED);}
  else {analogWrite(MOTOR_PIN, 0);}
  
}

void receiveCamera(){
  Serial.println("in receive camera");
  if (!client.connected()) {client.connect();}
  client.println("GET /~Ben/chocolateSundae/whipcream.php?");
  client.println();
  
  delay(1000);
  if (client.connected()) {Serial.println("still connected");}
  
  cameraResponse = "";
  while(client.available()){
    c = client.read();
    Serial.print(c);
    cameraResponse += c;
  }
  
  Serial.print(cameraResponse);
  if (cameraResponse == '1') {motorOn=true;}
  else {motorOn=false;}

}

void motor(){
  //do this only if motor is in AUTO state
  if (MOTOR_STATE == AUTO) {
    motorSecond += MOTOR_PERIOD/1000;
    if(motorOn==true){
      analogWrite(MOTOR_PIN, MOTOR_SPEED);
      motorSecond = 0;
      motorOn = false;
    }
    
    //actual code
    if (motorSecond >= MOTOR_ROTATING_DURATION){
      analogWrite(MOTOR_PIN, 0);
      motorSecond = 0;
    }
    
    /* TESTING PART
    //if it's time to turn on the motor
    if (motorSecond == MOTOR_OFF_PERIOD){
      analogWrite(MOTOR_PIN, MOTOR_SPEED);
    }
    //if it's time to turn off the motor
    if (motorSecond >= MOTOR_OFF_PERIOD + MOTOR_ROTATING_DURATION){
      analogWrite(MOTOR_PIN, 0);
      motorSecond = 0;
    }
    */
  }
}

void readpH(){
  Serial.println("in reading pH");

  //send read command
  Serial3.print("R/r");
  pHreading = "";
  //receive ph response
  delay(100);
  if(Serial3.available()>0){
    while(Serial3.available()){
      _pH = Serial3.read();
      if (_pH == 13) break;
      pH = ASCIItable(_pH);
      pHreading += pH;
    }
  }
  
  Serial.println(pHreading);
  
  //send pH reading to server
  toSendpH = "GET /~Ben/chocolateSundae/whipcream.php?slurrp=" + pHreading;
  
  if (!client.connected()) {client.connect();} 
  client.println(toSendpH);
  client.println();
  delay(1000); //give it sometime to receive back
   
  while (client.available()) {
    c = client.read();
    Serial.print(c);
  }
}

void readRFID(){
  //turn on RFID reader and delay for 500 ms
  digitalWrite(RFID_pin, LOW);
  delay(500);
  
  //if the reader detects a card
  if(Serial1.available()){
    digitalWrite(RFID_pin, HIGH); //turn off RFID reader
    
    RFID = "";
    _rfid = Serial1.read();    //read in first byte
    delay(25);
   
    //read the remaining bytes and put it into the packet
    int i;
    for (i = 0 ; i < 10 ; i++){
      _rfid = Serial1.read();
      RFID += ASCIItable(_rfid);
      delay(25);
    }
    
    //read the last byte
    _rfid = Serial1.read();
    
    Serial.println(RFID); //for testing purposes  
    
    //send to server
    toSendRFID = "" + RFID;
    
    if (!client.connected()) {client.connect();} 
    client.println(toSendRFID);
    client.println();
    delay(1000); //give it sometime to receive back
   
    while (client.available()) {
      c = client.read();
      Serial.print(c);
    }    
  }
}

char ASCIItable(byte b){
  switch (b){
    case 48: return '0'; break;
    case 49: return '1'; break;
    case 50: return '2'; break;
    case 51: return '3'; break;
    case 52: return '4'; break;
    case 55: return '7'; break;
    case 66: return 'B'; break;
    case 68: return 'D'; break;
    case 69: return 'E'; break;
    case 70: return 'F'; break;
    default: return 'x';
  }
}

/*
void sendSlurrp(){
  Serial.println("in send slurrp");
  toSendpH = "GET /~Ben/chocolateSundae/whipcream.php?slurrp=" + pHreading;
  
  if (!client.connected()) {client.connect();} 
  client.println(toSendpH);
  client.println();
  delay(1000); //give it sometime to receive back
   
  while (client.available()) {
    c = client.read();
    Serial.print(c);
  }
}
*/

//do not touch the loop
void loop() {
  t.update();
}
