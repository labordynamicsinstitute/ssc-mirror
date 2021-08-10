function [betanonp  tstats Fnp]=nonparamReg(y,x);
% Nonparametric regression estimation basaed on Birkess and Dogges' Alternative
% Methods of Regression 

% Written by Shapour Mohammmadi,University of Tehran
% Inputs: x as vectors of independent variables.(without vector of ones)
% and y as a vector dependent variable.
% Outputs: betanonp is the estimated coefficients, ityration is number of
% t-stats is t-students of the coefficients and Fnp stands for nonparametric 
% F-statistic.

%__________________________________________________________________________
ry=length(y);
[rx cx]=size(x);
%finding first estimates by OLS method
b0=regress(y,[ones(ry,1) x]);
%defining beta star
bstar(:,1)=b0(2:cx+1,1);
%subtracting Means from independent variables 
 mu=mean(x);
for i=1:cx
Xc(:,i)=x(:,i)-mu(1,i);
end
%__________________________________________________________________________
%itrations fpr foiinding NOnparamerteric estimates
tstar=1;
itration=0;
while tstar>.000001 && itration<500
    itration=itration+1;
    z=y-x*bstar;
    rankkk=sort(z);
    
    for i=1:ry
    IIII=find(z(i,1)==rankkk);
    Index(i,1)=mean(IIII);
    end
  
    u=Index(:,1)-0.5*(ry+1);
    d=(Xc'*Xc)^(-1)*Xc'*u;
    w=x*d;
    
    count0=0;
  for s=1:ry-1
        for k=s+1:ry
            if w(k,1)~=w(s,1) ;  
            count0=count0+1;
    weight1(count0,1)=abs(w(k,1)-w(s,1));
            end
        end
  end  
    
    sumweight=sum(weight1);
    
    count1=0;
    for s=1:ry-1
        for k=s+1:ry
            if w(k,1)~=w(s,1) ;  
                count1=count1+1;
    tstar1(count1,1)=(z(k,1)-z(s,1))/(w(k,1)-w(s,1));
    weight(count1,1)=abs(w(k,1)-w(s,1))/sumweight;
            end
        end
    end
    
    sortedtstar=sort(tstar1);
    rtstar1=length(tstar1);
    
    Indextstar=find(sortedtstar(1)==tstar1);;
    for eee=2:rtstar1
    Index2=find(sortedtstar(eee)==tstar1);
    if sortedtstar(eee)~=sortedtstar(eee-1)
    Indextstar=[Indextstar ;Index2];
    end
    end
     sortedweights=weight(Indextstar);
    
    cumsumweights=cumsum(sortedweights);
    Index3=find(cumsumweights>0.5);
    tstar=sortedtstar(Index3(1,1));
    bstar=bstar+tstar*d;
end
%__________________________________________________________________________
%final values are Nonparametric estimates

%estimation of BETA0:for the estimation of BETA0 one should get median of
%Y-X*BETA^ where BETA^ is the estimated values of slopes(without BETA0)

Yhat1=y-x*bstar;
beta0=median(Yhat1);
betanonp=[beta0;bstar];


%__________________________________________________________________________
%Estimation of t-stats and F

%t-stats
et=y-[ones(rx,1) x]*betanonp;
nt=length(et);
countt=0;
for it=1:nt
    for jt=it:nt
        countt=countt+1;
        Aij(countt,1)=(et(it,1)+et(jt,1))/2;
    end
end
A=sort(Aij);
a=(nt*(nt+1))/4;
b=((nt*(nt+1)*(2*nt+1))/24)^0.5;
k1=round(0.5+a-1.645*b);
k2=round(0.5+a+1.645*b);
p=cx;
f=(nt/(nt-(p+1)))^0.5;
tauhat=(f*(nt^0.5)*(A(k2)-A(k1)))/(2*1.645);
Q=[ones(rx,1) x];
VC=(tauhat^2)*((Q'*Q)^(-1));
stderrors=(diag(VC).^0.5);
tstats=betanonp./diag(VC.^0.5);
PValues=2*(1-tcdf(abs(tstats),ry-cx));

%calculation of F
efull=y-[ones(rx,1) x]*betanonp;
    rankfull=sort(efull);
    for ifull=1:ry
    Indfull=find(efull(ifull,1)==rankfull);
    Indexfull(ifull,1)=mean(Indfull);
    end
    SRWRfull=sum((Indexfull(:,1)-0.5*(ry+1)).*efull);

ereduc=y;
    rankreduc=sort(ereduc);
    for ireduc=1:ry
    Indreduc=find(ereduc(ireduc,1)==rankreduc);
    Indexreduc(ireduc,1)=mean(Indreduc);
    end
    SRWRreduc=sum((Indexreduc(:,1)-0.5*(ry+1)).*ereduc);
    
    c=(ry+1)/(48^0.5);
    Fnp=(SRWRreduc-SRWRfull)/(cx*c*tauhat);
    PValueF=1-fcdf(Fnp,cx,ry-cx-1);

%Display REsults
disp(' ')
disp('  Results of Nonparametric Regression       ' )
disp(' ')
disp('   Coef.     Std.Err.   t-stats   PValues')
disp(  [ betanonp     ,      stderrors   ,        tstats,  PValues ] )
disp('    Tauhat   Fnp        PValue.F')
disp([tauhat          ,        Fnp      ,          PValueF])
  
        
