#!/bin/bash
Version=1.1
Release=15/04/2018

GPIO_PIN=11     #GPIO Pin number to turn led on and off
INVERT="NO"     #If YES => led ON when okcash crashed, NO => led ON when okcash running

echo -e "\n\e[92mOkcash Headless Node Led-Status v$Version ($Release):\e[0m"
echo -e "wareck@gmail.com"
echo -e ""
echo -e "This script will install led-status addon script and service."
echo -e "Read documentation for installing hardware."
echo -e "\n\e[97mConfiguration\e[0m"
echo -e "-------------"
echo -e "GPIO Pin     : $GPIO_PIN"
echo -e "LED inverted : $INVERT"
sleep 2

MyUser=$USER

cd ~
if [ ! -d scripts ]; then mkdir scripts ; fi
if [ ! -d scripts/ledstatus ];then mkdir scripts/ledstatus ; fi
if [ -f scripts/ledstatus/ledstatus.sh ]; then rm scripts/ledstatus/ledstatus.sh; fi
if [ -f scripts/ledstatus/led_on.py ]; then rm scripts/ledstatus/led_on.py; fi
if [ -f scripts/ledstatus/led_off.py ]; then rm scripts/ledstatus/led_off.py; fi

if [ $INVERT = "NO" ];
then
XXX="off"
YYY="on"
else
XXX="on"
YYY="off"
fi

echo -e "\n\e[95mBuild ledstatus.sh script :\e[0m"
cat <<'EOF'>> scripts/ledstatus/ledstatus.sh
#!/bin/bash
## GPIO = PPP
## INVERTED = III : led will be $XX if okcashd is running , and led $YY if not .
if  ps -ef | grep -v grep | grep okcashd >/dev/null # check if okcash is running or not
then
connexion=$(okcashd getnetworkinfo | awk 'NR ==7{print$3}'| sed 's/,//g') #check if it's connected on network and find peers
reacheable=$(okcashd getnetworkinfo | awk 'NR ==12{print$3}' | sed 's/,//g') # check if it's reachable
if [ -z $connexion ];then connexion=0;fi
if [ -z $reacheable ];then reacheable=0;fi
else
connexion=0
reacheable=0
okcashrun=0
fi
if [ $reacheable = "true" ]
then
okcashrun=1 #I'm reachable
fi
if [ $connexion -ge 1 ]
then
okcashrun=1 #I've got at least one peer node
else
okcashrun=0
fi
if [ $okcashrun = 0 ]
then
sudo python /home/ZZZ/scripts/ledstatus/led_XXX.py
else
#I'm recheable and I have one peer = running
sudo python /home/ZZZ/scripts/ledstatus/led_YYY.py
fi
EOF
sudo bash -c "sed -i -e 's/ZZZ/$MyUser/g' scripts/ledstatus/ledstatus.sh"
sudo bash -c "sed -i -e 's/XXX/$XXX/g' scripts/ledstatus/ledstatus.sh"
sudo bash -c "sed -i -e 's/YYY/$YYY/g' scripts/ledstatus/ledstatus.sh"
sudo bash -c "sed -i -e 's/PPP/$GPIO_PIN/g' scripts/ledstatus/ledstatus.sh"
sudo bash -c "sed -i -e 's/III/$INVERT/g' scripts/ledstatus/ledstatus.sh"
chmod +x  scripts/ledstatus/ledstatus.sh
echo "Done."

echo -e "\n\e[95mBuild led_on.py & led_off.py script :\e[0m"
cat <<EOF>> scripts/ledstatus/led_on.py
import RPi.GPIO as GPIO
from time import sleep
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BOARD)
GPIO.setup($GPIO_PIN, GPIO.OUT)
GPIO.output($GPIO_PIN,1)
EOF

cat <<EOF>> scripts/ledstatus/led_off.py
import RPi.GPIO as GPIO
from time import sleep
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BOARD)
GPIO.setup($GPIO_PIN, GPIO.OUT)
GPIO.output($GPIO_PIN,0)
EOF

echo "Done."

echo -e "\n\e[95mAdding Led_status to contab :\e[0m"
if  ! grep "/home/pi/scripts/ledstatus/ledstatus.sh" /etc/crontab >/dev/null
then
MyUser=$USER
echo $MyUser>/tmp/tmp3
sudo bash -c 'echo "" > /dev/null >>/etc/crontab | sudo -s'
sudo bash -c 'echo "#Okcash led_status" > /dev/null >>/etc/crontab | sudo -s'
sudo bash -c 'form=$(cat "/tmp/tmp3") && echo "* * * * * $form bash /home/pi/scripts/ledstatus/ledstatus.sh" >>/etc/crontab | sudo -s'
fi
echo -e "Done."

#echo -e "\n\e[95mSystem check : \e[97mLed blinking\e[0m"
#echo -e "Led must blink..."
#echo -e "Otherwise, check your wiring / gpio port number\n"
#echo -e "Press any key to continue..."
#if [ -t 0 ]; then stty -echo -icanon -icrnl time 0 min 0; fi
#
#while true; do
#	sudo python /home/$MyUser/scripts/ledstatus/led_off.py
#	sleep 0.01
#	sudo python /home/$MyUser/scripts/ledstatus/led_on.py
#   read -r -s -t 0.1 -n 1 input
#    if [ ! -z $input ]; then
#	echo -e "Done."
#	break
#    fi
#done

#if [ -t 0 ]; then stty sane; fi

~/scripts/ledstatus/ledstatus.sh
echo -e "\nInstall done !"
