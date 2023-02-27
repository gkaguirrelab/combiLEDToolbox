function [psiParamsQuest, psiParamsFit] = reportParams(obj)

% Grab some variables
questData = obj.questData;
psiParamsDomainList = obj.psiParamsDomainList;
verbose = obj.verbose;

% The best quess at the params from Quest
psiParamsIndex = qpListMaxArg(questData.posterior);
psiParamsQuest = questData.psiParamsDomain(psiParamsIndex,:);

% Maximum likelihood fit. Create bounds from psiParamsDomainList
for ii=1:length(psiParamsDomainList)
    lb(ii) = min(psiParamsDomainList{ii});
    ub(ii) = max(psiParamsDomainList{ii});
end

% Obtain the fit
psiParamsFit = qpFit(questData.trialData,questData.qpPF,psiParamsQuest,questData.nOutcomes,...
    'lowerBounds', lb,'upperBounds',ub);

% Report these values
if verbose
    if obj.simulateResponse
        fprintf('Simulated parameters: %2.3f, %2.3f, %2.3f, %2.3f\n',obj.simulatePsiParams);
    end
    fprintf('Max posterior QUEST+ parameters: %2.3f, %2.3f, %2.3f, %2.3f\n',psiParamsQuest);
    fprintf('Maximum likelihood fit parameters: %2.3f, %2.3f, %2.3f, %2.3f\n', psiParamsFit);
end


end