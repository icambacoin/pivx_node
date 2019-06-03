## Real Time Clock addon : ##
The RTC (real time clock) addon give best performance to your okcash daemon.

If you let the system running with Okcsh daemon, after a while, raspberry internal clock drift.

If your internal clock is too far from real clock, you will have this kind of error : "time stamp too far from reference clock" and RPI stop staking.

I tried to use NTPd to adjust internal clock but still have some issue (internal clock stop during update, so after udpate you will have more or less 1 second error which slowly drift)

So the best is to use a small electronic addon (5$) for givin raspberry a RTC (based on chip DS1307)

![](https://raw.githubusercontent.com/wareck/okcash_build/master/doc/images/rtc.png)![](https://raw.githubusercontent.com/wareck/okcash_build/master/doc/images/rtc_rpi.png)

How to install (software side) :
Script will install libraries, enable i2c connections.

    ./rtc.sh
    sudo reboot

After reboot, start again script (rtc init and synchronize):

    ./rtc.sh

Now internal clock and RTC clock were syncronized, and your RPI clock will never drift...
