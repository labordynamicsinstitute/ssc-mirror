function [Fdgen NoisfreFD ]=fractaldim(y,Q,M)

%__________________________________________________________________________
% Usage: Computes fractal dimension by box counting(BC) method.
% NOTE: Running the code may take a little time, because it calculates 
% dimensions for all embedding dimensions up to M.
 
% This code is based on an algorithm that constructs a box for the first
% observation and for other observations test which it  belongs to previous
% box(s). If the observation belongs to one of the existent boxes then
% increases number of points in the relevant box,otherwise makes a new box.
% the algorithm of this code uses only rounding down and it does not need 
% binary coding, sorting and so on. It uses only transformation data to
% [0,2^32-1] and finding valid boxes based on Leibovich and Toth(1989).
 
% Inputs: 
%  y is a vector time series.
%  q stands for generalized dimension q=1 entropy dimension,q=2 correlation
%  dimension and so on. q=0 is box counting dimension that automatically
%  calculated. q can takes any real value 
%  M is embedding dimension.If you have not any information about embedding
%  dimension please let in zero. The code finds proper M value by
%  symplectic geometry method.
 
% Output:
%  Fdgen is generalized fractal dimension.
  
 
% Copyright(c) Shapour Mohammadi, University of Tehran, 2009
% shmohammadi@gmail.com

%Ref:
% 1- Sprott,C. (2003). Chaos and Time Series Analysis, Oxford University
% Press.
% 2-Leibovich and Toth(1989), A Fast Algorithm To Determine Fractal 
% Dimensions By Box Counting, Physics Letters A, 141,386-390.

if M==0

%_______Determination Embedding Dimension: Symplectic Geometry Method______

cnt=0;
figure('name','Symplethic Geometry','NumberTitle','off')
for k=3:1:20
cnt=cnt+1;
X=lagmatrix(y,1:k);
X=X(k+1:end,:);
A=X'*X;

[rA cA]=size(A);
HH=ones(cA);

for i=1:cA
    
    S=A(:,i);
    if i>1
        S(1:i-1,1)=0;
    end
    if norm(S(i+1:end,1),2)>0;
    alpha=norm(S,2);
    E=zeros(rA,1);
    E(i,1)=1;
    roh=norm(S-alpha*E,2);
    omega=(1/roh)*(S-alpha*E);
    H=eye(rA)-2*omega*omega';
    A=H*A;
    HH=HH*H;
    end
    
end

lambda1=real(eig(A));
lambda=sort(lambda1,'descend');
sigma=lambda.^2;
SIGMA=log10(sigma/sum(sigma));
for ii=2:length(SIGMA)-1
    Hyp(ii,1)= vartest2(SIGMA(ii:end),SIGMA(1:end),0.05);
end

ind=find(Hyp==1);
if ~isempty(ind)
Embddim(cnt,1)=ind(1,1);
end

plot(SIGMA,'-*b')
hold on
end
emdim=find(Embddim>0);
embddim=emdim(1,1);

M=embddim
title (['Symplectic Geometry for Determination of Embedding Dimension']);
end



%___________________________Defining lags for y____________________________
yreg=y(:);
maxlag=M;
[nyr,nyc]=size(yreg);
yLreg=lagmatrix(y,1:maxlag);
yreg=yreg(maxlag+1:end,1);
yLreg=yLreg(maxlag+1:end,:);
[ryLreg cyLreg]=size(yLreg);

%_________________________Calcualtion of Dimension_________________________



if Q<2
    warning('Note: Q must be greater than 2, Automatical selection Q=2')
    Q=2;
end

tic
y=y(:);
M=M+1;
y=((y-min(y))/(max(y)-min(y)))*(2^32-1);

for m=1:M
yl=lagmatrix(y,0:m-1);
yl=yl(m+1:end,:);
[ry cy]=size(yl);
for i=21:30
    eps=ones(1,m)*2^i;
    % This section dived the point by 2^i and round down it after rounding
    % for returning back the opration of division the resulting value is 
    % multiplied by 2^i. By this opration minimum the box that this point
    % blonges to, will be determined and by adding the eps min and max of 
    % the box will be estimated.
    boxmin=floor(yl(1,:)/(2^i))*2^i;
    boxmax=floor(yl(1,:)/(2^i))*2^i+eps;
    nbox=0;
    for j=1:ry
        [rbox cbox]=size(boxmax);
        pivot=0;
        for s=1:rbox
            I=0;
            for k=1:cy
                if (yl(j,k)>=boxmin(s,k) && yl(j,k)<boxmax(s,k))
                     I=I+1;
                end 
            end
            if  cy==I
                nbox(s,1)=nbox(s,1)+1;
                pivot=pivot+1; break
            end
        end
          if pivot==0
                boxmin=[boxmin;floor(yl(j,:)/(2^i))*2^i];
                boxmax=[boxmax;floor(yl(j,:)/(2^i))*2^i+eps];
                nbox=[nbox;1];
          end
    end
    
    for q=-1:-1:-Q
    fdgen(i-21+1,m)=(1/(q-1))*log2(sum((nbox/(ry)).^q));
    fdgenneg{:,-q}=fdgen;
    end 
    
    rnbox(i-21+1,m)=length(nbox);
    fdbox(i-21+1,m)=-log2(rnbox(i-21+1,m));
    fdentrop(i-21+1,m)=(nbox/ry)'*log2((nbox/ry));
    
    for q=2:Q
    fdgen(i-21+1,m)=(1/(q-1))*log2(sum((nbox/ry).^q));
    fdgenpos{:,q-1}=fdgen;
    end
    
    clear pivot I  
     
end
Ind{:,m}=find(rnbox(1:end,m)<=floor(ry/5));
end
FFFd=[fdgenneg fdbox fdentrop fdgenpos];
for ll=1:2*Q+1
FFdgen=FFFd{ll};
for s=1:M
Fdgen(ll,s)=mean(diff(FFdgen(Ind{s},s)));
end
end

Fdgen=Fdgen(:,1:end-1);
embed=(1:m-1)
QQ=floor([-Q:1:Q]');
%__________________________________________________________________________



%_______________________________Display Results____________________________
disp(' ')
disp([blanks(m) 'Results of Fractal Dimension Estimation        ' ])
disp('  _________________________________________________________________')
disp([blanks(5) 'q' blanks(m*3) '  Embedding dimension'])
disp('  _________________________________________________________________')
disp(                   embed             )
disp(   [QQ ,Fdgen] )
disp('  _________________________________________________________________')
disp('q=0: Box Dimension q=1: Information Dimen. q=2: Correlation Dimen.')
disp('When embedding dimension increases fractal dimension approachs to')
disp('its correct value for noise free data')
disp('For embedding dimension greater than 2, the code calculates a noise')
disp('free fractal dimension, which is applicable when results do not ')
disp('converge to any specific value,due to presence of noise,') 







for i=1:2*Q+1  
dimnois=regress(Fdgen(i,:)',[ones(length(embed),1) embed']);
NoisfreFD(i,:)=Fdgen(i,:)'-dimnois(2,1)*embed';
end

%____________________________________END___________________________
toc


