{smcl}
{* *! version 2.0 10oct2025}{...}
{viewerdialog step3 "dialog step3"}{...}
{viewerjumpto "Syntax" "step3##syntax"}{...}
{viewerjumpto "Description" "step3##description"}{...}
{viewerjumpto "Options" "step3##options"}{...}
{viewerjumpto "Example" "step3##example"}{...}
{viewerjumpto "Stored results" "step3##results"}{...}
{viewerjumpto "References" "step3##references"}{...}
{viewerjumpto "Authors" "step3##authors"}{...}

{p2colset 1 14 16 2}{...}
{p2col:{bf:step3} {hline 2}}Relating latent class membership to covariates and outcomes{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:step3} {it:{help varlist:varlist}}
{ifin},
{opt pr(stub)}
{opt lc:lass(newvar)}
[{opt bch}
{opt out:come}
{opt id(varname)}
{opt eqvar}
{opt b:ase(#)}
{opt rrr}
{opt l:evel(#)}
{opt d:etail}]

{marker description}{...}
{title:Description}

{pstd}
{cmd:step3} performs two bias-adjusted three-step methods to relate latent class membership to external variables: Maximum Likelihood (ML; Vermunt, 2010) and Bolck-Croon-Hagenaars (BCH; Bolck et al., 2004). The external variables can be either covariates (predictors of class membership) or distal outcomes (predicted by class membership).

{pstd}
The command adjusts for misclassification errors that arise in three-step approaches when observations are assigned to classes based on posterior probabilities from an initial latent class model.

{pstd}
The first step (estimating the latent class model and predicting posterior probabilities) must be done separately (e.g., with {help gsem_lclass_options:gsem} or {help fmm:fmm}). {cmd:step3} uses these predicted probabilities to construct a classification error matrix and fits the structural model via ML or BCH correction.

{marker options}{...}
{title:Options}

{phang}{opt pr(stub)} is required. It specifies the stub name of the posterior class membership probabilities from Step 1. Variables must be named as {it:stub}1, {it:stub}2, etc.

{phang}{opt lc:lass(newvar)} is required. The program will generate a new variable to store the modal class assignment.

{phang}{opt bch} specifies to use the BCH method; default is ML.

{phang}{opt out:come} specifies that the variables in {it:varlist} are distal outcomes. By default, they are treated as covariates. Categorical outcomes must be introduced by the {it:"i."} prefix.

{phang}{opt id(varname)} specifies the identifier variable for clustered standard errors.

{phang}{opt eqvar} assumes equal variance across classes (for ML with continuous outcomes); default is to assume unequal variance.

{phang}{opt b:ase(#)} sets the reference class; default is {opt b:ase(1)}.

{phang}{opt rrr} reports results as relative risk ratios.

{phang}{opt l:evel(#)} sets the confidence level; default is {opt l:evel(95)}.

{phang}{opt d:etail} displays additional information, including how many observations switch class from Step 1 to Step 3 (ML only).

{marker example}{...}
{title:Example}

{pstd}
In this example, we aim to infer an unobserved binary sex variable using height as a proxy, and examine its relationship with a continuous outcome variable, {cmd:y}.

{phang}{bf:1. Setup}

{phang2}{cmd:. webuse set https://califano.xyz/data}

{phang2}{cmd:. webuse height}

{phang}{bf:2. Estimate a 2-class mixture model on height (Step 1)}

{phang2}{cmd:. fmm 2: regress height}

{phang}{bf:3. Predict posterior class membership probabilities}

{phang2}{cmd:. predict cpost*, classposteriorpr}

{phang}{bf:4. Use the BCH method to assign each individual to their most likely class and estimate class-specific means of {cmd:y} (Steps 2 and 3)}

{phang2}{cmd:. step3 y, pr(cpost) lclass(W) outcome bch}

{phang}{bf:5. Use the ML method for the same task and inspect class stability}

{phang2}{cmd:. step3 y, pr(cpost) lclass(W) outcome detail}

{phang}{bf:6. Use {cmd:y} as a covariate to predict latent class membership, reporting results as odds ratios}

{phang2}{cmd:. step3 y, pr(cpost) lclass(W) rrr}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:step3} stores the following in {cmd:e()}:

{synoptset 20 tabbed}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(changed)}}= 1 if more than 20% of observations switched classes between Step 1 and Step 3, 0 otherwise (ML only){p_end}
{synopt:{cmd:e(cmd)}}{cmd:step3}{p_end}
{synopt:{cmd:e(analysis)}}combination of ML/BCH and covariate/distal outcome{p_end}
{synopt:{cmd:e(variance)}}equal/unequal variance assumed across classes (ML with continuous outcome only){p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance–covariance matrix{p_end}
{synopt:{cmd:e(D)}}classification error matrix{p_end}
{synopt:{cmd:e(invD)}}inverse of classification error matrix{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{marker references}{...}
{title:References}

{phang}
Bolck, A., Croon, M., & Hagenaars, J. (2004). Estimating latent structure models with categorical variables: One-step versus three-step estimators. {it:Political Analysis}, {it:12}(1), 3-27.

{phang}
Vermunt, J. K. (2010). Latent class modeling with covariates: Two improved three-step approaches. {it:Political Analysis}, {it:18}(4), 450–469.

{marker authors}{...}
{title:Authors}

{pstd}Giovanbattista Califano{p_end}
{pstd}University of Naples Federico II{p_end}
{pstd}Dept. of Agricultural Sciences{p_end}
{pstd}giovanbattista.califano@unina.it{p_end}

{pstd}Rosa Fabbricatore{p_end}
{pstd}University of Naples Federico II{p_end}
{pstd}Dept. of Economics and Statistics{p_end}
{pstd}rosa.fabbricatore@unina.it{p_end}  
