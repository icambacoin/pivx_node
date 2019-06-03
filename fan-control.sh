#!/bin/bash
Version=1.1
Release=10/08/2018

################
#Configuration :
###############
GPIO_PIN=4     #GPIO Pin number to turn fan on and off
Start_TEMP=47.0 #Start temperature in Celsius
Gap_TEMP=3.0  #Wait until the temperature is X degrees under the Max before shutting off

echo -e "\n\e[97mOkcash headless Node auto-fan v$Version ($Release):\e[0m"
echo -e "wareck@gmail.com"
echo -e ""
echo -e "This script will install auto-fan control script and service."
echo -e "Read documentation for installing hardware."
echo -e "\n\e[97mConfiguration\e[0m"
echo -e "-------------"
echo -e "GPIO Pin    : $GPIO_PIN"
echo -e "Start Temp  : $Start_TEMP°C"
echo -e "Gap Temp    : $Gap_TEMP°C"
sleep 2
echo -e "\n\e[95mBuild run-fan.py script :\e[0m"
MyUser=$USER

if [ ! -d /home/$USER/scripts ];then mkdir /home/$USER/scripts ; fi
if [ -f /home/$USER/scripts/run-fan.py ];then rm /home/$USER/scripts/run-fan.py ; fi

cat <<'EOF'>> /home/$USER/scripts/run-fan.py
#!/usr/bin/env python

#########################
#
# The original script is from:
#    Author: Edoardo Paolo Scalafiotti <edoardo849@gmail.com>
#    Source: https://hackernoon.com/how-to-control-a-fan-to-cool-the-cpu-of-your-raspberrypi-3313b6e7f92c
#
#########################

#########################
import os
import time
import signal
import sys
import RPi.GPIO as GPIO
import datetime

#########################
sleepTime = 30	# Time to sleep between checking the temperature
                # want to write unbuffered to file
fileLog = open('/tmp/run-fan.log', 'w+', 0)

#########################
# Log messages should be time stamped
def timeStamp():
    t = time.time()
    s = datetime.datetime.fromtimestamp(t).strftime('%Y/%m/%d %H:%M:%S - ')
    return s

# Write messages in a standard format
def printMsg(s):
    fileLog.write(timeStamp() + s + "\n")

#########################
class Pin(object):
    pin = XXXXX     # GPIO or BCM pin number to turn fan on and off

    def __init__(self):
        try:
            GPIO.setmode(GPIO.BCM)
            GPIO.setup(self.pin, GPIO.OUT)
            GPIO.setwarnings(False)
            printMsg("Initialized: run-fan using GPIO pin: " + str(self.pin))
        except:
            printMsg("If method setup doesn't work, need to run script as sudo")
            exit

    # resets all GPIO ports used by this program
    def exitPin(self):
        GPIO.cleanup()

    def set(self, state):
        GPIO.output(self.pin, state)

# Fan class
class Fan(object):
    fanOff = True

    def __init__(self):
        self.fanOff = True

    # Turn the fan on or off
    def setFan(self, temp, on, myPin):
        if on:
            printMsg("Turning fan on " + str(temp))
        else:
            printMsg("Turning fan off " + str(temp))
        myPin.set(on)
        self.fanOff = not on

# Temperature class
class Temperature(object):
    cpuTemperature = 0.0
    startTemperature = 0.0
    stopTemperature = 0.0

    def __init__(self):
        # Start temperature in Celsius
        #   Maximum operating temperature of Raspberry Pi 3 is 85C
        #   CPU performance is throttled at 82C
        #   running a CPU at lower temperatures will prolong its life
        self.startTemperature = YYYYY

        # Wait until the temperature is M degrees under the Max before shutting off
        self.stopTemperature = self.startTemperature - ZZZZZ

        printMsg("Start fan at: " + str(self.startTemperature))
        printMsg("Stop fan at: " + str(self.stopTemperature))

    def getTemperature(self):
        # need to specify path for vcgencmd
        res = os.popen('/opt/vc/bin/vcgencmd measure_temp').readline()
        self.cpuTemperature = float((res.replace("temp=","").replace("'C\n","")))

    # Using the CPU's temperature, turn the fan on or off
    def checkTemperature(self, myFan, myPin):
        self.getTemperature()
        if self.cpuTemperature > self.startTemperature:
            # need to turn fan on, but only if the fan is off
            if myFan.fanOff:
                myFan.setFan(self.cpuTemperature, True, myPin)
        else:
            # need to turn fan off, but only if the fan is on
            if not myFan.fanOff:
                myFan.setFan(self.cpuTemperature, False, myPin)

#########################
printMsg("Starting: run-fan")
try:
    myPin = Pin()
    myFan = Fan()
    myTemp = Temperature()
    while True:
        myTemp.checkTemperature(myFan, myPin)

        # Read the temperature every N sec (sleepTime)
        # Turning a device on & off can wear it out
        time.sleep(sleepTime)

except KeyboardInterrupt: # trap a CTRL+C keyboard interrupt
    printMsg("keyboard exception occurred")
    myPin.exitPin()
    fileLog.close()

except:
    printMsg("ERROR: an unhandled exception occurred")
    myPin.exitPin()
    fileLog.close()
EOF
chmod +x /home/$USER/scripts/run-fan.py
echo -e "Done."

echo -e "\n\e[95mApply Configuration :\e[0m"
sed -i -e "s/XXXXX/$GPIO_PIN/g" /home/$USER/scripts/run-fan.py
sed -i -e "s/YYYYY/$Start_TEMP/g" /home/$USER/scripts/run-fan.py
sed -i -e "s/ZZZZZ/$Gap_TEMP/g" /home/$USER/scripts/run-fan.py
echo -e "Done."

#if [ $GPIO_PIN = "4" ]
#then
#echo -e "\n\e[95mDisable 1wire-GPIO :\e[0m"
#	if  ! grep "dtoverlay=w1-gpio" /boot/config.txt >/dev/null
#		then
#		sudo bash -c 'echo "" >>/boot/config.txt'
#		sudo bash -c 'echo "# Disable OneWire driver" >>/boot/config.txt'
#		sudo bash -c 'echo "dtoverlay=w1-gpio" >>/boot/config.txt'
#		fi
#echo -e "Done."
#fi

echo -e "\n\e[95mBuild run-fan.service script :\e[0m"
if [ -f /tmp/run-fan.service ]; then rm /tmp/run-fan.service;fi
sudo cat <<'EOF'>> /tmp/run-fan.service
[Unit]
Description=autofan control
After=meadiacenter.service
[Service]
   User=root
   Group=root
   Type=simple
   ExecStart=/usr/bin/python /home/XXX/scripts/run-fan.py
   Restart=always 

  [Install]
   WantedBy=multi-user.target
EOF
sed -i -e "s/XXX/$MyUser/g" /tmp/run-fan.service
sudo bash -c 'cp /tmp/run-fan.service /lib/systemd/system/ | sudo -s'
echo -e "Done"
sleep 1

sudo systemctl daemon-reload
sudo systemctl enable run-fan.service
sleep 5


echo -e "\n\e[97mInstall is finished !!!\e[0m"
