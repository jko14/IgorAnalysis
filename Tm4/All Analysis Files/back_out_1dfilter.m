function [K, varargout]= back_out_1dfilter(x,R,varargin);

% attempt to do the baccus-style filtering to get the two dimensional
% filter back out...

% 090429 -- this is not working all of a sudden. perhaps just not working
% with binary inputs? doesn't work well with width 2 delta functions...

x=x(:)' - mean(x); R=R(:)' - mean(R);

if ~length(varargin)
    N=100; % size of filter to look for...
else
    N=varargin{1};
end
ZEROPAD = 1;
if length(varargin)>1;
    EPS = varargin{2};
else
    EPS = 0;
end

interval = 3; % so you aren't in phase with 60 hz pick up
spacing=1:interval:length(R)-N;

if ~ZEROPAD
    xw=zeros(length(spacing),N);
    Rw=xw;
else
    xw=zeros(length(spacing),2*N);
    Rw=xw;
end


for i=1:length(spacing)
    if ~ZEROPAD
        xw(i,:)=fft(x(spacing(i):spacing(i)+N-1));
        Rw(i,:)=fft(R(spacing(i):spacing(i)+N-1));
    else
        xw(i,:)=fft([x(spacing(i):spacing(i)+N-1),zeros(1,N)]);
        Rw(i,:)=fft([R(spacing(i):spacing(i)+N-1),zeros(1,N)]);
    end
end


num=mean((Rw).*conj(xw),1);
ssdenom = sum(abs(mean(xw.*conj(xw),1)).^2);
denom=mean(xw.*conj(xw),1)+EPS*abs(mean(mean(xw.*conj(xw),1)));
ssdenom2 = sum(abs(denom).^2);
denom = denom * ssdenom/ssdenom2; % equalize power with EPS!

Kw = num./denom; % DAC 081216 -- conjugate stimulus, as in baccus linear filter
% Kw = squeeze(mean(conj(Rw).*(xw),1)./mean(xw.*conj(xw),1)); % first written

K=ifft(Kw);
if ZEROPAD
    K=K(1:end/2); %% IS THIS THE CORRECT HALF? think so.
end

Rt=filter(K,1,x);
C=corr([R(:),Rt(:)]);
varargout{1}=C(1,2);
varargout{2}=Rt;

% keyboard;

