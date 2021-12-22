{smcl}
{* *! version 1.0.0  13oct2021}{...}
{cmd:help metatef}{right: Patrick Royston}
{hline}


{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:metatef} {hline 2}}IPD meta analysis of an interaction between treatment and a continuous covariate{p_end}
{p2colreset}{...}


{title:Syntax}

{phang2}
{cmd:metatef} [, {it:metatef_options}]
{cmd::} {it:regression_cmd} [{it:yvar}] {it:xvar} {ifin} {weight} [, {it:regression_cmd_options} ]


{synoptset 30}{...}
{synopthdr :metatef_options}
{synoptline}
{synopt :{opt adj:ust(varlist)}}adjustment variables{p_end}
{synopt :{opt by(varlist)}}({it:required}) study indicator variable(s){p_end}
{synopt :{opt cen:tre}{cmd:(}{it:#}|{cmd:mean}{cmd:)}}centre {it:xvar} on its mean or on {it:#}{p_end}
{synopt :{opt eb:ayes(stubname)}}store empirical Bayes estimates of functions{p_end}
{synopt :{opt fixp:owers}{cmd:(}{it:#}[{it:#} ...]|{it:matrixname}{cmd:)}}({it:required}) fractional polynomial powers for transforming {it:xvar}{p_end}
{synopt :{opt fun:ction(stubname)}}store treatment effect functions{p_end}
{synopt :{opt gen:erate(newvarname)}}stores overall treatment effect function{p_end}
{synopt :{opt ran:dom}}fits random-effects model{p_end}
{synopt :{opt str:ata(varlist)}}stratify by variables in {it:varlist}{p_end}
{synopt :{opt stu:dywise}}fits studywise fractional polynomial functions{p_end}
{synopt :{opt tau(newvarname)}}stores random-effects variance function in {it:newvarname}{p_end}
{synopt :{opt with(trtvar)}}({it:required}) binary indicator variable for treatment groups{p_end}

{synopthdr :}
{synopt :{it:regression_cmd_options}}options appropriate to the regression command in use{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
where

{p 8 8 2}
{it:regression_cmd} may be
{help clogit},
{help cnreg},
{help glm},
{help logistic},
{help logit},
{help mlogit},
{help nbreg},
{help ologit},
{help oprobit},
{help poisson},
{help probit},
{help qreg},
{help regress},
{help rreg},
{help stcox},
{help stpm},
{help stpm2},
{help streg},
or
{help xtgee}.

{pstd}
All weight types supported by {it:regression_cmd} are allowed; see help
{help weights}.

{pstd}
{bf:Important}: if you wish to use flexible parametric survival models
(a.k.a. Royston-Parmar models) with {cmd:metatef}, you must install
or update to the current version of {cmd:stpm2} from SSC:

      {cmd:. ssc install stpm2, replace}
      

{title:Description}

{pstd}
{cmd:metatef} models an interaction between a response variable
({it:yvar}) and  a fractional polynomial (FP) function of a continuous
covariate ({it:xvar}), optionally adjusting for other variable(s)
specified in {cmd:adjust()}. Estimated "treatment effect functions" are
averaged across the studies specified by {cmd:by()}.

{pstd}
{cmd:metatef} assembles a weighted mean curve and pointwise confidence
interval based on a treatment x covariate interaction estimated in several
studies. The variables used to adjust for confounding in multivariable models
may differ between the studies, in which case {cmd:adjust()} may
consist of an 'index' (linear predictor) representing the estimated
confounder adjustment from each study. It is strongly recommended
that the index be standardised to have mean zero.

{pstd}
The user must specify, in {opt fixpowers()}, the FP powers to be used to
model the main effect of {it:xvar} and its interaction with {it:trtvar}.
To specify a linear function, enter {cmd:fixpowers(1)}.
See Sauerbrei & Royston (2011) for a description of a closely related
problem.


{title:Options}

{phang}
{opt adjust(varlist)} adjusts each estimated function for the variables
in {it:varlist}.

{phang}
{opt by(varlist)} is not optional. {it:varlist} defines the
studies (typically, {it:varlist} will be a single categorical variable).

{phang}
{cmd:centre(}{it:#}|{cmd:mean)} centres the covariate {it:xvar} on
{it:#}. {cmd:mean} denotes the mean of {it:xvar} over the entire dataset.

{phang}
{opt cutpoints(numlist)} replaces an FP analysis of {it:xvar} with one in
which {it:xvar} is categorised according to the cutpoints in {it:numlist}.

{phang}
{opt ebayes(stubname)} stores the empirical Bayes estimate of the
treatment effect function in study #j (j = 1, 2, ...) in a new variable called
{it:stubname}{cmd:j}. This option only applies if {cmd:random} is also used.

{phang}
{cmd:fixpowers(}{it:#}[{it:#} ...]|{it:matrixname}{cmd:)} forces
the FP powers to be {it:#} [{it:#} ...] for each individual
study and overall. If {it:#} = 1 then linear functions are fitted.
Alternatively, if {it:matrixname} is specified then the powers must
be stored in a matrix; each row of {it:matrixname} contains set of powers
per study. The first row gives the powers for use in the overall
(stratified) model. The number of columns corresponds to the maximum
number of powers required. If some studies have less than the maximum
number of powers, missing values should be used to fill the empty positions
in the matrix. {opt fixpowers(matrixname)} is valid only with {cmd:studywise}.

{phang}
{opt function(stubname)} stores the estimated treatment effect
function from study #j (j = 1, 2, ...) in a new variable called
{it:stubname}{cmd:j}.

{phang}
{opt generate(newvarname)} specifies that{it:newvarname} is a
new variable containing the mean fitted treatment effect function,
centered at the value set by the {cmd:centre()} option.
Furthermore, {it:newvarname}{cmd:_se} is a new variable containing the
standard error of the fitted function, and {it:newvarname}{cmd:_ll} and
{it:newvarname}{cmd:_ul} contain respectively the lower and upper pointwise
confidence limits of the function.

{phang}
{opt random} adds a component of variance between studies to the estimated
pointwise variance of the mean fitted curve, which may change
the weights used to calculate the weighted mean function. The default
is that the weight for a given study equals the reciprocal of the estimated
variance of the estimated function. {cmd:random} also allows empirical Bayes
(shrunken) estimates of the individual function for each study
to be made (see the {opt ebayes()} option).

{phang}
{opt strata(varlist)} stratifies each model according to the variables
in {it:varlist}, in addition to stratification using the {opt by()}
variable. Stratification applies only to models fit using {cmd:stcox}
or {cmd:stpm}.

{phang}
{opt studywise} uses the FP powers specified in {opt fixpowers()},
both per-study and overall. For the overall model, a 
stratified or adjusted regression model is fitted, with stratification
or adjustment by study. With {cmd:streg} and {cmd:stcox}, the
{cmd:strata()} option is used; with {cmd:stpm}, the {cmd:stratify()}
option is used; with all other regression commands, dummy variables
are created for each study except the first and the regression is
adjusted for these dummy variables.

{phang}
{opt with(trtvar)} defines the treatment variable. This must have exactly
two distinct non-missing values. Therefore, only trials with two treatment
arms are supported by this version of {cmd:metatef}.

{phang}
{it:regression_cmd_options} may be any of the options appropriate to
{it:regression_cmd}.


{title:Remarks}

{pstd}
{cmd:metatef} does {it:not} support the selection of FP functions by applying
{cmd:mfpi}. Rather, you must determine best-fitting FP functions of given
degree by applying {cmd:mfpi} first, and recording the required FP powers,
overall and optionally for each study. If {cmd:mfpi} is not available or
out of date, it may be installed or updated by using the command
{cmd:ssc install mfpi, replace}.

{pstd}
Full details of the methodology with an application in breast cancer
clinical trials are given by Sauerbrei and Royston (2021).


{title:Examples}

{phang}{cmd:. metatef, by(cohort) fixpowers(0.5) with(trt) generate(d): regress bloodpress age}{p_end}
{phang}{cmd:. line d d_ll d_ul age, sort}

{phang}{cmd:. matrix p = -2,0 \ -1,2 \ 0,3 \ -2,.5 \ -2,.5 \ -2,.5 \ -1,3 \ 0,2 \-.5,0 \ -.5,1}{p_end}
{phang}{cmd:. metatef, dist(weibull) by(study) with(trt) fixpowers(p) adjust(xb) generate(fx1) function(fx1): streg x1}{p_end}
{phang}{cmd:. line fx1? x1, sort}

{phang}{cmd:. metatef, dist(weibull) by(study) with(trt) fixpowers(p) adjust(xb) generate(fx1) function(fx1) ebayes(ebf) random: streg x1}{p_end}

{phang}{cmd:. metatef, by(study) with(trt) strata(sex) fixpowers(p) generate(fx1) studywise: stcox x1}{p_end}


{title:Author}

{phang}Patrick Royston{p_end}
{phang}MRC Clinical Trials Unit at UCL{p_end}
{phang}London, UK{p_end}
{phang}j.royston@ucl.ac.uk{p_end}


{title:References}

{phang}
Sauerbrei W, Royston P. 2011. A new strategy for meta-analysis of continuous
covariates in observational studies. Statistics in Medicine 30: 3341-3360.
https://doi.org/10.1002/sim.4333.

{phang}
Kasenda B, Sauerbrei W, Royston P, Mercat A, Slutsky AS, Cook D, Guyatt GH,
Brochard L, Richard J-C M, Stewart TE, Meade M, Briel M. 2016.
Multivariable fractional polynomial interaction to investigate continuous effect
modifiers in a meta-analysis on higher versus lower PEEP for patients with ARDS.
BMJ Open 6. https://doi.org/10.1136/bmjopen-2016-011148.

{phang}
Sauerbrei W, Royston P. 2021. Investigating treatment-effect modification by a
continuous covariate in IPD meta-analysis: an approach using fractional
polynomials. Submitted.


{title:Also see}

{psee}
Manual:  {hi:[R] fp, [R] mfp}

{psee}
Online: help for {help fp}, {help mfp}, {help mfpi} (if installed),
{help stpm2} (if installed)
