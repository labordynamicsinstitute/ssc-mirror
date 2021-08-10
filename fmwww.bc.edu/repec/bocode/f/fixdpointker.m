function [fixhist,fixker,Modes]=fixdpointker(y)

%__________________________________________________________________________
% This code finds fixed points of time series by method of So et al. Also I
% use kernel density method for finding modes as fixed points and
% derivatives for determining attractor and repellor fixed points.Histogram
% method is discontinues and derivative cannot be calculated for it.
% Therefore I use kernel density in addition to So et al (1996) method.
% Positive to negative cross of  kernel density derivative graph validates
% modes which are fixed points. fix kernel is only first fixed point, but
% Mods give all of fixed points.
 
% Inputs:
%   y is  one variable time series data.
 
% Outputs:
%   fixhist, fixed point by histogram method.
%   fixker, fixed point by kernel method.
%   Mods, fxed points by modes of  kernel density distribution and kernel
%   derivatives.
 
% Ref:
%   1-So P., E. Ott, S.J. Schiff, D.T. Kaplan, T. Sauer, and C. Grebogi,
%   (1996).Detecting Unstable Periodic Orbits in Chaotic Experimental Data,
%   Physical Review Letters 17 June, Volume 76, Number 25.
%   2-Pagan,A., Ullah, A. (1999). Nonparametric Econometrics. Cambridge
%   University Press.
 
% Keywords: Fixed points, Attractors, Kernel density estimation, Histogram,
%   Modes, Multimodality, Nonparametric estimation, Econometrics.
 
% Copyright(c) Shapour Mohammadi, University of Tehran, 2009
%   shmohammadi@gmail.com
 
%__________________________________________________________________________


tic

ry=length(y);

%generates random numbers in [-1,1]*5

EE=(y(3:end,1)-y(2:end-1,1))./(y(2:end-1,1)-y(1:end-2,1));

kapa=max(y)-min(y);
k=(-1+2*(rand(500,1)))*kapa;

[nn,xouthist]=hist(y,200);

%calculation of interquqartile range for bandwidth deterimination
R=iqr(y);
h=0.9*min(std(y),(R/1.34))*(ry^(-1/5));
[ff,xoutker]=ksdensity(y,'npoints',200,'width',h);
rk=length(k);

for j=1:rk
s=(y(3:end,1)-y(2:end-1,1))./(y(2:end-1,1)-y(1:end-2,1))+k(j,1)*...
    (y(2:end-1,1)-y(1:end-2,1));
yhat(:,j)=(y(2:end-1,1)-s.*y(1:end-2,1))./(1-s);
end

for i=1:rk
[n]=hist(yhat(:,i),xouthist);
N(:,i)=n';

[f,x]=ksdensity(yhat(:,i),xoutker);
F(:,i)=f';
end

MN=mean(N')';
maxlocationhist=find(MN(2:199)==max(MN(2:199)));
fixhist=xouthist(maxlocationhist+1);

figure;
bar(xouthist(2:199),MN(2:199))
title('Histogram Plot: Peaks are fixed points')


MF=mean(F')';
maxlocationker=find(MF==max(MF));
fixker=xoutker(maxlocationker);

figure
plot(xoutker,MF,'- k')
title('Kernel Density Plot: Peaks are fixed points')


%calculation of the Derivatives by 
%f'=(1/h)sumj=0 to s((-1)^(j)C(j,s)fhat(x+(s-2j)/2h)) Pagan and Ullah
%(1999,p.20)

for i=1:rk
[fhat11,xoutderiv1]=ksdensity(yhat(:,i),xoutker+h/2);
[fhat21,xoutderiv2]=ksdensity(yhat(:,i),xoutker-h/2);
fhat1(:,i)=(1/h)*(fhat11-fhat21);
end

Mfhat1=mean(fhat1')';
figure
plot(xoutker,Mfhat1,'-k')
title('Derivatives of kernel density')

zeroline=Mfhat1-Mfhat1;
hold on 
plot(xoutker,zeroline,'-k')

% finding mods by minimums of Mfhat1

for i=2:199
if(Mfhat1(i-1)>0 && Mfhat1(i+1)<0)    
mods(i,1)=xoutker(i);
end
end
Modes=mods(mods~=0);

toc
%__________________________________END_____________________________________
