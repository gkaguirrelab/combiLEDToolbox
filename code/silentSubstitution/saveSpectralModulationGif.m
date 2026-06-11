function saveSpectralModulationGif(modResult,saveDir,options)
% Save an animation of a temporal spectral modulation


arguments
    modResult (1,1) {isstruct}
    saveDir {mustBeFolder}
    options.nFrames = 80
    options.profile = 'sinusoid'
    options.receptorSet = {'S_10deg','Mel','M_10deg','L_10deg'}

end


% Grab the wavelengths
S = modResult.meta.cal.rawData.S;
wavelengths = SToWls(S);

% Grab the spectra
background = modResult.backgroundSPD';
positive = modResult.positiveModulationSPD';
negative = modResult.negativeModulationSPD';

% Get the desired photoreceptors
[~, receptorIdx] = ismember(options.receptorSet, {modResult.meta.photoreceptors.name});
nReceptors = length(receptorIdx);
T_receptors = modResult.meta.T_receptors(receptorIdx,:);
receptorColors = {modResult.meta.photoreceptors(receptorIdx).plotColor};

% Where to save the animation
fileName = fullfile(saveDir,[modResult.meta.whichDirection '_' options.profile '_modulate.gif']);

% Define the contrast vector
switch options.profile
    case 'sinusoid'
        timeVec = linspace(0, 60, options.nFrames);
        theta = linspace(0, 2*pi, options.nFrames);
        contrastVec = sin(theta);
    otherwise
        erorr('not a defined profile')
end

% Set up a figure window to hold three side-by-side panels
fig = figure('Position', [30, 100, 1600, 520], 'Color', 'w');

% Define Global Font Sizes
titleFontSize = 20;
labelFontSize = 17;
axisFontSize  = 15;

for ii = 1:options.nFrames

    current_time = timeVec(ii);
    m = contrastVec(ii);

    % Calculate current spectrum based on modulation phase
    if m >= 0
        current_spectrum = background + m * (positive - background);
    else
        current_spectrum = background + abs(m) * (negative - background);
    end

    % Compute photoreceptor isomerization rates
    isomerization_rates = calculateRelativeIsomerizationRates(current_spectrum, T_receptors);

    % Panel 1: Modulation Timeline
    subplot(1, 3, 1);
    cla; hold on; grid on;

    if ii > 1
        plot(timeVec(1:ii), contrastVec(1:ii), 'k-', 'LineWidth', 3);
    end
    plot(current_time, m, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 11, 'LineWidth', 2);

    xlim([0 60]);
    ylim([-1.2 1.2]);
    set(gca, 'FontSize', axisFontSize, 'LineWidth', 1.5);
    xlabel('Time (seconds)', 'FontSize', labelFontSize, 'FontWeight', 'bold');
    ylabel('Contrast', 'FontSize', labelFontSize, 'FontWeight', 'bold');
    title('Sinusoidal Modulation Course', 'FontSize', titleFontSize, 'FontWeight', 'bold');

    % Panel 2: Spectral Content Modulation
    subplot(1, 3, 2);
    cla; hold on; grid on;

    plot(wavelengths, background, 'Color', [0.75 0.75 0.75], 'LineWidth', 3.5);
    plot(wavelengths, current_spectrum, 'Color', 'k', 'LineWidth', 3.5);

    set(gca, 'FontSize', axisFontSize, 'LineWidth', 1.5);
    xlabel('Wavelength (nm)', 'FontSize', labelFontSize, 'FontWeight', 'bold');
    ylabel('Spectral Power Distribution', 'FontSize', labelFontSize, 'FontWeight', 'bold');
    title('Modulation of Spectral Content', 'FontSize', titleFontSize, 'FontWeight', 'bold');
    xlim([min(wavelengths) max(wavelengths)]);
    ylim([0 max([positive, negative, background])*1.2]);

    % Panel 3: Isomerization Rate
    subplot(1, 3, 3);
    cla; hold on; grid on;

    hBar = bar(1:nReceptors, isomerization_rates, 'FaceColor', 'flat', 'EdgeColor', [0.2 0.2 0.2], 'LineWidth', 1.5);

    % Set bar colors
    for pp = 1:nReceptors
    hBar.CData(pp, :) = receptorColors{pp};
    end

    ylim([0 14]);
    set(gca, 'XTick', 1:4, 'XTickLabel', {'S', 'Mel', 'M', 'L'}, ...
        'FontSize', axisFontSize, 'FontWeight', 'bold', 'LineWidth', 1.5);
    ylabel('Isomerization Rate (au)', 'FontSize', labelFontSize, 'FontWeight', 'bold');
    title('Isomerization Rate', 'FontSize', titleFontSize, 'FontWeight', 'bold');

    % Force immediate graphic update
    drawnow;

    % Capture combined figure window layout for the GIF
    frame = getframe(fig);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);

    % Write/Append to the GIF file
    if ii == 1
        imwrite(imind, cm, fileName, 'gif', 'Loopcount', inf, 'DelayTime', 0.05);
    else
        imwrite(imind, cm, fileName, 'gif', 'WriteMode', 'append', 'DelayTime', 0.05);
    end
end

close(fig);

end


%% Photoreceptor Isomerization Rate Calculation Function

function rates = calculateRelativeIsomerizationRates(current_spectrum, T_receptors)
rates = zeros(1, size(T_receptors, 1));
for ii = 1:size(T_receptors,1)
    rates(ii) = sum(current_spectrum .* T_receptors(ii, :));
end
end