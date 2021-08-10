function [KI,fval] = ridgeoptimumMlticolin(X,y) 

% Description:
% This function determines generalized ridge parameters based minimization
% of the sum of the absolute value of t-statistics with the constraint that absolute
% value of ridge estimators of coefficients be less than the absolute value of
% OLS estimators.
 
% Inputs:
% X: design matrix or matrix of explanatory variables
% y: dependent variable.
 
% Outputs:
% K is generalized k factor for generalized ridge regression, and fvalu is 
% the minimum value for the function.
 
% Related Functions:
% This function is used by function HarmMulticolinTst.
 
 
%Reference:
% 1- Mohammadi, Shapour.(2020) A test of harmful multicollinearity: 
%  A generalized ridge regression approach, Communications in Statistics-
%  Theory and Methods, Published online: 22 Apr 2020.  
%  https://doi.org/10.1080/03610926.2020.1754855
 
% Copyright, Shapour Mohammadi 2020. shmohmad@ut.ac.ir
%--------------------------------------------------------------------------

warning('off','all');
[T,K]=size(X);

x0=sum(X.^2)';

ssmin=min(sum(X.^2));
ssmax=max(sum(X.^2));
options = optimoptions(@fminimax,'AbsoluteMaxObjectiveCount',K,'Display','off');
[KI,fval] = fminimax(@mohnestedfun,x0,[],[],[],[],(1/K)*ssmin*ones(K,1),K*ones(K,1)*ssmax,@mohnlconst,options);

% Nested function that computes the objective function     
    function fun = mohnestedfun(KI)
        KII=eye(K);
        for i=1:K
        KII(i,i)=KI(i);
        end
        beta=(X'*X)^(-1)*X'*y;
        KII2=(X'*X+KII)^(-1);
        e=y-X*beta;
        VC=(1/(T-(K+1)))*(e'*e)*KII2*(X'*X)*KII2;
        fun = -(KII2*X'*y)./sqrt(diag(VC));
    end

    function [c,ceq] =mohnlconst(KI)
              KII=eye(K);
        for i=1:K
        KII(i,i)=KI(i);
        end
        KII2=(X'*X+KII)^(-1);
        
     c = abs(KII2*X'*y)-abs((X'*X)^(-1)*X'*y);
    ceq = [];
    end

end