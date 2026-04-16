{smcl}
{* *! version 1.0.0  31mar2026}{...}
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

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt id(varname)}}study identifier variable{p_end}
{synopt:{opt cov:ariates(varlist)}}study-level covariate(s) to include{p_end}

{syntab:Covariate targets}
{synopt:{opt sen:only}}covariates affect sensitivity only{p_end}
{synopt:{opt spe:only}}covariates affect specificity only{p_end}
{synopt:{it:default}}covariates affect both Se and Sp{p_end}

{syntab:Output}
{synopt:{opt level(#)}}confidence level; default is 95{p_end}
{synopt:{opt nog:raph}}suppress the bubble plot{p_end}
{synopt:{opt save:table(filename)}}save results as LaTeX file{p_end}
{synopt:{opt nois:ily}}show {cmd:meglm} iteration output{p_end}
{synoptline}

{pstd}
{opt senonly} and {opt speonly} are mutually exclusive.


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas metareg} extends the bivariate random-effects model for DTA
meta-analysis by adding study-level covariates that modify the mean
logit sensitivity and/or logit specificity:

{p 8}logit(Se{sub:i}) = {it:mu1} + {it:beta1} * X{sub:i} + u{sub:1i}{p_end}
{p 8}logit(Sp{sub:i}) = {it:mu2} + {it:beta2} * X{sub:i} + u{sub:2i}{p_end}

{pstd}
where X{sub:i} is a study-level covariate (continuous or binary).
By default, each covariate has separate effects on Se and Sp.
Use {opt senonly} or {opt speonly} to restrict effects to one parameter.

{pstd}
The model is fitted via Stata's {cmd:meglm} with binomial family,
logit link, and unstructured random effects for study-specific
intercepts on both disease-status equations.  This is the natural
extension of the Reitsma et al. (2005) bivariate model to include
covariates, following the framework of Harbord et al. (2007).


{marker options}{...}
{title:Options}

{phang}
{opt covariates(varlist)} specifies one or more study-level variables.
Continuous and binary covariates are both supported.  For categorical
covariates with >2 levels, create indicator variables first using
{cmd:tabulate, generate()}.

{phang}
{opt senonly} restricts covariate effects to sensitivity.  This is
appropriate when the covariate is hypothesised to affect disease
detection (e.g., test threshold, imaging resolution) but not
false-positive rates.

{phang}
{opt speonly} restricts covariate effects to specificity.

{phang}
{opt noisily} displays the full {cmd:meglm} iteration output.

{phang}
{opt savetable(filename)} writes the coefficient table as a LaTeX file.


{marker results}{...}
{title:Stored results}

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:e(ll)}}log-likelihood{p_end}
{synopt:{cmd:e(AIC)}}Akaike information criterion{p_end}
{synopt:{cmd:e(BIC)}}Bayesian information criterion{p_end}
{synopt:{cmd:e(N)}}number of studies{p_end}
{synopt:{cmd:e(ncov)}}number of covariates{p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:e(covariates)}}names of covariate variables{p_end}
{synopt:{cmd:e(cmd)}}{cmd:midas_metareg}{p_end}

{pstd}
All {cmd:meglm} estimation results are also available in {cmd:e()}.
Access individual coefficients with {cmd:_b[_cx_se_}{it:varname}{cmd:]}
and {cmd:_b[_cx_sp_}{it:varname}{cmd:]}.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
The model is implemented as a single {cmd:meglm} call on the long-format
data (2 rows per study: one for Se, one for Sp).  Covariates enter as
interaction terms with disease-status indicators:

{p 8}{cmd:_cx_se_}{it:X} = X * I(dis=1)    (effect on sensitivity){p_end}
{p 8}{cmd:_cx_sp_}{it:X} = X * I(dis=2)    (effect on specificity){p_end}

{pstd}
The likelihood ratio test comparing the meta-regression model with
the base model can be performed manually:

{phang2}{cmd:. midas mle tp fp fn tn, id(author)}{p_end}
{phang2}{cmd:. estimates store base}{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(year)}{p_end}
{phang2}{cmd:. lrtest base .}{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Single continuous covariate{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(year)}{p_end}

{pstd}Covariate affecting sensitivity only{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(threshold) senonly}{p_end}

{pstd}Multiple covariates with LaTeX output{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(year sample_size) savetable(tab_mr.tex)}{p_end}

{pstd}Show full estimation output{p_end}
{phang2}{cmd:. midas metareg tp fp fn tn, id(author) covariates(blinding) noisily}{p_end}


{title:References}

{phang}
Reitsma JB, et al. 2005. Bivariate analysis of sensitivity and
specificity produces informative summary measures in diagnostic reviews.
{it:J Clin Epidemiol} 58: 982-990.

{phang}
Harbord RM, et al. 2007. A unification of models for meta-analysis of
diagnostic test accuracy studies. {it:Biostatistics} 8: 239-251.


{title:Author}

{pstd}
Ben Adarkwa Dwamena, MD{break}
University of Michigan / BennyBeauBooks{break}
{browse "mailto:ben@bennybeaubooks.com":ben@bennybeaubooks.com}
{p_end}
