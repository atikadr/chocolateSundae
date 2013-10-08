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
*****************************************/


/****************************************
  DEFINE ALL THE PERIOD IN MILLISECONDS
*****************************************/
Timer t;
#define SEND_DATA_PERIOD 10000
#define RECEIVE_DATA_PERIOD 5000
#define READ_PH_SENSOR_PERIOD 2000


/****************************************
  DECLARATIONS
*****************************************/

byte localhost[] = {192,168,43,60};
Client client(localhost, 80);

#define MOTOR_PIN 13
char response; //1 indicates motor is on, 0 indicates motor is off

String pHreading; //stores the current pH sensor reading
byte received_from_ph_sensor =0;
char ph_data[20];
byte flag_ph_received=0;
String toSend;


/****************************************
  SETUP
*****************************************/

void setup() {
  pinMode(MOTOR_PIN, OUTPUT);
  digitalWrite(MOTOR_PIN, LOW);
  
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
  
  Serial.print(response);
  if (response == '1') {digitalWrite(MOTOR_PIN, HIGH);}
  else {digitalWrite(MOTOR_PIN, LOW);}
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



//do not touch the loop
void loop() {
  t.update();
}
