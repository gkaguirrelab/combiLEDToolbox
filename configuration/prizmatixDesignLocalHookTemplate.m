function prizmatixDesignLocalHook

%  prizmatixDesignLocalHook
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


%% Say hello.
projectName = 'prizmatixDesign';


%% Delete any old prefs
if (ispref(projectName))
    rmpref(projectName);
end

end