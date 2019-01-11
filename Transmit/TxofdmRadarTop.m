close all
%setup usrp
ofdmRadarTransmitter.Platform = 'B210';
ofdmRadarTransmitter.SeralNum = '30D0D28';
ofdmRadarTransmitter.CenterFrequency = 5.89e9
ofdmRadarTransmitter.GAIN_TX = 85;
ofdmRadarTransmitter.EnableBurst = false;
ofdmRadarTransmitter.StopTime = 300
ofdmRadarTransmitter.TransportDataType = 'int8';
ofdmRadarTransmitter.FramesPerBurst = 1760;
ofdmRadarTransmitter.MClock = .5e7;
ofdmRadarTransmitter.BW =.5e7;
ofdmRadarTransmitter.N = 64;
ofdmRadarTransmitter.cycPre = 16;
ofdmRadarTransmitter.Chan = 2;

%802.11p preamble  data
ofdmRadarTransmitter.sw1 = sqrt(13/6)*[zeros(1,6) 0, 0, 1+j, 0, 0, 0, -1-j, 0, 0, 0, 1+j, 0, 0, 0, -1-j, 0, 0, 0, -1-j, 0, 0, 0, 1+j, 0, 0, 0, 0, 0,0, 0, -1-j, 0, 0, 0, -1-j, 0, 0, 0, 1+j, 0, 0, 0, 1+j, 0, 0, 0, 1+j, 0, 0, 0, 1+j, 0, 0 zeros(1,5)];
ofdmRadarTransmitter.sw2 = [zeros(1,6) 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 0, 1, -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, -1, -1, 1, 1, -1, -1, 1, -1, 1, -1, 1, 1, 1, 1 zeros(1,5)];
ofdmRadarTransmitter.inputiFFT = [0,0,0,0,0,0,1,-1,-1,-1,1,-1,1,1,1,1,-1,1,-1,1,-1,-1,1,1,-1,1,-1,-1,1,1,-1,1,0,1,-1,-1,1,-1,-1,1,1,1,1,1,-1,-1,1,-1,-1,1,-1,1,1,1,-1,1,1,1,1,0,0,0,0,0];%[zeros(1,6), 2*randi([0,1],1,26)-1, 0, 2*randi([0,1],1,26)-1, zeros(1,5)];
ofdmRadarTransmitter.mul_scl=10;

%create first syncword
ofdmRadarTransmitter.pre1      = ifft(ofdmRadarTransmitter.sw1,ofdmRadarTransmitter.N);
ofdmRadarTransmitter.syncword1 = [ofdmRadarTransmitter.pre1(33:64) ofdmRadarTransmitter.pre1 ofdmRadarTransmitter.pre1];
ofdmRadarTransmitter.sw1_scl   = ofdmRadarTransmitter.syncword1./( ofdmRadarTransmitter.syncword1*ofdmRadarTransmitter.syncword1') * ofdmRadarTransmitter.mul_scl;


%create second sycnword
ofdmRadarTransmitter.pre2      = ifft(ofdmRadarTransmitter.sw2,ofdmRadarTransmitter.N);
ofdmRadarTransmitter.syncword2 =[ofdmRadarTransmitter.pre2(33:64) ofdmRadarTransmitter.pre2 ofdmRadarTransmitter.pre2.*.65];
ofdmRadarTransmitter.sw2_scl   = ofdmRadarTransmitter.syncword2./( ofdmRadarTransmitter.syncword2*ofdmRadarTransmitter.syncword2') * (ofdmRadarTransmitter.mul_scl-2);


%create data to send
qpsk1= [-1+1i,-1+1i,1+1i,1-1i,-1+1i,-1-1i,-1+1i,1-1i,-1+1i,-1-1i,1-1i,-1+1i,-1+1i,-1-1i,-1+1i,-1+1i,1-1i,1-1i,1-1i,-1-1i,-1+1i,-1+1i,1+1i,-1+1i,-1+1i,-1-1i];
qpsk2 = [1-1i,1-1i,-1+1i,1-1i,1+1i,1+1i,1-1i,1-1i,-1-1i,-1-1i,-1-1i,-1+1i,1-1i,-1-1i,-1+1i,-1-1i,-1+1i,-1+1i,-1-1i,1+1i,-1-1i,-1-1i,1+1i,1+1i,-1+1i,-1-1i];
ofdmRadarTransmitter.inputiFFT = [zeros(1,6), qpsk1, 0, qpsk2, zeros(1,5)];
%ofdmRadarTransmitter.inputiFFT(1:2:end) = eps; 
ofdmRadarTransmitter.outputiFFT         = ifft(ofdmRadarTransmitter.inputiFFT,ofdmRadarTransmitter.N);
ofdmRadarTransmitter.outputiFFT_with_CP = [ofdmRadarTransmitter.outputiFFT(49:64) ofdmRadarTransmitter.outputiFFT];
ofdmRadarTransmitter.out_scl            = ofdmRadarTransmitter.outputiFFT_with_CP./( ofdmRadarTransmitter.outputiFFT_with_CP*ofdmRadarTransmitter.outputiFFT_with_CP') * (ofdmRadarTransmitter.mul_scl-5);

ofdmRadarTransmitter.txall = [ofdmRadarTransmitter.sw1_scl ofdmRadarTransmitter.sw2_scl ofdmRadarTransmitter.out_scl complex(zeros(1,4000))];

ofdmRadarTransmitter.FrameTime = ofdmRadarTransmitter.FramesPerBurst*(length(ofdmRadarTransmitter.txall)/.5e7);
tx2tx = repmat(ofdmRadarTransmitter.txall,[1,85]);

figure
plot(real(ofdmRadarTransmitter.txall))
hold on
plot(imag(ofdmRadarTransmitter.txall))
hold off

compileIt  = true; % true if code is to be compiled for accelerated execution
useCodegen = true; % true to run the latest generated mex fi

if compileIt
    codegen('TxrunOFDMradar', '-args', {coder.Constant(ofdmRadarTransmitter)}); %#ok<UNRCH>
end

if useCodegen
   clear TxrunOFDMradar_mex %#ok<UNRCH>
   TxrunOFDMradar_mex(ofdmRadarTransmitter);
else
    hello = 1
   runOFDMradar(ofdmRadarTransmitter);
end



