{smcl}
{* *! last edited 04jan2017}{…}

{hline}
help file for {cmd:hetop} version 2.0
{hline}

{title:Title}

{phang}
{bf:hetop} {hline 2} heteroskedastic ordered probit models (via {help oglm})

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmdab:hetop}
{it:grpvar levelvar}
{cmd: ,} {opt numcats(#)}
[ {opt modtype(string)}
  {opt identify(string)}
  {opt setref(#)}
  {opt phop(varname)}
  {opt pkvals(varname)}
  {opt STARTFRom(namelist)}
  {opt kappa(#)}
  {opt save(string)} 
  {opt ADDCONStraints(string)}
  {opt minsize(#)}
  {opt initvals}
  {opt gaps} 
  {opt noisily}
  {opt homop}
  {it:maximize_options} ]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}

{synopt:{opt numcats(#)}}
number of ordered categories in outcome variable{p_end}

{syntab:Optional}

{synopt:{opt modtype(hetop/homop)}}
specify a heteroskedastic or homoskedastic model; allowable options are 
{it:hetop} (the default) or {it:homop}{p_end}

{synopt:{opt identify(sums/refgroup)}}
type of constraints used to identify the model; allowable options are {it:sums} 
(the default) or {it:refgroup}{p_end}

{synopt:{opt setref(#)}}
the ID number from {it:grpvar} of the group to be constrained as a reference
group{p_end}

{synopt:{opt phop(varname)}}
variable name containing a 0/1 indicator for groups to constrain with a single
pooled standard deviation estimate via a PHOP model. All groups with
{it:varname}=1 will be constrained. Must be used in
conjunction with {opt modtype(hetop)} or with {opt modtype()}
blank.{p_end}

{synopt:{opt pkvals(varname)}}
specifies a variable containing the population proportions of each group. If not
specified, by default the sample proportions in the data will be used as the
population proportions of each group{p_end}

{synopt:{opt STARTFRom(namelist)}}
start estimation from values specified in the matrix {it:namelist}.{p_end}

{synopt:{opt kappa(1/2)}}
adjust the de-referencing equations. Recommended to leave this option
blank.{p_end}

{synopt:{opt save(string)}}
save estimates of mstar and sstar, with standard errors. These will be saved
as new variables mstar_{bf:string}, sstar_{bf:string},
mstar_{bf:string}_se, and sstar_{bf:string}_se. Using {opt save(star)}
will not append anything to the names.{p_end}

{synopt:{opt ADDCONStraints(string)}}
index values of additional pre-defined constraints to pass to the
maximization.{p_end}

{synopt:{opt minsize(#)}}
exclude all groups with sample sizes smaller than # from estimation.{p_end}

{synopt:{opt initvals}}
calculate initial starting values for estimation.{p_end}

{synopt:{opt gaps}}
display additional statistics.{p_end}

{synopt:{opt noisily}}
print output from {help oglm} during estimation.{p_end}

{synopt:{opt homop}}
a shortcut equivalent to typing {opt modtype(homop)}.{p_end}

{synopt:{it: maximize_options}}
options passed to {help oglm} to control maximization process.{p_end}

{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:hetop} estimates means and standard deviations of underlying continuous,
normal distributions for each group in {it:grpvar} based on the frequency counts
of observations in each variable with the stem {it:levelvar}*. The estimates
are returned in a standardized metric to facilitate interpretation and
subsequent analyses. Details

{pstd}
The {it:grpvar} variable must uniquely identify the groups,
and it is recommended to number the
groups consecutively 1:G. There should be one row per group, with one column of
frequency counts for each of the {it: K} ordered categories. The
count variables should be named as {it:levelvarX} where X is a sequence of
ordered integer values indicating the order of the categories. While
the order of these values must correspond to the ordering of the categories, the
magnitude of the values is arbitrary
(so {it:levelvar1}, {it:levelvar2}, {it:levelvar3} is the same as
{it:levelvar0}, {it:levelvar4}, {it:levelvar5}). The starting value calculations
are based on the integer codes, so the best starting values are obtained when
the values are sequential integers.

{pstd}
{cmd:hetop} extends and relies on the {help oglm} command for
Stata to carry out the estimation.

{pstd}
The data file should have the following layout:

	+---------------------------------------------------------+
	| grpvar  levelvar0   levelvar1   levelvar2   levelvar3   |
	|---------------------------------------------------------|
	|   1        750        1428          741          66     |
	|   2        600        1197          811         155     |
	|   3        840        1653         1080         160     |
	|  ...       ...         ...          ...         ...     |
	|   G       2204        3622         2507         570     |
	|---------------------------------------------------------|

{pstd}
The {cmd:hetop} function can be used to estimate the following models:

{pstd}
{bf:HETOP}: heteroskedastic ordered probit models with a unique mean and
standard deviation for each group.

{pstd}
{bf:PHOP}: partially heteroskedastic ordered probit models with unique means 
for all groups, unique standard deviations for one set of groups and a single
pooled standard deviation estimate for remaining groups.

{pstd}
{bf:HOMOP}: homoskedastic ordered probit model with a unique mean estimated for
each group but standard deviations of all groups constrained to be equal.

{pstd}
Note that when there are data in only two categories it is only possible to
estimate a HOMOP model. When there are more than 2 categories but there are
only non-zero counts
in 2 or fewer categories for some groups, finite ML estimates for the means and
standard deviations of those groups may not exist. {help hetop} issues warnings
about the presence of such gruops but does not apply formal checks or other
precautions for these cases. In some cases, the estimation algorithm may
indicate convergence to a false solution in the presence of such groups. Slow
convergence or very large standard errors can be signs that the ML estimates
for some groups do not exist or are poorly identified.

{p}

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt numcats} If numcats<3 only a HOMOP model can be fit.

{dlgtab:Optional}

{phang}
{opt modtype(string)} This can be either {it:homop} for a HOMOP model or
{it:hetop} when fitting HETOP or PHOP models. Default is {opt modtype(hetop)}.

{phang}
{opt identify(string)} In order to identify the model and set the scale for the
estimates, constraints must be placed on the parameter estimates. There are
two possible types of constraints. The {it:sums} constraint constrains the
weighted sum of the log(SD) estimates and the weighted sum of the means to be 0,
where the weights for each group are the proportion of each group in the
population or the weights specified in {opt pkvals(varname)}. Another option
is to constrain the mean and log(SD) of a single
group to be 0. This group is referred to as a "reference" group. When
specifying the {opt identify(refgroup)} option, an automatic reference group
will be selected unless a specific group is specified with {opt setref(#)}. Both
sets of constraints yield theoretically equivalent models; however, in some
cases the reference group approach may yield higher convergence rates for
problematic samples. In all cases, {cmd:hetop} produces "star" estimates that are
in a standardized metric as described in Reardon et al. (2016). These standardized
estimates should be identical regardless of which identification method is
used. Default is {opt identify(sums)}.

{phang}
{opt setref(#)} See above description of {opt identify}. Specifying {opt setref}
without specifying {opt identify} is the same as specifying
{opt identify(refgroup)}.

{phang}
{opt phop(varname)} Specifies a 0/1 indicator variable, where all groups with
{it:varname}=0 will receive a unique standard deviation estimate and all
groups with {it:varname}=1 will receive a single pooled standard deviation
estimate. Cannot be specified with the {opt modtype(homop)} option.

{phang}
{opt pkvals(varname)} A variable specifying the proportion of each
group in the population.
These are used to identify the model for the sums constraints method and
are also used in the standardization and standard error calculations. No
checks made to verify that, e.g., these sum to 1.

{phang}
{opt STARTFRom(namelist)} Specifies a matrix containing starting values
to use as initial values for the ML estimation. Names must match the
parameters estimated by {help oglm}. No checks are made to verify the
names or reasonableness of the values.

{phang}
{opt kappa(1/2)} See Reardon et al. (2016) for details about this option.
Default is {opt kappa(1)}.

{phang}
{opt save(string)} Option to save mean and standard
deviation estimates and their standard errors. These will be saved
as new variables mstar_{bf:string}, sstar_{bf:string},
mstar_{bf:string}_se, and sstar_{bf:string}_se. Using {opt save(star)}
will not append anything to the names.

{phang}
{opt ADDCONStraints(string)} Many models fit by {cmd:hetop} specify constraints
automatically. This option can be used to place additional constraints on the
model. These constraints must be defined prior to running {cmd:hetop}.
Contraint numbers listed here will be added to the call to {help oglm}.
WARNING: no checks are made to ensure that these constraints are compatible with
those that will automatically be applied within {cmd:hetop}. Use at own risk.

{phang}
{opt minsize(#)} A convenience for excluding small groups from estimation.
Any group with fewer than {it:minsize} observations will be excluded from
estimation.

{phang}
{opt initvals} Initial values are computed by treating the integer codes for
the ordinal categories as interval scores. A mean and standard deviation is
calculated for each group as an approximate starting value and rescaled
according to the model identification strategy.

{phang}
{opt gaps} If specified, an additional matrix of pairwise gaps will be returned.
This may slow down the runtime of the code.

{phang}
{opt noisily} Simply passes the "noisily" option on to {cmd:oglm}.

{phang}
{opt homop} equivalent to {opt modtype(homop)}.

{phang}
{it:maximize_options} See {help maximize} for more details.

{marker remarks}{...}
{title:Remarks}

{pstd}
Requires {help oglm} version 2.3.0 or later.
{p_end}

{pstd}
For detailed explanation of the models fit see Reardon, Shear, 
Castellano and Ho (2016).
{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Load the sample data file.{p_end}
{phang2}{cmd:. use "hetop-example.dta" , clear}

{pstd}Fit HETOP model with fewest possible options:{p_end}
{phang2}{cmd:. hetop id level , numcats(4)}

{pstd}Which is equivalent to:{p_end}
{phang2}{cmd:. hetop id level , numcats(4) modtype(hetop) identify(sums)}

{pstd}Fit HOMOP model with fewest possible options:{p_end}
{phang2}{cmd:. hetop id level , numcats(4) homop}

{pstd}Which is equivalent to:{p_end}
{phang2}{cmd:. hetop id level , numcats(4) modtype(homop) identify(sums)}

{pstd}Fit PHOP model with fewest possible options; all groups with 
n<=185 to have a single standard deviation estimate:{p_end}

{phang2}{cmd:. g phopvar = ng <= 185}

{phang2}{cmd:. hetop id level , numcats(4) phop(phopvar)}

{pstd}Fit HETOP model with reference group constraints; automatically
selected reference group:{p_end}
{phang2}{cmd:. hetop id level , numcats(4) identify(refgroup)}

{pstd}Fit HETOP model with reference group constraints;
use group 1 as reference group:{p_end}
{phang2}{cmd:. hetop id level , numcats(4) setref(1)}


{title:Stored results}

{pstd}
{cmd:hetop} stores the following in {cmd:e()} (which are added to values stored by {help oglm}):

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(initvals)}}0 if not used; 1 if used{p_end}
{synopt:{cmd:e(mseRC)}}error code for mstar Std. Err. calculations{p_end}
{synopt:{cmd:e(sseRC)}}error code for sstar Std. Err. calculations{p_end}
{synopt:{cmd:e(varmatsRC)}}error code for other Std. Err. calculations{p_end}
{synopt:{cmd:e(icchat)}}estimated ICC{p_end}
{synopt:{cmd:e(icchatratio)}}alternate form of estimated ICC{p_end}
{synopt:{cmd:e(icchat_var)}}estimated sampling variance of ICC{p_end}
{synopt:{cmd:e(sigmaprime)}}estimated total standard deviation in prime metric{p_end}
{synopt:{cmd:e(sigmaw)}}estimated within group variance in prime metric{p_end}
{synopt:{cmd:e(sigmab)}}estimated between group variance in prime metric{p_end}
{synopt:{cmd:e(refgrp)}}reference group ID; 0 if reference group not used.{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(phop)}}name of PHOP variable, "." if not used.{p_end}
{synopt:{cmd:e(modtype)}}either "hetop" or "homop"{p_end}
{synopt:{cmd:e(identify)}}either "sums" or "refgroup"{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(mstar)}}vector of estimated means in standardized metric{p_end}
{synopt:{cmd:e(mstar_se)}}vector of standard errors of estimated means in standardized metric{p_end}
{synopt:{cmd:e(sstar)}}vector of estimated standard deviations in standardized metric{p_end}
{synopt:{cmd:e(sstar_se)}}vector of standard errors of estimated standard deviations in standardized metric{p_end}
{synopt:{cmd:e(cstar)}}vector of estimated cut scores in star metric{p_end}
{synopt:{cmd:e(cstar_se)}}vector of standard errors of estimated cut scores in star metric{p_end}
{synopt:{cmd:e(mprime)}}vector of estimated means in prime metric{p_end}
{synopt:{cmd:e(mprime_se)}}vector of standard errors of estimated log(standard deviations) in prime metric{p_end}
{synopt:{cmd:e(sprime)}}vector of estimated standard deviations in prime metric{p_end}
{synopt:{cmd:e(sprime_se)}}vector of standard errors of estimated standard deviations in prime metric{p_end}
{synopt:{cmd:e(gprime)}}vector of estimated log(sd) in prime metric{p_end}
{synopt:{cmd:e(gprime_se)}}vector of standard errors of estimated means in prime metric{p_end}
{synopt:{cmd:e(cprime)}}vector of estimated cut scores in prime metric{p_end}
{synopt:{cmd:e(cprime_se)}}vector of standard errors of estimated cut scores in prime metric{p_end}
{synopt:{cmd:e(initvalsmat)}}vector of initial starting values for all model parameters{p_end}
{synopt:{cmd:e(refrank)}}vector of group ID values, sorted in order of (potentially) best to worst reference groups{p_end}
{synopt:{cmd:e(pk)}}vector of proportions used as population proportions for each group in computations{p_end}

{synopt:{cmd:e(G)}}matrix of all pairwise standardized mean differences between groups, using an equally weighted pooled SD{p_end}
{synopt:{cmd:e(Gvar1)}}matrix of estimated sampling variances for each gap{p_end}


{p2colreset}{...}

{title:References}

{pstd}Reardon, S. F., Shear, B. R., Castellano, K. E., & Ho, A. D.
(2016). "Using Heteroskedastic Ordered Probit Models to Recover Moments
of Continuous Test Score Distributions From Coarsened Data."
Journal of Educational and Behavioral Statistics. DOI: 10.3102/1076998616666279{break}
Pre-publication version available at:
{browse "http://cepa.stanford.edu/content/using-heteroskedastic-ordered-probit-models-recover-moments-continuous-test-score-distributions-coarsened-data"}

{title:Acknowledgements}

{pstd}
We gratefully acknowledge the help of Katherine Castellano, Andrew Ho,
Erin Fahle, Demetra Kalogrides, and JR Lockwood in developing and testing the HETOP
methods and code used here. {cmd:hetop} makes substantial use of {cmd:oglm},
an excellent program written by Richard Williams.
Richard Williams provided helpful input during development, including modifying {cmd:oglm}
to facilitate its use with {cmd:hetop}.

{pstd}
Development of {cmd:hetop} was partially funded by an Institute of Education Sciences
training grant (#R305B090016).

{title:Authors}

{pstd}
Benjamin R. Shear{break}
University of Colorado Boulder{break}
benjamin.shear@colorado.edu{break}

{pstd}
sean f. reardon.{break}
Stanford University{break}
sean.reardon@stanford.edu{break}
