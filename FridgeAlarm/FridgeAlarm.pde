#define DATA_PIN  2
#define WR_PIN    13
#define RD_PIN    4
#define CS_PIN    5

enum {
  SYS_DIS   = 0b00000000,
  SYS_EN    = 0b00000001,
  LCD_OFF   = 0b00000010,
  LCD_ON    = 0b00000011,
  TIMER_DIS = 0b00000100,
  WDT_DIS   = 0b00000101,
  TIMER_EN  = 0b00000110,
  WDT_EN    = 0b00000111,
  TONE_OFF  = 0b00001000,
  TONE_ON   = 0b00001001,
  
  //Set bias to 1/2 or 1/3 cycle
  //Set to 2,3 or 4 connected COM lines
  BIAS_HALF_2_COM  = 0b00100000,
  BIAS_HALF_3_COM  = 0b00100100,
  BIAS_HALF_4_COM  = 0b00101000,
  BIAS_THIRD_2_COM = 0b00100001,
  BIAS_THIRD_3_COM = 0b00100101,
  BIAS_THIRD_4_COM = 0b00101001,
  
  //Don't use
  TEST_ON   = 0b11100000,
  TEST_OFF  = 0b11100011
} Commands;

//Write up to 8 bits
void writeBits(byte data, byte cnt)
{
  byte bitmask;
  while (cnt) {
    digitalWrite(WR_PIN, LOW);
    byte bitval = data & (1 << (cnt - 1)) ?
                  HIGH : LOW;
    digitalWrite(DATA_PIN, bitval);
    digitalWrite(WR_PIN, HIGH);
    cnt--;
  }
}

void readBits(byte *data, byte cnt)
{
  int i;
  pinMode(DATA_PIN, INPUT);
  *data = 0;
  while (cnt) {
   digitalWrite(RD_PIN, LOW);
   *data += digitalRead(DATA_PIN) << (cnt - 1);
   digitalWrite(RD_PIN, HIGH);
   cnt--;
  }
  pinMode(DATA_PIN, OUTPUT);
}

#define COMMAND_MODE 0b100
void writeCommand(byte cmd, bool first = true, bool last = true)
{
  if (first) {
    digitalWrite(CS_PIN, LOW);
    writeBits(COMMAND_MODE, 3);
  }
  writeBits(cmd, 8);
  writeBits(0, 1); //Don't care
  if (last)
    digitalWrite(CS_PIN, HIGH);
}

#define WRITE_MODE 0b101
void writeMem(byte address, byte data)
{
  digitalWrite(CS_PIN, LOW);
  writeBits(WRITE_MODE, 3);
  writeBits(address, 6);
  writeBits(data, 4);
  digitalWrite(CS_PIN, HIGH);
}

//Write up to 256 values starting from address
//Note: Data is 8-bit aligned. This is not vary efficient
void writeMemRegion(byte address, byte *data, byte cnt)
{
  byte i;
  digitalWrite(CS_PIN, LOW);
  writeBits(WRITE_MODE, 3);
  writeBits(address, 6);
  for (i = 0; i < cnt; i++)
    writeBits(data[i], 4);
  digitalWrite(CS_PIN, HIGH);
}

#define READ_MODE 0b110
byte readMem(byte address)
{
  byte data;
  digitalWrite(CS_PIN, LOW);
  writeBits(READ_MODE, 3);
  writeBits(address, 6);
  readBits(&data, 4);
  digitalWrite(CS_PIN, HIGH);
  return data;
}

#define ADDR_MAX 128
void clearDisplay()
{
  digitalWrite(CS_PIN, LOW);
  writeBits(WRITE_MODE, 3);
  writeBits(0, 6);
  for (int i = 0; i < ADDR_MAX; i++)
    writeBits(0, 4);
  digitalWrite(CS_PIN, HIGH);
}

void setup()
{
  Serial.begin(9600);
  pinMode(DATA_PIN, OUTPUT);
  pinMode(WR_PIN, OUTPUT);
  pinMode(RD_PIN, OUTPUT);
  pinMode(CS_PIN, OUTPUT);
  
  //begin
  {
    //init device
    digitalWrite(CS_PIN, HIGH);
    digitalWrite(WR_PIN, HIGH);
    digitalWrite(RD_PIN, HIGH);
    digitalWrite(DATA_PIN, HIGH);
  
    //delay(100);
    writeCommand(SYS_DIS);
    clearDisplay();
    writeCommand(LCD_ON);
  }
  Serial.println("Done");
  //degrees celsius
  writeMem(1, 0b1010);
  writeMem(2, 0b1011);
  //writeCommand(SYS_EN);
}
  int i = 0;
void loop()
{
    writeMem(1, 0b1111);
  writeMem(2, 0b1111);

  writeMem(0, i % 16);
  Serial.println(i);
  i++;
  delay(2000);
}
