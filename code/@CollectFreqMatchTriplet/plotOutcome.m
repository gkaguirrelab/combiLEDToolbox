function plotOutcome(obj)

% Grab some variables
questData = obj.questData;
ReferenceFrequencySet = obj.ReferenceFrequencySet;
TestFrequency = obj.TestFrequency;

% Transform the ReferenceFrequencySet
ReferenceFrequencySet = obj.forwardTransformVals(ReferenceFrequencySet,TestFrequency);

% Plot trial locations together with maximum likelihood fit. Point
% transparancy visualizes number of trials (more opaque -> more trials),
% while point color visualizes percent correct (more blue -> more R1).
figure; 
subplot(1,3,1);
hold on
stimCounts = qpCounts(qpData(questData.trialData),questData.nOutcomes);
stim = zeros(length(stimCounts),questData.nStimParams);
for cc = 1:length(stimCounts)
    stim(cc,:) = stimCounts(cc).stim;
    nTrials(cc) = sum(stimCounts(cc).outcomeCounts);
    pChooseR2(cc) = stimCounts(cc).outcomeCounts(2)/nTrials(cc);
end
markerSizeIdx = discretize(nTrials,3);
markerSizeSet = [25,50, 100];
for cc = 1:length(stimCounts)
    scatter(stim(cc,2),stim(cc,1),markerSizeSet(markerSizeIdx(cc)),'o', ...
        'MarkerFaceColor',[pChooseR2(cc) 0 1-pChooseR2(cc)], ...
        'MarkerEdgeColor','k', ...
        'MarkerFaceAlpha',nTrials(cc)/max(nTrials));
    hold on
end
axis square
xlim([min(ReferenceFrequencySet)*1.1, max(ReferenceFrequencySet)]*1.1);
ylim([min(ReferenceFrequencySet)*1.1, max(ReferenceFrequencySet)]*1.1);
xlabel('ref2 [difference in log freq from test]');
ylabel('ref1 [difference in log freq from test]');
set(gca, 'YDir','reverse')
title('red choose R2; blue choose R1')

subplot(1,3,2);
hold on
% Get the Max Likelihood psi params
storeVerbose = obj.verbose;
obj.verbose = false;
[~, psiParamsFit] = obj.reportParams;
obj.verbose = storeVerbose;

% Plot the psychometric matrix
for r1 = ReferenceFrequencySet
    for r2 = ReferenceFrequencySet
        pChooseR2 = qpPFJoganStocker([r1,r2],psiParamsFit);
        h = scatter(r2,r1,100,'o','MarkerEdgeColor','none','MarkerFaceColor',[pChooseR2(2) 0 pChooseR2(1)],...
            'MarkerFaceAlpha',1,'MarkerEdgeAlpha',1);
    end
end
axis square
xlim([min(ReferenceFrequencySet)*1.1, max(ReferenceFrequencySet)]*1.1);
ylim([min(ReferenceFrequencySet)*1.1, max(ReferenceFrequencySet)]*1.1);
xlabel('ref2 [difference in log freq from test]');
ylabel('ref1 [difference in log freq from test]');
set(gca, 'YDir','reverse')
title('red choose R2; blue choose R1')

subplot(1,3,3);
hold on
plot(1:length(questData.entropyAfterTrial),questData.entropyAfterTrial,'.k');
axis square
xlabel('trial number');
ylabel('entropy');
title('Entropy as a function of trial number')

end