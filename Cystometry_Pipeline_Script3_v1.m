%Cystometry - Unitary Sub Event Analysis - Analyze Using Indices
%Written by Max Odem

%Initial steps and global variables
clear all;
close all;
Path = 'C:\MATLAB_TestCode\CystometryWorkFolder\'; %Path for MATLAB time series data
cmapPressure = [0 0 0]; %Color map for plots
cmapEMG = [0 0 0]; %Color map for plots
fontsize = 12;
SampleRate = 10000;
SmoothWindowSize = 300; %For gaussian smoothing emgData (default = 30 ms, example: @10 kHz, 10 ms = 100 samples)
GaussFilter = gausswin(SmoothWindowSize); %Value found by guess & check to define the appropriate filter size
NormGaussFilter = GaussFilter ./ sum(sum(GaussFilter)); %Normalize so that it all adds up to 1 (apply filter across matrix equivalently)
emgSpikeMinimum = 20; %Amplitude in microvolts
emgMinThresh = 3; %Value in uV, removes the low values in EMG trace for mean and sum calculations
BladderFillRate = 0.5; %Value in uL/second

%Load 1 source file
filterspec = {'C:\MATLAB_TestCode\CystometryWorkFolder\*.mat'};
SourceFile = uigetfile(filterspec);
[SourceFilePath,SourceName,SourceExt] = fileparts(SourceFile);

%Load 1 "UnitaryEvents_IndexTable_ANIMAL" excel file
%Number of rows = number of events to analyze
%Number of columns = number of parameters (31 parameters total)
filterspecEXCEL = {'C:\MATLAB_TestCode\CystometryWorkFolder\*.xlsx'};
UnitaryIndexTable = uigetfile(filterspecEXCEL);
[IndTableFilePath, IndTableFileName, IndTableFileExt] = fileparts(UnitaryIndexTable);
fileinfolder = [Path, UnitaryIndexTable];
UniIndTable = readtable(fileinfolder);
UnitaryName = UniIndTable.UnitaryName(1:end,1);
DerivFileName = UniIndTable.DerivFileName(1:end,1);
MinimaFileName = UniIndTable.MinimaFileName(1:end,1);
PeaksFileName = UniIndTable.PeaksFileName(1:end,1);
SubEventID = UniIndTable.SubEventID;
Sex = char(UniIndTable.Sex);
StartIndType = char(UniIndTable.StartIndexType);
EndIndType = char(UniIndTable.EndIndexType);
NumOfEvents = height(UniIndTable);
UnitaryParameters = zeros(NumOfEvents, 31);

%Begin analysis loop
for i = 1:NumOfEvents
    MATLABFILE = char(UnitaryName(i));
    matNameUnitary = [Path, MATLABFILE, '.mat'];
    load(matNameUnitary);

    %Set iteration number to SubEventID
    iteration = sprintf('_SubEvent%d', SubEventID(i));

    %Define start index
    StartType = StartIndType(i);
        if StartType == 'D'
            DerivFile = [Path, char(DerivFileName(i)), '.xlsx'];
            DerivNums = readvars(DerivFile);
            DerivTime = DerivNums(UniIndTable.StartIndexNumber(i), 1);
            DerivTimeConvert = DerivTime*SampleRate;
            StartInd = floor(DerivTimeConvert);
        elseif StartType == 'M'
            MinimaFile = [Path, char(MinimaFileName(i)), '.xlsx'];
            MinimaNums = readvars(MinimaFile);
            MinimaTime = MinimaNums(UniIndTable.StartIndexNumber(i), 1);
            MinimaTimeConvert = MinimaTime*SampleRate;
            StartInd = floor(MinimaTimeConvert);
        end
    
    %Define end index
    EndType = EndIndType(i);
        if EndType == 'D'
            DerivFile = [Path, char(DerivFileName(i)), '.xlsx'];
            DerivNums = readvars(DerivFile);
            DerivTime = DerivNums(UniIndTable.EndIndexNumber(i), 1);
            DerivTimeConvert = DerivTime*SampleRate;
            EndInd = floor(DerivTimeConvert);
        elseif EndType == 'M'
            MinimaFile = [Path, char(MinimaFileName(i)), '.xlsx'];
            MinimaNums = readvars(MinimaFile);
            MinimaTime = MinimaNums(UniIndTable.EndIndexNumber(i), 1);
            MinimaTimeConvert = MinimaTime*SampleRate;
            EndInd = floor(MinimaTimeConvert);
        end

    %Collect pressure data
    pressureUnitary = pressureTraceUnitary(StartInd:EndInd);
    emgUnitary = emgTraceUnitary(StartInd:EndInd);
    TimeScale = TimeScaleSecUnitary(StartInd:EndInd);
    Duration = (EndInd-StartInd)/SampleRate;
    UnitaryStartPressure = pressureTraceUnitary(1);
    StartTime = StartInd/SampleRate;
    StartPressure = pressureTraceUnitary(StartInd);
    EndTime = EndInd/SampleRate;
    EndPressure = pressureTraceUnitary(EndInd);
    Amplitude = max(pressureUnitary)-pressureTraceUnitary(StartInd);
    pressureRMS = rms(pressureUnitary);
    pressureOffsetForAUC = min(pressureUnitary);
    pressureUniTemp = pressureUnitary - pressureOffsetForAUC;
    pressureIntegral = trapz(pressureUniTemp)/length(pressureUniTemp);
    pressureAUC = trapz(pressureUniTemp)/SampleRate;
    RelaStartPressure = StartPressure+UnitaryStartPressure;
    RelaEndPressure = EndPressure+UnitaryStartPressure;

    %Smoothing emg and normalizing to median
    emgUniTemp = emgUnitary.^2; %Square amplitude before smoothing
    emgUniTempSmooth = sqrt(conv(emgUniTemp, NormGaussFilter, 'valid'));
    emgSmoothToMedian = emgUniTempSmooth - median(emgUniTempSmooth);

    %Sum and mean emg RMS
    %These parameters are calculated for the whole trace
    %If emg activity is detected above threshold, then these values will be overwritten with values calculated only during emg activity 
    emgSumRMS = sum(emgSmoothToMedian);
    emgMeanRMS = mean(emgSmoothToMedian);
    emgSmoothToMedianConvert = emgSmoothToMedian.*1000; %Convert to uV
    ForDeletion = find(abs(emgSmoothToMedianConvert) < emgMinThresh);
    emgSmoothToMedianConvertDuplicate = emgSmoothToMedianConvert;
    emgSmoothToMedianConvertDuplicate(ForDeletion) = NaN;
    emgCleanMeanRMS = mean(emgSmoothToMedianConvertDuplicate,'omitnan');
    emgCleanSumRMS = sum(emgSmoothToMedianConvertDuplicate,'omitnan');

    %Calculate pressure peak
    if UniIndTable.PeakIndexNumber(i) > 0
        PeakFile = [Path, char(PeaksFileName(i)), '.xlsx'];
        PeakTimeNums = readvars(PeakFile, 'Range', 'A:A');
        PeakPressureNums = readvars(PeakFile, 'Range', 'B:B');
        PeakTime = PeakTimeNums(UniIndTable.PeakIndexNumber(i), 1);
        PeakPressure = PeakPressureNums(UniIndTable.PeakIndexNumber(i), 1);
        PeakInd = floor(PeakTime*SampleRate);
        TimeStartToPeak = (PeakInd-StartInd)/SampleRate;
        TimePeakToEnd = (EndInd-PeakInd)/SampleRate;
        RelaPeakPressure = PeakPressure+UnitaryStartPressure;
    elseif UniIndTable.PeakIndexNumber(i) == 0
        PeakPressure = max(pressureUnitary);
        PeakTime = (StartInd+floor(find(pressureUnitary == PeakPressure)))/SampleRate;
        PeakInd = floor(PeakTime*SampleRate);
        TimeStartToPeak = (PeakInd-StartInd)/SampleRate;
        TimePeakToEnd = (EndInd-PeakInd)/SampleRate;
        RelaPeakPressure = PeakPressure+UnitaryStartPressure;
    end

    %Calculate time constant (tau) for relaxation phase of bladder contraction
    RelaxPhase = pressureTraceUnitary(PeakInd:EndInd);
    Pressure63Percent = 0.632*(max(RelaxPhase)-min(RelaxPhase));
    TauPressure = max(RelaxPhase) - Pressure63Percent;
    TauTime = find(RelaxPhase < TauPressure, 1, 'first')/SampleRate;
    RelaTauPressure = TauPressure+UnitaryStartPressure;

    %Use findpeaks to detect emg activity and define sex-specific variables
    %Males and females analyzed differently, if sex is unknown, then default to male variable values
    [emgSpikeAmpCheck, emgSpikeTimeCheck, w, emgSpikePromCheck] = findpeaks(emgSmoothToMedianConvert);
    MouseSex = Sex(i);
        if MouseSex == 'M'
            emgSpikeMinimum = 20; %Amplitude in microvolts
            emgMinThresh = 3; %Value in uV, removes the low values in EMG trace for mean and sum calculations
        elseif MouseSex == 'U'
            emgSpikeMinimum = 20;
            emgMinThresh = 3;
        elseif MouseSex == 'F'
            emgSpikeMinimum = 5;
            emgMinThresh = 3;
        end

    %If emg activity meets minimum threshold, then recalculate parameters
    if max(emgSpikeAmpCheck) >= emgSpikeMinimum

        %Define remaining sex-specific emg variables
        if MouseSex == 'M'
            [emgSpikeYLoc, emgSpikeXLoc, w, emgSpikeProm] = findpeaks(emgSmoothToMedianConvert, 'MINPEAKHEIGHT', emgSpikeMinimum);
            emgMinProm = max(emgSpikeProm)*0.25; %Min spike prominence for males is 25% maximal amplitude
            emgPromFilter = emgMinProm;
        elseif MouseSex == 'U'
            [emgSpikeYLoc, emgSpikeXLoc, w, emgSpikeProm] = findpeaks(emgSmoothToMedianConvert, 'MINPEAKHEIGHT', emgSpikeMinimum);
            emgMinProm = max(emgSpikeProm)*0.25;
            emgPromFilter = emgMinProm;
        elseif MouseSex == 'F'
            [emgSpikeYLoc, emgSpikeXLoc, w, emgSpikeProm] = findpeaks(emgSmoothToMedianConvert, 'MINPEAKHEIGHT', emgSpikeMinimum);
            emgMinProm = emgSpikeMinimum; %Min spike prominence for females is set to the spike minimum
            emgPromFilter = emgMinProm;
        end

        %Detect emg activity using sex-specific variables
        figure;
        findpeaks(emgSmoothToMedianConvert, 'MINPEAKHEIGHT', emgSpikeMinimum, 'Annotate', 'extents'); %Will generate plot
        drawnow;
        saveas(gcf, [Path, char(UnitaryName(i)), '_plotEMGspikes_NoMinProm', iteration, '.jpg'], 'jpg');
        figure;
        findpeaks(emgSmoothToMedianConvert, 'MINPEAKHEIGHT', emgSpikeMinimum, 'MINPEAKPROM', emgMinProm, 'Annotate', 'extents'); %Will generate plot
        drawnow;
        saveas(gcf, [Path, char(UnitaryName(i)), '_plotEMGspikes_OneFourthMaxProm', iteration, '.jpg'], 'jpg');
        
        %Calculate correction for samples lost after applying NormGaussFilter to emg
        LostSamples = length(emgUniTemp)-length(emgUniTempSmooth);
        LostSampleRate = length(emgUniTemp)/LostSamples;
        LostSampleCorrection = (emgSpikeXLoc/LostSampleRate)/SampleRate;

        %Output all detected emg activity
        emgSpikeTime = (emgSpikeXLoc/SampleRate)+LostSampleCorrection;
        emgSpikeTimeTable = array2table(emgSpikeTime);
        emgSpikePeakTable = array2table(emgSpikeYLoc);
        emgSpikeProminenceTable = array2table(emgSpikeProm);
        emgSpikeLocations = [emgSpikeTimeTable emgSpikePeakTable emgSpikeProminenceTable];
        emgSaveName = [Path, char(UnitaryName(i)), '_UnitaryParameters_emgSpikes_NoMinProm', iteration, '.xlsx'];
        writetable(emgSpikeLocations, emgSaveName, 'WriteRowNames', 1);
    
        %Isolate emg bursts
        emgBursts = emgSpikeLocations; %Duplicate
        emgBursts(emgBursts.emgSpikeProm < emgPromFilter, :) = []; %Remove rows with prominence less than the sex-specific prominence filter
        emgSaveName2 = [Path, char(UnitaryName(i)), '_UnitaryParameters_emgSpikes_OneFourthMaxProm', iteration, '.xlsx'];
        writetable(emgBursts, emgSaveName2, 'WriteRowNames', 1);
        emgFirstBurstTime = emgBursts.emgSpikeTime(1,1);
        emgFirstBurstTimeCorrected = emgFirstBurstTime+LostSampleCorrection(1,1);
        emgFirstBurstInd = floor(emgBursts.emgSpikeTime(1,1)*SampleRate);
        emgLastBurstInd = floor(emgBursts.emgSpikeTime(end,1)*SampleRate);
        emgFirstBurstPressure = pressureUnitary(emgFirstBurstInd);
        emgRelaFirstBurstPressure = emgFirstBurstPressure+UnitaryStartPressure;
    
        %Recalculate emg measurements to only include emg bursting activity
        emgSumRMS = sum(emgSmoothToMedian(emgFirstBurstInd:emgLastBurstInd));
        emgMeanRMS = mean(emgSmoothToMedian(emgFirstBurstInd:emgLastBurstInd));
        emgCleanMeanRMS = mean(emgSmoothToMedianConvertDuplicate(emgFirstBurstInd:emgLastBurstInd),'omitnan');
        emgCleanSumRMS = sum(emgSmoothToMedianConvertDuplicate(emgFirstBurstInd:emgLastBurstInd),'omitnan');
    
        %Calculate emg burst frequency
        emgBurstTimeTotal = (emgLastBurstInd - emgFirstBurstInd)/SampleRate;
        emgBurstFreq = length(emgBursts.emgSpikeProm)/emgBurstTimeTotal;
    else
        emgFirstBurstTime = NaN;
        emgFirstBurstTimeCorrected = NaN;
        emgFirstBurstPressure = NaN;
        emgBurstFreq = NaN;
        emgRelaFirstBurstPressure = NaN;
    end

    %Calculate bladder compliance at start of event
    BladderCompEventStart = (StartTime*BladderFillRate)/(StartPressure-UnitaryStartPressure);

    %Plot pressure and emg time series
    figure;
    subplot(2,1,1);
    plot(TimeScale, pressureUnitary(1:(end)), 'Color', cmapPressure, 'LineWidth', 1)
    xlabel('Time (s)', 'FontSize', fontsize);
    ylabel('Bladder pressure (mmHg)', 'FontSize', fontsize);
    yLimsPressure = get(gca, 'YLim');
    xLimsPressure = get(gca, 'XLim');
    axis([xLimsPressure(1) xLimsPressure(2) yLimsPressure(1) yLimsPressure(2)]); 
    subplot(2,1,2);
    plot(TimeScale, emgUnitary(1:(end)), 'Color', cmapEMG, 'LineWidth', 1)
    xlabel('Time (s)', 'FontSize', fontsize);
    ylabel('Urethra activity (mV)', 'FontSize', fontsize); %Units are millivolts
    yLimsEMG = get(gca, 'YLim');
    xLimsEMG = get(gca, 'XLim');
    axis([xLimsEMG(1) xLimsEMG(2) yLimsEMG(1) yLimsEMG(2)]);
    set(gca, 'FontSize', fontsize);
    drawnow;
    saveas(gcf, [Path, char(UnitaryName(i)), '_plotTraces', iteration, '.jpg'], 'jpg');

    %Load parameters into array
    UnitaryParameters(i,1) = UnitaryStartPressure;
    UnitaryParameters(i,2) = StartTime;
    UnitaryParameters(i,3) = StartPressure;
    UnitaryParameters(i,4) = RelaStartPressure;
    UnitaryParameters(i,5) = EndTime;
    UnitaryParameters(i,6) = EndPressure;
    UnitaryParameters(i,7) = RelaEndPressure;
    UnitaryParameters(i,8) = PeakTime;
    UnitaryParameters(i,9) = PeakPressure;
    UnitaryParameters(i,10) = RelaPeakPressure;
    UnitaryParameters(i,11) = TimeStartToPeak;
    UnitaryParameters(i,12) = TimePeakToEnd;
    UnitaryParameters(i,13) = Duration;
    UnitaryParameters(i,14) = Amplitude;
    UnitaryParameters(i,15) = TauTime;
    UnitaryParameters(i,16) = TauPressure;
    UnitaryParameters(i,17) = RelaTauPressure;
    UnitaryParameters(i,18) = pressureRMS;
    UnitaryParameters(i,19) = pressureOffsetForAUC;
    UnitaryParameters(i,20) = pressureIntegral;
    UnitaryParameters(i,21) = pressureAUC;
    UnitaryParameters(i,22) = emgSumRMS;
    UnitaryParameters(i,23) = emgMeanRMS;
    UnitaryParameters(i,24) = emgCleanMeanRMS;
    UnitaryParameters(i,25) = emgCleanSumRMS;
    UnitaryParameters(i,26) = emgFirstBurstTime;
    UnitaryParameters(i,27) = emgFirstBurstTimeCorrected;
    UnitaryParameters(i,28) = emgFirstBurstPressure;
    UnitaryParameters(i,29) = emgRelaFirstBurstPressure;
    UnitaryParameters(i,30) = emgBurstFreq;
    UnitaryParameters(i,31) = BladderCompEventStart;

    %Generate new .mat traces for heatmaps, set inflection point to 10 seconds
    %Set indices for heatmap traces
    pressureTraceUnitaryLastInd = length(pressureTraceUnitary);
    StartIndHM = StartInd-(10*SampleRate);
    EndIndHM = StartInd+(20*SampleRate);

    %Create arrays for heatmap traces
    pressureHM = zeros(EndIndHM-StartIndHM+1,1);
    emgHM = zeros(EndIndHM-StartIndHM+1,1);

    %Fill missing rows with NaN if trace is not long enough before or after inflection point
    if EndIndHM > pressureTraceUnitaryLastInd
        RealLength = pressureTraceUnitaryLastInd-StartIndHM+1;
        FillLength = EndIndHM-pressureTraceUnitaryLastInd;
        RowsForNaN = NaN(FillLength,1);
        pressureHM(1:RealLength,1) = pressureTraceUnitary(StartIndHM:pressureTraceUnitaryLastInd);
        pressureHM((RealLength+1):end,1) = RowsForNaN;
        emgHM(1:RealLength,1) = pressureTraceUnitary(StartIndHM:pressureTraceUnitaryLastInd);
        emgHM((RealLength+1):end,1) = RowsForNaN;
    elseif EndIndHM <= pressureTraceUnitaryLastInd
        if StartIndHM > 0
            pressureHM = pressureTraceUnitary(StartIndHM:EndIndHM);
            emgHM = emgTraceUnitary(StartIndHM:EndIndHM);
        else
            tracelength = height(pressureHM);
            lengthtouse = tracelength-abs(StartIndHM);
            pressureHM(1:abs(StartIndHM)) = NaN;
            pressureHM(abs(StartIndHM)+1:end) = pressureTraceUnitary(1:lengthtouse);
            emgHM(1:abs(StartIndHM)) = NaN;
            emgHM(abs(StartIndHM)+1:end) = emgTraceUnitary(1:lengthtouse);
        end
    end
    TimeScaleHM = 1/SampleRate:1/SampleRate:(EndIndHM-StartIndHM)/SampleRate;
    SaveTraceNameHM = [Path, char(UnitaryName(i)), '_forHM', iteration, '.mat'];
    save(SaveTraceNameHM, 'emgHM', 'pressureHM', 'TimeScaleHM');
end

%Write event parameters
UnitaryParameterResults = array2table(UnitaryParameters,'VariableNames',{'UnitaryStartPressure', 'StartTime', 'StartPressure', 'RelativeStartPressure', 'EndTime', 'EndPressure', 'RelativeEndPressure', 'PeakTime', 'PeakPressure', 'RelativePeakPressure', 'TimeStartToPeak', 'TimePeakToEnd' 'Duration', 'Amplitude', 'RelaxTauTime', 'RelaxTauPressure', 'RelativeTauPressure', 'pressureRMS', 'pressureOffsetForAUC', 'pressureIntegral', 'pressureAUC', 'emgSumRMS', 'emgMeanRMS', 'emgCleanMeanRMS', 'emgCleanSumRMS', 'emgFirstBurstTime', 'emgCorrectedFirstBurstTime', 'emgFirstBurstPressure', 'emgRelativeFirstBurstPressure', 'emgBurstFrequencyHz', 'BladderComplianceEventStart'});
SaveName1 = [Path, SourceName, '_UnitaryParameters', '.xlsx'];
writetable(UnitaryParameterResults, SaveName1, 'WriteRowNames', 1);