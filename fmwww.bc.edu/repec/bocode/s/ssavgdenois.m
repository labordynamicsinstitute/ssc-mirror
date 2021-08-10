function  [ybar]=ssavgdenois(y,m)
tic
%__________________________________________________________________________
% Usage: State space averaging method for denoising time series 
 
% Inputs: 
%   y  is a vector and m is embedding dimension e.g. 2,3,4. The
%   embedding dimension can be determined by  autocorrelation function 
%   or minimum mutual information(MMI).
 
% Output:
%    ybar is denoised series. 
%    Also the code plots two figures for original and denoised  series.


% Copyright(c) Shapour Mohammadi, University of Tehran, 2008
% shmohammadi@gmail.com
 
% Keywords: Denoising, state space averaging, time series , chaose.
% Ref.: 
% Sprott,C.(2003)Chaos and Time Series Analysis,Oxford University Press.
%__________________________________________________________________________



y1=y(:);
for ii=.3*std(y):-.1*std(y):.1*std(y)
N=size(y1,1);
s2=nan(2*m+1,1);
w=nan(N-2*m,1);
z=nan(N-2*m,1);
sigma2=ii;
y11=lagmatrix(y1,-m:m);
for  n=m:N-m-1
    for k=m:N-m-1
        
        s2=(y11(k+1,:)-y11(n+1,:)).^2;
       
        w(k-m+1,1)=exp(-(sigma2^(-1))*sum(s2));
        z(k-m+1,1)=w(k-m+1,1)*y1(k,1);
    end
    ybar1(n-m+1,1)=sum(z)/sum(w);
end
y1=ybar1;
end
ybar=ybar1;
%__________________________________________________________________________
figure
plot(y(2:end), y(1:end-1),'.')
title('Noisey series')
figure
plot(ybar(2:end) , ybar(1:end-1),'.g')
title('Denoised series')
toc