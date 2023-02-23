function initializeQP(obj)

% Pull out some information from the obj
psiParamsDomainList = obj.psiParamsDomainList;
simulateResponse = obj.simulateResponse;
verbose = obj.verbose;

% Transform the stimulus set to relative log space
ReferenceFrequencySet = obj.forwardTransformVals(obj.ReferenceFrequencySet,obj.TestFrequency);

% Handle simulation and the outcome function
if simulateResponse
    simulatePsiParams = obj.simulatePsiParams;
    qpOutcomeF = @(x) qpSimulatedObserver(x,@qpPFJoganStocker,simulatePsiParams);
else
    qpOutcomeF = [];
end

% Create the Quest+ varargin
qpKeyVals = { ...
    'stimParamsDomainList',{ReferenceFrequencySet, ReferenceFrequencySet}, ...
    'psiParamsDomainList',psiParamsDomainList, ...
    'qpPF',@qpPFJoganStocker, ...
    'filterStimParamsDomainFun',@qpFilterJoganStockerStimDomain, ...
    'qpOutcomeF',qpOutcomeF, ...
    'nOutcomes', 2, ...
    'verbose',verbose};

% Alert the user
if verbose
    fprintf('Initializing Quest+\n')
end

% Perform the initialize operation
obj.questData = qpInitialize(qpKeyVals{:});


end