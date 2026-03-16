{smcl}
{* *! version 1.0.0  March 2026}{...}
{vieweralsosee "[TS] var" "help var"}{...}
{vieweralsosee "[TS] svar" "help svar"}{...}
{vieweralsosee "[TS] irf" "help irf"}{...}
{viewerjumpto "Syntax" "tca##syntax"}{...}
{viewerjumpto "Description" "tca##description"}{...}
{viewerjumpto "Options" "tca##options"}{...}
{viewerjumpto "Examples" "tca##examples"}{...}
{viewerjumpto "Stored results" "tca##results"}{...}
{viewerjumpto "Reference" "tca##reference"}{...}
{title:Title}

{p2colset 5 15 17 2}{...}
{p2col:{bf:tca} {hline 2}}Transmission Channel Analysis for structural VAR models{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{phang}
Direct specification:

{p 8 14 2}
{cmd:tca} {cmd:,}
{opt phi0(matname)}
{opt ar(matname)}
{opt hor:izon(#)}
{opt from(#)}
{opt int:ermediates(numlist)}
[{it:options}]

{phang}
After {cmd:var} or {cmd:svar} estimation:

{p 8 14 2}
{cmd:tca_from_var} {cmd:,}
{opt from(#)}
{opt int:ermediates(numlist)}
[{it:options}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt phi0(matname)}}structural impact matrix (K x K){p_end}
{p2coldent:* {opt ar(matname)}}AR coefficient matrix (K x K*p), A_1|A_2|...|A_p{p_end}
{p2coldent:* {opt hor:izon(#)}}maximum impulse response horizon{p_end}
{p2coldent:* {opt from(#)}}shock variable number (1-based){p_end}
{p2coldent:* {opt int:ermediates(numlist)}}intermediate variables for channel decomposition{p_end}
{synoptline}

{synoptset 30 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt or:der(numlist)}}transmission ordering; default is {cmd:1 2 ... K}{p_end}
{synopt:{opt mode(string)}}decomposition mode: {cmd:overlapping}, {cmd:exhaustive_3way}, or {cmd:exhaustive_4way}{p_end}
{synopt:{opt target(#)}}response variable to display; default is first intermediate{p_end}
{synopt:{opt varnames(string)}}variable names for display{p_end}
{synopt:{opt gr:aph}}produce bar chart of channel decomposition{p_end}
{synopt:{opt val:idate}}run binary additivity test{p_end}
{synopt:{opt store(string)}}prefix for stored Stata matrices{p_end}
{synopt:{opt allhorizons}}display all horizons (not just selected ones){p_end}
{synoptline}
{p 4 6 2}* Required for {cmd:tca}; not needed for {cmd:tca_from_var}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tca} implements {it:Transmission Channel Analysis} (TCA) for structural
vector autoregressive (SVAR) models following the methodology of Wegner, Lieb,
and Smeekes (2025). TCA decomposes impulse response functions (IRFs) into
contributions from distinct transmission channels using a systems form
representation and directed acyclic graph (DAG) path analysis.

{pstd}
The key equation is {bf:x = Bx + Omega*epsilon}, where B is a K*(h+1) x K*(h+1)
block lower-triangular matrix and Omega encodes structural shocks. By selectively
zeroing entries in B and Omega, different transmission paths can be isolated.

{pstd}
Three decomposition modes are supported:

{phang2}
{cmd:overlapping} — Each channel represents through(j) = total - not_through(j).
Channels may overlap, so their sum may exceed the total.

{phang2}
{cmd:exhaustive_3way} — (Requires 2 intermediates) Non-overlapping decomposition:
(1) through variable 1 (inclusive), (2) through variable 2 only, (3) direct.
Sum equals total exactly.

{phang2}
{cmd:exhaustive_4way} — (Requires 2 intermediates) Full inclusion-exclusion:
(1) variable 1 only, (2) variable 2 only, (3) both variables, (4) direct.
Sum equals total exactly.


{marker options}{...}
{title:Options}

{phang}
{opt phi0(matname)} specifies the K x K structural impact matrix. For Cholesky
identification, this is the lower Cholesky factor of the residual covariance
matrix: {cmd:matrix Phi0 = cholesky(Sigma)}.

{phang}
{opt ar(matname)} specifies the AR coefficient matrix as K x (K*p), where
A_1, A_2, ..., A_p are concatenated column-wise. Row i contains the
coefficients for equation i.

{phang}
{opt horizon(#)} specifies the maximum impulse response horizon h.

{phang}
{opt from(#)} specifies which structural shock to analyze (1-based variable
number).

{phang}
{opt intermediates(numlist)} specifies the intermediate variables through which
transmission channels are defined. For exhaustive modes, exactly 2 variables
are required.

{phang}
{opt order(numlist)} specifies the transmission ordering. Default is natural
ordering 1 2 ... K. This determines the causal ordering in the DAG.

{phang}
{opt mode(string)} specifies the decomposition mode. Default is
{cmd:overlapping}.

{phang}
{opt target(#)} specifies which variable's response to display. Default is the
first intermediate variable.

{phang}
{opt varnames(string)} provides names for display. Default is Var1 Var2 ....

{phang}
{opt graph} produces a stacked bar chart of the channel decomposition with
the total IRF overlaid.

{phang}
{opt validate} runs the binary additivity test for all variables before the
main analysis, verifying that total = through(j) + not_through(j) at machine
precision.

{phang}
{opt allhorizons} displays all horizons instead of only selected ones
(0, 1, 2, 4, 8, 12, 16, 20, h).


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Direct specification with monetary policy model}

{phang2}{cmd:. // Define VAR parameters}{p_end}
{phang2}{cmd:. matrix A1 = (0.7,-0.1,0.05,-0.05 \ -0.3,0.6,0.10,-0.10 \ -0.2,0.1,0.70,0.05 \ -0.1,0.2,0.05,0.65)}{p_end}
{phang2}{cmd:. matrix A2 = (0.1,0,0,0 \ -0.1,0.1,0,0 \ -0.1,0,0.1,0 \ 0,0,0,0.1)}{p_end}
{phang2}{cmd:. matrix A = A1, A2}{p_end}

{phang2}{cmd:. // Residual covariance and Cholesky}{p_end}
{phang2}{cmd:. matrix Sigma = (1,0.3,0.2,0.1 \ 0.3,1.5,0.25,0.15 \ 0.2,0.25,0.8,0.1 \ 0.1,0.15,0.1,0.6)}{p_end}
{phang2}{cmd:. matrix Phi0 = cholesky(Sigma)}{p_end}

{phang2}{cmd:. // Run TCA: interest rate shock, channels via GDP(2) and Wages(4)}{p_end}
{phang2}{cmd:. tca , phi0(Phi0) ar(A) horizon(20) from(1) intermediates(2 4) target(3) mode(exhaustive_4way) varnames(IntRate GDP Inflation Wages) validate graph}{p_end}

{pstd}
{\bf:Example 2: After VAR estimation}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. var dln_inv dln_inc dln_consump, lags(1/2)}{p_end}
{phang2}{cmd:. tca_from_var , from(1) intermediates(2) target(3) horizon(20) validate}{p_end}

{pstd}
{bf:Example 3: Overlapping channels}

{phang2}{cmd:. tca , phi0(Phi0) ar(A) horizon(20) from(1) intermediates(2 4) mode(overlapping) target(3) varnames(IntRate GDP Inflation Wages)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tca} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(K)}}number of variables{p_end}
{synopt:{cmd:r(horizon)}}maximum horizon{p_end}
{synopt:{cmd:r(from)}}shock variable number{p_end}
{synopt:{cmd:r(n_channels)}}number of channels{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(mode)}}decomposition mode{p_end}
{synopt:{cmd:r(ch1name)}}name of channel 1{p_end}
{synopt:{cmd:r(ch2name)}}name of channel 2, etc.{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(irf_total)}}total IRF matrix (h+1 x K){p_end}
{synopt:{cmd:r(irf_ch1)}}channel 1 IRF matrix (h+1 x K){p_end}
{synopt:{cmd:r(irf_ch2)}}channel 2 IRF matrix, etc.{p_end}

{pstd}
Global macros {cmd:$tca_mode}, {cmd:$tca_nch}, {cmd:$tca_chname1}, etc. are
also stored.

{pstd}
Stata matrices {cmd:tca_total}, {cmd:tca_ch1}, {cmd:tca_ch2}, etc. are stored
for use in subsequent commands or graphing.


{marker reference}{...}
{title:Reference}

{phang}
Wegner, E., L. Lieb, and S. Smeekes. 2025.
{it:Transmission Channel Analysis in Dynamic Models.}
arXiv:2405.18987.
{browse "https://github.com/enweg/tca-matlab-toolbox"}
{p_end}


{title:Author}

{pstd}
This Stata implementation is a parallel port of the MATLAB tca-matlab-toolbox.
{p_end}
{smcl}
