function analyzePsychometricExperiment(subjectID,modDirection,psychType,varargin)
% Code to analyze and plot results from a completed psychometric experiment
%
% Examples:
%{
    subjectID = 'HERO_gka';
    modDirection = 'LightFlux';
    modDirection = 'LminusM_wide';
    psychType = 'CDT';
    analyzePsychometricExperiment(subjectID,modDirection,psychType)
%}

% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dataDirRoot','~/Desktop/flickerPsych',@ischar);
p.parse(varargin{:})

% Define a location to save data
saveModDir = fullfile(p.Results.dataDirRoot,subjectID,modDirection);
saveDataDir = fullfile(p.Results.dataDirRoot,subjectID,modDirection,psychType);

% Load and plot the modulation
filename = fullfile(saveModDir,'modResult.mat');
load(filename,'modResult');
figHandle = plotModResult(modResult);
filename = fullfile(saveModDir,'modResult.pdf');
saveas(figHandle,filename,'pdf')

% Load the measurementRecord
filename = fullfile(saveDataDir,'measurementRecord.mat');
load(filename,'measurementRecord');

% Identify all of the unique psych objects in the sessionRecord
fileStems = unique([measurementRecord.sessionData.fileStem]);

% Loop through the psychometric objects and plot the outcomes. Also, save
% parameters depending upon the psychType
results = [];
for ii=1:length(fileStems)
    % Load the object
    filename = fullfile(saveDataDir,[fileStems{ii} '.mat']);
    load(filename,'psychObj');
    % Make the plot
    figHandle = psychObj.plotOutcome('off');
    % Save the plot
    filename = fullfile(saveDataDir,[fileStems{ii} '.pdf']);
    saveas(figHandle,filename,'pdf')
    % Now do psychType specific parameter saving
    switch psychType
        case 'CDT'
            [~,fitParams] = psychObj.reportParams;
            results(ii).freq = psychObj.TestFrequency;
            results(ii).logContrastThresh = fitParams(1);
    end
end

% Create a psychType-specific plot of the results
switch psychType
    case 'CDT'
        % Make a plot of the temporal contrast sensitivity function
        figure
        plot(log10([results.freq]),1./(10.^[results.logContrastThresh]),'or');
        hold on
        xlabel('frequency [Hz]')
        ylabel('Sensitivity (1/contrast)')
        a = gca;
        a.XTick = log10(sort([results.freq]));
        a.XTickLabel = string(sort([results.freq]));
        % save the key results
        filename = fullfile(saveDataDir,'results.mat');
        save(filename,'results');
end


end
