{smcl}
{* *! version 1.0.0 12jun2026}{...}
{vieweralsosee "mmqrtest" "help mmqrtest"}{...}
{vieweralsosee "mmqreg" "help mmqreg"}{...}
{vieweralsosee "xtqreg" "help xtqreg"}{...}
{viewerjumpto "Description" "mmqrtest_postestimation##description"}{...}
{viewerjumpto "Supported estimators" "mmqrtest_postestimation##supported"}{...}
{viewerjumpto "What is reused" "mmqrtest_postestimation##reused"}{...}
{viewerjumpto "Guarantees" "mmqrtest_postestimation##guarantees"}{...}
{viewerjumpto "Examples" "mmqrtest_postestimation##examples"}{...}
{title:Title}

{phang}
{bf:mmqrtest postestimation} {hline 2} Running the MM-QR test battery
after estimation


{marker description}{...}
{title:Description}

{pstd}
Every {helpb mmqrtest} subcommand can be invoked with no variable list
right after fitting a panel quantile model.  The command then reads the
model specification from the estimation results in memory, restricts all
computations to {cmd:e(sample)}, and {bf:restores your estimation results}
when it finishes, so you can keep working with the fitted model
(replay, {cmd:test}, {cmd:predict}, ...).


{marker supported}{...}
{title:Supported estimators}

{p2colset 5 16 18 2}{...}
{p2col:{helpb mmqreg}}recommended.  Dependent variable from
{cmd:e(depvar)}; regressors from the {it:location} equation of {cmd:e(b)};
quantiles from {cmd:e(qth)}; panel id from {cmd:e(fevlist)} when
{cmd:absorb()} contained a single variable, otherwise from {helpb xtset}.
The {cmd:scalerel} subcommand additionally reuses {cmd:e(b)}/{cmd:e(V)}
directly, inheriting your VCE (robust, cluster, jackknife).{p_end}
{p2col:{helpb xtqreg}}regressors from {cmd:e(b_location)}; quantiles from
{cmd:e(q)}; panel id from {helpb xtset}.{p_end}
{p2col:{helpb qregfe}}specification recovered from {cmd:e(cmdline)};
quantile from {cmd:e(quantile)}; panel id from {cmd:e(absorb)} or
{helpb xtset}.{p_end}
{p2colreset}{...}

{pstd}
Anything else raises error 301 with a pointer to the standalone syntax.


{marker reused}{...}
{title:What is recomputed and why}

{pstd}
The tests need objects that estimators do not store: residuals {it:R_it},
the fitted scale {it:sigma_it}, the unit effects {it:alpha_i} and
{it:delta_i}, and the standardized residuals {it:U_it}.  {cmd:mmqrtest}
therefore re-runs the MM-QR sequential algorithm (Machado and Santos Silva
2019, sec. 3.1) internally on {cmd:e(sample)} {hline 2} ordinary least
squares within regressions plus one-dimensional quantile estimation, so the
cost is negligible.  Coefficient estimates reproduce {cmd:mmqreg} with a
single absorbed panel variable; if you absorbed several variables, the
tests use one-way (panel) fixed effects and a note about the difference
applies.

{pstd}
Note that the tests are defined for the {bf:one-way fixed-effects panel
location-scale model}; the panel identifier is required even in standalone
mode.


{marker guarantees}{...}
{title:Guarantees}

{p 8 12 2}1. your {cmd:e()} results are held and restored on exit, even on
error ({cmd:_estimates hold});

{p 8 12 2}2. computations are restricted to {cmd:e(sample)};

{p 8 12 2}3. the sort order of your data is preserved;

{p 8 12 2}4. observations with non-positive fitted scale are excluded from
{it:U}-based statistics and flagged.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. mmqreg ln_wage tenure ttl_exp, absorb(idcode) quantile(25 50 75) cluster(idcode)}{p_end}
{phang2}{cmd:. mmqrtest all, seed(12345) graph}{p_end}
{phang2}{cmd:. mmqreg}{space 12}// replay still works: e() was restored{p_end}


{title:Author}

{pstd}
Merwan Roudane {hline 2}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{hline 2} {browse "https://github.com/merwanroudane"}
