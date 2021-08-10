function [TestPvalue,PvalIndvidCefs]=HarmMulticolinTst(X,y) 

%Description:
% This function tests harmful multicollinearity based on the difference
% between p-value of estimated coefficients of ordinary least squares and 
% generalized ridge regression estimators.
 
% Inputs:
% X is the design matrix or matrix of explanatory variables
% y is the dependent variable.
 
% Outputs:
% TestPvalue gives the level of significance. Lower p-value means a higher
% probability of harmful collinearity.
% PvalIndvidCefs gives the p-value of each variable in the regression. Again
% Lower p-value for a coefficient means a higher likelihood of harmful 
% collinearity for the variable.
 
% Related Functions:
% This function uses functions multicolinRidge and BrownCorrectMulticolin 
 
 
%Reference:
% 1- Mohammadi, Shapour.(2020) A test of harmful multicollinearity: 
%  A generalized ridge regression approach, Communications in Statistics-
%  Theory and Methods, Published online: 22 Apr 2020.  
%  https://doi.org/10.1080/03610926.2020.1754855
 
% Copyright, Shapour Mohammadi 2020. shmohmad@ut.ac.ir
%--------------------------------------------------------------------------

[T,K]=size(X);
K=K+1;

mX=X-kron(mean(X),ones(T,1));
[KI] =ridgeoptimumMlticolin(mX,y-mean(y));
[Results]=multicolinRidge(y,X,KI);


%getting p-values for ordinary least squares t-statistic(s)
pvalols=2*(1-tcdf(abs(Results(:,3)),T-K));

tridg=Results(:,4);
ZBrowndata=X;

absstandrdt0=abs(Results(:,3));
absstandrdt=absstandrdt0./max(absstandrdt0);
absstandrdtindx=find(absstandrdt<0.1);
TRIDG(:,1)=tridg/(1+(length(absstandrdtindx)/(K-1-length(absstandrdtindx))));
tolsforridge=Results(:,3);
TRIDG(absstandrdtindx)=tolsforridge(absstandrdtindx);

pvalridg=2*(1-tcdf(abs(TRIDG),T-K));

% Do Brown correction for dependent data   
[Brc,Bdf]=BrownCorrectMlticolin(ZBrowndata);

%Brown correction in the degree of freedom of Chi2 for fisher test
if Bdf>=2*(K-1)
Bdf=2*(K-1);
Brc=1;
end

chisqridgepvales=sum(-2*(log(pvalridg)));
chisqolspvals=sum(-2*(log(pvalols)));
Pvalridgepvals=1-chi2cdf(chisqridgepvales/Brc,Bdf);
Pvalolspvals=1-chi2cdf(chisqolspvals/Brc,Bdf);


if Pvalridgepvals/Pvalolspvals<1
PvalchisqBrownridge=1-chi2cdf(-2*log(Pvalridgepvals/Pvalolspvals),2);
TestResult=PvalchisqBrownridge;
else
    TestResult=1;
end


% Harmfule multicollinearity in 5 percent Level.

PvalOLSFinal5(pvalols>0.05)=1;
PvalOLSFinal5(pvalols<=.05)=0;
if sum(PvalOLSFinal5)>0
    TestPvalue=TestResult;
else
    TestPvalue='No Harmful Multicollinearity in 5 Percent Level';
end


%Individual tests
 PvalIndvidCefs=1-chi2cdf(-2*log(pvalridg./pvalols),2);    
 
 
 
