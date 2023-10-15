function photoreceptors = photoreceptorDictionaryCanine(varargin)

p = inputParser;
p.parse(varargin{:});

% The set of photoreceptor classes
photoreceptorClassNames = {'canineS','canineMel','canineRod','canineML'};

for ii = 1:length(photoreceptorClassNames)

    % assign the name of the photoreceptor
    photoreceptors(ii).name = photoreceptorClassNames{ii};

    % assign the species
    photoreceptors(ii).species = 'canine';

    switch photoreceptors(ii).name
        case 'canineS'
            photoreceptors(ii).whichReceptor = 'sc';
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('SCone');
        case 'canineMel'
            photoreceptors(ii).whichReceptor = 'mel';
            photoreceptors(ii).plotColor = SSTDefaultReceptorColors('Mel');
        case 'canineRod'
            photoreceptors(ii).whichReceptor = 'rh';
            photoreceptors(ii).plotColor = 'k';
        case 'canineML'
            photoreceptors(ii).whichReceptor = 'mc';
            photoreceptors(ii).plotColor = 'y';
        otherwise
            error('Not a recognized photoreceptor')

    end

end


end