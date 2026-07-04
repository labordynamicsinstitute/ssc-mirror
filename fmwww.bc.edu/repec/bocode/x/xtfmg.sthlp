{smcl}
{* *! version 1.0.0  03jul2026}{...}
{vieweralsosee "xtfmg fccemg" "help xtfmg_fccemg"}{...}
{vieweralsosee "xtfmg fsurmg" "help xtfmg_fsurmg"}{...}
{vieweralsosee "xtfmg estimators" "help xtfmg_estimators"}{...}
{vieweralsosee "xtfmg all" "help xtfmg_all"}{...}
{vieweralsosee "xtfmg breaks" "help xtfmg_breaks"}{...}
{vieweralsosee "xtfmg map" "help xtfmg_map"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtreg" "help xtreg"}{...}
{vieweralsosee "xtdcce2 (if installed)" "help xtdcce2"}{...}
{vieweralsosee "xtmg (if installed)" "help xtmg"}{...}
{viewerjumpto "Syntax" "xtfmg##syntax"}{...}
{viewerjumpto "Description" "xtfmg##description"}{...}
{viewerjumpto "The regime map" "xtfmg##regimemap"}{...}
{viewerjumpto "Subcommands" "xtfmg##subcommands"}{...}
{viewerjumpto "Examples" "xtfmg##examples"}{...}
{viewerjumpto "Stored results" "xtfmg##results"}{...}
{viewerjumpto "References" "xtfmg##references"}{...}
{viewerjumpto "Author" "xtfmg##author"}{...}

{title:Title}

{phang}
{bf:xtfmg} {hline 2} Second-generation heterogeneous panel estimators with
individual and common shocks: MG, CCEMG, SURMG, F-SURMG and the Fourier
Common Correlated Effects Mean Group (F-CCEMG) estimator


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtfmg} {it:subcommand} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 12 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt :{opt fccemg}}Fourier CCE Mean Group estimator (Guliyev 2026) {hline 2} see {helpb xtfmg_fccemg}{p_end}
{synopt :{opt fsurmg}}Fourier SUR Mean Group estimator (Guliyev 2023, 2025) {hline 2} see {helpb xtfmg_fsurmg}{p_end}
{synopt :{opt ccemg}}CCE Mean Group estimator (Pesaran 2006) {hline 2} see {helpb xtfmg_estimators}{p_end}
{synopt :{opt surmg}}SUR Mean Group estimator {hline 2} see {helpb xtfmg_estimators}{p_end}
{synopt :{opt mg}}Mean Group estimator (Pesaran and Smith 1995) {hline 2} see {helpb xtfmg_estimators}{p_end}
{synopt :{opt fe}}pooled fixed-effects benchmark {hline 2} see {helpb xtfmg_estimators}{p_end}
{synopt :{opt all}}all six estimators, journal-style comparison table {hline 2} see {helpb xtfmg_all}{p_end}
{synopt :{opt breaks}}per-unit sup-Wald structural-break test (Andrews 1993) {hline 2} see {helpb xtfmg_breaks}{p_end}
{synopt :{opt map}}CSD diagnostics and regime-map estimator recommendation {hline 2} see {helpb xtfmg_map}{p_end}
{synoptline}

{p 4 6 2}
The data must be {helpb xtset} with both a panel and a time variable.
{it:indepvars} must be numeric; time-series and factor-variable operators are
not allowed (create the lags/dummies first).


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtfmg} estimates the mean slope of the heterogeneous panel data model
with individual and common shocks

{p 8 8 2}
y_it = a_i + b_i' x_it + u_it,{space 6}u_it = g_i' f_t + e_it,

{pstd}
where the slopes b_i are heterogeneous across units with mean b = E(b_i),
f_t is a vector of unobserved common factors generating cross-sectional
dependence (CSD), and each unit may in addition experience structural breaks
at {it:unit-specific} dates. The object of interest is the mean slope b.

{pstd}
The package implements the full estimator set studied in Guliyev (2026):

{phang2}o{space 2}{bf:FE} {hline 2} the pooled fixed-effects benchmark, inconsistent for
b under slope heterogeneity (Pesaran and Smith 1995);{p_end}
{phang2}o{space 2}{bf:MG} {hline 2} unit-by-unit OLS averaged across units, consistent
under heterogeneity but biased under CSD;{p_end}
{phang2}o{space 2}{bf:CCEMG} {hline 2} unit regressions augmented with the
cross-sectional averages of (y, x), which asymptotically span the factor
space (Pesaran 2006);{p_end}
{phang2}o{space 2}{bf:SURMG} {hline 2} the N unit equations estimated jointly by
feasible-GLS SUR, exploiting cross-equation error correlation when N is
small relative to T;{p_end}
{phang2}o{space 2}{bf:F-SURMG} {hline 2} SURMG with unit-specific single-frequency
Fourier terms approximating breaks of unknown number, timing and form
(Becker, Enders and Lee 2006; Enders and Lee 2012);{p_end}
{phang2}o{space 2}{bf:F-CCEMG} {hline 2} the proposed estimator: the CCE regression
augmented with unit-specific Fourier terms, so the cross-sectional averages
filter the common factor while the Fourier terms absorb idiosyncratic,
heterogeneously-timed breaks.{p_end}

{pstd}
All mean-group estimators report the nonparametric Pesaran-Smith (1995)
variance. Every estimation subcommand also reports the Pesaran CD statistic
computed from its unit residuals.


{marker regimemap}{...}
{title:The regime map}

{pstd}
The Monte Carlo evidence in Guliyev (2026) shows that the appropriate
estimator depends jointly on the cross-section size N, the strength of the
cross-sectional dependence (measured by the Bailey-Kapetanios-Pesaran 2016
exponent alpha), and whether the structural breaks are individual rather
than common:

{p 8 8 2}{space 1}Dependence{space 6}very small N (<10){space 8}moderate / large N{p_end}
{p 8 8 2}{hline 60}{p_end}
{p 8 8 2}{space 1}weak{space 12}F-SURMG{space 19}F-CCEMG{p_end}
{p 8 8 2}{space 1}moderate{space 8}F-CCEMG{space 19}F-CCEMG{p_end}
{p 8 8 2}{space 1}strong{space 10}F-CCEMG (caution){space 9}CCEMG / F-CCEMG{p_end}

{pstd}
{cmd:xtfmg map} estimates the panel's position on this map from the Mean
Group residuals and prints a recommendation. {cmd:xtfmg breaks} documents
whether the breaks are heterogeneously timed, as in the G7 application of
the paper where the estimated dates span 1974-2004.


{marker subcommands}{...}
{title:Subcommands and options}

{pstd}
Estimation subcommands ({cmd:fccemg}, {cmd:fsurmg}, {cmd:ccemg},
{cmd:surmg}, {cmd:mg}) share the options {opt k:freq(#)} (Fourier frequency,
default 1; Fourier estimators only), {opt l:evel(#)}, {opt het:eroplot}
(forest plot of the unit-specific slopes), {opt four:ierplot} (plot of the
estimated unit-specific Fourier components; Fourier estimators only),
{opt f:ocus(varname)} (variable shown in the heterogeneity plot) and
{opt notab:le}. See the linked pages for details.

{pstd}
{cmd:xtfmg all} adds {opt coef:plot} (comparison of all six estimates with
confidence intervals, one panel per regressor). {cmd:xtfmg breaks} has
{opt trim(#)} (default 0.15) and {opt plot}. SUR-based estimators require a
balanced panel with T > N.

{pstd}
All table-producing subcommands accept {opt sav:ing(filename)},
{opt ti:tle(string)} and {opt rep:lace}, which export the table in
publication format chosen by the file extension: {bf:.tex} (LaTeX with
booktabs rules and superscript stars), {bf:.rtf}/{bf:.doc} (Word, Times New
Roman, journal rules), {bf:.csv}, or {bf:.txt} (aligned text). Coefficients
carry significance stars with standard errors in parentheses beneath, and
the table notes report N, T, the CD statistic and the star legend.


{marker examples}{...}
{title:Examples}

{phang}Setup{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{phang}Where is this panel on the regime map?{p_end}
{phang2}{cmd:. xtfmg map invest mvalue kstock}{p_end}

{phang}Are the breaks heterogeneously timed?{p_end}
{phang2}{cmd:. xtfmg breaks invest mvalue kstock, plot}{p_end}

{phang}The proposed estimator, with plots{p_end}
{phang2}{cmd:. xtfmg fccemg invest mvalue kstock, heteroplot fourierplot}{p_end}

{phang}Small-N comparator that does not rely on cross-sectional averages{p_end}
{phang2}{cmd:. xtfmg fsurmg invest mvalue kstock}{p_end}

{phang}Full journal-style comparison table and coefficient plot{p_end}
{phang2}{cmd:. xtfmg all invest mvalue kstock, coefplot}{p_end}

{phang}Export the comparison table for the paper (LaTeX and Word){p_end}
{phang2}{cmd:. xtfmg all invest mvalue kstock, saving(table8.tex) replace}{p_end}
{phang2}{cmd:. xtfmg all invest mvalue kstock, saving(table8.rtf) replace}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
Each subcommand is {cmd:rclass}; see the subcommand pages for the full
list. All estimation subcommands store {cmd:r(b)}, {cmd:r(V)},
{cmd:r(bunit)}, {cmd:r(seunit)}, {cmd:r(N)}, {cmd:r(Tbar)}, {cmd:r(cd)},
{cmd:r(cd_p)} and {cmd:r(alpha)}. {cmd:xtfmg all} stores the stacked
comparison matrices {cmd:r(B)} and {cmd:r(SE)} plus per-estimator
{cmd:r(b_}{it:est}{cmd:)} and {cmd:r(V_}{it:est}{cmd:)}. {cmd:xtfmg breaks}
stores {cmd:r(breaks)}. {cmd:xtfmg map} stores {cmd:r(regime)} and
{cmd:r(recommend)}.


{marker references}{...}
{title:References}

{phang}Andrews, D. W. K. 1993. Tests for parameter instability and structural
change with unknown change point. {it:Econometrica} 61: 821-856.
{browse "https://doi.org/10.2307/2951764"}{p_end}
{phang}Bailey, N., G. Kapetanios, and M. H. Pesaran. 2016. Exponent of
cross-sectional dependence: Estimation and inference.
{it:Journal of Applied Econometrics} 31: 929-960.
{browse "https://doi.org/10.1002/jae.2476"}{p_end}
{phang}Becker, R., W. Enders, and J. Lee. 2006. A stationarity test in the
presence of an unknown number of smooth breaks.
{it:Journal of Time Series Analysis} 27: 381-409.
{browse "https://doi.org/10.1111/j.1467-9892.2006.00478.x"}{p_end}
{phang}Enders, W., and J. Lee. 2012. A unit root test using a Fourier series
to approximate smooth breaks.
{it:Oxford Bulletin of Economics and Statistics} 74: 574-599.
{browse "https://doi.org/10.1111/j.1468-0084.2011.00662.x"}{p_end}
{phang}Guliyev, H. 2025. Heterogeneous panel data model with sharp and smooth
changes: Testing the green growth hypothesis in G7 countries.
{it:Innovation and Green Development} 4(3): 100245.
{browse "https://doi.org/10.1016/j.igd.2025.100245"}{p_end}
{phang}Guliyev, H. 2026. Second-generation heterogeneous panel data model
with individual and common shocks. arXiv:2606.29063.{p_end}
{phang}Pesaran, M. H. 2006. Estimation and inference in large heterogeneous
panels with a multifactor error structure. {it:Econometrica} 74: 967-1012.
{browse "https://doi.org/10.1111/j.1468-0262.2006.00692.x"}{p_end}
{phang}Pesaran, M. H., and R. Smith. 1995. Estimating long-run relationships
from dynamic heterogeneous panels. {it:Journal of Econometrics} 68: 79-113.
{browse "https://doi.org/10.1016/0304-4076(94)01644-F"}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}
{p_end}
