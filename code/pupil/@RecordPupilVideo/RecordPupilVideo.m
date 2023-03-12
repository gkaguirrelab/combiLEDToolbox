% Object to stream video from a PupilLabs video recorder to disk

classdef RecordPupilVideo < handle

    properties (Constant)
    end

    % Private properties
    properties (GetAccess=private)
        recordCommandStem = 'ffmpeg -hide_banner -video_size 640x480 -framerate 60.500094 -f avfoundation -i "1" -t trialDurationSecs "videoFileOut.mp4"';

    end

    % Calling function can see, but not modify
    properties (SetAccess=private)

    end

    % These may be modified after object creation
    properties (SetAccess=public)

        experimentName = 'pupilGlare_01';
        trialDurationSecs = 4;
        subjectID
        

        % Verbosity
        verbose = true;
        
    end

    methods

        % Constructor
        function obj = RecordPupilVideo(varargin)

            % input parser
            p = inputParser; p.KeepUnmatched = false;
            p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@islogical);
            p.addParameter('verbose',true,@islogical);
            p.parse(varargin{:})

            % Place various inputs and options into object properties
            obj.verbose = p.Results.verbose;

        end

        % Required methds
        initializeQP(obj)
        initializeDisplay(obj)
        validResponse = presentTrial(obj)
        [intervalChoice, responseTimeSecs] = getResponse(obj)
        [intervalChoice, responseTimeSecs] = getSimulatedResponse(obj,qpStimParams,ref1Interval)
        waitUntil(obj,stopTimeMicroSeconds)
        [psiParamsQuest, psiParamsFit, psiParamsCI, fVal] = reportParams(obj,options)
        figHandle = plotOutcome(obj,visible)
        values = forwardTransformVals(obj,refValues,testValue)
        values = inverseTransVals(obj,refValues,testValue)
    end
end