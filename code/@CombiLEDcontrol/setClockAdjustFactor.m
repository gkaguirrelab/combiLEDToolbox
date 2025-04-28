function setClockAdjustFactor(obj,clockAdjustFactor)


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

% Enter the send state
writeline(obj.serialObj,'CF');
readline(obj.serialObj);

% Send the clockAdjustFactor as a float
writeline(obj.serialObj,num2str(clockAdjustFactor,'%.5f'));
msg = readline(obj.serialObj);

if obj.verbose
    fprintf(['Clock adjust factor set to ' char(msg) '\n']);
end

obj.clockAdjustFactor = clockAdjustFactor;

end