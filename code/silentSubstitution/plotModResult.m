function figHandle = plotModResult(modResult,visible)

% Set the figure to visible unless we say otherwise
if nargin==1
    visible = 'on';
end

% Extract some elements
whichDirection = modResult.meta.whichDirection;
wavelengthsNm = modResult.wavelengthsNm;
positiveModulationSPD = modResult.positiveModulationSPD;
negativeModulationSPD = modResult.negativeModulationSPD;
backgroundSPD = modResult.backgroundSPD;
contrastReceptorsBipolar = modResult.contrastReceptorsBipolar;
whichReceptorsToTarget = modResult.meta.whichReceptorsToTarget;
whichReceptorsToIgnore = modResult.meta.whichReceptorsToIgnore;
settingsLow = modResult.settingsLow;
settingsHigh = modResult.settingsHigh;
settingsBackground = modResult.settingsBackground;
photoreceptorClassNames = {modResult.meta.photoreceptors.name};
nPrimaries = length(settingsBackground);
nPhotoClasses = length(photoreceptorClassNames);

% Create a figure with an appropriate title
figName = sprintf([modResult.meta.photoreceptors(1).species ' ' whichDirection ': contrast = %2.2f'],contrastReceptorsBipolar(whichReceptorsToTarget(1)));
figHandle = figure('Visible',visible,'Name',figName);
figuresize(900, 400,'pt');

% Receptor spectra
subplot(2,4,5:6)
nReceptors = length(modResult.meta.photoreceptors);
for ii = 1:nReceptors
    vec = modResult.meta.T_receptors(ii,:);
    plotColor = modResult.meta.photoreceptors(ii).plotColor;
    plot(wavelengthsNm,vec,'-','Color',plotColor,'LineWidth',2);
hold on
end
title('Receptor spectra');
xlim([300 800]);
xlabel('Wavelength');
ylabel('Relative sensitivity');

% Modulation spectra
subplot(2,4,1:2)
hold on
plot(wavelengthsNm,positiveModulationSPD,'k','LineWidth',2);
plot(wavelengthsNm,negativeModulationSPD,'r','LineWidth',2);
plot(wavelengthsNm,backgroundSPD,'Color',[0.5 0.5 0.5],'LineWidth',2);
title('Modulation spectra');
xlim([300 800]);
xlabel('Wavelength');
ylabel('Power');

% Primaries
subplot(2,4,3)
c = 1:nPrimaries;
hold on
plot(c,settingsHigh,'*k');
plot(c,settingsLow,'*r');
plot(c,settingsBackground,'-*','Color',[0.5 0.5 0.5]);
set(gca,'TickLabelInterpreter','none');
title('Primaries');
if isfield(modResult.meta,'primaryLabels')
    a = gca;
    a.XTickLabel = modResult.meta.primaryLabels;
end
ylim([-0.1 1.1]);
xlim([0.5 nPrimaries+0.5])
xlabel('Primary');
ylabel('Setting');
axis square

% Contrasts
subplot(2,4,7)
c = 1:nPhotoClasses;
barVec = zeros(1,nPhotoClasses);
thisBar = barVec;
thisBar(whichReceptorsToTarget) = contrastReceptorsBipolar(whichReceptorsToTarget);
bar(c,thisBar,'FaceColor',[0.5 0.5 0.5],'EdgeColor','none');
hold on
thisBar = barVec;
thisBar(whichReceptorsToIgnore) = contrastReceptorsBipolar(whichReceptorsToIgnore);
bar(c,thisBar,'FaceColor','w','EdgeColor','k');
thisBar = contrastReceptorsBipolar;
thisBar(whichReceptorsToTarget) = nan;
thisBar(whichReceptorsToIgnore) = nan;
bar(c,thisBar,'FaceColor','none','EdgeColor','r');
set(gca,'TickLabelInterpreter','none');
a = gca;
a.XTick=1:nPhotoClasses;
a.XTickLabel = photoreceptorClassNames;
xlim([0.5 nPhotoClasses+0.5]);
title('Contrast');
ylabel('Contrast');
axis square

% Chromaticity
subplot(2,4,8)

% Start with the Matlab chromaticity diagram
plotChromaticity;
hold on

% Load the XYZ fundamentals
load('T_xyz1931.mat','T_xyz1931','S_xyz1931');
S = WlsToS(wavelengthsNm);
T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
xyYLocus = XYZToxyY(T_xyz);

% Calculate the luminance and the chromaticities
bg_photopicLuminanceCdM2_Y = T_xyz(2,:)*backgroundSPD;
bg_chromaticity_xy = (T_xyz(1:2,:)*backgroundSPD/sum(T_xyz*backgroundSPD));
modPos_chromaticity_xy = (T_xyz(1:2,:)*positiveModulationSPD/sum(T_xyz*positiveModulationSPD));
modNeg_chromaticity_xy = (T_xyz(1:2,:)*negativeModulationSPD/sum(T_xyz*negativeModulationSPD));

% Plot the loci for each of the spectra
plot(bg_chromaticity_xy(1), bg_chromaticity_xy(2), 'o','MarkerEdgeColor','w','MarkerFaceColor', [0.5 0.5 0.5],'LineWidth', 2, 'MarkerSize', 10);
plot(modPos_chromaticity_xy(1), modPos_chromaticity_xy(2), 'o','MarkerEdgeColor','w','MarkerFaceColor', 'k', 'LineWidth', 2,'MarkerSize', 10);
plot(modNeg_chromaticity_xy(1), modNeg_chromaticity_xy(2), 'o','MarkerEdgeColor','w','MarkerFaceColor', 'r','LineWidth', 2, 'MarkerSize', 10);

% Labels
xlabel('x chromaticity');
ylabel('y chromaticity');
title(sprintf('Luminance %2.1f cd/m2',bg_photopicLuminanceCdM2_Y))
axis square

% Show a square of color at the background location
subplot(2,4,4)
rgb=xyz2rgb([bg_chromaticity_xy; 0]');
im = zeros(10,10,3);
im(:,:,1)=rgb(1); im(:,:,2)=rgb(2); im(:,:,3)=rgb(3);
imagesc(im)
axis off

end