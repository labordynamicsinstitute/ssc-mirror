
%___________________________Discription____________________________________
 
% This mfile is for generating chaotic 1D and 2D discrete maps. user can
% change number of realizations by chaging N value in line 54. Also
% parameters can be changed by changing values in lines:63,68,73 and so on.
% Noise level, can be changed in line 99.


% Keywords: Chaos, Logistic map, Cubic map, Ricker's map, Sin map.
% Henon map, Gingerbreadman map, Burgers' map, Tinkerbell map
 
% Ref:
% Sprott, C.(2003),Chaos and Time series Analysis, Oxford University Press.

% Copyright(c) Shapour Mohammadi, University of Tehran, 2009
% shmohammadi@gmail.com
%__________________________________________________________________________



%Initials for Gingerbreadman map
xgin=0.5;
ygin=3.7;

%Initials for Henon map
xhenon=0;
yhenon=0.9;

%Initials for Tinkerbell map
xtin=0;
ytin=0.5;

%Initials for Burgers' map
xber=-0.1;
yber=0.1;

%Initial for Logistic map
xlog=.1;

%Initials for Ricker's map
xexp=.1;

%Initials for Cubic map
xlogcub=.1;

%Initials for Sin map
xsin=.1;

% If you need more realizations(observations) you can increase N, 
% otherwise less observations are needed please decrease N to any 
% number that you want

N=5000;

for k=2:N
      
    % Gingerbreadman map
    xgin(k,1)=1+abs(xgin(k-1,1))-ygin(k-1,1);
    ygin(k,1)=xgin(k-1,1);
    
    % Henon map
    ahen=1.4; bhen=0.3; % Parameters of map
    xhenon(k,1)=1-ahen*xhenon(k-1,1)^2+bhen*yhenon(k-1,1);
    yhenon(k,1)=xhenon(k-1,1);
    
    % Tinkerbell map
    ati=0.9; bti=-0.6; cti=2; dti=0.5;% Parameters of map
    xtin(k,1)=xtin(k-1,1)^2-ytin(k-1,1)^2+ati*xtin(k-1,1)+bti*ytin(k-1,1);
    ytin(k,1)=2*xtin(k-1,1)*ytin(k-1,1)+cti*xtin(k-1,1)+dti*ytin(k-1,1);
    
    % Burgers' map
    aber=0.75; bber=1.75; % Parameters of map
    xber(k,1)=0.75*xber(k-1,1)-yber(k-1,1)^2;
    yber(k,1)=1.75*yber(k-1,1)+xber(k-1,1)*yber(k-1,1);
    
    % Logistic map
    Alog=4; % Parameter of map
    xlog(k,1)=Alog*xlog(k-1,1)*(1-xlog(k-1,1));
    
    % Ricker's map
    Aexp=20; %Parameter of map
    xexp(k,1)=Aexp*xexp(k-1,1)*(exp(-xexp(k-1,1)));
    
    % Cubic map
    Acub=3; % Parameter of map
    xlogcub(k,1)=3*xlogcub(k-1,1)*(1-(xlogcub(k-1,1))^2);
    
    % Sin map
    Asin=1; % Parameter of map
    xsin(k,1)=sin(pi*xsin(k-1,1));
    
end



%___________________________GENRATING NOISY DATA___________________________

Noislev=0.1; % 10 percent noise level. One can increase or decrease noise
% level simply by changing Noise level. Note that this noise is
% observational noise, for inducing system noise, one should add the noise
% inside of the loop.


%Logistic map
xlognoise=xlog/std(xlog)+normrnd(0,Noislev,N,1);

%Richer's map
xexpnoise=xexp/std(xexp)+normrnd(0,Noislev,N,1);

%Cubic map
xcubnoise=xlogcub/std(xlogcub)+normrnd(0,Noislev,N,1);

%Sin map
xsinnoise=xsin/std(xsin)+normrnd(0,Noislev,N,1);

%Gingerbeardman map
xginnoise=xgin/std(xgin)+normrnd(0,Noislev,N,1);
yginnoise=ygin/std(ygin)+normrnd(0,Noislev,N,1);

%Henon map
xhenonnoise=xhenon/std(xhenon)+normrnd(0,Noislev,N,1);
yhenonnoise=yhenon/std(yhenon)+normrnd(0,Noislev,N,1);

%Tinkerbell map
xtinnoise=xtin/std(xtin)+normrnd(0,Noislev,N,1);
ytinnoise=ytin/std(ytin)+normrnd(0,Noislev,N,1);

%Burgers' map
xbernoise=xber/std(xber)+normrnd(0,Noislev,N,1);
ybernoise=yber/std(yber)+normrnd(0,Noislev,N,1);


%______________________________PLOTS: Noisy data___________________________

% Plots of 1D maps are x vs x(-1) plot
figure 
plot(xlognoise(1:end-1),xlognoise(2:end),'.') 
title('Logistic map: Noisy data')

figure 
plot(xexpnoise(1:end-1),xexpnoise(2:end),'.') 
title('Rickers map: Noisy Data')

figure 
plot(xcubnoise(1:end-1),xcubnoise(2:end),'.') 
title(' Cubic map:Noisy data')

figure 
plot(xsinnoise(1:end-1),xsinnoise(2:end),'.') 
title(' Sin map: Noisy data')

% Plots of 2d maps are xy plot
figure 
plot(xginnoise,yginnoise,'.') 
title('Gingerbreadman map: Noisy data')

figure 
plot(xhenonnoise,yhenonnoise,'.') 
title('Henon map: Noisy data')

figure 
plot(xtinnoise,ytinnoise,'.') 
title('Tinkerbell map: Noisy data')

figure 
plot(xbernoise,ybernoise,'.') 
title('Burgers map: Noisy data')


%______________________________PLOTS: Clean data___________________________

% Plots of 1D maps are x vs x(-1) plot
figure 
plot(xlog(1:end-1),xlog(2:end),'.') 
title('Logistic map')

figure 
plot(xexp(1:end-1),xexp(2:end),'.') 
title('Rickers map')

figure 
plot(xlogcub(1:end-1),xlogcub(2:end),'.') 
title(' Cubic map')

figure 
plot(xsin(1:end-1),xsin(2:end),'.') 
title(' Sin map')

% Plots of 2d maps are xy plot
figure 
plot(xgin,ygin,'.') 
title('Gingerbreadman map')

figure 
plot(xhenon,yhenon,'.') 
title('Henon map')

figure 
plot(xtin,ytin,'.') 
title('Tinkerbell map')

figure 
plot(xber,yber,'.') 
title('Burgers map')
%_______________________________END________________________________________



