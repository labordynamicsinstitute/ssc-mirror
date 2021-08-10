
% This routine estimates the common break point (mean change)  in panel data.
% The method and theory are explained in
% Bai, J. (2010) "Common breaks in means and variances for panel data"  
% Journal of Econometrics 157 (1), 78-92.
% The code is written by Yutang Shi (August 2017)

% Data set: y, T by N matrix
% T: the number of time periods (time dimension)
% N: the number of series (cross-section dimension)

clear;

r=100;                      % number of repetitions
NN=[1,10,20,100];            % N=1,10,20,100
T=10;                        % T=10
Case=4;                      % number of T and N combinations
k0=5;                        % true break point
khat=zeros(r,Case);          % estimated change point for each simulation and case
for kk=1:Case;
    N=NN(kk);                % N for each case
for i=1:r;
% data generating process
    u1=randn(1,N);         % pre-break mean, u1 -- N(0,1)
    u2=u1-2+4*rand(1,N);   % post-break mean, u2 -- u1+U(-2,2)
    y=[repmat(u1,k0,1);repmat(u2,T-k0,1)]+randn(T,N); % whole data, matrix of y_it
% data generating process done

% If you have the data y (T by N), you only need the program below.
SSR=zeros(T,1);         % total sum of square residuals for each replication
% estimate break point
for k=1:T-1;          % k=1,2,...,T-1. 
    SSR(k)=sum(sum(bsxfun(@minus,y(1:k,:),mean(y(1:k,:))).^2)+sum(bsxfun(@minus,y(k+1:T,:),mean(y(k+1:T,:))).^2));
   % SSR - total sum of square residuals
end
SSR(T)=sum(sum(bsxfun(@minus,y,mean(y)).^2));  
% when k=T, SSR=\sum_i=1^N [1/T\sum_t=1^T(y_it-1/T\sum_t=1^Ty_it)^2]
khat(i,kk)=find(SSR==min(SSR));   % change point, which k minimizes SSR
%estimate break point done

end
end

khat  % display the estimated break point


    
