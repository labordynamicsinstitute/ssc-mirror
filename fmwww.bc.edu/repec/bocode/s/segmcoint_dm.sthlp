{smcl}
{* 24jul2026}{...}
{vieweralsosee "segmcoint" "help segmcoint"}{...}
{vieweralsosee "segmcoint kim" "help segmcoint_kim"}{...}
{vieweralsosee "segmcoint mr" "help segmcoint_mr"}{...}
{vieweralsosee "methods" "help segmcoint_methods"}{...}
{viewerjumpto "Syntax" "segmcoint_dm##syntax"}{...}
{viewerjumpto "Description" "segmcoint_dm##description"}{...}
{viewerjumpto "Options" "segmcoint_dm##options"}{...}
{viewerjumpto "Interpreting output" "segmcoint_dm##interpret"}{...}
{viewerjumpto "Remarks" "segmcoint_dm##remarks"}{...}
{viewerjumpto "Stored results" "segmcoint_dm##results"}{...}
{viewerjumpto "Author" "segmcoint_dm##author"}{...}
{title:Title}

{phang}
{bf:segmcoint dm} {hline 2} Davidson & Monticini (2010) subsample cointegration tests

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:segmcoint dm} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth det:erministic(string)}}{cmd:const} (default) or {cmd:trend}
(mean- / mean-and-trend-deviation residuals){p_end}
{synopt:{opt lambda0(#)}}minimum subsample / rolling-window length, one of
{cmd:0.5}, {cmd:0.35}, {cmd:0.2}, {cmd:0.1}; default {cmd:0.5}{p_end}
{synopt:{opt stat:istic(string)}}subsample statistic: {cmd:pp} (default) or {cmd:df}{p_end}
{synopt:{opt grid(#)}}subsample-search step (obs); default = automatic{p_end}
{synopt:{cmd:graph}}plot each min-statistic against its 5% critical value{p_end}
{synopt:{opt graphname(name)}}graph name{p_end}
{synopt:{cmd:noheader}}suppress header{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}The data must be {helpb tsset}. Critical values are tabulated for 1-2
regressors only; statistics are still reported for more regressors, without
critical values.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:segmcoint dm} implements {help segmcoint##refs:Davidson & Monticini (2010)}.
An ordinary residual-based cointegration statistic (Dickey-Fuller {cmd:df} or
Phillips-Perron {cmd:pp}) is computed on subsamples of the data and the
{it:minimum} (most negative) value is taken.  Three subsample designs are reported:

{phang2}o {cmd:QS}, {cmd:QS*} {hline 1} split-sample (halves), the latter also
including the full sample;{p_end}
{phang2}o {cmd:QI} {hline 1} incremental forward and backward samples of minimum
length lambda0;{p_end}
{phang2}o {cmd:QR}, {cmd:QR*} {hline 1} rolling windows of fixed length lambda0.{p_end}

{pstd}
The approach requires no model under the alternative and does not need the number
or type of breaks; it formalises the practice of "data-snooping" subsamples by
providing valid critical values for the extremum.

{marker options}{...}
{title:Options}

{phang}{opt deterministic(string)} chooses mean-deviation ({cmd:const}) or
mean-and-trend-deviation ({cmd:trend}) subsample residuals.  {cmd:none} is not
available (subsample residuals are always demeaned).

{phang}{opt lambda0(#)} is the minimum subsample length for the incremental test
and the fixed window length for the rolling test.  Only the tabulated values
{cmd:0.5}/{cmd:0.35}/{cmd:0.2}/{cmd:0.1} are accepted.  {cmd:QR}/{cmd:QR*} critical
values are tabulated only for {cmd:0.5}; smaller lambda0 yields more power to find a
short cointegrated window but has no tabulated rolling critical value.

{phang}{opt statistic(pp|df)} selects the subsample statistic; both share the same
asymptotic critical values.

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
Five min-statistics are printed with 10/5/2.5/1% {it:lower-tail} critical values
(Table 1).  {bf:Reject} the null of no cointegration on any subsample when a
statistic is {it:below} the critical value.  A rejection points to the existence of
a cointegrating relationship in some subperiod, worthy of further investigation.
Entries marked {cmd:(no CV)} have no tabulated critical value for the current
lambda0 / number of regressors.

{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
o Power depends on lambda0 relative to the break location: to detect a cointegrated
window of length at least lambda0*T, choose lambda0 no larger than that window.
A mid-sample noncointegration block defeats large-lambda0 windows because every
window straddles it (use {cmd:QI} with small lambda0 to reach a clean tail).{p_end}
{pstd}
o The incremental {cmd:QI} test is a good all-round default; {cmd:QI(0.35)}
performed well in the authors' simulations.{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:segmcoint dm} stores in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(qs)}, {cmd:r(qsstar)}}split-sample statistics{p_end}
{synopt:{cmd:r(qi)}}incremental statistic{p_end}
{synopt:{cmd:r(qr)}, {cmd:r(qrstar)}}rolling statistics{p_end}
{synopt:{cmd:r(T)}, {cmd:r(K)}}sample size and number of regressors{p_end}

{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(stat)}}5x1 min-statistics (QS,QS*,QI,QR,QR*){p_end}
{synopt:{cmd:r(cv)}}5x4 critical values (10/5/2.5/1%){p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
