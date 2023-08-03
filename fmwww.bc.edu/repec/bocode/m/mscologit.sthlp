{smcl}
{.-}
help for {cmd:mscologit}
{.-}

{title:mscologit - Multiscale ordered logit model}


{title:Syntax}

{pstd}
{cmd:mscologit} {depvars} [{cmd:if}] [, {cmd:indvar}({indepvars}) {it:options}]


{title:Description}

{pstd}
{cmd:mscologit} fits the multiscale ordered logit model that expresses the association between covariates {indepvars} and an ordinal outcome variable. {cmd:mscologit} is a generalization of the standard proportional odds ordered logit model, 
but unlike the standard model, {cmd:mscologit} accommodates the presence of multiple response scales to measure the same rating dimension in the data, as when response formats for the same rating question differ across surveys or 
survey waves. Alternative outcome variables are listed as {depvars}, but typically there is but one valid observation in {depvars} for each row of data (e.g., because each survey respondent had been presented with one particular response
format in a particular survey, country, survey wave, or sample split).

{pstd}
{cmd:mscologit} is a derivative of the proportional odds model, and is sharing all features of this ordered logit model. {cmd:mscologit} permits to relax the parallel lines assumption of the proportional odds model through its 
{opt lo} and {opt up} options, whereby a multiscale variant of the generalized ordered logit model (Fu 1998, Williams 2006, 2016, Fullerton 2009, Agresti 2010, Fullerton and Xu 2016) may be estimated. As a wrapper for {cmd:meglm}, 
{cmd:gllamm}, and {cmd:runmlwin}, {cmd:mscologit} also permits to implement multilevel specifications of the multiscale ordered logit model; in the current implementation, up to 5 hierarchical levels may be specified in {cmd:mscologit}.

{title:Options}

{pstd}
{it:Standard (single-level) model specifications}

{phang}
{depvars} contains a variable list that corresponds to alternative measures of the outcome variable. Typically, there is only one valid observation on this variable list per row of data, because each respondent 
(or unit of observation) had been confronted with one particular response format only. {cmd:mscologit} is estimating an ordered logit model on this data under the assumption that {depvars} constitute alternative ways of recording the 
same latent dimension and that all {depvars} reflect ordinally ranked outcome data. Under this setting, {cmd:mscologit} estimates a common structural model Xb that applies to all observations irrespective of the concrete 
response format of the particular {depvar} that a respondent i happened to answer. Like in the standard ordered logit model, {cmd:mscologit} produces estimates for the scale cutpoints {it:aj}, but {cmd:mscologit} does so 
separately for each scale defined by one of the variables in {depvars}. Cutpoint estimates are labeled as {cmd:/cS_J} (with ML estimation) or {cmd:cutp_S_J} (when using {cmd:mscologit} as a wrapper) in the regression table, 
where cutpoint S,J refers to S=1,..max-1 in the list of {depvars} (scales) and J to one of the categories j of scale S, with j numbered from J(S)=1,..max-1 and cutp_S_J referring to the conditional probability Pr(Y>j | S=s).
{cmd:mscologit} also handles the case where one or several dependent variables are being observed on a binary scale only.

{phang}
{opt ind:var}{cmd:(}{indepvars}{cmd:)} contains a variable list {indepvars} that corresponds to the independent variables. Factor variables and time-series notation is allowed, but avoiding either convenience notation may significantly speed up 
{cmd:mscologit} with large datasets and many scales and response categories.

{phang}
{opt or} requests {cmd:mscologit} to report coefficients as odds ratios rather than as regression coefficients on the logit scale. The coefficient format may also be changed through the replay function associated with the actual 
({cmd:logit}, {cmd:meglm}, {cmd:gllamm}, or {cmd:runmlwin}) estimation command.

{phang}
{opt logit} is used to request estimating the multiscale model via logit regression on a suitably expanded dataset rather than via direct maximum likelihood estimation. In most situations, direct ML estimation will be the preferable option,
but the use of {opt logit} may be required when the number of model cutpoints becomes large (i.e. when being faced with a high number of rating scale formats and/or many long scales with a large number of response categories).

{phang}
{opt acc} may be used to request the estimation of the model in its accelerating order parametrization, i.e. in the parametrization of cutpoint parameters as used in Stata's {cmd:ologit} estimation command.
{opt acc} will result in the same estimates for coefficients, but cutpoint parameters will become inverted relative to the standard output, as they now refer to the conditional probability Pr(Y<=j | S=s) rather than to Pr(Y>j | S=s).
{opt acc} is implicit when requesting full ML estimation of the single-level multiscale model, i.e. {cmd:mscologit}'s ML estimator always implements the same model parametrization as does {cmd:ologit}.

{phang}
{opt vce(vcetype)} may be used to request the computation of robust or clustered standard errors. Its specification follows standard Stata syntax, and all {it:vcetypes} supported by {cmd:logit} may also be used with {cmd:mscologit}.

{phang}
{opt lo} may be used to relax the parallel regression assumption in the lower tail of the latent outcome variable. Use option {opt lowcut(probability)} to define the lower tail, and option {opt lowvar(varlist)} 
to define the variables for which the parallel lines assumption is to be relaxed. When {opt lowvar(varlist)} is not specified, separate coefficients will be estimated for all {indepvars}. 
The use of {opt lo} requires that all elements of {depvar} record outcomes by at least three response categories, the simultaneous use of {opt lo} and {opt up} requires that all elements of {depvar} record outcomes by at least 
four response categories. Regression coefficients relating to the lower tail of the outcome distribution are labelled as lo_<varname> in the regression table.

{phang}
{opt up} may be used to relax the parallel regression assumption in the upper tail of the latent outcome variable. Use option {opt upcut(probability)} to define the upper tail, and option {opt upvar(varlist)} 
to define the variables for which the parallel lines assumption is to be relaxed. When {opt upvar(varlist)} is not specified, separate coefficients will be estimated for all {indepvars}. 
The use of {opt up} requires that all elements of {depvar} record outcomes by at least three response categories, the simultaneous use of {opt lo} and {opt up} requires that all elements of depvar record outcomes by at least 
four response categories. Regression coefficients relating to the upper tail of the outcome distribution are labelled as up_<varname> in the regression table.

{phang}
{opt altpar} may be used to switch the format of regression coefficients in the generalized model specifications. The default behavior in {cmd:mscologit} is to estimate coefficients as interaction terms, which provides users 
with a direct test of coefficient variability against the model for the middle part of the outcome distribution. {opt altpar} switches {cmd:mscologit} behavior to estimating separate regression coefficients 
for each zone of the outcome distribution, and then corresponding hypothesis tests may be conducted using {cmd:test} and related post-estimation commands.

{pstd}
{it:Additional options in multilevel model specifications}

{phang}
{opt level2(levelspec)}, {opt level3(levelspec)}, {opt level4(levelspec)}, {opt level5(levelspec)} are being used to describe the regression specifications at higher levels of the data hierarchy. 
The exact details of levelspec depend on the actual estimation command called by {cmd:mscologit} (i.e. {cmd:meglm}, {cmd:gllamm}, or {cmd:runmlwin}). Users should specify {it:levelspec} in exactly the same way as they would do 
if using the original estimation command directly. {cmd:mscologit} is performing very limited syntax checking in itself, but will pass on {it:levelspec} to the actual estimation command mostly as specified by the user. 
The specification of one or more {opt levelX(levelspec)} options requires the choice of either {opt melogit}, {opt gllamm}, or {opt mlwin} as the actual estimation command.

{phang}
{opt mlwin} is used to call MLwiN for the estimation of the multilevel multiscale ordered logit model. This is the highly recommended option, given MLwiN's superior convergence behavior. 
The use of MLwiN requires a copy of the software, which is available from the Centre for Multilevel Modelling at the University of Bristol ({browse "http://www.bristol.ac.uk/cmm/"}), and the {cmd:runmlwin} ado has to be installed 
in order to call MLwiN from within Stata. The option {opt mlwop:tions(MLwiN_options)} may be used to pass on any estimation option available in {cmd:runmlwin}, other than the levels specification provided by {opt levelX(levelspec)}.
Also, when using {cmd:mscologit} with the {opt mlwin} option, it is the user's responsibility to declare the path for the MLwiN executable, see the {help runmlwin} helpfile for details. 

{phang}
{opt melogit} is used to call Stata's internal {cmd:meglm} command for the estimation of the multilevel multiscale ordered logit model. The option {opt melogop:tions(melogit_options)} may be used to pass on any estimation option 
available in {cmd:meglm}, other than the levels specification provided by {opt levelX(levelspec)}. By default, {cmd:mscologit} uses numerical derivatives and Stata's {opt difficult} option for ML estimation, 
so model convergence may be somewhat slower than usual.

{phang}
{opt gllamm} is used to call the {cmd:gllamm} ado command for the estimation of the multilevel multiscale ordered logit model. The use of {opt gllamm} requires that the {cmd:gllamm} ado has been installed before. 
As with the other multilevel estimation commands, the option {opt gllammop:tions(gllamm_options)} may be used to pass on any estimation option available in {cmd:gllamm}, other than the levels specification provided by {opt levelX(levelspec)}. 
By default, {cmd:mscologit} uses {cmd:gllamm}'s adaptive quadrature routine as well as Stata's {opt difficult} option for ML estimation, so model convergence may therefore be slower than usual.


{title:Examples}

{phang}
{it:Single-level model}

{phang2}
. mscologit depvar1 depvar2 depvar3, indvar(female educ age age2)

{phang}
{it:Single-level model, relaxing parallel regression assumption in the lower tail for all covariates, lower tail set to Pr(Y)<.33}

{phang2}
. mscologit depvar1 depvar2 depvar3, indvar(female educ age age2) lo lowcut(.33)

{phang}
{it:Single-level model, relaxing parallel regression assumption in the lower tail for selected covariates, lower tail set to Pr(Y)<.33}

{phang2}
. mscologit depvar1 depvar2 depvar3, indvar(female educ age age2) lo lowcut(.33) lowvar(female educ)

{phang}
{it:Multilevel model, using meglm/melogit}

{phang2}
. mscologit depvar1 depvar2 depvar3, indvar(female educ age age2) melogit level2(levvar:)

{phang}
{it:Multilevel model, using MLwiN/runmlwin}

{phang2}
. global MLwiN_path "C:\Program Files\MLwiN v3.05\mlwin.exe"
{p_end}
{phang2}
. gen cons = 1
{p_end}
{phang2}
. mscologit depvar1 depvar2 depvar3, indvar(female educ age age2) mlwin level2(levvar: cons) mlwopt(maxit(100) nopause)


{title:Stored results}

{phang}
{cmd:mscologit} implements direct ML estimation of the basic specification of the multiscale ordered logit model, and acts as a wrapper for {cmd:logit}, {cmd:meglm}, {cmd:gllamm}, or {cmd:runmlwin} 
when estimating multilevel or generalized specifications of the model. All stored results that are available after executing the original estimation commands, remain accessible after calling {cmd:mscologit}.
Likewise, the use of {cmd:predict} or {cmd:margins} is the same as when using the original estimation command that has been used in a run of the {cmd:mscologit} wrapper. To replay model estimates, use the original estimation command
 (i.e. {cmd:logit}, {cmd:meglm}, {cmd:gllamm}, and {cmd:runmlwin}).


{title:References}

{phang}
Agresti, Alan. 2010. Analysis of Ordinal Categorical Data. 2nd edition. Hoboken, NJ: Wiley.

{phang}
Fu, Vincent Kang. 1998. "Sg88: Estimating Generalized Ordered Logit Models." Stata Technical Bulletin 8:160-64.

{phang}
Fullerton, Andrew S. 2009. "A Conceptual Framework for Ordered Logistic Regression Models." Sociological Methods & Research 38(2):306-47. {browse "https://www.doi.org/10.1177/0049124109346162"}

{phang}
Fullerton, Andrew S. and Jun Xu. 2016. Ordered Regression Models: Parallel, Partial, and Non-Parallel Alternatives. Boca Raton, FL: Chapman and Hall/CRC.

{phang}
Williams, Richard. 2006. "Generalized Ordered Logit/Partial Proportional Odds Models for Ordinal Dependent Variables." Stata Journal 6(1):58-82. {browse "https://www.doi.org/10.1177/1536867X0600600104"}

{phang}
Williams, Richard. 2016. "Understanding and Interpreting Generalized Ordered Logit Models." Journal of Mathematical Sociology 40(1):7-20. {browse "https://www.doi.org/10.1080/0022250X.2015.1112384"}


{title:Author}

{pstd}
Markus Gangl
{p_end}
{pstd}
School of Social Sciences (FB03)
{p_end}
{pstd}
Goethe University Frankfurt am Main
{p_end}
{pstd}
{browse "mailto:mgangl@soz.uni-frankfurt.de"}

{phang}
{cmd:mscologit} is work in progress. The software comes without any warranties, but comments, bug reports, or any other 
suggestions for improvement are welcome!

{phang}
The development of {cmd:mscologit} has been made possible by the generous funding of the European Research Council (ERC) 
under the European Commission's Horizon 2020 research and innovation programme (Grant Agreement no. 833196). 
Neither the ERC nor the European Commission are responsible for this software or any of its uses.


{title:Suggested citation}

{phang}
Markus Gangl (2023). A Generalized Ordered Logit Model to Accommodate Multiple Rating Scales. {it:Sociological Methods & Research}.
{browse "https://www.doi.org/10.1177/00491241231186655"}


{title:Also see}

{phang}
{help logit}, {help ologit}, {help melogit}, {help meglm}, if installed: {help gologit}, {help gologit2}, {help gllamm}, {help runmlwin}
