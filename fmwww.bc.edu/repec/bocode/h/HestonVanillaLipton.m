function P = HestonVanillaLipton(phi,S,K,T,r,rf,kappa,theta,sigma,rho,v0)
%HESTONVANILLALIPTON European FX option price in the Heston model obtained
%using the Lewis-Lipton formula.
%   P = HESTONVANILLALIPTON(PHI,S,K,T,R,RF,KAPPA,THETA,SIGMA,RHO,V0)  
%   returns a price of European call (PHI =1) or put (PHI = -1) option 
%   given spot price S, exercise price K, initial volatility VO, volatility
%   of volatility SIGMA, domestic interest rate R, foreign interest rate
%   RF, time to maturity (in years) T, rate of mean reversion KAPPA, 
%   average level of volatility THETA and the correlation between two 
%   Wiener processes RHO.
%
%   Sample use:
%     >> HestonVanillaLipton(1,100,100,1,.1, .1,.1,.9,.3,0,.05) 
%
%   Reference(s):   
%   [1] A.Janek, T.Kluge, R.Weron, U.Wystup (2010) FX smile in the
%       Heston model, see http://ideas.repec.org/p/pra/mprapa/25491.html
%       {Chapter prepared for the 2nd edition of "Statistical Tools for 
%       Finance and Insurance", P.Cizek, W.Härdle, R.Weron (eds.), 
%       Springer-Verlag, forthcoming in 2011.}   
%   [2] A.Lipton (2001) Mathematical methods for foreign exchange, World
%       Scientific, 375-387
%   [3] A.Lipton (2002) The vol smile problem, Risk, February, 61–65.
%   [4] M.Schmelzle (2010) Option Pricing Formulae using Fourier Transform: 
%       Theory and Application, Working Paper
  
%   Written by Agnieszka Janek and Rafal Weron (2010.10.20) 
%   Revised by Rafal Weron (2010.12.27)

% Calculate call option price using adaptive Gauss-Kronrod quadrature
C = exp(-rf.*T).*S - exp(-r.*T).*K./(pi).*quadgk(@(v) HestonVanillaLiptonInt(S,K,T,r,rf,kappa,theta,sigma,rho,v0,v),0,inf,'RelTol',1e-8);
if (phi==1) %call option
  P = C;
else % put option
  % Calculate put option price via put-call parity
  P = C - S.*exp(-rf.*T) + K.*exp(-r.*T);
end

%%%%%%%%%%%%% INTERNALLY USED ROUTINE %%%%%%%%%%%%%

function payoff = HestonVanillaLiptonInt(S,K,T,r,rf,kappa,theta,sigma,rho,v0,v)
%HESTONVANILLALIPTONINT Auxiliary function used by HESTONVANILLALIPTON.
%   PAYOFF=HESTONFFTVANILLAINT(S,K,T,R,RF,KAPPA,THETA,SIGMA,RHO,V0,V)
%   returns the values of the auxiliary function evaluated at points V, 
%   given spot price S, strike K, time to maturity (in years) T,
%   domestic interest rate R, foreign interest rate RF, level of mean
%   reversion KAPPA, long-run variance THETA, vol of vol SIGMA, correlation 
%   RHO and initial volatility VO.
    
% See [3], formulas (6)-(7)
X = log(S/K) + (r - rf).*T;
kappa_hat = kappa - rho*sigma/2;
zeta = sqrt( v.^2.*sigma.^2.*(1-rho.^2) + 2.*1i.*v.*sigma.*rho.*kappa_hat + kappa_hat.^2 + sigma.^2/4 );
psi_plus = - ( 1i*kappa*rho*sigma + kappa_hat ) + zeta;
psi_minus = ( 1i*kappa*rho*sigma + kappa_hat ) + zeta;
alpha = - kappa.*theta/(sigma.^2).*( psi_plus.*T + 2.*log( ( psi_minus + psi_plus.*exp(-zeta.*T) )./(2.*zeta) ) );
beta = ( 1 - exp(-zeta.*T) )./( psi_minus + psi_plus.*exp(-zeta.*T) ); % corrected typo ("-" -> "+" in [3])
payoff = real( exp( ( -1i.*v + 0.5 ).*X + alpha - (v.^2 + 0.25).*beta.*v0 ) )./(v.^2 + 0.25);
    
