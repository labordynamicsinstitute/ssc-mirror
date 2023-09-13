function [alpha,beta,sigma,mu]=stableregkw(x,deltac)
%STABLEREGKW Kogon-Williams parameter estimates of a stable distribution.
%	[ALPHA,BETA,SIGMA,MU]=STABLEREGKW(X) returns the estimated 
%	(regression method, Kogon-Williams implementation) parameters 
%	ALPHA, BETA, SIGMA and MU of a stable distribution vector X.
%	[ALPHA,BETA,SIGMA,MU]=STABLEREGKW(X,DELTAC) additionally allows to 
%   specify a vector of parameters DELTAC used in the regression for beta 
%   and mu. Default value is: DELTAC=0:99.
%
%   Sample use:
%       >> r = stablernd(1.5,0.5,1,0,1000,1);
%       >> [alpha,beta,sigma,mu] = stableregkw(r)
%
%  References:
%	[1] S.M.Kogon, D.B.Williams (1998) "Characteristic Function Based 
%	Estimation of Stable Distribution Parameters", in "A Practical Guide
%	to Heavy Tails: Statistical Techniques and Applications", R.J.Adler,
%	R.E.Feldman, M.Taqqu eds., Birkhauser, Boston, 311-335.
%   [2] S.Borak, A.Misiorek, R.Weron (2010) Models for Heavy-tailed Asset 
%   Returns, see http://ideas.repec.org/p/pra/mprapa/25494.html
%   {Chapter prepared for the 2nd edition of Statistical Tools for Finance 
%   and Insurance, P.Cizek, W.Härdle, R.Weron (eds.), Springer-Verlag, 
%   forthcoming in 2011.} 

%   Written by Szymon Borak and Rafal Weron (2002.12.04)
%   Revised by Rafal Weron (2010.04.26, 2010.20.08)
%   Copyright (c) 2002-2010 by Rafal Weron

% Initialize input parameters with default values
if nargin<2, delc = 0:99; else delc = deltac; end;

[xrow,xcol] = size(x);
if xrow==1,
    x = x';
    xrow = xcol;
    xcol = 1;
end;

% Compute initial parameter estimates using McCulloch's method
[alpha,beta,sigma,mu] = stablecull(x);

% Convert to S0 parametrization (see [2])
mu = mu + beta .*sigma.*tan(0.5*pi*alpha); 
x = (x-ones(xrow,1)*mu)./(ones(xrow,1)*sigma);

% Run regression
for n = 1:xcol,
    X = x(:,n);
    c1 = 0;
    K = 10;
    t = 0.1:0.9/(K-1):1;
    u = t;
    w = log(abs(t));
    w1 = w-mean(w);
    y = [];
    for tt=t,
        y = [y mean(exp(i*tt*X))];
    end;
    y = log(-2*log(abs(y)));
    alpha1 = (sum(w1.*(y-mean(y))))/sum(w1.*w1);
    c1 = (0.5*exp(mean(y-alpha1*w)))^(1/alpha1);
    X = X/c1;
    sinXu = [];
    cosXu = [];
    for uu = u,
        uuX = uu*X;
        sinXu = [sinXu sum(sin(uuX))];
        cosXu = [cosXu sum(cos(uuX))];
    end;
    testcos = ((1+0*(delc'))*cosXu).*cos(delc'*u)+((1+0*(delc'))*sinXu).*sin(delc'*u);
    testcos = sum(abs(diff(sign(testcos'))));
    
    deltac = delc(min(find(testcos==0)));
    if length(deltac)==0, 
        warning('Unable to find DELTAc'); 
    end;
    X = X-deltac;
    z = atan((sinXu*cos(deltac)-cosXu*sin(deltac))./(cosXu*cos(deltac)+sinXu*sin(deltac)));
    y = (c1^alpha1)*tan(pi*alpha1/2)*sign(u).*(u.^alpha1);
    delta2 = (sum(y.*y)*sum(u.*z)-sum(u.*y)*sum(z.*y))/(sum(u.*u)*sum(y.*y)-(sum(u.*y))^2);
    beta2 = (sum(u.*u)*sum(y.*z)-sum(u.*y)*sum(u.*z))/(sum(u.*u)*sum(y.*y)-(sum(u.*y))^2);
    sigma(n) = sigma(n)*c1;
    mu(n) = mu(n)+deltac*sigma(n);
    alpha(n) = alpha1;
    beta(n) = beta2;
    mu = mu(n)+sigma(n)*delta2;
end;
mu = mu + beta .*sigma.*tan(0.5*pi*alpha); 

% Correct estimates for out of range values
alpha(alpha<=0) = 10^(-10)+0*alpha(alpha<=0);
alpha(alpha>2) = 2+0*alpha(alpha>2);
sigma(sigma<=0) = 10^(-10)+0*sigma(sigma<=0);
beta(beta<-1) = -1+0*beta(beta<-1);
beta(beta>1) = 1+0*beta(beta>1);
  
