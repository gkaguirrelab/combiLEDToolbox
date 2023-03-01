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
figHandle = plotModResult(modResult,'off');
filename = fullfile(saveModDir,'modResult.pdf');
saveas(figHandle,filename,'pdf')
close(figHandle)

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
    close(figHandle)    
    % Now do psychType specific parameter saving
    switch psychType
        case 'CDT'
            nBoots = 200; confInterval = 0.68;
            [~,fitParams,fitParamsCI] = psychObj.reportParams(...
                'nBoots',nBoots,'confInterval',confInterval);
            results(ii).freq = psychObj.testFreqHz;
            results(ii).logContrastThresh = fitParams(1);
            results(ii).logContrastThreshLow = fitParamsCI(1,1);
            results(ii).logContrastThreshHigh = fitParamsCI(2,1);
    end
end

% Create a psychType-specific plot of the results
switch psychType
    case 'CDT'
        % Get the contrast on the targeted receptors
        modContrast = modResult.contrastReceptorsBipolar(1);
        % Make a plot of the temporal contrast sensitivity function
        figHandle = figure();
        figuresize(400, 200,'pt');
        hold on
        yyaxis left
        for ii=1:length(results)
            x = log10([results(ii).freq]);
            plot(x,1./(modContrast*10^[results(ii).logContrastThresh]),'or');
            plot([x x],[1./(modContrast*10.^[results(ii).logContrastThreshLow]), 1./(modContrast*10.^[results(ii).logContrastThreshHigh]) ],'-k')
        end
        xlabel('frequency [Hz]')
        ylabel({'Sensitivity',['[1/contrast on ' modDirection ' ]']});
        a = gca;
        a.XTick = log10(sort([results.freq]));
        a.XTickLabel = string(sort([results.freq]));
        ylim([0, ceil(a.YLim(2)/100)*100]);
        % Add a right side axis with the absolute device contrast
        yyaxis right
        plot(log10([results.freq]),10.^[results.logContrastThresh],"Color","none")
        ylabel('Device contrast [0 - 1]');
        % Expand the range a bit
        xlim([-0.15 1.75]);
        % Create a DoG fit
        x=log10([results.freq]);
        y=1./(modContrast.*10.^[results.logContrastThresh]);
        w=1./([results.logContrastThreshHigh]-[results.logContrastThreshLow]);
        myDoG = @(p,x) p(1).*(normpdf(x,p(2),p(3)) - normpdf(x,p(4),p(5)));
        myObj = @(p) sqrt(sum(w.*((myDoG(p,x)-y).^2)));
        p=fmincon(myObj,[100,1.1,0.2,0.8,0.5]);
        xFit = 0:0.01:2.0;
        yFit = myDoG(p,xFit);
        yyaxis left
        plot(xFit,yFit,'-r')
        % save the figure
        filename = fullfile(saveDataDir,'results.pdf');
        saveas(figHandle,filename);
        % save the key results
        filename = fullfile(saveDataDir,'results.mat');
        save(filename,'results');
end

end
