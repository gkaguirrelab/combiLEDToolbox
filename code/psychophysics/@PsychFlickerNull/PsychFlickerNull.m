% Object to conducting flicker nulling of a chromatic stimulus

classdef PsychFlickerNull < handle

    properties (Constant)
    end

    % Private properties
    properties (GetAccess=private)
    end

    % Calling function can see, but not modify
    properties (SetAccess=private)
        modResultA
        modResultB
        questData
        simulatePsiParams
        simulateResponse
        simulateStimuli
        giveFeedback
        psiParamsDomainList
        randomizePhase = true;
        testFreqHz
        maxTestContrast
        testDiffSet
        pulseDurSecs = 1;
        halfCosineRampDurSecs = 0.1
        interStimulusIntervalSecs = 0.2;
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

        % We allow this to be modified so we
        % can set it to be brief during object
        % initiation when we clear the responses
        responseDurSecs = 3;

    end

    methods

        % Constructor
        function obj = PsychFlickerNull(CombiLEDObj,modResultA,modResultB,varargin)

            % input parser
            p = inputParser; p.KeepUnmatched = false;           
            p.addParameter('testFreqHz',30,@isnumeric);
            p.addParameter('maxTestContrast',0.8,@isnumeric);
            p.addParameter('randomizePhase',true,@islogical);
            p.addParameter('simulateResponse',false,@islogical);
            p.addParameter('simulateStimuli',false,@islogical);
            p.addParameter('giveFeedback',true,@islogical);
            p.addParameter('testDiffSet',[fliplr(-logspace(-2,log10(0.5),10)) 0 logspace(-2,log10(0.5),10)],@isnumeric);
            p.addParameter('simulatePsiParams',[0, 0.25],@isnumeric);
            p.addParameter('psiParamsDomainList',{...
                [fliplr(-logspace(-2,log10(0.5),10)) 0 logspace(-2,log10(0.5),10)], ...
                linspace(0.05,0.5,10),...
                },@isnumeric);
            p.addParameter('verbose',true,@islogical);
            p.parse(varargin{:})

            % Place various inputs and options into object properties
            obj.CombiLEDObj = CombiLEDObj;
            obj.modResultA = modResultA;
            obj.modResultB = modResultB;
            obj.testFreqHz = p.Results.testFreqHz;
            obj.maxTestContrast = p.Results.maxTestContrast;            
            obj.testDiffSet = p.Results.testDiffSet;
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

        end

        % Required methds
        initializeQP(obj)
        initializeDisplay(obj)
        validResponse = presentTrial(obj)
        [intervalChoice, responseTimeSecs] = getResponse(obj)
        [intervalChoice, responseTimeSecs] = getSimulatedResponse(obj,qpStimParams,testInterval)
        waitUntil(obj,stopTimeMicroSeconds)
        [psiParamsQuest, psiParamsFit, psiParamsCI, fVal] = reportParams(obj,options)
        figHandle = plotOutcome(obj,visible)
        resetSearch(obj)
    end
end