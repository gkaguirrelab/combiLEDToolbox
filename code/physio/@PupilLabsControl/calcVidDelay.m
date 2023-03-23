function calcVidDelay(obj,trialIdx)

% Path to the video file
vidOutFile = fullfile(obj.dataOutDir,sprintf([obj.filePrefix 'trial_%02d.mpg'],trialIdx));

% Check that the file exists
if ~isfile(vidOutFile)
    obj.trialData(trialIdx).vidDelaySecs = nan;
else
    % Get the creation time stamp for the video file, with msec precision
    d1 =datetime(py.os.path.getctime(vidOutFile),'ConvertFrom','epochtime','TicksPerSecond',1,'Format','dd-MMM-yyyy HH:mm:ss.SSS');
    % Store the difference in time between trial onset and file recording
    % onset
    obj.trialData(trialIdx).vidDelaySecs = d1 - obj.trialData(trialIdx).recordCommandStartTime;
end
