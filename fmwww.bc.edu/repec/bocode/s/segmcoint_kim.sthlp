{smcl}
{* 24jul2026}{...}
{vieweralsosee "segmcoint" "help segmcoint"}{...}
{vieweralsosee "segmcoint dm" "help segmcoint_dm"}{...}
{vieweralsosee "segmcoint mr" "help segmcoint_mr"}{...}
{vieweralsosee "methods" "help segmcoint_methods"}{...}
{viewerjumpto "Syntax" "segmcoint_kim##syntax"}{...}
{viewerjumpto "Description" "segmcoint_kim##description"}{...}
{viewerjumpto "Options" "segmcoint_kim##options"}{...}
{viewerjumpto "Interpreting output" "segmcoint_kim##interpret"}{...}
{viewerjumpto "Remarks" "segmcoint_kim##remarks"}{...}
{viewerjumpto "Stored results" "segmcoint_kim##results"}{...}
{viewerjumpto "Author" "segmcoint_kim##author"}{...}
{title:Title}

{phang}
{bf:segmcoint kim} {hline 2} Kim (2003) weighted-LS tests for segmented cointegration

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:segmcoint kim} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth det:erministic(string)}}{cmd:none}, {cmd:const} (default), {cmd:trend}
= Kim Case I / II / III{p_end}
{synopt:{opt trimbar(#)}}upper bound on the length of the noncointegration interval,
as a fraction of T (Lemma 1 conservative bound); default {cmd:0.3}{p_end}
{synopt:{opt minlen(#)}}minimum noncointegration length as a fraction of T; default {cmd:0.05}{p_end}
{synopt:{opt bw:idth(#)}}Bartlett bandwidth for the long-run variance; default = automatic{p_end}
{synopt:{opt adflags(#)}}number of lagged differences in the ADF variant; default {cmd:0}{p_end}
{synopt:{opt grid(#)}}search-grid step (obs); default = automatic thinning for large T{p_end}
{synopt:{cmd:graph}}plot each statistic against its 5% critical value{p_end}
{synopt:{opt graphname(name)}}graph name{p_end}
{synopt:{cmd:noheader}}suppress header{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}The data must be {helpb tsset}. {it:n} = 1 + number of regressors must be <= 6
(the range of the tabulated critical values).{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:segmcoint kim} implements the procedure of
{help segmcoint##refs:Kim (2003)}.  For a trial noncointegration interval N_T the
cointegrating vector is estimated by weighted least squares that zeroes the weight
on N_T (the only weighting that yields a consistent estimator under the
alternative), Phillips-Perron-Ouliaris ({cmd:Zrho*}, {cmd:Zt*}) and augmented
Dickey-Fuller ({cmd:ADFrho*}, {cmd:ADFt*}) statistics are formed on the resulting
cointegration-set residuals, and the {it:infimum} over all admissible N_T is taken.
The smallest value constitutes the evidence against the null.  The command also
reports the estimated location of the noncointegration interval.

{marker options}{...}
{title:Options}

{phang}{opt deterministic(string)} selects the deterministic kernel of the
cointegrating regression, matching the tabulated critical-value cases.

{phang}{opt trimbar(#)} is the upper bound l-bar on the {it:relative length} of the
noncointegration interval used when searching and when selecting critical values.
Kim tabulates l-bar = 0.3; a smaller bound gives a more conservative test
(Lemma 1).

{phang}{opt minlen(#)} sets the shortest interval considered.

{phang}{opt bwidth(#)} fixes the Bartlett/Newey-West bandwidth of the long-run
variance estimator; the default uses floor(4 (Tc/100)^(2/9)).

{phang}{opt adflags(#)} adds lagged differences to the ADF variant (eq 3.5).

{phang}{opt grid(#)} thins the segmentation search for speed; the statistics are
continuous in the segmentation fractions so a coarse grid changes results only
slightly in large samples.

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
Four statistics are printed with their 1/2.5/5/10% {it:lower-tail} critical values
(Kim Tables 1-2, l-bar = 0.3).  {bf:Reject} the null of no cointegration when a
statistic is {it:below} the critical value; stars mark the level.  {cmd:Zt*} is
generally the most powerful.  The last block reports the estimated noncointegration
interval N_T as sample fractions, from both the inf-{cmd:Zt*} segmentation and the
extremum ({cmd:Lambda}-max) estimator of eq (3.16)-(3.17).

{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
o Power depends strongly on {it:n} and the AR root of the stationary error: Kim's
Table 4 shows high power for {cmd:Zt*} at n=3 but modest power at n=2 when the root
is near unity.  {p_end}
{pstd}
o Because the critical values are computed for l-bar = 0.3, the test is
conservative when the true noncointegration interval is shorter (Lemma 1).{p_end}
{pstd}
o For multiple noncointegration intervals Kim suggests detecting one at a time
(Bai 1997); this command handles a single interval.{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:segmcoint kim} stores in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(zt)}}inf {cmd:Zt*} statistic{p_end}
{synopt:{cmd:r(zrho)}}inf {cmd:Zrho*} statistic{p_end}
{synopt:{cmd:r(adft)}}inf {cmd:ADFt*} statistic{p_end}
{synopt:{cmd:r(adfrho)}}inf {cmd:ADFrho*} statistic{p_end}
{synopt:{cmd:r(tau0)}, {cmd:r(tau1)}}estimated noncointegration interval fractions{p_end}
{synopt:{cmd:r(n)}, {cmd:r(T)}}n and sample size{p_end}

{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(stat)}}4x3: statistic, tau0, tau1 for each of Zrho,Zt,ADFrho,ADFt{p_end}
{synopt:{cmd:r(cv_rho)}, {cmd:r(cv_t)}}critical-value rows (1/2.5/5/10%){p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
