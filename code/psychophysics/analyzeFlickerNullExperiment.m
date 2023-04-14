function analyzeFlickerNullExperiment(subjectID,modDirection,toBeNulledDirection,varargin)
% 
%
% Examples:
%{
    subjectID = 'HERO_gka1';
    modDirection = 'LminusM_wide';
    foo = 'LminusM_wide';
    analyzeFlickerNullExperiment(subjectID,modDirection,foo);
%}

% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
p.addParameter('projectName','combiLED',@ischar);
p.addParameter('stimContrast',0.175,@isnumeric);
p.parse(varargin{:})

% Set our experimentName
experimentName = 'flickerNull';

stimContrast = p.Results.stimContrast;

% Fix the random seed for reproducibility of boot-strap results
rng(1);

% Define the location of the data
modDir = fullfile(...
    p.Results.dropBoxBaseDir,...
    'MELA_data',...,
    p.Results.projectName,...
    subjectID,modDirection);

dataDir = fullfile(modDir,experimentName);

% Load the measurement record
filesuffix = ['_' subjectID '_' modDirection '_' experimentName ...
    sprintf('_cntrst-%2.2f',stimContrast) ];
filename = fullfile(dataDir,['measurementRecord' filesuffix '.mat']);
load(filename,'measurementRecord');

% Extract some variables
nStims = measurementRecord.experimentProperties.nStims;


% 
% % Create a directory for the subject
% if ~isfolder(dataDir)
%     mkdir(dataDir)
% end

% Load the psychometric objects
sessionData = struct();
for ii=1:nStims
    if mod(ii,2)==0
        searchDirection = 'adjustHighSettings';
    else
        searchDirection = 'adjustLowSettings';
    end

    sessionData.fileStem{ii} = [subjectID '_' modDirection '_' experimentName ...
        sprintf('_cntrst-%2.2f',stimContrast) '_' searchDirection];

    % Load the psychometric objects
    filename = fullfile(dataDir,[sessionData.fileStem{ii} '.mat']);
    if isfile(filename)
        tmpObj = load(filename,'psychObj');
        sessionObj{ii} = tmpObj.psychObj;
        clear tmpObj
    end
end

% Combine all of the trials across objects in a single object,
% and re-fit

comboObj = sessionObj{1};
for ii=2:nStims
    comboObj.questData.trialData = ...
        [comboObj.questData.trialData; sessionObj{ii}.questData.trialData];
    comboObj.questData.stimIndices = ...
        [comboObj.questData.stimIndices; sessionObj{ii}.questData.stimIndices];
    comboObj.questData.entropyAfterTrial = ...
        [comboObj.questData.entropyAfterTrial; sessionObj{ii}.questData.entropyAfterTrial];

end
        figHandle = comboObj.plotOutcome();%('off');
%        filename = fullfile(dataDir,[fileStem '.pdf']);
%        saveas(figHandle,filename,'pdf')


% Save the adjusted modulation
if mod(measurementRecord.trialIdx-1,nTrialsPerStim*nStims)==0
    fprintf('Saving the adjusted modulation result.\n')
    adjustment = [];
    adjIdx = [];
    % Get the average adjustment
    for ii=1:nStims
        filename = fullfile(dataDir,[measurementRecord.sessionData(end).fileStem{ii} '.mat']);
        tmpObj = load(filename,'psychObj');
        sessionObj{ii} = tmpObj.psychObj;
        clear tmpObj
        [~, psiParamsFit] = sessionObj{ii}.reportParams();
        adjustment(ii) = psiParamsFit(1);
    end
    % Create the nulled modResult
    modResultNulled = sessionObj{1}.returnAdjustedModResult(mean(adjustment));
    filename = fullfile(dataDir,'modResultNulled.mat');
    save(filename,'modResultNulled');
    figHandle = plotModResult(modResultNulled,'off');
    filename = fullfile(dataDir,'modResultNulled.pdf');
    saveas(figHandle,filename,'pdf')
    close(figHandle)
end

end
