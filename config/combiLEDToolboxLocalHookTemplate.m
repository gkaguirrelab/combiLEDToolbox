function combiLEDToolboxLocalHook

%  combiLEDToolboxLocalHook
%
% Configure things for working on the prizmatixDesign project.
%
% For use with the ToolboxToolbox.
%
% If you 'git clone' prizmatixDesign into your ToolboxToolbox "projectRoot"
% folder, then run in MATLAB
%   tbUseProject('prizmatixDesign')
% ToolboxToolbox will set up prizmatixDesign and its dependencies on
% your machine.
%
% As part of the setup process, ToolboxToolbox will copy this file to your
% ToolboxToolbox localToolboxHooks directory (minus the "Template" suffix).
% The defalt location for this would be
%   ~/localToolboxHooks/prizmatixDesignLocalHook.m
%
% Each time you run tbUseProject('prizmatixDesign'), ToolboxToolbox will
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

% Obtain the Dropbox path
[~,hostname] = system('hostname');
hostname = strtrim(lower(hostname));

% Handle hosts with custom dropbox locations
switch hostname
    case 'gka-macbook.local'
        [~, userName] = system('whoami');
        userName = strtrim(userName);
        dropBoxUserFullName = 'Geoffrey Aguirre';
        assert(strcmp(userName,'aguirre'));
        dropboxBaseDir = fullfile(filesep,'Users',userName,...
            'Aguirre-Brainard Lab Dropbox',dropBoxUserFullName);
    otherwise
        [~, userName] = system('whoami');
        userName = strtrim(userName);
        dropboxBaseDir = ...
            fullfile('/Users', userName, ...
            'Aguirre-Brainard Lab Dropbox', userName);
end

% Set preferences for project output
setpref(projectName,'dropboxBaseDir',dropboxBaseDir); % main directory path 

end