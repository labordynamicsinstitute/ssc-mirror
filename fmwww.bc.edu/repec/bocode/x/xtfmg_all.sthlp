{smcl}
{* *! version 1.0.0  03jul2026}{...}
{vieweralsosee "xtfmg" "help xtfmg"}{...}
{vieweralsosee "xtfmg fccemg" "help xtfmg_fccemg"}{...}
{vieweralsosee "xtfmg fsurmg" "help xtfmg_fsurmg"}{...}
{vieweralsosee "xtfmg estimators" "help xtfmg_estimators"}{...}
{vieweralsosee "xtfmg map" "help xtfmg_map"}{...}
{viewerjumpto "Syntax" "xtfmg_all##syntax"}{...}
{viewerjumpto "Description" "xtfmg_all##description"}{...}
{viewerjumpto "Options" "xtfmg_all##options"}{...}
{viewerjumpto "Stored results" "xtfmg_all##results"}{...}
{viewerjumpto "Examples" "xtfmg_all##examples"}{...}

{title:Title}

{phang}
{bf:xtfmg all} {hline 2} estimate all six estimators and report a
journal-style comparison table


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtfmg all} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt k:freq(#)}}Fourier frequency for F-SURMG and F-CCEMG; default 1{p_end}
{synopt :{opt l:evel(#)}}confidence level for the coefficient plot; default 95{p_end}
{synopt :{opt coef:plot}}comparison plot of all six estimates with confidence
intervals, one panel per regressor{p_end}
{synopt :{opt notab:le}}suppress the comparison table{p_end}
{synopt :{opt sav:ing(filename)}}export the comparison table in journal
format ({cmd:.tex}, {cmd:.rtf}/{cmd:.doc}, {cmd:.csv} or {cmd:.txt}){p_end}
{synopt :{opt ti:tle(string)}}caption for the exported table{p_end}
{synopt :{opt rep:lace}}overwrite the export file if it exists{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtfmg all} runs FE, MG, CCEMG, SURMG, F-SURMG and F-CCEMG on the same
estimation sample and prints a comparison table in the format of Table 8 of
Guliyev (2026): one column per estimator, coefficient with significance
stars over the standard error in parentheses, {cmd:sin}/{cmd:cos} rows for
the mean-group Fourier coefficients, and a footer reporting N, average T,
the number of observations, the residual CD statistic and the
Bailey-Kapetanios-Pesaran CSD exponent (both from the Mean Group residuals,
as in the paper).

{pstd}
If the estimation sample is unbalanced, SURMG and F-SURMG are skipped with a
note (they require a balanced panel with T > N) and their columns are left
blank; the other four estimators are unaffected.

{pstd}
Agreement of all six estimators on the sign and significance of the
coefficient of interest is itself informative {hline 2} in the paper's G7
application, the conclusion that renewable-energy consumption has no
significant growth effect is robust precisely because all six estimators
agree, while the methodological comparison shows which estimates are
defensible for a panel of that shape.


{marker options}{...}
{title:Options}

{phang}
{opt kfreq(#)} sets the Fourier frequency used by F-SURMG and F-CCEMG;
default 1.

{phang}
{opt coefplot} draws, for each regressor (up to 6), the six point estimates
with {opt level()}% confidence intervals, combined into a single figure named
{cmd:xtfmg_coef}. Missing estimators (skipped SUR columns) appear as gaps.

{phang}
{opt saving(filename)} exports the six-column comparison table in
publication format chosen by the file extension: {cmd:.tex} (LaTeX,
booktabs rules, numbered columns (1)-(6), superscript stars), {cmd:.rtf} or
{cmd:.doc} (Word, Times New Roman, journal rules), {cmd:.csv} or
{cmd:.txt}. The notes report N, T, the number of observations, the Fourier
frequency, the CD statistic, the CSD exponent and the star legend {hline 2}
ready to drop into a manuscript.

{phang}
{opt title(string)} sets the exported table caption; {opt replace} permits
overwriting an existing file.

{phang}
{opt level(#)}; {opt notable}: see {helpb xtfmg_fccemg:xtfmg fccemg}.


{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}, {cmd:r(Tbar)}, {cmd:r(n)}, {cmd:r(k)}, {cmd:r(kfreq)}}panel dimensions and frequency{p_end}
{synopt:{cmd:r(cd)}, {cmd:r(cd_p)}, {cmd:r(alpha)}}CSD diagnostics from MG residuals{p_end}
{synopt:{cmd:r(balanced)}}1 if the sample is balanced{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(B)}}(k+2) x 6 matrix of estimates (rows: regressors, sin, cos;
columns: FE MG CCEMG SURMG F_SURMG F_CCEMG){p_end}
{synopt:{cmd:r(SE)}}matching matrix of standard errors{p_end}
{synopt:{cmd:r(b_fe)} ... {cmd:r(b_fccemg)}}per-estimator coefficient vectors{p_end}
{synopt:{cmd:r(V_fe)} ... {cmd:r(V_fccemg)}}per-estimator variance matrices{p_end}
{synopt:{cmd:r(bunit_fccemg)}, {cmd:r(seunit_fccemg)}}F-CCEMG unit-specific
estimates and standard errors{p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtfmg all invest mvalue kstock, coefplot}{p_end}
{phang2}{cmd:. matrix list r(B)}{p_end}
{phang2}{cmd:. matrix list r(SE)}{p_end}

{phang}Export the table for a manuscript{p_end}
{phang2}{cmd:. xtfmg all invest mvalue kstock, saving(table1.tex) replace}{p_end}
{phang2}{cmd:. xtfmg all invest mvalue kstock, saving(table1.rtf) title(Investment regressions) replace}{p_end}


{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}
{p_end}
