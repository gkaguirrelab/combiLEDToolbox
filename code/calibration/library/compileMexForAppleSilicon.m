% This routine replaces several intel MEX files with compiled Apple Silicon
% versions for elements of Psychtoolbox that are needed for PR670 based
% calibrations. The calibration code will fail under native Apple Silicon
% versions of Matlab without these updates.


% IOPort
cd(fullfile(userpath,'toolboxes/Psychtoolbox-3/PsychSourceGL/Source'));
mex -outdir ../Projects/MacOSX/build -output IOPort -largeArrayDims -DMEX_DOUBLE_HANDLE -DPTBMODULE_IOPort CFLAGS="\$CFLAGS -mmacosx-version-min=10.11" LDFLAGS="\$LDFLAGS -mmacosx-version-min=10.11 -framework CoreServices -framework CoreFoundation -framework CoreAudio"  -ICommon/Base -IOSX/Base -ICommon/IOPort  "OSX/Base/*.c" "Common/Base/*.c" "Common/IOPort/*.c"
cd(fullfile(userpath,'toolboxes/Psychtoolbox-3/PsychSourceGL/Projects/MacOSX/build'));
command = ['mv IOPort.mexmaca64 ' userpath '/toolboxes/Psychtoolbox-3/Psychtoolbox/PsychBasic/'];
system(command);
cd(userpath);

% WaitSecs
cd(fullfile(userpath,'toolboxes/Psychtoolbox-3/PsychSourceGL/Source'));
mex -outdir ../Projects/MacOSX/build -output WaitSecs -largeArrayDims -DMEX_DOUBLE_HANDLE -DPTBMODULE_WaitSecs CFLAGS="\$CFLAGS -mmacosx-version-min=10.11" LDFLAGS="\$LDFLAGS -mmacosx-version-min=10.11 -framework CoreServices -framework CoreFoundation -framework CoreAudio"  -ICommon/Base -IOSX/Base -ICommon/WaitSecs  "OSX/Base/*.c" "Common/Base/*.c" "Common/WaitSecs/*.c"
cd(fullfile(userpath,'toolboxes/Psychtoolbox-3/PsychSourceGL/Projects/MacOSX/build'));
command = ['mv WaitSecs.mexmaca64 ' userpath '/toolboxes/Psychtoolbox-3/Psychtoolbox/PsychBasic/'];
system(command);
cd(userpath);

% GetSecs
cd(fullfile(userpath,'toolboxes/Psychtoolbox-3/PsychSourceGL/Source'));
mex -outdir ../Projects/MacOSX/build -output GetSecs -largeArrayDims -DMEX_DOUBLE_HANDLE -DPTBMODULE_GetSecs CFLAGS="\$CFLAGS -mmacosx-version-min=10.11" LDFLAGS="\$LDFLAGS -mmacosx-version-min=10.11 -framework CoreServices -framework CoreFoundation -framework CoreAudio"  -ICommon/Base -IOSX/Base -ICommon/GetSecs  "OSX/Base/*.c" "Common/Base/*.c" "Common/GetSecs/*.c"
cd(fullfile(userpath,'toolboxes/Psychtoolbox-3/PsychSourceGL/Projects/MacOSX/build'));
command = ['mv GetSecs.mexmaca64 ' userpath '/toolboxes/Psychtoolbox-3/Psychtoolbox/PsychBasic/'];
system(command);
cd(userpath);
