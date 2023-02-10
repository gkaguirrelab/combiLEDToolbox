function setBackground(obj,background)

% Check that the background match the number of primaries
if length(background) ~= obj.nPrimaries
    warning('The background vector must match number of primaries')
    return
end

% Check that the settings is an integer vector
if any(floor(background)~=background)
    warning('The settings must be integers')
    return
end

% Sanity check the background range
if any(background>(obj.nDiscreteLevels-1)) || any(background<0)
    warning('The settings must be 0 and then number of discrete levels')
    return
end

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


% Enter the background send state
writeline(obj.serialObj,'BG');
readline(obj.serialObj);

% Loop over the primaries and send the settings
for ii = 1:obj.nPrimaries
    for ll= 1:obj.nDiscreteLevels
        writeline(obj.serialObj,num2str(background(ii)));
        readline(obj.serialObj);
    end
end

if obj.verbose
    fprintf('Background vector sent\n');
end

end