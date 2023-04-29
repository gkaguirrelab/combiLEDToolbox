

% Define the identity of and path to the simulink model
mdl = "alpha_mod_stimulation";
mdlPath = fullfile(fileparts(mfilename('fullpath')),'simulink',mdl);

% Load the model into memory in the background
mdlHandle = load_system(mdl);

stimFreq = 10;

% Show that we can get parameters from the model
get_param(fullfile(mdl,"Input noise","Gain5"),"Gain")
get_param(fullfile(mdl,"C2"),"Gain")

% Set the stimulation frequency
set_param(fullfile(mdl,"Signal Generator"),"Frequency",num2str(stimFreq));

% Set the period of time to be modeled, in seconds
set_param(mdl, 'StopTime', '2');

% Obtain the model output
simIn = Simulink.SimulationInput(mdl);
simOut = sim(simIn);

% Plot the input and output in the time domain
deltaTSecs = diff(simOut.signal(1:2,1));

censorIdx = 200;

inputSignal = simOut.Input(censorIdx:end,2);
outputSignal = simOut.signal(censorIdx:end,2);
x = simOut.signal(censorIdx:end,1);

figure
subplot(2,2,1);
plot(x,inputSignal,'-k');

subplot(2,2,2);
plot(x,outputSignal,'-r');

subplot(2,2,3)
[frq, amp, phase] = simpleFFT( outputSignal-mean(outputSignal), 1/deltaTSecs);
plot(log10(frq),amp,'-k');
hold on
plot(log10([stimFreq stimFreq]),[0 300],'-r');