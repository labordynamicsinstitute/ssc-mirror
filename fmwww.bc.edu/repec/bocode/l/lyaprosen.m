function  [LaypExpnt]=lyaprosen(y,dt)

%__________________________________________________________________________
% Usage: Calculates largest Lyapunov exponent
 
% INPUTS:
%  y: y is a vector of values(time series data).
%  dt: the time step is used for data generation. It is 1 for discrete maps
%  and normally 0.01, 0.02 or 0.05 for continuous chaotic data sets.
 
% OUTPUTS:
%  LaypExpnt: Largest Lyapunov Exponent.
 
% NOTE1:
% The first version of this code was published in 2009. A function
% has recently been added in MATLAB named "lyapunovExponent" which is an 
% efficient and accurate code. Advantages of this version our code is noise 
% robustness, and automatic determination of all parameters except than dt, 
% whereas in the Matlab built-in code for getting accurate results at least  
% frequency(fs) and "Expansion range" should be determined by the user.
 
% NOTE2: 
% The code is noise-robust because of using the method of Liu et al. (2005). 
 
% Ref: 
% -Rosenstein, M. T., J. J. Collins, and C. J. De Luca,(1993). A practical 
% method for calculating largest Lyapunov exponents from small data sets.
% Physica D.
% -Hai-Feng Liu, Zheng-Hua Dai, Wei-Feng Li, Xin Gong, Zun-Hong Yu(2005)
% Noise robust estimates of the largest Lyapunov exponent, Physics Letters
% A 341, 119?127
% -Sprott, J. C. (2003). Chaos and Time Series Analysis. Oxford University
% Press.
% -Lei, M., Wang Z., Feng Z.A method of embedding dimension estimation
% based on symplectic geometry, Physics Letters A 303 (2002) 179?189. 
% -Zeng, X., R. Eykholt, and R. A. Pielke (1991)Estimating the 
% Lyapunov-Exponent Spectrum from Short Time Series of Low Precision,
% Physical Review Letters, Vol. 66, Number 25.
% -Kantz, H. (1994), A robust method to estimate the maximal Lyapunov 
% exponent of a time series Physics Letters A, Vol. 185(1), pp. 77-87.
 
 
% Copyright(c) Shapour Mohammadi, University of Tehran, 2009
% shmohammadi@gmail.com
 
% Revised for more accuracy in 2020,shmohmad@ut.ac.ir  
 
% Keywords: Lyapunov Exponents, Chaos, Time Series, Direct Method, 
% Full Automatic selection code, Autocorrelation, False nearest neighbors,
% MATLAB lyapunovExponent.



y=(y-min(y))/(max(y)-min(y));
[nyr,~]=size(y);
[m, ~]=fnn(y,10);

warning('off','all')

%___________________Determination of embeding Lag: tau_____________________

% Autocorrelation 
ACF=autocorr(y,floor(nyr/4)+1);
IndACF=find(ACF<=exp(-1));
tau0=IndACF(1,1)-1;

if tau0==0
    tau0=1;
end
tau=max(ceil(tau0/max((m-1),1)),1);

%______________________Defining lags for y:tau_____________________________

%Embeding matrix.(time delay)
EM=lagmatrix(y,(0:m-1)*tau);
EEM=EM((m-1)*tau+1:end,:);
[rEEM, ~]=size(EEM);

%_______________________Loop for distance calculations_____________________

dd=pdist(EEM);
MeanPeriod=ceil((1/dt)/max(meanfreq(y,1/dt)));
dd=squareform(dd);
dd=dd+eye(rEEM)*max(max(dd));

if dt<1
    kmax=min(250,5*(1/dt));
else
    kmax=25+floor(log10(nyr/4));
end

     MdlKDT = KDTreeSearcher(EEM);
     [index, DD]= knnsearch(MdlKDT,EEM,'K',rEEM);
     index=index(:,2:end);
     DD=DD(:,2:end);
       
epsmax=max(quantile(DD(:,1),0.95));
for n=1:rEEM-kmax
     nDD=DD(n,:);    
     l11{n,1}=find(nDD<=epsmax);    
end
    
  cntk=0;     
for k=0:kmax
    cntk=cntk+1;
    cntn=0;
for n=1:rEEM-kmax
     nl11=l11{n,1};
     
     if ~isempty(nl11)
          l1=index(n,nl11);
          l1=l1(l1<rEEM-k);
          l1=l1(abs(l1-n)>MeanPeriod);
         if length(l1)>=1
             cntn=cntn+1;
             u=dd(n+k,l1(1:min(5,length(l1)))+k);
             LL(cntn,1) = log(mean(u));
         end
     end
end
L(cntk,1)=(1/dt)*nanmean(LL);
K(cntk,1)=k;

end

%_________________Nonlinear Regression Layapunov Exponents_________________

if dt<1
    T0=max(1,floor(kmax/10));
else
    T0=1;
end
L=L(T0:end,1);
K=K(T0:end,1);
Lmaxind=find(diff(L)<0,1);
if isempty(Lmaxind)
     Lmaxind=find(L==max(L));
end

Lmax=L(Lmaxind,1);

L0=L(1);
Lm=L0+0.8*(Lmax-L0);

Ldiff=abs(L(1:Lmaxind,1)-Lm);

Tl=find(Ldiff==min(Ldiff));

if Tl<5
    Tl=5;
end

x=K(1:Tl);

[betar]=regress(L(1:Tl), [ones(length(x),1) x]);
yfit1=[];
for iii=1:100
[beta,resid,~,Covb] = nlinfit(x,L(1:Tl),@nonlin1,[betar;randn(1)]);
LLE1(iii,1)=beta(2,1);
yfit1(:,iii)=L(1:Tl)-resid;
tstudent(:,iii)=beta./(diag(Covb).^0.5);
R2(iii,1)=corr(yfit1(:,iii),L(1:Tl))^2;
end

indexr2=find(R2==max(R2));

LaypExpnt=LLE1(indexr2(1));
yfit=yfit1(:,indexr2);
tstat=tstudent(:,indexr2);
pvalue=2*(1-tcdf(abs(tstat),Tl-3));

if pvalue(3,1)>0.05
    
[betar,~,residuals]=regress(L(1:Tl,1),[ones(length(K(1:Tl,1)),1) K(1:Tl,1)]);
yfit=L(1:Tl,1)-residuals;
LaypExpnt=betar(2,1);

strlamtitle=['\fontsize{13}Largest Lyapunov Exponent:',' ',...
    '\fontsize{13}ln(d_{ij}(\tau))',...
    '=','k_0','+','\lambda_{max}\fontsize{13}\tau'];
figure('name',strlamtitle,'NumberTitle','off')
plot(K(1:end),L(1:end),'or')
hold on
plot(K(1:Tl,1),L(1:Tl,1),'ob');
title(strlamtitle)

plot(K(1:Tl,1),yfit,'-k','LineWidth',0.7);
xlyapi=1+1;
ylyapi=(min(L)+max(L))/2;
strlam=['\fontsize{14}\lambda_{max}','=\fontsize{12}'];
strlamlyap=[strlam,num2str(LaypExpnt)];
text(xlyapi,ylyapi,strlamlyap,'HorizontalAlignment','left');
  xlabel('\fontsize{14}\tau')
  ylabel('\fontsize{14}ln(d_{ij}(\tau))') 

else

strlamtitle=['\fontsize{13}Largest Lyapunov Exponent:',' ',...
    '\fontsize{13}ln(d_{ij}(\tau))',...
    '=','k_0','+','\lambda_{max}\fontsize{13}\tau','+' ,...
    'k\fontsize{13}\tau/e^{(\lambda_{max}\tau)}'];
figure('name',strlamtitle,'NumberTitle','off')
plot(K(1:end),L(1:end),'or');
hold on
plot(K(1:Tl,1),L(1:Tl,1),'ob');
title(strlamtitle)
hold on    
plot(K(1:Tl),yfit,'-k','LineWidth',0.7);
xlyapi=1+1;
ylyapi=(min(L)+max(L))/2;
strlam=['\fontsize{14}\lambda_{max}','=\fontsize{12}'];
strlamlyap=[strlam,num2str(LaypExpnt)];
text(xlyapi,ylyapi,strlamlyap,'HorizontalAlignment','left');
  xlabel('\fontsize{14}\tau')
  ylabel('\fontsize{14}ln(d_{ij}(\tau))') 

end


function yhat = nonlin1(beta,x)
b1 = beta(1);
b2 = beta(2);
b3 = beta(3);

yhat =b1+b2*x+b3*x./exp(b2*x);

%________________________________END_______________________________________
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
IndACF=find(ACF<=exp(-1));
tau0=IndACF(1,1)-1;
if tau0==0
    tau0=1;
end
RT=10;

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
     fnn0(k,1)=sum(((Rmp1-Rm)./Rm)>RT);
     diviser(k,1)=rEEM-m*tau;
end

fnn=fnn0./diviser;
embedm=find(fnn<0.001);

if isempty(embedm) 
  embedm=maxm;
elseif embedm==0
  embedm=1;  
else
  embedm=embedm(1);
end
%_____________________________End__________________________________________
