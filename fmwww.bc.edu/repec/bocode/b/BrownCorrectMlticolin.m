function [Brc,Bdf]=BrownCorrectMlticolin(data)


%Description:
% This function does Brown correction for the dependence between p-values.
 
% Inputs:
% data: data set that is used for the computation of variables.
 
% Outputs:
% Brc: Brown statistics.
% Bdf: the degree of freedom for Brown statistic.
 
% Related Functions:
% This function is used by HarmMulticolinTst function.
 
 
%References:
% 1- Brown M.B. (1975) 400: a method for combining non-independent, 
%  one-sided tests of significance. Biometrics, 31, 987?992.
% 2- Mohammadi, Shapour.(2020) A test of harmful multicollinearity: 
%  A generalized ridge regression approach, Communications in Statistics-
%  Theory and Methods, Published online: 22 Apr 2020.  
%  https://doi.org/10.1080/03610926.2020.1754855
 
% Copyright, Shapour Mohammadi 2020. shmohmad@ut.ac.ir
%--------------------------------------------------------------------------

[rows,colmns]=size(data);

% Preallocation for better performance and memory use
ZBrownPvalue=zeros(rows,colmns);
 ind=zeros(rows,1);

% Normalization and getting p-values by MATLAB ecdf function
for i=1:colmns
 nx=normalize(data(:,i));
 [f, x]=ecdf(nx);
 f=f(2:end,1);x=x(2:end);
 
for j=1:length(nx)
    ind(j,1)=find(x==nx(j,1));
end

 ZBrownPvalue(:,i)=-2*log(f(ind));
end


% Brown(1975), pp. 988-989.
Brcov=cov(ZBrownPvalue);
mu=length(Brcov(:,1));
Exp= 2*mu;
covsum = sum(sum(Brcov))-trace(Brcov);
Var = 4.0*mu+covsum;
Brc = Var/(2*Exp);
Bdf =2*(Exp^2)/Var;

end