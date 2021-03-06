function [sData] = markRipples(sData,makeSpectrogramPlot)

%detectRipples is used to automatically detect peaks in the ripple
%frequency and extract indices of these peaks so that snippets of the LFP
%signals containing putative ripples may be plotted for visual verification.

%HOW TO PERFORM MANUAL SCORING
%in response to the prompt "Keep ripple? X of X", type 'y' to keep the
%ripple that is at the center of the plot. Type 'b' to go back to a
%previous ripple and re-inspect, type 'm' to manually click on a ripple
%waveform in the plot that may have been missed. NB! When you type 'm' and hit
%enter, crosshairs will appear and you can click on the LFP line plot
%roughly in the center of the ripple (aligning the crosshairs with the
%spectrogram helps to estimate the ripple peak). You can click as many
%times as you want if there are multiple missed ripples in the plot. When
%you are done clicking, hit enter. The "extra" ripple locations will be
%saved and you will be prompted again to save or discard the ripple that
%was detected at the center of the plot. To discard a ripple, simply hit
%enter.

%%INPUTS: 
%sData struct, containing the lfp recording from one animal, one session
%makeSpectrogramPlot, a logical (1/0) indicating whether to include a
%spectrogram when plotting the ripple traces for manual scoring

%%OUTPUTS:
%sData, updated with ripple locations, ripple waveform snippets, and
%parameters of the scoring (freq filter, threshold)

fs = 2500;
freqFilter = [100 250];
lfpSignal = sData.ephysdata.lfp;
try 
    runSignal = sData.daqdata.run_speed;
catch
    runSignal = sData.daqdata.runSpeed;
end
lfp = lfpSignal;
rawLFP = lfpSignal;

nSnips = floor(length(rawLFP)/(fs)) - 1;
time = linspace(0,length(lfp),length(lfp))/(fs);
timeRound = round(time,3);
rippleLocs = [];

window_size = 1;
window_size_index = window_size * fs;


    
% Filter LFP between 150-250 hz for sharp wave ripple detection
freqL = freqFilter(1);
freqU = freqFilter(2);
nyquistFs = fs/2;
%min_ripple_width = 0.015; % minimum width of envelop at upper threshold for ripple detection in ms
    
% Thresholds for ripple detection 
U_threshold = 3;  % in standard deviations
% L_threshold = 1; % in standard deviations
    
% Create filter and apply to LFP data
filter_kernel = fir1(600,[freqL freqU]./nyquistFs); % Different filters can also be tested her e.g. butter and firls

filtered_lfp = filtfilt(filter_kernel,1,lfp); % Filter LFP using the above created filter kernel

% Hilbert transform LFP to calculate envelope
lfp_hil_tf = hilbert(filtered_lfp);
lfp_envelop = abs(lfp_hil_tf);

% Smooth envelop using code from 
% https://se.mathworks.com/matlabcentral/fileexchange/43182-gaussian-smoothing-filter?focused=3839183&tab=function 
smoothed_envelop = gaussfilt_2017(time,lfp_envelop,.004);
moving_mean = movmean(smoothed_envelop, window_size_index);
moving_std = movstd(smoothed_envelop, window_size_index);
moving_mean_move = movmean(runSignal, window_size_index);


% Find upper/lower threshold values of the LFP
upper_thresh = moving_mean + U_threshold*moving_std;
    

% Find peaks of envelop. NB: The parameters of this function have to be properly
% chosen for best result.
[~,locs,~,~] = findpeaks(smoothed_envelop-upper_thresh,fs,'MinPeakHeight',0,'MinPeakDistance',0.025,'MinPeakWidth',0.015,'WidthReference','halfhprom','Annotate','extents','WidthReference','halfprom');
rippleLocs = round(locs,3);    
 

    
% end

rippleSnips = struct();
rippleIdx = zeros(1,length(rippleLocs));
rippleLocs = round(rippleLocs,3);
%convert the ripple locations from time to sample
for i = 1:length(rippleLocs)
        lfpPeakIdx = find(timeRound == rippleLocs(i));
        lfpStartIdx = lfpPeakIdx(1) - (0.5*fs);
        %if the ripple timepoint is near the beginning of the trace
        if lfpStartIdx < 0; lfpStartIdx = 1; end
        lfpEndIdx = lfpPeakIdx(1) + (0.5*fs);
        %if the ripple timepoint is near the end of the trace
        if lfpEndIdx > length(lfpSignal); lfpEndIdx = length(lfpSignal); end
        rippleSnips(i).lfp = rawLFP(lfpStartIdx:lfpEndIdx);
        rippleIdx(i) = lfpPeakIdx(1);
    if runSignal(rippleIdx(i)) ~= 0; rippleIdx(i) = NaN; end %take out timepoints when animal is walking
%     if runSignal(moving_mean_move(i)) ~= 0; rippleIdx(i) = NaN; end %take out timepoints when animal is walking
    
end

%remove NaNs and timepoints too close together (likely identifying the same ripple
%waveform)
rippleSnips(isnan(rippleIdx)) = [];
rippleIdx(isnan(rippleIdx)) = [];

[final_rippleLFP,final_rippleLocs] = inspectRipples(rippleSnips,rippleIdx,lfp,makeSpectrogramPlot);
sData.ephysdata.absRipIdx = final_rippleLocs;
sData.ephysdata.rippleSnips = final_rippleLFP;
try frames = sData.daqdata.frame_onset_reference_frame;
catch frames = sData.daqdata.frameIndex;
end
sData.ephysdata.frameRipIdx = frames(sData.ephysdata.absRipIdx);
sData.ephysdata.freqFilterSWR = freqFilter;
sData.ephysdata.SWREnvThr = U_threshold;
% timeBetweenRipples = diff(rippleIdx);
% %must have at least 100 ms between ripples, if there are 2 close together,
% %keep the later one
% extraRipples = find(timeBetweenRipples < 250);
% rippleIdx(extraRipples + 1) = [];
% rippleSnips(extraRipples + 1) = [];





