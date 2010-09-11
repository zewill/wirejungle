/*
	Copyright 2009-2010 Ami Chayun
	
	CoffeeMan is a simple program to turn on a relay in a user selectable time
	
	This file is free software; you can redistribute it and/or modify
	it under the terms of either the GNU General Public License version 2
	or the GNU Lesser General Public License version 2.1, both as
	published by the Free Software Foundation.
*/
#include <LiquidCrystal.h>
#include <ShiftRegister.h>

#include <inttypes.h>

#define MAX_TIMESTAMP  ((unsigned long) -1)

#define LCD_RS_PIN   6
#define LCD_RW_PIN   7
#define LCD_EN_PIN   8
#define LCD_D4_PIN   12
#define LCD_D5_PIN   11
#define LCD_D6_PIN   10
#define LCD_D7_PIN   9

//shift register buttons
#define SHIFT_CLK_PIN 3
#define SHIFT_DATA_PIN 4
#define SHIFT_LOAD_PIN 2
#define SHIFT_CLR_PIN 5  //optional clear pin

#define RELAY_PIN  13
#define DEBOUNCE 350

#define MSG_TIMEOUT 2000

#define ALARM_DELAY  2000

#define ALARM_STR "Alarm "
#define TIME_STR   "Time "

#define IS_BTN_SET(x) (x & 0x8)
#define IS_BTN_PLUS(x) (x & 0x4)
#define IS_BTN_MINUS(x) (x & 0x2)
#define IS_BTN_ALARM(x) (x & 0x1)
#define IS_BTN_DISPLAY(x) (x & 0x10)

#define IS_BTN_PLUS_OR_MINUS(x) (x & 0x6)  //Plus or minus

#define IS_BTN_DOWN(x) (x & 0x1F)  //Any of the above

#define INC_MINUTE(x)                      \
	do  {                              \
		x.minute++;                \
		if (x.minute == 60)        \
			x.minute = 0;      \
	} while(0);                        

#define INC_HOUR(x)                        \
	do  {                              \
		x.hour++;                  \
		if (x.hour == 24)          \
			x.hour = 0;        \
	} while(0);

#define DEC_MINUTE(x)                      \
	do  {                              \
		x.minute--;                \
		if (x.minute > 60)         \
			x.minute = 59;     \
	} while(0);

#define DEC_HOUR(x)                        \
	do  {                              \
		x.hour--;                  \
		if (x.hour > 24)           \
			x.hour = 23;       \
	} while(0);

#define CLEAR_MSG  do {show_msg = 0; refreshDisplay = true; msg_str2 = NULL;} while(0);
#define SET_MSG(x)  do {show_msg = millis(); msg_str1 = x;} while(0);
#define SET_MSG2(x)  do {msg_str2 = x;} while(0);

uint8_t bell_symbol[] = {
	0b00100,
	0b01010,
	0b01010,
	0b10001,
	0b10001,
	0b01110,
	0b00100,
	0b00000
};
uint8_t coffee_symbol1[] = {
	0b11111,
	0b10000,
	0b10000,
	0b10000,
	0b11111,
	0b11111,
	0b11111,
	0b01111
};

uint8_t coffee_symbol2[] = {
	0b11110,
	0b00101,
	0b00101,
	0b00101,
	0b11101,
	0b11110,
	0b11100,
	0b11000
};

uint8_t coffee_steam1[] = {
	0b10010,
	0b10010,
	0b01001,
	0b10010,
	0b10010,
	0b01001,
	0b10010,
	0b10010
};

uint8_t coffee_steam2[] = {
	0b01000,
	0b01000,
	0b00100,
	0b00100,
	0b01000,
	0b00100,
	0b00100,
	0b01000
};


LiquidCrystal lcd(LCD_RS_PIN, LCD_RW_PIN, LCD_EN_PIN, 
                  LCD_D4_PIN, LCD_D5_PIN, LCD_D6_PIN, 
                  LCD_D7_PIN);

ShiftRegisterIn reg(SHIFT_CLK_PIN, SHIFT_DATA_PIN, SHIFT_LOAD_PIN, SHIFT_CLR_PIN);

typedef struct Time {
	byte hour;
	byte minute;
	long msec;
	boolean initialized;
	char str[6];
	Time() : hour(0), minute(0), msec(0), initialized(false) {str[2] = ':';str[5] = 0;};
	const char *toStr()
	{
		str[0] = '0' + (hour / 10);
		str[1] = '0' + (hour % 10);
		//str[2] = ":";  //pre initialized
		str[3] = '0' + (minute / 10);
		str[4] = '0' + (minute % 10);
		return str;
	}
};

struct Time clock, alarm;

boolean blinkOn = false;
long blinkTimer = 0;

boolean displayMode = 0;

enum {
  SET_MODE_NONE = 0,
  SET_MODE_HH   = 1,
  SET_MODE_MM   = 2,
  SET_MODE_MAX  = 3
};
byte setMode = SET_MODE_NONE;

int inputs;
long last_read = 0;

long show_msg = 0;
const char * msg_str1, *msg_str2 = 0;

int seconds = 0;
int dt = 0;
unsigned long timestamp;
boolean refreshDisplay;

void setup()
{
	timestamp = millis();
	lcd.begin(16, 2);
	lcd.createChar(1, coffee_symbol1);
	lcd.createChar(2, coffee_symbol2);
	lcd.createChar(3, bell_symbol);
	lcd.createChar(4, coffee_steam1);
	lcd.createChar(5, coffee_steam2);

	pinMode(RELAY_PIN, OUTPUT);
	digitalWrite(RELAY_PIN, LOW);
}

void loop()
{
	if (clock.initialized) {
		advance_clock();
	}
	handleAlarm();

	handleInputs(); //Allow one press every DEBOUNCE msec

	//Show warning / info messages, 
	//unless the user caused some sort of display change
	if (show_msg && ! refreshDisplay) {
		displayMsg();
	} else if (displayMode == 0) { //show clock/alarm
		//clock is not set, blink 00:00
		if (! clock.initialized && setMode == SET_MODE_NONE)  {
			blink_string(TIME_STR "00:00");
		} else if (refreshDisplay) {
			displayClock();
		} 
	} else if (refreshDisplay) {  //show alarm
		displayAlarm();
	}
}

inline void blink_string(char *str)
{
#define BLINK_DELAY 500
	if (blinkTimer == 0 || (blinkTimer + BLINK_DELAY < millis()) || (millis() < blinkTimer)) { 
		if (blinkOn == false) {
			lcd.print(str);
			blinkOn = true;
		} else {
			lcd.clear();
			blinkOn = false;
		}
		blinkTimer = millis();
	} else {
		//Do nothing, stay at current state
	}
}

inline void displayClock()
{
	refreshDisplay = false;
	lcd.clear();
	lcd.print(TIME_STR);
	lcd.print(clock.toStr());
	lcd.setCursor(0, 1);
	lcd.print(ALARM_STR "[");
	if (alarm.initialized)
		lcd.write(0x3);
	else
		lcd.print(" ");
	lcd.print("]");

        setMode != SET_MODE_NONE ? lcd.blink() : lcd.noBlink();
	if (setMode == SET_MODE_HH) {
		lcd.setCursor(sizeof(TIME_STR) + 3, 0);
	} else if (setMode == SET_MODE_MM) {
		lcd.setCursor(sizeof(TIME_STR), 0);
	}
}

inline void displayAlarm()
{
	refreshDisplay = false;
	lcd.clear();
	lcd.print(ALARM_STR);
	lcd.print(alarm.toStr());

	//Show some blinken if we're in set. Blink low hours or low min
	setMode != SET_MODE_NONE ? lcd.blink() : lcd.noBlink();
	if (setMode == SET_MODE_HH) {
		lcd.setCursor(sizeof(ALARM_STR) + 3, 0);
	} else if (setMode == SET_MODE_MM) {
		lcd.setCursor(sizeof(ALARM_STR), 0);
	}
}

inline void displayMsg()
{
	if ( (millis() - show_msg) < MSG_TIMEOUT) {
		//TODO: Clock wrap?
		lcd.noBlink();
		lcd.home();
		lcd.print(msg_str1);
		if (msg_str2) {
			lcd.setCursor(0,1);
			lcd.print(msg_str2);
		}
	}else {
		CLEAR_MSG;
	}
}

inline void handleAlarm()
{
	if (clock.initialized && alarm.initialized 
			&&clock.hour == alarm.hour && clock.minute == alarm.minute)
		if (alarm.msec == 0) {
			//alarm on
			SET_MSG("Brewing   \x04\x05");
			SET_MSG2("Coffee... \x01\x02");
			alarm.msec = millis();
			digitalWrite(RELAY_PIN, HIGH);
		} else if (alarm.msec + ALARM_DELAY < millis() || millis() < alarm.msec) {
			digitalWrite(RELAY_PIN, LOW);
			alarm.initialized = false;
			refreshDisplay = true;
		}
}

inline void handleInputs()
{
	inputs = reg.read();
	if (IS_BTN_DOWN(inputs)) {
		if ((millis() - last_read) > DEBOUNCE || millis() < last_read) {
			CLEAR_MSG;  //user clicked a button, clear any message
			last_read = millis();

			toggleSet();
			toggleAlarm();
			toggleDisplay();
			adjustTime();
		}
	}
}

//Cycle setMode, nothing / hours / minutes
inline void toggleSet()
{
	if (IS_BTN_SET(inputs)) {
		setMode++;
		if (setMode == SET_MODE_MAX)
			setMode = SET_MODE_NONE;
	}
}

inline void toggleAlarm()
{
	if (IS_BTN_ALARM(inputs)) {
		refreshDisplay = true;
		displayMode = 0;  //alarm is shown only in clock mode, show something to the user
		if (alarm.initialized) {
			alarm.initialized = false;
		} else {
			alarm.initialized = true;
			alarm.msec = 0;
		}
	}
}

//toggle display 0 = clock, 1 = alarm
inline void toggleDisplay()
{
	if (IS_BTN_DISPLAY(inputs)) {
		displayMode = ~displayMode;
		refreshDisplay = true;
		setMode = SET_MODE_NONE;
	}
}

inline void adjustTime()
{
	if (setMode != SET_MODE_NONE) {
		if (IS_BTN_PLUS_OR_MINUS(inputs)) {
			refreshDisplay = true;
			if (displayMode == 0 && ! clock.initialized)
				clock.initialized = true;
		}
		if (IS_BTN_PLUS(inputs)) {
			if (setMode == SET_MODE_HH) {
				INC_MINUTE( (displayMode == 0 ? clock : alarm) );
			} else { //setMode == SET_MODE_MM
				INC_HOUR((displayMode == 0 ? clock : alarm));
			}  
		} else if (IS_BTN_MINUS(inputs)) {
			if (setMode == SET_MODE_HH) {
				DEC_MINUTE((displayMode == 0 ? clock : alarm));
			} else {//setMode == SET_MODE_MM
				DEC_HOUR((displayMode == 0 ? clock : alarm));  
			}  
		}
	}
	if (setMode == SET_MODE_HH && (IS_BTN_PLUS(inputs) || IS_BTN_MINUS(inputs)) ) {
		seconds = 0;  //reset seconds on minute change
		timestamp = millis();  //reset msec
	}
}

inline void advance_clock()
{
	long tick2 = millis();
	if (tick2 >= timestamp) {
		dt += tick2 - timestamp;
	}else  {//clock wrap
		dt = MAX_TIMESTAMP - timestamp + tick2;
	}
	timestamp = tick2;
	if (dt >= 1000) {
		dt -= 1000;
		seconds++;
		if (seconds == 60) {
			INC_MINUTE(clock);
			if (clock.minute == 0)
				INC_HOUR(clock);
			seconds = 0;
			refreshDisplay = true;
		}
	}
}
