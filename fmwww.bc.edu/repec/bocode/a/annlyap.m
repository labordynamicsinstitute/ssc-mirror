function [Lyap,SIC,netopt]=annlyap(y,maxlag,nhiden)
%__________________________________________________________________________
% This M-file calculates Lyapunov exponents with minimum RMSE neural 
%  network.

%   
% Inputs:
%   - y , a time series in vertical vector form.(e.g. stock prices)
%   - maxlag ,maximum lag that should be entered in model.(e.g. 2)
%   - nhiden, number of hidden layer units.(e.g. 5)
%     NOTE: Higher number of Hidden unites and higher lags needs longer
%     time to execute the code.
% Outputs:
%   - Lyap, Lyapunov exponent.
%   - SIC, Shewarz beysian information criteria.
%   - netopt , the NET with minimum mean squares error.
 
 % Ref: 
 % - Lai, D. and G. Chen(1998) Statistical Analysis of  Lyapunov Exponents 
 %   from Time Series: A    Jacobian Approach, Math. Comput. Modeling Vol.
 %   27, No. 7, pp. 1-9.

 % - Eckmann, J. P. and D. Ruelle (1985). Ergodic Theory of Strange 
 %   Attractors. Review of Modern Physics,57, pp. 617-656.

 % - Sprott, J. C. (2003). Chaos and Time Series Analysis. Oxford 
 %   University Press.
 
 % - Gencay  R. and W. D. Dechert An algorithm for the n Lyapunov
 %   exponents of an n-dimensional unknown dynamical system Physica D 59
 %   (1992) 142-157.

 % - Shintani M. and  O. Linton (2004). Nonparametric neural network 
 %   estimation of Lyapunov exponents and a direct test for chaos, Journal 
 %   of Econometrics 120 (2004) 1 – 33

 
% Copyright(c) Shapour Mohammadi, University of Tehran, 2008
%  shmohammadi@gmail.com
 
% Keywords: Lyapunov Exponents, Chaos, Time Series, Neural Networks,
%  Jaccobian Method.


%___________________________Defining lags for y____________________________
y=y(:);
y=y';
trset=100;
[nyr,nyc]=size(y);
trset=floor(nyc*trset/100);
yL=lagmatrix(y',1:maxlag)';
lr = maxlinlr(yL(:,maxlag+1:end),'bias');


%______ Networks with different number of hiden units and input lags_______

warning off

PRL=min(yL')';
PRU=max(yL')';

for ner=1:nhiden
for lag=1:maxlag
net(ner,lag)={newff([PRL(1:lag) PRU(1:lag)],[ner 1],{'logsig',...
    'purelin'},'trainlm' )};
net{ner,lag}.trainParam.lr = lr;
net{ner,lag}.trainParam.lr_inc = 1.05;
net{ner,lag}.trainParam.lr_dec = .7;
net{ner,lag}.trainparam.epochs=500;
net{ner,lag}.trainparam.show=100;
net{ner,lag}.trainparam.goal=1e-9;
net{ner,lag}.trainParam.showWindow = false;
net{ner,lag}.trainParam.showCommandLine = false;

end
end

%________________________________Training nets_____________________________

for ner=1:nhiden
for lag=1:maxlag
   
    
[TRAINEDNET{ner,lag},tr]=train(net{ner,lag},yL(1:lag,lag+1:trset),y(1,...
    lag+1:trset));

%RMSE calculation
yhat=sim(TRAINEDNET{ner,lag},yL(1:lag,lag+1:nyc));

k=nyc-(ner*lag+ner+1);
sigma2hat=sum((yhat-y(1,lag+1:nyc)).^2)/(nyc-k);
sic=log(sigma2hat)+k*log(nyc)/nyc;
SIC(ner,lag)=sic;

end
end
for lag=1:maxlag
for ner=1:nhiden
if SIC(ner,lag)==min(min(SIC))
optner=ner;
optlag=lag;
end
end
end

%______________________________Calculating Derivatives_____________________

netopt=TRAINEDNET{optner,optlag};
IW=netopt.IW{1,1};
LW=netopt.LW{2,1};
bW=netopt.b{1,1};

for i=1:optlag  
    D(:,i)=IW(:,i).*LW';
end

yL=yL';
oyL=yL(1+lag:nyc,1:optlag);
[ryL cyL]=size(oyL);
WW=[bW IW];

for j=1:optner
neurval1(:,j)=([ones(ryL,1) oyL]*WW(j,:)');
neurval(:,j)=exp(-neurval1(:,j))./((1+exp(-neurval1(:,j))).^2);
end

for i=1:optlag
Df(:,i)=(neurval)*D(:,i);
end


%__________________________QR decomposition________________________________
tic
M=floor(ryL/20);
Lyap=[Df(1,:);eye(optlag-1,optlag)]-[Df(1,:);eye(optlag-1,optlag)];
for bl=1:20
LAMBDA=[Df(1,:);eye(optlag-1,optlag)]-[Df(1,:);eye(optlag-1,optlag)];

Q0=eye(optlag);
for i=(bl-1)*M+1:bl*M;
    [Q,R]=qr([Df(i,:);eye(optlag-1,optlag)]*Q0);
    LAMBDA1=logm(R);
    LAMBDA=LAMBDA+real(LAMBDA1);
    Q0=Q;
end
Lyap=LAMBDA+Lyap;

end
Lyap=Lyap/(M*20);
toc
%____________________________________END___________________________________
