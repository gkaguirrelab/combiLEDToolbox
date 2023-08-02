function createSPDsByIlluminanceFigurePDF(subjectID,sessionDate,varargin)

%{
subjectID = 'HERO_gka1';
sessionDate = '29-03-2023';
createSPDsByIlluminanceFigurePDF(subjectID,sessionDate);
%}

% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
p.addParameter('projectName','combiLED',@ischar);
p.addParameter('approachName','environmentalSampling',@ischar);
p.addParameter('fps',112.5,@isnumeric);
p.addParameter('windowDurFrames',1200,@isnumeric);
p.addParameter('windowStepFrames',600,@isnumeric);
p.addParameter('savePlots',true,@islogical);
p.parse(varargin{:})

windowStepSecs = p.Results.windowStepFrames/p.Results.fps;

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


% Initialize a cell variable. This is kinda ugly code
for cc = 1:3; spectSet{cc} = []; end

% Load and clean the spectrograms
for vv = 1:length(videoList)
    resultFilename = fullfile(analysisDir,[videoList(vv).name '_spectrogram.mat']);

    load(resultFilename,'spectrogram','frq');
    LowestFreqIdx = 2;

    % log-transform and smooth the spectrogram
    for cc=1:3
        k = log10(squeeze(spectrogram(cc,:,:)));
        s = size(k);
        k = reshape(smooth(k(:),10),s(1),s(2))';
        spectSet{cc} = [spectSet{cc},k,nan(size(k,1),4)];
    end

end

% Get the illuminance vec
[xHours,totalIrradianceVec,activityVec]=processActLumusRecording(subjectID,sessionDate);
totalIrradianceVec = smooth(totalIrradianceVec,25);
activityVec = smooth(activityVec,25);


downSampIrr = interp1(linspace(0,1,6401),totalIrradianceVec,linspace(0,1,2412));
downSampAct = interp1(linspace(0,1,6401),activityVec,linspace(0,1,2412));

lowIrr = downSampIrr < median(downSampIrr);
HiIrr = downSampIrr > median(downSampIrr);

lowAct = downSampAct < median(downSampAct);
HiAct = downSampAct > median(downSampAct);

% Set up the figure
f1 = figure();
figuresize(200,200,'pt');
set(gcf,'color','w');

% The three spectrograms
xAxisVals = [0.1,1,10,50];
xFreq = frq(LowestFreqIdx:end);
directions = {'LMS','L–M','S'};
plotColors = {'k','r','b'};
for cc = 1:2
    thisSpect = spectSet{cc};
    k=mean(thisSpect(:,HiAct),2,'omitmissing');
    semilogx(xFreq(1:end-1),k(2:end-1),'-','Color',plotColors{cc},'LineWidth',2);
    hold on
    k=mean(thisSpect(:,lowAct),2,'omitmissing');
    plot(xFreq(1:end-1),k(2:end-1),'-','Color',plotColors{cc},'LineWidth',1);
end

a = gca;
a.TickDir = 'out';
a.XTick = xAxisVals;
a.XTickLabel = arrayfun(@(x) {num2str(x)},xAxisVals);
a.YTick = [-2 -1 0 1];
xlim([0.1 50]);
xlabel('Frequency [Hz]');
ylabel('log contrast')
box off
axis square
title({'Temporal power spectra of','natural environment at','lowest spatial frequency'})

if p.Results.savePlots
    filename = [subjectID '_' sessionDate '_' 'environmentSPDbyActivity.pdf'];
    export_fig(f1,fullfile(analysisDir,filename),'-Painters','-transparent');
end


% Set up the figure
f1 = figure();
figuresize(200,200,'pt');
set(gcf,'color','w');

% The three spectrograms
xAxisVals = [0.1,1,10,50];
xFreq = frq(LowestFreqIdx:end);
directions = {'LMS','L–M','S'};
plotColors = {'k','r','b'};
for cc = 1:2
    thisSpect = spectSet{cc};
    k=mean(thisSpect(:,HiIrr),2,'omitmissing');
    semilogx(xFreq(1:end-1),k(2:end-1),'-','Color',plotColors{cc},'LineWidth',2);
    hold on
    k=mean(thisSpect(:,lowIrr),2,'omitmissing');
    plot(xFreq(1:end-1),k(2:end-1),'-','Color',plotColors{cc},'LineWidth',1);
end

a = gca;
a.TickDir = 'out';
a.XTick = xAxisVals;
a.XTickLabel = arrayfun(@(x) {num2str(x)},xAxisVals);
a.YTick = [-2 -1 0 1];
xlim([0.1 50]);
xlabel('Frequency [Hz]');
ylabel('log contrast')
box off
axis square
title({'Temporal power spectra of','natural environment at','lowest spatial frequency'})

if p.Results.savePlots
    filename = [subjectID '_' sessionDate '_' 'environmentSPDbyIlluminance.pdf'];
    export_fig(f1,fullfile(analysisDir,filename),'-Painters','-transparent');
end



end % Function


