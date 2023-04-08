function modResult = designModulation(whichDirection,varargin)
% Nominal primaries and SPDs for isolating post-receptoral mechanisms
%
% Syntax:
%	resultSet = designModulation
%
% Description:
%   This routine loads a calibration file for the CombiLED device and
%   identifies the settings on the LEDs that provides maximal contrast
%   along a specified post-receptoral direction.
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
%
% Examples:
%{
    observerAgeInYears = 53;
    pupilDiameterMm = 3;
    whichDirection = 'LminusM_wide';
    modResult = designModulation(whichDirection,...
        'observerAgeInYears',observerAgeInYears,'pupilDiameterMm',pupilDiameterMm);
%}


%% Parse input
p = inputParser;
p.addRequired('whichDirection',@ischar)
p.addParameter('calLocalData',fullfile(tbLocateProject('combiLEDToolbox'),'cal','CombiLED_shortLLG_classicEyePiece_ND2x5.mat'),@ischar);
p.addParameter('primaryHeadRoom',0.00,@isscalar)
p.addParameter('observerAgeInYears',25,@isscalar)
p.addParameter('fieldSizeDegrees',30,@isscalar)
p.addParameter('pupilDiameterMm',2,@isscalar)
p.addParameter('verbose',true,@islogical)
p.parse(whichDirection,varargin{:});


% Pull some variables out of the Results for code clarity
primaryHeadRoom = p.Results.primaryHeadRoom;
verbose = p.Results.verbose;

% Load the calibration
load(p.Results.calLocalData,'cals');
cal = cals{end};

% Pull out some information from the calibration
S = cal.rawData.S;
B_primary = cal.processedData.P_device;
ambientSpd = cal.processedData.P_ambient;
nPrimaries = size(B_primary,2);

% Define photoreceptor classes that we'll consider.
[photoreceptorClasses, photoreceptorClassNames] = photoreceptorDictionary();

% Get spectral sensitivities. Each row of the matrix T_receptors provides
% the spectral sensitivity of the photoreceptor class in the corresponding
% entry of the cell array photoreceptorClasses. The last two arguments are
% the oxygenation fraction and the vessel thickness. We set them to be
% empty here.
fractionBleached = [];
oxygenationFraction = [];
vesselThickness = [];
T_receptors = GetHumanPhotoreceptorSS(S, photoreceptorClasses, ...
    p.Results.fieldSizeDegrees, p.Results.observerAgeInYears, ...
    p.Results.pupilDiameterMm, ...
    [], fractionBleached, oxygenationFraction, vesselThickness);

% Get the design parameters from the modulation dictionary
[whichReceptorsToTarget,whichReceptorsToIgnore,...
    desiredContrast,x0Background,matchConstraint,searchBackground] = ...
    modDirectionDictionary(whichDirection);

% Define the isolation operation as a function of the background.
modulationPrimaryFunc = @(backgroundPrimary) isolateReceptors(...
    whichReceptorsToTarget,whichReceptorsToIgnore,desiredContrast,...
    T_receptors,B_primary,ambientSpd,backgroundPrimary,primaryHeadRoom,matchConstraint);

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
optionsBADS.Display = 'off';

% The optimization toolbox is currently not available for Matlab
% running under Apple silicon. Detect this case and tell BADS so that
% it doesn't issue a warning
V = ver;
if ~any(strcmp({V.Name}, 'Optimization Toolbox'))
    optionsBADS.OptimToolbox = 0;
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
    backgroundPrimary = bads(myObj,x0Background',lb,ub,plb,pub,[],optionsBADS)';
else
    if verbose
        fprintf(['Searching for ' whichDirection ' modulation\n'])
    end
    % If we are not searching across backgrounds, use the half-on
    backgroundPrimary = repmat(0.5,nPrimaries,1);
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
wavelengthsNm = SToWls(S);

% Create vectors of the primaries with informative names
settingsLow = backgroundPrimary+(-(modulationPrimary-backgroundPrimary));
settingsHigh = modulationPrimary;
settingsBackground = backgroundPrimary;

% Create a structure to return the results
modResult.meta.whichDirection = whichDirection;
modResult.meta.x0Background = x0Background;
modResult.meta.matchConstraint = matchConstraint;
modResult.meta.searchBackground = searchBackground;
modResult.meta.p = p.Results;
modResult.backgroundSPD = backgroundSPD;
modResult.meta.photoreceptorClasses = photoreceptorClasses;
modResult.meta.photoreceptorClassNames = photoreceptorClassNames;
modResult.meta.whichReceptorsToTarget = whichReceptorsToTarget;
modResult.meta.whichReceptorsToIgnore = whichReceptorsToIgnore;
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

function contrastReceptors = calcBipolarContrastReceptors(modulationPrimary,backgroundPrimary,T_receptors,B_primary,ambientSpd)

% Obtain the isomerization rate for the receptors by the background
backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);

% Calculate the positive receptor contrast and the differences
% between the targeted receptor sets
modulationReceptors = T_receptors*B_primary*(modulationPrimary - backgroundPrimary);
contrastReceptors = modulationReceptors ./ backgroundReceptors;

end


function contrastReceptors = calcUnipolarContrastReceptors(modulationPrimary,backgroundPrimary,T_receptors,B_primary,ambientSpd)

% For the unipolar case, the "background" is the negative primary
negativePrimary = (backgroundPrimary-(modulationPrimary - backgroundPrimary));

% Obtain the isomerization rate for the receptors by the background
negativeReceptors = T_receptors*(B_primary*negativePrimary + ambientSpd);

% Calculate the positive receptor contrast and the differences
% between the targeted receptor sets
modulationReceptors = T_receptors*B_primary*modulationPrimary;
contrastReceptors = modulationReceptors ./ negativeReceptors;

end