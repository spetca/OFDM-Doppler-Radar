function runOFDMradarTx(ofdmRadarTransmitter)
coder.extrinsic('uicontrol')
 coder.extrinsic('waitforbuttonpress')
 coder.extrinsic('tcpip')
persistent  radio

if isempty(radio)
%setup usrp
radio = comm.SDRuTransmitter(...
'Platform',ofdmRadarTransmitter.Platform, ...
'SerialNum', ofdmRadarTransmitter.SeralNum, ...
'ChannelMapping',ofdmRadarTransmitter.Chan, ... 
'CenterFrequency',ofdmRadarTransmitter.CenterFrequency, ...
'Gain', ofdmRadarTransmitter.GAIN_TX, ...
'ClockSource', 'External', ...
'TransportDataType', ofdmRadarTransmitter.TransportDataType,...
'EnableBurstMode',ofdmRadarTransmitter.EnableBurst,...
'NumFramesInBurst',ofdmRadarTransmitter.FramesPerBurst,...
'MasterClockRate',ofdmRadarTransmitter.MClock,...
'InterpolationFactor',ofdmRadarTransmitter.MClock/ofdmRadarTransmitter.BW);
%'NumFramesBurst',ofdmRadarTransmitter.FramesPerBurst,...
%'NumFramesInBurst',ofdmRadarTransmitter.FramesPerBurst,...

end
currentTime = 0; 
a = zeros(400,1);
modZero = complex(a,0);
next = 0;
framesDropped = 0; 
Transmitting_Now = 1
tx2tx = repmat(ofdmRadarTransmitter.txall,[1,85]);
ofdmRadarTransmitter.FrameTime = length(tx2tx)/.5e7;

%Transmission Process
while currentTime < ofdmRadarTransmitter.StopTime
    for counter = 1:(ofdmRadarTransmitter.FramesPerBurst) 
            uf = radio(tx2tx.');
            if (uf)
    
                framesDropped = framesDropped + 1; 
            end
      
    end
   
    currentTime=currentTime+ofdmRadarTransmitter.FrameTime*ofdmRadarTransmitter.FramesPerBurst;
end
Symbols_Dropped = framesDropped
release(radio)
end