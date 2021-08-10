function [x,y]=stablepdf_fft(alpha,beta,sigma,mu,xmax,n,par,mult)
%STABLEPDF_FFT Stable probability density function (pdf) via FFT.
%   [X,Y]=STABLEPDF_FFT(ALPHA,BETA,SIGMA,MU,XMAX,N) returns the stable pdf
%   ((X,Y) pairs) with characteristic exponent ALPHA, skewness BETA, scale
%   SIGMA and location MU at 2^N evenly spaced values in [-XMAX,XMAX] in 
%   the S0 parametrization. Default values for XMAX and N are 20 and 12, 
%   respectively.
%   [X,Y]=STABLEPDF_FFT(ALPHA,BETA,SIGMA,MU,XMAX,N,PAR) allows to select 
%   the parametrization: PAR=0 --> S0 (default), PAR=1 --> S (or S1).
%
%   For |ALPHA - 1| < 0.001 the stable pdf is calculated using the formula 
%   for ALPHA = 1, otherwise numerical errors creep in. 
%
%   Due to the nature of FFT, values away from the center may be 
%   underestimated. For this reason STABLEPDF_FFT calculates the stable pdf 
%   on the interval [-XMAX,XMAX]*2^MULT and then truncates it to the 
%   original interval. The default value of MULT is 4, however, for better 
%   accuracy use MULT>4. The full syntax is:
%   [X,Y]=STABLEPDF_FFT(ALPHA,BETA,SIGMA,XMAX,N,PAR,MULT).
%
%   Sample use:
%       >> [x,y] = stablepdf_fft(1.5,0.5,1,0,100);
%
%   Reference(s):
%   [1] Sz.Borak, W.Härdle, R.Weron (2005) "Stable distributions", in
%   "Statistical Tools for Finance and Insurance", eds. P.Cizek, 
%   W.Härdle, R.Weron, Springer-Verlag, Berlin, 21-44. Available at 
%   http://ideas.repec.org/p/hum/wpaper/sfb649dp2005-008.html
%   [2] J.Nolan (20??) "Stable Distributions: Models for Heavy Tailed Data",
%   Birkhauser (in progress). Ch.1 at http://academic2.american.edu/~jpnolan
%	[3] R.Weron (2004) "Computationally intensive Value at Risk 
%   calculations", in "Handbook of Computational Statistics: Concepts and 
%   Methods", eds. J.E.Gentle, W.Härdle, Y.Mori, Springer, Berlin, 
%   911-950. 

%   Written by Rafal Weron (1996.07.01, rev. 2001.02.13, 2009.03.27, 2010.04.26)
%   Copyright (c) 1996-2010 by Rafal Weron

% Initialize input parameters with default values
if nargin < 8, mult = 4; end
if nargin < 7, par = 0; end
if nargin < 6, n = 12; end
if nargin < 5; xmax = 20; end

% Calculate pdf on a larger interval
xmax = xmax*(2^mult);

% Increase n to cover the larger interval with the same grid points
n = n + mult;
M = 2^n;
R = pi/xmax;
dt = 1/(R*M);

% Define the grid of evenly spaced points 
xx = (-2^(n-1)+.5:(2^(n-1)-.5))/(2^n*dt);

% Stable characteristic function
piby2 = pi/2;
if abs(alpha-1)<0.001,
    % Correct mu for the S (or S1) parametrization
    if par==1, 
        mu = mu + beta*sigma*log(sigma)/piby2;
    end
    % Characteristic function in the S0 parametrization
    yy = exp( -sigma*(abs(xx)).*( 1+i*beta.*sign(xx)/piby2.*log(sigma*abs(xx)) ) + i*mu*xx );
else
    % Correct mu for the S (or S1) parametrization
    if par==1,
        mu = mu + beta*sigma*tan(alpha*piby2);
    end
    % Characteristic function in the S0 parametrization
    yy = exp( -(sigma.*abs(xx)).^alpha.*( 1+i*beta.*sign(xx).*tan(alpha*piby2).*( (sigma.*abs(xx)).^(1-alpha)-1 ) ) + i*mu*xx );
end;
  
% Run FFT
yy1 = [yy((2^(n-1)+1):2^n), yy(1:2^(n-1))];
z = real( fft(yy1) )/(2*pi)*R;

% Compute stable density
x = (2*pi)*((0:1:(M-1))/(M*R)-1/(2*R));
y = [z((2^(n-1)+1):2^n), z(1:2^(n-1))];   

% Shrink to the original interval
T = find((x<=xmax/(2^mult)) & (x>=-xmax/(2^mult)));
x = x(T); x = x(:);
y = y(T); y = y(:);
