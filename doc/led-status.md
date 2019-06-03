## Led status addon :

#### Shematic :
![](https://raw.githubusercontent.com/wareck/okcash_build/master/doc/images/led_status.png)

(you can choose any GPIO, just don't forget to edit led-status.sh file)

#### Software :
If you want to edit options:
```shell
nano led-status.sh
```

then edit options :

**GPIO_PIN=11**     #GPIO Pin number to turn led on and off

**INVERT="NO"**     #If YES => led on when okcash crashed, NO => led on when okcash running


save 

then install addon with:
```shell
./led-status.sh
```
