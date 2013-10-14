#include "WiFly.h"
#include "Credentials.h"
#include "Timer.h"

/***************************************
  FUNCTIONS IN THIS CODE:
    - sendSlurrp()
        sends sensor data to server
    - receiveSlurrp()
        receives configuration by querying server
    - readpH()
        reads pH sensor and stores it in pHreading
        connect pH sensor to Serial3
    - motor()
        turn on motor every 5 minutes if it's in AUTO mode
    - readRFID()
        get data from the RFID reader
        connect RFID reader to Serial1
    - ASCIItable(byte, int)
        called by readRFID to turn bytes into string
*****************************************/


/****************************************
  DEFINE ALL THE PERIOD IN MILLISECONDS
*****************************************/
Timer t;
#define SEND_DATA_PERIOD 10000
#define RECEIVE_DATA_PERIOD 5000
#define READ_PH_SENSOR_PERIOD 2000
#define MOTOR_PERIOD 300000
#define MOTOR_ROTATING_DURATION 30000
#define MOTOR_SPEED 200 // 0 is completely off, 255 is maximum speed
#define RFID_PERIOD 3000

/****************************************
  DECLARATIONS
*****************************************/

byte localhost[] = {192,168,43,60};
Client client(localhost, 80);

#define MOTOR_PIN 13
char response; //1 indicates motor is on manual ON mode, 0 indicates motor is AUTO mode
enum MOTOR_STATE {ON, OFF, AUTO};

String pHreading; //stores the current pH sensor reading
byte received_from_ph_sensor =0;
char ph_data[20];
byte flag_ph_received=0;
String toSend;

#define RFID_pin 22
byte x;
char RFID[20];
String toSendRFID;


/****************************************
  SETUP
*****************************************/

void setup() {
  //pinMode(MOTOR_PIN, OUTPUT);
  analogWrite(MOTOR_PIN, 0);
  pinMode(RFID_pin, OUTPUT);
  digitalWrite(RFID_pin, HIGH);
  
  Serial.begin(9600);
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
  
  t.every(READ_PH_SENSOR_PERIOD, readpH);
  t.every(SEND_DATA_PERIOD, sendSlurrp);
  t.every(RECEIVE_DATA_PERIOD, receiveSlurrp);
  //t.every(MOTOR_PERIOD, motor);
  //t.every(RFID_PERIOD, readRFID);
  
}


/****************************************
  FUNCTIONS
*****************************************/

void receiveSlurrp(){
  Serial.println("in receive slurrp");
  if (!client.connected()) {client.connect();}
  client.println("GET /~Ben/chocolateSundae/whipcream.php?");
  client.println();
  
  delay(1000);
  if (client.connected()) {Serial.println("still connected");}
  
  while(client.available()){
    char c = client.read();
    Serial.print(c);
    response = c;
  }
  /*
  Serial.print(response);
  if (response == '1') {analogWrite(MOTOR_PIN, MOTOR_SPEED);}
  else {digitalWrite(MOTOR_PIN, LOW);}
  */
}

void sendSlurrp(){
  Serial.println("in send slurrp");
  toSend = "GET /~Ben/chocolateSundae/whipcream.php?slurrp=" + pHreading;
  
  if (!client.connected()) {client.connect();} 
  client.println(toSend);
  client.println();
  delay(1000); //give it sometime to receive back
   
  while (client.available()) {
    char c = client.read();
    Serial.print(c);
  }
}

void readpH(){
  Serial.println("in reading pH");

  //send read command
  Serial3.print("R/r");
  
  //receive ph response
      //add a delay(100) every time you finish sending an instruction and waiting for a response
      //to give the pH sensor some time to respond.
  delay(100);
  if(Serial3.available()>0){
    received_from_ph_sensor=Serial3.readBytesUntil(12,ph_data,20);
    ph_data[received_from_ph_sensor]=0;
    flag_ph_received = 1;
  }
  
  //read response
  if(flag_ph_received==1){
    pHreading = str(ph_data);
    flag_ph_received=0;
  }
}

void motor(){
  if (MOTOR_STATE == AUTO) {
    analogWrite(MOTOR_PIN, MOTOR_SPEED);
    delay(MOTOR_ROTATING_DURATION);
    analogWrite(MOTOR_PIN, 0);
    }
}

void ASCIItable(byte b, int i){
  switch (b){
    case 48: RFID[i] = '0'; break;
    case 50: RFID[i] = '2'; break;
    case 55: RFID[i] = '7'; break;
    case 66: RFID[i] = 'B'; break;
    case 68: RFID[i] = 'D'; break;
    case 69: RFID[i] = 'E'; break;
    case 70: RFID[i] = 'F'; break;
    default: ;
  }
}

void readRFID(){
  //turn on RFID reader and delay for 500 ms
  digitalWrite(RFID_pin, LOW);
  delay(500);
  
  //if the reader detects a card
  if(Serial.available()){
    digitalWrite(RFID_pin, HIGH); //turn off RFID reader
    
    x = Serial.read();    //read in first byte
    delay(25);
   
    //read the remaining bytes and put it into the packet
    int i;
    for (i = 0 ; i < 10 ; i++){
      x = Serial.read();
      ASCIItable(x, i);
      delay(25);
    }
    
    //read the last byte
    x = Serial.read();
    
    Serial.println(RFID); //for testing purposes  
    strcpy(toSendRFID, RFID); //copy the string to array of packets
    
    delay(1000); //wait for one second before turning on RFID again
  }
}

//do not touch the loop
void loop() {
  t.update();
}
