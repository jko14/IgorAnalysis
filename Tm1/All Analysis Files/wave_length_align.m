function outmatrix = wave_length_align(varargin)
lengthvec = [];
for i = 1:length(varargin)
    lengthvec(i) = length(varargin(i));
end

minlength = min(lengthvec);

for j = 1:length(varargin);
    x = varargin(i);
    outmatrix(i,:) = x(1:minlength);
end

end

