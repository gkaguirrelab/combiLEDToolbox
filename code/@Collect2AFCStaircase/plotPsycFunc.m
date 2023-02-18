function plotPsycFunc(obj)

TestFrequencySet = obj.TestFrequencySet;

testParams = {obj.trialHistory(:).testParams};
testFrequencies = cellfun(@(x) x(2),testParams);
nTrials = length(testFrequencies);

figure
subplot(1,2,1);
plot(1:nTrials,testFrequencies)
xlabel('trial number');
ylabel('test freq [Hz]');
ylim([min(TestFrequencySet) max(TestFrequencySet)])

testInterval = cell2mat({obj.trialHistory(:).testInterval});
response = cell2mat({obj.trialHistory(:).response});
validTrials = cell2mat({obj.trialHistory(:).validResponse});

proportionTestFaster = nan(size(TestFrequencySet));
for ii=1:length(TestFrequencySet)
    % Find those trials that presented a given frequency
    idx = find(and(testFrequencies == TestFrequencySet(ii),validTrials));
    % How many times was the test judged faster?
    if ~isempty(idx)
        proportionTestFaster(ii) = sum(testInterval(idx)==response(idx))/length(idx);
    end
end

subplot(1,2,2);
semilogx(TestFrequencySet,proportionTestFaster,'-*r')
xlabel('test Freq [Hz]');
ylabel('p test faster')
xlim([min(TestFrequencySet) max(TestFrequencySet)])

end