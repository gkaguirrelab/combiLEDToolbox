function setPrimaries(obj,settings)

% Check that the settings match the number of primaries
if length(settings) ~= obj.nPrimaries
    warning('Length of settings must match number of primaries')
    return
end

% Check that the settings is an integer vector
if any(floor(settings)~=settings)
    warning('The settings must be integers')
    return
end

% Check that the settings is an integer vector
if any(settings>4095) || any(settings<0)
    warning('The settings must be 0-4095')
    return
end

% Check that we have an open connection
if isempty(obj.serialObj)
    warning('Serial connection not yet established');
    return
end

% Place the CombiLED in Direct Mode
writeline(obj.serialObj,'DM');

% Prepare to send settings
writeline(obj.serialObj,'LL');

% Loop over the primaries and write the values
for ii=1:length(settings)
    writeline(obj.serialObj,num2str(settings(ii)));
    pause(0.1);
end

if obj.verbose
    fprintf('Primaries set\n');
end

end