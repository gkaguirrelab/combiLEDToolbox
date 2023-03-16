function analyzeFlickPhysioExperiment(subjectID,modDirection,varargin)
%
%
%{
    subjectID = 'HERO_gka';
    modDirection = 'LightFlux';
    analyzeFlickPhysioExperiment(subjectID,modDirection);
%}


% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
p.addParameter('projectName','combiLED',@ischar);
p.addParameter('approachName','flickerPhysio',@ischar);
p.addParameter('testContrastSet',[0.05,0.1,0.2,0.4,0.8],@isnumeric);
p.addParameter('testFreqSetHz',[4,6,10,14,20,28,40],@isnumeric);
p.addParameter('updateFigures',false,@islogical);
p.parse(varargin{:})

% Set our experimentName
experimentName = 'pilotLumFlicker';


dataDir = fullfile(...
    p.Results.dropBoxBaseDir,...
    p.Results.projectName,...
    p.Results.approachName,...
    subjectID,modDirection,experimentName);

Fs = 2000;
testFreqHz = 20;
sampleShift = -150;

clear data
for ii=1:40
    for jj=1:5
        fileName = fullfile(dataDir,'rawEEGData',sprintf('freq_20.0_contrast_0.750_trial_%02d_%02d.mat',ii,jj));
        load(fileName,'vepDataStruct');
        % Multiple by 100 to set as microvolt units
        signal = circshift(vepDataStruct.response*100,sampleShift);
        signal = signal-mean(signal);
        dataTimeAll(ii,jj,:) = signal;
        dataTimeOff(ii,jj,:) = signal(1:4000);
        [~, amp] = simpleFFT( signal(1:4000), 2000);
        dataFreqOff(ii,jj,:) = amp;
        dataTimeOn(ii,jj,:) = signal(4001:8000);
        [frq, amp] = simpleFFT( signal(4001:8000), 2000);
        dataFreqOn(ii,jj,:) = amp;
    end
end


% Fit the dataTimeOff and On with a Fourier regressor
xFull = vepDataStruct.timebase;
xHalf = vepDataStruct.timebase(1:4000);

% Create the half-cosine ramp
ramp = ones(size(xHalf));
rampDur = 0.1;
ramp(1:rampDur*Fs)=(cos(pi+pi*(1:rampDur*Fs)/(rampDur*Fs))+1)/2;
ramp(length(ramp)-rampDur*Fs+1:end)=(cos(pi*(1:rampDur*Fs)/(rampDur*Fs))+1)/2;

X(:,1) = ramp.*sin(2*2*pi*(xHalf./max(xHalf))*testFreqHz);
X(:,2) = ramp.*cos(2*2*pi*(xHalf./max(xHalf))*testFreqHz);

figHandle = figure;
figuresize(600,300,'pt');
t = tiledlayout(2,2);
t.TileSpacing = 'compact';
t.Padding = 'compact';

nexttile([1,2]);

% Put up a patch to indicate the stimulus period
[~,xIdx] = min(abs(xFull-2));
pHandle = patch( ...
    [xFull(xIdx),xFull(xIdx),xFull(end),xFull(end)], ...
    [-4 4 4 -4],'b','EdgeColor','none','FaceColor','b','FaceAlpha',0.05);
hold on

meanData = squeeze(mean(mean(dataTimeAll),2));
plot(xFull,meanData,'-','Color',[0.75 0.75 0.75],'LineWidth',1.25);
meanData = squeeze(mean(mean(dataTimeOff),2));
b(:,1)=X\meanData;
fitY = X*b(:,1);
plot(xHalf,fitY,'-r','LineWidth',1.25)
meanData = squeeze(mean(mean(dataTimeOn),2));
b(:,2)=X\meanData;
fitY = X*b(:,2);
plot(xHalf+2,fitY,'-r','LineWidth',1.25)
ylim([-4 4]);
xlabel('time [secs]');
ylabel('μ volts');
hold on

for pp = 1:2
    nexttile;
    a=gca();
    a.XScale='log';
    if pp == 1
        meanData = squeeze(mean(mean(dataFreqOff),2))/2000;
    else
        meanData = squeeze(mean(mean(dataFreqOn),2))/2000;
    end

    % Nan the multiples of 60 Hz
    for ii=1:15
        idx = abs(frq-60*ii)<1.5;
        meanData(idx)=nan;
    end

    % Put up a patch to indicate the stimulus freq
    [~,xIdx] = min(abs(frq-testFreqHz));
    pHandle = patch( ...
        [frq(xIdx-3),frq(xIdx-3),frq(xIdx+3),frq(xIdx+3)], ...
        [0 2 2 0],'r','EdgeColor','none','FaceColor','r','FaceAlpha',0.1);

    hold on

    semilogx(frq,meanData,'-','Color',[0.25 0.25 0.25],'LineWidth',1.25);

    a.XTick = [1 20 100];
    a.XTickLabel = {'1','20','100'};
    xlabel('log freq [Hz]');
    ylabel('μ volts');
    ylim([0 2]);
end

end
