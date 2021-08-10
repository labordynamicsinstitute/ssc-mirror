function [Results]=multicolinRidge(y,X,Kridg)

% Description:
% This function uses the output of another function named "mohridgeoptimum"
% determines ridge parameters based maximization of the sum of absolute value
% of t-statistics with the constraint that the absolute value of ridge estimators
% of coefficients be less than the absolute value of OLS estimators.
 
% Inputs:
% X: design matrix or matrix of explanatory variables.
% y: the dependent variable.
% Kridge: k factor for generalized ridge regression which is the output of
% ridgeoptimumMulticolin.
 
% Outputs:
% Results contains beta, betaridge, tstat, and tridge which are
% coefficients of OLS method, coefficients of GRR method, t-statistic(s) 
% of OLS and t-statistic(s) of GRR, respectively.
 
% Related Functions:
% Results of this function is used in HarmMulticolinTst function.
 
 
%Reference:
% 1- Mohammadi, Shapour.(2020) A test of harmful multicollinearity: 
%  A generalized ridge regression approach, Communications in Statistics-
%  Theory and Methods, Published online: 22 Apr 2020.  
%  https://doi.org/10.1080/03610926.2020.1754855 
% Copyright, Shapour Mohammadi 2020. shmohmad@ut.ac.ir
%--------------------------------------------------------------------------

[T,K]=size(X);
ybar=mean(y);
my=(y-ybar);
mX = mean(X);
Z = (X - mX);
ZZ=(Z'*Z)^(-1);

% OLS estimation.
beta=ZZ*(Z'*my);
Beta=[ybar-mX*beta;beta];
e=y-[ones(T,1) X]*Beta;
sigma2ols=e'*e/(T-(K+1));
VC=sigma2ols*ZZ;
tstat=beta./sqrt(diag(VC));

% Generalized ridge regression estimation.
Kridg=diag(Kridg); 
ZBR=(Z'*Z+Kridg)^(-1);
betaridge=ZBR*(Z'*my);
VCgridg=sigma2ols*ZBR*(Z'*Z)*ZBR;
tridg=betaridge./sqrt(diag(VCgridg));

Results=[beta,betaridge,tstat,tridg];
 
end
