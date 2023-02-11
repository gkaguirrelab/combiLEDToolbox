function setContrast(obj,contrast)

% Check that we have an open connection
if isempty(obj.serialObj)
    warning('Serial connection not yet established');
    return
end

% Sanity check the contrast value
mustBeInRange(contrast,0,1);

% Place the CombiLED in Config Mode
switch obj.deviceState
    case 'CONFIG'
    case {'RUN','DIRECT'}
        writeline(obj.serialObj,'CM');
        readline(obj.serialObj);
        obj.deviceState = 'CONFIG';
end

% Enter the frequency send state
writeline(obj.serialObj,'CN');
readline(obj.serialObj);

% Send the frequency
writeline(obj.serialObj,num2str(contrast));
readline(obj.serialObj);

if obj.verbose
    fprintf('Contrast sent\n');
end

end