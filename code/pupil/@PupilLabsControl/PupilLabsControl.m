% Object to stream video from a PupilLabs video recorder to disk

classdef PupilLabsControl < handle

    properties (Constant)
    end

    % Private properties
    properties (GetAccess=private)

        % A record command suitable for the pupilLabs camera
        recordCommand = 'ffmpeg -hide_banner -video_size 800x600 -framerate 60.000240 -f avfoundation -i "cameraIdx" -t trialDurationSecs "videoFileOut.mp4"';

        % A record command for the FaceTime camera
        %{
        recordCommand = 'ffmpeg -hide_banner -video_size 640x480 -framerate 30.0 -f avfoundation -i "cameraIdx" -t trialDurationSecs "videoFileOut.mp4"';
        %}
    end

    % Calling function can see, but not modify
    properties (SetAccess=private)
        dataOutDir
        cameraIdx = '0';
        trialIdx = 1;
        trialData = [];
    end

    % These may be modified after object creation
    properties (SetAccess=public)

        % How long to record
        trialDurationSecs = 4;

        % How long to record
        backgroundRecording = true;

        % Verbosity
        verbose = true;
        
    end

    methods

        % Constructor
        function obj = PupilLabsControl(subjectID,modDirection,experimentName,varargin)

            % input parser
            p = inputParser; p.KeepUnmatched = false;
            p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
            p.addParameter('projectName','combiLED',@ischar);
            p.addParameter('approachName','pupillometry',@ischar);
            p.addParameter('backgroundRecording',true,@islogical);
            p.addParameter('verbose',true,@islogical);
            p.parse(varargin{:})

            % Place various inputs and options into object properties
            obj.backgroundRecording = p.Results.backgroundRecording;
            obj.verbose = p.Results.verbose;

            % Define the dir in which to save pupil videos
            obj.dataOutDir = fullfile(...
                p.Results.dropBoxBaseDir,...
                p.Results.projectName,...
                p.Results.approachName,...
                subjectID,modDirection,experimentName,'rawPupilVideos');

            % Create the directory if it isn't there
            if ~isfolder(obj.dataOutDir)
                mkdir(obj.dataOutDir)
            end

        end

        % Required methds
        identifyCamera(obj)
        positionCamera(obj)
        recordTrial(obj)
    end
end