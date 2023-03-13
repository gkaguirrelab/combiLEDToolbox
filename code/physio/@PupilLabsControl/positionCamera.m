function positionCamera(obj)

% Alert the user
if obj.verbose
    fprintf('Adjust camera.\n');
end

% Prepare a figure
figHandle = figure();
ButtonHandle = uicontrol('Style', 'PushButton', ...
    'String', 'Done adjusting', ...
    'Callback', 'delete(gcbf)');
hold on
axis off
set(gca, 'YDir','reverse')

% Enter the camera adjustment loop
stillRecording = true;
firstImage = true;

while stillRecording

    % Record a video snippet
    tmpVid = [tempname '.mp4'];
    vidCommand = obj.recordCommand;
    vidCommand = strrep(vidCommand,'cameraIdx',num2str(obj.cameraIdx));
    vidCommand = strrep(vidCommand,'trialDurationSecs','0.33');
    vidCommand = strrep(vidCommand,'videoFileOut.mp4',tmpVid);
    [~,~] = system(vidCommand);

    % Extact the mid time point of that snippet
    tmpIm = [tempname '.jpg'];
    extractCommand = ['ffmpeg -ss 00:00:00.17 -i ' tmpVid ' -vframes 1 -q:v 2 ' tmpIm];
    [~,~] = system(extractCommand);

    % Display the image
    im = imread(tmpIm);
    if firstImage
        h=imagesc(im);
        firstImage = false;
    else
        h.CData = im;
    end
    drawnow

    % Delete the temp files
    delete(tmpVid);
    delete(tmpIm);

    % Check if we have hit the stop button
    if ~ishandle(ButtonHandle)
        stillRecording = false;
    end

end

end