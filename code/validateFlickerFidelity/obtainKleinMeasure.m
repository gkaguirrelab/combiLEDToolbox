function [luminance256HzData, xChroma8HzData, yChroma8HzData, zChroma8HzData] = obtainKleinMeasure(CombiLEDObj, lumRangeIdx)
% Use the K10A_device driver, measuring at 256 Hz, how how closely we can
% produce rapid luminance flicker

% Open the Klein
openKlein();

% Set the CombiLED to the background
CombiLEDObj.stopModulation;

% Set the luminance range
luminanceCorrectionFactor = setKleinLuminanceRange(lumRangeIdx);

% Start the modulation
CombiLEDObj.startModulation;

% Pause a quarter second to make sure the modulation is going
pause(0.25);

% Stream for 2 seconds
streamDurationSeconds = 2;

% Collect the measurement
[luminance256HzData, xChroma8HzData, yChroma8HzData, zChroma8HzData] = ...
    stream256HzDataFromKlein(streamDurationSeconds, luminanceCorrectionFactor);

% Set the CombiLED to the background
CombiLEDObj.stopModulation;

% Close the Klein
closeKlein();

end



function testKlein()

% ------------- ENABLE AUTO-RANGE -------------------------------------
K10A_device('sendCommand', 'EnableAutoRanging');


% ------------- GET SOME CORRECTED xyY MEASUREMENTS -------------------
for k = 1:10
    [~, response] = K10A_device('sendCommand', 'SingleShot XYZ');
    fprintf('response[%d]:%s\n', k, response);
end

end


function [correctedLuminanceData, correctedXdata8HzStream, ...
    correctedYdata8HzStream, correctedZdata8HzStream] = ...
    stream256HzDataFromKlein(streamDurationSeconds, luminanceCorrectionFactor)

[~, uncorrectedYdata256HzStream, ...
    correctedXdata8HzStream, ...
    correctedYdata8HzStream, ...
    correctedZdata8HzStream] = K10A_device('sendCommand', 'Standard Stream', streamDurationSeconds);

clearKleinPort()

% Correct 256 Hz luminance data
correctedLuminanceData = uncorrectedYdata256HzStream * luminanceCorrectionFactor;

% Reset streaming communication params
K10A_device('sendCommand', 'SingleShot XYZ');

end


function luminanceCorrectionFactor = setKleinLuminanceRange(lumRangeIdx)

K10A_device('sendCommand', 'DisableAutoRanging');
switch lumRangeIdx
    case 1 % 0.001 cd/m^2 to 19 cd/m^2
        K10A_device('sendCommand', 'LockInRange1');
    case 2 % 0.010 cd/m^2 to 120 cd/m^2
        K10A_device('sendCommand', 'LockInRange2');
    case 3 % 0.400 cd/m^2 to 800 cd/m^2
        K10A_device('sendCommand', 'LockInRange3');
    case 4 % saturates above 2000 cd/m^2
        K10A_device('sendCommand', 'LockInRange3');
end

streamDurationSeconds = 3.0;

[~, uncorrectedYdata256HzStream, ~, correctedYdata8HzStream, ~ ] = ...
    K10A_device('sendCommand', 'Standard Stream', streamDurationSeconds);

luminanceCorrectionFactor = max(correctedYdata8HzStream) / max(uncorrectedYdata256HzStream);

% Reset streaming communication params. Make sure that all is OK.
K10A_device('sendCommand', 'SingleShot XYZ');

clearKleinPort();

end

function clearKleinPort()
% ----- READ ANY DATA AVAILABLE AT THE PORT ---------------------------
[status, dataRead] = K10A_device('readPort');
if ((status == 0) && (length(dataRead) > 0))
    fprintf('Read data: %s (%d chars)\n', dataRead, length(dataRead));
end
end

function closeKlein()
status = K10A_device('close');
fprintf('Closed the Klein K10A colorimeter\n');
end

function openKlein()
% ------ SET THE VERBOSITY LEVEL (1=minimum, 5=intermediate, 10=full)--
status = K10A_device('setVerbosityLevel', 1);

% ------ OPEN THE DEVICE ----------------------------------------------
status = K10A_device('open', '/dev/tty.usbserial-KU000000');
if (status == 0)
    disp('Opened Klein port');
elseif (status == -1)
    disp('Could not open Klein port');
elseif (status == 1)
    disp('Klein port was already opened');
elseif (status == -99)
    disp('Invalided serial port');
end

% ----- SETUP DEFAULT COMMUNICATION PARAMS ----------------------------
speed     = 9600; % 4800; % 9600;
wordSize  = 8;
parity    = 'n';
timeOut   = 50000;

status = K10A_device('updateSettings', speed, wordSize, parity,timeOut);
if (status == 0)
    disp('Update communication settings in Klein port');
elseif (status == -1)
    disp('Could not update settings in Klein port');
elseif (status == 1)
    disp('Klein port is not open');
end

% ----- READ ANY DATA AVAILABLE AT THE PORT ---------------------------
clearKleinPort()

% ----- WRITE SOME DUMMY DATA TO THE PORT -----------------------------
status = K10A_device('writePort', 'Do you feel lucky, punk?');


% ----- READ ANY DATA AVAILABLE ATTHE PORT ----------------------------
clearKleinPort()


% ------------- GET THE SERIAL NO OF THE KLEIN METER ------------------
[status, modelAndSerialNo] = ...
    K10A_device('sendCommand', 'Model and SerialNo');
fprintf('Serial no and model: %s\n', modelAndSerialNo);

if (~strcmp(modelAndSerialNo, 'P0K-10-A U005700  <0>'))
    clearKleinPort();
    error('Serial number is invalid. Expected ''P0K-10-A U005700  <0>''.');
end

% ------------ GET THE FIRMWARE REVISION OF THE KLEIN METER -----------
[status, response] = K10A_device('sendCommand', 'FlickerCal & Firmware');
fprintf('>>> Firmware version: %s\n', response(20:20+7-1));


fprintf('Opened and established communication with the Klein K10A colorimeter\n');

end
