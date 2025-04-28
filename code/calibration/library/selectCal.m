function [cal, calFileName, calDir] = selectCal()

% Figure out where the cal files are located
calSubDirFlag = false;
calDir = string(getpref('combiLEDToolbox','CalDataFolder'));
calsList = dir(fullfile(calDir,'*mat'));
if isempty(calsList)
    calsList = dir(fullfile(calDir,'*','*mat'));
    calSubDirFlag = true;
end

% Extract the cal names
for ii=1:length(calsList)
    calFileNames{ii}=calsList(ii).name;
end

% Select a cals file
charSet = [97:97+25, 65:65+25];
fprintf('\nSelect a calibration:\n')
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
calDir = string(calsList(idx).folder);
calFileName = string(calFileNames{idx});
load(fullfile(calDir,calFileName),'cals')

% Ask which calibration to use
if length(cals)>1
    whichCal = input(['Which cal to use? [1:' num2str(length(cals)) ']: ']);
else
    whichCal = 1;
end
cal = cals(whichCal);

end