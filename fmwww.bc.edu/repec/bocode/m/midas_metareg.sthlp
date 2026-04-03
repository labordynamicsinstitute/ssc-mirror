{smcl}
{* *! version 2.0.0  31mar2026}{...}
{vieweralsosee "[R] midas" "help midas"}{...}
{vieweralsosee "[R] midas subgroup" "help midas_subgroup"}{...}
{viewerjumpto "Syntax" "midas_metareg##syntax"}{...}
{viewerjumpto "Description" "midas_metareg##description"}{...}
{viewerjumpto "Options" "midas_metareg##options"}{...}
{viewerjumpto "Stored results" "midas_metareg##results"}{...}
{viewerjumpto "Examples" "midas_metareg##examples"}{...}
{viewerjumpto "Methods" "midas_metareg##methods"}{...}

{title:Title}

{phang}
{bf:midas metareg} {hline 2} Bivariate meta-regression for DTA meta-analysis


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:midas metareg} {it:tp fp fn tn}
{cmd:,} {opt id(varname)} {opt cov:ariates(varlist)}
[{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt id(varname)}}study identifier variable{p_end}
{synopt:{opt cov:ariates(varlist)}}study-level covariate(s){p_end}

{syntab:Covariate targets}
{synopt:{opt sen:only}}covariates affect sensitivity only{p_end}
{synopt:{opt spe:only}}covariates affect specificity only{p_end}
{synopt:{it:default}}covariates affect both Se and Sp{p_end}

{syntab:Binary SROC subgroup estimator}
{synopt:{opt subest:imator(name)}}estimator for subgroup fits; default {cmd:mle}{p_end}
{synopt:}{it:name} is one of {cmd:mle}, {cmd:inla}, or {cmd:hmc}{p_end}

{syntab:INLA options (when subestimator(inla))}
{synopt:{opt rpath(string)}}full path to {cmd:Rscript} executable{p_end}

{syntab:HMC options (when subestimator(hmc))}
{synopt:{opt standir(string)}}path to CmdStan installation{p_end}
{synopt:{opt modelfile(string)}}Stan model filename{p_end}
{synopt:{opt outputfile(string)}}HMC output file prefix{p_end}
{synopt:{opt chains(#)}}number of MCMC chains; default {cmd:4}{p_end}
{synopt:{opt warmup(#)}}warmup iterations per chain; default {cmd:1000}{p_end}
{synopt:{opt iter(#)}}total iterations per chain; default {cmd:10000}{p_end}
{synopt:{opt thin(#)}}thinning interval; default {cmd:10}{p_end}
{synopt:{opt seed(#)}}random seed; default {cmd:12345}{p_end}
{synopt:{opt subcov:ariance(name)}}prior covariance family for HMC{p_end}

{syntab:Output}
{synopt:{opt level(#)}}confidence level; default {cmd:95}{p_end}
{synopt:{opt nog:raph}}suppress graphical output{p_end}
{synopt:{opt save:table(filename)}}save results as LaTeX{p_end}
{synopt:{opt nois:ily}}show {cmd:meglm} iteration output{p_end}
{synoptline}

{pstd}
{opt senonly} and {opt speonly} are mutually exclusive.


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas metareg} extends the bivariate random-effects model by adding
study-level covariates:

{p 8}logit(Se{sub:i}) = mu{sub:1} + beta{sub:1} * X{sub:i} + u{sub:1i}{p_end}
{p 8}logit(Sp{sub:i}) = mu{sub:2} + beta{sub:2} * X{sub:i} + u{sub:2i}{p_end}

{pstd}
The joint model is fitted via {cmd:meglm} with binomial family, logit link,
and unstructured random effects.  This is the natural extension of
Reitsma et al. (2005).

{pstd}
{bf:Graphical output} depends on the covariate type:

{phang2}{bf:Continuous covariates}: Bubble plot with study-level Se/Sp
points sized by sample size, overlaid with predicted regression lines.{p_end}

{phang2}{bf:Binary covariates} (exactly 2 levels): Comparative SROC plot
with summary operating points, 95% confidence ellipses (solid), and 95%
prediction ellipses (dashed) for each subgroup.  The prediction ellipses
use the residual between-study heterogeneity (tau-squared) from the joint
meta-regression model.{p_end}

{pstd}
The binary SROC plot fits a separate bivariate model per subgroup to
obtain subgroup-specific summary points and confidence regions.  By
default these use {cmd:meglm} (MLE), but for small subgroups where MLE
may not converge, you can specify {opt subestimator(inla)} or
{opt subestimator(hmc)} to use R-INLA or CmdStan instead.


{marker options}{...}
{title:Options}

{dlgtab:Covariate targets}

{phang}
{opt senonly} restricts covariates to affect sensitivity only.
The specificity equation retains only its intercept.

{phang}
{opt speonly} restricts covariates to affect specificity only.

{dlgtab:Binary SROC subgroup estimator}

{phang}
{opt subestimator(name)} specifies the estimation method for the
per-subgroup fits in the binary SROC plot.  This does NOT affect the
joint meta-regression (which always uses {cmd:meglm}).

{phang2}{cmd:mle} (default) fits each subgroup via {cmd:meglm}.  Fast but
may fail for small k (< 8 studies).{p_end}
{phang2}{cmd:inla} fits each subgroup via {cmd:midas inla}.  Robust for
small k; requires R + R-INLA.{p_end}
{phang2}{cmd:hmc} fits each subgroup via {cmd:midas hmc}.  Robust for
small k; requires CmdStan.{p_end}

{phang}
{opt rpath(string)} specifies the full path to the {cmd:Rscript}
executable.  Required when {cmd:subestimator(inla)} is specified.

{phang}
{opt standir(string)} specifies the CmdStan installation path.
Required when {cmd:subestimator(hmc)} is specified.

{phang}
{opt subcovariance(name)} specifies the prior covariance family for
HMC subgroup fits (e.g., {cmd:cholesky}, {cmd:iwishart}).

{dlgtab:Output}

{phang}
{opt nograph} suppresses both bubble plots and SROC plots.

{phang}
{opt savetable(filename)} writes a LaTeX table with regression
coefficients, standard errors, z-statistics, p-values, and 95% CIs.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:midas metareg} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(ll)}}log-likelihood{p_end}
{synopt:{cmd:e(AIC)}}Akaike information criterion{p_end}
{synopt:{cmd:e(BIC)}}Bayesian information criterion{p_end}
{synopt:{cmd:e(N)}}number of studies{p_end}
{synopt:{cmd:e(ncov)}}number of covariates{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(covariates)}}covariate variable names{p_end}
{synopt:{cmd:e(estimator)}}{cmd:metareg}{p_end}
{synopt:{cmd:e(package)}}{cmd:midas}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:midas_metareg}{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup:{p_end}
{phang2}{cmd:. use http://fmwww.bc.edu/repec/bocode/m/midas_example_data.dta, clear}{p_end}
{phang2}{cmd:. label define lbl 0 "Not blinded" 1 "Blinded"}{p_end}
{phang2}{cmd:. label values blinded lbl}{p_end}

{pstd}Continuous covariate (bubble plot):{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(year)}{p_end}

{pstd}Binary covariate (comparative SROC with MLE subgroups):{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(blinded)}{p_end}

{pstd}Binary covariate with INLA subgroup fits (small-k robust):{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(patient) subestimator(inla) rpath("C:/Program Files/R/R-4.5.2/bin/x64/Rscript.exe")}{p_end}

{pstd}Binary covariate with HMC subgroup fits:{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(period) subestimator(hmc) standir("C:/Users/dwame/.cmdstan/cmdstan-2.38.0") modelfile("midas.stan") outputfile("mr")}{p_end}

{pstd}Sensitivity-only regression:{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(qscore) senonly}{p_end}

{pstd}Multiple covariates (no graph):{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(year qscore pmet) nograph}{p_end}

{pstd}Save LaTeX table:{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(blinded) savetable(tables/tab_metareg_blind.tex)}{p_end}

{pstd}Likelihood ratio test (metareg vs base MLE):{p_end}
{phang2}{cmd:. midas mle tp fp fn tn, id(author)}{p_end}
{phang2}{cmd:. estimates store base}{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(blinded)}{p_end}
{phang2}{cmd:. di "LRT chi2 = " 2*(e(ll) - el("base","ll")) " (df=2, p=" chi2tail(2, 2*(e(ll)-el("base","ll"))) ")"}{p_end}


{marker methods}{...}
{title:Methods}

{pstd}
The meta-regression model adds fixed covariate effects to the bivariate
GLMM.  The joint model is:

{p 8}y{sub:ij} | u{sub:i} ~ Binomial(n{sub:ij}, pi{sub:ij}){p_end}
{p 8}logit(pi{sub:ij}) = mu{sub:j} + beta{sub:j}*X{sub:i} + u{sub:ij}{p_end}
{p 8}(u{sub:i1}, u{sub:i2})' ~ N(0, Sigma){p_end}

{pstd}
where j=1 for sensitivity, j=2 for specificity.  The residual
heterogeneity tau-squared is the variance of u after adjusting for X.

{pstd}
For the binary SROC plot, confidence ellipses use the fixed-effects VCE
of (logit Se, logit Sp) per subgroup.  Prediction ellipses add the
residual tau-squared from the joint model.  Both are computed on the
logit scale via Cholesky decomposition with chi-squared(2, 0.95) = 5.991
scaling, then transformed to probability/FPR space through invlogit.

{hline}

{title:References}

{phang}Reitsma JB, et al. (2005). Bivariate analysis of sensitivity and
specificity produces informative summary measures in diagnostic reviews.
{it:Journal of Clinical Epidemiology} 58:982-990.{p_end}

{phang}Harbord RM, et al. (2007). A unifying model for meta-analysis of
diagnostic accuracy studies. {it:Biostatistics} 8:239-251.{p_end}

{hline}

{title:Also see}

{psee}
{helpb midas}, {helpb midas_subgroup}, {helpb midas_mle}, {helpb meglm}

{title:Author}

{pstd}
Ben Adarkwa Dwamena, MD{break}
University of Michigan / BennyBeauBooks{break}
