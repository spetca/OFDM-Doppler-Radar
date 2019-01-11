function runOFDMradarRx(ofdmRadarReceiver) %#codegen

persistent radio
coder.extrinsic('pmusic')
coder.extrinsic('rootmusic')
coder.extrinsic('ginput')
coder.extrinsic('num2str')
coder.extrinsic('csvwrite') 
coder.extrinsic('tcpip')
coder.extrinsic('try')
coder.extrinsic('catch')
dumpFlag = 0; 
dumpFlag2 = 0;

if isempty(radio)
    %setup usrp
    radio = comm.SDRuReceiver(...
    'Platform',ofdmRadarReceiver.Platform, ...
    'SerialNum', ofdmRadarReceiver.SeralNum, ...
    'ChannelMapping', 1, ... 
    'CenterFrequency',ofdmRadarReceiver.CenterFrequency, ...
    'Gain', ofdmRadarReceiver.GAIN_RX, ...
    'ClockSource', 'External', ...
    'EnableBurstMode',ofdmRadarReceiver.EnableBurst,...
    'MasterClockRate',ofdmRadarReceiver.MClock,...
    'TransportDataType', ofdmRadarReceiver.TransportDataType,...
    'OutputDataType',ofdmRadarReceiver.OutputDataType,...
    'NumFramesInBurst',ofdmRadarReceiver.numFramesPerBurst,...
    'SamplesPerFrame',ofdmRadarReceiver.SamplesPerFrame,...
    'DecimationFactor',ofdmRadarReceiver.MClock/ofdmRadarReceiver.BW);
end

%FOR OFDM MODEM-------------------
N = 64;
Nactual = 52;  
framesBetween=0;
framesLast=0;
cal = 0; 
firstTime = 0; 
musicRrt = zeros(1,1);
musicRt = zeros(1,1); 
%incoming data
IQ = (complex(zeros(1,ofdmRadarReceiver.SamplesPerFrame)));

%syncword1
sw1 = sqrt(13/6)*[zeros(1,6) 0, 0, 1+j, 0, 0, 0, -1-j, 0, 0, 0, 1+j, 0, 0, 0, -1-j, 0, 0, 0, -1-j, 0, 0, 0, 1+j, 0, ...
                  0, 0, 0, 0,0, 0, -1-j, 0, 0, 0, -1-j, 0, 0, 0, 1+j, 0, 0, 0, 1+j, 0, 0, 0, 1+j, 0, 0, 0, 1+j, 0, 0 zeros(1,5)];
pre1      = ifft(sw1,64);
syncword1 = [pre1(33:64) pre1 pre1];

%syncword2
sw2  = [zeros(1,6) 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 0, 1, -1, -1, ...
        1, 1, -1, 1, -1, 1, -1, -1, -1, -1, -1, 1, 1, -1, -1, 1, -1, 1, -1, 1, 1, 1, 1 zeros(1,5)];
pre2 = ifft(sw2,N);
syncword2 = [pre2(33:64) pre2 pre2]; 

%known transmitted data
%inputiFFT = [0,0,0,0,0,0,1,-1,-1,-1,1,-1,1,1,1,1,-1,1,-1,1,-1,-1,1,1,-1,1,-1,-1,1,1,-1,1,0,1,-1,-1,1,-1,-1,1,1,1,1,1,-1,-1,1,-1,-1,1,-1,1,1,1,-1,1,1,1,1,0,0,0,0,0];
qpsk1   = [-1+1i,-1+1i,1+1i,1-1i,-1+1i,-1-1i,-1+1i,1-1i,-1+1i,-1-1i,1-1i,-1+1i,-1+1i,-1-1i,-1+1i,-1+1i,1-1i,1-1i,1-1i,-1-1i,-1+1i,-1+1i,1+1i,-1+1i,-1+1i,-1-1i];
qpsk2   = [1-1i,1-1i,-1+1i,1-1i,1+1i,1+1i,1-1i,1-1i,-1-1i,-1-1i,-1-1i,-1+1i,1-1i,-1-1i,-1+1i,-1-1i,-1+1i,-1+1i,-1-1i,1+1i,-1-1i,-1-1i,1+1i,1+1i,-1+1i,-1-1i];
inputiFFT = [zeros(1,6), qpsk1, 0, qpsk2, zeros(1,5)];

%used to find syncword2 start
Np = zeros(1,ofdmRadarReceiver.SamplesPerFrame); 

%flags
packetFound = 0;
timeOutOccured = false; 
droppedSomething = 0; 
currentTime = 0; 
detected = 0; 
len = uint32(0);
ovr = 0;
getData = 0; 
gotData = 0; 
bgn = 0; 

%data received and extracted from packet
dataH   = complex(zeros(1,64));
data    = complex(zeros(1,64));
timeOut = 0; 

%stuff for vectorized timing alignment 
v = syncword2(1:48); 
%v = [v zeros(1,ofdmRadarReceiver.SamplesPerFrame-48)];
npMaxidx=0;
%npThresh = 0; 
%npMax = 0;

%stuff used for partial frames of data
NpPartial = complex(zeros(1,320));
NpPartialTotal = complex(zeros(1,ofdmRadarReceiver.SamplesPerFrame)); 
UsePartial=0;
NpInNextFrame=0;
NpLeft = 320; 

NpPartial2 = complex(zeros(1,400));
NpPartialTotal2 = complex(zeros(1,ofdmRadarReceiver.SamplesPerFrame)); 
UsePartial2=0;
NpInNextFrame2=0;
NpLeft2 = 240; 

%FOR ODFM RADAR ----------------
%indxDiv = indxDivU
Hfill = ofdmRadarReceiver.Hfill; 
H = complex(zeros(Nactual,Hfill));
Hcnt = 1; 

%indexes to divide by 
indxDiv = [7:32 34:59];
tx = inputiFFT(indxDiv(:));
rx = zeros(size(tx));

%number of targets, k
k = 2;
m = k+2; 
W = complex(zeros(Hfill,k)); 
y = zeros(52,1); 
yV = zeros(1,96); 
RR = complex(zeros(m,m));
RV = complex(zeros(m,m)); 

musicV = zeros(k,1); 
musicR = zeros(k,1);
musicRr = zeros(k,1); 
espritR_1A = zeros(k,1);
espritV_2A = zeros(k,1);
esprit_1A_Omega = zeros(k,1); 
espritV_2A_Omega = zeros(k,1); 
RangeE_1A = zeros(k,1); 
VelocityE_2A = zeros(k,1);  

RangeM = zeros(k,1); 

t = zeros(256,1);
t2 = zeros(256,1);
tclutter = zeros(256,1);
f = zeros(256,1); 
f2 = zeros(256,1); 
t2clutter = zeros(256,1); 

%constants for calculations
BW = ofdmRadarReceiver.BW;
delta_f = BW/64;
c = physconst('LightSpeed');
delta_t = ofdmRadarReceiver.DataSpacing/BW;
f_carrier = 5.89*1e9;
lambda = c/f_carrier;

cal = zeros(2,1); 
indices = 0;
datIndx = 160+16:160+16+63;  
dd = zeros(1,64); 
nu = complex(zeros(k,1)); 
dB = 30; 
button=0;
%for the plots
figure

while (currentTime < ofdmRadarReceiver.StopTime)   
  
    [IQ,len,ovr] = radio();
   
    IQ=IQ.';
    if ovr
        droppedSomething = droppedSomething + 1; 
    end
    framesBetween=framesBetween+1; 

    timeOutOccured = false;
    timeOut = 0;
    Hcnt = 1; 
    
    for cntr = 1:(ofdmRadarReceiver.numFramesPerBurst-1)        
        
        if(packetFound == 0)
            %detect syncword1
            symbolDetection = abs(filter(syncword1(1:16),1,IQ(:)));
            symbolDetection = symbolDetection/max(symbolDetection);
            indices = find(symbolDetection>.8 & symbolDetection<1.1);
            idx = diff(indices)==16; 
            detect = sum(idx); 

            %if we find 3 consecutive (= 16*3 = 48 samples) in the detection region
            if( detect >= 3)
                detected = detected + 1;
                packetFound =1;
                %framesBetween-framesLast
            end
        end
        
        %if we found a packet but its not in this frame or the next we lost
        %something reset everything or if a packet was dropped (we need a
        %6-7 frames in between every packet for it to be 4320 spacing. If
        %its more then we lost something. 
        if( timeOut == 2 & packetFound == 1 || (framesBetween-framesLast) > 7)
                packetFound = 0; 
                getData = 0; 
                gotData = 0; 
                Hcnt = 1; 
                timeOut = 0; 
                UsePartial=0;
                NpInNextFrame=0; 
                UsePartial2=0;
                NpInNextFrame2=0;
                %npThresh = 0; 
                timeOutOccured = true; 
        end
        timeOut = timeOut + 1; 
        framesLast = framesBetween;
        
        %if this flag was set then grab the first half of this frame
        %and append it to the partial frame
        if(NpInNextFrame == 1)
             NpInNextFrame = 0; 
             indxL = 1:NpLeft; 
             NpPartialTotal(1,1:length(NpPartial)) = NpPartial;
             NpPartialTotal(1,length(NpPartial)+1:end) = IQ(indxL); 
             UsePartial = 1; 
             NpInNextFrame = 0; 
             IQ = NpPartialTotal; 
             packetFound = 1; 
             
        end
         
        %if this flag was set we need to grab 240 from the current frame to tack onto
        %400 from the last frame
        if(NpInNextFrame2 == 1)
             NpInNextFrame2 = 0; 
             indxL2 = 1:NpLeft2; 
             NpPartialTotal2(1,1:length(NpPartial2)) = NpPartial2;
             NpPartialTotal2(1,length(NpPartial2)+1:end) = IQ(indxL2); 
             UsePartial2 = 1;
             NpInNextFrame2 = 0; 
             IQ = NpPartialTotal2; 
             packetFound = 1;     
        end

        %make a partial frame and set the flag to grab the first part of
        %the next frame if the data started to occur more than half the way into the frame
        if( ~isempty(indices(indices>319)) & packetFound == 1 & UsePartial ==0 )
            indxNp = 321:640;
            NpPartial(1,:)= IQ(indxNp); 
            
            NpInNextFrame =1; 
        end
        
        %used if its greater than 240 (240+400 =640) we could have one sample out of this frame go collect part of the next
        if( ~isempty(indices(indices>239)) & packetFound == 1 & UsePartial == 0 & UsePartial2 == 0 & NpInNextFrame == 0)
            indxNp2 = 241:640;
            NpPartial2(1,:)= IQ(indxNp2); 
            NpLeft2 = 640-length(indxNp2); 
            NpInNextFrame2 =1; 
        end

       
        %if the packet was found & we have built a new frame or it is not
        %split between frames then go ahead and look for starting sample
        if( packetFound & NpInNextFrame==0 & NpInNextFrame2==0)

            if( getData==0  )
                Np = abs(filter(v(:),1,IQ(:)));
                %size(Np)
                %subplot(311)
                %plot(Np)
                [npMax, npMaxidx] = max(Np(:),[],1);
            
                getData = 1;
                bgn = npMaxidx-64;
                if(bgn+160+16>640 || bgn+160+16+63>640)
                    getData = 0; 
                end
            end
           
            %if the whole pakcet was in this frame grab it and process
            if( getData )
                  if( bgn>0) 
                     
                      dd(1,:) = (bgn+160+16:bgn+160+16+63);
                      data = IQ(dd);
                      dataH = fft(data,N);
                      getData = 0; 
                      gotData = 1;
                      %npThresh = npMax(1);
                  end
            end
        
            %if we got the data build H matrix and process. 
            if(gotData & timeOutOccured == false)
                
                rx = dataH(indxDiv(:));
                H(1:52,Hcnt) = (rx./tx).';
                Hcnt = Hcnt + 1;
               
                %if we have filled up our OFDM radar matrix
                %process it
                if(Hcnt == Hfill+1 )
                    
                    %method 1B
                    [OmegaV_1B, disp] = velocity1B(H,k,m);
                    
                      
                    if(ofdmRadarReceiver.Plots)
                        
                            [t,f] = pmusic(H'*H, k,'corr') ; 
                       
                            shiftamnt = (ceil(length(t)/2)); 
                            t = circshift(t, shiftamnt,1);
                            f2 = f-pi; 
                            plot(f2*lambda/(4*pi*delta_t),20*log10(abs(t)),'linewidth',2)
                            
                            hold on 
                            plot([OmegaV_1B(1) OmegaV_1B(1)]* -lambda/(4*pi*delta_t), [-50 -10],'color','r','linewidth', 2)
                            if(disp)
                                plot([OmegaV_1B(2) OmegaV_1B(2)]* -lambda/(4*pi*delta_t), [-50 -10], 'color','r','linewidth', 2)
                                xlabel(['' num2str(abs(OmegaV_1B(1) -OmegaV_1B(2))*lambda/(4*pi*delta_t)) ' meters per second'])
                            else
                                xlabel(['' num2str(0) ' meters per second'])
                            end
                            axis([-15 15 -50 50])
                            grid on
                            set(gca,'Xtick',-15:2:15)
                            hold off
                            ylabel('dB')
                            title('ESPRIT(red) w/ MUSIC Overlay')
                            set(gca,'fontsize',20)
                            drawnow
                       
                    end
                  
                    
                    %reset falg to fill up matrix again
                     Hcnt = 1;
  
                end
                packetFound = 0; 
                timeOut = 0; 
                gotData = 0;
                getData = 0; 
                UsePartial = 0 ; 
                NpInNextFrame = 0; 
                UsePartial2 = 0 ; 
                NpInNextFrame2 = 0; 
                timeOutOccured = false; 
            end
            
        end

        [IQ,len,ovr] = radio();
        IQ = IQ.';
        if ovr
            droppedSomething = droppedSomething+1; 
        end
        framesBetween=framesBetween+1; 
    end
    
    
    % Update simulation time
    currentTime = currentTime + ofdmRadarReceiver.FrameTime;
   
   
end


detected
droppedSomething
release(radio)

end

