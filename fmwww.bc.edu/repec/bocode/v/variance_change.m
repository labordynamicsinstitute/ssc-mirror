
% This routine estimates the common break point (variance change)  in panel data.
% The method and theory are explained in
% Bai, J. (2010) "Common breaks in means and variances for panel data"  
% Journal of Econometrics 157 (1), 78-92.
% The code is written by Yutang Shi (August 2017)

% Data set: y, T by N matrix
% T: the number of time periods (time dimension)
% N: the number of series (cross-section dimension)

clear;
r=10;                      % number of repetitions
NN=[1,10,20,100];            % N=1,10,20,100
T=30;                        % T=30
Case=4;                      % number of T and N combinations
k0=10;                        % true break point
khat=zeros(r,Case);          % estimated change point for each simulation and case
for kk=1:Case;
    N=NN(kk);                % N for each case
for i=1:r;
% data generating process
    y1=repmat(randn(1,N),k0,1)+sqrt(2)*randn(k0,N);   
    % pre-break data, error - N(0,2), mean - N(0,1)
    y2=repmat(randn(1,N),T-k0,1)+sqrt(4)*randn(T-k0,N); 
    % post-break data, error - N(0,4), mean - N(0,1)
    y=[y1;y2];    % whole data, matrix of y_it
% data generating process done
%
% If you have the data y (T by N), you only need the program below.

% Estimating the break point by minimizing the negative Quasi-Maximum 
% likelihood function (QML)
QML=zeros(T,1);     % QML objective function value for each replication
for k=1:T-1;          % k=1,2,...,T-1. 
    sigma1=mean(bsxfun(@minus,y(1:k,:),mean(y(1:k,:))).^2); 
    sigma2=mean(bsxfun(@minus,y(k+1:T,:),mean(y(k+1:T,:))).^2);
    QML(k)=k*sum(log(sigma1))+(T-k)*sum(log(sigma2));
    % QML - QML objective function
end
b=QML;
b(b==0)=inf;
b(b==-inf)=inf;
khat(i,kk)=find(b==min(b));   % change point, which k minimizes QML
% estimating the break point done
end
end

khat  % display the estimated break point
