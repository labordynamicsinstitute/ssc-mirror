
function [WXf W]=forcascomb(Xf)

%__________________________________________________________________________
% The code combines forecasts of various e models based on minimization of 
% combined forecast. This algorithm uses a logic similar to portfolio 
% optimization 
 
% Inputs: 
%   Xf: matrix of forecasts by various methods. each column of the matrix
%   is the forecast of one model or method. fore examples if one forecasts
%   ten step ahead by model1 and model two Xf matrix is  a(10 by 2) matrix.
 
 
% Output:
%   WXf, combined forecast based on W weights.
%   W optimal weights based on Variance-Covariance Minimization of
%   forecasts.
 
% Keywords: Forecast combination, minimum variance combination,
% variance-Covariance method of combination.
 
 
% Ref:
%  Clement, M. P. and D. F. Hendry,(1998), Forecasting Economic Time Series 
%  Cambridge University Press.
 
 
% Copyright(c) Shapour Mohammadi, University of Tehran, 2009
% shmohammadi@gmail.com
%__________________________________________________________________________


H=cov(Xf);
[r c]=size(H);
f(1:r,1)=1;
Aeq(1,1:r)=1;
beq=1;
lb=zeros(r,1);
W = quadprog(2*H,0*f,[],[],Aeq,beq,lb,[]);
WXf=Xf*W;