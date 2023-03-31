function analyzeVEPTCSFExperiment(subjectID,modDirection,varargin)
%
%
%{
    subjectID = 'HERO_gka1';
    modDirection = 'LightFlux';
    analyzeVEPTCSFExperiment(subjectID,modDirection);
%}


% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
p.addParameter('projectName','combiLED',@ischar);
p.addParameter('approachName','flickerPhysio',@ischar);
p.addParameter('stimContrastSet',[0,0.05,0.1,0.2,0.4,0.8],@isnumeric);
p.addParameter('stimFreqSetHz',[4,6,10,14,20,28,40],@isnumeric);
p.parse(varargin{:})

% Set our experimentName
experimentName = 'ssVEPTCSF';

% Define a location to save data
modDir = fullfile(...
    p.Results.dropBoxBaseDir,...
    'MELA_data',...
    p.Results.projectName,...
    p.Results.approachName,...
    subjectID,modDirection);

dataDir = fullfile(modDir,experimentName);

% Get the stimulus values
stimFreqSetHz = p.Results.stimFreqSetHz;
stimContrastSet = p.Results.stimContrastSet;

Fs = 2000;
sampleShift = -150;
stimDurSecs = 2;

% Load the measurementRecord
filename = fullfile(dataDir,'measurementRecord.mat');
load(filename,'measurementRecord');
nTrials = length(measurementRecord.trialData);

% Get the carry-over matrix
emptyDataMatrix = cell(length(stimContrastSet),length(stimContrastSet));
contrastCarryOverRaw = cell(length(stimFreqSetHz));
for tt = 1:nTrials
    stimFreqHz = measurementRecord.trialData(tt).stimFreqHz;
    ff = find(stimFreqSetHz==stimFreqHz);
    if isempty(contrastCarryOverRaw{ff})
        dataMatrix = emptyDataMatrix;
    else
        dataMatrix = contrastCarryOverRaw{ff};
    end
    stimContrastOrder = measurementRecord.trialData(tt).stimContrastOrder;
    for ss = 2:length(stimContrastOrder)
        filename = sprintf('freq_%2.1f_trial_%02d_contrast_%2.1f_stim_%02d.mat',...
            stimFreqSetHz(ff),...
            tt,...
            stimContrastSet(stimContrastOrder(ss)),...
            ss );
        load(fullfile(dataDir,'rawEEGData',filename),'vepDataStruct');

        % Multiple by 100 to set as microvolt units
        signal = circshift(vepDataStruct.response*100,sampleShift);
        signal = signal-mean(signal);

        % Add to the data
        rr = stimContrastOrder(ss-1);
        cc = stimContrastOrder(ss);

        if isempty(dataMatrix{rr,cc})
            dataMatrix{rr,cc} = signal;
        else
            signalMat = dataMatrix{rr,cc};
            signalMat(end+1,:) = signal;
            dataMatrix{rr,cc} = signalMat;
        end
    end
    contrastCarryOverRaw{ff}=dataMatrix;
end

% Save a timebase
xTime = vepDataStruct.timebase;

% Create the half-cosine ramp
ramp = ones(size(xTime));
rampDur = 0.1;
ramp(1:rampDur*Fs)=(cos(pi+pi*(1:rampDur*Fs)/(rampDur*Fs))+1)/2;
ramp(length(ramp)-rampDur*Fs+1:end)=(cos(pi*(1:rampDur*Fs)/(rampDur*Fs))+1)/2;

% Now get the amplitude in each matrix
contrastCarryOverAmplitude = cell(1,length(stimFreqSetHz));
for ff = 1:length(stimFreqSetHz)

    % Get this data matrix
    dataMatrix = contrastCarryOverRaw{ff};

        % Create the X regression matrix
        X(:,1) = ramp.*sin(stimDurSecs*2*pi*(xTime./max(xTime))*stimFreqSetHz(ff));
        X(:,2) = ramp.*cos(stimDurSecs*2*pi*(xTime./max(xTime))*stimFreqSetHz(ff));
        X(:,3) = ramp.*sin(2*stimDurSecs*2*pi*(xTime./max(xTime))*stimFreqSetHz(ff));
        X(:,4) = ramp.*cos(2*stimDurSecs*2*pi*(xTime./max(xTime))*stimFreqSetHz(ff));

        % Loop through rows and columns
        ampMatrix = [];
        for rr=1:length(stimContrastSet)
        for cc=1:length(stimContrastSet)
            signalMat = dataMatrix{rr,cc};
               meanData = mean(signalMat)';
            b=X\meanData; 
            ampMatrix(rr,cc) = norm(b);
        end
        end
    contrastCarryOverAmplitude{ff}= ampMatrix;
end

% Create the average carry-over effect across frequencies
averageCarryOverEffect = zeros(length(stimContrastSet),length(stimContrastSet));
for ff=1:length(stimFreqSetHz)
    k=contrastCarryOverAmplitude{ff};
    k=k./max(k(:));
    averageCarryOverEffect=averageCarryOverEffect+k;
end
averageCarryOverEffect = averageCarryOverEffect/length(stimFreqSetHz);


% Loop through the stimuli
dataTime = cell(length(stimFreqSetHz),length(stimContrastSet));
dataFourier = cell(length(stimFreqSetHz),length(stimContrastSet));

for ff = 1:length(stimFreqSetHz)
    for cc = 1:length(stimContrastSet)
        for tt = 1:nTrials
            if measurementRecord.trialData(tt).stimFreqHz == stimFreqSetHz(ff)
                stimContrastOrder = measurementRecord.trialData(tt).stimContrastOrder;
                stimIdx = find(stimContrastOrder == cc);
                stimIdx = stimIdx(stimIdx~=1);
                for ss=1:length(stimIdx)
                    filename = sprintf('freq_%2.1f_trial_%02d_contrast_%2.1f_stim_%02d.mat',...
                        stimFreqSetHz(ff),...
                        tt,...
                        stimContrastSet(cc),...
                        stimIdx(ss) );
                    load(fullfile(dataDir,'rawEEGData',filename),'vepDataStruct');

                    % Multiple by 100 to set as microvolt units
                    signal = circshift(vepDataStruct.response*100,sampleShift);
                    signal = signal-mean(signal);
                    [frq,amp] = simpleFFT(signal, Fs);

                    % Add to the data
                    if isempty(dataTime{ff,cc})
                        dataTime{ff,cc} = signal;
                        dataFourier{ff,cc} = amp;
                    else
                        signalMat = dataTime{ff,cc};
                        signalMat(end+1,:) = signal;
                        dataTime{ff,cc} = signalMat;
                        signalMat = dataFourier{ff,cc};
                        signalMat(end+1,:) = amp;
                        dataFourier{ff,cc} = signalMat;
                    end
                end
            end
        end
    end
end

% Save the xFreq
xFreq = frq;


%% Sub-plots of the SPDs and average response
% Loop through frequencies and contrasts and obtain the amplitude of the
% evoked response
f1 = figure();
t = tiledlayout(length(stimContrastSet),length(stimFreqSetHz));
t.TileSpacing = 'compact';
t.Padding = 'compact';

f2 = figure();
t = tiledlayout(length(stimContrastSet),length(stimFreqSetHz));
t.TileSpacing = 'compact';
t.Padding = 'compact';


avgResponse = [];
for cc = 1:length(stimContrastSet)
    for ff = 1:length(stimFreqSetHz)

        % Get this signal matrix
        signalMat = dataTime{ff,cc};

        % Create the X regression matrix
        X(:,1) = ramp.*sin(stimDurSecs*2*pi*(xTime./max(xTime))*stimFreqSetHz(ff));
        X(:,2) = ramp.*cos(stimDurSecs*2*pi*(xTime./max(xTime))*stimFreqSetHz(ff));
        X(:,3) = ramp.*sin(2*stimDurSecs*2*pi*(xTime./max(xTime))*stimFreqSetHz(ff));
        X(:,4) = ramp.*cos(2*stimDurSecs*2*pi*(xTime./max(xTime))*stimFreqSetHz(ff));

        % Bootstrap the Fourier regression fit
        for bb = 1:1000
            bootIdx = datasample(1:size(signalMat,1),size(signalMat,1));
            meanData = mean(signalMat(bootIdx,:))';
            b(:,bb)=X\meanData;
        end
        fitY = X*mean(b,2);
        phaseVec = sort(-atan(b(2,:)./b(1,:)));
        avgPhase(ff,cc) = mean(phaseVec);
        harmonicRatioVec = sort(vecnorm(b(3:4,:),2,1)./vecnorm(b(1:2,:),2,1));
        avgHarmonicRatio(ff,cc) = mean(harmonicRatioVec);
        avgHarmonicRatioLow(ff,cc) = harmonicRatioVec(50);
        avgHarmonicRatioHigh(ff,cc) = harmonicRatioVec(950);
        respVec = sort(vecnorm(b,2,1));
        avgBetas(ff,cc,:)=mean(b,2);
        semBetas(ff,cc,:)=std(b,0,2);
        avgResponse(ff,cc)=mean(respVec);
        avgResponseLow(ff,cc)=respVec(50);
        avgResponseHigh(ff,cc)=respVec(950);

        % Plot the mean response and fit
        figure(f1);
        nexttile
        plot(xTime,meanData,'-','Color',[0.75 0.75 0.75],'LineWidth',1.25);
        hold on
        plot(xTime,fitY,'-','Color','r','LineWidth',1.25);
        ylim([-5 5]);
        if cc==1
            title(sprintf('freq %2.2f',stimFreqSetHz(ff)))
            if ff==1
                xlabel('time [secs]')
                ylabel('microvolts')
            end
        end

        % Plot the mean psd
        signalMat = dataFourier{ff,cc};
        meanData = mean(signalMat)'/length(xFreq);

        % Nan the multiples of 60 Hz
        for ii=1:15
            idx = abs(frq-60*ii)<1.5;
            meanData(idx)=nan;
        end

        figure(f2);
        nexttile
        a=gca();
        a.XScale='log';

        % Put up a patch to indicate the stimulus freq
        for hh = 1:2
            [~,xIdx] = min(abs(xFreq-hh*stimFreqSetHz(ff)));
            pWidth = 1;
            patch( ...
                [xFreq(xIdx)*0.9,xFreq(xIdx)*0.9,xFreq(xIdx)*1.1,xFreq(xIdx)*1.1], ...
                [0 3 3 0],'r','EdgeColor','none','FaceColor','r','FaceAlpha',0.1);
            hold on
        end
        plot(xFreq,meanData,'-','Color',[0.25 0.25 0.25],'LineWidth',1.25);
        ylim([0 3]);
        xlim([0.5 200]);

    end
end


%% Temporal sensitivity
figure
logX = log10(stimFreqSetHz);
logX(1) = 0.4;
cmap = cool;
for cc = 1:length(stimContrastSet)
    vec = avgResponse(:,cc);
    color = cmap(1+255*((cc-1)/(length(stimContrastSet)-1)),:);
    if cc==1
        low = mean(avgResponseLow(:,cc));
        high = mean(avgResponseHigh(:,cc));
        patch(...
            [logX(1),logX(1),logX(end),logX(end)],...
            [low high high low],'g','EdgeColor','none','FaceColor','r','FaceAlpha',0.1);
        hold on
    else
        plot(logX,vec,'-','Color',color)
        hold on
        for ff = 1:length(stimFreqSetHz)
            plot([logX(ff) logX(ff)],[avgResponseLow(ff,cc) avgResponseHigh(ff,cc)],'-','Color',color,'LineWidth',2)
            plot(logX(ff),avgResponse(ff,cc),'.','Color',color,'MarkerSize',20)
        end
    end
end
xlabel('log freq [Hz]')
ylabel('amplitude [micro volts]')


%% Contrast response function
figure
logX = log10(stimContrastSet);
logX(1) = -1.6;
cmap = cool;
for ff = 1:length(stimFreqSetHz)
    color = cmap(round(1+255*((ff-1)/(length(stimFreqSetHz)-1))),:);
    vec = avgResponse(ff,:);
    vec = vec ./ max(vec);
    plot(logX,vec,'-','Color',color)
    hold on
    plot(logX,vec,'.','Color',color,'MarkerSize',20)
end
xlabel('log contrast');
ylabel('relative response');


%% Relative contribution of 2nd harmonic
figure
logX = log10(stimFreqSetHz);
logX(1) = 0.4;
cmap = cool;
for cc = 6:length(stimContrastSet)
    color = cmap(1+255*((cc-1)/(length(stimContrastSet)-1)),:);
    vec = avgHarmonicRatio(:,cc);
    plot(logX,vec,'-','Color',color)
    hold on
    for ff = 1:length(stimFreqSetHz)
        plot([logX(ff) logX(ff)],[avgHarmonicRatioLow(ff,cc) avgHarmonicRatioHigh(ff,cc)],'-','Color',color,'LineWidth',2)
        plot(logX(ff),avgHarmonicRatio(ff,cc),'.','Color',color,'MarkerSize',20)
    end
end
xlabel('log freq [Hz]')
ylabel('h2 amp / h1 amp')


%% Carry-over figure
figure
figuresize(325,400,'pt')
subplot(5,4,[1 2 3]);
logX = log10(stimContrastSet);
logX(1) = -1.6;
meanZeroContrast = mean(averageCarryOverEffect(:,1));
plot([min(logX),max(logX)],[meanZeroContrast,meanZeroContrast],':k')
hold on
plot(logX,mean(averageCarryOverEffect),'-k','LineWidth',2);
ylabel('response');
xlabel('contrast')
ylim([0 1]);
xlim([min(logX)-mean(diff(logX))/2, max(logX)+mean(diff(logX))/2]);
a = gca();
a.XAxis.Visible = 'off';
box off


subplot(5,4,[8 12 16]);
logX = log10(stimContrastSet);
logX(1) = -1.6;
meanVal = mean(averageCarryOverEffect(:));
plot([0 0],[min(logX) max(logX)],':k')
hold on
plot(mean(averageCarryOverEffect,2)-meanVal,logX,'-k','LineWidth',2);
xlabel('modulation');
ylabel('contrast')
xlim([-0.1 +0.1]);
ylim([min(logX)-mean(diff(logX))/2, max(logX)+mean(diff(logX))/2]);
a = gca();
a.YAxisLocation = "right";
a.YAxis.Visible = 'off';
box off

% Color map
subplot(5,4,[5 6 7 9 10 11 13 14 15]);
cmap = [ linspace(0,1,255);[linspace(0,0.5,127) linspace(0.5,0,128)];[linspace(0,0.5,127) linspace(0.5,0,128)]]';
im = 2*(averageCarryOverEffect - 0.5);
im = round(im * 128 + 128);
image(im);
colormap(cmap)
axis normal
a = gca();
a.YDir = 'normal';
a.XTick = 1:length(stimContrastSet);
a.YTick = 1:length(stimContrastSet);
a.XTickLabels = arrayfun(@(x) {num2str(x)},stimContrastSet);
a.YTickLabels = arrayfun(@(x) {num2str(x)},stimContrastSet);
a.XAxis.TickLength = [0 0];
a.YAxis.TickLength = [0 0];
xlabel('current contrast');
ylabel('prior contrast');
box off

subplot(5,4,[17 18 19]);
hCB = colorbar('south','AxisLocation','in');
hCB.Label.String = 'relative ssVEP response';
set(gca,'Visible',false)

end
