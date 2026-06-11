{smcl}
{* *! version 1.0.0  03jun2026}{...}
{vieweralsosee "tnardll" "help tnardll"}{...}
{vieweralsosee "tnardllmult" "help tnardllmult"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "tnardlldiag##syntax"}{...}
{viewerjumpto "Description" "tnardlldiag##description"}{...}
{viewerjumpto "Options" "tnardlldiag##options"}{...}
{viewerjumpto "Remarks" "tnardlldiag##remarks"}{...}
{viewerjumpto "Examples" "tnardlldiag##examples"}{...}
{viewerjumpto "Stored results" "tnardlldiag##results"}{...}
{viewerjumpto "Author" "tnardlldiag##author"}{...}
{title:Title}

{phang}
{bf:tnardlldiag} {hline 2} Residual diagnostics after {help tnardll:tnardll}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tnardlldiag}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt bg:lags(#)}}lag order for the Breusch-Godfrey serial-correlation test; default {cmd:bglags(4)}{p_end}
{synopt:{opt arch:lags(#)}}lag order for the Engle ARCH-LM test; default {cmd:archlags(4)}{p_end}
{synopt:{opt reset:pow(#)}}highest power of the fitted value in the Ramsey RESET test; default {cmd:resetpow(3)}{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
{cmd:tnardlldiag} is for use after {helpb tnardll}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:tnardlldiag} reports a suite of specification diagnostics computed on the
residuals of the unrestricted error-correction model fitted by {helpb tnardll}.
The threshold design is rebuilt from the stored thresholds, so the residuals
reproduce the estimator exactly.  Four families of tests are reported:

{p 6 8 2}1. {bf:Serial correlation} {c -} the Breusch-Godfrey LM test for
autocorrelation up to {opt bglags()} lags.  The residuals are regressed on the
model regressors and {it:bglags} lagged residuals (presample residuals set to
zero); the statistic is {it:n}{c -}R{sup:2} and is referred to a chi-squared
distribution with {opt bglags()} degrees of freedom.{p_end}
{p 6 8 2}2. {bf:Heteroskedasticity} {c -} the Engle ARCH-LM test (squared
residuals on {opt archlags()} of their own lags) and a Breusch-Pagan test (the
Koenker {it:n}{c -}R{sup:2} form, squared residuals on the model regressors).{p_end}
{p 6 8 2}3. {bf:Normality} {c -} the Jarque-Bera test, with the sample skewness
and kurtosis of the residuals.{p_end}
{p 6 8 2}4. {bf:Functional form} {c -} the Ramsey RESET test, which adds powers
{cmd:2}..{opt resetpow()} of the fitted value to the model and tests their joint
significance with an F-test.{p_end}

{marker options}{...}
{title:Options}

{phang}
{opt bglags(#)} sets the number of lags in the Breusch-Godfrey test.  Must be a
positive integer; default {cmd:bglags(4)}.

{phang}
{opt archlags(#)} sets the number of lags in the Engle ARCH-LM test.  Must be a
positive integer; default {cmd:archlags(4)}.

{phang}
{opt resetpow(#)} sets the highest power of the fitted value used by the Ramsey
RESET test; powers {cmd:2} through {it:#} are added.  Must be at least {cmd:2};
default {cmd:resetpow(3)} (adds the square and cube of the fit).

{marker remarks}{...}
{title:Remarks}

{pstd}
The diagnostics are computed on the same estimation sample as the fitted
{helpb tnardll} model.  Because {cmd:tnardll} posts a Mata-built coefficient
vector rather than a {helpb regress}-type fit, the standard {helpb estat}
postestimation tests are not available; {cmd:tnardlldiag} provides the
equivalent residual diagnostics directly.  A well-specified model with
independent, homoskedastic, normal errors should fail to reject all five nulls.

{marker examples}{...}
{title:Examples}

{pstd}Fit the model, then run the default diagnostics:{p_end}

{phang2}{cmd:. tnardll y x, lags(1 1) regimes(2)}{p_end}
{phang2}{cmd:. tnardlldiag}{p_end}

{pstd}Customise the lag orders and RESET powers:{p_end}

{phang2}{cmd:. tnardlldiag, bglags(8) archlags(6) resetpow(4)}{p_end}

{pstd}Recover a single statistic for further work:{p_end}

{phang2}{cmd:. tnardlldiag}{p_end}
{phang2}{cmd:. display r(bg_p)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:tnardlldiag} stores the following in {cmd:r()}:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(bg)}, {cmd:r(bg_df)}, {cmd:r(bg_p)}}Breusch-Godfrey LM statistic, df and p-value{p_end}
{synopt:{cmd:r(arch)}, {cmd:r(arch_df)}, {cmd:r(arch_p)}}Engle ARCH-LM statistic, df and p-value{p_end}
{synopt:{cmd:r(bp)}, {cmd:r(bp_df)}, {cmd:r(bp_p)}}Breusch-Pagan statistic, df and p-value{p_end}
{synopt:{cmd:r(jb)}, {cmd:r(jb_p)}}Jarque-Bera statistic and p-value{p_end}
{synopt:{cmd:r(skewness)}, {cmd:r(kurtosis)}}residual skewness and kurtosis{p_end}
{synopt:{cmd:r(reset_F)}, {cmd:r(reset_df1)}, {cmd:r(reset_df2)}, {cmd:r(reset_p)}}Ramsey RESET F, numerator df, denominator df and p-value{p_end}
{p2colreset}{...}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}See {helpb tnardll} for the model, references, and the full list of
stored estimation results.{p_end}

{marker alsosee}{...}
{title:Also see}

{psee}
Estimation:  {helpb tnardll}{p_end}

{psee}
Postestimation:  {helpb tnardllmult} (cumulative dynamic multipliers){p_end}
