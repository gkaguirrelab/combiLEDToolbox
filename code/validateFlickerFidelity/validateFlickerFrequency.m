% Open a CombiLEDcontrol object
obj = CombiLEDcontrol();

modResult = designModulation('LightFlux');
modResult.settingsBackground([1 2 3 4 6 7 8])=0.5;
modResult.settingsHigh([1 2 3 4 6 7 8])=0.5;
modResult.settingsLow([1 2 3 4 6 7 8])=0.5;
obj.setSettings(modResult);
obj.setBackground(modResult.settingsBackground);
obj.setWaveformIndex(1);
obj.setContrast(1);
obj.setAMIndex(0);

freqsToTest = [3,6,12,24,48];

disp('Connect Klein.');
pause;

figure
for ff=1:length(freqsToTest)
    obj.setFrequency(freqsToTest(ff));
    luminance256HzData = obtainKleinMeasure(obj,2);
    luminance256HzData = luminance256HzData-mean(luminance256HzData);
    X=[sin( 2*2*pi*freqsToTest(ff).*(0:length(luminance256HzData)-1)/length(luminance256HzData));...
        cos( 2*2*pi*freqsToTest(ff).*(0:length(luminance256HzData)-1)/length(luminance256HzData))];
    b=X'\luminance256HzData';
    fitLum = X'*b;    
    [frq, amp] = simpleFFT( luminance256HzData, 256);
    subplot(2,5,ff);
    plot(luminance256HzData,'.');
    hold on
    plot(fitLum,'-r');
    subplot(2,5,ff+5);
    loglog(frq,amp,'.k');
    hold on
    loglog(frq,amp,'-r');
    title(sprintf('%d Hz, amp=%2.0f',freqsToTest(ff),norm(b)));
    xlabel('log frequency');
    ylabel('log luminance / freq');
    drawnow
end