<h1>Remote Light Controller Using MSP430 Microcontroller</h1>

![Static Badge](https://img.shields.io/badge/Author-Jared%20Carvente-blue)
![Static Badge](https://img.shields.io/badge/Release-December%202024-green)
![Static Badge](https://img.shields.io/badge/IDE-Code%20Composer%20Studio-red)


<h2>Introduction</h2>
<p>This project is intended to control 127 V spotlights remotely using an Android App and a Wi-Fi connection.</p>

<h2>Key points</h2>
<li>Remote control is achieved through the use of AT commands</li>
<li>Wi-Fi communication is handled by an ESP32 module</li>

<h2>To adapt this code just make this small tweak</h2>

<p>Open the <strong><em>msp430g2xx3_ta_19.asm</em></strong> file in the main repository, head over to the line 370 and change this line of code:</p>

`WIFI_CONN           .string "AT+CWJAP=",34,"Micros",34,",",34,"9876543210",34,0x0D,0x0A`

<p>for this new one:</p>

`WIFI_CONN           .string "AT+CWJAP=",34,"YOUR_WIFI_SSID",34,",",34,"YOUR_WIFI_PASSWORD",34,0x0D,0x0A`

<p>Make sure you substitute "YOUR_WIFI_SSID" and "YOUR_WIFI_PASSWORD" for the actual SSID and password of your network.</p>
