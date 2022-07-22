function resultSet = backgroundSearch(varargin)
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
% Inputs:
%	None
%
% Outputs:
%	resultSet             - Cell array of structs. The primaries and SPDs.
%
% Optional key/value pairs:
%  'saveDir'              - Char. Full path to the directory in which the
%                           diagnostic plots will be saved. The directory
%                           will be created if it does not exist.
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
p.addParameter('primaryHeadRoom',0.05,@isscalar)
p.addParameter('observerAgeInYears',25,@isscalar)
p.addParameter('fieldSizeDegrees',30,@isscalar)
p.addParameter('pupilDiameterMm',2,@isscalar)
p.addParameter('stepSizeDiffContrastSearch',0.025,@isscalar)
p.addParameter('shrinkFactorThresh',0.7,@isscalar)
p.addParameter('verbose',true,@islogical)
p.parse(varargin{:});

% Set some constants
whichModel = 'human';
whichPrimaries = 'prizmatix';
maxPowerDiff = 10000; % No smoothness constraint enforced for the LED primaries
curDir = pwd;

% Load the resultSet
cd(p.Results.saveDir);
load('resultSet.mat','resultSet');

% Extract some info from the resultSet to guide the search
T_receptors = resultSet.T_receptors;
whichDirectionSet = resultSet.whichDirectionSet;
whichReceptorsToTargetSet = resultSet.whichReceptorsToTargetSet;
whichReceptorsToIgnoreSet = resultSet.whichReceptorsToIgnoreSet;
whichReceptorsToMinimizeSet = resultSet.whichReceptorsToMinimizeSet;
minAcceptableContrastSets = resultSet.minAcceptableContrastSets;
minAcceptableContrastDiffSet = resultSet.minAcceptableContrastDiffSet;
backgroundSearchFlag = resultSet.backgroundSearchFlag;
ambientSpd = resultSet.ambientSpd;
B_primary = resultSet.B_primary;

% Loop over the set of directions for which we will generate modulations
for ss = 1:length(whichDirectionSet)

    % Check if we wish to search over the background for this
    % modulation
    if backgroundSearchFlag(ss)

        % Extract values from the cell arrays
        whichDirection = whichDirectionSet{ss};
        whichReceptorsToTarget = whichReceptorsToTargetSet{ss};
        whichReceptorsToIgnore = whichReceptorsToIgnoreSet{ss};
        whichReceptorsToMinimize = whichReceptorsToMinimizeSet{ss};
        minAcceptableContrast = minAcceptableContrastSets{ss};
        minAcceptableContrastDiff = minAcceptableContrastDiffSet(ss);

        % Set the desired contrast to be slightly larger than the current
        % contrast of the modulation
        desiredContrast = resultSet.(whichDirection).positiveReceptorContrast(resultSet.whichReceptorsToTargetSet{ss});
        desiredContrast = desiredContrast' .* (1/0.8);

        % Don't pin any primaries.
        whichPrimariesToPin = [];

        % Grab the current background
        backgroundPrimary = resultSet.(whichDirection).background.primary;
        nPrimaries = size(backgroundPrimary,1);

        % Anonymous function that returns one element of a contrast vector
        myContrast = @(x) x(whichReceptorsToTarget(1));

        % Anonymous function that reports the contrast on the
        % targeted photoreceptor for the product of a modPrimarySearch
        myContrastVec = @(xModPrimary,xBackPrimary) (T_receptors*B_primary*(xModPrimary - xBackPrimary)) ./ (T_receptors*(B_primary*xBackPrimary + ambientSpd));

        % Anonymous function that perfoms a modPrimarySearch for a
        % particular background defined by backgroundPrimary
        myModPrimary = @(xBackPrimary) modPrimarySearch(...
            B_primary,xBackPrimary,xBackPrimary,ambientSpd,T_receptors,...
            whichReceptorsToTarget,whichReceptorsToIgnore,...
            whichReceptorsToMinimize,whichPrimariesToPin,...
            p.Results.primaryHeadRoom,maxPowerDiff,desiredContrast,...
            minAcceptableContrast,minAcceptableContrastDiff,...
            p.Results.verbose,p.Results.stepSizeDiffContrastSearch,p.Results.shrinkFactorThresh);

        % Objective function that returns the inverse of the contrast on
        % the targeted photoreceptor
        myObj = @(xBackPrimary) 1/myContrast(myContrastVec(myModPrimary(xBackPrimary),xBackPrimary));

        % Set the options for an fmincon search
        options = optimoptions('fmincon','Display','iter');

        % Conduct the search over backgrounds
        backgroundPrimary = fmincon(myObj,backgroundPrimary,[],[],[],[],zeros(nPrimaries,1),ones(nPrimaries,1),[],options);

        % Obtain the modulationPrimary for this background
        modulationPrimary = myModPrimary(backgroundPrimary);

        % Obtain the isomerization rate for the receptors by the background
        backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);

        % Store the background properties
        resultSet.(whichDirection).background.primary = backgroundPrimary;
        resultSet.(whichDirection).background.spd = B_primary*backgroundPrimary;

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
    end

end

% Save the results file
cd(p.Results.saveDir);
save('resultSet.mat','resultSet');

% Loop through the directions and save figures
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

% Return to the directory from whence we started
cd(curDir);

end