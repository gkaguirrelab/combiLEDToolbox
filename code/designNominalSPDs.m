function resultSet = designNominalSPDs(varargin)
% Nominal primaries and SPDs for isolating post-receptoral mechanisms
%
% Syntax:
%	resultSet = designNominalSPDs
%
% Description:
%   This routine loads the tabular SPDs for a set of LEDs, and then
%   explores what mixture of n LEDs provides maximal contrast on specified
%   post-receptoral mechanisms, while simultaneously constraining the
%   differential contrast on jointly targeted mechanisms.
%
%   The particular application is selecting LEDs to be placed within a
%   device manufactured by the company Prizmatix. The output of the various
%   LEDs are combined by passing through dichroic mirrors. This has the
%   effect of filtering the SPDs of LEDs that are adjacent in peak
%   wavelength. This effect is modeled.
%
% Inputs:
%	None
%
% Outputs:
%	resultSet             - Struct. The primaries and SPDs.
%
% Optional key/value pairs:
%  'saveDir'              - Char. Full path to the directory in which the
%                           diagnostic plots will be saved. The directory
%                           will be created if it does not exist.
%  'ledSPDFileName'       - Char. Which table of LED primary SPDs to laod.
%  'primaryHeadRoom'      - Scalar. We can enforce a constraint that we
%                           don't go right to the edge of the gamut.  The
%                           head room parameter is defined in the [0-1]
%                           device primary space.  Using a little head room
%                           keeps us a bit away from the hard edge of the
%                           device.
%  'fieldSizeDegrees'     - Scalar
%  'pupilDiameterMm'      - Scalar
%  'observerAgeInYears'   - Scalar
%  'nLEDsToKeep'          - Scalar. The number of LEDs in the final device.
%  'minLEDspacing'        - Scalar. When picking sets of LEDs to examine,
%                           only use sets for which the peak wavelengths
%                           between the LEDs are all separated by at least
%                           this amount in nanometers.
%  'weightedBackgroundPrimaries' - Logical. When set to true, the
%                           background settings are inversely weighted by
%                           the total power of each LED.
%  'filterAdjacentPrimariesFlag' - Logical. When set to true, a logistic
%                           transmitance filter is applied to the SPD of
%                           adjacent LEDs to model the filtering effects
%                           of the dichroic mirrors.
%  'filterMaxSlopeParam'  - Scalar. The maximum slope of the logistic
%                           function that models the dichroic mirrors, in
%                           units of proportion filter / nm. The value of
%                           0.2 is pretty close to what is on the website
%                           for these filters.
%  'primariesToKeepBest'  - Vector. A set of LEDs that have been found to
%                           perform well in previous searches.
%  'nTests'               - Scalar. The number of permutations of LED sets
%                           to test for optimal performance. Set to inf to
%                           test all.
%  'stepSizeDiffContrastSearch' - Scalar. In searching for a modulation,
%                           routine attempts to maximize contrast on a
%                           targeted set of photoreceptors, but also
%                           attempts to minimize differential contrast on
%                           these. The targeted contrast is iteratively
%                           reduced until the differential contrast
%                           constraint is satisfied. This parameter sets
%                           how finely these iterative steps are taken.
%  'shrinkFactorThresh'   - Scalar. For this search across reduced contrast
%                           levels to minimize differential contrast, this
%                           sets the threshold at which we abandon the
%                           search and move on to a different set of
%                           primaries. If set to 0.7, for example, if the
%                           reduction in the desired contrast hits 70% of
%                           the original target, then we give up.
%
% Examples:
%{
    % These entries test our ability to replicate the SPD model used by the
    % Prizmatix engineers. There is some disagreement in the 4th primary
    % as I did not have access to the true SPD for that primary, and had
    % to assume the SPD and total power of the UHP-T-545-SR for the
    % UHP-T-545-LA21.
    ledSPDFileName = 'PrizmatixLED_SetA_SPDs.csv';
    ledTotalPowerFileName = 'PrizmatixLED_SetA_totalPower.csv';
    filterCenterWavelengthsBest = [423 453 506 575 610 649 685];
    primariesToKeepBest = 1:8; nTests = 1;
    resultSetOurs = designNominalSPDs('ledSPDFileName',ledSPDFileName,...
        'ledTotalPowerFileName',ledTotalPowerFileName,...
        'filterCenterWavelengthsBest',filterCenterWavelengthsBest,...
        'primariesToKeepBest',primariesToKeepBest,'nTests',nTests,...
        'makePlots',false);
    ledSPDFileName = 'PrizmatixLED_SetA_postFilter_SPDs.csv';
    ledTotalPowerFileName = 'PrizmatixLED_SetA_postFilter_totalPower.csv';
    filterCenterWavelengthsBest = [423 453 506 575 610 649 685];
    resultSetTheirs = designNominalSPDs('ledSPDFileName',ledSPDFileName,...
        'ledTotalPowerFileName',ledTotalPowerFileName,...
        'filterCenterWavelengthsBest',filterCenterWavelengthsBest,...
        'primariesToKeepBest',primariesToKeepBest,'nTests',nTests,...
        'makePlots',false);
    figure
    plot(resultSetTheirs.LMS.wavelengthsNm,resultSetTheirs.B_primary,'-','LineWidth',2); hold on
    plot(resultSetTheirs.LMS.wavelengthsNm,resultSetOurs.B_primary,'--','LineWidth',2);
%}
%{
    % Test of the model:
    % https://www.prizmatix.com/jscriptview/a1.htm#NET=[[90032,2,-1,-1,1,1,2,1],[90009,3,2,2,1,1,3,3],[90018,4,3,2,1,1,4,5],[90068,5,2,3,1,1,5,2],[90052,6,5,2,1,1,0,4],[90064,7,6,2,1,1,1,6],[90109,8,7,2,0,1,6,4],[90023,9,4,2,1,1,7,3],[113,10,5,3,1,1,0,0],[125,11,6,3,1,1,1,0],[181,12,7,3,1,1,2,0],[146,13,8,3,1,1,3,0],[108,14,3,1,1,1,4,0],[121,15,4,1,1,1,5,0],[123,16,9,1,1,1,6,0],[189,17,9,2,1,1,7,0],[128,18,8,2,1,1,8,0]]-PIX=[280,800]-
    primariesToKeepBest = [1 3 6 10 12 13 17 18];
    filterCenterWavelengthsBest = [411 459 480 509 569 610 645];
    nTests = 1;
    resultSet = designNominalSPDs(...
        'filterCenterWavelengthsBest',filterCenterWavelengthsBest,...
        'primariesToKeepBest',primariesToKeepBest,'nTests',nTests,...
        'makePlots',true);
%}
%{
    % Design sent to Nathaniel Sperka on 26-July-2022. This is the set of
    % LEDs and filters in device we have ordered.
    primariesToKeepBest = [1 3 6 10 12 13 17 18];
    filterCenterWavelengthsBest = [412 456 482 516 587 619 645];
    nTests = 1;
    resultSet = designNominalSPDs(...
        'filterCenterWavelengthsBest',filterCenterWavelengthsBest,...
        'primariesToKeepBest',primariesToKeepBest,'nTests',nTests,...
        'makePlots',true);
%}

%% Parse input
p = inputParser;
p.addParameter('saveDir','~/Desktop/nominalSPDs',@ischar);
p.addParameter('ledSPDFileName','PrizmatixLED_FullSet_SPDs.csv',@ischar);
p.addParameter('ledTotalPowerFileName','PrizmatixLED_FullSet_totalPower.csv',@ischar);
p.addParameter('primaryHeadRoom',0.05,@isscalar)
p.addParameter('observerAgeInYears',25,@isscalar)
p.addParameter('fieldSizeDegrees',30,@isscalar)
p.addParameter('pupilDiameterMm',2,@isscalar)
p.addParameter('nLEDsToKeep',8,@isscalar)
p.addParameter('minLEDspacing',20,@isscalar)
p.addParameter('weightedBackgroundPrimaries',false,@islogical)
p.addParameter('filterAdjacentPrimariesFlag',true,@islogical)
p.addParameter('filterMaxSlopeParam',1/5,@isscalar)
p.addParameter('primariesToKeepBest',[1 3 7 10 12 13 17 18],@isvector)
p.addParameter('filterCenterWavelengthsBest',[],@isvector)
p.addParameter('nTests',inf,@isscalar)
p.addParameter('stepSizeDiffContrastSearch',0.025,@isscalar)
p.addParameter('shrinkFactorThresh',0.5,@isscalar)
p.addParameter('x0PrimaryChoice','background',@isscalar)
p.addParameter('verbose',true,@islogical)
p.addParameter('makePlots',true,@islogical)
p.parse(varargin{:});

% Set some constants
whichModel = 'human';
whichPrimaries = 'prizmatix';
maxPowerDiff = 10000; % No smoothness constraint enforced for the LED primaries
curDir = pwd;

% Load the table of LED primaries
spdTablePath = fullfile(fileparts(fileparts(mfilename('fullpath'))),'data',p.Results.ledSPDFileName);
spdTableFull = readtable(spdTablePath);

% Load the table of total power (in milliWatts) for each LED
powerTablePath = fullfile(fileparts(fileparts(mfilename('fullpath'))),'data',p.Results.ledTotalPowerFileName);
powerTableFull = readtable(powerTablePath);

% Save the list of names of the LEDs
totalLEDs = size(spdTableFull,2)-1;
LEDnames = spdTableFull.Properties.VariableNames(2:end);

% Derive the wavelength support
wavelengthSupport = spdTableFull.Wavelength;
S = [wavelengthSupport(1), wavelengthSupport(2)-wavelengthSupport(1), length(wavelengthSupport)];

% Scale the SPDs to reflect absolute power, and record the peak wavelength
% for each LED
for ii=1:totalLEDs
    thisSPD = cell2mat(table2cell(spdTableFull(:,ii+1)));
    thisName = LEDnames(ii);
    totalPowerMw = powerTableFull.(thisName{1});

    % We have some knowledge of the area of the emitting surface of the
    % LED. We get that number and adjust the power by the multiple of
    % square mm.
    switch thisName{1}(end-1:end)
        case 'EP'
            surfaceArea = 2*2;
        case 'SR'
            surfaceArea = 1.2*1.5;
        case '21' % The "LA21"
            surfaceArea = 2*1;
        otherwise
            error('Need the surface area for this LED')
    end

    % Apply the adjustment
    thisSPD = thisSPD .* ( (totalPowerMw*surfaceArea ) / (S(2) * sum(thisSPD)) );
    thisSPD(thisSPD<0)=0;
    spdTableFull(:,ii+1) = table(thisSPD);
    [~,idx]=max(thisSPD);
    LEDpeakWavelength(ii) = wavelengthSupport(idx);

end
LEDpower = cell2mat(table2cell(powerTableFull));
unitLabel = 'mW/nm';

%% Get the photoreceptors
% Define photoreceptor classes that we'll consider.
% ReceptorIsolate has a few more built-ins than these.
photoreceptorClasses = {...
    'LConeTabulatedAbsorbance2Deg', 'MConeTabulatedAbsorbance2Deg', 'SConeTabulatedAbsorbance2Deg',...
    'LConeTabulatedAbsorbance10Deg', 'MConeTabulatedAbsorbance10Deg', 'SConeTabulatedAbsorbance10Deg',...
    'Melanopsin'};

photoreceptorClassNames = {'L_2deg','M_2deg','S_2deg','L_10deg','M_10deg','S_10deg','Mel'};

% Make sensitivities.  The wrapper routine is GetHumanPhotoreceptorSS,
% which is in the ContrastSplatter directory.  Each row of the matrix
% T_receptors provides the spectral sensitivity of the photoreceptor class
% in the corresponding entry of the cell array photoreceptorClasses.
%
% The last two arguments are the oxygenation fraction and the vessel
% thickness. We set them to be empty here.
oxygenationFraction = [];
vesselThickness = [];
fractionBleached = [];
T_receptors = GetHumanPhotoreceptorSS(S, photoreceptorClasses, p.Results.fieldSizeDegrees, p.Results.observerAgeInYears, p.Results.pupilDiameterMm, [], fractionBleached, oxygenationFraction, vesselThickness);


%% Define the receptor sets to isolate
% I consider the following modulations:
%   LMS -   Equal contrast on the peripheral cones, silencing Mel, as
%           this modulation would mostly be used in conjunction with
%           light flux and mel stimuli
%   LminusM - An L-M modulation that has equal contrast with eccentricity.
%           Ignore mel.
%   S -     An S modulation that has equal contrast with eccentricity.
%           Ignore mel.
%   Mel -   Mel directed, silencing peripheral but not central cones. It is
%           very hard to get any contrast on Mel while silencing both
%           central and peripheral cones. This stimulus would be used in
%           concert with occlusion of the macular region of the stimulus.
%   SnoMel- S modulation in the periphery that silences melanopsin.

whichDirectionSet = {'LMS','LminusM','S','Mel','SnoMel'};
whichReceptorsToTargetSet = {[4 5 6],[1 2 4 5],[3 6],[7],[6]};
whichReceptorsToIgnoreSet = {[1 2 3],[7],[7],[1 2 3],[1 2 3]};
whichReceptorsToMinimizeSet = {[],[],[],[],[]}; % This can be left empty. Any receptor that is neither targeted nor ignored will be silenced
desiredContrastSet = {repmat(0.5,1,3),[0.12 -0.12 0.12 -0.12],[0.7 0.7],0.6,0.65};
minAcceptableContrastSets = {...
    {[1,2,3]},...
    {[1,2],[3,4]},...
    {[1,2]},...
    {},...
    {},...
    };
minAcceptableContrastDiffSet = [0.015,0.005,0.025,0,0];
backgroundSearchFlag = [true,false,false,true,true];
whichDirectionsToScore = [1 4]; % Only these influence the metric

% whichDirectionSet = {'Mel'};
% whichReceptorsToTargetSet = {[7]};
% whichReceptorsToIgnoreSet = {[1 2 3]};
% whichReceptorsToMinimizeSet = {[]}; % This can be left empty. Any receptor that is neither targeted nor ignored will be silenced
% desiredContrastSet = {0.6};
% minAcceptableContrastSets = {...
%     {},...
%     };
% minAcceptableContrastDiffSet = [0];
% backgroundSearchFlag = [true];
% whichDirectionsToScore = [1]; % Only these influence the metric


%% Define the filter form
% Adjacent LEDs are subject to filtering by dichroic mirrors that direct
% the light. Generate here the form of that filter. The maximum slope of
% the logit function is set in the varargin.
logitFunc = @(x,x0) 1./(1+exp(-p.Results.filterMaxSlopeParam.*(x-x0)));


% Partition the LEDs into sets
if p.Results.nTests == 1
    nTests = 1;
    partitionSets = p.Results.primariesToKeepBest;
else
    partitionSets = nchoosek(1:totalLEDs,p.Results.nLEDsToKeep);

    % Loop through the partitions and mark the bad ones
    goodPatitions = ones(size(partitionSets,1),1);
    for ii=1:size(partitionSets,1)
        % Filter the partition sets to remove those that have LEDs that are
        % too close together
        if min(diff(LEDpeakWavelength(squeeze(partitionSets(ii,:))))) <= p.Results.minLEDspacing
            goodPatitions(ii)=0;
        end
    end

    % Remove the badness
    partitionSets = partitionSets(find(goodPatitions),:);

    % Randomize the order of the sets to search
    partitionSets = partitionSets(randperm(size(partitionSets,1)),:);
    nTests = min([p.Results.nTests,size(partitionSets,1)]);
end

% Alert the user
if p.Results.verbose
    tic
    fprintf(['Searching over %d LED partitions. Started ' char(datetime('now')) '\n'],nTests);
    fprintf('| 0                      50                   100%% |\n');
    fprintf('.\n');
end

% Loop over the tests
parfor dd = 1:nTests

    % Update progress
    if p.Results.verbose
        if mod(dd,round(nTests/50))==0
            fprintf('\b.\n');
        end
    end

    % Pick a random subset of the available LEDs to use as primaries
    primariesToKeep = partitionSets(dd,:);
    primariesToKeepNames = LEDnames(primariesToKeep);

    % Keep this part of the SPD table
    spdTable = spdTableFull(:,[1 primariesToKeep+1]);

    % Clear the resultSet variable and store a few of the variables used in
    % the computation
    resultSet = [];
    resultSet.primariesToKeepIdx = primariesToKeep;
    resultSet.primariesToKeepNames = primariesToKeepNames;
    resultSet.photoreceptorClassNames = photoreceptorClassNames;
    resultSet.T_receptors = T_receptors;
    resultSet.whichDirectionSet = whichDirectionSet;
    resultSet.whichReceptorsToTargetSet = whichReceptorsToTargetSet;
    resultSet.whichReceptorsToIgnoreSet = whichReceptorsToIgnoreSet;
    resultSet.whichReceptorsToMinimizeSet = whichReceptorsToMinimizeSet;
    resultSet.desiredContrastSet = desiredContrastSet;
    resultSet.minAcceptableContrastSets = minAcceptableContrastSets;
    resultSet.minAcceptableContrastDiffSet = minAcceptableContrastDiffSet;
    resultSet.backgroundSearchFlag = backgroundSearchFlag;

    % Derive the primaries from the SPD table
    B_primary = table2array(spdTable(:,2:end));
    nPrimaries = size(B_primary,2);

    % Store the primaries before filtering by the dichroic mirrors
    resultSet.B_primaryPreFilter = B_primary;

    % The primaries are arranged in a device that channels the light with
    % dichroic mirrors. This has the effect of filtering SPD of adjacent
    % primaries. Apply this here if requested.
    if p.Results.filterAdjacentPrimariesFlag
        filterCenterWavelengths = zeros(nPrimaries-1,1);
        for ii=1:nPrimaries-1

            % Find the midpoint wavelength between two adjacent LEDs, or
            % use the specified value in filterCentersNmBest
            if ~isempty(p.Results.filterCenterWavelengthsBest)
                filterCenterWavelengths(ii) = p.Results.filterCenterWavelengthsBest(ii);
                [~, filterCenterIdx] = min(abs(wavelengthSupport-filterCenterWavelengths(ii)));
            else
                primaryDiff = B_primary(:,ii)-B_primary(:,ii+1);
                [~,idx1]=max(primaryDiff);
                [~,idx2]=min(primaryDiff);
                [~,idx3]=min(abs(primaryDiff(idx1:idx2)));
                filterCenterIdx = idx1+idx3;
                filterCenterWavelengths(ii)=wavelengthSupport(filterCenterIdx);
            end

            % Make the filter
            filterTransmitance = logitFunc(1:length(wavelengthSupport),filterCenterIdx);

            % Apply the filter to the two primaries
            B_primary(:,ii) = B_primary(:,ii) .* (1-filterTransmitance)';
            B_primary(:,ii+1) = B_primary(:,ii+1) .* filterTransmitance';

        end
    end

    % Save the filter centers
    resultSet.filterCenterWavelength = filterCenterWavelengths;

    % Set up a zero ambient
    ambientSpd = zeros(S(3),1);

    % Add these to the resultSet
    resultSet.B_primary = B_primary;
    resultSet.ambientSpd = ambientSpd;

    % Loop over the set of directions for which we will generate
    % modulations
    for ss = 1:length(whichDirectionSet)

        % Extract values from the cell arrays
        whichDirection = whichDirectionSet{ss};
        whichReceptorsToTarget = whichReceptorsToTargetSet{ss};
        whichReceptorsToIgnore = whichReceptorsToIgnoreSet{ss};
        whichReceptorsToMinimize = whichReceptorsToMinimizeSet{ss};
        minAcceptableContrast = minAcceptableContrastSets{ss};
        minAcceptableContrastDiff = minAcceptableContrastDiffSet(ss);
        desiredContrast = desiredContrastSet{ss};

        % Don't pin any primaries.
        whichPrimariesToPin = [];

        % Set background
        if p.Results.weightedBackgroundPrimaries
            % Create a background that inversely weights the LEDs by their
            % total power
            j=LEDpower(primariesToKeep); j=j/max(j); j=j-mean(j); j=j/2;
            backgroundPrimary = (0.5-j)';
        else
            backgroundPrimary = repmat(0.5,nPrimaries,1);
        end

        % Decide upon an x0Primary to start the search
        switch p.Results.x0PrimaryChoice
            case 'background'
                x0Primary = backgroundPrimary;
            case 'ones'
                x0Primary = ones(size(backgroundPrimary));
            case 'random'
                x0Primary = rand(size(backgroundPrimary));
        end

        % Anonymous function that perfoms a modPrimarySearch for a
        % particular background defined by backgroundPrimary and x0
        myModPrimary = @(xBackPrimary) modPrimarySearch(...
            B_primary,xBackPrimary,x0Primary,ambientSpd,T_receptors,...
            whichReceptorsToTarget,whichReceptorsToIgnore,...
            whichReceptorsToMinimize,whichPrimariesToPin,...
            p.Results.primaryHeadRoom,maxPowerDiff,desiredContrast,...
            minAcceptableContrast,minAcceptableContrastDiff,...
            p.Results.verbose,p.Results.stepSizeDiffContrastSearch,...
            p.Results.shrinkFactorThresh);

        % Obtain the modulationPrimary for this background
        modulationPrimary = myModPrimary(backgroundPrimary);

        % Obtain the isomerization rate for the receptors by the background
        backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);

        % Store the background properties
        resultSet.(whichDirection).background.primary = backgroundPrimary;
        resultSet.(whichDirection).background.spd = B_primary*backgroundPrimary;
        resultSet.(whichDirection).background.wavelengthsNm = SToWls(S);

        % Store the modulation primaries
        resultSet.(whichDirection).modulationPrimary = modulationPrimary;

        % Calculate and store the positive and negative receptor contrast
        modulationReceptors = T_receptors*B_primary*(modulationPrimary - backgroundPrimary);
        contrastReceptors = modulationReceptors ./ backgroundReceptors;
        resultSet.(whichDirection).positiveReceptorContrast = contrastReceptors;

        modulationReceptors = T_receptors*B_primary*(-(modulationPrimary - backgroundPrimary));
        contrastReceptors = modulationReceptors ./ backgroundReceptors;
        resultSet.(whichDirection).negativeReceptorContrast = contrastReceptors;

        % Calculate and store the spectra
        resultSet.(whichDirection).positiveModulationSPD = B_primary*modulationPrimary;
        resultSet.(whichDirection).negativeModulationSPD = B_primary*(backgroundPrimary-(modulationPrimary - backgroundPrimary));
        resultSet.(whichDirection).wavelengthsNm = SToWls(S);

    end

    % Place the resultSet in the outcomes cell array
    outcomes{dd} = resultSet;

end

% alert the user that we are done with the search loop
if p.Results.verbose
    toc
    fprintf('\n');
end

% Obtain the set of contrasts for the modulations
for ss=1:length(whichDirectionSet)
    whichDirection = whichDirectionSet{ss};
    contrasts(ss,:) = cellfun(@(x) x.(whichDirection).positiveReceptorContrast(whichReceptorsToTargetSet{ss}(1)), outcomes);
end

% Normalize each contrast vector by the desired target contrast
contrasts = contrasts./cellfun(@(x) x(1),desiredContrastSet)';

% Only pay attention to those contrasts that we are asked to score
contrasts = contrasts(whichDirectionsToScore,:);

% Find the best outcome
[~,idxBestOutcome]=min(max((1-contrasts)));
resultSet = outcomes{idxBestOutcome};

% Create the save dir
if ~isempty(p.Results.saveDir)
    if ~isfolder(p.Results.saveDir)
        mkdir(p.Results.saveDir);
    end
end

% Save the results file
cd(p.Results.saveDir);
save('resultSet.mat','resultSet');

% Save figures
if p.Results.makePlots

    % Loop through the directions
    for ss = 1:length(whichDirectionSet)

        % Extract values from the cell arrays
        whichDirection = whichDirectionSet{ss};

        % Create a figure with an appropriate title
        fighandle = figure('Name',sprintf([whichDirection ': contrast = %2.2f'],resultSet.(whichDirection).positiveReceptorContrast(whichReceptorsToTargetSet{ss}(1))));

        % Modulation spectra
        subplot(1,2,1)
        hold on
        plot(resultSet.(whichDirection).wavelengthsNm,resultSet.(whichDirection).positiveModulationSPD,'k','LineWidth',2);
        plot(resultSet.(whichDirection).wavelengthsNm,resultSet.(whichDirection).negativeModulationSPD,'r','LineWidth',2);
        plot(resultSet.(whichDirection).background.wavelengthsNm,resultSet.(whichDirection).background.spd,'Color',[0.5 0.5 0.5],'LineWidth',2);
        title(sprintf('Modulation spectra [%2.2f]',resultSet.(whichDirection).positiveReceptorContrast(whichReceptorsToTargetSet{ss}(1))));
        xlim([300 800]);
        xlabel('Wavelength');
        ylabel('Power');
        legend({'Positive', 'Negative', 'Background'},'Location','NorthEast');

        % Primaries
        subplot(1,2,2)
        c = categorical(resultSet.primariesToKeepNames);
        hold on
        plot(c,resultSet.(whichDirection).modulationPrimary,'*k');
        plot(c,resultSet.(whichDirection).background.primary+(-(resultSet.(whichDirection).modulationPrimary-resultSet.(whichDirection).background.primary)),'*r');
        plot(c,resultSet.(whichDirection).background.primary,'-*','Color',[0.5 0.5 0.5]);
        set(gca,'TickLabelInterpreter','none');
        title('Primary settings');
        ylim([0 1]);
        xlabel('Primary');
        ylabel('Setting');

        % Save the figure
        saveas(fighandle,sprintf('%s_%s_%s_PrimariesAndSPD.pdf',whichModel,whichPrimaries,whichDirection),'pdf');

    end

    % Plot the primary SPDs at source and output
    minColorWavelength = 375;
    maxColorWavelength = 675;
    myColorMap = myRainbowColorMap((1+maxColorWavelength-minColorWavelength));
    figure

    % Absolute SPDs of primaries at source
    myPrimaries = resultSet.B_primaryPreFilter;
    subplot(2,2,1)
    for ii=1:size(myPrimaries,2)
        myPrimary = myPrimaries(:,ii);
        [~,idx] = max(myPrimary);
        myColorIdx = round(wavelengthSupport(idx)-minColorWavelength);
        myColor = myColorMap(myColorIdx,:);
        plot(wavelengthSupport,myPrimary,'-','Color',myColor,'LineWidth',2);
        if ii==1 
            hold on;
        end
    end
    xlim([300 800]);
    xlabel('wavelength [nm]')
    ylabel(unitLabel);

    % Relative SPDs of primaries at source, with dichroics
    myPrimaries = resultSet.B_primaryPreFilter;
    subplot(2,2,2)
    for ii=1:size(myPrimaries,2)
        myPrimary = myPrimaries(:,ii);
        myPrimary = myPrimary./max(myPrimary);
        [~,idx] = max(myPrimary);
        myColorIdx = round(wavelengthSupport(idx)-minColorWavelength);
        myColor = myColorMap(myColorIdx,:);
        plot(wavelengthSupport,myPrimary,'-','Color',myColor,'LineWidth',2);
        if ii==1 
            hold on;
        else
            filterCenterWavelength = resultSet.filterCenterWavelength(ii-1);
            [~, filterCenterIdx] = min(abs(wavelengthSupport-filterCenterWavelength));
            filterTransmitance = logitFunc(1:length(wavelengthSupport),filterCenterIdx);
            myColorIdx = round(filterCenterWavelength-minColorWavelength);
            myColor = myColorMap(myColorIdx,:);
            plot(wavelengthSupport,filterTransmitance,'--','Color',myColor);
        end
    end
    xlim([300 800]);
    xlabel('wavelength [nm]')
    ylabel('scaled power');

    % Absolute SPDs of primaries at output
    subplot(2,2,3)
    myPrimaries = resultSet.B_primary;
    for ii=1:size(myPrimaries,2)
        myPrimary = myPrimaries(:,ii);
        [~,idx] = max(myPrimary);
        myColorIdx = round(wavelengthSupport(idx)-minColorWavelength);
        myColor = myColorMap(myColorIdx,:);
        plot(wavelengthSupport,myPrimary,'-','Color',myColor,'LineWidth',2);
        if ii==1 
            hold on;
        else
            filterCenterWavelength = resultSet.filterCenterWavelength(ii-1);
            myColorIdx = round(filterCenterWavelength-minColorWavelength);
            myColor = myColorMap(myColorIdx,:);
            plot([filterCenterWavelength filterCenterWavelength],[0 max(myPrimaries(:))],'-','Color',myColor);
        end
    end
    xlim([300 800]);
    xlabel('wavelength [nm]')
    ylabel(unitLabel);

    % Relative SPDs of primaries at output, with dichroic center lines
    subplot(2,2,4)
    for ii=1:size(myPrimaries,2)
        myPrimary = myPrimaries(:,ii);
        myPrimary = myPrimary./max(myPrimary);
        [~,idx] = max(myPrimary);
        myColorIdx = round(wavelengthSupport(idx)-minColorWavelength);
        myColor = myColorMap(myColorIdx,:);
        plot(wavelengthSupport,myPrimary,'-','Color',myColor,'LineWidth',2);
        if ii==1 
            hold on;
        else
            filterCenterWavelength = resultSet.filterCenterWavelength(ii-1);
            myColorIdx = round(filterCenterWavelength-minColorWavelength);
            myColor = myColorMap(myColorIdx,:);
            plot([filterCenterWavelength filterCenterWavelength],[0 1],'-','Color',myColor);
        end
    end
    xlim([300 800]);
    xlabel('wavelength [nm]')
    ylabel('Scaled power');

end

% Return to the directory from whence we started
cd(curDir);

end


%% Local function
function CT = myRainbowColorMap(nColors)
CT0 = [0.1405 0.00719 0.2242;0.2134 0.02435 0.3071;0.2648 0.02239 0.3479;0.2939 0.02786 0.3459;0.3375 0.02245 0.3691;0.3897 0.0223 0.4038;0.4351 0.02615 0.4378;0.456 0.01441 0.4381;0.4954 0.01003 0.449;0.5511 0.009804 0.4672;0.6116 0.008296 0.464;0.6801 0.001307 0.4526;0.7271 0.00228 0.4565;0.7818 0.006536 0.4948;0.828 0.009907 0.5359;0.8676 0.0143 0.5839;0.8606 0.01917 0.6722;0.8253 0.02237 0.7799;0.818 0.02273 0.8655;0.7843 0.01825 0.9707;0.7034 0.02612 0.9948;0.6356 0.02984 0.975;0.5591 0.0158 0.986;0.4729 0.01941 0.9852;0.3943 0.01963 0.9843;0.2488 0.0183 0.9863;0.07647 0.02211 0.9914;0.008018 0 0.9843;0.01111 0 0.969;0.01767 0.01238 0.9275;0.01273 0.01356 0.8648;0.03213 0.01246 0.8417;0.02846 0.04258 0.801;0.0274 0.1747 0.8174;0.02555 0.2225 0.8204;0.03333 0.2876 0.817;0.02546 0.3374 0.8016;0.0236 0.3879 0.8185;0.01625 0.432 0.8365;0.006413 0.4712 0.8649;0.007416 0.4887 0.8925;0.0007977 0.5012 0.9207;0.0004992 0.5309 0.9578;0 0.5756 0.9916;0.003567 0.6182 0.997;0.00719 0.6767 0.9928;0.02484 0.7205 0.9989;0.03152 0.7562 0.993;0.01508 0.822 0.9863;0.01747 0.8936 0.9953;0.02296 0.9529 0.9891;0.024 0.9852 0.9279;0.02026 0.9961 0.8719;0.01496 0.9886 0.7667;0.03049 0.9892 0.6001;0.02087 0.9863 0.4098;0.01789 0.9974 0.07776;0.01725 0.9606 0.0003963;0.01863 0.9308 0.01073;0.001961 0.9131 0;0.004236 0.8942 0;0.005677 0.8781 0.001307;0.005311 0.8535 0.0006948;0.01288 0.833 0.01111;0.01661 0.8162 0.01895;0.01176 0.7963 0.01565;0.02207 0.786 0.02584;0.02157 0.7644 0.02651;0.06474 0.7566 0.03014;0.1571 0.7701 0.01745;0.1626 0.7964 0.02131;0.1612 0.8166 0.008401;0.2329 0.8254 0.01182;0.2985 0.8546 0;0.3777 0.8741 0.01526;0.474 0.8925 0.006012;0.5589 0.9105 0.0002779;0.6113 0.9272 0.01176;0.6918 0.9392 0.01242;0.7733 0.9464 0.02611;0.8095 0.9646 0.02408;0.87 0.9698 0.03896;0.9162 0.9704 0.0406;0.9458 0.9832 0.02098;0.9722 0.9876 0.03364;0.9933 0.9877 0.03591;0.9966 0.9901 0.03054;0.9943 0.9878 0.0268;0.9928 0.9864 0.02418;0.9907 0.9778 0.01195;0.9969 0.9605 0.01176;0.9987 0.9372 0.01176;0.9908 0.9186 0.004179;0.987 0.8869 0.005882;0.9922 0.8495 0.007843;0.9884 0.8197 0.01942;0.9843 0.7858 0.02226;0.9892 0.7445 0.02651;0.9838 0.7106 0.01977;0.9882 0.677 0.01548;0.9961 0.6406 0.02876;0.9924 0.6112 0.02539;0.9926 0.583 0.03174;0.9967 0.5562 0.02285;0.999 0.538 0.01752;0.9943 0.523 0.00915;0.9987 0.5125 0.009305;0.9975 0.497 0;0.9974 0.4951 0;0.9984 0.49 0.00244;1 0.4782 0.001307;0.9978 0.4522 0.003278;0.9975 0.434 0.01569;0.9972 0.4088 0.01825;0.998 0.3756 0.02078;0.9958 0.3408 0.01079;0.9882 0.3182 0.003;0.9839 0.2809 0.01128;0.9916 0.2318 0.01659;0.9952 0.1948 0.01917;0.9895 0.1604 0.01373;0.9863 0.1382 0.01373;0.9863 0.09212 0.002857;0.9938 0.05828 0.003598;0.9942 0.04339 0.01283;0.9941 0.02184 0.01438;0.9882 0.02519 0.01642;0.985 0.02092 0.03268];
na = size(CT0,1);
CT = interp1(linspace(0,1,na),CT0,linspace(0,1,nColors));
end