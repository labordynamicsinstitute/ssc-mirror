{smcl}
{* 24jul2026}{...}
{vieweralsosee "segmcoint kim" "help segmcoint_kim"}{...}
{vieweralsosee "segmcoint dm" "help segmcoint_dm"}{...}
{vieweralsosee "segmcoint mr" "help segmcoint_mr"}{...}
{vieweralsosee "methods" "help segmcoint_methods"}{...}
{viewerjumpto "Syntax" "segmcoint##syntax"}{...}
{viewerjumpto "Description" "segmcoint##description"}{...}
{viewerjumpto "Subcommands" "segmcoint##sub"}{...}
{viewerjumpto "Common options" "segmcoint##options"}{...}
{viewerjumpto "Examples" "segmcoint##examples"}{...}
{viewerjumpto "Stored results" "segmcoint##results"}{...}
{viewerjumpto "References" "segmcoint##refs"}{...}
{viewerjumpto "Author" "segmcoint##author"}{...}
{title:Title}

{phang}
{bf:segmcoint} {hline 2} Tests for segmented cointegration
(cointegration holding only over part of the sample)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:segmcoint} {it:subcommand} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{pmore}
where {it:subcommand} is one of:

{synoptset 14 tabbed}{...}
{synopt:{helpb segmcoint_kim:kim}}Kim (2003) weighted-LS Phillips-Ouliaris and ADF tests, {it:inf} over segmentations{p_end}
{synopt:{helpb segmcoint_dm:dm}}Davidson & Monticini (2010) subsample DF/PP tests, {it:min} over subsamples{p_end}
{synopt:{helpb segmcoint_mr:mr}}Martins & Rodrigues (2021) residual sup-Wald tests, W(m) and Wmax{p_end}
{synoptline}

{pstd}
{it:depvar} and {it:indepvars} are the variables of the cointegrating regression;
the data must be {helpb tsset}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:segmcoint} implements three complementary residual-based procedures that test
the null of {it:no cointegration over the whole sample} against the alternative
that a stable cointegrating relationship prevails over one or more subperiods,
while breaking down (nonstationary error) over others.  This situation
{hline 1} {it:segmented cointegration} {hline 1} was introduced by
{help segmcoint##refs:Kim (2003)} and explains why standard full-sample
Engle-Granger / Phillips-Ouliaris tests often fail to confirm a well understood
long-run relationship: a relatively short interval of nonstationary deviation
can dominate the full-sample statistic and mask the relationship.

{pstd}
The three subcommands span the literature:

{phang2}
o {bf:kim} estimates the cointegrating vector by weighted least squares on a
{it:trial} cointegration set, forms Phillips-Perron-Ouliaris ({cmd:Zrho}, {cmd:Zt})
or ADF statistics, and takes the {it:infimum} over all admissible segmentations.
It also {it:dates} the noncointegration interval.

{phang2}
o {bf:dm} computes an ordinary DF or PP cointegration statistic on {it:subsamples}
of the data (split-sample, incremental, or rolling) and takes the {it:minimum}.
No model is estimated under the alternative and the break type/number need not
be specified.

{phang2}
o {bf:mr} runs a residual-based {it:sup-Wald} persistence-change test that allows
multiple regimes switching between cointegration and no cointegration, dates the
breaks by global SSR minimisation, and reports the double-maximum statistic Wmax.

{pstd}
See {helpb segmcoint_methods:help segmcoint methods} for the equation-by-equation
derivation and the step->equation compatibility map.

{marker sub}{...}
{title:Subcommands}

{pstd}
Each subcommand has its own help page with full syntax, options and stored results:

{phang2}{helpb segmcoint_kim:segmcoint kim} {hline 1} Kim (2003){p_end}
{phang2}{helpb segmcoint_dm:segmcoint dm} {hline 1} Davidson & Monticini (2010){p_end}
{phang2}{helpb segmcoint_mr:segmcoint mr} {hline 1} Martins & Rodrigues (2021){p_end}

{marker options}{...}
{title:Common options}

{synoptset 26 tabbed}{...}
{synopt:{opth det:erministic(string)}}deterministic terms: {cmd:none}, {cmd:const}
(default), or {cmd:trend} (intercept + linear trend); these correspond to Kim's
Case I / II / III and to the Martins-Rodrigues cases (a)/(b)/(c){p_end}
{synopt:{cmd:graph}}produce a diagnostic plot of each statistic against its 5%
critical value{p_end}
{synopt:{opt graphname(name)}}name for the saved graph{p_end}
{synopt:{cmd:noheader}}suppress the header block{p_end}
{synoptline}

{pstd}
All statistics test H0: no cointegration over the whole sample.  For {bf:kim} and
{bf:dm} the statistics are in the lower tail (reject when the statistic is
{it:below} the critical value); for {bf:mr} the Wald statistics are in the upper
tail (reject when {it:above}).

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse or use your own tsset time series}{p_end}
{phang2}{cmd:. tsset time}{p_end}

{pstd}Kim (2003), intercept, date the noncointegration interval, plot{p_end}
{phang2}{cmd:. segmcoint kim y x1 x2, deterministic(const) graph}{p_end}

{pstd}Davidson-Monticini rolling test with window length 0.35T{p_end}
{phang2}{cmd:. segmcoint dm y x, deterministic(const) lambda0(0.35) statistic(pp)}{p_end}

{pstd}Martins-Rodrigues sup-Wald with up to 4 breaks, intercept + trend{p_end}
{phang2}{cmd:. segmcoint mr y x1 x2, deterministic(trend) maxbreaks(4)}{p_end}

{pstd}A complete, self-checking demonstration ships with the package:{p_end}
{phang2}{cmd:. do segmcoint_example.do}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
Each subcommand is {cmd:rclass} and returns its statistics, critical-value
matrices and p-value information in {cmd:r()}; see the individual help pages.

{marker refs}{...}
{title:References}

{phang}
Davidson, J., and A. Monticini. 2010. Tests for cointegration with structural
breaks based on subsamples. {it:Computational Statistics & Data Analysis} 54:
2498-2511.

{phang}
Kim, J.-Y. 2003. Inference on segmented cointegration.
{it:Econometric Theory} 19: 620-639.

{phang}
Martins, L. F., and P. M. M. Rodrigues. 2021. Tests for segmented cointegration:
an application to US governments' budgets. {it:Empirical Economics} 63: 567-600.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
