function [Lyap,yL]=lyapexpan(y,maxlag)
%__________________________________________________________________________
% This M-file calculates lyapunov exponents with Volterrs expansion.

% Inputs:
%   - y, a time series in vertical vector form.(eg stock prices)
%   - maxlag, maximume lag that should be entered in model.(eg 5)

% Outputs:
%   - yL, matrix of y's lags.
%   - Lyapunov exponents

% Ref: 
% -Lai,D. and G.Chen(1998)Statistical Analysis of Lyapunov Exponents 
%  from Time Series:A Jacobian Approach,Mathl. Comput. Modelling Vol. 27,
%  No. 7, pp. 1-9.
% -Eckmann, J. P. and D. Ruelle (1985). Ergodic Theory of Srange 
%  Attractores. Review of Modern Physics,57, pp. 617-656.
% -Sprott,J. C. (2003). Chaos and Time Series Analysis. Oxford University
%  Press.

% Copyright(c) Shapour Mohammadi, University of Tehran, 2009
%  shmohammadi@gmail.com

% Keywords: Lyapunov Exponents, Chaos, Time Series, Taylor Expansion,
% Jaccobian Method.
%__________________________________________________________________________


warning off
tic

%___________________________Defining lags for y____________________________
y=y(:);
[nyr,nyc]=size(y);
yL=lagmatrix(y,1:maxlag);
y=y(maxlag+1:end,1);
yL=yL(maxlag+1:end,:);
[ryL cyL]=size(yL);
%_________________ Regressors Up to degree 3_______________________________

X1=yL;
num1=0;
X2ij=[];
for i=1:cyL
     for j=i:cyL
      X2ij=[X2ij yL(:,i).*yL(:,j)];
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
           X3ijk=[ X3ijk yL(:,i).*yL(:,j).*yL(:,k)];
           Indexijk(num2+1,1)=i;
           Indexijk(num2+1,2)=j;
           Indexijk(num2+1,3)=k;
           num2=num2+1;
      
         end 
     end
end

X=[ones(ryL,1) X1 X2ij  X3ijk];

beta =inv (X'*X)*X'*y;
betaX1=beta(2:cyL+1);
betaX2ij=beta(cyL+2:cyL+1+num1);
betaX3ijk=beta(cyL+2+num1:cyL+1+num1+num2);


for i=1:cyL
    Inij1=find(Indexij(:,1)==i);
    Inij2=find(Indexij(:,2)==i);
    Inijk1=find(Indexijk(:,1)==i);
    Inijk2=find(Indexijk(:,2)==i);
    Inijk3=find(Indexijk(:,3)==i);
    Df1(:,i)=betaX1(i,1)*ones(ryL,1);
        
    Df210=zeros(ryL,1);
    for h21=1:length(Inij1)
        
        Df210=betaX2ij(Inij1(h21),1)*yL(:,Indexij(Inij1(h21),2))+Df210;
     
       
    end
    Df21(:,i)=Df210;
    
    Df220=zeros(ryL,1);
     for h22=1:length(Inij2)
        
        Df220=betaX2ij(Inij2(h22),1)*yL(:,Indexij(Inij2(h22),1))+Df220;
        
     end
     Df22(:,i)=Df220;
     
     Df310=zeros(ryL,1);
     for h31=1:length(Inijk1)
         
         Df310=betaX3ijk(Inijk1(h31),1)*yL(:,Indexijk(Inijk1(h31),2))...
             .*yL(:,Indexijk(Inijk1(h31),3))+Df310;
        
             
     end
      Df31(:,i)=Df310;
      
     Df320=zeros(ryL,1);
     for h32=1:length(Inijk2)
         
         Df320=betaX3ijk(Inijk2(h32),1)*yL(:,Indexijk(Inijk2(h32),1))...
             .*yL(:,Indexijk(Inijk2(h32),3))+Df320; 
        
     end
     Df32(:,i)=Df320;
     
     Df330=zeros(ryL,1);
     for h33=1:length(Inijk3)
         
         Df330=betaX3ijk(Inijk3(h33),1)*yL(:,Indexijk(Inijk3(h33),1))...
             .*yL(:,Indexijk(Inijk3(h33),2))+Df330;
         
     end
      Df33(:,i)=Df330;
end

Df=Df1+Df21+Df22+Df31+Df32+Df33;


%QR decomposition

M=floor(ryL/50);
Lyap=[Df(1,:);eye(maxlag-1,maxlag)]-[Df(1,:);eye(maxlag-1,maxlag)];
for bl=1:50
LAMBDA=[Df(1,:);eye(maxlag-1,maxlag)]-[Df(1,:);eye(maxlag-1,maxlag)];

Q0=eye(maxlag);
for i=(bl-1)*M+1:bl*M;
    [Q,R]=qr([Df(i,:);eye(maxlag-1,maxlag)]*Q0);
    LAMBDA1=logm(R);
    LAMBDA=LAMBDA+real(LAMBDA1);
    Q0=Q;
end
Lyap=LAMBDA+Lyap;

end
Lyap=Lyap/(M*50);

t=toc
%_________________________________END______________________________________

