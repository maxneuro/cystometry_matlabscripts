%Cystometry - Peak Analysis
%Legacy script written by Jason Keller and Kara Marshall
%Refined script written by Max Odem

%Initial steps and global variables
clear all;
close all;
Path = 'C:\MATLAB_TestCode\CystometryWorkFolder\'; %Path for MATLAB time series data
emgMinThresh = 3; %Value in uV, removes the low values in EMG trace for mean and sum calculations
cmapPressure = [0 0 0]; %Color map for plots
cmapEMG = [0 0 0]; %Color map for plots
fontsize = 10;
SampleRate = 10000;
SmoothWindowSize = 300; %For gaussian smoothing emgData (default = 30 ms, example: @10 kHz, 10 ms = 100 samples)
NoiseBaseline = 1; %Time in seconds to measure noise in emgData
NoiseBaselineSamp = NoiseBaseline*SampleRate; %Number of samples for measuring noise
DownSampFactor = 1; %Downsampling necessary for heatmaps and emgData parameters

%Define period of time to isolate pressure peak and measure emgData parameters (Default is 5 seconds pre and post, currently using 18)
PrePeakToAnalyze = 5; %Time in seconds
PostPeakToAnalyze = 5; %Time in seconds

%Define period of time to plot pressure peak and emgData (Default is 20 seconds pre and post, currently using 10)
PreTimeToPlot = 20; %in seconds
PostTimeToPlot = 20; %in seconds

%Set plotting functions
PlotTraces = 1; %1 = plot selected peaks, 0 = no plot
PlotHeatMap = 1; %1 = plot selected peaks as heatmap, 0 = no plot

%Load time series for event parameter analysis
%Select 1 source file
%Select 1 or more "source_#" files for analysis
filterspec = {'C:\MATLAB_TestCode\CystometryWorkFolder\*.mat'};
SourceFile = uigetfile(filterspec);
[SourceFilePath,SourceName,SourceExt] = fileparts(SourceFile);
SaveName1 = [Path, SourceName, '_EventsParameters', '.xlsx'];
EventsForAnalysis = uigetfile(filterspec, 'MultiSelect', 'on');
[EventFilePath,EventName,EventExt] = fileparts(EventsForAnalysis);
LoadEvents = EventName;
TotalEvents = size(LoadEvents, 2);

%Creating data arrays
PrePeakSamples = PrePeakToAnalyze*SampleRate;
PostPeakSamples = PostPeakToAnalyze*SampleRate;
PreTimeSamples = PreTimeToPlot*SampleRate; 
PostTimeSamples = PostTimeToPlot*SampleRate; 
TotalSamples = PreTimeSamples + PostTimeSamples + 1;
ValidSamples = TotalSamples-SmoothWindowSize+1;
emgData = zeros(TotalSamples, TotalEvents);
emgDataAbs = zeros(TotalSamples, TotalEvents);
emgSmoothToMin = zeros(ValidSamples, TotalEvents);
emgSmoothToMean = zeros(ValidSamples, TotalEvents);
pressureData = zeros(TotalSamples, TotalEvents);
pressureDataForArea = zeros(TotalSamples, TotalEvents);
emgTraces = zeros(TotalSamples, TotalEvents);
emgTraceZero = zeros(TotalEvents,1);
emgTraceTemp = zeros(TotalSamples, TotalEvents);
emgSmoothTemp = zeros(399702, TotalEvents); %399702 is number of samples remaining after applying the NormGaussFilter
emgRMSMeanNoise = zeros(TotalEvents,1);

%Creating gaussian filter for smoothing emgData
GaussFilter = gausswin(SmoothWindowSize); %Value found by guess & check to define the appropriate filter size
NormGaussFilter = GaussFilter ./ sum(GaussFilter); %Normalize so that it all adds up to 1 (apply filter across matrix equivalently)

%Reading time series data for event parameters analysis
for i = 1:TotalEvents
    EventNum = LoadEvents{1,i};
    matName = [Path, EventNum, '.mat'];
    load(matName);
    
    pressureData(:,i) = pressureTrace;
    pressureDataForArea(:,i) = pressureTrace - min(pressureTrace);
    
    emgTraces(:,i) = emgTrace;
    emgTraceZero(i,1) = mean(emgTraces(1:NoiseBaselineSamp,i));
    emgData(:,i) = emgTraces(:,i) - emgTraceZero(i,1);
    emgDataAbs(:,i) = abs(emgTraces(:,i));
    
    %Smoothing emgData for noise and normalization
    emgTraceTemp(:,i) = emgTraces(:,i).^2; %Square emgTrace amplitude before smoothing
    emgSmoothTemp(:,i) = sqrt(conv(emgTraceTemp(:,i), NormGaussFilter, 'valid'));
    emgRMSMeanNoise(i) = mean(emgSmoothTemp(1:NoiseBaselineSamp,i)); %Calculate mean noise at beginning of trace
    emgSmoothToMean(:,i) = emgSmoothTemp(:,i) - emgRMSMeanNoise(i); %Subract mean noise
    emgRMSMinNoise(i) = min(emgSmoothTemp(1:NoiseBaselineSamp,i)); %Calculate minimum value at beginning of trace
    emgSmoothToMin(:,i) = emgSmoothTemp(:,i) - emgRMSMinNoise(i); %Subract minimum noise value to get all positive values for EMG RMS analysis
end

%Post-read compuations
Peak = round(TotalSamples/2);
peakOnlySamplesStart = Peak - PrePeakSamples;
peakOnlySamplesEnd = Peak + PostPeakSamples;
pressureDownSampled = downsample(pressureData(1:ValidSamples,:),DownSampFactor);
EventIntegral = trapz(pressureDataForArea)/length(pressureDataForArea); %Calculate contraction event integrals
EventIntegralsForSort = trapz(pressureDownSampled)/length(pressureDownSampled); %Calculate integral for downsampled pressureData, looks better than absolute area heatmap
TotalArea = trapz(pressureDataForArea)/SampleRate; %Calculates total area under the curve in units of mmHg x second
[~,MaxRowIndices] = sort(EventIntegralsForSort,'descend'); %Sort by decreasing pressure integral
pressureDataSorted = pressureDownSampled(:,MaxRowIndices); %Use for sorted heatmap, looks cleaner
pressureRMS = rms(pressureDownSampled);
EventMaxPressure = max(pressureDownSampled,[],1); %Find maximum pressure during each contraction event 
emgDownSampled = downsample(emgSmoothToMean(1:ValidSamples,:).*1000,DownSampFactor);
[~,emgMaxRowIndeces] = sort(mean(emgDownSampled)); %Use these indeces to sort heatmap by mean EMG
emgDataSorted = emgDownSampled(:,MaxRowIndices); %Sorts EMG using sorted pressure EventIntegrals
emgSumRMSDuringEvent = sum(emgSmoothToMean(peakOnlySamplesStart:peakOnlySamplesEnd,:),1); %Sum RMS EMG voltage during middle 10s of contraction event (centered on peak)
emgMeanRMSDuringEvent = mean(emgSmoothToMin(peakOnlySamplesStart:peakOnlySamplesEnd,:),1); %Mean RMS EMG voltage during middle 10s of contraction event (centered on peak)
emgSmoothtoMin2 = emgSmoothToMin.*1000; %Set new EMG values for those below threshold and convert to uV
emgToDelete = find(abs(emgSmoothtoMin2)<emgMinThresh); %Find non-signal values
emgSmoothtoMin2(emgToDelete) = NaN ; %Delete non-signal values for mean and sum parameters 
emgCleanMean = mean(emgSmoothtoMin2(peakOnlySamplesStart:peakOnlySamplesEnd,:),1,'omitnan'); %Calculate mean without NaN during middle 10 s of contraction event (centered on peak)
emgCleanSum = sum(emgSmoothtoMin2(peakOnlySamplesStart:peakOnlySamplesEnd,:),1,'omitnan'); %Calculate sum without NaN during middle 10 s of contraction event (centered on peak)

%Write pressure and EMG parameters to table
PeakEventParameters = [EventIntegral; TotalArea; pressureRMS; EventMaxPressure; emgSumRMSDuringEvent; emgMeanRMSDuringEvent; emgCleanMean; emgCleanSum];
PeakEventParameterResults = array2table(PeakEventParameters,'RowNames',{'EventIntegral', 'TotalArea', 'pressureRMS', 'EventMaxPressure', 'emgSumRMSDuringEvent', 'emgMeanRMSDuringEvent', 'emgCleanMean', 'emgCleanSum'});
writetable(PeakEventParameterResults, SaveName1, 'WriteRowNames', 1);

%Plot pressure/EMG time series
if PlotTraces
    for i = 1:TotalEvents
        EventNum = LoadEvents{1,i};
        figure;
        subplot(2,1,1);
        plot(TimeScaleSec, pressureData(:,i), 'Color', cmapPressure, 'LineWidth', 1)
        xlabel('Time (s)', 'FontSize', fontsize);
        ylabel('Bladder pressure (mmHg)', 'FontSize', fontsize);
        yLimsPressure = get(gca, 'YLim');
        axis([-PreTimeToPlot PostTimeToPlot yLimsPressure(1) yLimsPressure(2)]);
        set(gca, 'FontSize', fontsize);
        
        subplot(2,1,2);
        plot(TimeScaleSec, emgData(:,i), 'Color', cmapEMG, 'LineWidth', 1)
        xlabel('Time (s)', 'FontSize', fontsize);
        ylabel('Urethra activity (mV)', 'FontSize', fontsize); %Units are millivolts
        yLimsEMG = get(gca, 'YLim');
        axis([-PreTimeToPlot PostTimeToPlot yLimsEMG(1) yLimsEMG(2)]);
        set(gca, 'FontSize', fontsize);

        saveas(gcf, [Path, EventNum, '.jpg'], 'jpg');
    end
end

%Plot pressure and EMG intensity heatmaps
if PlotHeatMap 
    figure;
    %heatmap(pressureDownSampled'); %Can substitute sorted data ("pressureDataSorted")
    imagesc(pressureDownSampled'); %Can substitute sorted data ("pressureDataSorted")
    colormap bone
    caxis([0 25]);
    timescale = -PreTimeToPlot: (PostTimeToPlot+PreTimeToPlot)/length(pressureDownSampled) :PostTimeToPlot;
    x1 = find(timescale>-20, 1, 'first');
    x2 = find(timescale>-19, 1, 'first');
    x3 = find(timescale>-18, 1, 'first');
    x4 = find(timescale>-17, 1, 'first');
    x5 = find(timescale>-16, 1, 'first');
    x6 = find(timescale>-15, 1, 'first');
    x7 = find(timescale>-14, 1, 'first');
    x8 = find(timescale>-13, 1, 'first');
    x9 = find(timescale>-12, 1, 'first');
    x10 = find(timescale>-11, 1, 'first');
    x11 = find(timescale>-10, 1, 'first');
    x12 = find(timescale>-9, 1, 'first');
    x13 = find(timescale>-8, 1, 'first');
    x14 = find(timescale>-7, 1, 'first');
    x15 = find(timescale>-6, 1, 'first');
    x16 = find(timescale>-5, 1, 'first');
    x17 = find(timescale>-4, 1, 'first');
    x18 = find(timescale>-3, 1, 'first');
    x19 = find(timescale>-2, 1, 'first');
    x20 = find(timescale>-1, 1, 'first');
    x21 = find(timescale>0, 1, 'first');
    x22 = find(timescale>1, 1, 'first');
    x23 = find(timescale>2, 1, 'first');
    x24 = find(timescale>3, 1, 'first');
    x25 = find(timescale>4, 1, 'first');
    x26 = find(timescale>5, 1, 'first');
    x27 = find(timescale>6, 1, 'first');
    x28 = find(timescale>7, 1, 'first');
    x29 = find(timescale>8, 1, 'first');
    x30 = find(timescale>9, 1, 'first');
    x31 = find(timescale>10, 1, 'first');
    x32 = find(timescale>11, 1, 'first');
    x33 = find(timescale>12, 1, 'first');
    x34 = find(timescale>13, 1, 'first');
    x35 = find(timescale>14, 1, 'first');
    x36 = find(timescale>15, 1, 'first');
    x37 = find(timescale>16, 1, 'first');
    x38 = find(timescale>17, 1, 'first');
    x39 = find(timescale>18, 1, 'first');
    x40 = find(timescale>19, 1, 'first');
    x41 = length(timescale)-1;
    %set(gca,'XDisplayData', [x11 x12 x13 x14 x15 x16 x17 x18 x19 x20 x21 x22 x23 x24 x25 x26 x27 x28 x29 x30 x31 x41]);
    %set(gca,'XDisplayLabels', {'-10' '-9' '-8' '-7' '-6' '-5' '-4' '-3' '-2' '-1' '0' '1' '2' '3' '4' '5' '6' '7' '8' '9' '10'});
    set(gca,'XTick', [x1 x6 x11 x16 x21 x26 x31 x36 x41]);
    set(gca,'XTickLabel', {'-20' '-15' '-10' '-5' '0' '5' '10' '15' '20'});
    xlabel('Time from peak (s)');
    title('Bladder pressure (mmHg)');
    colorbar
    set(gca, 'FontSize', fontsize);
    saveas(gcf, [Path, SourceName, '_pressureHeatMap.jpg'], 'jpg');
    
    figure;
    %heatmap(emgDownSampled'); %Can substitute sorted data ("emgDataSorted")
    imagesc(emgDownSampled'); %Can substitute sorted data ("emgDataSorted")
    colormap(1-gray);
    caxis([0 50]);
    %set(gca,'XDisplayData', [x11 x12 x13 x14 x15 x16 x17 x18 x19 x20 x21 x22 x23 x24 x25 x26 x27 x28 x29 x30 x31 x41]); 
    %set(gca,'XDisplayLabels', {'-10' '-9' '-8' '-7' '-6' '-5' '-4' '-3' '-2' '-1' '0' '1' '2' '3' '4' '5' '6' '7' '8' '9' '10'});
    set(gca,'XTick', [x1 x6 x11 x16 x21 x26 x31 x36 x41]);
    set(gca,'XTickLabel', {'-20' '-15' '-10' '-5' '0' '5' '10' '15' '20'});
    xlabel('Time from peak (s)');
    title('Urethra activity (\muV)'); %Units are microvolts
    colorbar
    set(gca, 'FontSize', fontsize);
    saveas(gcf, [Path, SourceName, '_emgHeatMap.jpg'], 'jpg');
end