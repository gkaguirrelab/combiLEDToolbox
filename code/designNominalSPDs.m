function resultSet = designNominalSPDs(varargin)
% Nominal primaries and SPDs for isolating post-receptoral mechanisms
%
% Syntax:
%	resultSet = designNominalSPDs
%
% Description:
%   Given a calibration file from a monitor, this code will provide the RGB
%   primary settings that should serve to produce isolated stimulation of
%   the cone (L, M, S) and post-receptoral channels (LMS, L-M, S).
%
% Inputs:
%	None
%
% Outputs:
%	resultSet             - Cell array of structs. The primaries and SPDs.
%
% Optional key/value pairs:
%  'calFilePath'          - Char. Full path to the .mat cal file.
%  'plotDir'              - Char. Full path to the directory in which the
%                           diagnostic plots will be saved. The directory
%                           will be created if it does not exist. If set to
%                           empty, no files will be saved.
%  'primaryHeadRoom'      - Scalar. We can enforce a constraint that we
%                           don't go right to the edge of the gamut.  The
%                           head room parameter is defined in the [0-1]
%                           device primary space.  Using a little head room
%                           keeps us a bit away from the hard edge of the
%                           device.
%  'observerAgeInYears'   - Scalar
%  'fieldSizeDegrees'     - Scalar
%  'pupilDiameterMm'      - Scalar
%


%% Parse input
p = inputParser;
p.addParameter('saveDir','~/Desktop/nominalSPDs',@ischar);
p.addParameter('primaryHeadRoom',0,@isscalar)
p.addParameter('observerAgeInYears',25,@isscalar)
p.addParameter('fieldSizeDegrees',30,@isscalar)
p.addParameter('pupilDiameterMm',2,@isscalar)
p.addParameter('nLEDsToKeep',8,@isscalar)
p.addParameter('nTests',100,@isscalar)
p.addParameter('stepSizeDiffContrastSearch',0.025,@isscalar)
p.addParameter('verbose',false,@islogical)
p.parse(varargin{:});

% Set some constants
whichModel = 'human';
whichPrimaries = 'prizmatix';
curDir = pwd;

% Load the table of LED primaries
spdTablePath = fullfile(fileparts(fileparts(mfilename('fullpath'))),'data','PrizmatixLEDSet.csv');
spdTableFull = readtable(spdTablePath);

% Save the list of names of the LEDs
totalLEDs = size(spdTableFull,2)-1;
LEDnames = spdTableFull.Properties.VariableNames(2:end);

% Derive the wavelength support
wavelengthSupport = spdTableFull.Wavelength;
S = [wavelengthSupport(1), wavelengthSupport(2)-wavelengthSupport(1), length(wavelengthSupport)];


%% Get the photoreceptors
% Define photoreceptor classes that we'll consider.
% ReceptorIsolate has a few more built-ins than these.
photoreceptorClasses = {...
    'LConeTabulatedAbsorbance2Deg', 'MConeTabulatedAbsorbance2Deg', 'SConeTabulatedAbsorbance2Deg',...
    'LConeTabulatedAbsorbance10Deg', 'MConeTabulatedAbsorbance10Deg', 'SConeTabulatedAbsorbance10Deg',...
    'Melanopsin'};

resultSet.photoreceptorClasses = {'L_2deg','M_2deg','S_2deg','L_10deg','M_10deg','S_10deg','Mel'};

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
%           this modulation would mostly be used to in conjunction with
%           light flux and mel stimuli
%   LminusM - An L-M modulation that has equal contrast with eccentricity.
%           Ignore mel.
%   S -     An S modulation that has equal contrast with eccentricity.
%           Ignore mel.
%   Mel -   Mel directed, silencing peripheral but not central cones. It is
%           very hard to get any contrast on Mel while silencing both
%           central and peripheral cones. This stimulus would be used in
%           concert with occlusion of the macular region of the stimulus.
%   spatial - Ignore mel, try to create differential foveal and
%           peripheral cone contrast.
%
whichDirectionSet = {'LMS','LminusM','S','Mel'};
whichReceptorsToTargetSet = {[4 5 6],[1 2 4 5],[3 6],[7]};
whichReceptorsToIgnoreSet = {[1 2 3],[7],[7],[1 2 3]};
whichReceptorsToMinimizeSet = {[],[],[],[]}; % This can be left empty. Any receptor that is neither targeted nor ignored will be silenced
desiredContrastSet = {[ repmat(0.45,1,3) ],[0.14 -0.14 0.14 -0.14],[0.8 0.8],[0.8]};
minAcceptableContrastSets = {...
    {[1,2,3]},...
    {[1,2],[3,4]},...
    {[1,2]},...
    {},...
    };
minAcceptableContrastDiff = [0.01,0.005,0.025,0];

%% Loop over random samples of LEDs
for dd = 1:p.Results.nTests

    % Pick a random subset of the available LEDs to use as primaries
    primariesToKeep = randsample(totalLEDs,p.Results.nLEDsToKeep)';
    spdTable = spdTableFull(:,[1 primariesToKeep+1]);
    resultSet.primariesToKeepIdx = primariesToKeep;
    resultSet.primariesToKeepNames = LEDnames(primariesToKeep);

    % Derive the primaries from the SPD table
    B_primary = table2array(spdTable(:,2:end));
    nPrimaries = size(B_primary,2);

    % I don't yet have the absolute power measurements of the primaries,
    % and some are more normalized than others, so set all to have unit
    % amplitude here.
    B_primary = B_primary./max(B_primary);

    % Set up a zero ambient
    ambientSpd = zeros(S(3),1);

    % Set background to the half-on
    backgroundPrimary = repmat(0.5,nPrimaries,1);

    % Obtain the isomerization rate for the receptors by the background
    backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);

    % Store the background properties
    resultSet.background.primary = backgroundPrimary;
    resultSet.background.spd = B_primary*backgroundPrimary;
    resultSet.background.wavelengthsNm = SToWls(S);

    % Loop over the set of directions for which we will generate modulations
    for ss = 1:length(whichDirectionSet)

        % Extract values from the cell arrays
        whichDirection = whichDirectionSet{ss};
        whichReceptorsToTarget = whichReceptorsToTargetSet{ss};
        whichReceptorsToIgnore = whichReceptorsToIgnoreSet{ss};
        whichReceptorsToMinimize = whichReceptorsToMinimizeSet{ss};
        desiredContrast = desiredContrastSet{ss};

        % Don't pin any primaries.
        whichPrimariesToPin = [];

        % No smoothness constraint enforced for the LED primaries
        maxPowerDiff = 10000;

        % Obtain the primary settings for the isolating modulation. Perform
        % this search in a loop to steadily scale down targeted contrast
        % until differential absolute contrast amongst the targeted
        % photoreceptors is below criterion
        stillSearching = true;
        shrinkFactor = 1;
        thisContrastTarget = desiredContrast;

        while stillSearching
            modulationPrimary = ReceptorIsolate(T_receptors,whichReceptorsToTarget, whichReceptorsToIgnore, whichReceptorsToMinimize, ...
                B_primary, backgroundPrimary, backgroundPrimary, whichPrimariesToPin,...
                p.Results.primaryHeadRoom, maxPowerDiff, thisContrastTarget, ambientSpd);
            % Calculate the positive receptor contrast and the differences
            % between the targeted receptor sets
            modulationReceptors = T_receptors*B_primary*(modulationPrimary - backgroundPrimary);
            contrastReceptors = modulationReceptors ./ backgroundReceptors;
            contrastVal = contrastReceptors(whichReceptorsToTargetSet{ss}(1));
            contrastDiffs = cellfun(@(x) range(abs(contrastReceptors(whichReceptorsToTargetSet{ss}(x)))),minAcceptableContrastSets{ss});

            % Report the results of this iteration
            if p.Results.verbose
                fprintf([whichDirection ' contrast %2.2f, diff %2.2f, criterion %2.2f \n'],contrastVal,max(contrastDiffs),minAcceptableContrastDiff(ss))
            end

            % Check if we are done
            if any(contrastDiffs > minAcceptableContrastDiff(ss))
                shrinkFactor = shrinkFactor - p.Results.stepSizeDiffContrastSearch;
                thisContrastTarget = desiredContrast.*shrinkFactor;
            else
                stillSearching = false;
            end
        end

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

% Obtain the set of contrasts for the modulations
for ss=1:4
    whichDirection = whichDirectionSet{ss};
    contrasts(ss,:) = cellfun(@(x) x.(whichDirection).positiveReceptorContrast(whichReceptorsToTargetSet{ss}(1)), outcomes);
end

% Obtain maximum differential contrast
for ss=1:4
    whichDirection = whichDirectionSet{ss};
    diffContrasts(ss,:) = cellfun(@(x) range(abs(x.(whichDirection).positiveReceptorContrast(whichReceptorsToTargetSet{ss}))), outcomes);
end

% Normalize each contrast vector by the desired target contrast
contrasts = contrasts./cellfun(@(x) x(1),desiredContrastSet(1:4))';

% Find the best outcome
[~,idxBestOutcome]=max(vecnorm(contrasts));
resultSet = outcomes{idxBestOutcome};

% Create the save dir
if ~isempty(p.Results.saveDir)
    if ~isdir(p.Results.saveDir)
        mkdir(p.Results.saveDir);
    end
end
cd(p.Results.saveDir);

% Loop through the directions and save figures
for ss = 1:length(whichDirectionSet)

    % Extract values from the cell arrays
    whichDirection = whichDirectionSet{ss};

    % Create a figure with an appropriate title
    fighandle = figure('Name',sprintf([whichDirection ': contrast = %2.2f'],resultSet.(whichDirection).positiveReceptorContrast(whichReceptorsToTargetSet{ss}(1))));
    set(fighandle,'defaultTextInterpreter','none')

    % Modulation spectra
    subplot(1,2,1)
    hold on
    plot(resultSet.(whichDirection).wavelengthsNm,resultSet.(whichDirection).positiveModulationSPD,'k','LineWidth',2);
    plot(resultSet.(whichDirection).wavelengthsNm,resultSet.(whichDirection).negativeModulationSPD,'r','LineWidth',2);
    plot(resultSet.background.wavelengthsNm,resultSet.background.spd,'Color',[0.5 0.5 0.5],'LineWidth',2);
    title('Modulation spectra');
    xlim([300 800]);
    xlabel('Wavelength');
    ylabel('Power');
    legend({'Positive', 'Negative', 'Background'},'Location','NorthEast');

    % Primaries
    subplot(1,2,2)
    c = categorical(spdTable.Properties.VariableNames(2:end));
    hold on
    plot(c,resultSet.(whichDirection).modulationPrimary,'*k');
    plot(c,backgroundPrimary+(-(resultSet.(whichDirection).modulationPrimary-backgroundPrimary)),'*r');
    plot(c,backgroundPrimary,'-*','Color',[0.5 0.5 0.5]);
    title('Primary settings');
    ylim([0 1]);
    xlabel('Primary');
    ylabel('Setting');

    % Save the figure
    saveas(fighandle,sprintf('%s_%s_%s_PrimariesAndSPD.pdf',whichModel,whichPrimaries,whichDirection),'pdf');

end

% Return to the directory from whence we started
cd(curDir);

end