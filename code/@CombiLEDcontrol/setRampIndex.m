function setRampIndex(obj,rampIndex)

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

% Enter the amplitude values send state
writeline(obj.serialObj,'RI');
readline(obj.serialObj);

% Send the amplitude modulation index
writeline(obj.serialObj,num2str(rampIndex));
msg = readline(obj.serialObj);

if obj.verbose
    fprintf(['Ramp modulation index set to ' char(msg) '\n']);
end

end