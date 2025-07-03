function setStartDelay(obj,startDelaySecs)

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
writeline(obj.serialObj,'SD');
readline(obj.serialObj);

% Send the duration
writeline(obj.serialObj,num2str(startDelaySecs,'%.4f'));
msg = readline(obj.serialObj);

if obj.verbose
    fprintf(['Start delay set to ' char(msg) ' seconds\n']);
end


end