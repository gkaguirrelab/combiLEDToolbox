% Object to stream video from a PupilLabs video recorder to disk

classdef PupilLabsControl < handle

    properties (Constant)
    end

    % Private properties
    properties (GetAccess=private)

        % A record command suitable for the pupilLabs camera using ffmpeg
        %{
        recordCommand = 'ffmpeg -y -f avfoundation -s 800x600 -framerate 20 -pix_fmt uyvy422 -t trialDurationSecs -i "Pupil" "videoFileOut.mkv"';
        %}

        % Record command using osascript control of the quicktime player
        recordCommand = ['osascript ' ...
            escapeFileCharacters(fullfile(tbLocateToolbox('combiLEDToolbox'),'code','deviceControlers','library','quickTimeRecord.scpt')) ...
            ' videoFileOut trialDurationSecs'];
    end

    % Calling function can see, but not modify
    properties (SetAccess=private)
        dataOutDir
        cameraIdx = '0';
        trialData = [];
    end

    % These may be modified after object creation
    properties (SetAccess=public)

        trialIdx = 1;

        % A prefix to be added to the video files
        filePrefix

        % How long to record
        trialDurationSecs

        % How long to record
        backgroundRecording

        % Verbosity
        verbose

    end

    methods

        % Constructor
        function obj = PupilLabsControl(dataOutDir,varargin)

            % input parser
            p = inputParser; p.KeepUnmatched = false;
            p.addParameter('filePrefix','',@ischar);
            p.addParameter('trialDurationSecs',4,@isnumeric);
            p.addParameter('backgroundRecording',true,@islogical);
            p.addParameter('verbose',false,@islogical);
            p.parse(varargin{:})

            % Place various inputs and options into object properties
            obj.filePrefix = p.Results.filePrefix;
            obj.trialDurationSecs = p.Results.trialDurationSecs;
            obj.backgroundRecording = p.Results.backgroundRecording;
            obj.verbose = p.Results.verbose;

            % Define the dir in which to save pupil videos
            obj.dataOutDir = dataOutDir;

            % Create the directory if it isn't there
            if ~isfolder(obj.dataOutDir)
                mkdir(obj.dataOutDir)
            end

        end

        % Required methds
        positionCamera(obj)
        recordTrial(obj)
        vidDelaySecs = calcVidDelay(obj,trialIdx)
    end
end