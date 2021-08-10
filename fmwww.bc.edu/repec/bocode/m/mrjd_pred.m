function [M,I] = mrjd_pred(x0, P, L, ntraj)
%MRJD_PRED Makes a one-step ahead prediction of a MRJD model.
%   M = MRJD_PRED(X0,P) returns a one-step ahead point forecast of 
%   the Mean Reverting Jump Diffusion (MRJD) model:
%     dX = (alpha - beta*X)*dt + sigma*dB + N(mu,gamma)*dN(lambda) 
%	for an initial value X0 and a parameter vector 
%   P = [ALPHA,BETA,SIGMA,MU,GAMMA,LAMBDA]. The timestep dt is set to 1.
%   [M,I] = MRJD_PRED(X0,P,L) additionally returns the double-sided
%   prediction intervals I for a set of confidence levels L (default 
%   L = [.5 .9 .99]). [M,I] = MRJD_PRED(X0,P,L,NTRAJ) returns values based 
%   on Monte Carlo simulations with NTRAJ trajectories (instead of using 
%   analytic results).
%
%   Sample use:
%       >> [m_an,i_an] = mrjd_pred(5,[.5,.1,.2,4,1,.01],[.5 .9 .99]);
%       >> [m_mc,i_mc] = mrjd_pred(5,[.5,.1,.2,4,1,.01],[.5 .9 .99],1000);
%       >> [[m_an;i_an] [m_mc;i_mc]] 
%
%   Reference(s):
%   [1] C.Ball, W.N.Torous (1983) A Simplified Jump Process for Common 
%   Stock Returns, J. Financial and Quantitative Analysis 18, 53–65.
%   [2] R.Weron, A.Misiorek (2008) Forecasting spot electricity prices: 
%   A comparison of parametric and semiparametric time series models, 
%   International Journal of Forecasting 24, 744-763.

%   Written by Rafal Weron (2007.11.23)
%   Revised by Rafal Weron (2010.11.08)
%   Copyright (c) 2007-2010 by Rafal Weron

% Initialize output matrix
if (nargin<3) %| (length(L)==0),
    L = [.5 .9 .99];
end
q = reshape([(1-L)/2; 1-(1-L)/2], length(L)*2, 1);
q = q(:);
I = zeros(size(q));

alpha = P(1); beta = P(2); sigma = P(3); mu = P(4); gamma = P(5); lambda = P(6);

if nargin<4,
    % Analytical (+approximation) forecasts
    M = lambda*(x0 + alpha - beta*x0 + mu) + (1-lambda)*(x0 + alpha - beta*x0);
    for j=1:length(q)
        I(j) = fzero(@(x) mrjd_cdf(x,x0,P,q(j)),x0,P);
    end
else
    % Monte Carlo forecasts
    x = mrjd_sim(ntraj, 1, x0, P);
    M = mean(x(:,2));
    I = quantile(x(:,2),q);
end

%%%%%%%%%%%%% INTERNALLY USED ROUTINE %%%%%%%%%%%%%

function res = mrjd_cdf(x, x0, P, q)
%MRJD_CDF Computes (CDF-Q) of a MRJD point forecast.
%   RES = MRJD_CDF(X,X0,P,Q) returns (CDF(X)-Q) at point X of a one-step   
%   ahead point forecast of the Mean Reverting Jump Diffusion (MRJD) model:
%     dX = (alpha - beta*X)*dt + sigma*dB + N(mu,gamma)*dN(lambda) 
%	for an initial value X0 and a parameter vector 
%   P = [ALPHA,BETA,SIGMA,MU,GAMMA,LAMBDA]. The timestep dt is set to 1.

alpha = P(1); beta = P(2); sigma = P(3); mu = P(4); gamma = P(5); lambda = P(6);
res = lambda*normcdf(x, x0 + alpha - beta*x0 + mu, sqrt(gamma^2+sigma^2)) ...
    + (1-lambda)*normcdf(x, x0 + alpha - beta*x0, sigma) - q;