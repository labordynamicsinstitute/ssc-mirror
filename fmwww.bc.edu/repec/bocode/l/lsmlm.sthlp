{smcl}
{* *! version 1.1.0  20jul2026}{...}
{viewerjumpto "Syntax" "lsmlm##syntax"}{...}
{viewerjumpto "Description" "lsmlm##description"}{...}
{viewerjumpto "Options" "lsmlm##options"}{...}
{viewerjumpto "Stored results" "lsmlm##results"}{...}
{viewerjumpto "Examples" "lsmlm##examples"}{...}
{viewerjumpto "References" "lsmlm##references"}{...}
{title:Title}

{phang}
{bf:lsmlm} {hline 2} Lee-Strazicich minimum LM unit root test with zero, one, or two structural breaks


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:lsmlm} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt br:eaks(#)}}number of structural breaks: {cmd:0}, {cmd:1}, or {cmd:2}; default is {cmd:breaks(2)}. {cmd:breaks(0)} is the Schmidt-Phillips no-break LM test{p_end}
{synopt:{opt mod:el(string)}}deterministic model: {cmd:break} (level and trend shift) or {cmd:crash} (level shift only); default {cmd:break}. Ignored when {cmd:breaks(0)}{p_end}

{syntab:Search / lag selection}
{synopt:{opt maxl:ag(#)}}maximum number of augmenting lags for general-to-specific selection; default is data driven{p_end}
{synopt:{opt tr:im(#)}}fraction of the sample trimmed at each end for the break search; default {cmd:trim(0.10)}{p_end}
{synopt:{opt mind:ist(#)}}minimum distance (in observations) between the two breaks; two-break case only; default {cmd:mindist(2)}{p_end}

{syntab:Other}
{synopt:{opt time:var(varname)}}time variable to use if the data are not {cmd:tsset}{p_end}
{synopt:{opt nopr:int}}suppress the results table{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
The data must be {help tsset} (a single time series), or a time variable must be
given through {opt timevar()}. Use {help if} / {help in} to restrict the command
to any sub-sample: a time window (e.g. {cmd:if inrange(year,1946,1994)}) and/or a
single panel unit (e.g. {cmd:if id==1}).


{marker description}{...}
{title:Description}

{pstd}
{cmd:lsmlm} performs the Lee-Strazicich minimum LM unit root test with up to two
endogenous structural breaks. The null hypothesis is a unit root; rejection is
evidence of (trend-)stationarity around the estimated breaks. Two deterministic
models are available: the {cmd:crash} model (a level shift at each break) and the
{cmd:break} model (a level and trend shift at each break, i.e. Lee-Strazicich
Model C). With {cmd:breaks(0)} the command reports the Schmidt-Phillips no-break
LM test.

{pstd}
The procedure follows Lee and Strazicich (2003, 2013) and Schmidt and Phillips
(1992): for every candidate break date (or pair of dates) the first-differenced
series is regressed on the differenced deterministic terms to recover the shift
magnitudes; the LM-detrended series {it:S(t)} is built (with {it:S(1)=0} and
{it:D.S} equal to the residual of {it:D.y} on the differenced deterministics); and
{it:D.y} is regressed on those deterministics, {it:S(t-1)} and lagged {it:D.S}
terms. Augmenting lags are chosen by a general-to-specific rule (from
{opt maxlag()} downward, keeping the highest lag whose |t| >= 1.645). The break
date(s) that minimise the t-statistic on {it:S(t-1)} are selected, and that
minimum statistic is the test statistic.

{pstd}
The test statistic is computed in native Stata (adapted from the author's own
{cmd:ls1break_lm} / {cmd:ls2break_lm} routines). The critical values are
interpolated over the sample size and, for the trend-break model, over the break
fraction(s); the CV tables and interpolation routines are ported from the
{cmd:leestra} package (Eruygur, SSC s459688, MIT License).

{pstd}
The test is computed on a single time series (the {cmd:tsset} series, restricted
by {help if} / {help in}). For a panel, loop over units and call {cmd:lsmlm}
once per unit (see {help lsmlm##examples:Examples}).

{pstd}
{it:Note.} The break search is a native-Stata grid search, so run time grows with
the sample length and, for the two-break case, roughly with the square of the
sample. For long series or many panel units this is slower than a Mata
implementation such as {cmd:leestra}.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt breaks(#)} sets the number of structural breaks: {cmd:0}, {cmd:1}, or
{cmd:2}. The default is {cmd:breaks(2)}. {cmd:breaks(0)} gives the Schmidt-Phillips
no-break LM test (no break dummies; {opt model()} is ignored).

{phang}
{opt model(string)} selects the deterministic model: {cmd:break} (a level and
trend shift at each break, Lee-Strazicich Model C) or {cmd:crash} (a level shift
only at each break, Model A). The default is {cmd:break}.

{dlgtab:Search / lag selection}

{phang}
{opt maxlag(#)} is the maximum number of lagged {it:D.S} terms considered by the
general-to-specific search. If not specified, it defaults to
floor(4*(T/100)^0.25) (at least 1), where T is the sample size.

{phang}
{opt trim(#)} is the fraction of observations trimmed at each end of the sample
when searching for break dates; it must lie in (0, 0.5). The default is
{cmd:trim(0.10)}.

{phang}
{opt mindist(#)} is the minimum number of observations required between the two
breaks (two-break case only). The default is {cmd:mindist(2)}.

{dlgtab:Other}

{phang}
{opt timevar(varname)} names the time variable when the data are not {cmd:tsset}.
If omitted, the {cmd:tsset} time variable is used.

{phang}
{opt noprint} suppresses the results table. All results are still returned in
{cmd:r()}.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:lsmlm} stores the following in {cmd:r()}. Break-specific results are present
only for the corresponding number of breaks; trend-dummy t-stats
({cmd:r(tD1)}, {cmd:r(tD2)}) are present only for {cmd:model(break)}.

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(tau)}}minimum LM t-statistic on {it:S(t-1)} (the test statistic){p_end}
{synopt:{cmd:r(k)}}number of augmenting lags chosen{p_end}
{synopt:{cmd:r(breaks)}}number of breaks{p_end}
{synopt:{cmd:r(N)}}observations in the final regression{p_end}
{synopt:{cmd:r(maxlag)}}maximum lag used in the search{p_end}
{synopt:{cmd:r(trim)}}trimming fraction used{p_end}
{synopt:{cmd:r(cv1) r(cv5) r(cv10)}}interpolated 1%, 5%, 10% critical values{p_end}
{synopt:{cmd:r(reject1) r(reject5) r(reject10)}}1/0 rejection indicators{p_end}
{synopt:{cmd:r(tb1) r(tb1_index) r(lambda1)}}first break date, index, fraction{p_end}
{synopt:{cmd:r(break1_sig10)}}1 if break 1 dummies are relevant (|t|>=1.645){p_end}
{synopt:{cmd:r(tB1) r(tD1)}}t-stats on the break-1 level and trend dummies{p_end}
{synopt:{cmd:r(mindist)}}minimum break distance (two-break case){p_end}
{synopt:{cmd:r(tb2) r(tb2_index) r(lambda2)}}second break date, index, fraction (two-break case){p_end}
{synopt:{cmd:r(break2_sig10) r(tB2) r(tD2)}}break-2 relevance and dummy t-stats (two-break case){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(siglevel)}}significance level of rejection, or "Not significant"{p_end}
{synopt:{cmd:r(model)}}deterministic model{p_end}
{synopt:{cmd:r(timevar)}}time variable used{p_end}
{synopt:{cmd:r(varname)}}series tested{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}
The package ships an example dataset, {cmd:lsmlm_oecd15.dta}: log relative
per-capita income ({cmd:y}) for 15 OECD countries, 1870-1994. Load it with:{p_end}
{phang2}{cmd:. sysuse lsmlm_oecd15, clear}{p_end}

{pstd}One country (France), two breaks:{p_end}
{phang2}{cmd:. keep if country=="France"}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. lsmlm y, breaks(2) maxlag(8) mindist(5)}{p_end}

{pstd}No break (Schmidt-Phillips):{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. lsmlm y, breaks(0)}{p_end}

{pstd}One break, trend-break model (the default model):{p_end}
{phang2}{cmd:. lsmlm y, breaks(1)}{p_end}

{pstd}Two breaks, crash model:{p_end}
{phang2}{cmd:. lsmlm y, breaks(2) model(crash)}{p_end}

{pstd}Restrict to a time window with {help if}:{p_end}
{phang2}{cmd:. lsmlm y if inrange(year,1946,1994), breaks(2)}{p_end}

{pstd}Annual-data settings (8 lags, minimum break gap of 5):{p_end}
{phang2}{cmd:. lsmlm y, breaks(2) maxlag(8) mindist(5) trim(0.10)}{p_end}

{pstd}Use the returned results:{p_end}
{phang2}{cmd:. lsmlm y, breaks(2)}{p_end}
{phang2}{cmd:. display "tau=" r(tau) "  breaks at " r(tb1) " and " r(tb2)}{p_end}

{pstd}Loop over panel units and collect results (single unit per call):{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. tempname P}{p_end}
{phang2}{cmd:. postfile `P' int id int tb1 int tb2 double tau double cv5 byte rej10 using res.dta, replace}{p_end}
{phang2}{cmd:. levelsof id, local(ids)}{p_end}
{phang2}{cmd:. foreach i of local ids {c -(}}{p_end}
{phang2}{cmd:.     preserve}{p_end}
{phang2}{cmd:.         keep if id==`i'}{p_end}
{phang2}{cmd:.         tsset year}{p_end}
{phang2}{cmd:.         quietly lsmlm y, breaks(2) maxlag(8) mindist(5)}{p_end}
{phang2}{cmd:.         post `P' (`i') (r(tb1)) (r(tb2)) (r(tau)) (r(cv5)) (r(reject10))}{p_end}
{phang2}{cmd:.     restore}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. postclose `P'}{p_end}


{marker references}{...}
{title:References}

{phang}
Lee, J., and M. C. Strazicich. 2003. Minimum Lagrange multiplier unit root test
with two structural breaks. {it:Review of Economics and Statistics} 85(4): 1082-1089.

{phang}
Lee, J., and M. C. Strazicich. 2013. Minimum LM unit root test with one structural
break. {it:Economics Bulletin} 33(4): 2483-2492.

{phang}
Schmidt, P., and P. C. B. Phillips. 1992. LM tests for a unit root in the presence
of deterministic trends. {it:Oxford Bulletin of Economics and Statistics} 54(3): 257-287.


{title:Example data}

{pstd}
{cmd:lsmlm_oecd15.dta} is derived from the Maddison Project Database 2023, which is
licensed under a Creative Commons Attribution 4.0 International License. When using
it, please cite:{p_end}

{phang}
Bolt, J., and J. L. van Zanden. 2024. Maddison style estimates of the evolution of
the world economy: A new 2023 update. {it:Journal of Economic Surveys} 1-41.


{title:Acknowledgment}

{pstd}
The critical-value tables and interpolation routines are ported from the
{cmd:leestra} package by H. Ozan Eruygur ({stata "ssc describe leestra":ssc describe leestra}),
distributed under the MIT License.


{title:Author}

{pstd}
Ibrahim Ongoren, Department of Economics, Pamukkale University, Denizli, Turkey.
Email: ongorenibrahim78@gmail.com. The test statistic is adapted from the author's
own {cmd:ls1break_lm} / {cmd:ls2break_lm} routines.
