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
    plotColors = {'k','r','b'};
    for cc=1:3
        k = log10(squeeze(spectrogram(cc,:,:)));
        s = size(k);
        k = reshape(smooth(k(:),10),s(1),s(2))';
        spectSet{cc} = [spectSet{cc},k,nan(size(k,1),4)];
        %        loglog(frq(OneHzIdx:end),mean(squeeze(spectrogram(cc,:,OneHzIdx:end)),1),['-' plotColors{cc}]); hold on;
    end

end

% Get the irradiance and activity
[xHours,totalIrradianceVec,activityVec]=processActLumusRecording(subjectID,sessionDate);

% Code the activity; 1 = walking, 2 = sitting, 3 = driving. These are
% values taken from my notes / diary during data collection
indoorMinuteIdx = {1:55,74:123,148:156,160:162,167:172,195:241};
activityIdx = {1:7,8:41,42:64,65:72,73:77,78:121,122:127,128:146,147:172,173:191,192:200,201:241};
activityCode = {1,2,1,2,1,2,1,3,1,3,1,2};
activityColor = {'b','w','r'};

% Set up the figure
f1 = figure();
figuresize(400,600,'pt');
t = tiledlayout(6,1);
t.TileSpacing = 'tight';
t.Padding = 'none';

% Define the time domain of the data
[~,xLimIdx] = min(abs(xHours*60-(3200*4)));

% Irradiance and indoor/outdoor status
nexttile;

% Patches to indicate inside / outside
a = gca();
a.YScale = 'log';
for pp = 1:length(indoorMinuteIdx)
    idx1 = min(indoorMinuteIdx{pp}) / 60;
    idx2 = max(indoorMinuteIdx{pp}) / 60;
    patch( ...
        [idx1,idx1,idx2,idx2], ...
        [10^0 10^5 10^5 10^0],'k','EdgeColor','none','FaceColor','k','FaceAlpha',0.1);
    hold on
end

% The irradiance vector
semilogy(xHours,smooth(totalIrradianceVec,25),'-','Color',[0.25 0.25 0.25],'LineWidth',1.5);
ylabel({'log irradiance','[W/m2]'});
xlim([0 xHours(xLimIdx)]);
ylim([10^0 10^5])
a = gca;
a.TickDir = 'out';
a.XTick = [];
box off

% Activity
nexttile;

for pp = 1:length(activityIdx)
    idx1 = min(activityIdx{pp}) / 60;
    idx2 = max(activityIdx{pp}) / 60;
    patch( ...
        [idx1,idx1,idx2,idx2], ...
        [0 20 20 0],activityColor{activityCode{pp}},'EdgeColor','none','FaceColor',activityColor{activityCode{pp}},'FaceAlpha',0.1);
    hold on
end

% The activity vector
plot(xHours,smooth(activityVec,25),'-','Color',[0.25 0.25 0.25],'LineWidth',1.5);
ylabel({'activity'});
xlim([0 xHours(xLimIdx)]);
a = gca;
a.TickDir = 'out';
a.XTick = [];
a.YTick = [];
box off

% The three spectrograms
yAxisVals = [0.1,1,10,50];
xFreq = frq(LowestFreqIdx:end);
directions = {'LMS','L–M','S'};
imageHandles = gobjects(0);
for cc = 1:3
    nexttile([1 1]);
    k = spectSet{cc};
    k = k(LowestFreqIdx:end,:);
    k(k< -2)=-2; k(k>2)=2;
    [~,imageHandles(end+1)]=contourf(k,25,'LineStyle','none');
    a = gca;
    a.YScale='log';
    a.TickDir = 'out';
    colormap(turbo)
    clim([-2 2]);
    for ff = 1:length(yAxisVals)
        [~,yTickVals(ff)] = min(abs(yAxisVals(ff)-xFreq));
    end
    a.YTick = yTickVals;
    a.YTickLabel = arrayfun(@(x) {num2str(x)},yAxisVals);
    ylim([1 length(xFreq)+1])
    thirtyMins = (30*60)/windowStepSecs;
    a.XTick = 1:thirtyMins:thirtyMins*ceil((size(k,2)/thirtyMins));
    a.XTickLabel = arrayfun(@(x) {num2str(x)},0:0.5:(1+length(a.XTick))*0.5);
    ylabel('Freq [Hz]');
    xlabel('time [hours]')
    box off
    if cc ~= 1
        a.YTick = [];
        ylabel('')
    end
    if cc ~= 3
        a.XTick = [];
        xlabel('')
    end
end

nexttile;
hCB = colorbar('north','AxisLocation','in');
hCB.Label.String = 'log contrast';
hCB.Ticks = [0 0.25 0.5 0.75 1];
hCB.TickLabels = {'-2','-1','0','1','2'};
set(gca,'Visible',false)
colormap(turbo);
axis off

if p.Results.savePlots
    filename = [subjectID '_' sessionDate '_' 'visualDiet.png'];
    export_fig(f1,fullfile(analysisDir,filename),'-r600','-opengl');

    hidem(imageHandles);
    nexttile(5)
    a = gca;
    plot([min(a.XTick) max(a.XTick)],[1 1],'-r');
    a.XTick = 1:thirtyMins:thirtyMins*ceil((size(k,2)/thirtyMins));
    a.XTickLabel = arrayfun(@(x) {num2str(x)},0:0.5:(1+length(a.XTick))*0.5);
    ylabel('Freq [Hz]');
    xlabel('time [hours]')
    box off
    a.YTick = [];
    ylabel('')
    for cc = 1:3; nexttile(cc+2); title(directions{cc}); end

    filename = [subjectID '_' sessionDate '_' 'visualDiet.pdf'];
    export_fig(f1,fullfile(analysisDir,filename),'-Painters');

end

end % Function


