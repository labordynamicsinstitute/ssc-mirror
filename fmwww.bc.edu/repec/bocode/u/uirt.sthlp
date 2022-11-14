{smcl}
{* *! version 2.2.1 2022.11.13}{...}
{viewerjumpto "Syntax" "uirt##syntax"}{...}
{viewerjumpto "Postestimation commands" "uirt##postestimation"}{...}
{viewerjumpto "Description" "uirt##description"}{...}
{viewerjumpto "Options" "uirt##options"}{...}
{viewerjumpto "Examples" "uirt##examples"}{...}
{viewerjumpto "Stored results" "uirt##results"}{...}
{viewerjumpto "References" "uirt##references"}{...}
{cmd:help uirt}
{hline}

{title:Title}

{phang}
{bf:uirt} {hline 2} Stata module to fit unidimensional Item Response Theory models

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:uirt} {varlist} {ifin} [{cmd:,} {it:{help uirt##options:options}}]

{synoptset 24 tabbed}{p2colset 7 32 34 4}
{marker options}{...}
{synopthdr :Options}
{synoptline}
{syntab:Models}{synoptset 25 }
{synopt:{opt pcm(varlist)}} items to fit with the Partial Credit Model {p_end}
{synopt:{opt gpcm(varlist)}} items to fit with the Generalized Partial Credit Model{p_end}
{synopt:{opt gue:ssing(varlist [,opts])}} items to attempt fitting with the 3-Parameter Logistic Model {synoptset 25 tabbed}{p_end}
{synopt:{it:opts:}}{p_end}
{synopt:{opt att:empts(#)}} maximum number of attempts to fit a 3PLM; default: attempts(5) {p_end}
{synopt:{opt lr:crit(#)}} significance level for LR test comparing 2PLM against 3PLM; default: lrcrit(0.05) {p_end}

{syntab:Multi-group}{synoptset 25 }
{synopt:{opt gr:oup(varname [,opts])}} set group membership variable {synoptset 25 tabbed}{p_end}
{synopt:{it:opts:}}{p_end}
{synopt:{opt ref:erence(#)}} set the value of reference group {p_end}
{synopt:{opt dif(varlist)}} items to test for differential item functioning (DIF) {p_end}
{synopt:{opt free}} free the estimation of parameters of reference group {p_end}
{synopt:{opt slow}} suppress a speed-up of EM for the multi-group estimation{p_end}

{syntab:ICC}{synoptset 25 }
{synopt:{opt icc(varlist [,opts])}} items to create ICC graphs {synoptset 25 tabbed}{p_end}
{synopt:{it:opts:}}{p_end}
{synopt:{opt bins(#)}} number of ability intervals for observed proportions; default: bins(100) {p_end}
{synopt:{opt noo:bs}} suppress plotting observed proportions{p_end}
{synopt:{opt pv}} use plausible values to compute observed proportions; default is to use numerical integration {p_end}
{synopt:{opt pvbin(#)}} number of plausible values in each bin; default: pvbin(10000) {p_end}
{synopt:{opt c:olors(str)}} list of colors to override default colors of ICC lines {p_end}
{synopt:{opth tw(twoway_options)}} twoway graph options to override default graph layout {p_end}
{synopt:{opt f:ormat(str)}} file format for ICC graphs (png|gph|eps); default: format(png) {p_end}
{synopt:{opt pref:ix(str)}} set the prefix of file names {p_end}
{synopt:{opt suf:fix(str)}} set the suffix of file names {p_end}
{synopt:{opt cl:eargraphs}} suppress storing of graphs in Stata memory {p_end}


{syntab:Item-fit}{synoptset 25 }
{synopt:{opt chi2w(varlist [,opts])}} items to compute chi2W item-fit statistic {synoptset 25 tabbed}{p_end}
{synopt:{it:opts:}}{p_end}
{synopt:{opt bins(#)}} number of ability intervals for computation of chi2W {p_end}
{synopt:{opt npqm:in(#)}} minimum expected number of observations in ability intervals (NPQ); default: npqmin(20){p_end}
{synopt:{opt npqr:eport}} report information about minimum NPQ in ability intervals {synoptset 25 }{p_end}
{synopt:{opt sx2(varlist [,opts])}} dichotomous items to compute S-X2 item-fit statistic {synoptset 25 tabbed}{p_end}
{synopt:{it:opts:}}{p_end}
{synopt:{opt minf:req(#)}} minimum expected number of observations in ability intervals (NP and NQ); default: minf(1){p_end}

{syntab:Theta & PVs}{synoptset 25 }
{synopt:{opt th:eta([nv1 nv2] [,opts])}} declare variables to be added to the dataset {synoptset 25 tabbed}{p_end}
{synopt:{it:opts:}}{p_end}
{synopt:{opt eap}} create EAP estimator of theta and its standard error {p_end}
{synopt:{opt nip(#)}} number of GH quadrature points used when calculating EAP and its SE; default: nip(195){p_end}
{synopt:{opt pv(#)}} number of plausible values added to the dataset, default is pv(0) (no PVs added){p_end}
{synopt:{opt pvreg(str)}} define regression for conditioning PVs {p_end}
{synopt:{opt suf:fix(name)}} specify a suffix used in naming of EAP, PVs and ICC graphs {p_end}
{synopt:{opt sc:ale(#,#)}} scale parameters (m,sd) of theta in reference group {p_end}
{synopt:{opt skipn:ote}} suppress adding notes to newly created variables{p_end}

{syntab:Fixed and starting values}{synoptset 25 }
{synopt:{opt fix([opts])}} declare parameters to fix {synoptset 25 tabbed}{p_end}
{synopt:{it:opts:}}{p_end}
{synopt:{opt prev}} fix item parameters on estimates from previous {cmd:uirt} run (active estimation results)  {p_end}
{synopt:{opt from(name)}} fix item parameters on estimates from {cmd:uirt} run that is stored in memory {p_end}
{synopt:{opt used:ist}} fix group parameters on estimates from previous {cmd:uirt} run; used with {it:prev} or {it:from()}{p_end}
{synopt:{opt i:matrix(name)}} matrix with item parameters to be fixed {p_end}
{synopt:{opt d:matrix(name)}} matrix with group parameters to be fixed {p_end}
{synopt:{opt c:matrix(name)}} matrix with item category values {p_end}
{synopt:{opt miss}} allow imatrix() to have missing entries {synoptset 25 }{p_end}
{synopt:{opt init([opts])}} declare starting values {synoptset 25 tabbed}{p_end}
{synopt:{it:opts:}}{p_end}
{synopt:{opt prev}} initiate item parameters on estimates from previous {cmd:uirt} run (active estimation results)  {p_end}
{synopt:{opt from(name)}} initiate item parameters on estimates from {cmd:uirt} run that is stored in memory {p_end}
{synopt:{opt used:ist}} initiate group parameters on estimates from previous {cmd:uirt} run; used with {it:prev} or {it:from()}{p_end}
{synopt:{opt i:matrix(name)}} matrix with starting values of item parameters{p_end}
{synopt:{opt d:matrix(name)}} matrix with starting values of group parameters{p_end}
{synopt:{opt miss}} allow imatrix() to have missing entries {p_end}

{syntab:EM control}{synoptset 25 }
{synopt:{opt nip(#)}} number of GH quadrature points used in EM algorithm; default: nip(51){p_end}
{synopt:{opt nit(#)}} maximum number of iterations of EM algorithm; default: nit(100) {p_end}
{synopt:{opt crit_ll(#)}} stopping rule - relative change in logL between EM iterations; default: crit_ll(1e-9) {p_end}
{synopt:{opt crit_par(#)}} stopping rule - maximum absolute change in parameter values between EM iterations; default: crit_par(1e-4) {p_end}
{synopt:{opt an:egative}} allow items with negative discrimination {p_end}
{synopt:{opt err:ors(str)}} method for computation of standard errors (cdm|rem|sem|cp); default: err(cdm){p_end}
{synopt:{opt pr:iors(varlist [,opts])}} dichotomous items to estimate with priors {synoptset 25 tabbed}{p_end}
{synopt:{it:opts:}}{p_end}
{synopt:{opt a:normal(#,#)}} parameters of normal prior for discrimination parameter {p_end}
{synopt:{opt b:normal(#,#)}} parameters of normal prior for difficulty parameter {p_end}
{synopt:{opt c:beta(#,#)}} parameters of beta prior for pseudo-guessing parameter {p_end}

{syntab:Reporting}{synoptset 25 }
{synopt:{opt not:able}} suppress coefficient table{p_end}
{synopt:{opt noh:eader}} suppress model summary{p_end}
{synopt:{opt tr:ace(#)}} control log display after each iteration; 0 - suppress; 1 - normal (default); 2 - detailed{p_end}
{synoptline}

{marker postestimation}{...}
{title:Postestimation commands}

{pstd}
Several of {cmd:uirt} options are also available as separate postestimation commands, 
so it is possible to use them after {cmd:uirt} model parameters are estimated.
Running these postestimation commands only once after {cmd:uirt} may take more time to execute than invoking them as {cmd:uirt} options. 
But time is surely saved if you anticipate repeating these postestimation commands multiple times after a given uirt run.

{synopthdr :Command}
{synoptline}
{synopt :{helpb uirt_theta}} add EAP estimate of theta or draw plausible values{p_end}
{synopt :{helpb uirt_icc}} create ICC plots and perform graphical item-fit analysis{p_end}
{synopt :{helpb uirt_dif}} perform DIF analysis (two-group models){p_end}
{synopt :{helpb uirt_chi2w}} compute chi2W item-fit statistic{p_end}
{synopt :{helpb uirt_sx2}} compute S-X2 item-fit statistic (dichotomous items){p_end}
{synopt :{helpb uirt_esf}} create expected score function plots{p_end}
{synopt :{helpb uirt_inf}} create information function plots{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:uirt} is a Stata module for estimating variety of unidimensional IRT models (2PLM, 3PLM, GRM, PCM and GPCM).
It features multi-group modelling, DIF analysis, item-fit analysis
and generating plausible values (PVs) conditioned via latent regression.
{cmd:uirt} implements the EM algorithm (Dempster, Laird & Rubin, 1977)
in the form of marginal maximum likelihood estimation (MML) proposed by Bock & Aitkin (1981)
with normal Gauss-Hermite quadrature.
LR test is used for DIF testing and model-based P-DIF effect size measures are provided (Wainer, 1993).
Generating PVs is performed by adapting a MCMC method
developed for IRT models by Patz & Junker (1999).
Observed response proportions are plotted against the item characteristic curves to allow for detailed graphical item fit analysis.
Two item-fit statistics are available: S-X2 by Orlando and Thissen (2000) and chi2W developed by the author (Kondratek, 2022).


{marker options}{...}
{title:Options}

{dlgtab:Models}

{pstd}
By default, {cmd:uirt} will fit the 2-Parameter Logistic Model to all items that are detected to be dichotomous,
and the Samejima's Graded Response Model to all items that are detected to have more than two responses.
Options {opt pcm()}, {opt gpcm()}, {opt guessing()} are used if one wishes to use other models. Hybrid models are allowed.

{phang}
{opt pcm(varlist)} is used to provide a list of items to fit with the Partial Credit Model.
If PCM is used a common discrimination parameter is estimated for all PCM items.
When pcm(*) is typed all items declared in main list of items are fitted with PCM.

{phang}
{opt gpcm(varlist)} is used to provide a list of items to fit with the Generalized Partial Credit Model.
If item is dichotomous, it will be reported as 2PLM in the output (2PLM and GPCM are the same for dichotomous items).
When qpcm(*) is typed all items declared in main list of items are fitted with GPCM.

{phang}
{opt gue:ssing(varlist[,opts])} is used to provide a list of items to attempt fitting a 3-Parameter Logistic Model.
Items which are detected to have more than two response categories are automatically excluded from the list.
The pseudo-guessing parameter of the 3PL model is hard to estimate
(especially for easy items or small sample sizes) and often leads to convergence problems.
In order to circumvent this, for each 3PL-candidate item {cmd:uirt} starts with a 2PL model and
performs multiple attempts of fitting the 3PL model instead of 2PL.
The 3PL attempts are followed by checks on parameter behavior
with two criteria for deciding whether to keep the item 2PLM or to go with 3PLM.
The first criterion is convergence - an item stays 2PL if the parameter estimates change too rapidly,
the pseudo-guessing goes negative, the discrimination parameter goes to 0 or negative etc.
The second criterion is a result of a "LR test" after single EM iteration
- if the model likelihood does not improve significantly the item stays 2PL.
During each attempt {cmd:uirt} will print a note if either LR or convergence criterion resulted in an item staying 2PL.
Number of attempts of fitting a 3PL model is controlled by {opt att:empts()}
and the LR sensitivity is controlled by {opt lr:crit()}.
Note that this is an exploratory procedure.
Also note that uirt allows user to declare priors for the pseudo-guessing parameters within the {opt priors()} option.

{pmore}
{opt att:empts(#)} is a sub-option of {opt gue:ssing()};
maximum number of attempts to fit a 3PLM model to items specified in {opt guessing(varlist)}.
The default value is attempts(5).

{pmore}
{opt lr:crit(#)} is a sub-option of {opt gue:ssing()};
significance level criterion for "LR test" verifying whether 3PLM fits better than 2PLM on item level.
If test is negative the item stays 2PLM and a note is printed. Default value is {opt lr:crit(0.05)}.
Specifying value of 1 will suppress LR testing and rejection of 3PLM on the basis of such procedure will not be performed.
Note that "LR test" is performed after only one EM cycle hence not being a "proper" LR test.
This procedure is more conservative that the actual LR test (performed after complete convergence of the EM algorithm) would be.


{dlgtab:Multi-group}

{phang}
{opt gr:oup(varname [,opts])} sets the variable defining group membership for multi-group IRT models.
Grouping variable must be numeric.
There are multiple sub-options of {opt gr:oup()}..

{pmore}
{opt ref:erence(#)} is a sub-option of {opt gr:oup()}; sets the reference group value. 
If not specified, the reference group is set on the lowest value of the grouping variable. 

{pmore}
{opt dif(varlist)} is a sub-option of {opt gr:oup()};
it is used to provide the list of items to test for differential item functioning (DIF).
For each of the items specified in dif() a 2-group model with common item parameters in both groups
is compared against a model with group-specific parameters for the item under scrutiny.
Statistical significance of DIF is verified by a LR test.
Effect measures are computed on the observed score metric (P-DIF) by subtracting expected mean scores of an item
under each of the group-specific item parameter estimates (Wainer, 1993).
Namely, P-DIF|GR=E(parR,GR)-E(parF,GR), where GR indicates that the reference group distribution was used for integration
and parR and parF stand for item parameters estimated in GR and GF respectively. Analogous P-DIF|GF measure is also computed.
DIF significance and effect size information is stored in {cmd:e(dif_results)}. 
Group-specific item parameter estimates are stored in {cmd:e(dif_item_par_GR)} and {cmd:e(dif_item_par_GF)}.
Calling dif() will also result in plotting graphs with group-specific ICCs and PDFs, which are saved in the working directory.
When dif(*) is typed DIF analysis is performed on all items declared in main list of items.

{pmore}
{opt free} is a sub-option of {opt gr:oup()};
it frees the estimation of parameters of reference group. 
Using this option requires fixing parameters of at least one item in order to identify the model.

{pmore}
{opt slow} is a sub-option of {opt gr:oup()}; it suppresses a speed-up of EM for the multi-group estimation.
By default, the GH quadrature in {cmd:uirt} is updated within the EM cycle, just after iteration of group parameters is done.
This speeds-up the convergence of the algorithm but, in some cases, may lead to log-likelihood increase. 
Try using this option if you encounter such a problem in a multi-group model.


{dlgtab:ICC}

{phang}
{opt icc(varlist [,opts])} is used to provide a list of items for which ICC graphs are plotted.
When icc(*) is typed ICC graphs are plotted for all items declared in main list of items.
Note that if ICC graphs for such items are already saved in the working directory under default names they will be overwritten.
If you do not want to overwrite previous ICCs change the working directory or rename the existing files.

{pmore}
If {cmd:uirt} is asked to plot ICCs it will, by default, superimpose observed proportions against the ICC curves to enable a graphical item-fit assessment.
The observed proportions are computed after quantile-based division of the distribution of latent variable.
Item response of a single person is included simultaneously into many intervals (bins) of theta with probability
proportional to the density of {it: a posteriori} latent trait distribution of that person in each bin.
Default method uses definite numerical integration, but after adding a sub-option {opt pv} plausible values (PVs) will be employed to achieve this task.
Plotting observed proportions is controlled by {opt bins()} and {opt pvbin()}, it can be also turned off by {opt noobs}. 
Default look of graphs can be overridden by sub-options: {opt c:olors()} and {opt tw()}.

{pmore}
{opt bins(#)} is a sub-option of {opt icc()};
it sets the number of intervals the distribution of ability is split into
when calculating observed proportions of responses. Default value is bins(100).

{pmore}
{opt pv} is a sub-option of {opt icc()};
it changes the default method of computing observed proportions from definite numerical integration to Monte Carlo integration
with unconditioned PVs. It involves more CPU time, introduces variance due to sampling of PVs, 
but takes the uncertainty in estimation of IRT model parameters into account.

{pmore}
{opt pvbin(#)} is a sub-option of {opt icc()};
it sets the number of plausible values used for computing observed proportions of responses
within each interval of theta. Default value is pvbin(10000).

{pmore}
{opt noo:bs} is a sub-option of {opt icc()};
it suppresses plotting observed proportions.

{pmore}
{opt c:olors(str)} is a sub-option of {opt icc()};
it can be used to override the default Munsell color system used for ICC lines. It requires a list of color names separated by spaces.
The first color in the list applies to the pseudo-guessing parameter of 3PLM - it must be declared even if there are no 3PLM items in the model.

{pmore}
{opth tw(twoway_options)} is a sub-option of {opt icc()};
it is used to add user-defined twoway graph options to override the default graph layout, like: {opt xtitle()} or {opt scheme()} etc.

{pmore}
{opt f:ormat(str)} is a sub-option of {opt icc()};
it specifies the file format in which the ICC graphs are saved (png|gph|eps).
Default value is format(png).
This option influences also the graphs created after asking for DIF analysis.

{pmore}
{opt pref:ix(str)} is a sub-option of {opt icc()};
it used to define a string that is added at the beginning of the names of saved files.
Default value is prefix(ICC).

{pmore}
{opt suf:fix(str)} is a sub-option of {opt icc()};
it adds a user-defined string at the end of the names of saved files.
Default behavior is not to add any suffix.

{pmore}
{opt cl:eargraphs} is a sub-option of {opt icc()};
it is used to suppress the default behavior of storing all ICC graphs in Stata memory. 
After specifying this, all graphs are still saved in the current working directory, but only the last graph is active in Stata. 


{dlgtab:Item-fit}

{pstd}
{cmd:uirt} allows computing two types of item fit statistics. In single group setting, when there is enough dichotomously scored items with no missing responses,
item-fit can be assessed with classical S-X2 statistic proposed by Orlando and Thissen (2000).
The second available item-fit statistic, chi2W, is more general and can be applied to incomplete data and all IRT models handled by {cmd:uirt}.

{phang}
{opt chi2w(varlist [,opts])} is used to provide a list of items to compute chi2W item-fit statistic.
When chi2w(*) is typed the chi2W item-fit statistic is computed for all items declared in main list of items.
chi2W is a Wald-type test statistic that compares the observed and expected item mean scores over a set of ability bins.
The observed and expected scores are weighted means with weights being {it: a posteriori} density of person's ability within the bin 
- likewise as in the approach used to compute observed proportions in ICC plots.
Properties of chi2W have been examined for dichotomous items, Type I error rate was close to nominal and it exceeded S-X2 in statistical power (Kondratek, 2022).
Behavior of chi2W in case of polytomous items, as for the time of this {cmd:uirt} release, has not been researched. 
The results are stored in {cmd:e(item_fit_chi2W)}.
{opt chi2w()} comes with several sub-options:

{pmore}
{opt bins(#)} is a sub-option of {opt chi2w()};
it is used to set the number of ability intervals for computation of chi2W. 
Default settings depend on the item model and number of freely estimated parameters for the item being tested.
In general, the default is either {opt bins(3)} or a minimal number of intervals allowing for 1 degree of freedom
after accounting for the number of estimated item parameters.

{pmore}
{opt npqm:in(#)} is a sub-option of {opt chi2w()};
it sets a minimum for NPQ integrated over any ability interval, where:
N is the number of observations,
P is the expected item mean,
and Q=(max_item_score-P).
Larger NPQ values are associated with better asymptotics of chi2W. 
If NPQ for a given ability bin is smaller than the value declared in {opt npqm:in(#)} {cmd:uirt} will decrease the number of bins for that item.
Default value is {opt npqm:in(20)}.

{pmore}
{opt npqr:eport} is a sub-option of {opt chi2w()};
it will add a column to {cmd:e(item_fit_chi2W)} with information about minimum NPQ in ability intervals.

{phang}
{opt sx2(varlist [,opts])} is used to provide a list of dichotomous items to compute S-X2 item-fit statistic, as described in Orlando and Thissen (2000).
When sx2(*) is typed the S-X2 item-fit statistic is computed for all items declared in main list of items. S-X2 cannot be used in multigroup setting. 
The number-correct score used for grouping is obtained from dichotomous items - if polytomous items are present, they are ignored in computation of S-X2.
If a dichotomous item has missing responses, it is also ignored in computation of S-X2. The results are stored in {cmd:e(item_fit_SX2)}.

{pmore}
{opt minf:req(#)} is a sub-option of {opt sx2()};
it sets a minimum for both NP and NQ integrated over any ability interval, where:
N is the number of observations,
P is the expected item mean, and Q=(1-P).
Default value is {opt minf:req(1)}.


{dlgtab:Theta & PVs}

{phang}
{opt th:eta([newvar1 newvar2] [,opts])} is used to provide specification on ability variables that are to be added to the dataset.
{it:newvar1} and {it:newvar2} are optional. If specified, the expected a posteriori (EAP) estimator of theta and its standard error
will be added at the end of the dataset using {it:newvar1} and {it:newvar2} to name these new variables. 
The following sub-options are available for {opt theta()}:

{pmore}
{opt eap} is a sub-option of {opt th:eta()};
it will add the expected {it: a posteriori} (EAP) estimator of theta and its standard error at the end of the dataset.
These will be named "theta" and "se_theta" unless {opt suf:fix()} is specified.
Using {opt eap} is redundant if {it:newvar1} and {it:newvar2} are provided.

{pmore}
{opt nip(#)} is a sub-option of {opt th:eta()};
it sets the number of Gauss-Hermite quadrature points used when calculating EAP estimator of theta and its SE.
Default value is 195 which is an obvious overkill, but it does not consume much resources while
too low {opt nip()} values may lead to inadequate estimate of standard errors of EAP.

{pmore}
{opt pv(#)} is a sub-option of {opt th:eta()};
it is used to declare the the number of plausible values that are to be added to the dataset. 
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
Note that if some of the item parameters are fixed with {opt fix()} option the PVs will take no account 
of the uncertainty of estimation of these fixed parameters.
Additional {opt pvreg()} sub-option allows to modify the procedure so that it includes conditioning by a latent regression.

{pmore}
{opt pvreg(str)}  is a sub-option of {opt th:eta()};
it is used to perform conditioning of plausible values on ancillary variables.
If other variables, than the ones used in defining the IRT model,
are to be used in the analyses performed with PVs, these variables need to be included in {opt pvreg()} sub-option. 
Otherwise, the analyses will produce effects which are biased towards 0.
The syntax for {opt pvreg()} is the same as in defining the regression term in {helpb xtmixed},  e.g. pvreg(ses ||school:).
Note that multilevel modelling is allowed here.
If {opt pv()} is called without {opt pvreg()} the PVs for all observations within a group are generated with the same
normal prior distribution of ability with parameters taken from {cmd:e(group_par)}.
By including the {opt pvreg()} sub-option the procedure of generating PVs is modified in such a way that after each MCMC step 
a regression of the ability on the variables provided by the user is performed by {cmd:xtmixed}. The {cmd:xtmixed}
model estimates are then used to recompute the priors.
Note that if some observations are excluded from {cmd:xtmixed} run (for example due to missing cases on any of the regressors)
these observations will not be conditioned.

{pmore}
{opt suf:fix(name)} is a sub-option of {opt th:eta()};
it specifies a suffix used in naming new EAP and PVs variables. Also influences default naming of the x-axis in ICC graphs.
If {it:newvar1} and {it:newvar2} are provided they will take precedence in naming EAP estimates and the theta scale on graphs,
however {opt suf:fix()} will still apply to the PVs.

{pmore}
{opt sc:ale(#,#)} is a sub-option of {opt th:eta()};
it is used to change the scale of the latent trait for variables that are added to the dataset.
By default, the EAP and the PVs are obtained accordingly to the group parameters that are reported in {cmd:e(group_par)}. 
Specifying {opt sc:ale(m,sd)} will rescale the latent trait so that the mean and the standard deviation in reference group are {it:m} and {it:sd}.
Note that this will not influence the parameters reported in {cmd:e(item_par)} and {cmd:e(group_par)} 
- only the variables added with {opt theta()} are affected.
Also note that because {opt sc:ale(m,sd)} acts on the latent trait variable level,
the EAP estimates will most probably have smaller standard deviation in the reference group than {it:sd} due to shrinkage.

{pmore}
{opt skipn:ote} is a sub-option of {opt th:eta()};
it suppresses adding notes to newly created variables. Default behavior is to add notes.


{dlgtab:Fixed and starting values}

{pstd}
{cmd:uirt} allows model parameters to be fixed or initiated with prespecified values.
Fixing parameters is done with {opt fix()} option, and initiating with {opt init()} option.
These options have similar sub-options and can also be used simultaneously.
In case any model parameter is present in both {opt fix()} and {opt init()} the {opt fix()} information on that parameter is used
and {opt init()} information is discarded.
Parameters can be fixed/initiated in a twofold manner.
One way is to refer to previous uirt results that are stored in memory, using {opt prev} sub-option (if {cmd:uirt} estimates are active)
or using {opt from(name)} sub-option (if {cmd:uirt} results {it: name} are stored in memory).
The other way is to provide matrices with item parameters or group parameters using {opt i:matrix()} or {opt d:matrix()} sub-options.
These matrices must have the form used by {cmd:uirt} for storing results: {cmd:e(item_par)} and {cmd:e(group_par)} respectively.
It is possible to fix/initiate only selected parameters of an item when {opt i:matrix()} sub-option is used; 
if this is the intention, additional {opt miss} sub-option must be included - otherwise {cmd: uirt} will report an error in {opt i:matrix()}
as it vigorously checks the appropriateness of provided matrices.
When fixing parameters, you can also provide information on item category values if they are nor the usual {0,..,max_cat} using {opt c:matrix()} sub-option.

{phang}
{opt fix([opts])} is used declare parameters to fix. The sub-options are:

{pmore}
{opt prev} is a sub-option of {opt fix()};
it is used to fix item parameters on estimates from previous {cmd:uirt} run if {cmd:uirt} was the last command called. 
It will cause the parameters of all items that are found in {cmd:e(item_par)} to be fixed on values reported in that matrix.

{pmore}
{opt from(name)} is a sub-option of {opt fix()};
it is used to fix item parameters on values from {cmd:uirt} run that is stored in memory under name {it:name}. It works exactly like {opt prev}. 
{opt prev} and {opt from(name)} cannot be used simultaneously.

{pmore}
{opt used:ist} is a sub-option of {opt fix()};
it is used to fix group parameters on estimates from previous {cmd:uirt} run when calling {opt prev} or {opt from()} sub-options. 
(Default behavior of {opt prev} and {opt from()} is to fix only the item parameters.)

{pmore} 
{opt i:matrix(name)} is a sub-option of {opt fix()};
it is used to provide a matrix with item parameters to be fixed. 
With {opt i:matrix(name)} it is possible to fix only selected parameters of an item. 
To do it, the entries for item parameters that are to be estimated freely must be set to missing values (.) in matrix {it:name}
and sub-option {opt miss} must be included.

{pmore}
{opt d:matrix(name)} is a sub-option of {opt fix()};
it is used to provide a matrix with group parameters to be fixed. It does not allow for missing entries.

{pmore}
{opt c:matrix(name)} is a sub-option of {opt fix()};
it is used to provide a matrix with item category values if neither {opt prev} not {opt from(name)} is used to fix parameters. 
This can be handy when previous estimates are used in datasets with fewer observations, 
possibly with some item categories not present in data, in case when item categories are not consecutive integers starting from 0 up to max_cat.

{pmore}
{opt miss} is a sub-option of {opt fix()};
it permits the matrix {it:name} in {opt i:matrix(name)} to have missing entries for some item parameters. 

{phang}
{opt init([opts])} is used declare starting values. The sub-options are:

{pmore}
{opt prev} is a sub-option of {opt init()};
it is used to set item parameters starting values on estimates from previous {cmd:uirt} run if {cmd:uirt} was the last command called. 
It will cause the parameters of all items that are found in {cmd:e(item_par)} to be started from values reported in that matrix.

{pmore}
{opt from(name)} is a sub-option of {opt init()};
it is used to set item parameters starting values on estimates from {cmd:uirt} run that is stored in memory under name {it:name}.
It works exactly like {opt prev}. 
{opt prev} and {opt from(name)} cannot be used simultaneously.

{pmore}
{opt used:ist} is a sub-option of {opt init()};
it is used to start group parameters with estimates from previous {cmd:uirt} run when calling {opt prev} or {opt from()} sub-options. 
(Default behavior of {opt prev} and {opt from()} is to pass starting values only for the item parameters.)

{pmore} 
{opt i:matrix(name)} is a sub-option of {opt init()};
it is used to provide a matrix with  starting values for item parameters. 
With {opt i:matrix(name)} it is possible to provide starting values only for some parameters of an item. 
To do it, the entries for item parameters that are to be started by {cmd: uirt} defaults must be set to missing values (.) in matrix {it:name}
and sub-option {opt miss} must be included.

{pmore}
{opt d:matrix(name)} is a sub-option of {opt init()};
it is used to provide a matrix with starting values for group parameters. It does not allow for missing entries.

{pmore}
{opt miss} is a sub-option of {opt init()};
it permits the matrix {it:name} in {opt i:matrix(name)} to have missing entries for some item parameters. 

{dlgtab:EM control}

{phang}
{opt nip(#)} sets the number of Gauss-Hermite quadrature points used in EM algorithm. 
Default value is 51.

{phang}
{opt nit(#)} sets the maximum number of iterations of EM algorithm.
Default value is 100.

{phang}
{opt ninrf(#)} sets the maximum number of iterations of Newton-Raphson-Fisher algorithm within M-step. 
Default value is 20. This option is rarely used.

{phang}
{opt crit_ll(#)} sets a stopping rule - relative change in log-likelihood between EM iterations.
Default value is 1e-9.

{phang}
{opt an:egative} allows to keep items with negative discrimination in the model. 
Default behavior of {cmd:uirt} is to drop items whenever their discrimination parameter becomes negative. 
The final model is fit with all such items discarded.
If you want to keep such items in the model and estimate their parameters, you have to use the {opt an:egative} option.

{phang}
{opt crit_par(#)} sets a stopping rule - maximum absolute change in parameter values between EM iterations.
Default value is 1e-4.

{phang}
{opt err:ors(str)} is used to choose a method for computation of standard errors of estimated parameters. 
There are four methods available. Three methods (CDM,REM,SEM) are taking the approach of differentiation of the EM mapping
and one (CP) is based on Louis's (1982) cross-product approach. 
The methods will be briefly described in order of recommendation.
See Jamshidian & Jennrich (2000) for a general overview of these methods.
CDM (centered difference method) for numerical differentiation of EM mapping is the default option and is recommended for reporting standard errors.
CP (cross-product) by Louis's method is considerably faster but biased - use it when errors are of lesser importance and want to speed up the computation.
REM (Richardson extrapolation method) for differentiation of EM mapping is (unnecessarily) more precise that CDM, at cost of doubling the computational expense.
SEM (supplemented EM) for differentiation of EM mapping usually takes the most time and is unstable - not recommended, included for research purposes.

{phang}
{opt pr:iors(varlist [,opts])} is used to provide a list of items to estimate with priors. Only dichotomous items are supported.
When * is typed for {it:varlist}, the priors specified in {it:opts} will be applied to all dichotomous items declared in main list of items. 
Note that modification of the model that is introduced with item parameter priors is neither accounted for in the reported log-likelihood 
nor in the reported number of degrees of freedom of the model. 
Therefore likelihood based statistical testing (comparing nested models with LR test, DIF analysis, item-fit statistics etc.) 
conducted on models estimated with item parameter priors may be biased. 
When priors are used the convergence is monitored only with {opt crit_par()}; the {opt crit_ll()} stopping rule is ignored. 
The prior distributions for item parameters are specified with following sub-options of {opt pr:iors()}:

{pmore}
{opt a:normal(#,#)} is used to set parameters ({it:mean,sd}) of normal prior for discrimination parameter.
If this sub-option is skipped all discriminations are estimated without priors.

{pmore}
{opt b:normal(#,#)} is used to set parameters of normal prior ({it:mean,sd}) for difficulty parameter.
If this sub-option is skipped all difficulties are estimated without priors.

{pmore}
{opt c:beta(#,#)} is used to set parameters ({it:alpha,beta}) of beta prior for pseudo-guessing parameter.
If this sub-option is skipped all pseudo-guessing parameter are estimated without priors.

        
        
{dlgtab:Reporting}

{phang}
{opt not:able} suppresses display of coefficient table.
Default coefficient table may be large and provides information which is often not useful in context of IRT analysis
(we are usually not interested if IRT parameters differ from 0). 
Parameters and their errors are accessible in a compact form in {cmd:e()} matrices
so you may wish not to see the default coefficient table at all. 

{phang}
{opt noh:eader} suppresses display of model summary after estimation is complete.

{phang}
{opt trace(#)} allows for controlling how log is printed after iterations.
0 - no log (except warnings); 1 - limited log (default option); 2 - detailed log.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse masc2} {p_end}

{pstd}Run {cmd:uirt} on default settings (one group, 2PLM for 0-1 items, GRM for 0-k items), and ask to plot ICC for item {it:q6}{p_end}
{phang2}{cmd:. uirt q*,icc(q6)} {p_end}

{pstd} Continue the analysis using estimates from previous run as starting values, and ask that item {it:q6} be 3PLM with sub-option {opt lr:crit()} turned off, 
also plot ICC for that item{p_end}
{phang2}{cmd:. uirt q*,guess(q6,lr(1)) init(prev) icc(q6)} {p_end}

{pstd} Refit the model with all items asked to be 3PLM, use beta(5,18) distribution as prior for the pseudo-guessing parameter to ensure convergence{p_end}
{phang2}{cmd:. uirt q*, guess(*,lr(1)) priors(*,c(5,18)) } {p_end}

{pstd} Fit a two-group model to data with {it:female} grouping variable, all items 2PLM, and test item {it:q1} for DIF {p_end}
{phang2}{cmd:. uirt q*,gr(female,dif(q1))} {p_end}

{pstd} Fit a single-group model with all items 2PLM, generate 5 plausible values conditioned on the {it:female} variable, and ask that the scale of generated PVs to have mean=500 and sd=100{p_end}
{phang2}{cmd:. uirt q*,theta(,pv(5) pvreg(i.female) scale(500,100))} {p_end}


{marker results}{...}
{title:Stored results}

{syntab: {cmd: uirt} stores the following in e():}

{p2col 5 17 21 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(ll)}}log (restricted) likelihood{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(N_items)}}number of items in the model{p_end}
{synopt:{cmd:e(N_gr)}}number of groups in the model{p_end}
{synopt:{cmd:e(converged)}}1 if converged, 0 otherwise{p_end}

{p2col 5 17 21 2: Macros}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(cmdstrip)}}command in form that is passed to init() or fix() in re-runs{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variables (items){p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(cmd)}}{cmd:uirt}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 17 21 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(Cns)}}constraints matrix{p_end}
{synopt:{cmd:e(item_par)}}estimated item parameters{p_end}
{synopt:{cmd:e(item_par_se)}}standard errors of estimated item parameters{p_end}
{synopt:{cmd:e(group_par)}}estimated group parameters{p_end}
{synopt:{cmd:e(group_par_se)}}standard errors of estimated group parameters{p_end}
{synopt:{cmd:e(group_ll)}}log likelihood by group{p_end}
{synopt:{cmd:e(group_N)}}number of observations by group{p_end}
{synopt:{cmd:e(item_group_N)}}number of observations for each item by group{p_end}
{synopt:{cmd:e(item_cats)}}item categories{p_end}
{synopt:{cmd:e(dif_results)}}LR test results and effect size measures after DIF analysis{p_end}
{synopt:{cmd:e(dif_item_par_GR)}}parameters of DIF items obtained in the reference group{p_end}
{synopt:{cmd:e(dif_item_par_GF)}}parameters of DIF items obtained in the focal group{p_end}
{synopt:{cmd:e(item_fit_chi2W)}}item-fit results for chi2W statistic{p_end}
{synopt:{cmd:e(item_fit_SX2)}}item-fit results for S-X2 statistic{p_end}


{title:Author}

Bartosz Kondratek
everythingthatcounts@gmail.com

{title:Suggested citation}

{phang}
Kondratek, B. (2022). uirt: A command for unidimensional IRT modeling. {it:The Stata Journal}, 22(2), 243{c -}268. https://doi.org/10.1177/1536867X221106368

{title:Acknowledgement}

{phang}
I wish to thank Cees Glas who provided me with invaluable consultancy on many parts of the estimation algorithms used in {cmd:uirt} 
and Mateusz Zoltak for very helpful hints on Mata pointers which led to significant boost in efficiency of {cmd:uirt}.
Many thanks to all of my colleagues at the Institute of Educational Research in Warsaw for using {cmd:uirt} at the early stages of its development
and providing me with feedback and encouragement to continue with this endeavor. I am also grateful to numerous Stata users 
who contacted me with ideas on how to improve the software after its first release.
I feel especially indebted to Eric Melse, for his support in building postestimation commands 
that allow for plotting information functions and expected score curves.
Last but not least, I would like to thank the anonymous Reviewer at the Stata Journal,
who had guided me on how to rewrite {cmd:uirt} to make it more user friendly and more aligned with Stata programming standards.


{title:Funding}

{phang}
Preparation of modules of {cmd:uirt} related to item-fit analysis was funded by the 
National Science Centre research grant number 2015/17/N/HS6/02965.

{marker references}{...}
{title:References}

{phang}
Bock, R. D., Aitkin, M. (1981).
Marginal Maximum Likelihood Estimation of Item Parameters: Application of an EM algorithm.
{it:Psychometrika}, 46, 443{c -}459; 47, 369 (Errata)

{phang}
Dempster, A. P., Laird, N. M., Rubin, D. B. (1977). 
Maximum Likelihood from Incomplete Data via the EM Algorithm.
{it:Journal of the Royal Statistical Society}, Series B 39(1), 1{c -}38.

{phang}
Jamshidian, M., Jennrich, R.I. (2000).
Standard Errors for EM Estimation. 
{it:Journal of the Royal Statistical Society}, Series B, 62, 257{c -}270.

{phang}
Kondratek, B. (2022).
uirt: A command for unidimensional IRT modeling.
{it:The Stata Journal}, 22(2), 243{c -}268.
https://doi.org/10.1177/1536867X221106368

{phang}
Kondratek, B. (2022).
Item-Fit Statistic Based on Posterior Probabilities of Membership in Ability Groups.
{it:Applied Psychological Measurement}, 46(6), 462{c -}478.
https://doi.org/10.1177/01466216221108061

{phang}
Louis, T. A. (1982).
Finding the Observed Information Matrix When Using the EM Algorithm.
{it:Journal of the Royal Statistical Society}, Series B, 44, 226{c -}233.

{phang}
Orlando, M., & Thissen, D. (2000). 
Likelihood-based item-fit indices for dichotomous item response theory models.
{it:Applied Psychological Measurement}, 24, 50{c -}64.

{phang}
Patz, R. J., Junker, B. W. (1999).
A Straightforward Approach to Markov Chain Monte Carlo Methods for Item Response Models.
{it:Journal of Educational and Behavioral Statistics}, 24(2), 146{c -}178.

{phang}
Wainer, H. (1993).
Model-Based Standardized Measurement of an Item's Differential Impact. 
In: {it:Differential Item Functioning.}
ed. Holland, P. W. & Wainer, H., 123{c -}136.
Hillsdale: Lawrence Erlbaum.