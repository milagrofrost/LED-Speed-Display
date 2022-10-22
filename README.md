# LED Speed Display with TURBO!

## Powered by Powershell and C++ 

# What

![Faceplate](https://raw.githubusercontent.com/milagrofrost/LED-Speed-Display/main/pics/The%20product.jpg)
<img src="https://raw.githubusercontent.com/milagrofrost/LED-Speed-Display/main/pics/IRL-wiring.jpg" width="290">
<img src="https://raw.githubusercontent.com/milagrofrost/LED-Speed-Display/main/pics/systray.png" width="200">

This is replicating the gimmicky TURBO button and CPU and displays of the old 486-ish machines of yesteryear.  But this is build is for those who'd like to have the same retro feel and gimmicks for their modern machine!

There are two main components of this build.  An Arduino or ESP32/ESP8266 or similar microcontroller and then your Windows PC.  These two components communicate with each other over serial to gather PC info and displaying it onto a 3 digit 7-segment display.  

Unlike those retro LED displays, this modern display shows 4 PC stats in real-ish time.
- CPU clock speed
- GPU utilization (%)
- Network usage in Mbps
- Memory utilization (%)

On top of that, we can set our PC to TURBO MODE.  Kind of.  Using the latching button on the left, we can switch Power Plans on the Windows machine.  From Balanced power plan to the TURBO power plan.  You'll need to make the TURBO power plan yourself.  Recommended to copy the High Performance power plan and just name it 'TURBO'.

And one more thing, The locking mechanism, in this code, will turn your network on and off. You first must speicfy which network adapter should be disabled/enabled by using the systray icon included in this install and selecting 'Network Adapter' option.

This program is powered by some powershell scripts.  The Windows powershell scripts will run in a couple ways.  One script that handles the microcontroller communication runs as a SYSTEM level service (as admin for power plan management and network disable/enable capabilities).  The windows System service will be managed by the NSSM program (https://nssm.cc/).  The other powershell script is installed as a Scheduled Task that will run when you log in.  This script is a System Tray icon.  It helps you manage a few configuration settings.

# Why

Why not?

# Where

The components needed to replicate my build are as such

* Evercool BOX-MK-SL (or BOX-MK-SL) Internal Storage Box 5.25" 
 - https://www.microcenter.com/product/298576/evercool-box-mk-sl-internal-storage-box-525-drive-bay-insert-silver

* ESP32 D1 Mini ESP-WROOM-32 
 - https://a.co/d/eGtrExP

* MAX7219 0.56″ 3 or 4-Digit 7-Segment Display Board
 - https://protosupplies.com/product/max7219-0-56-3-or-4-digit-7-segment-display-board/
 
* LED 7-Segment 0.56″ CC 3-Digit
 - https://protosupplies.com/product/led-7-segment-0-56-cc-3-digit/?attribute_color=Green

* Metal Pushbutton - Momentary (16mm, Green)
 - https://www.sparkfun.com/products/11968

* Metal Pushbutton - Latching (16mm, Green)
 - https://www.sparkfun.com/products/11973

* Philmore 5/8" On/Off Key Switch Lock 
 - https://a.co/d/fJIEtMo
 
* 10k and 300 Ohm resistors
 - https://a.co/d/4EwxWpH

* Some jumper wires
 - https://a.co/d/0lW7d1C
 
* A couple headers for the LED display board
 - https://a.co/d/fkqCiV5
 
* Heat Shrink tubing
 - https://a.co/d/5dCLtir
 
* Internal USB header adapters so you can plug-in USB inside your machine for your microcontroller
 - https://a.co/d/4qWnlwN (USB 3.0)
 - or
 - https://a.co/d/0eBvKCO (USB 2.0)

* 3D printed faceplate to replace the one for the Evercool box.  
 - https://www.thingiverse.com/thing:5575163/files
 


# How?

Oh boy.  Where to start?

How about hardware?

## Hardware

Grab the components listed above and a soldering iron and a lighter (to light it on fire if it gets to be too much and/or for the heat shrink tubing). 

I've included a wiring diagram for this project in the git repo.  As well as the diagram file that can be opened with Cirkit Designer if you really need to blow stuff up. In the diagram I'm showing a different ESP32 than what I recommended in the parts list, but the GPIO pin numbers are the same between the two.  

Please don't negelct the resistors.  The 10k Ohm resistors for the switches keeps the board from shorting out and the 300 Ohm resistors for the LED wires helps prolong the life of the LED by reducing power to it.  Don't worry, they'll still be bright!  

Also don't neglect the heat shrink tubing.  Cover all solder connections and exposed wires with the tubing.  Shorting the board sucks.  I did once and only once.  

I soldered short pin headers onto the MAX7219 0.56″ 3 or 4-Digit 7-Segment Display Board and used male to female wire jumpers to connect the board to the display. 

Green wires are not used on the two buttons.

Jumper wires can be loose and not make good connections.  

## Software

Download/git this repo and extract/save it to anywhere on your machine.  Downloads folder is fine.  

### Microcontroller

This is fairly easy.  In this guide I'm using the Arduino program to flash the code.  

Open the ino file in the "3-digit-7-seg.c" folder.  Download the 'LEDControl' library (NOT 'LedController').  If you are using an ESP microcontroller, you need to edit the LEDControl library file in order for it to work with the ESP.  Arduinos, you're good to go skip this step.  

Open this file on your Windows machine: YOUR MY DOCUMENTS FOLDER\Arduino\libraries\LedControl\src\LeDControl.h

Replace the line "#include <avr/pgmspace.h>"

with

#if defined(AVR)
#include <avr/pgmspace.h>
#else  //defined(AVR)
#include <pgmspace.h>
#endif  //defined(AVR)

Save that and now you can upload the microcontroller code to your ESP32.  

### Windows

I think and hope and pray that I've made a decent install script for you.  It's worked for me on a couple blank-slate Windows machines.

Before you run the install file, please make sure your ESP/microcontroller is connected to your computer.  You'll be prompted to specify which Serial Device is the Microcontroller that is running the LED Speed Display code.  

You need to open Powershell AS ADMIN in order for the install script to run successfully.  To run Powershell as admin, search for powershell in your Start menu, RIGHT CLICK on it and select 'Run as Adminstrator'.

Next in the Admin Powershell console, navigate/cd to the folder of the install.ps1 file and run this command.  

Powershell.exe -executionpolicy bypass -file .\install.ps1

INFO: This script will install a packagae manager called Chocolatey/Choco.  This is soley used to install NSSM.  Choco is pretty nice I recommend using it for installed all your programs.   

The only thing this script needs from you is to input a number that correlates with the device name of your Microcontreoller. 

After the install script finishes, you'll need to restart.  

And after the restart, the SYSTEM service should be running even before you login and then the system tray icon should be loaded when you login.  

If you want to Utilize the TURBO function you need to make a TURBO power plan, in your energy/power settings. 

If you want to utilize the Network locking/disabling function you need to specify which NEtwork adapter should be disbaled/enabled by right clicking on the LED Speed Display system tray icon and selecting NEtwork Adapter.  There it will have a drop down of adapters that you can choose from.  Choose the one that you use to connect to the internet.  




# Who
I'm just a guy who dabbles in powershell and C++.  Don't hurt me for making bad code.  I'm trying my best here!
