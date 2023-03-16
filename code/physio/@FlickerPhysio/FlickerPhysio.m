% Object to control the collection of ssVEP and pupillometry data for a
% particular amplitude modulated flicker

classdef FlickerPhysio < handle

    properties (Constant)
    end

    % Private properties
    properties (GetAccess=private)
    end

    % Calling function can see, but not modify
    properties (SetAccess=private)
        pupilObj
        vepObj
        parpoolHandle

        dataOutDir

        simulateStimuli

        % Some stimulus properties
        stimFreqHz
        stimContrast
        stimContrastAdjusted
        amFreqHz
        halfCosineRampDurSecs
        trialDurationSecs
        trialData
        preTrialJitterRangeSecs
        cycleDurationSecs
        nSubTrials
    end

    % These may be modified after object creation
    properties (SetAccess=public)

        % The display object. This is modifiable so that we can re-load
        % a CollectFreqMatchTriplet, update this handle, and then continue
        % to collect data
        CombiLEDObj

        % A prefix to be added to the data files
        filePrefix

        % Verbosity
        verbose;

    end

    methods

        % Constructor
        function obj = FlickerPhysio(CombiLEDObj,subjectID,modDirection,experimentName,varargin)

            % input parser
            p = inputParser; p.KeepUnmatched = false;
            p.addParameter('stimFreqHz',20,@isnumeric);
            p.addParameter('stimContrast',0.75,@isnumeric);
            p.addParameter('amFreqHz',0.25,@isnumeric);
            p.addParameter('halfCosineRampDurSecs',0.1,@isnumeric);
            p.addParameter('trialDurationSecs',20,@isnumeric);
            p.addParameter('preTrialJitterRangeSecs',[0,1],@isnumeric);
            p.addParameter('simulateStimuli',false,@islogical);
            p.addParameter('dropBoxBaseDir',getpref('combiLEDToolbox','dropboxBaseDir'),@ischar);
            p.addParameter('projectName','combiLED',@ischar);
            p.addParameter('approachName','flickerPhysio',@ischar);
            p.addParameter('verbose',true,@islogical);
            p.parse(varargin{:})

            % Place various inputs and options into object properties
            obj.CombiLEDObj = CombiLEDObj;
            obj.stimFreqHz = p.Results.stimFreqHz;
            obj.stimContrast = p.Results.stimContrast;
            obj.amFreqHz = p.Results.amFreqHz;
            obj.halfCosineRampDurSecs = p.Results.halfCosineRampDurSecs;
            obj.trialDurationSecs = p.Results.trialDurationSecs;
            obj.preTrialJitterRangeSecs = p.Results.preTrialJitterRangeSecs;            
            obj.simulateStimuli = p.Results.simulateStimuli;
            obj.verbose = p.Results.verbose;

            % Figure out the cycleDurationSecs and the number of subtrials
            obj.cycleDurationSecs = 1/obj.amFreqHz;
            obj.nSubTrials = ceil(obj.trialDurationSecs/obj.cycleDurationSecs);

            % Define the dir in which to save the trial
            obj.dataOutDir = fullfile(...
                p.Results.dropBoxBaseDir,...
                p.Results.projectName,...
                p.Results.approachName,...
                subjectID,modDirection,experimentName);

            % Create the directory if it isn't there
            if ~isfolder(obj.dataOutDir)
                mkdir(obj.dataOutDir)
            end

            % There is a roll-off (attenuation) of the amplitude of
            % modulations with frequency. We can adjust for this property,
            % and detect those cases which are outside of our ability to
            % correct
            obj.stimContrastAdjusted = obj.stimContrast ./ ...
                contrastAttentionByFreq(obj.stimFreqHz);

            % Check that the adjusted contrast does not exceed unity
            mustBeInRange(obj.stimContrastAdjusted,0,1);

            % Create a file prefix for the raw data from the stimulus
            % properties
            filePrefix = sprintf('freq_%2.1f_contrast_%2.3f_',obj.stimFreqHz,obj.stimContrast);

            % Initialize the pupil recording object. We set it to be one
            % seconds longer, as there is a delay in starting the
            % recording, so we initiate the recording one second before
            % giving the command to start the stimulus.
            obj.pupilObj = PupilLabsControl(subjectID,modDirection,experimentName,...
                'filePrefix',filePrefix,...
                'trialDurationSecs',obj.trialDurationSecs+1,...
                'approachName',p.Results.approachName,...
                'backgroundRecording',true);

            % Initialize the ssVEP recording object
            obj.vepObj = BiopackControl(subjectID,modDirection,experimentName,...
                'filePrefix',filePrefix,...
                'trialDurationSecs',obj.cycleDurationSecs,...
                'nSubTrials',obj.nSubTrials, ...
                'approachName',p.Results.approachName);


        end

        % Required methds
        collectTrial(obj)
        waitUntil(obj,stopTimeMicroSeconds)
    end
end