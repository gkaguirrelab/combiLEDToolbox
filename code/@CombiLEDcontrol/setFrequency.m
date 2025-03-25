function setFrequency(obj,frequencyHz)

% Check that we have an open connection
if isempty(obj.serialObj)
    warning('Serial connection not yet established');
    return
end

% Check that we have a valid frequency value. Note that a value of zero is
% invalid and will cause strange behavior from the combiLED firmware.
assert(frequencyHz > 0);

% Place the CombiLED in Config Mode
switch obj.deviceState
    case 'CONFIG'
    case {'RUN','DIRECT'}
        writeline(obj.serialObj,'CM');
        readline(obj.serialObj);
        obj.deviceState = 'CONFIG';
end

% Enter the frequency send state
writeline(obj.serialObj,'FQ');
readline(obj.serialObj);

% Send the frequency
writeline(obj.serialObj,num2str(frequencyHz,'%.4f'));
msg = readline(obj.serialObj);

if obj.verbose
    fprintf(['Frequency set to ' char(msg) '\n']);
end


end