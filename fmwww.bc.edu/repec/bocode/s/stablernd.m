function r = stablernd(alpha,beta,sigma,mu,m,n,par);
%STABLERND Random numbers from stable distribution.
%	R=STABLERND(ALPHA,BETA,SIGMA,MU) returns a matrix of random numbers drawn
%	from the stable distribution with characteristic exponent ALPHA, 
%   skewness BETA, scale SIGMA and location MU.
%   R=STABLERND(ALPHA,BETA,SIGMA,MU,M,N) returns an M by N matrix, while
%   R=STABLERND(ALPHA,BETA,SIGMA,MU,M,N,PAR) allows to select the
%   parametrization: PAR=0 --> S0 (default), PAR=1 --> S (or S1). 
%
%   Sample use:
%       >> r = stablernd(1.5,0.5,1,0,1000,1);
%
%	Reference(s):
%   [1] Sz.Borak, W.Härdle, R.Weron (2005) "Stable distributions", in
%   "Statistical Tools for Finance and Insurance", eds. P.Cizek, 
%   W.Härdle, R.Weron, Springer-Verlag, Berlin, 21-44. Available at 
%   http://ideas.repec.org/p/hum/wpaper/sfb649dp2005-008.html
%   [2] J.M.Chambers, C.L.Mallows, B.W.Stuck (1976) "A Method for
%   Simulating Stable Random Variables", JASA 71, 340-344.
%   [3] J.Nolan (20??) "Stable Distributions: Models for Heavy Tailed Data",
%   Birkhauser (in progress). Ch.1 at http://academic2.american.edu/~jpnolan
%	[4] R.Weron (2004) "Computationally intensive Value at Risk 
%   calculations", in "Handbook of Computational Statistics: Concepts and 
%   Methods", eds. J.E.Gentle, W.Härdle, Y.Mori, Springer, Berlin, 
%   911-950. 

%   Written by Rafal Weron (2010.04.26)
%   Copyright (c) 2010 by Rafal Weron

% Initialize input parameters with default values
if nargin<2,
    error('Requires at least two input arguments.');
end
if nargin<3, sigma = 1; end
if nargin<4, mu = 0; end
if nargin<5, m = 1; end
if nargin<6, n = 1; end
if nargin<7, par = 0; end

% Initialize r to zero.
r = zeros(m,n);

% Run the Chambers-Mallows-Stuck algorithm 
U = pi.*(rand(size(r)) - 0.5);
W = -log(rand(size(r)));
piby2 = pi/2;
if alpha~=1,
    zeta = -beta.*tan(piby2.*alpha);
    xi = atan(-zeta)./alpha;
    S_ab = (1+zeta.^2).^(0.5./alpha);
    r = S_ab.*sin(alpha.*(U+xi))./(cos(U).^(1./alpha)).*(cos(U-alpha.*(U+xi))./W).^((1-alpha)./alpha);
else % alpha==0
    r = ((piby2 + beta.*U).*tan(U) - beta.*log(piby2*W.*cos(U)./(piby2 + beta.*U)))./piby2;
end

% Add scale and location
r = sigma.*r + mu;
if par==0, % Correct for alpha<>1 in the S0 parametrization 
    if alpha~=1,
        r = r - sigma*beta*tan(alpha*piby2);
    end
else % Correct for alpha==1 in the S (or S1) parametrization
    if alpha==1,
        r = r + sigma*beta*log(sigma)/piby2;
    end
end


