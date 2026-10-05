%Cystometry - Unitary Sub Event Analysis - Find Indices
%Written by Max Odem

%Initial steps and global variables
clear all;
close all;
Path = 'C:\MATLAB_TestCode\CystometryWorkFolder\'; %Path for MATLAB time series data
cmapPressure = [0 0 0]; %Color map for plots
cmapEMG = [0 0 0]; %Color map for plots
fontsize = 12;
SampleRate = 10000;
Min3rdDerivHeight = 0.5; %Peak cutoff for 3rd derivative (delta^3mmHg/delta^3t)
Min3rdDerivProm = 0.5; %Minimal peak amplitude for 3rd derivative

%Load time series for unitary event inspection
%Select 1 source file
%Select 1 or more "source_unitary_#" files for analysis
filterspec = {'C:\MATLAB_TestCode\CystometryWorkFolder\*.mat'};
SourceFile = uigetfile(filterspec);
[SourceFilePath,SourceName,SourceExt] = fileparts(SourceFile);
MouseNums = {SourceName};
TotalMice = size(MouseNums, 2);
UnitaryForAnalysis = uigetfile(filterspec, 'MultiSelect', 'on');
[UnitaryFilePath, UnitaryName, UnitaryExt] = fileparts(UnitaryForAnalysis);
LoadUnitary = UnitaryName;
TotalUnitary = size(LoadUnitary, 2);

%Plot source file and prompt user input for minima and peak settings
pressureData = {}; %Sets braces for loading pressure time series
for i = 1:TotalMice
    MouseNum = MouseNums{1,i};
    matName = [Path, MouseNum, '.mat'];
    load(matName);

    pressureData = data(:,1);
    RawTimeScale = 0:1/SampleRate:(size(pressureData,1)-1)/SampleRate; %Timescale in seconds
    StartSec = 1; 
    RawStartInd = find(RawTimeScale > StartSec, 1, 'first');
    RawEndInd = length(RawTimeScale);
    pressureDataNew = pressureData(RawStartInd:RawEndInd) - min(pressureData(RawStartInd:RawEndInd));

    %Smooth pressureData using a Gaussian filter (1 s window = 10000 points)
    pressureDataSmooth = smoothdata(pressureDataNew, 'gaussian', 10000);

    %Prompt user input for findpeak settings for normalizing pressureTrace to zero using lowest micturition cycle minima
    %Recommend using same settings used for Cystometry_AnalysisPipeline_Script1_v1
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
    
    %Normalize pressureData to lowest minima
    [pMinima, pMinimaTime] = findpeaks(-pressureDataSmooth, 'MINPEAKHEIGHT', PressureMinima, 'MINPEAKDISTANCE', MinSampBetweenMinima, 'MINPEAKPROMINENCE', MinMinimaProm);
    pressureOffset = min(abs(pMinima));
    pressureDataZero = pressureDataSmooth - pressureOffset; %Find lowest minima and normalize to it
    
    %Prompt user input for findpeak settings for labeling non-voiding and voiding event peaks
    fig2 = figure(2);
    plot(pressureDataZero);
    fig2.WindowState = 'maximized';
    drawnow;
    PeakSettingsAnswer = 0;
    while PeakSettingsAnswer == 0
        QuestionPeakCutoff = 'What pressure threshold do you want to use for non-voiding and voiding events? (Positive pressure in mmHg)';
        MinPeakHeight = input(QuestionPeakCutoff);
        QuestionPeakSamples = 'What time between do you want to use for non-voiding and voiding events? (Time in seconds)';
        MinSampBetweenPeaks = input(QuestionPeakSamples)*SampleRate;
        QuestionPeakProminence = 'What minimum amplitude do you want to use for non-voiding and voiding events? (Pressure in mmHg)';
        MinPeakProm = input(QuestionPeakProminence);
        findpeaks(pressureDataZero, 'MINPEAKHEIGHT', MinPeakHeight, 'MINPEAKDISTANCE', MinSampBetweenPeaks, 'MINPEAKPROMINENCE', MinPeakProm, 'Annotate', 'extents'); %Will generate plot with peaks labeled
        drawnow;
        QuestionPeakSettings = 'Do you accept these settings for finding non-voiding and voiding events? [1 for Yes/0 for No]';
        PeakSettingsAnswer = input(QuestionPeakSettings);
        if PeakSettingsAnswer == 1
            continue;
        end
    end

    %Prompt user input for findpeak settings for labeling local minima between non-voiding and voiding events
    %This loop will update minima settings
    fig3 = figure(3);
    plot(-pressureDataZero);
    fig3.WindowState = 'maximized';
    drawnow;
    MinimaSettingsAnswer = 0;
    while MinimaSettingsAnswer == 0
        QuestionMinimaCutoff = 'What pressure threshold do you want to use for local minima? (Negative pressure in mmHg)';
        PressureMinima = input(QuestionMinimaCutoff);
        QuestionMinimaSamples = 'What time between do you want to use for local minima? (Time in seconds)';
        MinSampBetweenMinima = input(QuestionMinimaSamples)*SampleRate;
        QuestionMinimaProminence = 'What minimum amplitude do you want to use for local minima? (Pressure in mmHg)';
        MinMinimaProm = input(QuestionMinimaProminence);
        findpeaks(-pressureDataZero, 'MINPEAKHEIGHT', PressureMinima, 'MINPEAKDISTANCE', MinSampBetweenMinima, 'MINPEAKPROMINENCE', MinMinimaProm, 'Annotate', 'extents'); %Will generate plot with local minima labeled
        drawnow;
        QuestionMinimaSettings = 'Do you accept these settings for finding local minima? [1 for Yes/0 for No]';
        MinimaSettingsAnswer = input(QuestionMinimaSettings);
        if MinimaSettingsAnswer == 1
            continue;
        end
    end
end

%Generate table with findpeak variables for unitary sub events
MinimaVariables = [PressureMinima, MinSampBetweenMinima/SampleRate, MinMinimaProm];
PeakVariables = [MinPeakHeight, MinSampBetweenPeaks/SampleRate, MinPeakProm];
FindPeaksVariables = array2table([PeakVariables MinimaVariables], 'VariableNames', {'Peaks - Pressure Cutoff', 'Peaks - Time Between', 'Peaks - Minimal Amplitude', 'Minima - Pressure Cutoff', 'Minima - Time Between', 'Minima - Minimal Amplitude'});
SaveVariables = [Path, SourceName, '_SubEventIsolationVariables.xlsx'];
writetable(FindPeaksVariables, SaveVariables, 'WriteRowNames', 1);

%Read unitary time series one at a time, cannot combine due to different lengths
for i = 1:TotalUnitary
    UnitaryNum = LoadUnitary{1,i};
    matNameUnitary = [Path, UnitaryNum, '.mat'];
    load(matNameUnitary);

    Save1 = [Path, UnitaryNum, '_pressureLengthInSamples.xlsx'];
    Save2 = [Path, UnitaryNum, '_pressurePeaks.xlsx'];
    Save3 = [Path, UnitaryNum, '_pressureMinima.xlsx'];
    Save4 = [Path, UnitaryNum, '_pressure3rdDerivPeaks.xlsx'];

    %Determine length of time series to define indices (different length per trace)
    pressureTraceUnitary = pressureTraceUnitary(1:(end-1)); %Remove last sample point to make equal with time scale
    emgTraceUnitary = emgTraceUnitary(1:(end-1)); %Remove last sample point to make equal with time scale
    UnitarySamples = length(pressureTraceUnitary);
    writematrix(UnitarySamples, Save1);

    %Use findpeaks to identify all peaks in unitary event
    fig4 = figure(4);
    findpeaks(pressureTraceUnitary, 'MINPEAKHEIGHT', MinPeakHeight, 'MINPEAKDISTANCE', MinSampBetweenPeaks, 'MINPEAKPROMINENCE', MinPeakProm, 'Annotate', 'extents'); %Will generate plot with peaks, widths, and amplitudes labeled
    fig4.WindowState = 'maximized';
    saveas(gcf, [Path, UnitaryNum, '_findPressurePeaks', '.jpg'], 'jpg');
    [pressurePeakmmHg, pressurePeakTime, w] = findpeaks(pressureTraceUnitary, 'MINPEAKHEIGHT', MinPeakHeight, 'MINPEAKDISTANCE', MinSampBetweenPeaks, 'MINPEAKPROMINENCE', MinPeakProm);
    NumOfPeaks = size(pressurePeakTime(:,1),1);
    clf;

    %Use findpeaks to identify all minima between peaks in unitary event
    fig5 = figure(5);
    findpeaks(-pressureTraceUnitary, 'MINPEAKHEIGHT', PressureMinima, 'MINPEAKDISTANCE', MinSampBetweenMinima, 'Annotate', 'extents'); %Will generate plot with local minima labeled
    fig5.WindowState = 'maximized';
    saveas(gcf, [Path, UnitaryNum, '_findMinima', '.jpg'], 'jpg');
    [pressureMinima, pressureMinimaTime] = findpeaks(-pressureTraceUnitary, 'MINPEAKHEIGHT', PressureMinima, 'MINPEAKDISTANCE', MinSampBetweenMinima);
    NumOfMinima = size(pressureMinimaTime(:,1),1);
    pressureMinimaAbs = abs(pressureMinima);
    clf;

    %Generate table with peak locations (mmHg and time) and width (time)
    pressurePeakTimeConvert = pressurePeakTime/SampleRate;
    pressurePeakTimeTable = array2table(pressurePeakTimeConvert);
    pressurePeakmmHgTable = array2table(pressurePeakmmHg);
    FindPeaksWidthConvert = w/SampleRate;
    FindPeakWidthsTable = array2table(FindPeaksWidthConvert);
    PeakLocations = [pressurePeakTimeTable pressurePeakmmHgTable FindPeakWidthsTable];
    writetable(PeakLocations, Save2);

    %Generate table with minima locations (mmHg and time)
    pressureMinimaTimeConvert = pressureMinimaTime/SampleRate;
    pressureMinimaTimeTable = array2table(pressureMinimaTimeConvert);
    pressureMinimaTable = array2table(pressureMinima);
    pressureMinimaLocations = [pressureMinimaTimeTable pressureMinimaTable];
    writetable(pressureMinimaLocations, Save3);

    %Calculate first, second, and third derivatives for pressure
    TimeTransposed = transpose(TimeScaleSecUnitary);
    pressureFirstDeriv = diff(pressureTraceUnitary)./diff(TimeTransposed);
    FirstDerivSmooth = smoothdata(pressureFirstDeriv, 'gaussian', 10000); %Second derivative is noisy without smoothing
    pressureSecondDeriv = diff(FirstDerivSmooth)./diff(TimeTransposed(2:end));
    SecondDerivSmooth = smoothdata(pressureSecondDeriv, 'gaussian', 10000); %Third derivative is noisy without smoothing
    pressureThirdDeriv = diff(SecondDerivSmooth)./diff(TimeTransposed(3:end));
    pressureDataPlot1stDeriv = pressureTraceUnitary; %Duplicate
    pressureDataPlot2ndDeriv = pressureTraceUnitary; %Duplicate
    pressureDataPlot3rdDeriv = pressureTraceUnitary; %Duplicate
    TimeTransposedPlot1stDeriv = TimeTransposed; %Duplicate
    TimeTransposedPlot2ndDeriv = TimeTransposed; %Duplicate
    TimeTransposedPlot3rdDeriv = TimeTransposed; %duplicate
    FirstDerivForPlot3rdDeriv = FirstDerivSmooth; %Duplicate
    SecondDerivForPlot3rdDeriv = SecondDerivSmooth; %Duplicate
    pressureDataPlot1stDeriv(1,:) = []; %Removing first row in matrix
    pressureDataPlot2ndDeriv(1:2,:) = []; %Removing first 2 rows in matrix
    pressureDataPlot3rdDeriv(1:3,:) = []; %Removing first 3 rows in matrix
    TimeTransposedPlot1stDeriv(1,:) = []; %Removing first row
    TimeTransposedPlot2ndDeriv(1:2,:) = []; %Removing first 2 rows
    TimeTransposedPlot3rdDeriv(1:3,:) = []; %Removing first 3 rows
    FirstDerivForPlot3rdDeriv(1:2,:) = []; %Removing first 2 rows
    SecondDerivForPlot3rdDeriv(1,:) = []; %Removing first row

    %Use findpeaks to identify peaks in 3rd derivative for pressure
    fig6 = figure(6);
    findpeaks(pressureThirdDeriv, 'MINPEAKHEIGHT', Min3rdDerivHeight, 'MINPEAKPROMINENCE', Min3rdDerivProm, 'Annotate', 'extents'); %Will generate plot with peaks, widths, and amplitudes labeled
    fig6.WindowState = 'maximized';
    saveas(gcf, [Path, UnitaryNum, '_find3rdDerivPeaks', '.jpg'], 'jpg');
    [ThirdDerivPeak, ThirdDerivTime] = findpeaks(pressureThirdDeriv, 'MINPEAKHEIGHT', Min3rdDerivHeight, 'MINPEAKPROMINENCE', Min3rdDerivProm);
    NumOf3rdDerivPeaks = size(ThirdDerivTime(:,1),1);
    pressureAt3rdDerivPeak = zeros(NumOf3rdDerivPeaks,1);
    for k = 1:NumOf3rdDerivPeaks
        pressureAt3rdDerivPeak(k,1) = pressureTraceUnitary(ThirdDerivTime(k,1),1); %Returns pressure value at index
    end
    clf;

    %Generate table with 3rd derivative peak locations (mmHg and time)
    ThirdDerivTimeConvert = ThirdDerivTime/SampleRate;
    ThirdDerivTimeTable = array2table(ThirdDerivTimeConvert);
    pressure3rdDerivTable = array2table(pressureAt3rdDerivPeak);
    pressure3rdDerivLocations = [ThirdDerivTimeTable pressure3rdDerivTable];
    writetable(pressure3rdDerivLocations, Save4);

    %Plot pressure and derivatives
    fig7 = figure(7);
    plot(TimeTransposedPlot3rdDeriv, pressureDataPlot3rdDeriv, 'DisplayName', 'pressureData', 'Color', cmapPressure, 'LineWidth', 0.25)
    hold on;
    plot(TimeTransposedPlot3rdDeriv, FirstDerivForPlot3rdDeriv, 'DisplayName', 'First derivative', 'Color', 'blue', 'LineWidth', 0.25);
    hold on;
    plot(TimeTransposedPlot3rdDeriv, SecondDerivForPlot3rdDeriv, 'DisplayName', 'Second derivative', 'Color', 'red', 'LineWidth', 0.25);
    hold on;
    plot(TimeTransposedPlot3rdDeriv, pressureThirdDeriv, 'DisplayName', 'Third derivative', 'Color', 'green', 'LineWidth', 0.15);
    ThirdDerivLabels = cellstr(num2str((1:NumOf3rdDerivPeaks)'));
    plot(((ThirdDerivTime/SampleRate)), pressureAt3rdDerivPeak, 'x', 'Color', 'magenta', 'MarkerSize', 10, 'DisplayName', '3rd Deriv Peaks')
    text(((ThirdDerivTime/SampleRate)), pressureAt3rdDerivPeak, ThirdDerivLabels);
    MinimaLabels = cellstr(num2str((1:NumOfMinima)'));
    plot(((pressureMinimaTime/SampleRate)), pressureMinimaAbs, 'o', 'Color', 'cyan', 'MarkerSize', 10, 'DisplayName', 'Minima')
    text(((pressureMinimaTime/SampleRate)), pressureMinimaAbs, MinimaLabels);
    PeakLabels = cellstr(num2str((1:NumOfPeaks)'));
    plot(((pressurePeakTime/SampleRate)), pressurePeakmmHg, 'x', 'Color', 'black', 'MarkerSize', 10, 'DisplayName', 'Pressure Peaks')
    text(((pressurePeakTime/SampleRate)), pressurePeakmmHg, PeakLabels);
    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Bladder pressure (mmHg)', 'FontSize', 12);
    yLims = get(gca, 'YLim');
    xLims = get(gca, 'XLim');
    axis([xLims(1) xLims(2) yLims(1) yLims(2)]);
    legend('Location', 'best');
    fig7.WindowState = 'maximized';
    saveas(gcf, [Path, UnitaryNum, '_plotDerivsMinimaPeaks' '.jpg'], 'jpg');
    clf;

    %Plot pressure and emg
    fig8 = figure(8);
    subplot(2,1,1);
    plot(TimeScaleSecUnitary, pressureTraceUnitary, 'Color', cmapPressure, 'LineWidth', 1)
    xlabel('Time (s)', 'FontSize', fontsize);
    ylabel('Bladder pressure (mmHg)', 'FontSize', fontsize);
    yLimsPressure = get(gca, 'YLim');
    xLimsPressure = get(gca, 'XLim');
    axis([xLimsPressure(1) xLimsPressure(2) yLimsPressure(1) yLimsPressure(2)]); 
    subplot(2,1,2);
    plot(TimeScaleSecUnitary, emgTraceUnitary, 'Color', cmapEMG, 'LineWidth', 1)
    xlabel('Time (s)', 'FontSize', fontsize);
    ylabel('Sphincter EMG (mV)', 'FontSize', fontsize); %Units are millivolts
    yLimsEMG = get(gca, 'YLim');
    xLimsEMG = get(gca, 'XLim');
    axis([xLimsEMG(1) xLimsEMG(2) yLimsEMG(1) yLimsEMG(2)]);
    set(gca, 'FontSize', fontsize);
    fig8.WindowState = 'maximized';
    saveas(gcf, [Path, UnitaryNum, '_plotTraces' '.jpg'], 'jpg');
    clf;

    %Plot converted emg trace to help pick threshold
    SmoothWindowSize = 300; %For gaussian smoothing emgData (default = 30 ms, example: @10 kHz, 10 ms = 100 samples)
    GaussFilter = gausswin(SmoothWindowSize); %Value found by guess & check to define the appropriate filter size
    NormGaussFilter = GaussFilter ./ sum(sum(GaussFilter)); %Normalize so that it all adds up to 1 (apply filter across matrix equivalently)
    emgTraceTemp = emgTraceUnitary.^2;
    emgTraceTempSmooth = sqrt(conv(emgTraceTemp, NormGaussFilter, 'valid'));
    emgTraceTempSmoothConvert = emgTraceTempSmooth.*1000;
    emgTraceNormToMedian = emgTraceTempSmoothConvert - median(emgTraceTempSmoothConvert);
    fig9 = figure(9);
    plot(emgTraceNormToMedian, 'Color', cmapEMG, 'LineWidth', 1)
    xlabel('Sample', 'FontSize', fontsize);
    ylabel('Sphincter EMG (\muV, normalized to trace median)', 'FontSize', fontsize);
    yLimsEMGConvert = get(gca, 'YLim');
    xLimsEMGConvert = get(gca, 'XLim');
    axis([xLimsEMGConvert(1) xLimsEMGConvert(2) yLimsEMGConvert(1) yLimsEMGConvert(2)]);
    set(gca, 'FontSize', fontsize);
    fig9.WindowState = 'maximized';
    saveas(gcf, [Path, UnitaryNum, '_plotConvertedEMGTrace' '.jpg'], 'jpg');
    clf;

    if i == TotalUnitary
        close all
    end
end