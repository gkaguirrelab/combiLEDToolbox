% Interacts with the OOC CalibratorAnalyzer routines in the BrainardLab
% Toolbox. Asks the user to select one of the CombiLED calibration files
% and then displays the analysis results for themost recent calibration.


% Select a cal file
[cal, calFileName, calDir] = selectCal();

% Open a calibration analysis object
calAnalysisObj = CalibratorAnalyzer(cal, calFileName, calDir);

% Save the warning state and silence a java warning
warningState = warning;
warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved');

% Analyze
calAnalysisObj.analyze;

% Restore the warning state
warning(warningState);

