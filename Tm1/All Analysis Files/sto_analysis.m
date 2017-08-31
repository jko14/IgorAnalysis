function [meanfilter] = sto_analysis
input1 = uigetfile('*.mat');
length1 = input('How long would you like the filter to be (in ms)?   ');
read_contrast(input1);
filter1 = ans{1,1};
filter2 = ans{2,1};
filter1 = back_out_1dfilter(filter1(:,2),filter1(:,3),length1,1);
filter2 = back_out_1dfilter(filter2(:,2),filter2(:,3),length1,1);
filter1 = filter1';
filter2 = filter2';
filters = [filter1, filter2];
meanfilter = mean(filters,2);
end

