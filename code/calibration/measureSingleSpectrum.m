% measureSingleSpectrum
%
% A modified version of calibrateCombiLED designed to measure a the full-on
% spectrum of the device, and the ambient
%

function measureSingleSpectrum

% Set the save location for cal files. To do so, we need to make sure that
% the BrainardLabToolbox preference 'CalDataFolder' is empty, so that the
% OOC calibrator code uses the path that we provide instead
calLocalData = getpref('combiLEDToolbox','CalDataFolder');
setpref('BrainardLabToolbox','CalDataFolder',calLocalData);
fprintf('\n****************\nCal files will be saved in:\n')
fprintf(['\t' calLocalData '\n']);
fprintf('If a different location is desired, quit this routine and set the CalDataFolder preference for combiLEDToolbox.\n****************\n\n')

% Offer a recommendation regarding connecting devices
fprintf('Connect and start the PR670; do not connect the CombiLED yet.\n')
fprintf('Press any key when ready.\n\n')
pause

% Ask the user about the measurement conditions
fprintf('Information regarding the device configuration:\n')
cableType = GetWithDefault('Fiber optic cable type','shortLLG');
eyePieceType = GetWithDefault('Display type','classicEyePiece');
ndfValue = GetWithDefault('NDF','0');

% Replace any decimal points in the ndfValue with "x"
ndfValue = strrep(ndfValue,'.','x');

% Create a default calibration file name
defaultName = ['CombiLED_' cableType '_' eyePieceType '_ND' ndfValue '_maxSpectrum'];

% Ask the user to provide a name for the calibration file
calFileName = GetWithDefault('Name for the cal file',defaultName);

% Ask how many averages are to obtained
nAverage = GetWithDefault('How many averages to obtain',25);

% Generate calibration options and settings
[displaySettings, calibratorOptions] = generateConfigurationForCombiLED(calFileName);

% Get the email address to report the results
emailAddress = GetWithDefault('Email address for notification','myname@upenn.edu');
calibratorOptions.emailAddressForDoneNotification = emailAddress;

% Update the number of averages
calibratorOptions.nAverage = nAverage;

% Open the spectroradiometer
OpenSpectroradiometer('measurementOption',false);

% Create the radiometer object
radiometerOBJ = openSpectroRadiometerObj('PR-670');

% Offer a recommendation regarding connecting devices
fprintf('Now connect and start the CombiLED. Press any key when ready.\n')
pause

% Generate the calibrator object
calibratorOBJ = generateCalibratorObject(displaySettings, radiometerOBJ, mfilename);

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
    'verbosity',                        0, ...
    'whoIsDoingTheCalibration',         'CombiLED user', ...
    'emailAddressForDoneNotification',  '', ...
    'blankOtherScreen',                 0, ...                          % whether to blank other displays attached to the host computer (1=yes, 0 = no), ...
    'whichBlankScreen',                 1, ...                          % screen number of the display to be blanked  (main screen = 1, second display = 2)
    'blankSettings',                    zeros(1,displayPrimariesNum), ...                 % color of the whichBlankScreen
    'bgColor',                          zeros(1,displayPrimariesNum), ...                 % color of the background
    'fgColor',                          zeros(1,displayPrimariesNum), ...                 % color of the foreground
    'meterDistance',                    0.1, ...                        % distance between radiometer and screen in meters
    'leaveRoomTime',                    30, ...                         % seconds allowed to leave room
    'nAverage',                         25, ...                         % number of repeated measurements for averaging
    'nMeas',                            1, ...                          % samples along gamma curve
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
function calibratorOBJ = generateCalibratorObject(displaySettings, radiometerOBJ, execScriptFileName)

% set init params
calibratorInitParams = displaySettings;

% add radiometerOBJ
calibratorInitParams{numel(calibratorInitParams)+1} = 'radiometerObj';
calibratorInitParams{numel(calibratorInitParams)+1} = radiometerOBJ;

% add executive script name
calibratorInitParams{numel(calibratorInitParams)+1} ='executiveScriptName';
calibratorInitParams{numel(calibratorInitParams)+1} = execScriptFileName;

% instantiate the calibrator object
calibratorOBJ = CombiLEDcalibrator(calibratorInitParams);

end

