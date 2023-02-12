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
% tbtbVerbose = getpref('ToolboxToolbox','verbose');
% setpref('ToolboxToolbox','verbose',false);

%% Parse input
p = inputParser;
p.addRequired('whichDirection',@ischar)
p.addParameter('calLocalData',fullfile(tbLocateProject('prizmatixDesign'),'cal','CombiLED.mat'),@ischar);
p.addParameter('searchBackground',true,@islogical)
p.addParameter('matchConstraint',1,@isscalar)
p.addParameter('primaryHeadRoom',0.00,@isscalar)
p.addParameter('observerAgeInYears',25,@isscalar)
p.addParameter('fieldSizeDegrees',30,@isscalar)
p.addParameter('pupilDiameterMm',2,@isscalar)
p.addParameter('verbose',false,@islogical)
p.addParameter('makePlots',true,@islogical)
p.parse(whichDirection,varargin{:});

% Restore the TbTb verbosity pref
% setpref('ToolboxToolbox','verbose',tbtbVerbose);

% Pull some variables out of the Results for code clarity
matchConstraint = p.Results.matchConstraint;
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
fractionBleached = [];
oxygenationFraction = [];
vesselThickness = [];
T_receptors = GetHumanPhotoreceptorSS(S, photoreceptorClasses, p.Results.fieldSizeDegrees, p.Results.observerAgeInYears, p.Results.pupilDiameterMm, [], fractionBleached, oxygenationFraction, vesselThickness);

% Define the modulation direction
[whichReceptorsToTarget,whichReceptorsToIgnore,desiredContrast,x0Background] = ...
    modDirectionDictionary(whichDirection);

% Define the isolation operation as a function of the background. Always
% use the background as the starting point of the modulation search
modulationPrimaryFunc = @(backgroundPrimary) ...
    isolateReceptors(T_receptors,whichReceptorsToTarget, ...
    whichReceptorsToIgnore, B_primary,backgroundPrimary,backgroundPrimary, ...
    primaryHeadRoom,desiredContrast,ambientSpd,matchConstraint);

% Define a function that returns the contrast on the targeted
% photoreceptors
contrastReceptorsFunc = @(modulationPrimary,backgroundPrimary) ...
    calcContrastReceptors(modulationPrimary,backgroundPrimary,T_receptors,B_primary,ambientSpd);

% Handle searching over backgrounds
if p.Results.searchBackground
    lb = zeros(1,nPrimaries)+primaryHeadRoom;
    plb = zeros(1,nPrimaries)+primaryHeadRoom;
    pub = ones(1,nPrimaries)-primaryHeadRoom;
    ub = ones(1,nPrimaries)-primaryHeadRoom;
    if verbose
        optionsBADS.Display = 'iter';
    else
        optionsBADS.Display = 'off';
    end
    % The optimization toolbox is currently not available for Matlab running
    % under Apple silicon. Detect this case and tell BADS so that it doesn't
    % issue a warning
    V = ver;
    if ~any(strcmp({V.Name}, 'Optimization Toolbox'))
        optionsBADS.OptimToolbox = 0;
    end
    % Set up an objective, which is attempting to maximize the contrast
    % provided on the targeted photoreceptor
    relevantContrast = @(contrastReceptors) contrastReceptors(whichReceptorsToTarget);
    myObj = @(x) -mean(relevantContrast(contrastReceptorsFunc(modulationPrimaryFunc(x'),x')).* (desiredContrast'));
   % backgroundPrimary = bads(myObj,x0Background',lb,ub,plb,pub,[],optionsBADS)';
    backgroundPrimary = x0Background;
else
    backgroundPrimary = repmat(0.5,size(B_primary,2),1);
end

% Perform the search with background background
modulationPrimary = modulationPrimaryFunc(backgroundPrimary);

% Get the contrast results
contrastReceptors = contrastReceptorsFunc(modulationPrimary,backgroundPrimary);

positiveModulationSPD = B_primary*modulationPrimary;
negativeModulationSPD = B_primary*(backgroundPrimary-(modulationPrimary - backgroundPrimary));
backgroundSPD = B_primary*backgroundPrimary;
wavelengthsNm = SToWls(S);

if p.Results.makePlots

    % Create a figure with an appropriate title
    fighandle = figure('Name',sprintf([whichDirection ': contrast = %2.2f'],contrastReceptors(whichReceptorsToTarget(1))));

    % Modulation spectra
    subplot(1,3,1)
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
    subplot(1,3,2)
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

    subplot(1,3,3)
    c = 1:length(photoreceptorClassNames);
    hold on
    bar(c(whichReceptorsToTarget),contrastReceptors(whichReceptorsToTarget),...
        'FaceColor',[0.5 0.5 0.5],'EdgeColor','none');
    hold on
    bar(c(whichReceptorsToIgnore),contrastReceptors(whichReceptorsToIgnore),...
        'FaceColor','w','EdgeColor','k');
    c(whichReceptorsToIgnore)=nan; c(whichReceptorsToTarget)=nan;
    whichReceptorsToSilence = c(~isnan(c));
    bar(c(whichReceptorsToSilence),contrastReceptors(whichReceptorsToSilence),...
        'FaceColor','none','EdgeColor','r');
    set(gca,'TickLabelInterpreter','none');
    title('Contrast');
    ylabel('Contrast');
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

%% LOCAL FUNCTIONS
function contrastReceptors = calcContrastReceptors(modulationPrimary,backgroundPrimary,T_receptors,B_primary,ambientSpd)

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