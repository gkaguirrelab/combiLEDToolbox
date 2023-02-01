% calibrateCombiLED
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
%    11/24/2021  smo   Delete the RadiometerOBJ and substitue it with PRIZ
%                      measurement codes. It works faster and fine.
%    12/15/2021  smo   Copied the object @PsychImagingCalibrator from BLTB
%                      and changed the name as @PRIZPsychImagingCalibrator.
%                      This is for using our PRIZ functions (cf.
%                      measurement) in all calibrations. 
%    02/01/2023  gka   Modifying for the 8-primary Prizmatix CombiLED 

function PRIZ_calibrateMonitor
    
    % Select a calibration configuration name
    AvailableCalibrationConfigs = {  ...
        'PRIZ'
    };
    
    % Default config is PRIZPrimary1
    defaultCalibrationConfig = AvailableCalibrationConfigs{find(contains(AvailableCalibrationConfigs, 'PRIZ'))};
    
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
            
        case 'PRIZ'
            configFunctionHandle = @generateConfigurationForPRIZ; 
            
        otherwise
            error('Unknown calibration configuration');
    end
    

    if (isempty(runtimeParams))
        [displaySettings, calibratorOptions] = configFunctionHandle();
    else
        [displaySettings, calibratorOptions] = configFunctionHandle(runtimeParams);
    end

    % Open the spectroradiometer.
    OpenSpectroradiometer('measurementOption',false);

    % Generate the calibrator object
    calibratorOBJ = generateCalibratorObject(displaySettings, mfilename);
    
    % Set the calibrator options
    calibratorOBJ.options = calibratorOptions;
        
    % display calStruct if so desired
    beVerbose = false;
    if (beVerbose)
        % Optionally, display the cal struct before measurement
        calibratorOBJ.displayCalStruct();
    end
        
    try 
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
          
    catch err
        % Shutdown DBLab_Calibrator object  
        if (~isempty(calibratorOBJ))
            % Shutdown calibratorOBJ
            calibratorOBJ.shutDown();
        end
        
        % Shutdown spectroradiometer.
        CloseSpectroradiometer;

        rethrow(err)
    end % end try/catch
end

% Configuration function for the PRIZ display (LED/DLP optical system)
function [displaySettings, calibratorOptions] = generateConfigurationForPRIZ()
    % Specify where to send the 'Calibration Done' notification email
    emailAddressForNotification = 'aguirreg@upenn.edu';
    
    % Specify the @Calibrator's initialization params. 
    % Users should tailor these according to their hardware specs. 
    % These can be set once only, at the time the @Calibrator object is instantiated.
    displayPrimariesNum = 8;
    displaySettings = { ...
        'screenToCalibrate',        2, ...                          % which display to calibrate. main screen = 1, second display = 2
        'desiredScreenSizePixel',   [1 1], ...                % pixels along the width and height of the display to be calibrated
        'desiredRefreshRate',       120, ...                        % refresh rate in Hz
        'displayPrimariesNum',      displayPrimariesNum, ...        % for regular displays this is always 3 (RGB) 
        'displayDeviceType',        'monitor', ...                  % this should always be set to 'monitor' for now
        'displayDeviceName',        'PRIZ', ...                     % a name for the display been calibrated
        'calibrationFile',          'PRIZ', ...                     % name of calibration file to be generated
        'comment',                  'The Prizmatix CombiLED 8-channel light engine' ...          % some comment, could be anything
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
        'blankSettings',                    [0.0 0.0 0.0], ...              % color of the whichBlankScreen 
        'bgColor',                          [0.3962 0.3787 0.4039], ...     % color of the background  
        'fgColor',                          [0.3962 0.3787 0.4039], ...     % color of the foreground
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
% it with PRIZ measurement functions.
function calibratorOBJ = generateCalibratorObject(displaySettings, execScriptFileName)
    % set init params
    calibratorInitParams = displaySettings;

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
% In this function, radiometerOBJ has been also deleted and we use PRIZ
% measure function instead.
function calibratorOBJ = selectAndInstantiateCalibrator(calibratorInitParams)
    
    calibratorOBJ = [];

                calibratorOBJ = PRIZPrimaryCalibrator(calibratorInitParams);
% 
%     try
%             calibratorOBJ = PRIZPrimaryCalibrator(calibratorInitParams);
%         
%     catch err
% 
%         % Shutdown the radiometer
%         CloseSpectroradiometer;
%         
%         % Shutdown DBLab_Radiometer object  
%         if (~isempty(calibratorOBJ))
%             % Shutdown calibratorOBJ
%             calibratorOBJ.shutDown();
%         end
%         
%         rethrow(err)
%    end % end try/catch
end