function calcChromaticity(varargin)
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
p.parse(varargin{:});

% Set some constants
curDir = pwd;

% Load the resultSet
cd(p.Results.saveDir);
load('resultSet.mat','resultSet');

% Extract some info from the resultSet
whichDirectionSet = resultSet.whichDirectionSet;
wavelengthSupport = resultSet.(whichDirectionSet{1}).wavelengthsNm;
S = [wavelengthSupport(1), wavelengthSupport(2)-wavelengthSupport(1), length(wavelengthSupport)];

% Load
load('T_xyz1931.mat','T_xyz1931','S_xyz1931');
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);

% Loop over the set of directions for which we will generate modulations
for ss = 1:length(whichDirectionSet)

    whichDirection = whichDirectionSet{ss};

    % Calculate and plot the chromaticities
    bgSpd = resultSet.(whichDirection).background.spd;
    modPosSpd = resultSet.(whichDirection).positiveModulationSPD;
    modNegSpd = resultSet.(whichDirection).negativeModulationSPD;

    bg_photopicLuminanceCdM2_Y = T_xyz(2,:)*bgSpd;
    bg_chromaticity_xy = T_xyz(1:2,:)*bgSpd/sum(T_xyz*bgSpd);
    modPos_chromaticity_xy = T_xyz(1:2,:)*modPosSpd/sum(T_xyz*modPosSpd);
    modNeg_chromaticity_xy = T_xyz(1:2,:)*modNegSpd/sum(T_xyz*modNegSpd);


end

% Return to the directory from whence we started
cd(curDir);

end