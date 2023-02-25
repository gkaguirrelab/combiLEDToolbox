function figHandle = plotOutcome(obj,visible)

if nargin==1
    visible='on';
end

% Grab some variables
questData = obj.questData;
TestContrastSet = obj.TestContrastSet;
TestFrequency = obj.TestFrequency;

% Plot trial locations together with maximum likelihood fit. Point
% transparancy visualizes number of trials (more opaque -> more trials),
% while point color visualizes percent correct (more blue -> more R1).
figHandle = figure('visible',visible);
figuresize(750,250,'units','pt');

subplot(1,3,1);
hold on
plot([obj.questData.trialData.stim],'.r');

subplot(1,3,2);
hold on
stimCounts = qpCounts(qpData(questData.trialData),questData.nOutcomes);
stim = zeros(length(stimCounts),questData.nStimParams);
for cc = 1:length(stimCounts)
    stim(cc) = stimCounts(cc).stim;
    nTrials(cc) = sum(stimCounts(cc).outcomeCounts);
    pCorrect(cc) = stimCounts(cc).outcomeCounts(2)/nTrials(cc);
end
markerSizeIdx = discretize(nTrials,3);
markerSizeSet = [25,50,100];
for cc = 1:length(stimCounts)
    scatter(stim(cc),pCorrect(cc),markerSizeSet(markerSizeIdx(cc)),'o', ...
        'MarkerFaceColor',[pCorrect(cc) 0 1-pCorrect(cc)], ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',nTrials(cc)/max(nTrials));
    hold on
end
% Get the Max Likelihood psi params
storeVerbose = obj.verbose;
obj.verbose = false;
[~, psiParamsFit] = obj.reportParams;
obj.verbose = storeVerbose;
% Plot the psychometric matrix
for r1 = 1:length(TestContrastSet)
        outcomes = obj.questData.qpPF(TestContrastSet(r1),psiParamsFit);
        fitCorrect(r1) = outcomes(2);
end
plot(TestContrastSet,fitCorrect,'-k')

subplot(1,3,3);
hold on
plot(1:length(questData.entropyAfterTrial),questData.entropyAfterTrial,'.k');
xlabel('trial number');
ylabel('entropy');
title('Entropy by trial number')

% Add a supertitle
str = sprintf('Freq = %d Hz; params = [%2.3f, %2.3f, %2.3f, %2.3f]',...
    obj.TestFrequency,psiParamsFit);
sgtitle(str);

end