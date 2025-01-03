# OFDM Based Doppler Radar 

This project is the code complimenting this [paper](https://ieeexplore.ieee.org/abstract/document/8705219): 

it requires MATLAB, the MATLAB USRP communications toolbox, and 2 USRPs 

Photos of the application running: 

## Car driving away from radar
![alt text](https://github.com/spetca/OFDM-Doppler-Radar/blob/master/imgs/img1.png)

## Car driving towards radar
![alt text](https://github.com/spetca/OFDM-Doppler-Radar/blob/master/imgs/img2.png)

## To Run [ON LINUX]:

1. Clone repository to local machine

2. open two separate terminal sessions

3. In each start matlab

4. In 1 instance of matlab open runOFDMradarRx.m - This script compiles and runs:
	-  runOFDMradarRx.m
	-  velocity1B.m

5. In a 2nd instance of matlab open TxofdmRadarTop.m - This script compiles and runs:
	-  TxrunOFDMradar.m

6. Connect 2 USRPs to USB ports:
	- ensure  USRP platform is configured in TxrunOFDMradar.m &  runOFDMradarRx.m
   		ofdmRadarReceiver.Platform='B210';
		ofdmRadarTransmitter.Platform = 'B210';

	- make sure serial number is configured in TxrunOFDMradar.m &  runOFDMradarRx.m
		ofdmRadarReceiver.SeralNum='30D0D3E';
		ofdmRadarTransmitter.SeralNum = '30D0D28';

	- make sure you are transmitting/receiving on expected port / antennas are wired correctly. 
	- Set ChannelMapping appropriately in runOFDMradarRx & TxrunOFDMradar:
			'ChannelMapping', 1, ...


7. Hit run on each matlab session (each will take a while to compile an begin upwards of 45s - 1 minute)

8. runOFDMradarRx.m should display a plot once it starts receiving transmitted OFDM symbols
