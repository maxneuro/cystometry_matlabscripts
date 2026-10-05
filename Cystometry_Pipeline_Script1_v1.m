%Cystometry - Isolate Peak and Unitary Events
%Legacy script written by Jason Keller and Kara Marshall
%Refined script written by Max Odem

%Initial steps and global variables
clear all;
close all;
Path = 'C:\MATLAB_TestCode\CystometryWorkFolder\'; %Path for MATLAB time series data
fontsize = 12;
SampleRate = 10000; %Sampling rate per second of MATLAB time series data
DownSampFactor = 5; %Downsampling makes plotting easier
cmapPressure = [0 0 0]; %Color map for plots
cmapEMG = [0 0 0]; %Color map for plots
pressureData = {}; %Sets braces for loading pressure time series
emgData = {}; %Sets braces for loading emg time series
PreTimeToIndex = 20*SampleRate; %Time in seconds to index prior to pressure peak
PostTimeToIndex = 20*SampleRate; %Time in seconds to index after pressure peak

%Load 1 source file
filterspec = {'C:\MATLAB_TestCode\CystometryWorkFolder\*.mat'};
SourceFile = uigetfile(filterspec);
[SourceFilePath,SourceName,SourceExt] = fileparts(SourceFile);
MouseNums = {SourceName};
TotalMice = size(MouseNums, 2);

%Reading time series data
for i = 1:TotalMice
    MouseNum = MouseNums{1,i};
    matName = [Path, MouseNum, '.mat'];
    load(matName);

    Save1 = [Path, MouseNum, '_pressureOffset.xlsx'];
    Save2 = [Path, MouseNum, '_EventIsolationVariables.xlsx'];
    Save3 = [Path, MouseNum, '_pressurePeaks.xlsx'];
    Save4 = [Path, MouseNum, '_pressureMinima.xlsx'];
   
    pressureData = data(:,1);
    emgData = data(:,2);
    
    RawTimeScale = 0:1/SampleRate:(size(pressureData,1)-1)/SampleRate; %Timescale in seconds
    StartSec = 1; 
    RawStartInd = find(RawTimeScale > StartSec, 1, 'first');
    RawEndInd = length(RawTimeScale);
    pressureOffset1 = min(pressureData(RawStartInd:RawEndInd));
    pressureDataNew = pressureData(RawStartInd:RawEndInd) - pressureOffset1;
    emgDataNew = emgData(RawStartInd:RawEndInd);
    NewTimeScale = RawTimeScale(RawStartInd:RawEndInd);

    %Smooth pressureData using a Gaussian filter (1 s window = 10000 points)
    pressureDataSmooth = smoothdata(pressureDataNew, 'gaussian', 10000);
    
    %Prompt user input for findpeak settings for micturition cycle minima
    %Important for normalizing the pressureTrace to zero
    fig1 = figure(1);
    plot(-pressureDataSmooth);
    fig1.WindowState = 'maximized';
    drawnow;
    MinimaSettingsAnswer = 0;
    while MinimaSettingsAnswer == 0
        QuestionMinimaCutoff = 'What pressure threshold do you want to use for micturition cycle minima? (Negative pressure in mmHg)';
        PressureMinima = input(QuestionMinimaCutoff);
        QuestionMinimaSamples = 'What time between do you want to use for micturition cycle minima? (Time in seconds)';
        MinSampBetweenMinima = input(QuestionMinimaSamples)*SampleRate;
        QuestionMinimaProminence = 'What minimum amplitude do you want to use for micturition cycle minima? (Pressure in mmHg)';
        MinMinimaProm = input(QuestionMinimaProminence);
        findpeaks(-pressureDataSmooth, 'MINPEAKHEIGHT', PressureMinima, 'MINPEAKDISTANCE', MinSampBetweenMinima, 'MINPEAKPROMINENCE', MinMinimaProm, 'Annotate', 'extents'); %Will generate plot with local minima labeled
        drawnow;
        QuestionMinimaSettings = 'Do you accept these settings for finding micturition cycle minima? [1 for Yes/0 for No]';
        MinimaSettingsAnswer = input(QuestionMinimaSettings);
        if MinimaSettingsAnswer == 1
            continue;
        end
    end
    fig2 = figure(2);
    findpeaks(-pressureDataSmooth, 'MINPEAKHEIGHT', PressureMinima, 'MINPEAKDISTANCE', MinSampBetweenMinima, 'MINPEAKPROMINENCE', MinMinimaProm, 'Annotate', 'extents'); %Will generate plot with local minima labeled
    fig2.WindowState = 'maximized';
    saveas(gcf, [Path, MouseNum, '_findMinima', '.jpg'], 'jpg');
    [pressureMinima, pressureMinimaTime] = findpeaks(-pressureDataSmooth, 'MINPEAKHEIGHT', PressureMinima, 'MINPEAKDISTANCE', MinSampBetweenMinima, 'MINPEAKPROMINENCE', MinMinimaProm);

    %Normalize pressureData to lowest minima
    pressureOffset2 = min(abs(pressureMinima));
    pressureDataZero = pressureDataSmooth - pressureOffset2; %Find lowest minima and normalize to it
    pressureMinimaZero = (abs(pressureMinima)) - pressureOffset2; %Normalize minima to match
    pressureOffsetTotal = pressureOffset1+pressureOffset2;
    writematrix(pressureOffsetTotal, Save1);
    
    %Prompt user input for findpeak settings for micturition peak events
    %Important for replicating Kara's method
    fig3 = figure(3);
    plot(pressureDataZero);
    fig3.WindowState = 'maximized';
    drawnow;
    PeakSettingsAnswer = 0;
    while PeakSettingsAnswer == 0
        QuestionPeakCutoff = 'What pressure threshold do you want to use for labeling peaks? (Positive pressure in mmHg)';
        MinPeakHeight = input(QuestionPeakCutoff);
        QuestionPeakSamples = 'What time between do you want to use between peaks? (Time in seconds)';
        MinSampBetweenPeaks = input(QuestionPeakSamples)*SampleRate;
        QuestionPeakProminence = 'What minimum amplitude do you want to use for peaks? (Pressure in mmHg)';
        MinPeakProm = input(QuestionPeakProminence);
        findpeaks(pressureDataZero, 'MINPEAKHEIGHT', MinPeakHeight, 'MINPEAKDISTANCE', MinSampBetweenPeaks, 'MINPEAKPROMINENCE', MinPeakProm, 'Annotate', 'extents'); %Will generate plot with peaks labeled
        drawnow;
        QuestionPeakSettings = 'Do you accept these settings for finding peaks? [1 for Yes/0 for No]';
        PeakSettingsAnswer = input(QuestionPeakSettings);
        if PeakSettingsAnswer == 1
            continue;
        end
    end
    fig4 = figure(4);
    findpeaks(pressureDataZero, 'MINPEAKHEIGHT', MinPeakHeight, 'MINPEAKDISTANCE', MinSampBetweenPeaks, 'MINPEAKPROMINENCE', MinPeakProm, 'Annotate', 'extents'); %Will generate plot with peaks, widths, and amplitudes labeled
    fig4.WindowState = 'maximized';
    saveas(gcf, [Path, MouseNum, '_findPressurePeaks', '.jpg'], 'jpg');
    [pressurePeakmmHg, pressurePeakTime, w] = findpeaks(pressureDataZero, 'MINPEAKHEIGHT', MinPeakHeight, 'MINPEAKDISTANCE', MinSampBetweenPeaks, 'MINPEAKPROMINENCE', MinPeakProm);

    %Generate table with findpeak variables
    MinimaVariables = [PressureMinima, MinSampBetweenMinima/SampleRate, MinMinimaProm];
    PeakVariables = [MinPeakHeight, MinSampBetweenPeaks/SampleRate, MinPeakProm];
    FindPeaksVariables = array2table([MinimaVariables PeakVariables], 'VariableNames', {'Minima - Pressure Cutoff', 'Minima - Time Between', 'Minima - Minimal Amplitude', 'Peaks - Pressure Cutoff', 'Peaks - Time Between', 'Peaks - Minimal Amplitude'});
    writetable(FindPeaksVariables, Save2, 'WriteRowNames', 1);

    %Removes peaks detected at the beginning/end if they cannot be fully plotted
    indToDelete1 = find(pressurePeakTime < PreTimeToIndex);
    indToDelete2 = find((length(pressureDataSmooth) - pressurePeakTime) < PostTimeToIndex);
    indToDelete = unique([indToDelete1; indToDelete2]);
    pressurePeakTime(indToDelete)= [];
    pressurePeakmmHg(indToDelete)= [];
    w(indToDelete) = [];

    %Generate table with pressure peak locations (mmHg and time) and width (time)
    pressurePeakTimeConvert = pressurePeakTime/SampleRate;
    pressurePeakTimeTable = array2table(pressurePeakTimeConvert);
    pressurePeakmmHgTable = array2table(pressurePeakmmHg);
    FindPeaksWidthConvert = w/SampleRate;
    FindPeakWidthsTable = array2table(FindPeaksWidthConvert);
    PeakLocations = [pressurePeakTimeTable pressurePeakmmHgTable FindPeakWidthsTable];
    writetable(PeakLocations, Save3);

    %Generate table with pressure minima locations (mmHg and time)
    pressureMinimaTimeConvert = pressureMinimaTime/SampleRate;
    pressureMinimaTimeTable = array2table(pressureMinimaTimeConvert);
    pressureMinimaTable = array2table(pressureMinimaZero);
    pressureMinimaLocations = [pressureMinimaTimeTable pressureMinimaTable];
    writetable(pressureMinimaLocations, Save4);

    %Plot full pressure and emg trace
    fig5 = figure(5);
    subplot(2,1,1)
    plot(NewTimeScale, pressureDataZero, 'Color', cmapPressure, 'LineWidth', 0.25)
    xlabel('Time (s)', 'FontSize', fontsize);
    ylabel('Bladder pressure (mmHg)', 'FontSize', fontsize);
    yLimsPressure = get(gca, 'YLim');
    %xLimsPressure = get(gca, 'XLim');
    axis([0 1200 yLimsPressure(1) yLimsPressure(2)]); 
    subplot(2,1,2)
    plot(NewTimeScale, emgDataNew, 'Color', cmapEMG, 'LineWidth', 0.25);
    xlabel('Time (s)', 'FontSize', fontsize);
    ylabel('Urethra activity (mV)', 'FontSize', fontsize); %Units are millivolts
    yLimsEMG = get(gca, 'YLim');
    %xLimsEMG = get(gca, 'XLim');
    axis([0 1200 yLimsEMG(1) yLimsEMG(2)]);
    set(gca, 'FontSize', fontsize);
    fig5.WindowState = 'maximized';
    saveas(gcf, [Path, MouseNum, '_plotTraces' '.jpg'], 'jpg');

    %Generate individual .mat files for pressure peaks (based on findpeaks of pressure), contains pressure and EMG time series
    for k = 1:length(pressurePeakTime)
        StartInd(k) = pressurePeakTime(k) - PreTimeToIndex;
        EndInd(k) = pressurePeakTime(k) + PostTimeToIndex;
        emgTrace = emgDataNew(StartInd(k):EndInd(k));
        pressureTrace = pressureDataZero(StartInd(k):EndInd(k));
        TimeScaleSec = -(PreTimeToIndex/SampleRate):1/SampleRate:(PostTimeToIndex/SampleRate);
        SaveTraceName = [Path, MouseNum, '_', num2str(k), '.mat'];
        save(SaveTraceName, 'emgTrace', 'pressureTrace', 'TimeScaleSec');
    end

    %Use minima indices to isolate unitary events
    NumOfMinima = size(pressureMinimaTime(:,1),1);
    MinimaDurations = zeros(NumOfMinima, 1);
    for k = 1:(NumOfMinima)-1
        MinimaDurations(k) = pressureMinimaTime((k+1),1)-pressureMinimaTime(k,1);
    end
    MinimaDurations(end,1) = length(pressureDataZero)-pressureMinimaTime(end,1); 
    for k = 1:(NumOfMinima)-1
        StartMinima(k) = pressureMinimaTime(k);
        EndMinima(k) = pressureMinimaTime(k+1);
        emgTraceUnitary = emgDataNew(StartMinima(k):EndMinima(k));
        pressureTraceUnitary = pressureDataZero(StartMinima(k):EndMinima(k));
        TimeScaleSecUnitary = 1/SampleRate:1/SampleRate:MinimaDurations(k)/SampleRate;
        SaveTraceNameUnitary = [Path, MouseNum, '_unitary_', num2str(k), '.mat'];
        save(SaveTraceNameUnitary, 'emgTraceUnitary', 'pressureTraceUnitary', 'TimeScaleSecUnitary');
    end
end