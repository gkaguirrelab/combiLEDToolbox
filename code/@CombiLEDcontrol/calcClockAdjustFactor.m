function clockAdjustFactor = calcClockAdjustFactor(obj)
% Determine the multiplicative offset between the arduino internal clock at
% the clock of the CPU used by the calling function. A returned value
% greater than one indicates that the arduino internal clock is faster than
% the clock of the calling function. This measurement should be made in
% replicate after minimizing any other activity on the host computer, and
% averaging across measures.


% Check that we have an open connection
if isempty(obj.serialObj)
    warning('Serial connection not yet established');
    return
end

% Place the CombiLED in Config Mode
switch obj.deviceState
    case 'CONFIG'
    case {'RUN','DIRECT'}
        writeline(obj.serialObj,'CM');
        readline(obj.serialObj);
        obj.deviceState = 'CONFIG';
end

if obj.verbose
    fprintf('Checking clock timing; wait 5 seconds...');
end

% Get the clock time of this CPU
cpuStartTime = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSSSSS');

% Get the clock time of the arduino
writeline(obj.serialObj,'CT');
arduinoStartTime = str2double(readline(obj.serialObj));

% Wait 5 seconds
pause(5)

% Repeat the measurements
cpuEndTime = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
writeline(obj.serialObj,'CT');
arduinoEndTime = str2double(readline(obj.serialObj));

% Check if we had an overflow event in the arduino measure
if arduinoEndTime < arduinoStartTime
    warning('Arduino clock overflow error; please repeat the measurement')
    return
end

% Calculate the ratio
cpuDiff = cpuEndTime - cpuStartTime;
cpuDiff.Format = cpuDiff.Format + ".SSSSSS";
cpuDiff = seconds(cpuDiff);
arduinoDiff = (arduinoEndTime - arduinoStartTime)/1e6;
clockAdjustFactor = arduinoDiff / cpuDiff;

% Say
if obj.verbose
    fprintf('The clockAdjustFactor is %2.5f\n',clockAdjustFactor);
end

end