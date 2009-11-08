/*
	Copyright 2009 Ami Chayun
	
	HRMonitor is a piece of code that samples data from Polar RMCM01 OEM
        module and calculates heart rate. Results are printed to serial port.
	
	This file is free software; you can redistribute it and/or modify
	it under the terms of either the GNU General Public License version 2
	or the GNU Lesser General Public License version 2.1, both as
	published by the Free Software Foundation.
*/

#define HR_PIN 10

long hr = 0;

long last_hr_ts = 0;
long last_report_ts = 0;
int report_delay = 2000; //Must be > 1000 miliseconds

long samples[8] = {0};  //size was chosen since it's optimized in division and modulus
byte last_sample = 0;

void setup()
{
  pinMode(HR_PIN, INPUT); 
  Serial.begin(9600);
}
void loop()
{
  long current_time = millis();
  if (digitalRead(HR_PIN) == HIGH)  {
        //First sample will be garbage, since last_hr_ts = 0
        //dt < 10 means the same sample. Otherwise it means hr of 6000bpm...
        //That's fast even for a colibri
        if (current_time - last_hr_ts > 10) {
            byte next_sample = ((last_sample + 1) % 8);
            samples[next_sample] = current_time - last_hr_ts;
            last_sample = next_sample;
        }
        last_hr_ts = current_time;
      }

  if (current_time - last_report_ts > report_delay)   {
    if (current_time - last_hr_ts < report_delay) {
      {
        long sum_samples = 0;
        byte i;
        for (i = 1; i < 9; ++i) {
          sum_samples += samples[((last_sample + i) % 8)];  //optimizes to (last_sample + 1)&7
      }
        sum_samples /= 8;  //optimizes to sum_samples >>= 3
          /*To be accurate (2 digits), we multiply the sample  by 100, and finally divide result */
        //hr = ((100000/(sum_samples))*60)/100;
        hr = (6000000/(sum_samples))/100;
        Serial.println(hr);
      }
    } else {
      Serial.println("Out of range");
    }
    last_report_ts = current_time;
  }
}
