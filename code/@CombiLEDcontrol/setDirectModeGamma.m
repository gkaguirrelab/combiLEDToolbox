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
    case 'DIRECT'
    case {'RUN','CONFIG'}
        writeline(obj.serialObj,'DM');
        readline(obj.serialObj);
        obj.deviceState = 'DIRECT';
end

% Send state
if boolGammaCorrect
    writeline(obj.serialObj,'GT');
    msg = readline(obj.serialObj);
    if obj.verbose
        fprintf(msg + "\n");
    end
else
    writeline(obj.serialObj,'GF');
    msg = readline(obj.serialObj);
    if obj.verbose
        fprintf(msg + "\n");
    end
end


end