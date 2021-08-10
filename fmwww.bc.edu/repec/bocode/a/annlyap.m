function [Lyap]=annlyap(y,dt)
%__________________________________________________________________________
% This M-file calculates the spectrum of Lyapunov exponents with minimum RMSE 
% neural network. It uses "5+2*ceil(log(length(y)))-2" and
% "5+2*ceil(log(length(y)))+2" for determination minimum and maximum number 
% of hidden units(neurons) in the neural networks, respectively. 
% The code tries five neural networks with neurons ranging from the minimum
% number to the maximum number of neurons and the neural network with minimum
% The code selects the minimum RMSE neural network to calculate the spectrum 
%  of Lyapunov exponents. The number of embedding dimension and time lag is 
% chosen automatically based on false nearest neighbors and autocorrelation.  
 
  
% Inputs:
%  - y, a time series in vertical vector form. (e.g., stock prices)
%  - dt is the time interval between observations. It is supposed to be 1 
% for maps(Logistics, Henon, etc.) and 0.01,0.02 or any value for flows
% (Lorenz, Rossler, etc.). If you do not have any information about this
% parameter, let dt=1.
 
 
% Outputs:
%  - Lyap, Lyapunov exponents.
 
 
 % Ref: 
 % - Lai, D. and G. Chen(1998) Statistical Analysis of Lyapunov Exponents 
 %  from Time Series: A  Jacobian Approach, Math. Comput. Modeling Vol.
 %  27, No. 7, pp. 1-9.
 
 % - Eckmann, J. P. and D. Ruelle (1985). Ergodic Theory of Strange 
 %  Attractors. Review of Modern Physics,57, pp. 617-656.
 
 % - Sprott, J. C. (2003). Chaos and Time Series Analysis. Oxford 
 %  University Press.
 
 % - Gencay R. and W. D. Dechert An algorithm for the n Lyapunov
 %  exponents of an n-dimensional unknown dynamical system Physica D 59
 %  (1992) 142-157.
 
 % - Shintani M. and O. Linton (2004). Nonparametric neural network 
 %  estimation of Lyapunov exponents and a direct test for chaos, Journal 
 %  of Econometrics 120 (2004) 1 ? 33
 
 
% Copyright(c) Shapour Mohammadi, University of Tehran, 2008, This is a
% Revised Version, 2020.
% shmohammadi@gmail.com, shmohmad@ut.ac.ir
 
% Keywords: Lyapunov Exponents, Chaos, Time Series, Neural Networks,
% Jacobian Method.
 
%______________Lag Selection Based on Autocorellation___________________
tic

maxm=10;
[embedm, ~]=fnn(y,maxm);

y=y(:);
y=y';
y=mapminmax(y);
[~,nyc]=size(y);
ACF=autocorr(y,floor(nyc/4)+1);
IndACF=find(ACF<=1-exp(-1));
tau0=IndACF(1,1);

%______ Networks with different number of hiden units and input lags_______

warning off
minner=5+5*ceil(log(length(y)))-2;
maxner=5+5*ceil(log(length(y)))+2;
cntner=0;
for ner=minner:maxner
      cntner=cntner+1;
             net0=feedforwardnet(ner);
             net0.trainParam.showWindow = false;
             net0.trainParam.showCommandLine = false;    
             net(cntner,1)={net0};
end             

%________________________________Training nets_____________________________

    y0=y;
    tau=max(round(tau0/max(embedm-1,1))-1,1);
    yL0=lagmatrix(y0',(1:embedm)*tau)';
    yL=yL0(:,1+tau*(embedm):end);
    y0=y0(1+tau*(embedm):end);
    [~,ny0c]=size(y0);
    
   for ner=1:cntner 
         [TRAINEDNET{ner,1}]=train(net{ner,1},yL,y0);
         
         %RMSE calculation
         yhat=sim(TRAINEDNET{ner,1},yL);
         k=(minner-1+ner)*embedm+(minner-1+ner)+1;
         sigma2hat=sum((yhat-y0).^2)/(ny0c-k);
         sic=log(sigma2hat)+k*log(ny0c)/ny0c;
         SIC(ner,1)=sic;
   end

[rSIC,~]=size(SIC);


if rSIC>1 
optnerind=find(SIC==min(SIC));
else
    optnerind=1;
end
optner=optnerind;


%______________________________Calculating Derivatives_____________________

netopt=TRAINEDNET{optner,1};
oyL=yL';
[ryL, ~]=size(oyL);
[oyLnorm,~]=mapminmax(oyL');
oyLnorm=oyLnorm';
IW=netopt.IW{1,1};
LW21=netopt.LW{2,1};
bW11=netopt.b{1,1};

WW11=[bW11 IW];
nj=([ones(ryL,1) oyLnorm]*WW11');

%Derivatives of Hyperbolic Tangent function
Dnj=4*(exp(-2*nj)).*(1+exp(-2*nj)).^(-2);

  for i=1:embedm  
           Df(:,i)=(Dnj*(IW(:,i).*LW21'));
  end  

%__________________________QR decomposition________________________________

cnt=0;
Q0=eye(embedm);

for i=1:tau:length(Df(:,1))              
        [Q,R]=qr([Df(i,:);eye(embedm-1,embedm)]*Q0);
        if sum(sum(isnan(R)))+sum(sum(isinf(R)))==0
             cnt=cnt+1;  
             Lyap0(cnt,:)=diag(real(log(abs(R))))';
             Q0=Q;
             LL(cnt,:)=(1/(tau*dt))*mean(Lyap0,1);
        end
end


Lyap=(1/(tau*dt))*mean(Lyap0(max(floor(cnt/10),1):end,:),1);

 
toc
%____________________________________END___________________________________

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

