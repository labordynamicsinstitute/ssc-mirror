{smcl}
{* *! version 1.0.0 09jun2026}{...}
{vieweralsosee "xttestpanel het" "help xttestpanel_het"}{...}
{vieweralsosee "xttestpanel serial" "help xttestpanel_serial"}{...}
{vieweralsosee "xttestpanel csd" "help xttestpanel_csd"}{...}
{vieweralsosee "xttestpanel func" "help xttestpanel_func"}{...}
{vieweralsosee "xttestpanel hausman" "help xttestpanel_hausman"}{...}
{vieweralsosee "xttestpanel vif" "help xttestpanel_vif"}{...}
{vieweralsosee "xttestpanel postestimation" "help xttestpanel_postestimation"}{...}
{vieweralsosee "xtreg" "help xtreg"}{...}
{viewerjumpto "Syntax" "xttestpanel##syntax"}{...}
{viewerjumpto "Description" "xttestpanel##description"}{...}
{viewerjumpto "Postestimation" "xttestpanel##postest"}{...}
{viewerjumpto "Subcommands" "xttestpanel##subcommands"}{...}
{viewerjumpto "Options" "xttestpanel##options"}{...}
{viewerjumpto "Examples" "xttestpanel##examples"}{...}
{viewerjumpto "Stored results" "xttestpanel##results"}{...}
{viewerjumpto "References" "xttestpanel##refs"}{...}
{viewerjumpto "Author" "xttestpanel##author"}{...}
{title:Title}

{phang}
{bf:xttestpanel} {hline 2} Post-estimation diagnostic test suite for linear panel-data models

{marker syntax}{...}
{title:Syntax}

{pstd}{ul:Standalone form} {hline 1} estimates the model internally:{p_end}

{p 8 17 2}
{cmd:xttestpanel} {it:subcommand} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{pstd}{ul:Postestimation form} {hline 1} reuses the last {helpb xtreg} / {helpb reghdfe}:{p_end}

{p 8 17 2}
{cmd:xtreg} {depvar} {indepvars}{cmd:, fe}{break}
{cmd:xttestpanel} {it:subcommand} [{cmd:,} {it:options}]

{pstd}
With no {it:varlist}, {cmd:xttestpanel} pulls {it:depvar}, {it:indepvars}, the model
type and the estimation sample {cmd:e(sample)} from the results in memory. Tests
that require a different or additional model (the RE heteroskedasticity variant, the
FE-only functional-form test, or the Hausman test that needs both FE and RE) are
re-fitted automatically; a note is printed when that happens.

{pstd}where {it:subcommand} is one of:{p_end}

{synoptset 16 tabbed}{...}
{synopt:{helpb xttestpanel_het:het}}heteroskedasticity tests{p_end}
{synopt:{helpb xttestpanel_serial:serial}}serial-correlation tests{p_end}
{synopt:{helpb xttestpanel_csd:csd}}cross-sectional dependence tests{p_end}
{synopt:{helpb xttestpanel_func:func}}functional-form (nonparametric) test{p_end}
{synopt:{helpb xttestpanel_hausman:hausman}}FE-vs-RE specification test (classical + robust){p_end}
{synopt:{helpb xttestpanel_vif:vif}}multicollinearity (VIF + robust VIF){p_end}
{synopt:{opt all}}run the whole suite and print a combined report{p_end}
{synoptline}

{pstd}
The data must be {helpb xtset} before use. {it:depvar} is the dependent variable and
{it:indepvars} the regressors of the panel model under scrutiny.

{marker description}{...}
{title:Description}

{pstd}
{cmd:xttestpanel} is a unified library of modern post-estimation diagnostic tests for
linear panel-data regressions. Each subcommand estimates the requested model
internally (fixed effects, random effects, two-way, or pooled), extracts the
residuals, computes the relevant battery of tests, prints a clean formatted table,
and -- with the {opt graph} option -- produces a publication-quality diagnostic plot.
The {opt all} subcommand runs everything and adds a colour-coded decision summary
and an optional combined {opt dashboard}.

{pstd}
This is the overview page. Each subcommand has its own detailed help with the exact
statistics, formulas, assumptions and references:

{p2colset 9 30 32 2}{...}
{p2col :{helpb xttestpanel_het:het}}heteroskedasticity{p_end}
{p2col :{helpb xttestpanel_serial:serial}}serial correlation{p_end}
{p2col :{helpb xttestpanel_csd:csd}}cross-sectional dependence{p_end}
{p2col :{helpb xttestpanel_func:func}}functional form{p_end}
{p2col :{helpb xttestpanel_hausman:hausman}}FE vs RE specification{p_end}
{p2col :{helpb xttestpanel_vif:vif}}multicollinearity{p_end}
{p2colreset}{...}

{marker postest}{...}
{title:Postestimation use (recommended)}

{pstd}
{cmd:xttestpanel} is built first and foremost as a {bf:postestimation} tool: fit your
panel model once with {helpb xtreg} and then run the diagnostics on the model in
memory, with no need to respecify the variables.

{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xtreg y x1 x2 x3, fe}{p_end}
{phang2}{cmd:. xttestpanel all}{space 10}// the whole battery + decision summary{p_end}
{phang2}{cmd:. xttestpanel het, graph}{space 3}// or one test at a time{p_end}
{phang2}{cmd:. xttestpanel serial, lags(2)}{p_end}

{pstd}
With no {it:varlist}, each subcommand reads the dependent variable, regressors,
model type and estimation sample {cmd:e(sample)} from the fitted model, and restores
your {cmd:e()} on exit so you can chain any number of tests after a single
{cmd:xtreg}. Supported estimators in memory: {cmd:xtreg, fe}; {cmd:xtreg, re};
{cmd:regress} (pooled); {cmd:reghdfe} (two-way). See
{helpb xttestpanel_postestimation:[help] xttestpanel postestimation} for the full
details, the per-test model rules, and worked examples.

{marker subcommands}{...}
{title:Subcommands at a glance}

{synoptset 26 tabbed}{...}
{synopt:{bf:Subcommand}}{bf:Tests implemented}{p_end}
{synoptline}
{synopt:het}Breusch-Pagan; Koenker (robust); Juhl & Sosa-Escudero (FE);
Feng, Li, Tong & Luo (two-way){p_end}
{synopt:serial}Baltagi & Li LM; Born-Breitung/Wooldridge robust; Bin Chen (2022) portmanteau{p_end}
{synopt:csd}Pesaran CD; Baltagi-Kao-Peng bias-corrected CD; Breusch-Pagan LM; scaled LM{p_end}
{synopt:func}Lin, Li & Sun (2014) kernel test with wild bootstrap{p_end}
{synopt:hausman}classical Mundlak Hausman; Beyaztas et al. robust weighted Hausman{p_end}
{synopt:vif}within-group VIF; Ismaeel-Midi-Sani robust VIF{p_end}
{synoptline}

{marker options}{...}
{title:Common options}

{phang}
{opt model(string)} selects the working model used to obtain residuals:
{cmd:fe} (default), {cmd:re}, {cmd:tw} (two-way FE), or {cmd:pool}.
Not every model is valid for every subcommand; see the subcommand help.

{phang}
{opt graph} draws the diagnostic plot associated with the subcommand.

{phang}
{opt dashboard} (with {opt all}) combines the het, func and serial plots into a
single panel.

{pstd}
Subcommand-specific options ({opt z()}, {opt lags()}, {opt reps()}, {opt bw()},
{opt tune()}) are documented on each subcommand page.

{marker examples}{...}
{title:Examples}

{pstd}Set up the panel:{p_end}
{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}

{pstd}Postestimation form (reuse the fitted model):{p_end}
{phang2}{cmd:. xtreg ln_wage age tenure hours, fe}{p_end}
{phang2}{cmd:. xttestpanel het}{p_end}
{phang2}{cmd:. xttestpanel all, dashboard}{p_end}

{pstd}Run the entire suite standalone with a combined dashboard:{p_end}
{phang2}{cmd:. xttestpanel all ln_wage age tenure hours, model(fe) dashboard}{p_end}

{pstd}Individual tests:{p_end}
{phang2}{cmd:. xttestpanel het    ln_wage age tenure hours, model(fe) graph}{p_end}
{phang2}{cmd:. xttestpanel serial ln_wage age tenure hours, lags(2) graph}{p_end}
{phang2}{cmd:. xttestpanel csd    ln_wage age tenure hours, graph}{p_end}
{phang2}{cmd:. xttestpanel func   ln_wage age tenure hours, reps(299)}{p_end}
{phang2}{cmd:. xttestpanel hausman ln_wage age tenure hours, graph}{p_end}
{phang2}{cmd:. xttestpanel vif    ln_wage age tenure hours, graph}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
Each subcommand stores its statistics and p-values in {cmd:r()}; see the subcommand
help pages. {opt all} stores the headline p-values in
{cmd:r(p_het)}, {cmd:r(p_serial)}, {cmd:r(p_csd)}, {cmd:r(p_func)},
{cmd:r(p_hausman)} and {cmd:r(mean_vif)}.

{marker refs}{...}
{title:References}

{phang}Baltagi, B.H., B.C. Jung, and S.H. Song. 2010. Testing for heteroskedasticity
and serial correlation in a random effects panel data model. {it:Journal of Econometrics}
154: 122-124.{p_end}
{phang}Baltagi, B.H., C. Kao, and B. Peng. 2016. Testing cross-sectional correlation in
large panel data models with serial correlation. {it:Econometrics} 4: 44.{p_end}
{phang}Beyaztas, B.H., S. Bandyopadhyay, and A. Mandal. 2021. A robust specification
test in linear panel data models. {it:arXiv:2104.07723}.{p_end}
{phang}Chen, B. 2022. A robust test for serial correlation in panel data models.
{it:Econometric Reviews} 41: 1095-1112.{p_end}
{phang}Feng, S., G. Li, T. Tong, and S. Luo. 2020. Testing for heteroskedasticity in
two-way fixed effects panel data models. {it:Journal of Applied Statistics} 47: 91-116.{p_end}
{phang}Ismaeel, S.S., H. Midi, and M. Sani. 2021. Robust multicollinearity diagnostic
measure for fixed effect panel data model. {it:Malaysian Journal of Fundamental and
Applied Sciences} 17: 636-646.{p_end}
{phang}Juhl, T., and W. Sosa-Escudero. 2014. Testing for heteroskedasticity in fixed
effects models. {it:Journal of Econometrics} 178: 484-494.{p_end}
{phang}Lin, Z., Q. Li, and Y. Sun. 2014. A consistent nonparametric test of parametric
regression functional form in fixed effects panel data models. {it:Journal of
Econometrics} 178: 167-179.{p_end}
{phang}Pesaran, M.H. 2004/2015. Testing weak cross-sectional dependence in large panels.
{it:Econometric Reviews} 34: 1089-1117.{p_end}

{marker author}{...}
{title:Author}

{pstd}Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}{p_end}
