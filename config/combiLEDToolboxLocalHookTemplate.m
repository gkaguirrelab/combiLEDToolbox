function combiLEDToolboxLocalHook

%  combiLEDToolboxLocalHook
%
% As part of the setup process, ToolboxToolbox will copy this file to your
% ToolboxToolbox localToolboxHooks directory (minus the "Template" suffix).
% The defalt location for this would be
%   ~/localToolboxHooks/combiLEDToolboxLocalHook.m
%
% Each time you run tbUseProject('combiLEDToolbox'), ToolboxToolbox will
% execute your local copy of this file to do setup for prizmatixDesign.
%
% You should edit your local copy with values that are correct for your
% local machine, for example the output directory location.
%


% Say hello.
projectName = 'combiLEDToolbox';

% Delete any old prefs
if (ispref(projectName))
    rmpref(projectName);
end

% Handle hosts with custom dropbox locations
[~, userName] = system('whoami');
userName = strtrim(userName);
switch userName
    case 'aguirre'
        dropBoxUserFullName = 'Geoffrey Aguirre';
        dropboxBaseDir = fullfile(filesep,'Users',userName,...
            'Aguirre-Brainard Lab Dropbox',dropBoxUserFullName);
    otherwise
        dropboxBaseDir = ...
            fullfile('/Users', userName, ...
            'Aguirre-Brainard Lab Dropbox',userName);
end

% Set preferences for project output
setpref(projectName,'dropboxBaseDir',dropboxBaseDir); % main directory path 


%% Check for required Matlab toolboxes
% The set of Matlab add-on toolboxes being used can be determined by
% running the ExampleTest code, followed by the license function.
%{
    RunExamples(fullfile(userpath(),'toolboxes','gkaModelEye'));
    license('inuse')
%}
% This provides a list of toolbox license names. In the following
% assignment, the license name is given in the comment string after the
% matching version name for each toolbox.
requiredAddOns = {...
    'Optimization Toolbox',...                  % optimization_toolbox
    'Image Processing Toolbox',...               % image_toolbox
    };
% Given this hard-coded list of add-on toolboxes, we then check for the
% presence of each and issue a warning if absent.
V = ver;
VName = {V.Name};
warnState = warning();
warning off backtrace
for ii=1:length(requiredAddOns)
    if ~any(strcmp(VName, requiredAddOns{ii}))
        warnString = ['The Matlab ' requiredAddOns{ii} ' is missing. ' toolboxName ' may not function properly.'];
        warning('localHook:requiredMatlabToolboxCheck',warnString);
    end
end
warning(warnState);

end