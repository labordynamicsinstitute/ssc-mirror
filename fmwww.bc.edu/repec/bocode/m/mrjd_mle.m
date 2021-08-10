function [alpha,beta,sigma,mu,gamma,lambda] = mrjd_mle(x)
%MRJD_MLE Estimate parameters of a Mean-Reverting Jump-Diffusion process.
%   [ALPHA,BETA,SIGMA,MU,GAMMA,LAMBDA] = MRJD_MLE(X) returns maximum  
%   likelihood estimates of the parameters of a MRJD process:
%     dX = (alpha - beta*X)*dt + sigma*dB + N(mu,gamma)*dN(lambda) 
%   MRJD_MLE uses the method of Ball and Torous (1983) and assumes that 
%   the arrival rate for two jumps within one period (dt) is negligible. 
%   Then the Poisson process with intensity lambda is well approximated 
%   by a simple binary probability q = lambda*dt of a jump (and (1-q) 
%   for no jump).
%
%   Sample use:
%       >> r = mrjd_sim(1,1000,5,[.5,.1,.2,4,1,.01]);
%       >> [alpha,beta,sigma,mu,gamma,lambda] = mrjd_mle(r)
%
%   Reference(s):
%   [1] C.Ball, W.N.Torous (1983) A Simplified Jump Process for Common 
%   Stock Returns, J. Financial and Quantitative Analysis 18, 53–65.
%   [2] R.Weron, A.Misiorek (2008) Forecasting spot electricity prices: 
%   A comparison of parametric and semiparametric time series models, 
%   International Journal of Forecasting 24, 744-763.

%   Written by Rafal Weron (2007.11.23)
%   Revised by Rafal Weron (2008.05.09, 2010.10.08)
%   Copyright (c) 2007-2010 by Rafal Weron

T = length(x);
x = x(:);

% Preliminary estimation of the MRD part
[alpha,beta,sigma] = mrd_mle(x);

% Preliminary estimation of the jump intensity
lx = logret(x);
stdlx = std(lx);
lambda = length(find(lx > 3*stdlx)) / T;

% Initial parameters vector
P0 = [alpha,beta,sigma,alpha/beta,1,lambda];

% Run optimization
[P,fval,exitflag,output] = fminsearch(@(P) mrjd_like(P,x),P0,optimset('MaxFunEvals',1e12));

alpha = P(1); beta = P(2); sigma = P(3); mu = P(4); gamma = P(5); lambda = P(6);

if lambda<(0.1/T), 
    lambda = 0; 
end

%%%%%%%%%%%%% INTERNALLY USED ROUTINE %%%%%%%%%%%%%

function logL = mrjd_like(P,x);
%MRJD_LIKE Likelihood function of a Mean-Reverting Jump-Diffusion process.
%   LOGL = MRJD_LIKE(P,X) returns the maximum of (the negative of) 
%   the log-likelihood of a MRJD
%     dX = (alpha - beta*X)*dt + sigma*dB + N(mu,gamma)*dN(lambda) 

T = length(x);
alpha = P(1); beta = P(2); sigma = P(3); mu = P(4); gamma = P(5); lambda = P(6);
% (Negative of) Log-likelihood
if (lambda<1) & (lambda>0) & (sigma>0) & (gamma>0) & (beta>0) & (alpha>0)
    logL = - sum( log( lambda*normpdf( (diff(x(1:T)) - (alpha - beta*x(1:T-1) + mu)), 0, sqrt(gamma^2+sigma^2) ) ...
         + (1-lambda)*normpdf( (diff(x(1:T)) - (alpha - beta*x(1:T-1))), 0, sigma ) ));
else
    logL = realmax;
end

%%%%%%%%%%%%% INTERNALLY USED ROUTINE %%%%%%%%%%%%%

function [alpha,beta,rho] = mrd_mle(x,dt)
%MRD_MLE Maximum likelihood estimates of a Mean-Reverting Diffusion process.
%   [ALPHA,BETA,RHO]=MRD_MLE(X,DELTA) returns parameters of a MRD process 
%   (a generalized Ornstein-Uhlenbeck type process or mean reverting 
%   Brownian motion): dX = (alpha - beta*X) * dt + rho * dB_t, with 
%   dt=DELTA (default: DELTA=1).

if nargin<2,
   dt = 1;
end;

N = length(x);
s = sum(x(1:N-1));
s2 = sum(x(1:N-1).*x(1:N-1));
sd = -sum(x(1:N-1).*diff(x));
alpha = (s2*(x(1)-x(N)) - s*sd) / (dt * (s*s - s2*(N-1)));
beta = ((x(1)-x(N)) + alpha*dt*(N-1)) / (dt*s);
rho = sqrt( sum((x(2:N) - (1-beta*dt)*x(1:N-1) - alpha*dt).^2) / (dt*(N-1)) );