
%Prompts the user to select the signal and timing channels from the current
%folder
[channel0] = uigetfile('*.ibw','Select the signal channel: ');
[channel1] = uigetfile('*.ibw','Select the timing channel: ');


%Aligns signal and timing waves to the onset of the first show_interval
[timing,signal] = align_function(channel0,channel1);


%Plots figure of timing wave in order for the user to select the beginning
%and ending times of the traces which they wish to single out;
figure;
plot(timing)

start_time = input('Enter time to start (s) : ');
start_time = start_time*(10^4);
end_time = input('Enter time to end (s): ');
end_time = end_time*(10^4);

close;

z = input('Add time before or after trace? (y or n)   ','s');
if lower(z) == 'y'
    x = input('Time to add before trace (s) : ');
    x = x*(10^5);
    y = input('Time to add after trace (s) : ');
    y = y*(10^5);
else
    x = 0;
    y = 0;
end


% %Finds the time point of the first timing signal in the time range
% %specified by the user

timing = timing';

 
 for j = start_time:1:end_time
    if timing(j+1) > threshold && timing(j) < threshold*0.10
        user_start = j;
        break
    end
 end
 
 
 
 for j = end_time:-1:start_time
    if timing(j) < threshold*0.10 && timing(j-1) > threshold
        user_end = j;
        break
    end
 end
 signal = signal';
     output_wave = signal((user_start - x):(user_end + y));
     figure;
     plot(output_wave)
% 

