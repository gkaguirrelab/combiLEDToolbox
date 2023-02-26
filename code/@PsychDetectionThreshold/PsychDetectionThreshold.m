% Object to support conducting a 2AFC contrast threshold detection task,
% using the log Weibull CFD under the control of Quest+ to select stimuli.
% A nuance of the parameterization is that we allow Quest+ to search for
% the value of the "guess rate", even though by design this rate must be
% 0.5. By providing this bit of flexibility in the parameter space, Quest+
% tends to explore the lower end of the contrast range a bit more,
% resulting in slightly more accurate estimates of the slope of the
% psychometric function. When we derive the final, maximum likelihood set
% of parameters, we lock the guess rate to 0.5.

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
        randomizePhase = false;
        TestFrequency
        TestContrastSet
        stimulusDurationSecs = 1;
        interStimulusIntervalSecs = 0.75;
        responseDurSecs = 3;
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
            p.addParameter('simulatePsiParams',[-2, 1.5, 0.5, 0.0],@isnumeric);
            p.addParameter('psiParamsDomainList',{...
                linspace(-2.5,-0.5,21), ...
                logspace(log10(0.75),log10(10),21),...
                linspace(0.4,0.6,6),...
                linspace(0,0.25,21)...
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