function setAMValues(obj,amplitudeValues)

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
writeline(obj.serialObj,'AV');
readline(obj.serialObj);

% Loop over the amplitude values and send these
for ii = 1:length(amplitudeValues)
    writeline(obj.serialObj,num2str(amplitudeValues(ii)));
    readline(obj.serialObj);
end

if obj.verbose
    fprintf('Amplitude modulation values sent\n');
end

end