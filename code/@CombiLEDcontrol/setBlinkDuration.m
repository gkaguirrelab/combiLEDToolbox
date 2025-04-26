function setBlinkDuration(obj,blinkDurSecs)


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
writeline(obj.serialObj,'BD');
readline(obj.serialObj);

% Send the blink duration as a float in units of seconds
writeline(obj.serialObj,num2str(blinkDurSecs,'%.4f'));
msg = readline(obj.serialObj);

if obj.verbose
    fprintf(['Blink duration set to ' char(msg) ' microsecs\n']);
end


end