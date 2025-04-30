function setPrimaries(obj,settings)

% Check that the settings match the number of primaries
if length(settings) ~= obj.nPrimaries
    warning('Length of settings must match number of primaries')
    return
end

% Sanity check the settings range
mustBeInRange(settings,0,1);

% Check that we have an open connection
if isempty(obj.serialObj)
    warning('Serial connection not yet established');
    return
end

% Flush the serial port IO
flush(obj.serialObj);

% Place the CombiLED in Direct Mode
switch obj.deviceState
    case 'DIRECT'
    case {'RUN','CONFIG'}
        writeline(obj.serialObj,'DM');
        readline(obj.serialObj);
        obj.deviceState = 'DIRECT';
end

% Prepare to send settings
writeline(obj.serialObj,'LL');
readline(obj.serialObj);

% Loop over the primaries and write the values
report = 'settings: [ ';
for ii=1:length(settings)
    % Each setting is sent as a float
    writeline(obj.serialObj,num2str(settings(ii),'%.5f'));
    readline(obj.serialObj);
    report = [report, char(msg), ' '];
end

report = [report,']\n'];
if obj.verbose
    fprintf(report);
end

end