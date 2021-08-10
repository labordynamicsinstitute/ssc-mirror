function Lyap=lyapexpan(y,dt)
%__________________________________________________________________________
% This M-file calculates Lyapunov exponents with Taylor expansion.
 
% Inputs:
%  - y, a time series in vertical vector form.(e.g., stock prices)
%  - dt is the time interval between observations. It is supposed to be 1 for
%  maps(Logistics, Henon,...) and 0.01,0.02 or any value per second
%  for flows(Lorenz, Rossler,...). If you do not have any information
%  about this parameter, let dt=1.
 
% Outputs:
%  - Lyap: Lyapunov exponents.
 
% Ref: 
% -Lai,D. and G.Chen(1998)Statistical Analysis of Lyapunov Exponents 
%  from Time Series: A Jacobian Approach, Mathl. Comput. Modelling Vol. 27,
%  No. 7, pp. 1-9.
% -Eckmann, J. P., and D. Ruelle (1985). Ergodic Theory of Strange 
%  Attractors. Review of Modern Physics,57, pp. 617-656.
% -Brown, R., P. Bryant, and H. D. I. Abarbanel(1991),Computing the Lyapunov 
%  spectrum of a dynamical system from an observed time series,Phys. Rev. A 
%  43. 



% -Sprott, J. C. (2003). Chaos and Time Series Analysis. Oxford University
% Press.
 
% Copyright(c) Shapour Mohammadi, University of Tehran, 2009. This is a
% Revised Version, 2020.
% shmohammadi@gmail.com, shmohmad@ut.ac.ir.
 
% Keywords: Lyapunov Exponents, Chaos, Time Series, Taylor Expansion,
% Jacobian Method.
%__________________________________________________________________________


warning off

tic
y=y(:);
[nyr,~]=size(y);
[m,~]=fnn(y,10);
maxlag=m;
%___________________Determination of Embeding Lag: tau_____________________

% Autocorrelation 
ACF=autocorr(y,floor(nyr/4)+1);
IndACF=find(ACF<=1-exp(-1));
tau0=IndACF(1,1)-1;
tau=max(round(tau0/max((maxlag-1),1)),1);

if tau==0
    tau=1;
end

ObsDimTay=2*floor(prod(([1:3]+maxlag)./[1:3]))+1;
yL=lagmatrix(y,(1:maxlag)*tau);
yL=yL(maxlag*tau+1:end,:);
y=y(maxlag*tau+1:end,1);
[n, ~]=size(yL);

%_________________ Regressors Up to degree 3_______________________________
Df=[];
for i=1:tau:n
    D0=pdist2(yL(i,:),yL);
    
    INDEX0=[D0' (1:length(D0))'];
    INDEX10=topkrows(INDEX0,ObsDimTay+1,'ascend');
    index=INDEX10(2:end,2);
%index=Id(i,2:end)';
 if length(index)==ObsDimTay
    Dy1=yL(index,:);  
    ys=y(index,1);
    [ryL, cyL]=size(Dy1);

X1=Dy1;
num1=0;
X2ij=[];
for i=1:cyL
     for j=i:cyL
      X2ij=[X2ij Dy1(:,i).*Dy1(:,j)];
      Indexij(num1+1,1)=i;
      Indexij(num1+1,2)=j;
      num1=num1+1;
     end 
end

num2=0;
X3ijk=[];
for i=1:cyL
     for j=i:cyL
         for k=j:cyL
           X3ijk=[X3ijk Dy1(:,i).*Dy1(:,j).*Dy1(:,k)];
           Indexijk(num2+1,1)=i;
           Indexijk(num2+1,2)=j;
           Indexijk(num2+1,3)=k;
           num2=num2+1;
         end 
     end
end


X=[ones(ryL,1) X1 X2ij X3ijk];

beta = (X'*X)\(X'*ys);
betaX1=beta(2:cyL+1);
betaX2ij=beta(cyL+2:cyL+1+num1);
betaX3ijk=beta(cyL+2+num1:cyL+1+num1+num2);

DF1f=kron(betaX1',ones(ryL,1));

for i=1:length(betaX2ij)
for j=1:cyL
    Dfcoefs2(i,j)=length(find(Indexij(i,:)==j));   
end
end


for i=1:length(betaX3ijk)
for j=1:cyL
    Dfcoefs3(i,j)=length(find(Indexijk(i,:)==j));  
end
end

YLj2=[];
for j=1:cyL
    Dfcoefs2j=ones(length(betaX2ij),cyL);
    Dfcoefs2j(:,j)=Dfcoefs2(:,j);
    Dfcoefs2jp=Dfcoefs2;
    Dfcoefs2jp(:,j)=max(0,Dfcoefs2(:,j)-1);
    DF2=zeros(ryL,1);
    for i=1:length(betaX2ij)
        for k=1:cyL
            YLj2(:,k)=(Dy1(:,k).^Dfcoefs2jp(i,k));
        end
        DF2=[DF2+betaX2ij(i,1)*Dfcoefs2j(i,j)*prod(YLj2,2)];
        
    end
    DF2f(:,j)=DF2;
    
    Dfcoefs3j=ones(length(betaX3ijk),cyL);
    Dfcoefs3j(:,j)=Dfcoefs3(:,j);
    Dfcoefs3jp=Dfcoefs3;
    Dfcoefs3jp(:,j)=max(0,Dfcoefs3(:,j)-1);
    
    YLj3=[];
    DF3=zeros(ryL,1);
    for i=1:length(betaX3ijk)
        for k=1:cyL
            YLj3(:,k)=(Dy1(:,k).^Dfcoefs3jp(i,k));
        end
        DF3=[DF3+betaX3ijk(i,1)*Dfcoefs3j(i,j)*prod(YLj3,2)];
        
    end
    DF3f(:,j)=DF3; 
end
end

Df0=DF1f+DF2f+DF3f;
Df=[Df;mean(Df0)];

end

%QR decomposition

Q0=eye(maxlag);
K=min(length(Df(:,1)),1000);

for j=1:100
     cnt=0;
     Lyap0=[];
     i0=randi(max(1,length(Df(:,1))-K));
for i=i0:K+i0-1       
        [Q,R]=qr([Df(i,:);eye(maxlag-1,maxlag)]*Q0);
        if sum(sum(isnan(R)))+sum(sum(isinf(R)))==0
             cnt=cnt+1;  
             Lyap0(cnt,:)=diag(real(log(abs(R))))';
             Q0=Q;
             LL(cnt,:)=(1/(tau*dt))*mean(Lyap0,1);
        end
end


k0=min(100,floor(length(Df(:,1))/5));
k=(1:K)';
w=1-cos(2*pi*(k-k0+0.5)/(K-k0));
W=kron(ones(1,cyL),w);

Lyap1(j,:)=(1/(tau*dt))*mean(Lyap0(k0+1:end,:).*W(k0+1:end,:),1);
end

Lyap=mean(Lyap1,1);


%_________________________________END______________________________________


function [embedm, fnn]=fnn(y,maxm)

% Usage: This function calculates the corrected false nearest neighbor.
 
% Inputs: 
%   y  is a  vertical vector of time series.
%   maxm: maximum value of embedding dimension.
 
% Output:
%   embedm: proper value for the embedding dimension.
%   fnn:false nearest neighbors.

% Copyright(c) Shapour Mohammadi, University of Tehran, 2009
% shmohammadi@gmail.com

% Revised for more accuracy in 2020,shmohmad@ut.ac.ir 

% Keywords: Embedding Dimension, Chaos Theory, Lyapunov Exponent, 
% False Nearest Neighbors.
 
% Ref:
% -Sprott, J. C. (2003). Chaos and Time Series Analysis. Oxford University
%  Press.

%__________________________________________________________________________
y=y(:);
[nyr,~]=size(y);
ACF=autocorr(y,floor(nyr/4)+1);
IndACF=find(ACF<=1-exp(-1));
tau0=IndACF(1,1)-1;
if tau0==0
    tau0=1;
end
RT=15;

%Embedding matrix
m=maxm+1;
 fnn0=zeros(m-1,1);
for k=1:m-1
    tau=max(round(tau0/max(k,1))-1,1);
    EM=lagmatrix(y,-(0:k)*tau);

%EM after nan elimination.
     EEM=EM(1:end-(1+(k-1)*tau),:);
     [rEEM, ~]=size(EEM);
     
     
     MdlKDT = KDTreeSearcher(EEM(:,1:k));
     index = knnsearch(MdlKDT,EEM(:,1:k),'K',2);
     Rm=sqrt(sum((EEM(index(:,1),1:k)-EEM(index(:,2),1:k)).^2,2));
     Rmp1=sqrt(sum((EEM(index(:,1),1:k+1)-EEM(index(:,2),1:k+1)).^2,2));
     fnn0(k,1)=sum((Rmp1./Rm)>RT);
     diviser(k,1)=rEEM-(1+k)*tau;
end

fnn=fnn0./diviser;
embedm=find(fnn<0.01);

if isempty(embedm) 
  embedm=maxm;
elseif embedm==0
  embedm=1;  
else
  embedm=embedm(1);
end
%_____________________________End__________________________________________
