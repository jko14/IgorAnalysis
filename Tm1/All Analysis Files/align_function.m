function [align1, align2] = align_function(channel0, channel1)
%load igor files
timing = IBWread(channel1);
signal = IBWread(channel0);
timingy = timing.y';
signaly = signal.y';
figure;
plot(timingy)
threshold = input('Enter threshold: ');
close;
assignin('base','threshold',threshold);


%determine the threshold that defines a change in the stimulus - this value
%should be adjusted depending on peaks in ch1_x
%threshold = 100;

for i = 1:(length(timingy)-1)
    if timingy(i) > threshold && timingy(i+1) < threshold*0.10
        beginning = i;
        break
    end
end

align1 = timingy(beginning:end);
align2 = signaly(beginning:end);

