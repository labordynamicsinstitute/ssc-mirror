function [q, qsig] = archtest (residuals, lags)
%ARCHTEST Engle's (1992) test for ARCH with Ljung & Box (1978) finite-sample correction
%
% [Q, QSIG] = ARCHTEST (RESIDUALS, LAGS) tests the null hypothesis of no AutoRegressive
%    Conditional Heteroskedasticity in time series RESIDUALS up to and including the lag
%    order(s) specified by LAGS, returning Q, the small-sample corrected Q statistic(s)
%    of Engle's ARCH test and QSIG, the level(s) of significance at which H0 is rejected.
%
%    RESIDUALS should be a vector of residuals obtained from some regression whose
%    goodness of fit one wishes to evaluate with the ARCH test. Alternatively, this can
%    also be a differenced time series.
%
%    LAGS can be a scalar (default is 1) or a vector of integers in any order.
%    For example, if LAGS = 5, results are only returned for the null hypothesis of no 5th
%    order ARCH effects, but if LAGS = [3 1 5], Q and QSIG will be three-point vectors
%    carrying the results for the test at lag orders 3, 1 and 5 (in this order).
%
%    QSIG assumes NaN values if the MATLAB Statistics Toolbox is not installed.
%
%    The cost of computation depends on the size of each lag order specified in LAGS.
%    This programme requires far more processing power than QSTAT.M. See the source code
%    comments for an explanation of how the test is conducted and the bottom of the
%    script for a list of references.
%
% The author assumes no responsibility for errors or damage resulting from usage. All
% rights reserved. Usage of the programme in applications and alterations of the code
% should be referenced. This script may be redistributed if nothing has been added or
% removed and nothing is charged. Positive or negative feedback would be appreciated.

%                     Copyright (c)  14 May 1998  by Ludwig Kanzler
%                     Department of Economics, University of Oxford
%                     Postal: Christ Church,  Oxford OX1 1DP,  U.K.
%                     E-mail: ludwig.kanzler@economics.oxford.ac.uk
%                     Homepage:      http://users.ox.ac.uk/~econlrk
%                     $ Revision: 1.01 $$ Date: 15 September 1998 $

% STEP 0: Set default value for LAGS, if the corresponding input argument is missing, and
% obtain information about the size of the input arguments:
if nargin < 2, lags = 1; end
nres   = length(residuals(:));
lags   = lags(:)';
nlags  = length(lags);
maxlag = max(lags);

% STEP 1: Compute the squares of the residuals obtained from the original regression:
res2   = residuals(:).^2;

% STEP 2: Form a matrix of constant and lagged squared residuals (up to the highest lag
% order) on which to regress the squared residuals:
vars(1:nres,1:1+maxlag) = 1;
for i = 1 : maxlag
   vars(1:nres-i, i+1) = res2(1+i:nres);
end

% For each lag order, perform...
R2(1:nlags) = 0;
for i = 1 : nlags
   
   % STEP 3: ... "run" the regression and obtain the predicted values, and ...
   pred  = vars(1:nres-lags(i), 1:1+lags(i)) * (vars(1:nres-lags(i), 1:1+lags(i))...
         \ res2(1:nres-lags(i)));
   
   % STEP 4: ... compute the non-centred coefficient of determination R².
   R2(i) = sum((pred                 - sum(pred)                /(nres-lags(i))).^2 )...
         / sum((res2(1:nres-lags(i)) - sum(res2(1:nres-lags(i)))/(nres-lags(i))).^2 );
end

% STEP 5: Following Engle (1992), the test statistic is then given by Q = NRES * R2.
% Apply Ljung & Box's (1978) small sample correction to this (see McLeod & Li, 1983):
q = (nres+2) ./ (nres-lags) .* nres .* R2;

% STEP 6: Evaluate the level at which the test statistics are significant under the
% respective null hypotheses of no ARCH effects:
if exist('chi2cdf.m','file') & nargout == 2
   qsig = 1 - chi2cdf(q, lags);
elseif nargout == 2
   qsig = NaN*lags;
end

% End of function.


% REFERENCES:
%
% Engle, Robert (1982), "Autoregressive Conditional Heteroskedasticity with Estimates of
%    the Variance of United Kingdom Inflation", Econometrica, vol. 50, pp. 987-1007
%
% Ljung, G.M. & G.E.P. Box (1978), "On a Measure of Lack of Fit in Time Series Models”,
%    Biometrika, vol. 65, no. 2, pp. 297-303
%
% McLeod, A.I. & W.K. Li (1983), "Diagnostic Checking ARMA Time Series Models Using
%    Squared-Residual Autocorrelations", Journal of Time Series Analysis, vol. 4, no. 4,
%    pp. 269-273

% SOME USEFUL INFORMATION ABOUT THE ARCH TEST CAN ALSO BE FOUND AMONG THE FOLLOWING:
% 
% Bollerslev, Tim, Ray Chou & Kenneth Kroner (1992), "ARCH Modeling in Finance: A Review
%    of the Theory and Empirical Evidence", Journal of Econometrics, vol. 52, pp. 5-59
%
% Hamilton, James (1994), "Time Series Analysis", Princeton University Press, Princeton,
%    New Jersey, pp. 664-665
%
% Harvey, Andrew (1990), "The Econometric Analysis of Time Series", 2nd edition, MIT
%    Press, Cambridge, Massachusetts, pp. 221-223
%
% Mills, Terence (1993), "The Econometric Modelling of Financial Time Series", Cambridge
%    University Press, Cambridge, p. 107

% End of file.
