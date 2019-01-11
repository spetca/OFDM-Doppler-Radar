close all
ofdmRadarReceiver.Platform='B210';
ofdmRadarReceiver.SeralNum='30D0D3E';
ofdmRadarReceiver.CenterFrequency=5.89e9;
ofdmRadarReceiver.GAIN_RX =60;
ofdmRadarReceiver.EnableBurst=true;
ofdmRadarReceiver.MClock = .5e7;
ofdmRadarReceiver.BW = .5e7;
ofdmRadarReceiver.StopTime = 200;
ofdmRadarReceiver.TransportDataType = 'int16';
ofdmRadarReceiver.OutputDataType = 'double';
ofdmRadarReceiver.SamplesPerFrame = 640;
ofdmRadarReceiver.Chan = 2; 
ofdmRadarReceiver.Hfill = 32; 
ofdmRadarReceiver.numFramesPerBurst = ofdmRadarReceiver.Hfill*8;
ofdmRadarReceiver.DataSpacing = 4000; %get from TX file
ofdmRadarReceiver.FrameTime= (1/ofdmRadarReceiver.BW)*ofdmRadarReceiver.SamplesPerFrame*ofdmRadarReceiver.numFramesPerBurst;
ofdmRadarReceiver.Plots = true; 
compileIt = true;  % true if code is to be compiled
useCodegen = true; % true to run the generated mex file

if compileIt
    codegen('runOFDMradarRx', '-args', {coder.Constant(ofdmRadarReceiver)});
end
if useCodegen
   clear runOFDMradarRx_mex %#ok<UNRCH>
   runOFDMradarRx_mex(ofdmRadarReceiver);
else
  runOFDMradarRx(ofdmRadarReceiver);
end