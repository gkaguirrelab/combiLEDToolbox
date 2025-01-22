function setDisplaysInitialState(obj, userPrompt)
    
    % Make a local copy of obj.cal so we do not keep calling it and regenerating it
    calStruct = obj.cal;
    
    % Instantiate the CombiLED object and setup the serial connection
    displayObj = CombiLEDcontrol();

    % Tell the CombiLED to NOT gamma correct
    displayObj.setDirectModeGamma(false);

    % Add the identifierString to the displayDeviceName
    obj.displayDeviceName = strcat(obj.displayDeviceName,'-',displayObj.identifierString);

    % Set the primaries to off
    displayObj.setPrimaries([0 0 0 0 0 0 0 0]);

    % Store the object
    obj.displayObj = displayObj;

    disp('Position radiometer and hit enter when ready');
    pause

    % Wait for user
    if (userPrompt) 
        fprintf('Pausing for %d seconds ...', calStruct.describe.leaveRoomTime);
        FlushEvents;
        % GetChar;
        pause(calStruct.describe.leaveRoomTime);
        fprintf(' done\n\n\n');
    end

end