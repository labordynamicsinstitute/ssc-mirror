{smcl}
{* *! version 0.1.0}{...}
{vieweralsosee "[R] ivregress" "help ivregress"}{...}
{viewerjumpto "Syntax" "copulaendog##syntax"}{...}
{viewerjumpto "Description" "copulaendog##description"}{...}
{viewerjumpto "Options" "copulaendog##options"}{...}
{viewerjumpto "Estimators" "copulaendog##estimators"}{...}
{viewerjumpto "Examples" "copulaendog##examples"}{...}
{viewerjumpto "Stored results" "copulaendog##results"}{...}
{viewerjumpto "Author" "copulaendog##author"}{...}
{viewerjumpto "References" "copulaendog##references"}{...}

{title:Title}

{phang}
{bf:copulaendog} {hline 2} Instrument-free copula corrections for endogenous
regressors


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:copulaendog} {depvar} {it:endogvars} {ifin}{cmd:,}
[{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt ex:og(varlist)}}exogenous regressors; factor variables allowed{p_end}
{synopt:{opt m:ethod(name)}}{cmd:pg}, {cmd:2scope}, {cmd:ima}, {cmd:bmw} or
{cmd:jams}; default {cmd:pg}{p_end}
{synopt:{opt noconstant}}suppress the constant term{p_end}

{syntab:Copula transformation}
{synopt:{opt cdf(name)}}marginal CDF estimator; default follows the
estimator's own paper{p_end}
{synopt:{opt ti:es(name)}}{cmd:max} (default) or {cmd:average}{p_end}

{syntab:Inference}
{synopt:{opt nb:oots(#)}}bootstrap replicates; default 199{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}

{syntab:Estimator-specific}
{synopt:{opt cond:itional(varlist)}}JAMS: variables whose joint categories the
copula structure may vary over{p_end}
{synopt:{opt dis:crete(varlist)}}JAMS: exogenous regressors to treat as
discrete and keep out of the copula terms{p_end}
{synopt:{opt fse:xclude(varlist)}}exogenous regressors to hold out of the
first stage{p_end}

{syntab:Reporting}
{synopt:{opt val:idity}}report the identification checks{p_end}
{synopt:{opt gen:erate(stub)}}keep the copula terms as variables{p_end}
{synoptline}

{p 4 6 2}{it:endogvars} must be plain numeric variables: each one gets its own
copula term, and a factor variable has no single copula term. Put categorical
controls in {opt exog()} instead.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:copulaendog} corrects endogenous regressors in a linear model without an
instrument. The dependence between an endogenous regressor and the structural
error is modelled with a Gaussian copula, and the resulting control function is
added to the regression:

{p 8 8 2}
y = mu + P alpha + W beta + C gamma + u,{p_end}

{pstd}
where C is built from the copula transformation Phi{c -1}(F(P)) of the
endogenous regressors. The five estimators differ in how C is constructed;
see {help copulaendog##estimators:Estimators} below.

{pstd}
Standard errors are bootstrap standard errors from a pairs bootstrap, because
C is a generated regressor and the textbook OLS standard errors are wrong for
the structural coefficients. Resamples that lose a factor level, or that leave
a JAMS category too thin, are rejected and redrawn.

{pstd}
This is a port of the R reference implementation of Rouven E. Haschka,
{it:Copula-based endogeneity corrections in R}, and of the packaged version of
it, {cmd:endogCopula} by Ashwin Malshe. Both are credited in full under
{help copulaendog##references:References}.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt exog(varlist)} lists the exogenous regressors. They enter the structural
model and, for {cmd:2scope}, {cmd:ima} and {cmd:bmw}, the first stage. Factor
variables are allowed and are expanded into indicators.

{phang}
{opt method(name)} selects the estimator. See
{help copulaendog##estimators:Estimators}.

{dlgtab:Copula transformation}

{phang}
{opt cdf(name)} chooses how the marginal CDF entering the copula
transformation is estimated. The literature disagrees on this, so all of the
proposals are implemented:

{p2colset 9 28 30 2}{...}
{p2col:{cmd:kde.silverman}}integrated Epanechnikov kernel density, Silverman
bandwidth; Park & Gupta (2012){p_end}
{p2col:{cmd:kde.plugin}}Gaussian kernel CDF, Polansky & Baker (2000) plug-in
bandwidth{p_end}
{p2col:{cmd:ecdf.fixed}}empirical CDF with replaced boundary; Becker, Proksch
& Ringle (2022){p_end}
{p2col:{cmd:ecdf.adj}}adjusted ECDF; Liengaard et al. (2025){p_end}
{p2col:{cmd:rank.n}}rescaled ECDF, rank/n with a correction; Qian, Koschmann &
Xie (2025){p_end}
{p2col:{cmd:rank.n1}}rank/(n+1); Breitung, Mayer & Wied (2024){p_end}
{p2colreset}{...}

{phang2}
Defaults follow each estimator's own paper: {cmd:kde.silverman} for
{cmd:pg}, {cmd:rank.n} for {cmd:2scope} and {cmd:ima}, {cmd:ecdf.adj} for
{cmd:jams}, {cmd:rank.n1} for {cmd:bmw}. {cmd:bmw} is the one place where the
choice is not free: its Proposition 3.1 is derived for rank/(n+1), so anything
else produces a note.

{phang2}
The cross-validated bandwidth of Li, Li & Racine (2017), {cmd:kde.cv} in the R
and Python versions, is not available here.

{phang}
{opt ties(name)} controls the counting function. {cmd:max} reproduces
F(x) = (1/n) sum I(P_i <= x) literally, which is how every one of the papers
writes it. {cmd:average} uses midranks, the convention of the wider copula
literature. The two differ only for tied values.

{dlgtab:Estimator-specific}

{phang}
{opt conditional(varlist)} applies to {cmd:jams}. The copula structure is
estimated separately within each joint category of the named variables
(Equations 20 and 21 of Liengaard et al.): two binary variables give four
cells, not two. Every copula column is zero outside its own cell. With
{opt conditional()} empty, one common structure is estimated (Equation 18).

{phang}
{opt discrete(varlist)} names exogenous regressors that are discrete and
therefore stay out of the copula terms of {cmd:jams}: W in Equation 17 is the
continuous exogenous vector. Indicators produced from factor variables are
detected and excluded automatically.

{phang}
{opt fsexclude(varlist)} holds exogenous regressors out of the first stage of
{cmd:2scope}, {cmd:ima} and {cmd:bmw} while leaving them in the structural
model. Use it for terms built from an endogenous variable, which are not
exogenous information whichever list they were written in.

{dlgtab:Reporting}

{phang}
{opt validity} reports the identification checks: the non-normality
requirement, the uncorrelatedness assumption where it applies, the shape of
the structural error, and ICON.

{phang}
{opt generate(stub)} keeps the copula terms in the data, named after the
coefficients they belong to, which is what {cmd:predict, xba} needs.


{marker estimators}{...}
{title:Estimators}

{phang}
{cmd:method(pg)} {hline 2} Park & Gupta (2012). The original. Transforms each
endogenous regressor to a normal score and adds it to the regression. Assumes
the endogenous and exogenous regressors are uncorrelated; {opt validity}
tests that assumption, because violating it is what motivated the later
estimators.

{phang}
{cmd:method(2scope)} {hline 2} Yang, Qian & Xie (2025). Transforms the
exogenous regressors as well, regresses each P* on W* and uses the residual as
the copula term, so the correction is orthogonal to W by construction. The
first stage carries an intercept.

{phang}
{cmd:method(ima)} {hline 2} Haschka (2025a). 2sCOPE without an intercept in
the first stage, which is what the paper's derivation of rho requires. The two
are usually very close.

{phang}
{cmd:method(bmw)} {hline 2} Breitung, Mayer & Wied (2024). Inverts the order:
the first stage runs on the raw variables and the rank transform is applied to
its residuals. The identification requirement therefore falls on the
first-stage residuals, which is what {opt validity} tests, and their
Corollary 3.2 makes the textbook t statistic valid for testing rho = 0, so a
Durbin-Hausman-Wu test is reported next to the bootstrap one.

{phang}
{cmd:method(jams)} {hline 2} Liengaard et al. (2025). Lets the copula
structure differ across the categories of the discrete exogenous regressors;
see {opt conditional()}.


{marker examples}{...}
{title:Examples}

{pstd}Park & Gupta with two exogenous controls{p_end}
{phang2}{cmd:. copulaendog y price, exog(feature display) seed(1)}{p_end}

{pstd}The same model with the identification checks{p_end}
{phang2}{cmd:. copulaendog y price, exog(feature display) seed(1) validity}{p_end}

{pstd}2sCOPE, which does not need the uncorrelatedness assumption{p_end}
{phang2}{cmd:. copulaendog y price, exog(feature display) method(2scope) seed(1)}{p_end}

{pstd}BMW with a factor control and more replicates{p_end}
{phang2}{cmd:. copulaendog y price, exog(feature i.store) method(bmw) nboots(499) seed(1)}{p_end}

{pstd}JAMS with the copula structure varying over the stores{p_end}
{phang2}{cmd:. copulaendog y price, exog(feature i.store) method(jams) conditional(store) seed(1)}{p_end}

{pstd}Two endogenous regressors{p_end}
{phang2}{cmd:. copulaendog y price adspend, exog(feature) method(2scope) seed(1)}{p_end}

{pstd}Structural prediction and residual{p_end}
{phang2}{cmd:. predict yhat}{p_end}
{phang2}{cmd:. predict xi, residuals}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:copulaendog} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(nboots)}}bootstrap replicates actually used{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(rmse)}, {cmd:e(r2)}, {cmd:e(r2_a)}}augmented regression{p_end}
{synopt:{cmd:e(rmse_s)}, {cmd:e(r2_s)}}structural model{p_end}
{synopt:{cmd:e(icon_max)}}largest standard error inflation{p_end}
{synopt:{cmd:e(xi_skew)}, {cmd:e(xi_kurt)}, {cmd:e(xi_ad)}, {cmd:e(xi_ksp)}}shape
of the structural error{p_end}
{synopt:{cmd:e(a5_r2)}, {cmd:e(a5_F)}, {cmd:e(a5_p)}}joint test of
Assumption 5 ({cmd:pg} only){p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:copulaendog}{p_end}
{synopt:{cmd:e(method)}, {cmd:e(methodlab)}}estimator{p_end}
{synopt:{cmd:e(endogenous)}, {cmd:e(exogenous)}, {cmd:e(copnames)}}variable
groups{p_end}
{synopt:{cmd:e(cdf)}, {cmd:e(ties)}}copula transformation{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients and bootstrap covariance{p_end}
{synopt:{cmd:e(rho)}, {cmd:e(rho_se)}}endogeneity measure{p_end}
{synopt:{cmd:e(b_ols)}, {cmd:e(se_ols)}}uncorrected OLS on the same
resamples{p_end}
{synopt:{cmd:e(icon)}}standard error inflation{p_end}
{synopt:{cmd:e(diagnostics)}}skewness, kurtosis, AD, CvM, KS p and the two
boundary-condition flags{p_end}
{synopt:{cmd:e(dhw)}}Durbin-Hausman-Wu test ({cmd:bmw} only){p_end}
{synopt:{cmd:e(assumption5)}}corr(W, copula term) and Holm p values
({cmd:pg} only){p_end}


{marker author}{...}
{title:Author}

{pstd}
Girish Mallapragada{break}
Indiana University{break}
{browse "https://www.linkedin.com/in/girishmallapragada/":LinkedIn} {c |}
{browse "https://scholar.google.com/citations?user=CixA1fgAAAAJ&hl=en":Google Scholar}

{pstd}
This command is a port, developed with the assistance of Claude. The
estimators, and the reference code every one of them is derived from, are the
work of Rouven E. Haschka and Ashwin Malshe; see
{help copulaendog##references:References} below. Please cite their work, and
the paper behind the estimator you use, in anything this contributes to.

{pstd}
Bug reports and questions:{break}
{browse "https://github.com/girishm77/copulaendog_stata_python/issues"}


{marker references}{...}
{title:References}

{pstd}
The implementation this command is ported from:

{phang}
Haschka, R. E. 2026. {it:Copula-based endogeneity corrections in R.}
{browse "https://github.com/HashtagHaschka/Copula-based-endogeneity-corrections"}

{phang}
Malshe, A. {it:endogCopula: Endogeneity Corrections via Gaussian Copulas.}
{browse "https://github.com/ashgreat/endogCopula"}

{pstd}
The estimators:

{phang}
Becker, J.-M., D. Proksch, and C. M. Ringle. 2022. Revisiting Gaussian copulas
to handle endogenous regressors. {it:Journal of the Academy of Marketing
Science} 50: 46-66.

{phang}
Breitung, J., A. Mayer, and D. Wied. 2024. Asymptotic properties of
endogeneity corrections using nonlinear transformations. {it:The Econometrics
Journal} 27(3): 362-383.

{phang}
Haschka, R. E. 2025a. Robustness of copula-correction models in causal
analysis: Exploiting between-regressor correlation. {it:IMA Journal of
Management Mathematics} 36(1): 161-180.

{phang}
Liengaard, B. D., J.-M. Becker, M. Bennedsen, P. Heiler, L. N. Taylor, and
C. M. Ringle. 2025. Dealing with regression models' endogeneity by means of an
adjusted estimator for the Gaussian copula approach. {it:Journal of the Academy
of Marketing Science} 53: 279-299.

{phang}
Park, S., and S. Gupta. 2012. Handling endogenous regressors by joint
estimation using copulas. {it:Marketing Science} 31(4): 567-586.

{phang}
Polansky, A. M., and E. R. Baker. 2000. Multistage plug-in bandwidth selection
for kernel distribution function estimates. {it:Journal of Statistical
Computation and Simulation} 65: 63-80.

{phang}
Qian, Y., A. Koschmann, and H. Xie. 2025. A practical guide to endogeneity
correction using copulas. {it:Journal of Marketing.}

{phang}
Yang, F., Y. Qian, and H. Xie. 2025. Addressing endogeneity using a two-stage
copula generated regressor approach. {it:Journal of Marketing Research} 62(4):
601-623.
