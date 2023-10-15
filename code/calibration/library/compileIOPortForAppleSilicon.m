% This routine replaces the intel MEX file "IOPort" that is part of
% Psychtoolbox with a version that is compiled to work under Apple Silicon.
% This is needed to be able to operate the PR670 and perform calibrations
% under a native install of Matlab.

cd(fullfile(userpath,'toolboxes/Psychtoolbox-3/PsychSourceGL/Source'));
mex -outdir ../Projects/MacOSX/build -output IOPort -largeArrayDims -DMEX_DOUBLE_HANDLE -DPTBMODULE_IOPort CFLAGS="\$CFLAGS -mmacosx-version-min=10.11" LDFLAGS="\$LDFLAGS -mmacosx-version-min=10.11 -framework CoreServices -framework CoreFoundation -framework CoreAudio"  -ICommon/Base -IOSX/Base -ICommon/IOPort  "OSX/Base/*.c" "Common/Base/*.c" "Common/IOPort/*.c"
cd(fullfile(userpath,'toolboxes/Psychtoolbox-3/PsychSourceGL/Projects/MacOSX/build'));
command = ['mv IOPort.mexmaca64 ' userpath '/toolboxes/Psychtoolbox-3/Psychtoolbox/PsychBasic/'];
system(command);
cd(userpath);