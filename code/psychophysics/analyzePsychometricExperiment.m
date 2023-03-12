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
%{
    subjectID = 'HERO_gka';
    modDirection = 'LightFlux';
    psychType = 'DoubleRef';
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
            results(ii).freqHz = psychObj.testFreqHz;
            results(ii).logContrastThresh = fitParams(1);
            results(ii).logContrastThreshLow = fitParamsCI(1,1);
            results(ii).logContrastThreshHigh = fitParamsCI(2,1);
        case 'DoubleRef'
            nBoots = 200; confInterval = 0.68;
            [~,fitParams,fitParamsCI] = psychObj.reportParams(...
                'nBoots',nBoots,'confInterval',confInterval);
            results(ii).refContrastDb = str2double(psychObj.testContrastLabel);
            results(ii).testContrastDb = str2double(psychObj.refContrastLabel);
            results(ii).testFreqHz = psychObj.testFreqHz;
            % The params are in the order rSigma, tSigma, bias
            results(ii).fitParams = fitParams;
            results(ii).fitParamsCI = fitParamsCI;

    end
end

% Create a psychType-specific plot of the results
switch psychType
    case 'CDT'
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
        filename = fullfile(saveDataDir,'ContrastThresholdByFreq.pdf');
        saveas(figHandle,filename);
        % save the key results
        filename = fullfile(saveDataDir,'ContrastThresholdByFreq.mat');
        save(filename,'results','deviceContrastByFreqHz');
    case 'DoubleRef'
        % save the key results
        filename = fullfile(saveDataDir,'DoubleRef2AFCDiscrim.mat');
        save(filename,'results');
        % Make a figure
        figHandle = figure();
        figuresize(600, 200,'pt');
        % Plot rSigma vs. reference contrast.
        subplot(1,3,1);
        hold on
        levelSet = unique([results.refContrastDb]);
        % Create a weighted average of rSigma values at each reference
        % contrast level
        for ii=1:length(levelSet)
            idx = find(levelSet(ii) == [results.refContrastDb]);
            vals = reshape([results(idx).fitParams],3,length(idx));
            vals = vals(1,:);
            weights = reshape(diff([results(idx).fitParamsCI],1),3,length(idx));
            weights = weights(1,:);
            weights = 1./weights;
            weights(isinf(weights)) = max(weights(~isinf(weights)));
            val = sum(vals.*weights)./sum(weights);
            plot(levelSet(ii),val,'or')
        end
        xlim([2 14]);
        xlabel('ref contrast [Dbs of threshold]')
        ylabel('modulation contrast [0-1]')
        title('ref noise sigma')

        % Plot tSigma vs. reference contrast.
        subplot(1,3,2);
        hold on
        levelSet = unique([results.testContrastDb]);
        % Create a weighted average of rSigma values at each reference
        % contrast level
        for ii=1:length(levelSet)
            idx = find(levelSet(ii) == [results.testContrastDb]);
            vals = reshape([results(idx).fitParams],3,length(idx));
            vals = vals(2,:);
            weights = reshape(1./diff([results(idx).fitParamsCI],1),3,length(idx));
            weights = weights(2,:);
            weights(isinf(weights)) = max(weights(~isinf(weights)));
            val = sum(vals.*weights)./sum(weights);
            plot(levelSet(ii),val,'or')
        end
        xlim([2 14]);
        xlabel('test contrast [Dbs of threshold]')
        ylabel('modulation contrast [0-1]')
        title('test noise sigma')

        % Plot bias vs. test frequency
        subplot(1,3,3);
        hold on
        levelSet = unique([results.testFreqHz]);
        % Create a weighted average of bias values at each test freq
        for ii=1:length(levelSet)
            idx = find(levelSet(ii) == [results.testFreqHz]);
            vals = reshape([results(idx).fitParams],3,length(idx));
            vals = vals(3,:);
            weights = reshape(1./diff([results(idx).fitParamsCI],1),3,length(idx));
            weights = weights(3,:);
            weights(isinf(weights)) = max(weights(~isinf(weights)));
            val = sum(vals.*weights)./sum(weights);
            plot(log10(levelSet(ii)),val,'or')
        end
        xlim([0.5 1.5]);
        xlabel('test freq [log Hz]')
        ylabel('bias')
        title('test bias')
        
end

end
