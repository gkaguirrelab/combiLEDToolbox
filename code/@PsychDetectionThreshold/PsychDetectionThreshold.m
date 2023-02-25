% Object to support conducting a 2AFC contrast threshold detection task,
% using a two up, one down staircase to reach a 71% correct performance
% level at asymptote. The measurements continue until a criterion number of
% reversals are obtained.

classdef PsychDetectionThreshold < handle

    properties (Constant)
    end

    % Private properties
    properties (GetAccess=private)
    end

    % Calling function can see, but not modify
    properties (SetAccess=private)
        questData
        simulatePsiParams
        simulateResponse
        simulateStimuli
        giveFeedback
        psiParamsDomainList
        randomizePhase = true;
        TestFrequency
        TestContrastSet
        stimulusDurationSecs = 1;
        responseDurSecs = 3;
        interStimulusIntervalSecs = 0.75;
    end

    % These may be modified after object creation
    properties (SetAccess=public)

        % The display object. This is modifiable so that we can re-load
        % a PsychDetectionThreshold, update this handle, and then continue
        % to collect data
        CombiLEDObj

        % Verbosity
        verbose = true;
        blockStartTimes = datetime();

    end

    methods

        % Constructor
        function obj = PsychDetectionThreshold(CombiLEDObj,TestFrequency,varargin)

            % input parser
            p = inputParser; p.KeepUnmatched = false;
            p.addParameter('randomizePhase',false,@islogical);
            p.addParameter('simulateResponse',true,@islogical);
            p.addParameter('simulateStimuli',true,@islogical);
            p.addParameter('giveFeedback',false,@islogical);
            p.addParameter('TestContrastSet',linspace(-3,-1,31),@isnumeric);
            p.addParameter('simulatePsiParams',[-2, 3, 0.5, 0.01],@isnumeric);
            p.addParameter('psiParamsDomainList',{...
                linspace(-2.5,-0.5,31), ...
                linspace(0.5,5,31),...
                0.5,...
                linspace(0,0.25,31)...
                },@isnumeric);
            p.addParameter('verbose',true,@islogical);
            p.parse(varargin{:})

            % Place various inputs and options into object properties
            obj.CombiLEDObj = CombiLEDObj;
            obj.TestFrequency = TestFrequency;
            obj.TestContrastSet = p.Results.TestContrastSet;
            obj.randomizePhase = p.Results.randomizePhase;
            obj.simulateResponse = p.Results.simulateResponse;
            obj.simulateStimuli = p.Results.simulateStimuli;
            obj.giveFeedback = p.Results.giveFeedback;
            obj.simulatePsiParams = p.Results.simulatePsiParams;
            obj.psiParamsDomainList = p.Results.psiParamsDomainList;
            obj.verbose = p.Results.verbose;

            % Detect incompatible simulate settings
            if obj.simulateStimuli && ~obj.simulateResponse
                fprintf('Forcing simulateResponse to true, as one cannot respond to a simulated stimulus\n')
                obj.simulateResponse = true;
            end

            % Initialize the blockStartTimes field
            obj.blockStartTimes(1) = datetime();
            obj.blockStartTimes(1) = [];

            % Initialize Quest+
            obj.initializeQP;

            % Initialize the CombiLED
            obj.initializeDisplay;

            % There is a roll-off (attenuation) of the amplitude of
            % modulations with frequency. Detect those cases which are outside of our ability to
            % correct
            TestContrastSetAdjusted = (10.^obj.TestContrastSet) ./ ...
                contrastAttentionByFreq(obj.TestFrequency);

            % Check that the adjusted contrast does not exceed unity
            mustBeInRange(TestContrastSetAdjusted,0,1);

        end

        % Required methds
        initializeQP(obj);
        initializeDisplay(obj);
        validResponse = presentTrial(obj);
        [intervalChoice, responseTimeSecs] = getResponse(obj);
        [intervalChoice, responseTimeSecs] = getSimulatedResponse(obj,TestContrast,testInterval);
        waitUntil(obj,stopTimeMicroSeconds)
        [psiParamsQuest, psiParamsFit] = reportParams(obj)
        figHandle = plotOutcome(obj,visible);
    end
end