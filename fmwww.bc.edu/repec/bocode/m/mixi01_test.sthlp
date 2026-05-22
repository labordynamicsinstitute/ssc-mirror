{smcl}
{* *! version 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)}{...}
{vieweralsosee "mixi01" "help mixi01"}{...}
{vieweralsosee "mixi01_fmols" "help mixi01_fmols"}{...}
{vieweralsosee "mixi01_fmvar" "help mixi01_fmvar"}{...}
{vieweralsosee "mixi01_fmiv" "help mixi01_fmiv"}{...}
{vieweralsosee "mixi01_acl"  "help mixi01_acl"}{...}
{vieweralsosee "mixi01_svar" "help mixi01_svar"}{...}
{vieweralsosee "mixi01_vecm" "help mixi01_vecm"}{...}
{vieweralsosee "mixi01_irf" "help mixi01_irf"}{...}
{viewerjumpto "Syntax" "mixi01_test##syntax"}{...}
{viewerjumpto "Description" "mixi01_test##description"}{...}
{viewerjumpto "Options" "mixi01_test##options"}{...}
{viewerjumpto "Remarks" "mixi01_test##remarks"}{...}
{viewerjumpto "Examples" "mixi01_test##examples"}{...}
{viewerjumpto "Stored results" "mixi01_test##stored"}{...}
{viewerjumpto "References" "mixi01_test##references"}{...}
{viewerjumpto "Author"     "mixi01_test##author"}{...}
{viewerjumpto "Also see"   "mixi01_test##alsosee"}{...}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :{hi:mixi01_test} {hline 2}}Wald tests with mixed chi-squared limits{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:mixi01_test}
[{cmd:,}
{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Test type}
{synopt :{opt gra:nger(varlist)}}test Granger non-causality for specified variables{p_end}
{synopt :{opt wald(string)}}general linear restriction R*vec(F)=r{p_end}
{synopt :{opt coint:egration}}Johansen-type cointegration rank test{p_end}
{synopt :{opt perm:anent(varlist)}}test if shock from variable is permanent{p_end}

{syntab:Inference method}
{synopt :{opt cons:ervative}}use chi2(q) upper bound (default){p_end}
{synopt :{opt lib:eral}}use chi2(q) with Omega_ee.2{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(real 95)}}significance level{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mixi01_test} is a post-estimation command that performs Wald-type
hypothesis tests using results stored by {helpb mixi01_fmvar},
{helpb mixi01_fmols}, {helpb mixi01_svar}, {helpb mixi01_fmiv}, or
{helpb mixi01_vecm}.

{pstd}
The key theoretical result (Phillips, 1995, Theorem 6.1) is that the Wald
statistic W^+ based on FM estimators has a limit distribution:

{p 8 8 2}
W^+ →_d  sum_{i=1}^{q_1} chi2_1(i) + sum_{j=1}^{q_1} d_j * chi2_{q_{22}}(j)

{pstd}
where d_j in (0,1) are the eigenvalues of (R_1 Omega_{00.2} R_1')
(R_1 Sigma_{00} R_1')^{−1}.

{pstd}
This mixture is bounded above by chi2(q), where q = q_1 * (q_{21} + q_{22})
is the total number of restrictions.  Hence:

{p 8 12 2}
{bf:Conservative test:}  Uses chi2(q) critical values.  Always valid.
Rejects the null less often than the true size.

{p 8 12 2}
{bf:Liberal test:}  Uses Omega_{00.2} = Omega_{00} − Omega_{02} Omega_{22}^{−1}
Omega_{20} in the variance metric instead of Sigma_{00}.  The resulting
statistic W^+_{00.x} is bounded {it:below} by chi2(q), giving a liberal
(anti-conservative) test.

{pstd}
In practice, the true size lies between the conservative and liberal p-values.
When d_j are close to 1 (weak endogeneity), both bounds are close to chi2(q).
When d_j are small (strong endogeneity), the bounds can diverge.


{marker options}{...}
{title:Options}

{dlgtab:Test type}

{phang}
{opt granger(varlist)} tests Granger non-causality.  For each variable in
{it:varlist}, the null hypothesis is that all lags of that variable have
zero coefficients in each equation of the FM-VAR.  This tests whether the
variable Granger-causes the dependent variable(s).  The test is valid
{it:regardless of the integration order} of the variables.

{phang}
{opt wald(string)} tests a general set of linear restrictions on the
coefficient vector.  The string should contain Stata-style {cmd:test}
constraints, e.g., {cmd:wald("x2=0, x3=0")}.

{phang}
{opt cointegration} performs a Johansen-type trace test for the cointegration
rank.  Requires prior estimation via {helpb mixi01_vecm} with {cmd:trace}
option.

{phang}
{opt permanent(varlist)} tests whether the structural shock associated with
each variable in {it:varlist} has a permanent effect on the I(1) variables.
Requires prior estimation via {helpb mixi01_svar}.  The test examines whether
the corresponding column of C(1) is zero.

{dlgtab:Inference method}

{phang}
{opt conservative} (default) reports p-values using the chi2(q) upper bound.
This is always valid and is recommended for applied work.

{phang}
{opt liberal} reports p-values using the Omega_{ee.2} variance metric.
The resulting p-value is a lower bound on the true p-value.  The test may
over-reject relative to the nominal size.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Why Granger causality works with unit roots.}  Standard Granger causality
tests using OLS and F-statistics have nonstandard distributions when some
variables are I(1).  FM-VAR-based Wald tests avoid this problem because the
FM corrections remove the second-order bias that causes the non-standard
asymptotics.  The resulting chi-squared limit distribution — bounded by
chi2(q) — allows use of conventional critical values.

{pstd}
{bf:When do conservative and liberal bounds differ?}  The gap between the
bounds depends on the strength of the long-run endogeneity.  When
Omega_{02} ≈ 0 (weak endogeneity of the nonstationary regressors), the
eigenvalues d_j ≈ 1 and both bounds give similar p-values.  When there is
strong endogeneity, d_j << 1 and the conservative bound can be substantially
larger than the liberal bound.

{pstd}
{bf:Comparison with Toda–Yamamoto.}  The Toda–Yamamoto approach adds extra
lags (d_{max}) to the VAR and tests using only the first p lags.  This wastes
degrees of freedom.  FM-VAR Granger causality uses the information-criteria
lag order directly.


{marker examples}{...}
{title:Examples}

{dlgtab:Example 1: Granger causality with conservative bound}

{phang2}{cmd:. mixi01_fmvar y1 y2 y3, lags(2) i0(y3)}{p_end}
{phang2}{cmd:. mixi01_test, granger(y2) conservative}{p_end}

{dlgtab:Example 2: Multiple Granger tests}

{phang2}{cmd:. mixi01_fmvar y1 y2 y3 y4, lags(4)}{p_end}
{phang2}{cmd:. mixi01_test, granger(y2 y3 y4) conservative}{p_end}

{pstd}Output:{p_end}
{phang2}{cmd:  }{hline 66}{p_end}
{phang2}{cmd:    mixi01 Wald Test Results — Granger Causality}{p_end}
{phang2}{cmd:  }{hline 66}{p_end}
{phang2}{cmd:              Hypothesis       Chi2    df      P>chi2}{p_end}
{phang2}{cmd:  }{hline 66}{p_end}
{phang2}{cmd:  Granger: y2 -/-> y1        14.32     4      0.0063}{p_end}
{phang2}{cmd:    Conservative bound                        0.0063}{p_end}
{phang2}{cmd:    Liberal bound                              0.0021}{p_end}
{phang2}{cmd:  }{hline 66}{p_end}
{phang2}{cmd:  Note: Conservative test uses chi2(q) upper bound.}{p_end}
{phang2}{cmd:        See Phillips (1995, Theorem 6.1).}{p_end}
{phang2}{cmd:  }{hline 66}{p_end}

{dlgtab:Example 3: General Wald test}

{phang2}{cmd:. mixi01_fmols y x1 x2 x3, i1(x1 x2) i0(x3)}{p_end}
{phang2}{cmd:. mixi01_test, wald("x2=0, x3=0") conservative}{p_end}

{dlgtab:Example 4: Test if monetary policy shock is permanent}

{phang2}{cmd:. mixi01_svar gdp cpi oil irate, lags(4) i1(gdp cpi oil) i0(irate) p1(1 2 3) p0(4)}{p_end}
{phang2}{cmd:. mixi01_test, permanent(irate)}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mixi01_test} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt :{cmd:e(W_granger)}}Wald statistic for Granger test{p_end}
{synopt :{cmd:e(df_granger)}}degrees of freedom for Granger test{p_end}
{synopt :{cmd:e(p_cons)}}conservative p-value{p_end}
{synopt :{cmd:e(p_lib)}}liberal p-value (if available){p_end}
{synopt :{cmd:e(W_wald)}}Wald statistic for general test{p_end}
{synopt :{cmd:e(df_wald)}}degrees of freedom{p_end}
{synopt :{cmd:e(p_wald)}}p-value{p_end}
{synopt :{cmd:e(level)}}significance level used{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt :{cmd:e(test_cmd)}}{cmd:mixi01_test}{p_end}
{synopt :{cmd:e(test_type)}}{cmd:granger}, {cmd:wald}, {cmd:cointegration},
or {cmd:permanent}{p_end}


{marker references}{...}
{title:References}

{phang}
Phillips, P. C. B. (1995).  Fully modified least squares and vector
autoregression.  {it:Econometrica}, 63(5), 1023–1078.
{p_end}

{phang}
Toda, H. Y. and T. Yamamoto (1995).  Statistical inference in vector
autoregressions with possibly integrated processes.
{it:Journal of Econometrics}, 66(1–2), 225–250.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Department of Economics (Independent Researcher){break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{p_end}


{marker alsosee}{...}
{title:Also see}

{pstd}
Master help — {helpb mixi01}.
{p_end}

{pstd}
Sibling commands — {helpb mixi01_fmols}, {helpb mixi01_fmvar},
{helpb mixi01_fmiv}, {helpb mixi01_acl}, {helpb mixi01_svar},
{helpb mixi01_vecm}, {helpb mixi01_irf}, {helpb mixi01_test}.
{p_end}
