function [PvalChiTras,PvalChiTsay,PvalChiKeenan]=NonlinTstMltvar(y)

% Discription:
% nonlinearity test for multivariate time series. Output of the code 
% includes following nonliearity tests:

% 1- Trasvirta,Lin, and Granger(1993)
% 2- Tsay
% 3- Keenan

%This Matlab code has been used in S. Mohammadi(2019).
 
% Input: 
% y is a univariate time series in the form column vector.
 
% Output:
% Probability value of the tests. Reject linearity(H0) if pval is
% less than 5%(or any predetermined level of significance).

% References:
% 1- Mohammadi S. Neural network for univariate and multivariate nonlinearity tests. 
%     Stat Anal Data Min: The ASA DataSci Journal. 2019.
%     13:50-70.https://doi.org/10.1002/sam.11441
% 2- Tsay, R. S. Testing and modeling multivariate threshold models,
%     J. Amer. Statist. Assoc. 93 (1998), 1188-1202.
% 3- Vavra, M.  Testing for nonlinearity in multivariate stochastic
%     processes1, Working paper NBS, 2013, http://www.nbs.sk/en/
%     publications-issued-by-the-nbs/working-papers.
   
% Copyright, Shapour Mohammadi 2020.shmohmad@ut.ac.ir

%--------------------------------------------------------------------------

% Finding optimal lag.
T=length(y);
     aiccriter=zeros(5,1);
    for lag=1:5
        xlagmat=lagmatrix(y,1:lag);
        xlagmat=[ones(T-lag,1) xlagmat(lag+1:end,:)];
        [mohstats]=moholsforann(y(lag+1:end,1),xlagmat);
         resmdl1=mohstats{1,1};
        aiccriter(lag,1)=log((resmdl1'*resmdl1)/(T-lag))+2*lag/(T-lag);
    end
     optlag=find(aiccriter==min(aiccriter));
     X=lagmatrix(y,1:optlag);
     
     
index0=isnan(X(:,end));
index=find(index0==1);
maxindex=max(index)+1;
X=X(maxindex:end,:);
y=y(maxindex:end,:);
[T, K]=size(X);
[Ty, Ky]=size(y);
[mohstats]=moholsforann(y,X);
resid=mohstats{1,1};
fitedKeenan=mohstats{2,1};
[rresid,cresid]=size(resid);



% Keenan Test(1985)
CRtermKeenan=[];
for i=1:Ky
    for j=i:Ky
        CRtermKeenan=fitedKeenan(:,i).*fitedKeenan(:,j);
        CRtermKeenan=[CRtermKeenan CRtermKeenan];
    end
end


[~,scoreKeenan,~,~,Explned0Keenan] = pca([CRtermKeenan]);
    Explned=cumsum(Explned0Keenan);
    ndimindex=find(Explned>(99-2*ceil(log(Ky))));
    ndimKeenan =ndimindex(1);
[mohstatsKeenan1]=moholsforann(scoreKeenan(:,1:ndimKeenan),X);
residKeenan1=mohstatsKeenan1{1,1};

[mohstatsKeenan2]=moholsforann(resid,residKeenan1);
residKeenan2=mohstatsKeenan2{1,1};
sigmrKeenan=cov(resid);
sigmauKeenan=cov(residKeenan2);
sKeenan=ndimKeenan;
tauKeenan=K+(cresid+sKeenan+3)/2;
chisqKeenan=(T-tauKeenan)*(log(det(sigmrKeenan))-log(det(sigmauKeenan)));
PvalChiKeenan=1-chi2cdf(chisqKeenan,sKeenan*cresid);



% Multivariate Nonlinearity Tests

% Tsay Test(1986)
CRterms=[];
for i=1:K
    for j=i:K
        CRterm=X(:,i).*X(:,j);
        CRterms=[CRterms CRterm];
    end
end


[~,scoreTsay,~,~,Explned0] = pca([CRterms]);
    Explned=cumsum(Explned0);
    ndimindex=find(Explned>(99-2*ceil(log(Ky))));
    ndimTsay =ndimindex(1);
[mohstatsTsay1]=moholsforann(scoreTsay(:,1:ndimTsay),X);
residTsay1=mohstatsTsay1{1,1};

[mohstatsTsay2]=moholsforann(resid,residTsay1);
residTsay2=mohstatsTsay2{1,1};
sigmrTsay=cov(resid);
sigmauTsay=cov(residTsay2);
sTsay=ndimTsay;
tauTsay=K+(cresid+sTsay+3)/2;
chisqTsay=(T-tauTsay)*(log(det(sigmrTsay))-log(det(sigmauTsay)));
PvalChiTsay=1-chi2cdf(chisqTsay,sTsay*cresid);



% Trasvirta et. al. (1993) test V23(Volterra 2nd and 3rd degree series)
CRtermsTras2=[];
for i=1:K
    for j=i:K
        CRtermTras2=X(:,i).*X(:,j);
        CRtermsTras2=[CRtermsTras2 CRtermTras2];
    end
end
CRtermsTras3=[];
for i=1:K
    for j=i:K
        for l=j:K
        CRtermTras3=X(:,i).*X(:,j).*X(:,l);
        CRtermsTras3=[CRtermsTras3 CRtermTras3];
        end
    end
end


[~,scoreTras,~,~,Explned0] = pca([CRtermsTras2 CRtermsTras3]);

    Explned=cumsum(Explned0);
    ndimindex=find(Explned>(99-ceil(log(Ky))));
    ndimTras =ndimindex(1);
[mohstatsTras]=moholsforann(resid,[X scoreTras(:,1:ndimTras)]);
residTras=mohstatsTras{1,1};
sigmrTras=cov(resid);
sigmauTras=cov(residTras);
sTras=ndimTras;
tauTras=K+(cresid+sTras+3)/2;
chisqTras=(T-tauTras)*(log(det(sigmrTras))-log(det(sigmauTras)));
PvalChiTras=1-chi2cdf(chisqTras,sTras*cresid);


% fast function for ordinary least squares estimation.

function [mohstats]=moholsforann(y,x)
x=[ones(length(y),1), x];

betaols=x\y;
yfit=x*betaols;
e=y-yfit;
    
mohstats{1,1}=e;
mohstats{2,1}=yfit;
mohstats{3,1}=betaols;



