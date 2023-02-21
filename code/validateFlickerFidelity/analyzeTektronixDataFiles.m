% Analysis of Tektronix oscilloscope measurements of CombiLED and OneLight
% sinusoidal modulations.
%
% A measure was made for the CombiLED and OneLight each producing a
% light-flux modulation at several frequencies. The background luminance
% was similar for the two devices (~200 cd/m2 for the CombiLED, and ~300
% cd/m2 for the OneLight). The OneLight was set to a refresh rate of 512
% Hz.
%
% The resulting voltage measurements wer fit (in a least-squares manner)
% with the phase and amplitude of a sinusoid at the modulation frequency.
% The voltage trace and the fit is shown, as well as the measured amplitude
% as a function of modulation frequency.
%
% Overall, the modulations approximate a sinusoid very well across all
% frequencies tested. The amplitude of the modulation, however, drops
% systematically with modulation frequency. This relationship is well
% described by the expression:
%
%
%
% I attribute this decrease in amplitude to some temporal blurring at the
% level of the LED output. The cycle time of the device should not produce
% this degree of loss. I think instead that there is a rise and fall time
% to light output after a change to the LED setting.
%
% In piloting, I observed that there was a power-law scaling of the voltage
% values returned by the oscilloscope that was dependent upon how close the
% radiometer head was placed to the light source. This motivated a fitting
% component that performed a non-linear search for exponent values to
% transform the voltage values prior to Fourier fitting. Ultimately, I
% found that increasing the distance of the radiometer from the light
% source removed this non-linearity, resulting in fitted exponents which
% are very close to unity.
%

% The devices that will be plotted
devices = {'CombiLED','OL','corrected Combi'};

% The frequencies at which measurements were made
freqsToTest = [8, 10, 16, 20, 32, 40, 64, 80];
nTested = length(freqsToTest);

% Loop over the devices
for dd = 1:2

    % Create a figure for the sinusoid fit results
    figure('Name',devices{dd});

    % The path to the CSV files saved from the Tektronix oscilloscope
    dataFileDir = fullfile(fileparts(mfilename("fullpath")),[devices{dd} '_tektronixDataFiles']);
    dataFileList = dir(fullfile(dataFileDir,'*.CSV'));

    % Loop over the frequencies
    for ff=1:nTested

        % Load the next file
        fileName = fullfile(dataFileList(ff).folder,dataFileList(ff).name);
        opts = detectImportOptions(fileName);
        T = readtable(fileName,opts);

        % Grab the time series and the voltage values
        ts = T{:,4}; y = T{:,5};

        % Create a Fourier regression matrix for this modulation frequency
        X(:,1) = sin(2*pi*freqsToTest(ff).*ts);
        X(:,2) = cos(2*pi*freqsToTest(ff).*ts);

        % Create an objective and find the best exponent
        myObj = @(p) powerScaleY(y,p,X);
        p = fminunc(myObj,1);

        % Obtain the fit and scaled y values at the solution
        [fVal, yFit, yScaled] = powerScaleY(y,p,X);

        % Store the amplitude of the response
        amplitudes(dd,ff) = range(yFit);

        % Plot the data and the fit
        subplot(4,2,ff);
        plot(ts,-yScaled,'-k');
        hold on
        plot(ts,-yFit,'r');
        ylim([0 0.15])
        xlabel('time [s]')
        ylabel('amp [volts]')
        title(sprintf('Freq: %2.1f Hz, amp = %2.2f, exponent = %2.2f',freqsToTest(ff),amplitudes(dd,ff),p))

    end

end

% Scale the amplitudes by the response at the lowest modulation frequency
amplitudes(1,:) = amplitudes(1,:)./amplitudes(1,1);
amplitudes(2,:) = amplitudes(2,:)./amplitudes(2,1);
correctedCombi = amplitudes(1,:) ./ amplitudes(2,:);

% Plot the roll-off curves
figure
plot(log10(freqsToTest(1:nTested)),amplitudes(1,:),'-ok');
hold on
plot(log10(freqsToTest(1:nTested)),amplitudes(2,:),'-or');
plot(log10(freqsToTest(1:nTested)),correctedCombi,':ok');
legend(devices)
a=gca;
a.XTick = log10(freqsToTest);
a.XTickLabel = arrayfun(@(x) num2str(x),freqsToTest,'UniformOutput',false);
xlabel('Frequency [log Hz]')
ylabel('Relative amplitude reduction [proportion]')



%% local function

function [fVal, yFit, yScaled] = powerScaleY(y,p,X)

% First, scale y between 0 and 1. Take the "min" as the median of the
% lowest 0.5% of the values
sortY = sort(y);
minVal = median(sortY(1:round(0.005*length(sortY))));
maxVal = median(sortY(round(0.995*length(sortY)):end));
rangeVal = maxVal-minVal;
yScaled = (y-minVal)./rangeVal;

% Apply the power law effect
yScaled = real(yScaled.^p);

% Now center and fit a sinusoid
yScaled = yScaled - mean(yScaled);
b=X\yScaled;
yFit = b'*X';

% Re-apply
yFit = (yFit' * rangeVal)+minVal;
yScaled = (yScaled * rangeVal)+minVal;

% Get the fVal
fVal = norm(yFit-yScaled);

end
