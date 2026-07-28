{smcl}
{* 24jul2026}{...}
{vieweralsosee "segmcoint" "help segmcoint"}{...}
{vieweralsosee "segmcoint kim" "help segmcoint_kim"}{...}
{vieweralsosee "segmcoint dm" "help segmcoint_dm"}{...}
{vieweralsosee "methods" "help segmcoint_methods"}{...}
{viewerjumpto "Syntax" "segmcoint_mr##syntax"}{...}
{viewerjumpto "Description" "segmcoint_mr##description"}{...}
{viewerjumpto "Options" "segmcoint_mr##options"}{...}
{viewerjumpto "Interpreting output" "segmcoint_mr##interpret"}{...}
{viewerjumpto "Remarks" "segmcoint_mr##remarks"}{...}
{viewerjumpto "Stored results" "segmcoint_mr##results"}{...}
{viewerjumpto "Author" "segmcoint_mr##author"}{...}
{title:Title}

{phang}
{bf:segmcoint mr} {hline 2} Martins & Rodrigues (2021) residual sup-Wald tests for
segmented cointegration

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:segmcoint mr} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth det:erministic(string)}}{cmd:none}, {cmd:const} (default), {cmd:trend}
= cases (a)/(b)/(c){p_end}
{synopt:{opt maxb:reaks(#)}}maximum number of breaks m-bar for Wmax; default {cmd:4}{p_end}
{synopt:{opt trim(#)}}trimming eps (minimum regime length as a fraction of T);
default {cmd:0.15}{p_end}
{synopt:{opt adflags(#)}}lagged differences in the ADF regression (serial-correlation
correction); default {cmd:0}{p_end}
{synopt:{cmd:graph}}plot W(m) and Wmax against their 5% critical values{p_end}
{synopt:{opt graphname(name)}}graph name{p_end}
{synopt:{cmd:noheader}}suppress header{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}The data must be {helpb tsset}. K+1 = 1 + number of regressors must be <= 6.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:segmcoint mr} implements the residual-based sup-Wald procedure of
{help segmcoint##refs:Martins & Rodrigues (2021)}, which extends the
Kejriwal-Perron persistence-change framework to cointegration.  Full-sample OLS
residuals of the cointegrating regression are subjected to an ADF regression whose
error-correction term is allowed to switch across m+1 regimes.  For each number of
breaks m the test contrasts the restricted (no-cointegration, spurious) sum of
squared residuals with the unrestricted sum computed over the SSR-minimising
partition, under two alternatives:

{phang2}o {bf:F_A} {hline 1} odd regimes have a unit root, even regimes are stationary;{p_end}
{phang2}o {bf:F_B} {hline 1} the first (and odd) regimes are stationary.{p_end}

{pstd}
W(m) = max(sup F_A, sup F_B) accommodates an unknown order of integration of the
first regime, and Wmax = max over m = 1..m-bar is a double-maximum statistic that
does not require m to be known.  Break dates are estimated by global SSR
minimisation (Bai-Perron dynamic programming).

{marker options}{...}
{title:Options}

{phang}{opt deterministic(string)} selects the deterministic kernel of the
cointegrating regression (unshifted, as in the paper's Remark 1).

{phang}{opt maxbreaks(#)} sets m-bar for the Wmax double-maximum statistic.  Tabulated
critical values cover W(1)-W(4) and Wmax; W(m) for m>4 is reported without a
critical value.

{phang}{opt trim(#)} is the trimming eps that bounds the minimum regime length
[eps*T]; the authors use 0.15.

{phang}{opt adflags(#)} adds lagged differences to the ADF regression to absorb
serial correlation in the error (the common short-run dynamics); with iid errors
0 is appropriate.

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
W(1)..W(m-bar) and Wmax are printed with 10/5/2.5/1% {it:upper-tail} critical values
(Table 1, T = 1000).  {bf:Reject} the null of no cointegration when a statistic is
{it:above} the critical value; stars mark the level.  The command then reports the
Wmax-selected number of breaks m* and the estimated break fractions.

{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
o The critical values are for T = 1000.  In smaller samples the tests are oversized:
the authors report Wmax empirical size around 0.10-0.16 at T = 200.  Treat borderline
rejections at short T with caution.{p_end}
{pstd}
o The cointegrating vector is estimated once on the full sample and is assumed not
to shift (Remark 1).  A regime with an unbounded random-walk error can contaminate
that estimate; the method has most power when cointegration prevails over the
majority of the sample.{p_end}
{pstd}
o With serially correlated errors, increase {cmd:adflags()}; this augments the
common short-run dynamics exactly as in the paper.{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:segmcoint mr} stores in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(wmax)}}Wmax double-maximum statistic{p_end}
{synopt:{cmd:r(w1)}..{cmd:r(w{it:mbar})}}W(m) statistics{p_end}
{synopt:{cmd:r(mstar)}}Wmax-selected number of breaks{p_end}
{synopt:{cmd:r(T)}, {cmd:r(K1)}}sample size and K+1{p_end}

{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(stat)}}(mbar+1)x1: W(1..mbar) then Wmax{p_end}
{synopt:{cmd:r(breaks)}}1x(mbar+1): m* then the estimated break fractions{p_end}
{synopt:{cmd:r(cv)}}5x4 critical values (rows W(1..4),Wmax; cols 10/5/2.5/1%){p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
