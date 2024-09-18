function setDirectModeGamma(obj,boolGammaCorrect)

% Check that we have an open connection
if isempty(obj.serialObj)
    warning('Serial connection not yet established');
    return
end

if obj.verbose
    fprintf('Setting the direct mode gamma correction boolean\n');
end

% Place the CombiLED in Config Mode
switch obj.deviceState
    case 'CONFIG'
    case {'RUN','DIRECT'}
        writeline(obj.serialObj,'CM');
        readline(obj.serialObj);
        obj.deviceState = 'CONFIG';
end

% Send state
if boolGammaCorrect
    writeline(obj.serialObj,'GT');
    readline(obj.serialObj);
    if obj.verbose
        fprintf('Gamma correct in direct mode = TRUE');
    end
else
    writeline(obj.serialObj,'GF');
    readline(obj.serialObj);
    if obj.verbose
        fprintf('Gamma correct in direct mode = TRUE');
    end
end


end