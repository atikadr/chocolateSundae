#include "WiFly.h"
#include "Credentials.h"
byte localhost[] = {};
Client client(localhost, 80);
char c;

int i, sensorValue;
String RFID;
char _rfid;
#define RFID_pin 7

void setup(){
  Serial.begin(9600);
  Serial2.begin(2400);
  pinMode(RFID_pin, OUTPUT);
  digitalWrite(RFID_pin, HIGH);
  
  WiFly.begin();
  if(!WiFly.join(ssid, passphrase)){
    Serial.println("Association failed.");
    while(1){
      // Hang on failure.
    }
  }
  Serial.println(WiFly.ip());
  if(client.connect())
    Serial.println("connected");
  else
    Serial.println("connection failed");
    
  delay(1000);
}

void loop(){
  sensorValue = analogRead(A0) * 5.0/10;
  Serial.println(sensorValue);
  if(sensorValue <= 43){
    readRFID();
    delay(1000);
  }
}

void readRFID(){
  digitalWrite(RFID_pin, LOW);
  while(!Serial2.available()){}
  
  //if the reader detects a card
  while(Serial2.available()){
    digitalWrite(RFID_pin, HIGH);
    Serial.println("RECEIVE RFID");
    RFID = "";
    _rfid = Serial2.read();    //read in first byte
    delay(25);
   
    //read the remaining bytes and put it into the packet
    int i;
    for (i = 0 ; i < 10 ; i++){
      _rfid = Serial2.read();
      RFID += _rfid;
      delay(25);
    }
    
    //read the last byte
    _rfid = Serial2.read();
    
    Serial.println(RFID); //for testing purposes  
    
    /*
    //send to server
    toSendRFID = "GET /dcp/increasePoints.php?points=10&rfid=" + RFID;
    
    if (!client.connected()) {client.connect();} 
    client.println(toSendRFID);
    client.println();
    delay(1000); //give it sometime to receive back
   
    while (client.available()) {
      c = client.read();
      Serial.print(c);
    } 
 */   
  }
}
