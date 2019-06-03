![](https://raw.githubusercontent.com/wareck/pivx_node/master/doc/images/logo.png)

# Script for build a solid pivx Node (Raspberry Pi2 & Pi3) ##

----------
This script build "Pivx headless daemon node" (okcashd command line only, for best efficiency) .

I suggest to use Pi2 or Pi3 otherwise, it will take to much time to synchronise and never staking ...

You can use Raspbian Jessie or Strecth (lite or full, better is to use lite version for efficiency/speed).

----------
## Raspberry pre-build ##

Donwload **Raspbian Stretch** or **Raspbian Jessie** from https://www.raspberrypi.org/

***If you want to use a huge sdcard (minimum 16GB) , just burn image on sdcard and jump to step 3.***

***If you want to use a standard sdcard + usb key: (best) do all step...***


Step 1 : ***Burn your card and plug it in your raspberry , start it.***

When logged into Raspberry start by an update upgrade :

    sudo apt-get update
    sudo apt-get upgrade
  
Then add essentials tools for starting :

    sudo apt-get install  build-essential git
 
 Now configure your Raspberry :

    sudo raspi-config

( hostname, password , timezone ) 

Step 2 : ***If you wants to use an USB key*** 

plug you key in your raspberry pi now, (must be formated in VFAT or EXT4), let in plugged during build/installation

Now prepare you raspberry to use usb key as okcash folder :

    mkdir /home/pi/.pivx
    sudo nano /etc/fstab

add this lines to fstab (**for vfat**)

    /dev/sda1 /home/pi/.pivx  vfat uid=pi,gid=pi,umask=0022,sync,auto,nosuid,rw,nouser    0    0
    
then 

    sudo chown pi .pivx
    
add this lines to fstab (**for ext4**)

    /dev/sda1       /home/pi/.pivx        ext4 defaults 0 0

then
    
    sudo chown -R pi .pivx

Step 3 : ***reboot and login again***

    sudo reboot

## Build pivx ##
Launch build scrypt :

	sudo apt-get update
	sudo apt-get install git
	cd /home/pi
	git clone https://github.com/wareck/pivx_node.git 
	cd /home/pi/pivx_node

now you can edit options :

    nano build_node.sh
    
*## Configuration ##*  

#Bootstrap (speedup first start, but requier 2GB free space on sdcard)
Bootstrap=YES # YES or NO => download bootstrap.dat (take long time to start, but better)

#Optimiser Raspberry (give watchdog function and autostart okcash, speedup a little the raspberry)
Raspi_optimize=YES

#Website frontend (give a small web page to check if everything is ok)
Website=YES

#Enable firewall
Firewall=YES

#Enable autostart
AutoStart=YES

#Login banner
Banner=YES
*CleanAfterInstall=YES # YES or NO => remove tarballs after install (keep space)*

*Bootstrap=NO # YES or NO => download bootstrap.dat (take long time to start, but better)*

*DelFolders=NO # YES or NO => delete build files after finish (keep space on sdcard)*

*PatchCheckPoints=YES # YES or NO => this put new checkpoint to allow okcash sync faster at first start*

*Raspi_optimize=YES # YES or NO => install watchdog, autostart , swap and new kernel for speedup a little / better work*

**Save (crtl+x then y)**

Start build:

    ./build_node.sh
	
**It will take 2 or 3 hours to build pivx.**

## Check  ##
You can check if everithing is ok by use this command:

    okcashd --printtoconsole
If you can see this king of screen, okcashd is running ...

![](https://raw.githubusercontent.com/wareck/pivx_node/master/doc/images/running.png)


wareck 
donate Bitcoin :  16F8V2EnHCNPVQwTGLifGHCE12XTnWPG8G / Okcash  :  PQdBdd7E7r1n4Bi492zqNdB2HrnaonmrkF

