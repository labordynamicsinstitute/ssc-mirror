function [alpha,beta,sigma,mu]=stablecull(x)
%STABLECULL Quantile parameter estimates of a stable distribution.
%	[ALPHA,BETA,SIGMA,MU]=STABLECULL(X) returns the estimated (McCulloch's 
%   method) parameters ALPHA, BETA, SIGMA, and MU of a stable distribution 
%   vector X.
%
%   Sample use:
%       >> r = stablernd(1.5,0.5,1,0,1000,1);
%       >> [alpha,beta,sigma,mu] = stablecull(r)
%
%   Reference(s):
%	[1] J.H.McCulloch (1986) "Simple Consistent Estimators of Stable
%	Distribution Parameters", Commun. Statist. - Simul. 15(4) 1109-1136
%   [2] S.Borak, A.Misiorek, R.Weron (2010) Models for Heavy-tailed Asset 
%   Returns, see http://ideas.repec.org/p/pra/mprapa/25494.html
%   {Chapter prepared for the 2nd edition of Statistical Tools for Finance 
%   and Insurance, P.Cizek, W.Härdle, R.Weron (eds.), Springer-Verlag, 
%   forthcoming in 2011.} 

%   Written by Szymon Borak and Rafal Weron (2000.12.15, rev. 2002.12.04)
%   Revised by Rafal Weron (2010.04.26, 2010.10.08)
%   Copyright (c) 2000-2010 by Rafal Weron

% Compute quantiles
x = sort(x);
x05 = prctile(x,5);
x25 = prctile(x,25);
x50 = prctile(x,50);
x75 = prctile(x,75);
x95 = prctile(x,95);

% Compute quantile statistics
va = (x95-x05)./(x75-x25);
vb = (x95+x05-2*x50)./(x95-x05);
vs = x75-x25;

% Define interpolation matrices (see [1])
tva = [2.439 2.5 2.6 2.7 2.8 3.0 3.2 3.5 4.0 5.0 6.0 8.0 10.0 15.0 25.0];
tvb = [0.0, 0.1, 0.2, 0.3, 0.5, 0.7, 1.0];
ta = [2.0 1.9 1.8 1.7 1.6 1.5 1.4 1.3 1.2 1.1 1.0 0.9 0.8 0.7 0.6 0.5];
tb = [0.0, 0.25, 0.5, 0.75, 1.0];

psi1 = [2.000, 2.000, 2.000, 2.000, 2.000, 2.000, 2.000;
      1.916, 1.924, 1.924, 1.924, 1.924, 1.924, 1.924;
      1.808, 1.813, 1.829, 1.829, 1.829, 1.829, 1.829;
      1.729, 1.730, 1.737, 1.745, 1.745, 1.745, 1.745;
      1.664, 1.663, 1.663, 1.668, 1.676, 1.676, 1.676;
      1.563, 1.560, 1.553, 1.548, 1.547, 1.547, 1.547;
      1.484, 1.480, 1.471, 1.460, 1.448, 1.438, 1.438;
      1.391, 1.386, 1.378, 1.364, 1.337, 1.318, 1.318;
      1.279, 1.273, 1.266, 1.250, 1.210, 1.184, 1.150;
      1.128, 1.121, 1.114, 1.101, 1.067, 1.027, 0.973;
      1.029, 1.021, 1.014, 1.004, 0.974, 0.935, 0.874;
      0.896, 0.892, 0.887, 0.883, 0.855, 0.823, 0.769;
      0.818, 0.812, 0.806, 0.801, 0.780, 0.756, 0.691;
      0.698, 0.695, 0.692, 0.689, 0.676, 0.656, 0.595;
      0.593, 0.590, 0.588, 0.586, 0.579, 0.563, 0.513];

psi2 = [0.000, 2.160, 1.000, 1.000, 1.000, 1.000, 1.000;
      0.000, 1.592, 3.390, 1.000, 1.000, 1.000, 1.000;
      0.000, 0.759, 1.800, 1.000, 1.000, 1.000, 1.000;
      0.000, 0.482, 1.048, 1.694, 1.000, 1.000, 1.000;
      0.000, 0.360, 0.760, 1.232, 2.229, 1.000, 1.000;
      0.000, 0.253, 0.518, 0.823, 1.575, 1.000, 1.000;
      0.000, 0.203, 0.410, 0.632, 1.244, 1.906, 1.000;
      0.000, 0.165, 0.332, 0.499, 0.943, 1.560, 1.000;
      0.000, 0.136, 0.271, 0.404, 0.689, 1.230, 2.195;
      0.000, 0.109, 0.216, 0.323, 0.539, 0.827, 1.917;
      0.000, 0.096, 0.190, 0.284, 0.472, 0.693, 1.759;
      0.000, 0.082, 0.163, 0.243, 0.412, 0.601, 1.596;
      0.000, 0.074, 0.147, 0.220, 0.377, 0.546, 1.482;
      0.000, 0.064, 0.128, 0.191, 0.330, 0.478, 1.362;
      0.000, 0.056, 0.112, 0.167, 0.285, 0.428, 1.274];

psi3 = [1.908, 1.908, 1.908, 1.908, 1.908;
      1.914, 1.915, 1.916, 1.918, 1.921;
      1.921, 1.922, 1.927, 1.936, 1.947;
      1.927, 1.930, 1.943, 1.961, 1.987;
      1.933, 1.940, 1.962, 1.997, 2.043;
      1.939, 1.952, 1.988, 2.045, 2.116;
      1.946, 1.967, 2.022, 2.106, 2.211;
      1.955, 1.984, 2.067, 2.188, 2.333;
      1.965, 2.007, 2.125, 2.294, 2.491;
      1.980, 2.040, 2.205, 2.435, 2.696;
      2.000, 2.085, 2.311, 2.624, 2.973;
      2.040, 2.149, 2.461, 2.886, 3.356;
      2.098, 2.244, 2.676, 3.265, 3.912;
      2.189, 2.392, 3.004, 3.844, 4.775;
      2.337, 2.635, 3.542, 4.808, 6.247;
      2.588, 3.073, 4.534, 6.636, 9.144];
  
  
psi4 = [0.0,    0.0,    0.0,    0.0,  0.0;  
      0.0, -0.017, -0.032, -0.049, -0.064;
      0.0, -0.030, -0.061, -0.092, -0.123;
      0.0, -0.043, -0.088, -0.132, -0.179;
      0.0, -0.056, -0.111, -0.170, -0.232;
      0.0, -0.066, -0.134, -0.206, -0.283;
      0.0, -0.075, -0.154, -0.241, -0.335;
      0.0, -0.084, -0.173, -0.276, -0.390;
      0.0, -0.090, -0.192, -0.310, -0.447;
      0.0, -0.095, -0.208, -0.346, -0.508;
      0.0, -0.098, -0.223, -0.383, -0.576;
      0.0, -0.099, -0.237, -0.424, -0.652;
      0.0, -0.096, -0.250, -0.469, -0.742;
      0.0, -0.089, -0.262, -0.520, -0.853;
      0.0, -0.078, -0.272, -0.581, -0.997;
      0.0, -0.061, -0.279, -0.659, -1.198];

% Compute estimates by interpolationg through the tables
[xrow,xcol] = size(x);
if (xrow == 1), xcol = 1; end;
for n = 1:xcol, 
    tvai1 = max([1 find(tva <= va(n))]);
    tvai2 = min([15 find(tva >= va(n))]);
    tvbi1 = max([1 find(tvb <= abs(vb(n)))]);
    tvbi2 = min([7 find(tvb >= abs(vb(n)))]);
    dista = (tva(tvai2)-tva(tvai1));
    if dista ~= 0,
        dista = (va(n)-tva(tvai1))/dista;
    end;
    distb = (tvb(tvbi2)-tvb(tvbi1));
    if distb ~= 0,
        distb = (abs(vb(n))-tvb(tvbi1))/distb;
    end;
    psi1b1 = dista*psi1(tvai2,tvbi1)+(1-dista)*psi1(tvai1,tvbi1);
    psi1b2 = dista*psi1(tvai2,tvbi2)+(1-dista)*psi1(tvai1,tvbi2);
    alpha(n) = distb*psi1b2+(1-distb)*psi1b1;
    psi2b1 = dista*psi2(tvai2,tvbi1)+(1-dista)*psi2(tvai1,tvbi1);
    psi2b2 = dista*psi2(tvai2,tvbi2)+(1-dista)*psi2(tvai1,tvbi2);
    beta(n) = sign(vb(n))*(distb*psi2b2+(1-distb)*psi2b1);
    tai1 = max([1 find(ta >= alpha(n))]);
    tai2 = min([16 find(ta <= alpha(n))]);
    tbi1 = max([1 find(tb <= abs(beta(n)))]);
    tbi2 = min([5 find(tb >= abs(beta(n)))]);
    dista = (ta(tai2)-ta(tai1));
    if dista ~= 0,
        dista = (alpha(n)-ta(tai1))/dista;
    end;
    distb = (tb(tbi2)-tb(tbi1));
    if distb ~= 0,
        distb = (abs(beta(n))-tb(tbi1))/distb;
    end;
    psi3b1 = dista*psi3(tai2,tbi1)+(1-dista)*psi3(tai1,tbi1);
    psi3b2 = dista*psi3(tai2,tbi2)+(1-dista)*psi3(tai1,tbi2);
    sigma(n) = vs(n)/(distb*psi3b2+(1-distb)*psi3b1);
    psi4b1 = dista*psi4(tai2,tbi1)+(1-dista)*psi4(tai1,tbi1);
    psi4b2 = dista*psi4(tai2,tbi2)+(1-dista)*psi4(tai1,tbi2);
    zeta = sign(beta(n))*sigma(n)*(distb*psi4b2+(1-distb)*psi4b1) + x50 ;
    if (abs(alpha(n)-1) < 0.05 )
        mu(n) = zeta;
    else
        mu(n) = zeta - beta(n)* sigma(n) * tan(0.5 * pi *alpha(n));
    end;
end;

% Correct estimates for out of range values
alpha(alpha <= 0) = 10^(-10)+0*alpha(alpha <= 0);
alpha(alpha > 2) = 2+0*alpha(alpha > 2);
sigma(sigma <= 0) = 10^(-10)+0*sigma(sigma <= 0);
beta(beta < -1) = -1+0*beta(beta < -1);
beta(beta > 1) = 1+0*beta(beta > 1);
