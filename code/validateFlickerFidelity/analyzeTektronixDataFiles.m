

freqsToTest = logspace(log10(4),log10(128),11);
dataFileDir = fullfile(fileparts(mfilename("fullpath")),'tektronixDataFiles');
dataFileList = dir(fullfile(dataFileDir,'*.CSV'));
% First loop over frequencies
figure

for ff=1:8

    fileName = fullfile(dataFileList(ff).folder,dataFileList(ff).name);
    opts = detectImportOptions(fileName);
    T = readtable(fileName,opts);

    ts = T{:,4};
    y = T{:,5};
    offset = mean(y);
    y = y - offset;

    X(:,1) = sin(2*pi*freqsToTest(ff).*ts);
    X(:,2) = cos(2*pi*freqsToTest(ff).*ts);

    b=X\y;

    yFit = b'*X';

    subplot(4,2,ff);
    plot(ts,y,'-k');
    hold on
    plot(ts,yFit,'r');
    ylim([-0.1 0.1])

    title(sprintf('Freq: %2.1f Hz, amp = %2.2f',freqsToTest(ff),range(yFit)))

end