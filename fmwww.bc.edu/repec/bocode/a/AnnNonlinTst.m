function [pval]=AnnNonlinTst(y)

% Description:
% nonlinearity test for univariate and multivariate time series. This Matlab
% code has been used in S. Mohammadi(2019).The test is a generalization of Lee,
% Granger and White(1993) test. In addition to generalization to multivariate
% time series, some modifications are made in Mohammadi(2019) for increasing
% the power of Lee, Granger, and White(1993)test in the case of a univariate
% time series.
 
 
% Input:
% y: a univariate(multivariate) time series in the form column
% vector(s)
 
% Output: 
% Probability value of the test. Reject linearity(H0) if pval is
% less than 5%(or any predetermined level of significance).


% References:

% 1-  Mohammadi S. Neural network for univariate and multivariate nonlinearity tests. 
%     Stat Anal Data Min: The ASA DataSci Journal. 2019.
%     13:50-70.https://doi.org/10.1002/sam.11441

% Copyright, Shapour Mohammadi 2020.shmohmad@ut.ac.ir
 
%--------------------------------------------------------------------------

warning('off')

% Find optimal lag.
T=length(y);
     aiccriter=zeros(5,1);
    for lag=1:5
        xlagmat=lagmatrix(y,1:lag);
        xlagmat=[ones(T-lag,1) xlagmat(lag+1:end,:)];
        [~,resmdl1,~]=moholsforann(y(lag+1:end,1),xlagmat);
        aiccriter(lag,1)=log((resmdl1'*resmdl1)/(T-lag))+2*lag/(T-lag);
    end
     optlag=find(aiccriter==min(aiccriter));
     x=lagmatrix(y,1:optlag);

%Change data to row vector for using neural networks.
[rowsx, columsx]=size(x);
if rowsx>columsx
    x0=[];
for i=1:columsx
      x0(i,:)=x(:,i);
end
x=x0;
end 

[rowsy, columsy]=size(y);
if rowsy>columsy
    y0=[];
for i=1:columsy
      y0(i,:)=y(:,i);
end 
y=y0;
end

index0=isnan(x(end,:));
index=find(index0==1);
if length(index)>0
maxindex=max(index)+1;
x=x(:,maxindex:end);
y=y(:,maxindex:end);
end

[rowsx, columsx]=size(x);
[rowsy,columsy]=size(y);

 [x,~]=mapminmax(x);
 [y,~]=mapminmax(y);


%Estimate a linear model and get residuals.
[~,resid]=moholsforann(y',[ones(columsy,1) x']);

% Number of hidden units(neurons).
nernum=10;

% Preallocation for neural networks weights.
bias1l=[];
bias2l=[];
bias1u=[];
bias2u=[];
IWtotal1l=[];
IWtotal1u=[];
LWtotal2l=[]; 
LWtotal2u=[];

%  Neural network architechture.
   net=feedforwardnet([nernum nernum],'trainlm');
   net.trainParam.epochs=1000;
   net.trainParam.show = NaN;
   net.trainParam.showWindow = false;
   net.trainParam.showCommandLine = false;
   
   NET(1:100,1)={net};
   
% Training 100 neural networks for obtaining support space of neural 
% network weights.   
parfor i=1:100
   
   net=train(NET{i,1},x,resid');
   bias1l=[bias1l min(net.b{1,1}')'];
   bias1u=[bias1u max(net.b{1,1}')'];
   bias2l=[bias2l min(net.b{2,1}')'];
   bias2u=[bias2u max(net.b{2,1}')'];
   
   IWtotal1l=[IWtotal1l; min(net.IW{1,1})]; 
   IWtotal1u=[IWtotal1u; max(net.IW{1,1})];
   LWtotal2l=[LWtotal2l; min(net.LW{2,1})];
   LWtotal2u=[LWtotal2u; max(net.LW{2,1})];  

   
end

% Lower and Upper bounds of neural networks weights based on formulae in
% page 7 of Mohammadi(2019)   
   gamal1=[min(bias1l);min(IWtotal1l)'];
   gamau1=[max(bias1u);max(IWtotal1u)'];
   gamal2=[min(bias2l);min(LWtotal2l)'];
   gamau2=[max(bias2u);max(LWtotal2u)']; 

   
   GAMAL1=kron(ones(1,nernum),gamal1);
   GAMAU1=kron(ones(1,nernum),gamau1);
   GAMAL2=kron(ones(1,nernum),gamal2);
   GAMAU2=kron(ones(1,nernum),gamau2); 
   
   GAMAL1(GAMAL1<0)=2*GAMAL1(GAMAL1<0);
   GAMAL1(GAMAL1>0)=0.0*GAMAL1(GAMAL1>0);
   GAMAU1(GAMAU1<0)=0.0*GAMAU1(GAMAU1<0);
   GAMAU1(GAMAU1>0)=2*GAMAU1(GAMAU1>0);
   
   GAMAL2(GAMAL2<0)=2*GAMAL2(GAMAL2<0);
   GAMAL2(GAMAL2>0)=0.0*GAMAL2(GAMAL2>0);
   GAMAU2(GAMAU2<0)=0.0*GAMAU2(GAMAU2<0);
   GAMAU2(GAMAU2>0)=2*GAMAU2(GAMAU2>0);
   
% Obtain phantom functions for nonlinearity test.   
parfor rr=1:1000
   
    
    gama=GAMAL1+(GAMAU1-GAMAL1).*rand(rowsx+1,nernum);
    ner=[ones(columsx,1) x']*gama;
    psigamma=2./(1+exp(-2*ner))-1;
    
    gama2=GAMAL2+(GAMAU2-GAMAL2).*rand(nernum+1,nernum);
    ner2=[ones(columsx,1) psigamma]*gama2;
    psigamma2=2./(1+exp(-2*ner2))-1;
    
    [~,score,~,~,Explned0] =pca([psigamma2]);
    
    Explned2=cumsum(Explned0);
    ndimindex2=find(Explned2>=(99-2*ceil(log(rowsy))));
    ndim=ndimindex2(1);

    [~,residLWG,~]=moholsforann(resid,[ones(columsx,1) x' score(:,1:ndim)]);
   
    sigmrAnn=cov(resid);
    sigmauAnn=cov(residLWG);
    sAnn=ndim;
    tauAnn=rowsx+(rowsy+sAnn+3)/2;
    chisqAnn=(columsx-tauAnn)*(log(det(sigmrAnn))-log(det(sigmauAnn)));
    
     pvalchipsi0(rr,1)=1-chi2cdf(chisqAnn,sAnn*rowsy);

  
end
 pvalchipsi01=sort(pvalchipsi0);
 pvalchipsi02= pvalchipsi01.*(length(pvalchipsi01)+1-([1:length(pvalchipsi01)]'));
 pval=min(pvalchipsi02);

% fast function for ordinary least squares estimation.
function [R2,resid,yfit]=moholsforann(y,x)
betaols=x\y;
yfit=x*betaols;  
resid=y-yfit;
R2=sum((yfit-mean(yfit)).^2)/(sum((y-mean(y)).^2));


  

