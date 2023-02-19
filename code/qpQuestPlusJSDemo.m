% Simulate an observer and test the Jogan & Stocker 2014 function

% Housekeeping
close all; clear;

% qpRun estimate of parameters of Jogan & Stocker function. The psiParams
% correspond to the noise sigma for the reference and test stimuli,
% respectively, and the bias with which the test stimulus is perceived

simulatedPsiParams = [3, 1.25, 1.5];
refValRange = linspace(-10,10,31);
tVal = 0;
nTrials = 100;

fprintf('* qpRun, Estimate parameters of Jogan & Stocker function:\n');

questData = qpRun(nTrials, ...
    'stimParamsDomainList',{refValRange, refValRange, tVal}, ...
    'psiParamsDomainList',{1:0.5:10, 1:0.5:10, -5:0.5:5}, ...
    'qpPF',@qpPFJoganStocker, ...
    'filterStimParamsDomainFun',@qpFilterJoganStockerStimDomain, ...
    'qpOutcomeF',@(x) qpSimulatedObserver(x,@qpPFJoganStocker,simulatedPsiParams), ...
    'nOutcomes', 2, ...
    'verbose',true);
psiParamsIndex = qpListMaxArg(questData.posterior);
psiParamsQuest = questData.psiParamsDomain(psiParamsIndex,:);
fprintf('Simulated parameters: %0.1f, %0.1f, %0.1f\n',simulatedPsiParams);
fprintf('Max posterior QUEST+ parameters: %0.1f, %0.1f, %0.1f\n',psiParamsQuest);

% Maximum likelihood fit. Use psiParams from QUEST+ as the starting
% parameter for the search, and impose as parameter bounds the range
% provided to QUEST+.
psiParamsFit = qpFit(questData.trialData,questData.qpPF,psiParamsQuest,questData.nOutcomes,...
    'lowerBounds', [1, 1, -5],'upperBounds',[10, 10, 5]);
fprintf('Maximum likelihood fit parameters: %0.1f, %0.1f, %0.1f\n', psiParamsFit);

% Plot trial locations together with maximum likelihood fit.
%
% Point transparancy visualizes number of trials (more opaque -> more
% trials), while point color visualizes percent correct (more blue -> more
% R1).
figure; clf; hold on
stimCounts = qpCounts(qpData(questData.trialData),questData.nOutcomes);
stim = zeros(length(stimCounts),questData.nStimParams);
for cc = 1:length(stimCounts)
    stim(cc,:) = stimCounts(cc).stim;
    nTrials(cc) = sum(stimCounts(cc).outcomeCounts);
    pChooseR2(cc) = stimCounts(cc).outcomeCounts(2)/nTrials(cc);
end
for cc = 1:length(stimCounts)
    scatter(stim(cc,2),stim(cc,1),nTrials(cc)*4,'o', ...
        'MarkerFaceColor',[pChooseR2(cc) 0 1-pChooseR2(cc)], ...
        'MarkerEdgeColor','none', ...
        'MarkerFaceAlpha',nTrials(cc)/max(nTrials));
end
axis square
xlim([min(refValRange)*1.25, max(refValRange)*1.25]);
ylim([min(refValRange)*1.25, max(refValRange)*1.25]);
xlabel('ref2 val relative to test');
ylabel('ref1 val relative to test');
set(gca, 'YDir','reverse')
title('red choose R2; blue choose R1')

% Show the psychomatrix
figure; clf; hold on
for r1 = refValRange
    for r2 = refValRange
        pChooseR2 = qpPFJoganStocker([r1,r2,tVal],simulatedPsiParams);
        h = scatter(r2-tVal,r1-tVal,100,'o','MarkerEdgeColor','none','MarkerFaceColor',[pChooseR2(2) 0 pChooseR2(1)],...
            'MarkerFaceAlpha',1,'MarkerEdgeAlpha',1);
    end
end
title('red choose R2; blue choose R1')
set(gca, 'YDir','reverse')
axis square
xlim([min(refValRange)*1.25, max(refValRange)*1.25]);
ylim([min(refValRange)*1.25, max(refValRange)*1.25]);
xlabel('ref2 val relative to test');
ylabel('ref1 val relative to test');
