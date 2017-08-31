function read_data(timing_filename, signal_filename, mat_filename)
%READ_DATA Segment the signal for later processing.
% The last experiment will be ignored, since its end time cannot be
% determined from the signal. To work around this, just add a
% "show_interval" experiment at the end.

%% Recognize timing events in the recorded signal

% Values that are larger than "threshold" will be considered candidates of
% timing events
threshold = 20;
% The start of a timing event should be at least "step" seconds later than
% the end of the previous event
step = 0.2;
% Resampled frequency
freq = 1000;
t = 1 / freq; % period

timing = IBWread(timing_filename);
signal = IBWread(signal_filename);
y1 = timing.y';
y2 = signal.y';
assert(length(y1) == length(y2), 'Timing and signal files have different lengths.');
assert(timing.dx == signal.dx, 'Timing and signal files have different frequencies.');
x_orig = (1: length(y1)) * timing.dx;
x = t: t: x_orig(end);
y1 = interp1(x_orig, y1, x, 'nearest', 0); % resample to "freq" Hz
y2 = interp1(x_orig, y2, x, 'nearest', 0);

% This is necessary since it's very difficult to recognize the first event
figure;
plot(x, y1);
start = input('Input the time from which the program should start searching: ');

% Index into "x", "y1" and "y2"
event_idxs = find(y1 > threshold);
event_idxs = event_idxs(event_idxs >= search(start, x));
event_idxs = event_idxs([true, diff(x(event_idxs)) >= step]);

%% Align the recorded signal with the experiment data

exp_data = load(mat_filename);
exp_data = exp_data.exp_data;

% Index into "exp_data"
tick_idxs = find(strcmp({exp_data.event}, 'tick'));
assert(length(event_idxs) == length(tick_idxs), ...
    'Number of recognized events is not equal to that in the experiment data.');

offset = exp_data(tick_idxs(1)).time - x(event_idxs(1));
x = x + offset;
figure;
hold on;
plot(x, y1);
stem([exp_data(tick_idxs).time], ones(size(tick_idxs)) * threshold);
hold off;

fprintf('Time discrepancies for each event (in milliseconds):\n');
discrepancies = (x(event_idxs) - [exp_data(tick_idxs).time]) * 1000;
disp(discrepancies);
fprintf('Min discrepancy: %.2f ms\n', min(discrepancies));
fprintf('Max discrepancy: %.2f ms\n', max(discrepancies));

%% Segment the signal and save into separate MAT files

[pathstr, name, ext] = fileparts(mat_filename);

% Index into "exp_data"
top_level_idxs = find([exp_data.is_top_level]);

% Index into "tick_idxs" and "event_idxs"
tick_beg = 1;
for i = 1: length(top_level_idxs) - 1
    % One past end
    tick_end = search(top_level_idxs(i + 1), tick_idxs);
    
    top_level = exp_data(top_level_idxs(i));
    parameters = top_level.parameters;
    signal = cell(tick_end - tick_beg, 1);
    for j = tick_beg: tick_end - 1
        signal_j = [x(event_idxs(j): event_idxs(j + 1) - 1)', ...
                    y1(event_idxs(j): event_idxs(j + 1) - 1)', ...
                    y2(event_idxs(j): event_idxs(j + 1) - 1)'];
        signal{j - tick_beg + 1} = signal_j;
    end
    
    switch top_level.event
        case 'show_interval'
            assert(tick_end - tick_beg == 1, 'show_interval: Unexpected number of timing events.');
            save(fullfile(pathstr, sprintf('%s_%d_show_interval%s', name, i, ext)), 'parameters', 'signal');
        case 'stimulus_script_fff'
            assert(tick_end - tick_beg == 2 * parameters.reps, 'fff: Unexpected number of timing events.');
            assert(strcmp(exp_data(top_level_idxs(i) + 1).event, 'colors'), 'fff: "colors" event not found');
            colors = exp_data(top_level_idxs(i) + 1).parameters;
            save(fullfile(pathstr, sprintf('%s_%d_fff%s', name, i, ext)), 'parameters', 'signal', 'colors');
        case 'stimulus_script_fff_sto'
            assert(tick_end - tick_beg == parameters.reps, 'fff_sto: Unexpected number of timing events.');
            colors = cell(tick_end - tick_beg, 1);
            for j = tick_beg: tick_end - 1
                colors_j = exp_data(tick_idxs(j) + 1: tick_idxs(j + 1) - 1);
                colors_j = colors_j(strcmp({colors_j.event}, 'flipped'));
                colors_j = [{colors_j.time}' {colors_j.parameters}'];
                colors{j - tick_beg + 1} = colors_j;
            end
            save(fullfile(pathstr, sprintf('%s_%d_fff_sto%s', name, i, ext)), 'parameters', 'signal', 'colors');
        case 'stimulus_script_rf'
            assert(strcmp(exp_data(top_level_idxs(i) + 1).event, 'colors'), 'rf: "colors" event not found');
            colors = exp_data(top_level_idxs(i) + 1).parameters;
            rects = cell(tick_end - tick_beg, 1);
            for j = tick_beg: tick_end - 1
                rects_j = exp_data(tick_idxs(j));
                rects_j = {rects_j.time rects_j.parameters};
                rects{j - tick_beg + 1} = rects_j;
            end
            save(fullfile(pathstr, sprintf('%s_%d_rf%s', name, i, ext)), 'parameters', 'signal', 'colors', 'rects');
        case 'stimulus_script_rf_sto'
            assert(tick_end - tick_beg == 1, 'rf_sto: Unexpected number of timing events.');
            assert(strcmp(exp_data(top_level_idxs(i) + 1).event, 'rect degrees'), 'rf_sto: "rect degrees" event not found');
            rects = exp_data(top_level_idxs(i) + 1).parameters;
            colors = exp_data(tick_idxs(tick_beg) + 1: tick_idxs(tick_beg + 1) - 1);
            colors = colors(strcmp({colors.event}, 'flipped'));
            colors = [{colors.time}' {colors.parameters}'];
            colors = {colors};
            save(fullfile(pathstr, sprintf('%s_%d_rf_sto%s', name, i, ext)), 'parameters', 'signal', 'rects', 'colors');
        case 'stimulus_script_moving_line'
            assert(tick_end - tick_beg == 1, 'moving_line: Unexpected number of timing events.');
            assert(strcmp(exp_data(top_level_idxs(i) + 1).event, 'colors'), 'moving_line: "colors" event not found');
            colors = exp_data(top_level_idxs(i) + 1).parameters;
            percentage = exp_data(tick_idxs(tick_beg) + 1: tick_idxs(tick_beg + 1) - 1);
            percentage = percentage(strcmp({percentage.event}, 'flipped'));
            percentage = [[percentage.time]' [percentage.parameters]'];
            percentage = {percentage};
            save(fullfile(pathstr, sprintf('%s_%d_moving_line%s', name, i, ext)), 'parameters', 'signal', 'colors', 'percentage');
        case 'stimulus_script_moving_edge'
            assert(tick_end - tick_beg == 1, 'moving_edge: Unexpected number of timing events.');
            assert(strcmp(exp_data(top_level_idxs(i) + 1).event, 'colors'), 'moving_edge: "colors" event not found');
            colors = exp_data(top_level_idxs(i) + 1).parameters;
            percentage = exp_data(tick_idxs(tick_beg) + 1: tick_idxs(tick_beg + 1) - 1);
            percentage = percentage(strcmp({percentage.event}, 'flipped'));
            percentage = [[percentage.time]' [percentage.parameters]'];
            percentage = {percentage};
            save(fullfile(pathstr, sprintf('%s_%d_moving_edge%s', name, i, ext)), 'parameters', 'signal', 'colors', 'percentage');
        case 'stimulus_script_step_cont'
            assert(tick_end - tick_beg == (numel(parameters.cont) * 2 + 1) * 2 * parameters.reps, 'step_cont: Unexpected number of timing events.');
            save(fullfile(pathstr, sprintf('%s_%d_step_cont%s', name, i, ext)), 'parameters', 'signal');
        case 'stimulus_script_moving_sine'
            assert(tick_end - tick_beg == 1, 'moving_sine: Unexpected number of timing events.');
            save(fullfile(pathstr, sprintf('%s_%d_moving_sine%s', name, i, ext)), 'parameters', 'signal');
        case 'stimulus_script_moving_square'
            assert(tick_end - tick_beg == 1, 'moving_square: Unexpected number of timing events.');
            save(fullfile(pathstr, sprintf('%s_%d_moving_square%s', name, i, ext)), 'parameters', 'signal');
        otherwise
            error('Unexpected top-level event: %s', top_level.event);
    end
    
    tick_beg = tick_end;
end

end

% For each element in "x", find the index of the first element in the
% sorted vector "y" that is greater than or equal to it (or the last index
% if not found)
function idxs = search(x, y)

assert(isvector(y));

idxs = zeros(size(x));
for i = 1: numel(x)
    b = 1;
    e = length(y);
    while b < e
        m = floor((b + e) / 2);
        if y(m) == x(i)
            b = m;
            e = m;
        elseif y(m) > x(i)
            e = m;
        else
            b = m + 1;
        end
    end
    idxs(i) = b;
end

end