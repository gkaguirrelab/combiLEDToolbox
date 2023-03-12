% Interacts with the OOC CalibratorAnalyzer routines in the BrainardLab
% Toolbox. Asks the user to select one of the CombiLED calibration files
% and then displays the analysis results for themost recent calibration.


% Figure out where the cal files are located
calDir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'cal');
calsList = dir(fullfile(calDir,'*mat'));

% Extract the cal names
for ii=1:length(calsList)
    calFileNames{ii}=calsList(ii).name;
end

% Select a cals file
charSet = [97:97+25, 65:65+25];
fprintf('\nSelect a modDemos:\n')
for pp=1:length(calFileNames)
    optionName=['\t' char(charSet(pp)) '. ' calFileNames{pp} '\n'];
    fprintf(optionName);
end
choice = input('\nYour choice (return for done): ','s');
if ~isempty(choice)
    choice = int32(choice);
    idx = find(charSet == choice);
else
    return
end

% Load the selected cals file
calFileName = calFileNames{idx};
load(fullfile(calDir,calFileName),'cals')

% Use the last calibration
cal = cals{end};

% Open a calibration analysis object
calAnalysisObj = CalibratorAnalyzer(cal, calFileName, calDir);

% Save the warning state and silence a java warning
warningState = warning;
warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved');

% Analyze
calAnalysisObj.analyze;

% Restore the warning state
warning(warningState);

