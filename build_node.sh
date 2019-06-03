#!/bin/bash
Version=1.0
Release=1/06/2019
author=wareck@gmail.com

#PIVX headless RPI Working (sync enable, staking enable)
pivx_v="`git ls-remote --tags https://github.com/PIVX-Project/PIVX.git | awk '{print $2}' | grep -v '{}' | awk -F"/" '{print $3}' | tail -n 2 | sed -n 1p`"
Dw=0 #Daemon working static
drpc_port=51473 #default rpc port
dudp_port=51474 #default remote port
set -e

############################
##Configuration / options ##
############################

#Bootstrap (speedup first start, but requier 2GB free space on sdcard)
Bootstrap=NO # YES or NO => download bootstrap.dat (take long time to start, but better)

#Optimiser Raspberry (give watchdog function and autostart pivx, speedup a little the raspberry)
Raspi_optimize=YES

#Website frontend (give a small web page to check if everything is ok)
Website=YES
Website_port=80 #80 for standard port other port for hiding website

#Enable firewall
Firewall=YES

#Enable autostart
AutoStart=YES

#Login banner
Banner=YES

#Reboot after build
Reboot=YES

LSB=$(lsb_release -r | awk '{print $2}')
OSV=$(sed 's/\..*//' /etc/debian_version)
if [ $OSV = 8 ];then img_v="Jessie";fi
if [ $OSV = 9 ];then img_v="Strecth"; fi
if [ -f /proc/device-tree/model ]
then
ident=`cat /proc/device-tree/model | awk '{print $6}'`
if [ $ident = "Plus" ]
then
ident=`cat /proc/device-tree/model | awk '{print $1" "$2" "$3""$5" "$6" "$7" v"$8}'`
else
ident=`cat /proc/device-tree/model | awk '{print $1" "$2" "$3""$5" v"$7}'`
fi

else
ident=""
img_v="Unknown"
fi
MyUser=$USER
MyDir=$PWD
echo $MyUser>/tmp/tmp_user
echo -e "\e[93mPIVX Headless Node builder v$Version ($Release)\e[0m"
echo -e "Author : wareck@gmail.com"
sleep 1
echo -e "\n\e[97mConfiguration\e[0m"
echo -e "-------------"
echo -e -n "Download Bootstrap.dat      : "; if [ $Bootstrap = "YES" ];then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]";fi
echo -e -n "Autostart at boot           : "; if [ $AutoStart = "YES" ];then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]";fi
echo -e -n "Raspberry Optimisation      : "; if [ $Raspi_optimize = "YES" ];then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]";fi
echo -e -n "Node message banner         : "; if [ $Banner = "YES" ];then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]";fi
echo -e -n "Website Frontend            : "; if [ $Website = "YES" ];then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]";fi
echo -e -n "Firewall enable             : "; if [ $Firewall = "YES" ];then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]";fi
echo -e -n "Reboot when finish build    : "; if [ $Reboot = "YES" ];then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]";fi
if [ $Website = "YES" ] && [ ! $Website_port = "80" ]
then
echo -e -n "Html port number $Website_port         : \e[38;5;0166mHidden \e[0m"
fi
sleep 1
echo -e "\n\e[97mSoftware version :\e[0m"
echo -e "------------------"
echo $ident

echo -e "Raspbian Image              : $img_v $LSB"
echo -e "Pivx                        : $pivx_v"
if [ $Bootstrap = "YES" ]
then
bt_version="`curl -s http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap_v.txt | awk 'NR==1 {print$3;exit}'`"
bt_parts="`curl -s http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap_v.txt | awk 'NR==2 {print$2; exit}'`"
echo -e "Boostrap.dat                : $bt_version >> $bt_parts parts "
fi
if [ $Bootstrap = "YES" ] && ! [ -f .pass ]
then
if [ $SOC -le 37 ]
then
echo ""
echo "Due to bootstrap file size increase a lot last month"
echo "Your sdcard is now too small to keep source code."
echo "Option KeepSourceAfterInstall was automaticaly set to NO"
echo "Use a bigger scdard to keep sourcefiles on card after compilation"
echo ""
fi
fi

if ps -ef | grep -v grep | grep pixd >/dev/null
then
echo -e "\n\e[38;5;166mpivx daemon is working => shutdown and will restart after install...\e[0m"
pivxd stop | true
sudo /etc/init.d/cron stop
sudo killall -9 pivxd | true
Dw=1
sudo /etc/init.d/cron stop 2>/dev/null || true
if [ "`systemctl is-active watchdog.service`" = "active" ]
then
echo -e "\n\e[93mStopping pivxd watchdog :\e[0m"
sudo systemctl stop watchdog >/dev/null
echo -e "Done."
fi
fi
sleep 5

function prereq_ {
echo -e "\n\e[95mSystem Check :\e[0m"
update_me=0
ntp_i=""
pv_i=""
gcc_i=""
xz_i=""
lrzip_i=""
pwgen_i=""
xz_i=""
echo -e -n "Check PV installed          : "
if ! [ -x "$(command -v pv)" ];then echo -e "[\e[91m NO \e[0m]" && pv_i="pv" && update_me=1;else echo -e "[\e[92m OK \e[0m]";fi
echo -e -n "Check NTP installed         : "
if ! [ -x "$(command -v ntpd)" ];then echo -e "[\e[91m NO \e[0m]" && ntp_i="ntp" && update_me=1;else echo -e "[\e[92m OK \e[0m]";fi
echo -e -n "Check LRZIP installed       : "
if ! [ -x "$(command -v lrzip)" ];then echo -e "[\e[91m NO \e[0m]" && lrzip_i="lrzip libbz2-dev liblzma-dev libzip-dev zlib1g-dev" && update_me=1;else echo -e "[\e[92m OK \e[0m]";fi
echo -e -n "Check PWGEN installed       : "
if ! [ -x "$(command -v pwgen)" ];then echo -e "[\e[91m NO \e[0m]" && pwgen_i="pwgen" && update_me=1;else echo -e "[\e[92m OK \e[0m]";fi
if ! [ -x "$(command -v htop)" ];then htop_i="htop" && update_me=1;fi

if [ $update_me = 1 ]
then
echo -e "\n\e[95mRaspberry update :\e[0m"
sudo apt-get update
sudo apt-get install aptitude -y
sudo apt install pv python-dev build-essential htop $ntp_i $pwgen_i $lrzip_i -y
sudo sed -i -e "s/# set const/set const/g" /etc/nanorc
fi
}

function Download_Expand_ {
echo -e "\n\e[95mDownload / Expand pivx $pivx_v:\e[0m"
if ! [ -d $MyDir/pivx-3.2.2 ]
then
	wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/pivx-3.2.2-arm-linux.tar.xz
	tar xfJ pivx-3.2.2-arm-linux.tar.xz --checkpoint=.100
fi
echo -e "Done."
}

function Build_Dependencies_ {
echo -e "\n\e[95mInstalling binaries :\e[0m"
cd pivx-3.2.2
sudo cp -v bin/* /usr/local/bin
cd ..
echo -e "\n\e[93mAll binaries were installed...\e[0m"
}

function Build_pivx_ {
if  ps -ef | grep -v grep | grep pivxd >/dev/null
then
sudo bash -c 'sudo /etc/init.d/cron stop'
killall -9 pivxd
fi
}

function conf_ {
if ! [ -f /home/$MyUser/.pivx/pivx.conf ]
then
echo -e "\n\e[95mInstall pivx.conf\e[0m"
if ! [ -d /home/$MyUser/.pivx/ ]; then mkdir /home/$MyUser/.pivx/ ; fi

touch /home/$MyUser/.pivx/pivx.conf
cat <<'EOF'>> /home/$MyUser/.pivx/pivx.conf
#Daemon and listen ON/OFF
daemon=1
listen=1
staking=1
maxconnections=30

#Connection User and Password
rpcuser=user
rpcpassword=password

#Authorized IPs
rpcallowip=127.0.0.1
rpcport=drpc_port
port=dudp_port

#write the location for this blockchain below if not on standard directory
#datadir=/home/USER/.pivx

#Add extra Nodes
addnode=wareck.dyndns.org
addnode=78.251.112.84
addnode=46.10.82.189
addnode=192.168.1.11
addnode=192.168.1.200
EOF
rpcu=$(pwgen -ncsB 12 1)
rpcp=$(pwgen -ncsB 12 1)
sed -i -e "s/rpcuser=user/rpcuser=$rpcu/g" /home/$MyUser/.pivx/pivx.conf
sed -i -e "s/rpcpassword=password/rpcpassword=$rpcp/g" /home/$MyUser/.pivx/pivx.conf
sed -i -e "s/drpc_port/$drpc_port/g" /home/$MyUser/.pivx/pivx.conf
sed -i -e "s/dudp_port/$dudp_port/g" /home/$MyUser/.pivx/pivx.conf

else
echo -e "File pivx.conf already setup."
fi
}

function Bootstrap_ {
badsum=0
echo -e "\n\e[95mDownload Bootstrap $bt_version:\e[0m"
cd /home/$MyUser
if [ $bt_parts -ge 1 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap.part1 |true ;fi
if [ $bt_parts -ge 2 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap.part2 |true ;fi
if [ $bt_parts -ge 3 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap.part3 |true ;fi
if [ $bt_parts -ge 4 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap.part4 |true ;fi
if [ $bt_parts -ge 5 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap.part5 |true ;fi
if [ $bt_parts -ge 6 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap.part6 |true ;fi
if [ $bt_parts -ge 7 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap.part7 |true ;fi
if [ $bt_parts -ge 8 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap.part8 |true ;fi
if [ $bt_parts -ge 9 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap.part9 |true ;fi
if [ $bt_parts -ge 10 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap.part10 |true ;fi
if [ $bt_parts -ge 1 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap1.md5 |true ;fi
if [ $bt_parts -ge 2 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap2.md5 |true ;fi
if [ $bt_parts -ge 3 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap3.md5 |true ;fi
if [ $bt_parts -ge 4 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap4.md5 |true ;fi
if [ $bt_parts -ge 5 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap5.md5 |true ;fi
if [ $bt_parts -ge 6 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap6.md5 |true ;fi
if [ $bt_parts -ge 7 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap7.md5 |true ;fi
if [ $bt_parts -ge 8 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap8.md5 |true ;fi
if [ $bt_parts -ge 9 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap9.md5 |true ;fi
if [ $bt_parts -ge 10 ]; then wget -c -q --show-progress http://wareck.free.fr/crypto/pivx/bootstrap/bootstrap10.md5 |true ;fi
echo -e "Done."

echo -e "\n\e[95mBootstrap checksum test:\e[0m"

if [ -f bootstrap.part1 ];then echo -e -n "Bootstrap.part1 md5sum Test: " && if md5sum --status -c bootstrap1.md5; then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]" && badsum=1 ;fi ;fi
if [ -f bootstrap.part2 ];then echo -e -n "Bootstrap.part2 md5sum Test: " && if md5sum --status -c bootstrap2.md5; then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]" && badsum=1 ;fi ;fi
if [ -f bootstrap.part3 ];then echo -e -n "Bootstrap.part3 md5sum Test: " && if md5sum --status -c bootstrap3.md5; then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]" && badsum=1 ;fi ;fi
if [ -f bootstrap.part4 ];then echo -e -n "Bootstrap.part4 md5sum Test: " && if md5sum --status -c bootstrap4.md5; then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]" && badsum=1 ;fi ;fi
if [ -f bootstrap.part5 ];then echo -e -n "Bootstrap.part5 md5sum Test: " && if md5sum --status -c bootstrap5.md5; then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]" && badsum=1 ;fi ;fi
if [ -f bootstrap.part6 ];then echo -e -n "Bootstrap.part6 md5sum Test: " && if md5sum --status -c bootstrap6.md5; then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]" && badsum=1 ;fi ;fi
if [ -f bootstrap.part7 ];then echo -e -n "Bootstrap.part7 md5sum Test: " && if md5sum --status -c bootstrap7.md5; then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]" && badsum=1 ;fi ;fi
if [ -f bootstrap.part8 ];then echo -e -n "Bootstrap.part8 md5sum Test: " && if md5sum --status -c bootstrap8.md5; then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]" && badsum=1 ;fi ;fi
if [ -f bootstrap.part9 ];then echo -e -n "Bootstrap.part9 md5sum Test: " && if md5sum --status -c bootstrap9.md5; then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]" && badsum=1 ;fi ;fi
if [ -f bootstrap.part10 ];then echo -e -n "Bootstrap.part10 md5sum Test: " && if md5sum --status -c bootstrap10.md5; then echo -e "[\e[92m OK \e[0m]"; else echo -e "[\e[91m NO \e[0m]" && badsum=1 ;fi ;fi


if [ $badsum = "1" ]
then
echo -e "\e[38;5;166mBootstrap.part error !\e[0m"
echo -e "\e[38;5;166mMaybe file damaged or not fully download\e[0m"
echo -e "\e[38;5;166mRemove bad file and try again !\e[0m"
exit
fi

echo -e "\n\e[95mJoin bootstrap.tar.gz.lrz :\e[0m"
cat bootstrap.part* >bootstrap.tar.gz.lrz
rm bootstrap.part*
rm bootstrap*.md5
echo -e "Done."

echo -e "\n\e[95mExpand bootstrap.tar.gz.lrz:\e[0m"
lrzip -d -D bootstrap.tar.gz.lrz
tar xvfz bootstrap.tar.gz
rm bootstrap.tar.gz
echo -e "Done."
}

function clean_after_install_ {
echo -e "\n\e[95mCleaning folders :\e[0m"
cd $MyDir
rm pivx-3.3.2 || true
if [ -f /home/$MyUser/bootstrap.zip ]; then rm /home/$MyUser/bootstrap.zip || true; fi
echo "Done."
}

function install_website_ {
echo -e "\n\e[95mWebsite Frontend installation:\e[0m"
OSV=$(sed 's/\..*//' /etc/debian_version)
case $OSV in
8)
sudo apt-get install apache2 php5 php5-xmlrpc curl php5-curl -y;;
9)
sudo apt-get install apache2 php7.0 php7.0-xmlrpc curl php7.0-curl -y ;;
*)
echo -e "\e[38;5;166mUnknown system, please use Raspberry Stretch or Jessie image...\e[0m"
exit 0
;;
esac
cd /var/www/
if ! [ -f /var/www/node_status/php/config.php ]
then
        sudo bash -c 'git clone https://csa402@bitbucket.org/csa402/pivx-node-frontend.git node_status'
        sudo bash -c 'sudo cp /var/www/node_status/php/config.sample.php /var/www/node_status/php/config.php'
	param1=`cat /home/pi/.pivx/pivx.conf  | grep "rpcuser=" | awk -F "=" '{print$2}'`
	param2=`cat /home/pi/.pivx/pivx.conf  | grep "rpcpassword=" | awk -F "=" '{print$2}'`
	cat /var/www/node_status/php/config.php >>/tmp/config.php
	sed -i -e "s/rpcuser/$param1/g" /tmp/config.php
	sed -i -e "s/rpcpass/$param2/g" /tmp/config.php
	sed -i -e "s/myport/$drpc_port/g" /tmp/config.php
	sudo bash -c 'sudo mv /tmp/config.php /var/www/node_status/php/config.php'

	if [ ! -f /etc/apache2/apache2.conf.old ]
	then
        sudo bash -c 'sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.old'
	fi
  	if [ ! -f /etc/apache2/sites-enabled/000-default.conf.old ]
        then
        sudo bash -c 'sudo cp /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf.old'
        sudo bash -c 'sudo rm /etc/apache2/sites-enabled/000-default.conf'
	fi
	if [ ! -f /etc/apache2/sites-enabled/001-node_status.conf ]
	then
	cat <<'EOF'>> /tmp/001-node_status.conf
Listen 80
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/node_status
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
	sed -i -e "s/80/$Website_port/g" /tmp/001-node_status.conf
	sudo cp /tmp/001-node_status.conf /etc/apache2/sites-enabled/001-node_status.conf
	fi
	cd /home/$MyUser
fi

if  ! grep "curl -Ssk http://127.0.0.1/stats.php" /etc/crontab >/dev/null
then
sudo bash -c 'echo "" > /dev/null >>/etc/crontab | sudo -s'
sudo bash -c 'echo "#pivx frontend website" > /dev/null >>/etc/crontab | sudo -s'
sudo bash -c 'form=$(cat "/tmp/tmp_user") && echo "*/5 *  *   *   *  $form curl -Ssk http://127.0.0.1/stats.php > /dev/null" >>/etc/crontab | sudo -s'
sudo bash -c 'form=$(cat "/tmp/tmp_user") && echo "*/5 *  *   *   *  $form curl -Ssk http://127.0.0.1/peercount.php > /dev/null" >>/etc/crontab | sudo -s'
fi
sudo /etc/init.d/apache2 restart
echo -e "Done."
}

function Raspberry-optimisation_ {
echo -e "\n\e[95mRaspberry optimisation : \e[97mKernel Update \e[0m"
sudo SKIP_WARNING=1 rpi-update

echo -e "\n\e[95mRaspberry optimisation : \e[97mWatchDog and Autostart :\e[0m"
sudo apt-get install watchdog chkconfig -y
sudo chkconfig watchdog on
sudo /etc/init.d/watchdog start
sudo update-rc.d watchdog enable

if ! [ -f /home/$MyUser/scripts/watchdog_pivx.sh ]
then
mkdir /home/$MyUser/scripts |true
cat <<'EOF'>> /home/$MyUser/scripts/watchdog_pivx.sh
#!/bin/bash
if ps -ef | grep -v grep | grep pivxd >/dev/null
then
exit 0
else
pivxd --printtoconsole
exit 0
fi
EOF
fi
chmod +x /home/$MyUser/scripts/watchdog_pivx.sh

echo -e "\n\e[95mRaspberry optimisation : \e[97mEnabling/tunning Watchdog:\e[0m"
sudo bash -c 'sed -i -e "s/#watchdog-device/watchdog-device/g" /etc/watchdog.conf'
sudo bash -c 'sed -i -e "s/#interval             = 1/interval            = 4/g" /etc/watchdog.conf'
sudo bash -c 'sed -i -e "s/#max-load-1              = 24/max-load-1              = 24/g" /etc/watchdog.conf'
sudo bash -c 'sed -i -e "s/#max-load-5              = 18/watchdog-timeout = 15/g" /etc/watchdog.conf'
sudo bash -c 'sed -i -e "s/#RuntimeWatchdogSec=0/RuntimeWatchdogSec=14/g" /etc/systemd/system.conf'
if ! [ -f /etc/modprobe.d/bcm2835_wdt.conf ]
then
sudo bash -c 'touch /etc/modprobe.d/bcm2835_wdt.conf'
sudo bash -c 'echo "alias char-major-10-130 bcm2835_wdt" /etc/modprobe.d/bcm2835_wdt.conf'
sudo bash -c 'echo "alias char-major-10-131 bcm2835_wdt" /etc/modprobe.d/bcm2835_wdt.conf'
sudo bash -c 'echo "bcm2835_wdt" >>/etc/modules'
fi
echo -e "Done."

echo -e "\n\e[95mRaspberry optimisation : \e[97mWatchdog.sh & crontab :\e[0m"
if  ! grep "watchdog_pivx.sh" /etc/crontab >/dev/null
then
sudo bash -c 'echo "" >>/etc/crontab | sudo -s'
sudo bash -c 'echo "#pivx watchdog" >>/etc/crontab | sudo -s'
sudo bash -c 'form=$(cat "/tmp/tmp_user") && echo "*/15  * * * * $form /home/$form/scripts/watchdog_pivx.sh" >>/etc/crontab'
fi
echo "Done."

echo -e "\n\e[95mRaspberry optimisation : \e[97mDisable Blueutooth \e[0m"
if ! grep "dtoverlay=pi3-disable-bt" /boot/config.txt >/dev/null
then
sudo bash -c 'echo "" >>/boot/config.txt'
sudo bash -c 'echo "# Disable internal BT" >>/boot/config.txt'
sudo bash -c 'echo "dtoverlay=pi3-disable-bt" >>/boot/config.txt'
sudo systemctl disable hciuart >/dev/null
sleep 1
fi
echo -e "Done."

echo -e "\n\e[95mRaspberry optimisation : \e[97mDisable Audio \e[0m"
if grep "dtparam=audio=on" /boot/config.txt >/dev/null
then
sudo bash -c 'sed -i -e "s/dtparam=audio=on/dtparam=audio=off/g" /boot/config.txt'
fi
echo -e "Done."

echo -e "\n\e[95mRaspberry optimisation : \e[97mDisable Console blank \e[0m"
if ! grep "consoleblank=0" /boot/cmdline.txt >/dev/null
then
sudo bash -c 'sed -i -e "s/rootwait/rootwait consoleblank=0/g" /boot/cmdline.txt'
fi
echo -e "Done."

echo -e "\n\e[95mRaspberry optimisation : \e[97mEnable Swap \e[0m"
sudo apt-get install dphys-swapfile -y
sudo bash -c 'sed -i -e "s/CONF_SWAPSIZE=100/CONF_SWAPSIZE=1024/g" /etc/dphys-swapfile'
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
echo -e "Done."

}

function auto_start_ {
echo -e "\n\e[95mpivx autostart : rc.local\e[0m"
if ! grep "pivxd" /etc/rc.local >/dev/null
then

sudo bash -c 'sed -i -e "s/exit 0//g" /etc/rc.local'
sudo bash -c 'echo "#pivx Node start" >>/etc/rc.local'
sudo bash -c 'form=$(cat "/tmp/tmp_user") && echo -e "su - $form -c \x27pivxd --printtoconsole\x27" >>/etc/rc.local'
sudo bash -c 'echo "exit 0" >>/etc/rc.local'
fi
echo -e "Done."
}

function banner_ {
echo -e "\n\e[95mInstall message banner :\e[0m"
ident=`cat /proc/device-tree/model | mawk '{print $1" "$2" "$3""$5" v"$7}'`
echo $ident
if [ -f /tmp/motd ]; then rm /tmp/motd ;fi
cat <<EOF>> /tmp/motd
 _____       _
|   | |___ _| |___
| | | | . | . | -_|
|_|___|___|___|___|

 pivx node v$Version
 $ident

EOF
sudo bash -c 'mv /tmp/motd /etc/motd | sudo -s'
if  grep "raspberrypi" /etc/hostname >/dev/null;then sudo sed -i -e "s/raspberrypi/Node/g" /etc/hostname ;fi
if  grep "raspberrypi" /etc/hosts >/dev/null;then sudo sed -i -e "s/raspberrypi/Node/g" /etc/hosts;fi
echo -e "Done."
}

function Firewall_ {
echo -e "\n\e[95mFirewall setup :\e[0m"
sudo apt-get -y install ufw libapache2-mod-security2
if [ $Website = "YES" ]
then
echo "Hidding Apache Server Name"
sudo sed -i -e "s/ServerTokens OS//g" /etc/apache2/conf-enabled/security.conf
sudo sed -i -e "s/ServerTokens Full//g" /etc/apache2/conf-enabled/security.conf
if ! grep "ServerTokens Full" /etc/apache2/conf-enabled/security.conf >/dev/null
then
sudo bash -c 'echo "ServerTokens Full" >>/etc/apache2/conf-enabled/security.conf'
fi
if ! grep "SecServerSignature cheyenne/2.2.6" /etc/apache2/conf-enabled/security.conf >/dev/null
then
sudo bash -c 'echo "SecServerSignature cheyenne/2.2.6" >>/etc/apache2/conf-enabled/security.conf'
fi
fi
if [ -f /tmp/ufw ]; then sudo rm /tmp/ufw ;fi
sudo cp /etc/default/ufw /tmp/ufw
sudo chown $USER /tmp/ufw
#sudo sed -i '/IPV6=/d' /tmp/ufw
#sudo echo "IPV6=no" >> /tmp/ufw
sudo chmod 644 /tmp/ufw
sudo chown root:root /tmp/ufw
sudo cp /tmp/ufw /etc/default/ufw
echo -e "\e[33mOpening up Port 22 TCP for SSH:\e[0m"
sudo ufw allow 22/tcp
echo -e "\e[33mOpening up Port $drpc_port/$dudp_port for pivx daemon:\e[0m"
sudo ufw allow $drpc_port,$dudp_port/tcp
if [ $Website = "YES" ]
then
echo -e "\e[33mOpening up Port $Website_port for website frontpage:\e[0m"
sudo ufw allow $Website_port/tcp
fi
echo -e ""
sudo ufw status verbose
sudo ufw --force enable
echo -e "Done."
}


############
# Main loop#
############
if ! [ -f .pass ]
then
prereq_
Download_Expand_
Build_Dependencies_
else
echo -e "\nDependencies were already builded..."
echo -e "Remove file \x22.pass\x22 to restart build..."
sleep 5
fi
if ! [[ -x "$(command -v pv)" || -x "$(command -v ntpd)" || -x "$(command -v lrzip)" || -x "$(command -v pwgen)" || -x "$(command -v htop)" ]]
then
prereq_
fi
sudo ldconfig
Build_pivx_
conf_

if [ $Website = "YES" ];then install_website_ ;fi
if [ $KeepSourceAfterInstall = "NO" ]; then clean_after_install_;fi
if [ $Raspi_optimize = "YES" ]
then
Raspberry-optimisation_
sudo /etc/init.d/cron stop #add this to prevent accidental restart during bootstrap download process
fi

if [ $Bootstrap = "YES" ] ; then Bootstrap_ ;fi
if [ $AutoStart = "YES" ]; then auto_start_ ;fi
if [ $Firewall = "YES" ] ; then Firewall_ ;fi
if [ $Banner = "YES" ] ; then banner_ ;fi
echo -e "\n\e[97mBuild is finished !!!\e[0m"

if [ $Raspi_optimize = "YES" ];then echo -e "\e[92mRaspberry was optimized : need to reboot ...\e[0m";fi
if [ $Website = "YES" ]
then
echo -e "\e[92mDon't forget to edit your /var/www/node_status/php/config.php file ...\e[0m"
if [ ! $Website_port = "80" ]
then
_IP=$(hostname -I) || true
echo -e "\e[92mHtml frontend hidden use http://${_IP::-1}:$Website_port to check the webpage \e[0m"
fi
fi

echo -e "\nwareck@gmail.com"
echo -e "Donate:"
echo -e "Bitcoin: 16F8V2EnHCNPVQwTGLifGHCE12XTnWPG8G"
echo -e "OKcash:  PQdBdd7E7r1n4Bi492zqNdB2HrnaonmrkF"
echo -e ""
if [ $Dw = 1 ]
then
pivxd
sudo bash -c 'sudo /etc/init.d/cron restart'
fi

if [ $Raspi_optimize = "YES" ]
then
	if [ $Reboot = "YES" ]
	then
	echo -e "Reboot in 10 seconds (CRTL+C to abord):"
	for i in {10..1}
	do
	echo -e -n "$i "
	sleep 1
	done
	echo ""
	sudo reboot
fi
else
	sleep 5
fi
