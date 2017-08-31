function [K, varargout]= back_out_1dfilter(x,R,N,EPS,ZEROPAD);

% attempt to do the baccus-style filtering to get the two dimensional
% filter back out...

x=x(:)' - mean(x); R=R(:)' - mean(R);

interval = 100; % this can be changed without much trouble
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
ssdenom = sum(abs(mean(xw.*conj(xw),1)));
ssdenom = max(abs(mean(xw.*conj(xw),1)));
denom=mean(xw.*conj(xw),1)+EPS*abs(mean(mean(xw.*conj(xw),1)));
ssdenom2 = max(abs(denom));
denom = denom * (ssdenom/ssdenom2); % keeps the low frequency stuff at same power after adding epsilon

Kw = num./denom;
Cohw = abs(num).^2./abs(mean(Rw.*conj(Rw),1))./abs(mean(xw.*conj(xw),1));

% keyboard;

K=ifft(Kw);
if ZEROPAD
    K=K(1:end/2); %% IS THIS THE CORRECT HALF? think so.
end

Rt=filter(K,1,x);
C=corr([R(:),Rt(:)]);
varargout{1}=C(1,2);
varargout{2}=Rt;
varargout{3}=Cohw; % coherence as a function of frequency

% keyboard;

