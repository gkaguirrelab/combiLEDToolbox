function qpInitialize(obj)

% Pull out some information from the obj
TestFrequency = obj.TestFrequency;
ReferenceFrequencySet = obj.ReferenceFrequencySet;
psiParamsDomainList = obj.psiParamsDomainList;
simulateResponse = obj.simulateResponse;
verbose = obj.verbose;

% Transform the reference frequency set for compatability with the
% psychometric function
ReferenceFrequencySet = obj.forwardTransformVals(ReferenceFrequencySet,TestFrequency);

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