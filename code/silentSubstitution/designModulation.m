function modResult = designModulation(whichDirection,photoreceptors,cal,varargin)
% Nominal primaries and SPDs for isolating post-receptoral mechanisms
%
% Syntax:
%	modResult = designModulation(whichDirection,photoreceptors);
%
% Description:
%   This routine loads a calibration file for the CombiLED device and
%   identifies the settings on the LEDs that provides maximal contrast
%   along a specified post-receptoral direction.
%
% Inputs:
%	whichDirection        - Char. An entry in the modDirectionDictionary.
%	photoreceptors        - Struct. A struct returned by
%	                        photoreceptorDictionary
%   cal                   - Struct. A calibration result
%
% Outputs:
%	modResult             - Struct. The primaries and SPDs.
%
% Optional key/value pairs:
%  'primaryHeadRoom'      - Scalar. We can enforce a constraint that we
%                           don't go right to the edge of the gamut.  The
%                           head room parameter is defined in the [0-1]
%                           device primary space. Using a little head room
%                           keeps us a bit away from the hard edge of the
%                           device.
%  'contrastMatchConstraint' - Scalar. The difference between the desired 
%                           and obtained contrast on the photoreceptors is
%                           multiplied by the log of this value in
%                           calculating the error for the modulation search
%  'searchBackground'     - Logical. If set to true, a search will be 
%                           conducted over different background settings
%                           to maximize contrast on targeted photoreceptors
%  'xyTarget'             - 1x2 vector. The xy chromaticity desired for the
%                           background. If left empty, this value will be
%                           set to the chromaticity value of the the passed
%                           background primary, or (if a background is not
%                           specified) the value of the half-on background.
%  'xyTol'                - Scalar. In the search across backgrounds, a
%                           nonlinear constraint is used to keep the
%                           background within this range of the target
%                           chromaticity. If set to a large number, the
%                           search will consider any possible background.
%                           If set to zero, then the departure from the
%                           xyTarget will be used not as a linear
%                           constraint, but as a shrinkage parameter upon
%                           the search.
%  'xyTolMetric'          - Scalar. The Minkowski metric used to combine
%                           the x and y differences between the target and
%                           achieved background chromaticity. A value of 2
%                           is the Euclidean (L2) norm. A value of -Inf
%                           would constrain the minimum departure for x or
%                           y.
%  'xyTolWeight'          - How the nonlinear chromaticity constraint is
%                           weighted.
%  'backgroundPrimary'    - 1xnPrimaries vector. A vector of primary
%                           settings in the range of 0-1 that describe the
%                           background around which the modulation will be
%                           set.
%  'verbose'              - Logical. Verbosity.
%
% Examples:
%{
    % L-M modulation around a half-on background
    cal = loadCalByName('CombiLED_shortLLG_classicEyePiece_ND2x5');
    observerAgeInYears = 53;
    pupilDiameterMm = 3;
    photoreceptors = photoreceptorDictionaryHuman('observerAgeInYears',observerAgeInYears,'pupilDiameterMm',pupilDiameterMm);
    whichDirection = 'LminusM_wide';
    modResult = designModulation(whichDirection,photoreceptors,cal);
    plotModResult(modResult);
%}
%{
    % Shifted background human melanopsin modulation
    cal = loadCalByName('CombiLED_shortLLG_classicEyePiece_ND2x5');
    observerAgeInYears = 53;
    pupilDiameterMm = 3;
    photoreceptors = photoreceptorDictionaryHuman('observerAgeInYears',observerAgeInYears,'pupilDiameterMm',pupilDiameterMm);
    whichDirection = 'Mel';
    modResult = designModulation(whichDirection,photoreceptors,cal,'searchBackground',true);
    plotModResult(modResult);
%}
%{
    % A canine ML+S modulation around the half-on background.
    cal = loadCalByName('CombiLED_shortLLG_classicEyePiece_ND2x5');
    photoreceptors = photoreceptorDictionaryCanine();
    whichDirection = 'MLminusS';
    modResult = designModulation(whichDirection,photoreceptors,cal);
    plotModResult(modResult);
%}
%{
    % A rodent melanopsin modulation around the half-on background. We load
    % the calibration of the mouse light panel, and then modify it to
    % synthesize power spectrum of the UV light
    cal = loadCalByName('fullPanel');
    cal = addSynthesizedUVSPDForMouseLight(cal);
    photoreceptors = photoreceptorDictionaryRodent();
    whichDirection = 'mel';
    modResult = designModulation(whichDirection,photoreceptors,cal);
    plotModResult(modResult);
%}
%{
    % modulations for a theoretically perfect device
    cal = loadCal('perfectDevice.mat');
    observerAgeInYears = 53;
    pupilDiameterMm = 3;
    photoreceptors = photoreceptorDictionaryHuman('observerAgeInYears',observerAgeInYears,'pupilDiameterMm',pupilDiameterMm);
    whichDirection = 'Mel_RodSilent_shiftBackground';
    modResult = designModulation(whichDirection,photoreceptors,cal);
    plotModResult(modResult);
%}


%% Parse input
p = inputParser;
p.addRequired('whichDirection',@ischar);
p.addRequired('photoreceptors',@isstruct);
p.addParameter('cal',@isstruct);
p.addParameter('primaryHeadRoom',0.00,@isscalar)
p.addParameter('contrastMatchConstraint',3,@isscalar)
p.addParameter('searchBackground',false,@islogical)
p.addParameter('xyTarget',[],@isnumeric)
p.addParameter('xyTol',1,@isnumeric)
p.addParameter('xyTolMetric',-Inf,@isnumeric)
p.addParameter('xyTolWeight',1e3,@isnumeric)
p.addParameter('backgroundPrimary',[],@isnumeric)
p.addParameter('verbose',false,@islogical)
p.parse(whichDirection,photoreceptors,varargin{:});


% Pull some variables out of the Results for code clarity
primaryHeadRoom = p.Results.primaryHeadRoom;
contrastMatchConstraint = p.Results.contrastMatchConstraint;
searchBackground = p.Results.searchBackground;
xyTarget = p.Results.xyTarget;
xyTol = p.Results.xyTol;
xyTolMetric = p.Results.xyTolMetric;
xyTolWeight = p.Results.xyTolWeight;
backgroundPrimary = p.Results.backgroundPrimary;
verbose = p.Results.verbose;

% The species defined in the photoreceptors
species = photoreceptors(1).species;

% Pull out some information from the calibration
S = cal.rawData.S;
B_primary = cal.processedData.P_device;
ambientSpd = cal.processedData.P_ambient;
nPrimaries = size(B_primary,2);
wavelengthsNm = SToWls(S);

% Detect if there are multiple species intermixed in the photoreceptor set.
% The code currently does not support that circumstance
if length(unique({photoreceptors.species}))~=1
    error('The set of photoreceptors must all be from the same species')
end

% Create the spectral sensitivities in the photoreceptor structure for our
% given set of wavelengths (S). Also assemble the T_receptors matrix.
for ii = 1:length(photoreceptors)
    switch species
        case 'human'
            [photoreceptors(ii).T_energyNormalized,...
                photoreceptors(ii).T_energy,...
                photoreceptors(ii).adjIndDiffParams] = ...
                returnHumanSpectralSensitivity(photoreceptors(ii),S);
        case 'rodent'
            photoreceptors(ii).T_energyNormalized = ...
                returnRodentSpectralSensitivity(photoreceptors(ii),S);
        case 'canine'
            photoreceptors(ii).T_energyNormalized = ...
                returnCanineSpectralSensitivity(photoreceptors(ii),S);
        otherwise
            error('The photoreceptor set contains a non-recognized species')
    end
    T_receptors(ii,:) = photoreceptors(ii).T_energyNormalized;
end

% Get the design parameters from the modulation dictionary. This varies by
% species. Just use the species of the first photoreceptor, as we require
% above that all receptors are from the same species.
switch species
    case 'human'
        [whichReceptorsToTarget,whichReceptorsToIgnore,desiredContrast] = ...
            modDirectionDictionaryHuman(whichDirection,photoreceptors);
    case 'rodent'
        [whichReceptorsToTarget,whichReceptorsToIgnore,desiredContrast] = ...
            modDirectionDictionaryRodent(whichDirection,photoreceptors);
    case 'canine'
        [whichReceptorsToTarget,whichReceptorsToIgnore,desiredContrast] = ...
            modDirectionDictionaryCanine(whichDirection,photoreceptors);
end

% Define the isolation operation as a function of the background.
modulationPrimaryFunc = @(backgroundPrimary) isolateReceptors(...
    whichReceptorsToTarget,whichReceptorsToIgnore,desiredContrast,...
    T_receptors,B_primary,ambientSpd,backgroundPrimary,primaryHeadRoom,contrastMatchConstraint);

% Define a function that returns the contrast on all photoreceptors
contrastReceptorsFunc = @(modulationPrimary,backgroundPrimary) ...
    calcBipolarContrastReceptors(modulationPrimary,backgroundPrimary,T_receptors,B_primary,ambientSpd);

% And a function that returns the contrast on just the targeted
% photoreceptors
contrastOnTargeted = @(contrastReceptors) contrastReceptors(whichReceptorsToTarget);

% Set the bounds within the primary headroom
lb = zeros(1,nPrimaries)+primaryHeadRoom;
plb = zeros(1,nPrimaries)+primaryHeadRoom;
pub = ones(1,nPrimaries)-primaryHeadRoom;
ub = ones(1,nPrimaries)-primaryHeadRoom;

% Set BADS verbosity
if p.Results.verbose
    optionsBADS.Display = 'iter';
else
    optionsBADS.Display = 'off';
end

% The optimization toolbox is currently not available for Matlab
% running under Apple silicon. Detect this case and tell BADS so that
% it doesn't issue a warning
V = ver;
if ~any(strcmp({V.Name}, 'Optimization Toolbox'))
    optionsBADS.OptimToolbox = 0;
end

% If not passed, define the settings for the background as half-on to start
if isempty(backgroundPrimary)
    backgroundPrimary = repmat(0.5,nPrimaries,1);
end

% Handle searching over backgrounds
if searchBackground
    % Alert the user if requested
    if verbose
        fprintf(['Searching over background for ' whichDirection ' modulation...\n'])
    end
    % Set up an objective, which is just the negative of the mean contrast
    % on the targeted photoreceptors, accounting for the sign of the
    % desired contrast
    myObj = @(x) -mean(contrastOnTargeted(contrastReceptorsFunc(modulationPrimaryFunc(x'),x')).*(desiredContrast'));
    % A non-linear constraint that keeps the background within a certain
    % chromaticity range. If the xyTarget is not specified, then the
    % xyValue of the half-on background is used.
    if isempty(xyTarget)
        xyTarget = chromaValue(B_primary*backgroundPrimary,wavelengthsNm);
    end
    myNonlcon = @(x) nonlcon(x',B_primary,wavelengthsNm,xyTarget,xyTol,xyTolMetric,xyTolWeight);
    % If xyTol is zero, we will use the nonlinear constraint as a shrinkage
    % penalty instead of as a constraint.
    if xyTol == 0
        myShrinkObj = @(x) myObj(x)+myNonlcon(x);
        backgroundPrimary = bads(myShrinkObj,backgroundPrimary',lb,ub,plb,pub,[],optionsBADS)';
    else
        backgroundPrimary = bads(myObj,backgroundPrimary',lb,ub,plb,pub,myNonlcon,optionsBADS)';
    end
else
    if verbose
        fprintf(['Searching for ' whichDirection ' modulation\n'])
    end
end

% Perform the search with resulting background background
modulationPrimary = modulationPrimaryFunc(backgroundPrimary);

% Get the contrast results
contrastReceptorsBipolar = contrastReceptorsFunc(modulationPrimary,backgroundPrimary);
contrastReceptorsUnipolar = calcUnipolarContrastReceptors(modulationPrimary,backgroundPrimary,T_receptors,B_primary,ambientSpd);

% Obtain the SPDs and wavelength support
backgroundSPD = B_primary*backgroundPrimary;
positiveModulationSPD = B_primary*modulationPrimary;
negativeModulationSPD = B_primary*(backgroundPrimary-(modulationPrimary - backgroundPrimary));

% Create vectors of the primaries with informative names
settingsLow = backgroundPrimary+(-(modulationPrimary-backgroundPrimary));
settingsHigh = modulationPrimary;
settingsBackground = backgroundPrimary;

% Create a structure to return the results
modResult.meta.whichDirection = whichDirection;
modResult.meta.photoreceptors = photoreceptors;
modResult.meta.cal = cal;
modResult.meta.passedBackgroundPrimary = p.Results.backgroundPrimary;
modResult.meta.contrastMatchConstraint = contrastMatchConstraint;
modResult.meta.searchBackground = searchBackground;
modResult.meta.xyTarget = xyTarget;
modResult.meta.xyTol = xyTol;
modResult.meta.xyTolMetric = xyTolMetric;
modResult.meta.B_primary = B_primary;
modResult.meta.T_receptors = T_receptors;
modResult.meta.whichReceptorsToTarget = whichReceptorsToTarget;
modResult.meta.whichReceptorsToIgnore = whichReceptorsToIgnore;
modResult.meta.desiredContrast = desiredContrast;
modResult.meta.p = p.Results;
modResult.ambientSpd = ambientSpd;
modResult.backgroundSPD = backgroundSPD;
modResult.contrastReceptorsBipolar = contrastReceptorsBipolar;
modResult.contrastReceptorsUnipolar = contrastReceptorsUnipolar;
modResult.positiveModulationSPD = positiveModulationSPD;
modResult.negativeModulationSPD = negativeModulationSPD;
modResult.wavelengthsNm = wavelengthsNm;
modResult.settingsBackground = settingsBackground;
modResult.settingsLow = settingsLow;
modResult.settingsHigh = settingsHigh;

end


%% LOCAL FUNCTIONS

function c = nonlcon(x,B_primary,wavelengthsNm,xyTarget,xyTol,xyTolMetric,xyTolWeight)

% Get the chroma values for the x spd
xyVal = chromaValue(B_primary*x,wavelengthsNm);

% We combine the x and y dimensions following the passed xyMetric
for ii=1:size(xyVal,2)
    xy_distance(ii) = norm(xyVal(:,ii)-xyTarget,xyTolMetric);
end

% Set the constraint value to the value by which the tolerance is exceeded,
% times the tolWeight
c = ((xy_distance-xyTol).*double(xy_distance>xyTol))'*xyTolWeight;

% Handle the case of nan values
c(isnan(xy_distance)) = xyTolWeight;

end
