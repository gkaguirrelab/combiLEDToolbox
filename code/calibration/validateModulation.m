function validateModulation(modResultFilePath)
%
% A modified version of calibrateCombiLED designed to measure spectra
% defined by a modResult file and compare the observed with the predicted
% output.
%

% If the modResultFilePath is empty or undefined, offer a file picker
if nargin == 0
    modResultFilePath = '';
end

% Validation files will be saved at the location of the modResultFile
if isempty(modResultFilePath)
    [modName,modPath] = uigetfile;
else
    [modPath,modName,ext] = fileparts(modResultFilePath);
    modName = [modName ext];
end

% This preference setting is used by the calibration code to define the
% save location
setpref('BrainardLabToolbox','CalDataFolder',modPath);

% Let the user know where files will be saved
fprintf('\n****************\validation files will be saved in:\n')
fprintf(['\t' modPath '\n']);

% Load the modResult
load(fullfile(modPath,modName),'modResult');

% Create a default calibration file name
defaultName = strrep(modName,'.mat','_validation.mat');

% Ask the user to provide a name for the calibration file
valFileName = GetWithDefault('Name for the validation file',defaultName);

% Ask how many averages are to obtained
nAverage = GetWithDefault('How many averages to obtain',3);

% Generate calibration options and settings
[displaySettings, calibratorOptions] = generateConfigurationForCombiLED(valFileName);

% Get the email address to report the results
emailAddress = GetWithDefault('Email address for notification','myname@upenn.edu');
calibratorOptions.emailAddressForDoneNotification = emailAddress;

% Update the number of averages
calibratorOptions.nAverage = nAverage;

% Offer a recommendation regarding connecting devices
fprintf('Connect and start the PR670; do not connect the CombiLED yet.\n')
fprintf('Press any key when ready.\n\n')
pause

% Open the spectroradiometer
OpenSpectroradiometer('measurementOption',false);

% Create the radiometer object
radiometerOBJ = openSpectroRadiometerObj('PR-670');

% Offer a recommendation regarding connecting devices
fprintf('Now connect and start the CombiLED. Press any key when ready.\n')
pause

% Generate the calibrator object
calibratorOBJ = generateCalibratorObject(displaySettings, radiometerOBJ, modResult);

% Set the calibrator options
calibratorOBJ.options = calibratorOptions;

% Calibrate
calibratorOBJ.calibrate();

% Shutdown DBLab_Calibrator
calibratorOBJ.shutDown();

% Shutdown spectroradiometer.
CloseSpectroradiometer;

end


%% LOCAL FUNCTIONS

function [displaySettings, calibratorOptions] = generateConfigurationForCombiLED(calFileName)

% Specify the @Calibrator's initialization params. Users should tailor
% these according to their hardware specs. These can be set once only, at
% the time the @Calibrator object is instantiated.
displayPrimariesNum = 1;
displaySettings = { ...
    'screenToCalibrate',        2, ...                          % which display to calibrate. main screen = 1, second display = 2
    'desiredScreenSizePixel',   [1 1], ...                      % pixels along the width and height of the display to be calibrated
    'desiredRefreshRate',       120, ...                        % refresh rate in Hz
    'displayPrimariesNum',      displayPrimariesNum, ...        % for regular displays this is always 3 (RGB)
    'displayDeviceType',        'monitor', ...                  % this should always be set to 'monitor' for now
    'displayDeviceName',        'CombiLED', ...                 % a name for the display been calibrated
    'calibrationFile',          calFileName, ...                % name of calibration file to be generated
    'comment',                  'The CombiLED light engine' ... % some comment, could be anything
    };

% Need to create a dummy linearity testing table to pass validation
customLinearitySetup.settings = zeros(3,4);

% Specify the @Calibrator's optional params using a CalibratorOptions object
% To see what options are available type: doc CalibratorOptions
% Users should tailor these according to their experimental needs.
calibratorOptions = CalibratorOptions( ...
    'verbosity',                        1, ...
    'whoIsDoingTheCalibration',         'CombiLED user', ...
    'emailAddressForDoneNotification',  '', ...
    'blankOtherScreen',                 0, ...                          % whether to blank other displays attached to the host computer (1=yes, 0 = no), ...
    'whichBlankScreen',                 1, ...                          % screen number of the display to be blanked  (main screen = 1, second display = 2)
    'blankSettings',                    zeros(1,displayPrimariesNum), ...                 % color of the whichBlankScreen
    'bgColor',                          zeros(1,displayPrimariesNum), ...                 % color of the background
    'fgColor',                          zeros(1,displayPrimariesNum), ...                 % color of the foreground
    'meterDistance',                    0.1, ...                        % distance between radiometer and screen in meters
    'leaveRoomTime',                    5, ...                         % seconds allowed to leave room
    'nAverage',                         3, ...                         % number of repeated measurements for averaging
    'nMeas',                            16, ...                          % samples along gamma curve
    'nDevices',                         displayPrimariesNum, ...        % number of primaries
    'boxSize',                          1, ...                          % size of calibration stimulus in pixels
    'boxOffsetX',                       0, ...                          % x-offset from center of screen (neg: leftwards, pos:rightwards)
    'boxOffsetY',                       0, ...                          % y-offset from center of screen (neg: upwards, pos: downwards)
    'skipLinearityTest',                true, ...
    'skipAmbientLightMeasurement',      false, ...
    'skipBackgroundDependenceTest',     true, ...
    'customLinearitySetup',             customLinearitySetup ...
    );
end


% Function to generate the calibrator object.
function calibratorOBJ = generateCalibratorObject(displaySettings, radiometerOBJ, modResult)

% set init params
calibratorInitParams = displaySettings;

% add radiometerOBJ
calibratorInitParams{numel(calibratorInitParams)+1} = 'radiometerObj';
calibratorInitParams{numel(calibratorInitParams)+1} = radiometerOBJ;

% add executive script name
calibratorInitParams{numel(calibratorInitParams)+1} ='executiveScriptName';
calibratorInitParams{numel(calibratorInitParams)+1} = '';

% instantiate the calibrator object
calibratorOBJ = CombiLEDvalidator(calibratorInitParams,modResult);

end

