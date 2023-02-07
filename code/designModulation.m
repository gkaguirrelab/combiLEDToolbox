function resultSet = designModulation(whichDirection,varargin)
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


%% Parse input
p = inputParser;
p.addRequired('whichDirection',@ischar)
p.addParameter('calLocalData',fullfile(tbLocateProject('prizmatixDesign'),'cal','CombiLED.mat'),@ischar);
p.addParameter('primaryHeadRoom',0.00,@isscalar)
p.addParameter('observerAgeInYears',25,@isscalar)
p.addParameter('fieldSizeDegrees',30,@isscalar)
p.addParameter('pupilDiameterMm',2,@isscalar)
p.addParameter('searchOverBackgrounds',false,@islogical)
p.addParameter('verbose',true,@islogical)
p.addParameter('makePlots',true,@islogical)
p.parse(whichDirection,varargin{:});

% Set some constants

% Load the calibration
load(p.Results.calLocalData,'cals');
cal = cals{end};

S = cal.rawData.S;
B_primary = cal.processedData.P_device;
ambientSpd = cal.processedData.P_ambient;

%% Get the photoreceptors
% Define photoreceptor classes that we'll consider.
photoreceptorClasses = {...
    'LConeTabulatedAbsorbance2Deg', 'MConeTabulatedAbsorbance2Deg', 'SConeTabulatedAbsorbance2Deg',...
    'LConeTabulatedAbsorbance10Deg', 'MConeTabulatedAbsorbance10Deg', 'SConeTabulatedAbsorbance10Deg',...
    'Melanopsin'};
photoreceptorClassNames = {'L_2deg','M_2deg','S_2deg','L_10deg','M_10deg','S_10deg','Mel'};

% Get spectral sensitivities. Each row of the matrix T_receptors provides
% the spectral sensitivity of the photoreceptor class in the corresponding
% entry of the cell array photoreceptorClasses. The last two arguments are
% the oxygenation fraction and the vessel thickness. We set them to be
% empty here.
oxygenationFraction = [];
vesselThickness = [];
fractionBleached = [];
T_receptors = GetHumanPhotoreceptorSS(S, photoreceptorClasses, p.Results.fieldSizeDegrees, p.Results.observerAgeInYears, p.Results.pupilDiameterMm, [], fractionBleached, oxygenationFraction, vesselThickness);

% Define the modulation direction
[whichReceptorsToTarget,whichReceptorsToIgnore,whichReceptorsToMinimize,desiredContrast] = ...
    selectModulationDirection(whichDirection);

% No smoothness constraint enforced for the LED primaries
maxPowerDiff = 10000;
% Don't pin any primaries.
whichPrimariesToPin = [];

primaryHeadRoom = p.Results.primaryHeadRoom;

% Perform the search with a mid-point background
backgroundPrimary = repmat(0.5,size(B_primary,2),1);

x0Primary = backgroundPrimary;

modulationPrimary = ReceptorIsolate(T_receptors,whichReceptorsToTarget, whichReceptorsToIgnore, whichReceptorsToMinimize, ...
    B_primary, backgroundPrimary, x0Primary, whichPrimariesToPin,...
    primaryHeadRoom, maxPowerDiff, desiredContrast, ambientSpd);

% Obtain the isomerization rate for the receptors by the background
backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);

% Calculate the positive receptor contrast and the differences
% between the targeted receptor sets

modulationReceptors = T_receptors*B_primary*(modulationPrimary - backgroundPrimary);
contrastReceptors = modulationReceptors ./ backgroundReceptors


end

