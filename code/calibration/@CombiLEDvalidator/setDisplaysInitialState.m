function setDisplaysInitialState(obj, userPrompt)
    
    % Make a local copy of obj.cal so we do not keep calling it and regenerating it
    calStruct = obj.cal;

    % Retrieve the modResult from the object properties
    modResult = obj.modResult;
    
    % Instantiate the CombiLED object and setup the serial connection
    displayObj = CombiLEDcontrol();

    % Confirm that the modResult was generated for this particular combiLED
    assert(strcmp(displayObj.identifierString,modResult.meta.cal.describe.displayDeviceName));
    
    % Set the displayDeviceName to the identifierString
    obj.displayDeviceName = displayObj.identifierString;

    % Send the gamma table
    gammaTable = modResult.meta.cal.processedData.gammaTable;
    displayObj.setGamma(gammaTable);

    % Tell the CombiLED to gamma correct
    displayObj.setDirectModeGamma(true);

    % Sent the modResult settings
    displayObj.setSettings(modResult)

    % Define a "modulation" that has the property of being extremely slow
    displayObj.setDuration(1e3);
    displayObj.setFrequency(1/1e6);
    displayObj.setWaveformIndex(1);

    % Store the displayObject
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