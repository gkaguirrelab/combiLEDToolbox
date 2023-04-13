function analyzeDetectThresholdExperiment(subjectID,modDirection,varargin)
% Code to analyze and plot results from a completed psychometric experiment
%
% Examples:
%{
    subjectID = 'HERO_gka1';
    modDirection = 'LminusM_LMNull';
    analyzeDetectThresholdExperiment(subjectID,modDirection)
%}

% Parse the parameters
p = inputParser; p.KeepUnmatched = false;
p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
p.addParameter('projectName','combiLED',@ischar);
p.addParameter('approachName','flickerPsych',@ischar);
p.parse(varargin{:})

% Set our experimentName
experimentName = 'CDT';

% Set a random seed to a reproducible state so that bootstrap results are
% consistent across re-runs of the routine
rng(1);

% Define a location to load data and save analyses
dataDir = fullfile(...
    p.Results.dropBoxBaseDir,...
    'MELA_data',...
    p.Results.projectName,...
    p.Results.approachName,...
    subjectID,modDirection,experimentName);

analysisDir = fullfile(...
    p.Results.dropBoxBaseDir,...
    'MELA_data',...
    p.Results.projectName,...
    p.Results.approachName,...
    subjectID,modDirection,experimentName);

% Create a directory for the subject
if ~isfolder(analysisDir)
    mkdir(analysisDir)
end



% Load the measurementRecord
filename = fullfile(dataDir,'measurementRecord.mat');
load(filename,'measurementRecord');

% Identify all of the unique psych objects in the sessionRecord
fileStems = unique([measurementRecord.sessionData.fileStem]);

% Loop through the psychometric objects and plot the outcomes. Also, save
% parameters depending upon the psychType
results = [];
for ii=1:length(fileStems)
    % Load the object
    filename = fullfile(dataDir,[fileStems{ii} '.mat']);
    load(filename,'psychObj');
    % Make the plot
    figHandle = psychObj.plotOutcome('off');
    % Save the plot
    filename = fullfile(dataDir,[fileStems{ii} '.pdf']);
    saveas(figHandle,filename,'pdf')
    close(figHandle)
    % Obtain boot-strapped params
            nBoots = 200; confInterval = 0.68;
            [~,fitParams,fitParamsCI] = psychObj.reportParams(...
                'nBoots',nBoots,'confInterval',confInterval);
            results(ii).freqHz = psychObj.testFreqHz;
            results(ii).logContrastThresh = fitParams(1);
            results(ii).logContrastThreshLow = fitParamsCI(1,1);
            results(ii).logContrastThreshHigh = fitParamsCI(2,1);
end

% Create a plot of the results

        % Sort the results by order of frequency
        [~,sortIdx] = sort([results.freqHz]);
        results = results(sortIdx);
        % Get the contrast on the targeted receptors
        modContrast = modResult.contrastReceptorsBipolar(1);
        % Make a plot of the temporal contrast sensitivity function
        figHandle = figure();
        figuresize(400, 200,'pt');
        hold on
        yyaxis left
        for ii=1:length(results)
            x = log10([results(ii).freqHz]);
            plot(x,1./(modContrast*10^[results(ii).logContrastThresh]),'or');
            plot([x x],[1./(modContrast*10.^[results(ii).logContrastThreshLow]), 1./(modContrast*10.^[results(ii).logContrastThreshHigh]) ],'-k')
        end
        xlabel('frequency [Hz]')
        ylabel({'Sensitivity',['[1/contrast on ' modDirection ' ]']});
        a = gca;
        a.XTick = log10([results.freqHz]);
        a.XTickLabel = string([results.freqHz]);
        leftYmax = ceil(a.YLim(2)/100)*100;
        ylim([1, leftYmax]);
        ytickVals = a.YTick;
        % Add a right side axis with the absolute device contrast
        yyaxis right
        a = gca;
        a.YTick = ytickVals;
        ylim([1, leftYmax]);
        a.YTickLabel = string(round(1./(ytickVals*modContrast),4));
        ylabel('Device contrast [0 - 1]');
        % Set the x range
        xlim([-0.15 1.75]);
        % Create a weighted DoG fit as a function of freq to the
        % sensitivity values
        yyaxis left
        x=[results.freqHz];
        y=1./(modContrast*10.^[results.logContrastThresh]);
        w=1./(1./(modContrast*10.^[results.logContrastThreshLow])- 1./(modContrast*10.^[results.logContrastThreshHigh]));
        myDoG = @(p,x) p(1).*normpdf(log10(x),log10(p(2)),log10(p(3)));
        myObj = @(p) sqrt(sum(w.*((myDoG(p,x)-y).^2)));
        p=fmincon(myObj,[150,14,2]);
        % Add the fit
        xFit = logspace(0,2,50);
        yFit = myDoG(p,xFit);
        plot(log10(xFit),yFit,'-r')
        % Create an anonymous function that expresses the fit result as
        % absolute device contrast as a function of frequency in Hz
        deviceContrastByFreqHz = @(x) 1./(modContrast*myDoG(p,x));
        % save the figure
        filename = fullfile(analysisDir,'ContrastThresholdByFreq.pdf');
        saveas(figHandle,filename);
        % save the key results
        filename = fullfile(analysisDir,'ContrastThresholdByFreq.mat');
        save(filename,'results','deviceContrastByFreqHz');

end
