% SACC_calibrateMonitor
%
% Executive script for object-oriented-based monitor calibration.

% History:
%    03/27/2014  npc   Wrote it.
%    08/05/2014  npc   Added option to conduct PsychImaging - based calibration
%    03/02/2015  npc   Re-organized script so that settings and options are set in
%                      a single function.
%    08/30/2016  jar   Added calibration configuration for the InVivo Sensa Vue
%                      Flat panel monitor located at the Stellar Chance 3T Magnet.
%    10/18/2017  npc   Reset Radiometer before crashing
%    12/12/2017  ana   Added eye tracker LCD case
%    11/24/2021  smo   Delete the RadiometerOBJ and substitue it with SACC
%                      measurement codes. It works faster and fine.
%    12/15/2021  smo   Copied the object @PsychImagingCalibrator from BLTB
%                      and changed the name as @SACCPsychImagingCalibrator.
%                      This is for using our SACC functions (cf.
%                      measurement) in all calibrations.
%    02/05/2023  gka   Modified for the Prizmatix CombiLED

function calibrateCombiLED

% Select a calibration configuration name
AvailableCalibrationConfigs = {  ...
    '@CombiLEDcalibrator'
    };

% Default config is @CombiLEDcalibrator
defaultCalibrationConfig = AvailableCalibrationConfigs{find(contains(AvailableCalibrationConfigs, '@CombiLEDcalibrator'))};

while (true)
    fprintf('Available calibration configurations \n');
    for k = 1:numel(AvailableCalibrationConfigs)
        fprintf('\t %s\n', AvailableCalibrationConfigs{k});
    end
    calibrationConfig = input(sprintf('Select a calibration config [%s]: ', defaultCalibrationConfig),'s');
    if isempty(calibrationConfig)
        calibrationConfig = defaultCalibrationConfig;
    end
    if (ismember(calibrationConfig, AvailableCalibrationConfigs))
        break;
    else
        fprintf(2,'** %s ** is not an available calibration configuration. Try again. \n\n', calibrationConfig);
    end
end

% Generate calibration options and settings
runtimeParams = [];
switch calibrationConfig

    case '@CombiLEDcalibrator'
        configFunctionHandle = @generateConfigurationForCombiLED;

    otherwise
        error('Not a valid calibration config')
end


if (isempty(runtimeParams))
    [displaySettings, calibratorOptions] = configFunctionHandle();
else
    [displaySettings, calibratorOptions] = configFunctionHandle(runtimeParams);
end

% Open the spectroradiometer.
OpenSpectroradiometer('measurementOption',false);

radiometerOBJ = OLOpenSpectroRadiometerObj('PR-670');

% Generate the calibrator object
calibratorOBJ = generateCalibratorObject(displaySettings, radiometerOBJ, mfilename);

% Set the calibrator options
calibratorOBJ.options = calibratorOptions;

% display calStruct if so desired
beVerbose = false;
if (beVerbose)
    % Optionally, display the cal struct before measurement
    calibratorOBJ.displayCalStruct();
end

%    try
% Calibrate !
calibratorOBJ.calibrate();

if (beVerbose)
    % Optionally, display the updated cal struct after the measurement
    calibratorOBJ.displayCalStruct();
end

% Optionally, export cal struct in old format, for backwards compatibility with old programs.
% calibratorOBJ.exportOldFormatCal();

disp('All done with the calibration ...');

% Shutdown DBLab_Calibrator
calibratorOBJ.shutDown();

% Shutdown spectroradiometer.
CloseSpectroradiometer;

%     catch err
%         % Shutdown DBLab_Calibrator object
%         if (~isempty(calibratorOBJ))
%             % Shutdown calibratorOBJ
%             calibratorOBJ.shutDown();
%         end
%
%         % Shutdown spectroradiometer.
%         CloseSpectroradiometer;
%
%         rethrow(err)
%     end % end try/catch

end



function radiometerOBJ = generateRadiometerObject(calibrationConfig)

    if (strcmp(calibrationConfig, 'debugMode'))
        % Dummy radiometer - measurements will be all zeros
        radiometerOBJ = PR670dev('emulateHardware',  true);
        fprintf('Will employ a dummy PR670dev radiometer (all measurements will be zeros).\n');
        return;
    end
    
    
    % List of available @Radiometer objects
    radiometerTypes = {'PR650dev', 'PR670dev', 'SpectroCALdev'};
    radiometersNum  = numel(radiometerTypes);
    
    % Ask the user to select a calibrator type
    fprintf('\n\n Available radiometer types:\n');
    for k = 1:radiometersNum
        fprintf('\t[%3d]. %s\n', k, radiometerTypes{k});
    end
    defaultRadiometerIndex = 1;
    radiometerIndex = input(sprintf('\tSelect a radiometer type (1-%d) [%d]: ', radiometersNum, defaultRadiometerIndex));
    if isempty(radiometerIndex) || (radiometerIndex < 1) || (radiometerIndex > radiometersNum)
        radiometerIndex = defaultRadiometerIndex;
    end
    fprintf('\n\t-------------------------\n');
    selectedRadiometerType = radiometerTypes{radiometerIndex};
    fprintf('Will employ an %s radiometer object [%d].\n', selectedRadiometerType, radiometerIndex);
    
    if (strcmp(selectedRadiometerType, 'PR650dev'))
        radiometerOBJ = PR650dev(...
            'verbosity',        1, ...                  % 1 -> minimum verbosity
            'devicePortString', '/dev/cu.KeySerial1');  % PR650 port string

    elseif (strcmp(selectedRadiometerType, 'PR670dev'))
        radiometerOBJ = PR670dev(...
            'verbosity',        1, ...       % 1 -> minimum verbosity
            'devicePortString', [] ...       % empty -> automatic port detection
            );
        
        % Specify extra properties
        desiredSyncMode = 'OFF';
        desiredCyclesToAverage = 1;
        desiredSensitivityMode = 'STANDARD';
        desiredApertureSize = '1 DEG';
        desiredExposureTime =  'ADAPTIVE';  % 'ADAPTIVE' or range [1-6000 msec] or [1-30000 msec]
        
        radiometerOBJ.setOptions(...
        	'syncMode',         desiredSyncMode, ...
            'cyclesToAverage',  desiredCyclesToAverage, ...
            'sensitivityMode',  desiredSensitivityMode, ...
            'apertureSize',     desiredApertureSize, ...
            'exposureTime',     desiredExposureTime ...
        );
    elseif (strcmp(selectedRadiometerType, 'SpectroCALdev'))
        radiometerOBJ = SpectroCALdev();
    end
    
end


% Configuration function for the SACC display (LED/DLP optical system)
function [displaySettings, calibratorOptions] = generateConfigurationForCombiLED()
% Specify where to send the 'Calibration Done' notification email
emailAddressForNotification = 'aguirreg@upenn.edu';

% Specify the @Calibrator's initialization params.
% Users should tailor these according to their hardware specs.
% These can be set once only, at the time the @Calibrator object is instantiated.
displayPrimariesNum = 8;
displaySettings = { ...
    'screenToCalibrate',        2, ...                          % which display to calibrate. main screen = 1, second display = 2
    'desiredScreenSizePixel',   [1920 1080], ...                % pixels along the width and height of the display to be calibrated
    'desiredRefreshRate',       120, ...                        % refresh rate in Hz
    'displayPrimariesNum',      displayPrimariesNum, ...        % for regular displays this is always 3 (RGB)
    'displayDeviceType',        'monitor', ...                  % this should always be set to 'monitor' for now
    'displayDeviceName',        'CombiLED', ...                     % a name for the display been calibrated
    'calibrationFile',          'CombiLED', ...                     % name of calibration file to be generated
    'comment',                  'The CombiLED light engine' ...          % some comment, could be anything
    };

% Specify the @Calibrator's optional params using a CalibratorOptions object
% To see what options are available type: doc CalibratorOptions
% Users should tailor these according to their experimental needs.
calibratorOptions = CalibratorOptions( ...
    'verbosity',                        2, ...
    'whoIsDoingTheCalibration',         input('Enter your name: ','s'), ...
    'emailAddressForDoneNotification',  GetWithDefault('Enter email address for done notification',  emailAddressForNotification), ...
    'blankOtherScreen',                 0, ...                          % whether to blank other displays attached to the host computer (1=yes, 0 = no), ...
    'whichBlankScreen',                 1, ...                          % screen number of the display to be blanked  (main screen = 1, second display = 2)
    'blankSettings',                    [0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 ], ...              % color of the whichBlankScreen
    'bgColor',                          [0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 ], ...     % color of the background
    'fgColor',                          [0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 ], ...     % color of the foreground
    'meterDistance',                    1.0, ...                        % distance between radiometer and screen in meters
    'leaveRoomTime',                    3, ...                          % seconds allowed to leave room
    'nAverage',                         1, ...                          % number of repeated measurements for averaging
    'nMeas',                            10, ...                          % samples along gamma curve
    'nDevices',                         displayPrimariesNum, ...        % number of primaries
    'boxSize',                          600, ...                        % size of calibration stimulus in pixels
    'boxOffsetX',                       0, ...                          % x-offset from center of screen (neg: leftwards, pos:rightwards)
    'boxOffsetY',                       0, ...                           % y-offset from center of screen (neg: upwards, pos: downwards)
    'skipLinearityTest',                true, ...
    'skipAmbientLightMeasurement',      true, ...
    'skipBackgroundDependenceTest',     true ...
    );
end



% Function to generate the calibrator object.
%
% Users should not modify this function unless they know what they are doing.
%
% This function has been updated to exclude the radiometerOBJ to substitue
% it with SACC measurement functions.
function calibratorOBJ = generateCalibratorObject(displaySettings, radiometerOBJ, execScriptFileName)
% set init params
calibratorInitParams = displaySettings;

    % add radiometerOBJ
    calibratorInitParams{numel(calibratorInitParams)+1} = 'radiometerObj';
    calibratorInitParams{numel(calibratorInitParams)+1} = radiometerOBJ;

% add executive script name
calibratorInitParams{numel(calibratorInitParams)+1} ='executiveScriptName';
calibratorInitParams{numel(calibratorInitParams)+1} = execScriptFileName;

% Select and instantiate the calibrator object
calibratorOBJ = selectAndInstantiateCalibrator(calibratorInitParams);
end

% Function to select and instantiate a particular calibrator type
%
% Users should not modify this function unless they know what they are doing.
%
% In this function, radiometerOBJ has been also deleted and we use SACC
% measure function instead.
function calibratorOBJ = selectAndInstantiateCalibrator(calibratorInitParams)

% List of available @Calibrator objects
calibratorTypes = {'CombiLED'};
calibratorsNum  = numel(calibratorTypes);

% Ask the user to select a calibrator type
fprintf('\n\n Available calibrator types:\n');
for k = 1:calibratorsNum
    fprintf('\t[%3d]. %s\n', k, calibratorTypes{k});
end
defaultCalibratorIndex = 1;
calibratorIndex = input(sprintf('\tSelect a calibrator type (1-%d) [%d]: ', calibratorsNum, defaultCalibratorIndex));
if isempty(calibratorIndex) || (calibratorIndex < 1) || (calibratorIndex > calibratorsNum)
    calibratorIndex = defaultCalibratorIndex;
end
fprintf('\n\t-------------------------\n');
selectedCalibratorType = calibratorTypes{calibratorIndex};
fprintf('Will employ an %s calibrator object [%d].\n', selectedCalibratorType, calibratorIndex);

calibratorOBJ = [];

try
    % Instantiate an Calibrator object with the required configration variables.
    calibratorOBJ = CombiLEDcalibrator(calibratorInitParams);

catch err
    % Shutdown the radiometer
    CloseSpectroradiometer;

    % Shutdown DBLab_Radiometer object
    if (~isempty(calibratorOBJ))
        % Shutdown calibratorOBJ
        calibratorOBJ.shutDown();
    end

    rethrow(err)
end % end try/catch
end