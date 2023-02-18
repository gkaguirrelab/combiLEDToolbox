function response = getResponse(obj)

% Set the response interval
responseDurMicroSecs = obj.responseDurSecs * 1e9;

% Determine the identities of the responses
keyPress1 = [30, 89];
keyPress2 = [31, 90];
KbResponse = [];

% Silence echoing key presses to Matlab console
ListenChar(2);

% Enter a while loop
waitingForKey = true;
intervalStart = tic();
while waitingForKey

    % Check keyboard:
    [isdown, ~, keycode]=KbCheck(-1);
    if isdown
        KbResponse = find(keycode);
        if any([keyPress1, keyPress2]==KbResponse)
            waitingForKey = false;
        end
    end

    % Check if we have run out of time
    if (tic()-intervalStart) > responseDurMicroSecs
        waitingForKey = false;
    end

end

% Interpret the response
switch KbResponse
    case num2cell(keyPress1)
        response = 1;
    case num2cell(keyPress2)
        response = 2;
    otherwise
        response = [];
end

% Restore echoing key presses to Matlab console
ListenChar(0);


end