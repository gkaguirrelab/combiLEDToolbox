function createVisualDietFigure(subjectID,sessionDate,varargin)

%{
subjectID = 'HERO_gka1';
sessionDate = '29-03-2023';
createVisualDietFigure(subjectID,sessionDate);
%}

% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
p.addParameter('projectName','combiLED',@ischar);
p.addParameter('approachName','environmentalSampling',@ischar);
p.addParameter('fps',100,@isnumeric);
p.addParameter('windowDurSecs',100,@isnumeric);
p.addParameter('windowStepSecs',25,@isnumeric);
p.parse(varargin{:})

windowStepSecs = p.Results.windowStepSecs;

% Path to the data
dataDir = fullfile(p.Results.dropBoxBaseDir,...
    'MELA_data',...
    p.Results.projectName,...
    p.Results.approachName,...
    subjectID,sessionDate);

analysisDir = fullfile(p.Results.dropBoxBaseDir,...
    'MELA_analysis',...
    p.Results.projectName,...
    p.Results.approachName,...
    subjectID,sessionDate);

% Get the list of videos
videoDir = fullfile(dataDir,'videos');
videoList =dir(fullfile(videoDir,'*','*.avi'));

% Set up a cell array to hold all of the spectrograms
allSpectrograms = cell(1,length(videoList));

% Load the spectrograms
for cc = 1:3
    spectSet{cc} = [];
end
for vv = 1:length(videoList)
    resultFilename = fullfile(analysisDir,[videoList(vv).name '_spectrogram.mat']);

    load(resultFilename,'spectrogram','frq');

    % log-transform and smooth the spectrogram
    for cc=1:3
        k = log10(squeeze(spectrogram(cc,:,:)));
        s = size(k);
        k = reshape(smooth(k(:),10),s(1),s(2));
        spectSet{cc} = [spectSet{cc},k'];
    end

end % Loop over the videos

% Get the irradiance
[xHours,totalIrradianceVec]=processActLumusRecording(subjectID,sessionDate);

% Code the activity
indoorMinuteIdx = [1:53,74:121,148:156,161:163,167:172,195:241];
outdoorMinuteIdx = [54:73,122:147,157:160,164:166,173:194];
walkingMinuteIdx = [1:7,42:62,73:77,122:126,147:172,192:205];
sittingMinuteIdx = [8:41,63:72,78:121,206:241];
drivingMinuteIdx = [127:146,173:191];


figure

subplot(5,1,1);
plot(indoorMinuteIdx,repmat(2,size(indoorMinuteIdx)),'.','Color',[0.25 0.25 0.25]);
hold on
plot(outdoorMinuteIdx,repmat(2,size(outdoorMinuteIdx)),'.','Color',[0.95 0.95 0.95]);
plot(walkingMinuteIdx,repmat(1,size(walkingMinuteIdx)),'.','Color','y');
plot(sittingMinuteIdx,repmat(1,size(sittingMinuteIdx)),'.','Color','r');
plot(drivingMinuteIdx,repmat(1,size(drivingMinuteIdx)),'.','Color','g');
xlim([1 241]);
ylim([0 5]);
axis off

xFreq = frq(101:end);
subplot(5,1,2);
semilogy(xHours,smooth(totalIrradianceVec,25),'-','Color',[0.25 0.25 0.25],'LineWidth',1.5);
ylabel('log irradiance [W/m2]');
xlim([0 max(xHours)]);
ylim([10^0 10^5])
    a = gca;
    a.TickDir = 'out';
    box off

for cc = 1:3
    subplot(5,1,cc+2);
    k = spectSet{cc};
    k = k(101:end,:);
    imagesc(k(101:end,:));
    a = gca;
    a.TickDir = 'out';
    a.YDir = 'normal';
    a.YTick = [1,901,1901:1000:length(xFreq)];
    a.YTickLabel = arrayfun(@(x) {num2str(x)},xFreq(a.YTick));
    ylim([1 length(xFreq)+1])
    a.XTick = 1:(60*60)/windowStepSecs:(60*60/windowStepSecs)*round((size(k,2)*windowStepSecs)/60/60);
    a.XTickLabel = arrayfun(@(x) {num2str(x)},0:round((size(k,2)*windowStepSecs)/60/60));
    ylabel('Freq [Hz]');
    xlim([1 (60*60/windowStepSecs)*round((size(k,2)*windowStepSecs)/60/60)]);
    xlabel('time [hours]')
    if cc < 3
        axis off
    else
    box off
    end

end
colormap(turbo);

end % Function


