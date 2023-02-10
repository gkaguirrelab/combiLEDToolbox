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

% Save the ToolboxToolbox verbosity pref, and set it to false
tbtbVerbose = getpref('ToolboxToolbox','verbose');
setpref('ToolboxToolbox','verbose',false);

%% Parse input
p = inputParser;
p.addRequired('whichDirection',@ischar)
p.addParameter('calLocalData',fullfile(tbLocateProject('prizmatixDesign'),'cal','CombiLED.mat'),@ischar);
p.addParameter('matchConstraint',1,@isscalar)
p.addParameter('primaryHeadRoom',0.00,@isscalar)
p.addParameter('observerAgeInYears',25,@isscalar)
p.addParameter('fieldSizeDegrees',30,@isscalar)
p.addParameter('pupilDiameterMm',2,@isscalar)
p.addParameter('searchOverBackgrounds',false,@islogical)
p.addParameter('verbose',false,@islogical)
p.addParameter('makePlots',false,@islogical)
p.parse(whichDirection,varargin{:});

% Restore the TbTb verbosity pref
setpref('ToolboxToolbox','verbose',tbtbVerbose);

% Load the calibration
load(p.Results.calLocalData,'cals');
cal = cals{end};

S = cal.rawData.S;
B_primary = cal.processedData.P_device;
ambientSpd = cal.processedData.P_ambient;

matchConstraint = p.Results.matchConstraint;

%% Get the photoreceptors
% Define photoreceptor classes that we'll consider.
photoreceptorClasses = {...
    'LConeTabulatedAbsorbance2Deg', 'MConeTabulatedAbsorbance2Deg', 'SConeTabulatedAbsorbance2Deg',...
    'LConeTabulatedAbsorbance10Deg', 'MConeTabulatedAbsorbance10Deg', 'SConeTabulatedAbsorbance10Deg',...
    'LConeTabulatedAbsorbancePenumbral', 'MConeTabulatedAbsorbancePenumbral', 'SConeTabulatedAbsorbancePenumbral', ...
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
[whichReceptorsToTarget,whichReceptorsToIgnore,desiredContrast] = ...
    selectModulationDirection(whichDirection);

primaryHeadRoom = p.Results.primaryHeadRoom;

% Perform the search with a mid-point background
backgroundPrimary = repmat(0.5,size(B_primary,2),1);

x0Primary = backgroundPrimary;

modulationPrimary = isolateReceptors(T_receptors,whichReceptorsToTarget, ...
    whichReceptorsToIgnore, B_primary,backgroundPrimary,x0Primary, ...
    primaryHeadRoom,desiredContrast,ambientSpd,matchConstraint);

% Obtain the isomerization rate for the receptors by the background
backgroundReceptors = T_receptors*(B_primary*backgroundPrimary + ambientSpd);

% Calculate the positive receptor contrast and the differences
% between the targeted receptor sets

modulationReceptors = T_receptors*B_primary*(modulationPrimary - backgroundPrimary);
contrastReceptors = modulationReceptors ./ backgroundReceptors

positiveModulationSPD = B_primary*modulationPrimary;
negativeModulationSPD = B_primary*(backgroundPrimary-(modulationPrimary - backgroundPrimary));
backgroundSPD = B_primary*backgroundPrimary;
wavelengthsNm = SToWls(S);

if p.Results.makePlots

    % Create a figure with an appropriate title
    fighandle = figure('Name',sprintf([whichDirection ': contrast = %2.2f'],contrastReceptors(1)));

    % Modulation spectra
    subplot(1,2,1)
    hold on
    plot(wavelengthsNm,positiveModulationSPD,'k','LineWidth',2);
    plot(wavelengthsNm,negativeModulationSPD,'r','LineWidth',2);
    plot(wavelengthsNm,backgroundSPD,'Color',[0.5 0.5 0.5],'LineWidth',2);
    title(sprintf('Modulation spectra [%2.2f]',contrastReceptors(whichReceptorsToTarget(1))));
    xlim([300 800]);
    xlabel('Wavelength');
    ylabel('Power');
    legend({'Positive', 'Negative', 'Background'},'Location','NorthEast');

    % Primaries
    subplot(1,2,2)
    c = 0:7;
    hold on
    plot(c,modulationPrimary,'*k');
    plot(c,backgroundPrimary+(-(modulationPrimary-backgroundPrimary)),'*r');
    plot(c,backgroundPrimary,'-*','Color',[0.5 0.5 0.5]);
    set(gca,'TickLabelInterpreter','none');
    title('Primary settings');
    ylim([0 1]);
    xlabel('Primary');
    ylabel('Setting');
end

for ii = 1:8
    str = '{ ';
    for bb = -22:1:22
        level = round(4095 * (backgroundPrimary(ii)+ (bb/22)*(-(modulationPrimary(ii)-backgroundPrimary(ii)))));
        val = round(4095 * cal.processedData.gammaTable(level+1,ii));
        settings(ii,bb+23) = val;
        str = [str sprintf('%d, ',val)];
    end
    str = str(1:end-2);
    str = [str ' },\n'];
    %    fprintf(str);
end

modResult.settings = settings;

end

