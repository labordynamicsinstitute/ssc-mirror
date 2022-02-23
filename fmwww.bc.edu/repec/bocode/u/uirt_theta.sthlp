{smcl}
{* *! version 1.1 2022.01.24}{...}
{viewerjumpto "Syntax" "uirt_theta##syntax"}{...}
{viewerjumpto "Description" "uirt_theta##description"}{...}
{viewerjumpto "Options" "uirt_theta##options"}{...}
{viewerjumpto "Examples" "uirt_theta##examples"}{...}
{viewerjumpto "Stored results" "uirt_theta##results"}{...}
{viewerjumpto "References" "uirt_theta##references"}{...}
{cmd:help uirt_theta}
{hline}

{title:Title}

{phang}
{bf:uirt_theta} {hline 2} Postestimation command of {helpb uirt} to add EAP or PVs

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:uirt_theta} [{it:newvar1} {it:newvar2}] [{cmd:,}{it:{help uirt_theta##options:options}}]

{pmore}
{it:newvar1} and {it:newvar2} are optional. If specified, the expected a posteriori (EAP) estimator of theta and its standard error 
will be added at the end of the dataset using {it:newvar1} and {it:newvar2} to name these new variables. 

{synoptset 24 tabbed}{p2colset 7 32 34 4} 
{marker options}{...}
{synopthdr :Options}
{synoptline}
{synopt:{opt eap}} create EAP estimator of theta and its standard error {p_end}
{synopt:{opt nip(#)}} number of GH quadrature points used when calculating EAP and its SE; default: nip(195){p_end}
{synopt:{opt pv(#)}} number of plausible values added to the dataset, default is pv(0) (no PVs added){p_end}
{synopt:{opt pvreg(str)}} define regression for conditioning PVs {p_end}
{synopt:{opt suf:fix(name)}} specify a suffix used in naming of EAP and PVs{p_end}
{synopt:{opt sc:ale(#,#)}} scale parameters (m,sd) of theta in reference group {p_end}
{synopt:{opt skipn:ote}} suppress adding notes to newly created variables{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:uirt_theta} is a postestimation command of {helpb uirt} that allows adding EAP point estimates of theta to the dataset.
Drawing plausible values (PVs) is also available; conditioning of PVs on ancillary variables is supported.


{marker options}{...}
{title:Options}

{phang}
{opt eap} adds the expected {it: a posteriori} (EAP) estimator of theta and its standard error at the end of the dataset.
These will be named "theta" and "se_theta" unless {opt suf:fix()} is specified. 
Using {opt eap} is redundant if {it:newvar1} and {it:newvar2} are provided.

{phang}
{opt nip(#)} sets the number of Gauss-Hermite quadrature points used when calculating EAP estimator of theta and its SE.
Default value is 195 which is an obvious overkill, but it does not consume much resources while
too low {opt nip()} values may lead to inadequate estimate of standard errors of EAP.

{phang}
{opt pv(#)} is used to declare the number of plausible values that are to be added to the dataset. 
Default value is 0 (no PVs added). 
The PVs will be named "pv_1",..., "pv_#" unless {opt suf:fix()} is specified.
The PVs are generated after the estimation is completed.
The general procedure involves two steps.
In the first step, # random draws, b*, of model parameters are taken from MVN distribution with means vector {cmd:e(b)} and covariance matrix {cmd:e(V)}.
In the second step, for each person, # independent MCMC chains are run according to procedure described by 
Patz & Junker (1999) with b* parameter draws treated as fixed. 
Finally, after a burn-in period, each of the PVs is drawn from a different MCMC chain.
Such procedure allows incorporating IRT model uncertainty in PV generation without the need of multilevel-structured MCMC, 
thus reducing the computational expense and avoiding the use of Bayesian priors for item parameters. 
Note that if some of the item parameters were fixed with {opt fix()} option of {cmd:uirt} the PVs will take no account 
of the uncertainty of estimation of these fixed parameters.
Additional {opt pvreg()} option allows to modify the procedure so that it includes conditioning by a latent regression.

{phang}
{opt pvreg(str)} is used to perform conditioning of plausible values on ancillary variables.
If other variables, than the ones used in defining the IRT model,
are to be used in the analyses performed with PVs, these variables need to be included in {opt pvreg()} option. 
Otherwise, the analyses will produce effects which are biased towards 0.
The syntax for {opt pvreg()} is the same as in defining the regression term in {helpb xtmixed},  e.g. pvreg(ses ||school:).
Note that multilevel modelling is allowed here.
If {opt pv()} is called without {opt pvreg()} the PVs for all observations within a group are generated with the same
normal prior distribution of ability with parameters taken from {cmd:e(group_par)}.
By including the {opt pvreg()} option the procedure of generating PVs is modified in such a way that after each MCMC step 
a regression of the ability on the variables provided by the user is performed by {cmd:xtmixed}. The {cmd:xtmixed}
model estimates are then used to recompute the priors.
Note that if some observations are excluded from {cmd:xtmixed} run (for example due to missing cases on any of the regressors)
these observations will not be conditioned.

{phang}
{opt suf:fix(name)} specifies a suffix used in naming new EAP and PVs variables.
If {it:newvar1} and {it:newvar2} are provided they will take precedence in naming EAP, however {opt suf:fix()} will still apply to the PVs.

{phang}
{opt sc:ale(#,#)} is used to change the scale of the latent trait for variables that are added to the dataset.
By default the EAP and the PVs are obtained accordingly to the group parameters that are reported in {cmd:e(group_par)}. 
Specifying {opt sc:ale(m,sd)} will rescale the latent trait so that the mean and the standard deviation in reference group are {it:m} and {it:sd}.
Note that because {opt sc:ale(m,sd)} acts on the latent trait variable level,
the EAP estimates will most probably have smaller standard deviation in the reference group than {it:sd} due to shrinkage.

{phang}
{opt skipn:ote} suppresses adding notes to newly created variables. Default behavior is to add notes.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse masc2} {p_end}

{pstd}Fit an IRT model with default settings of {helpb uirt} using items q1-q9 {p_end}
{phang2}{cmd:. uirt q*} {p_end}

{pstd}Add EAP point estimate of theta to data and its standard error with default names{p_end}
{phang2}{cmd:. uirt_theta , eap} {p_end}

{pstd}The same as above, but with user specified variable names{p_end}
{phang2}{cmd:. uirt_theta my_eap my_se_of_eap} {p_end}

{pstd}Add 5 unconditioned plausible values to data and use suffix "uncond" when naming them{p_end}
{phang2}{cmd:. uirt_theta , pv(5) suf(uncond)} {p_end}

{pstd}Add 5 plausible values to data but condition them on the {it:female} variable, use suffix "cond", and change scale to m=500 and sd=100{p_end}
{phang2}{cmd:. uirt_theta , pv(5) pvreg(i.female) suf(cond) scale(500,100)} {p_end}

{pstd}List contents of notes of newly created variables to inspect the comments that were added by {cmd:uirt_theta}{p_end}
{phang2}{cmd:. notes list} {p_end}


{marker results}{...}
{title:Stored results}

{syntab: {cmd: uirt_theta} does not store anything in r():}


{title:Author}

Bartosz Kondratek
everythingthatcounts@gmail.com


{marker references}{...}
{title:References}

{phang}
Patz, R. J., Junker, B. W. 1999.
A Straightforward Approach to Markov Chain Monte Carlo Methods for Item Response Models.
{it:Journal of Educational and Behavioral Statistics}, 24(2), 146{c -}178.

