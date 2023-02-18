% Simulate an observer and test the Jogan & Stocker 2014 function

% Housekeeping
close all; clear;
rng('default'); rng(3008,'twister');

% qpRun estimate of parameters of Jogan & Stocker function. The psiParams
% correspond to the noise sigma for the reference and test stimuli,
% respectively, and the bias with which the test stimulus is perceived

simulatedPsiParams = [3.0, 5, 0.0];
nTrials = 100;

fprintf('* qpRun, Estimate parameters of Jogan & Stocker function:\n');
questData = qpRun(nTrials, ...
    'stimParamsDomainList',{linspace(-10,10,31), linspace(-10,10,31), 0.01}, ...
    'psiParamsDomainList',{1:1:10, 1:1:10, -3:1:3}, ...
    'qpPF',@qpPFJoganStocker, ...
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
    'lowerBounds', [0, 0, -0.5],'upperBounds',[3, 3, 0.5]);
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
    h = scatter(stim(cc,1),stim(cc,2),100,'o','MarkerEdgeColor','none','MarkerFaceColor',[pChooseR2(cc) 0 1-pChooseR2(cc)],...
        'MarkerFaceAlpha',nTrials(cc)/max(nTrials),'MarkerEdgeAlpha',nTrials(cc)/max(nTrials));
end
axis square
xlabel('Value R1');
ylabel('Value R2');
set(gca, 'YDir','reverse')
title('red choose R2; blue choose R1')

% Show the psychomatrix
figure; clf; hold on
for r1 = -10:1:10
    for r2 = -10:1:10
        pChooseR2 = qpPFJoganStocker([r1,r2,0],simulatedPsiParams);
        h = scatter(r1,r2,100,'o','MarkerEdgeColor','none','MarkerFaceColor',[pChooseR2(2) 0 pChooseR2(1)],...
            'MarkerFaceAlpha',1,'MarkerEdgeAlpha',1);
    end
end
title('red choose R2; blue choose R1')
set(gca, 'YDir','reverse')
axis square
xlabel('Value R1');
ylabel('Value R2');
