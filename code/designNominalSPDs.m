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
p.parse(varargin{:});



whichModel = 'human';
whichPrimaries = 'monitor';
curDir = pwd;

% Obtain SPDs of the primaries
spdTablePath = fullfile(fileparts(fileparts(mfilename('fullpath'))),'data','PrizmatixLEDSet.csv');
spdTable = readtable(spdTablePath);

% Derive the primaries from the SPD table
wavelengthSupport = spdTable.Wavelength;
S = [wavelengthSupport(1), wavelengthSupport(2)-wavelengthSupport(1), length(wavelengthSupport)];
B_primary = table2array(spdTable(:,2:end));

% I don't yet have the absolute power measurements of the primaries, and
% some are more normalized than others, so set all to have unit amplitude
% here.
B_primary = B_primary./max(B_primary);

figure; plot(wavelengthSupport,B_primary');

nPrimaries = size(B_primary,2);
ambientSpd = zeros(S(3),1);

% Set background to the half-on
backgroundPrimary = repmat(0.5,nPrimaries,1);


%% Get sensitivities and set other relvant parameters
% The routines that do these computations are in the ContrastSplatter
% directory of the SilentSubstitutionToolbox. They provide pre-defined
% receptor types and compute spectral sensitivities using the routines
% provided in the Psychtoolbox. The routines here, however, also allow
% computation of fraction cone bleached, which may be used to adjust
% pigment peak optical density.  They can also compute photopigment
% variants corrected for filtering by blood vessels.


% Define photoreceptor classes that we'll consider.
% ReceptorIsolate has a few more built-ins than these.
photoreceptorClasses = {...
    'LConeTabulatedAbsorbance2Deg', 'MConeTabulatedAbsorbance2Deg', 'SConeTabulatedAbsorbance2Deg',...
    'LConeTabulatedAbsorbance10Deg', 'MConeTabulatedAbsorbance10Deg', 'SConeTabulatedAbsorbance10Deg',...
    'Melanopsin'};

resultSet.photoreceptorClasses = {'L_2deg','M_2deg','S_2deg','L_10deg','M_10deg','S_10deg','Mel'};

% set the receptor sets to isolate
% whichDirectionSet = {'LMS','LminusM','S','Mel'};
% whichReceptorsToTargetSet = {[1:6],[1 2 4 5],[3 6],[7]};
% whichReceptorsToIgnoreSet = {[],[7],[7],[]};
% whichReceptorsToMinimizeSet = {[],[],[],[]}; % This can be left empty. Any receptor that is neither targeted nor ignored will be silenced
% desiredContrastSet = {[0.45 0.45 0.45 0.45 0.45 0.45 ],[0.10 -0.10 0.10 -0.10],[0.7 0.7],[0.5]};

whichDirectionSet = {'Spatial'};
whichReceptorsToTargetSet = {[1 2 4 5]};
whichReceptorsToIgnoreSet = {[3 6 7]};
whichReceptorsToMinimizeSet = {[]}; % This can be left empty. Any receptor that is neither targeted nor ignored will be silenced
desiredContrastSet = {[-0.1 0.1 0.1 -0.1]};


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


figure; plot(wavelengthSupport,T_receptors);

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
    
    % No smoothness constraint enforced for the monitor primaries
    maxPowerDiff = 10000;
    
    % Obtain the primary settings for the isolating modulation
    modulationPrimary = ReceptorIsolate(T_receptors,whichReceptorsToTarget, whichReceptorsToIgnore, whichReceptorsToMinimize, ...
        B_primary, backgroundPrimary, backgroundPrimary, whichPrimariesToPin,...
        p.Results.primaryHeadRoom, maxPowerDiff, desiredContrast, ambientSpd);
    
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
    
    % Create and save results
    if ~isempty(p.Results.saveDir)
        if ~isdir(p.Results.saveDir)
            mkdir(p.Results.saveDir);
        end
        cd(p.Results.saveDir);
       
        % Create a figure with an appropriate title
        fighandle = figure('Name',sprintf([whichDirection ': contrast = %2.2f'],resultSet.(whichDirection).positiveReceptorContrast(whichReceptorsToTargetSet{ss}(1))));
               
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
        plot(c,modulationPrimary,'*k');
        plot(c,backgroundPrimary+(-(modulationPrimary-backgroundPrimary)),'*r');
        plot(c,backgroundPrimary,'-*','Color',[0.5 0.5 0.5]);
        title('Primary settings');
        ylim([0 1]);
        xlabel('Primary');
        ylabel('Setting');
        
        % Save the figure
        saveas(fighandle,sprintf('%s_%s_%s_PrimariesAndSPD.pdf',whichModel,whichPrimaries,whichDirection),'pdf');
    end
end


%% Return to the directory from whence we started
cd(curDir);