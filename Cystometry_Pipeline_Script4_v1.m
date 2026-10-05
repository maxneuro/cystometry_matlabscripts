%Cystometry - Heatmaps for Unitary Sub Events - Create Heatmaps
%Written by Max Odem

%Initial steps and global variables
clear all;
close all;
Path = 'C:\MATLAB_TestCode\CystometryWorkFolder\'; %Path for MATLAB time series data
fontsize = 12;
SampleRate = 10000;
SmoothWindowSize = 300; %For gaussian smoothing emgData (default = 30 ms, example: @10 kHz, 10 ms = 100 samples)
NoiseBaseline = 1; %Time in seconds to measure noise in emgData
NoiseBaselineSamp = NoiseBaseline*SampleRate; %Number of samples for measuring noise
GaussFilter = gausswin(SmoothWindowSize); %Value found by guess & check to define the appropriate filter size
NormGaussFilter = GaussFilter ./ sum(sum(GaussFilter)); %Normalize so that it all adds up to 1 (apply filter across matrix equivalently)

%Set inflection and/or peak-aligned heatmap output (1 = yes plot, 0 = no plot)
WantInflectHM = 1;
WantPeakHM = 1;

%Define number of samples output by previous step in pipeline
NumOfSamples = 300001;

%Define plot time around inflection point
PreInflectionTime = 10; %Time in seconds
PostInflectionTime = 20; %Time in seconds

%Define plot time around peak
PrePeakTime = 10; %Time in seconds
PostPeakTime = 10; %Time in seconds

%Load time series for heatmaps
%Select 1 or more "source_unitary_#_forHM_SubEvent#" files
filterspec = {'C:\MATLAB_TestCode\CystometryWorkFolder\*.mat'};
SubsForAnalysis = uigetfile(filterspec, 'MultiSelect', 'on');
[SubFilePath,SubName,SubExt] = fileparts(SubsForAnalysis);
SubNames = transpose(SubName(1,1:end));
NumOfEvents = length(SubName);

%Create data arrays for inflection heatmaps
pressureData = zeros(NumOfSamples,NumOfEvents);
emgData = zeros(NumOfSamples,NumOfEvents);
emgSmoothNumOfSamples = NumOfSamples-SmoothWindowSize+1;
emgDataSmooth = zeros(emgSmoothNumOfSamples,NumOfEvents);

%Create data arrays for peak heatmaps
PeakNumOfSamples = 200001;
PeakFirst10Sec = zeros(NumOfEvents,1);
PeakInd = zeros(NumOfEvents,1);
pressureDataForPeaks = zeros(PeakNumOfSamples,NumOfEvents);
emgSmoothPeakNumOfSamples = PeakNumOfSamples;
emgDataSmoothForPeaks = zeros(emgSmoothPeakNumOfSamples,NumOfEvents);

%Read time series
for i = 1:NumOfEvents
    MATLABFILE = char(SubNames(i));
    MatFileNameSub = [Path, MATLABFILE, '.mat'];
    load(MatFileNameSub);

    %Load data into arrays
    pressureData(:,i) = pressureHM;
    emgData(:,i) = emgHM;

    %Find peak within first 10 seconds from inflection
    PeakFirst10Sec(i,:) = max(pressureHM(100000:200000));
    PeakInd(i,:) = find(pressureHM == max(pressureHM(100000:200000)),1,'first');
    PeakHMStartInd = PeakInd-(PrePeakTime*SampleRate);
    PeakHMEndInd = PeakInd+(PostPeakTime*SampleRate);
    pressureDataForPeaks(:,i) = pressureHM(PeakHMStartInd(i):PeakHMEndInd(i));

    %Smoothing emg and normalize to median
    emgTempHM = emgHM.^2; %Square amplitude before smoothing
    emgTempHMSmooth = sqrt(conv(emgTempHM, NormGaussFilter, 'valid'));
    emgHMSmoothToMedian = emgTempHMSmooth - median(emgTempHMSmooth);
    emgHMSmoothToMedianConvert = emgHMSmoothToMedian.*1000; %Convert to uV
    emgDataSmooth(:,i) = emgHMSmoothToMedianConvert;
    emgDataSmoothForPeaks(:,i) = emgDataSmooth(((PeakHMStartInd(i)-300):(PeakHMEndInd(i)-300)),i);
end

%Sort data by max indices
[~,MaxRowIndices] = sort(PeakFirst10Sec,'descend');
pressureDataSorted = pressureData(:,MaxRowIndices);
emgDataSmoothSorted = emgDataSmooth(:,MaxRowIndices);
pressureDataForPeaksSorted = pressureDataForPeaks(:,MaxRowIndices);
emgDataSmoothForPeaksSorted = emgDataSmoothForPeaks(:,MaxRowIndices);

maxpressure = max(max(pressureData));
maxemg = max(max(emgDataSmooth));

%Create inflection-aligned heatmaps
if WantInflectHM
    figure;
    imagesc(pressureData');
    colormap bone;
    caxis([0 maxpressure]);
    InflectHMTimeScale = -PreInflectionTime:(PostInflectionTime+PreInflectionTime)/length(pressureData):PostInflectionTime;
    x1 = find(InflectHMTimeScale>-10,1,'first');
    x2 = find(InflectHMTimeScale>-5,1,'first');
    x3 = find(InflectHMTimeScale>0,1,'first');
    x4 = find(InflectHMTimeScale>5,1,'first');
    x5 = find(InflectHMTimeScale>10,1,'first');
    x6 = find(InflectHMTimeScale>15,1,'first');
    x7 = length(InflectHMTimeScale)-1;
    set(gca,'XTick', [x1 x2 x3 x4 x5 x6 x7]);
    set(gca,'XTickLabel', {'-10' '-5' '0' '5' '10' '15' '20'});
    set(gca, 'YTick', [1 48.5 70.5 97.5 115.5 129.5 157.5 181.5 207.5]); %set animal rows
    set(gca, 'YTickLabel', {'WT1', 'WT2', 'WT3', 'WT4', 'WT5', 'WT6', 'P1KO1', 'P1KO2', 'P1KO3'}); %set animal row labels
    yline([48.5 70.5 97.5 115.5 129.5 157.5 181.5 207.5], '--r', '', 'Color', 'y', 'LineWidth', 3); %set animal row lines
    xlabel('Time from inflection (s)', 'FontSize', 30);
    c = colorbar;
    ylabel(c, 'Pressure (mmHg)');
    ax = gca;
    ax.FontSize = 25;
    print(gcf, [Path, '_pressureInflectionHeatMap_Chronological.tiff'], '-dtiff', '-r300');

    figure;
    imagesc(pressureDataSorted');
    colormap bone;
    caxis([0 maxpressure]);
    InflectHMTimeScale = -PreInflectionTime:(PostInflectionTime+PreInflectionTime)/length(pressureDataSorted):PostInflectionTime;
    x1 = find(InflectHMTimeScale>-10,1,'first');
    x2 = find(InflectHMTimeScale>-5,1,'first');
    x3 = find(InflectHMTimeScale>0,1,'first');
    x4 = find(InflectHMTimeScale>5,1,'first');
    x5 = find(InflectHMTimeScale>10,1,'first');
    x6 = find(InflectHMTimeScale>15,1,'first');
    x7 = length(InflectHMTimeScale)-1;
    set(gca,'XTick', [x1 x2 x3 x4 x5 x6 x7]);
    set(gca,'XTickLabel', {'-10' '-5' '0' '5' '10' '15' '20'});
    xlabel('Time from inflection (s)', 'FontSize', 30);
    c = colorbar;
    ylabel(c, 'Pressure (mmHg)');
    ax = gca;
    ax.FontSize = 25;
    print(gcf, [Path, '_pressureInflectionHeatMap_Sorted.tiff'], '-dtiff', '-r300');
    
    figure;
    imagesc(emgDataSmooth');
    colormap(1-gray);
    caxis([0 100]);
    InflectHMTimeScale = -PreInflectionTime:(PostInflectionTime+PreInflectionTime)/length(emgDataSmooth):PostInflectionTime;
    x1 = find(InflectHMTimeScale>-10,1,'first');
    x2 = find(InflectHMTimeScale>-5,1,'first');
    x3 = find(InflectHMTimeScale>0,1,'first');
    x4 = find(InflectHMTimeScale>5,1,'first');
    x5 = find(InflectHMTimeScale>10,1,'first');
    x6 = find(InflectHMTimeScale>15,1,'first');
    x7 = length(InflectHMTimeScale)-1;
    set(gca,'XTick', [x1 x2 x3 x4 x5 x6 x7]);
    set(gca,'XTickLabel', {'-10' '-5' '0' '5' '10' '15' '20'});
    set(gca, 'YTick', [1 48.5 70.5 97.5 115.5 129.5 157.5 181.5 207.5]); %set animal rows
    set(gca, 'YTickLabel', {'WT1', 'WT2', 'WT3', 'WT4', 'WT5', 'WT6', 'P1KO1', 'P1KO2', 'P1KO3'}); %set animal row labels
    yline([48.5 70.5 97.5 115.5 129.5 157.5 181.5 207.5], '--r', '', 'Color', 'b', 'LineWidth', 3); %set animal row lines
    xlabel('Time from inflection (s)', 'FontSize', 30);
    c = colorbar;
    ylabel(c, 'Urethra activity (\muV)');
    ax = gca;
    ax.FontSize = 25;
    print(gcf, [Path, '_emgInflectionHeatMap_Chronological.tiff'], '-dtiff', '-r300');

    figure;
    imagesc(emgDataSmoothSorted');
    colormap(1-gray);
    caxis([0 100]);
    InflectHMTimeScale = -PreInflectionTime:(PostInflectionTime+PreInflectionTime)/length(emgDataSmoothSorted):PostInflectionTime;
    x1 = find(InflectHMTimeScale>-10,1,'first');
    x2 = find(InflectHMTimeScale>-5,1,'first');
    x3 = find(InflectHMTimeScale>0,1,'first');
    x4 = find(InflectHMTimeScale>5,1,'first');
    x5 = find(InflectHMTimeScale>10,1,'first');
    x6 = find(InflectHMTimeScale>15,1,'first');
    x7 = length(InflectHMTimeScale)-1;
    set(gca,'XTick', [x1 x2 x3 x4 x5 x6 x7]);
    set(gca,'XTickLabel', {'-10' '-5' '0' '5' '10' '15' '20'});
    xlabel('Time from inflection (s)', 'FontSize', 30);
    c = colorbar;
    ylabel(c, 'Urethra activity (\muV)');
    ax = gca;
    ax.FontSize = 25;
    print(gcf, [Path, '_emgInflectionHeatMap_Sorted.tiff'], '-dtiff', '-r300');
end

%Create peak-aligned heatmaps
if WantPeakHM
    figure;
    imagesc(pressureDataForPeaks');
    colormap bone;
    caxis([0 maxpressure]);
    PeakHMTimeScale = -PrePeakTime:(PostPeakTime+PrePeakTime)/length(pressureDataForPeaks):PostPeakTime;
    x1 = find(PeakHMTimeScale>-10,1,'first');
    x2 = find(PeakHMTimeScale>-5,1,'first');
    x3 = find(PeakHMTimeScale>0,1,'first');
    x4 = find(PeakHMTimeScale>5,1,'first');
    x5 = length(PeakHMTimeScale)-1;
    set(gca,'XTick', [x1 x2 x3 x4 x5]);
    set(gca,'XTickLabel', {'-10' '-5' '0' '5' '10'});
    set(gca, 'YTick', [1 48.5 70.5 97.5 115.5 129.5 157.5 181.5 207.5]); %set animal rows
    set(gca, 'YTickLabel', {'WT1', 'WT2', 'WT3', 'WT4', 'WT5', 'WT6', 'P1KO1', 'P1KO2', 'P1KO3'}); %set animal row labels
    yline([48.5 70.5 97.5 115.5 129.5 157.5 181.5 207.5], '--r', '', 'Color', 'y', 'LineWidth', 3); %set animal row lines
    xlabel('Time from peak (s)', 'FontSize', 30);
    c = colorbar;
    ylabel(c, 'Pressure (mmHg)');
    ax = gca;
    ax.FontSize = 25;
    print(gcf, [Path, '_pressurePeakHeatMap_Chronological.tiff'], '-dtiff', '-r300');

    figure;
    imagesc(pressureDataForPeaksSorted');
    colormap bone;
    caxis([0 maxpressure]);
    PeakHMTimeScale = -PrePeakTime:(PostPeakTime+PrePeakTime)/length(pressureDataForPeaksSorted):PostPeakTime;
    x1 = find(PeakHMTimeScale>-10,1,'first');
    x2 = find(PeakHMTimeScale>-5,1,'first');
    x3 = find(PeakHMTimeScale>0,1,'first');
    x4 = find(PeakHMTimeScale>5,1,'first');
    x5 = length(PeakHMTimeScale)-1;
    set(gca,'XTick', [x1 x2 x3 x4 x5]);
    set(gca,'XTickLabel', {'-10' '-5' '0' '5' '10'});
    xlabel('Time from peak (s)', 'FontSize', 30);
    c = colorbar;
    ylabel(c, 'Pressure (mmHg)');
    ax = gca;
    ax.FontSize = 25;
    print(gcf, [Path, '_pressurePeakHeatMap_Sorted.tiff'], '-dtiff', '-r300');
    
    figure;
    imagesc(emgDataSmoothForPeaks');
    colormap(1-gray);
    caxis([0 100]);
    PeakHMTimeScale = -PrePeakTime:(PostPeakTime+PrePeakTime)/length(emgDataSmoothForPeaks):PostPeakTime;
    x1 = find(PeakHMTimeScale>-10,1,'first');
    x2 = find(PeakHMTimeScale>-5,1,'first');
    x3 = find(PeakHMTimeScale>0,1,'first');
    x4 = find(PeakHMTimeScale>5,1,'first');
    x5 = length(PeakHMTimeScale)-1;
    set(gca,'XTick', [x1 x2 x3 x4 x5]);
    set(gca,'XTickLabel', {'-10' '-5' '0' '5' '10'});
    set(gca, 'YTick', [1 48.5 70.5 97.5 115.5 129.5 157.5 181.5 207.5]); %set animal rows
    set(gca, 'YTickLabel', {'WT1', 'WT2', 'WT3', 'WT4', 'WT5', 'WT6', 'P1KO1', 'P1KO2', 'P1KO3'}); %set animal row labels
    yline([48.5 70.5 97.5 115.5 129.5 157.5 181.5 207.5], '--r', '', 'Color', 'b', 'LineWidth', 3); %set animal row lines
    xlabel('Time from peak (s)', 'FontSize', 30);
    c = colorbar;
    ylabel(c, 'Urethra activity (\muV)');
    ax = gca;
    ax.FontSize = 25;
    print(gcf, [Path, '_emgPeakHeatMap_Chronological.tiff'], '-dtiff', '-r300');

    figure;
    imagesc(emgDataSmoothForPeaksSorted');
    colormap(1-gray);
    caxis([0 100]);
    PeakHMTimeScale = -PrePeakTime:(PostPeakTime+PrePeakTime)/length(emgDataSmoothForPeaksSorted):PostPeakTime;
    x1 = find(PeakHMTimeScale>-10,1,'first');
    x2 = find(PeakHMTimeScale>-5,1,'first');
    x3 = find(PeakHMTimeScale>0,1,'first');
    x4 = find(PeakHMTimeScale>5,1,'first');
    x5 = length(PeakHMTimeScale)-1;
    set(gca,'XTick', [x1 x2 x3 x4 x5]);
    set(gca,'XTickLabel', {'-10' '-5' '0' '5' '10'});
    xlabel('Time from peak (s)', 'FontSize', 30);
    c = colorbar;
    ylabel(c, 'Urethra activity (\muV)');
    ax = gca;
    ax.FontSize = 25;
    print(gcf, [Path, '_emgPeakHeatMap_Sorted.tiff'], '-dtiff', '-r300');
end