{smcl}
{* *! version 4.0.0 05Nov2024}{...}
{viewerdialog metapreg "dialog metapreg"}{...}
{vieweralsosee "[ME] meqrlogit" "help meqrlogit"}{...}
{vieweralsosee "[ME] meqrlogit" "mansection ME meqrlogit"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[ME] melogit" "help melogit"}{...}
{vieweralsosee "[ME] melogit" "mansection ME melogit"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[ME] mecloglog" "help mecloglog"}{...}
{vieweralsosee "[ME] mecloglog" "mansection ME mecloglog"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] binreg" "help binreg"}{...}
{vieweralsosee "[R] binreg" "mansection R binreg"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] bayesmh" "help bayesmh"}{...}
{vieweralsosee "[R] bayesmh" "mansection R bayesmh"}{...}
{viewerjumpto "Syntax" "metapreg##syntax"}{...}
{viewerjumpto "Menu" "metapreg##menu"}{...}
{viewerjumpto "Description" "metapreg##description"}{...}
{viewerjumpto "Options" "metapreg##options"}{...}
{viewerjumpto "Remarks" "metapreg##remarks"}{...}
{viewerjumpto "Examples" "metapreg##examples"}{...}
{viewerjumpto "Stored results" "metapreg##results"}{...}

{title:Title}
{p2colset 5 18 25 2}{...}
{p2col :{opt metapreg} {hline 2}} Meta-analysis, meta-regression and network meta-analysis of proportions from binomial data using generalized linear models in the frequentist and Bayesian approach.{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
[{help by} {varlist}{cmd::}] 
{opt metapreg  {depvars}} 
[{indepvars}] 
{ifin}
{cmd:,} 
{opt st:udyid}({it:{help varname:studyid}}) 
[{it:{help metapreg##options_table:options}}]

{p 8 8 2}
{it:{depvars}} has the form {cmd: n N} in a {cmd: general/comparative/abnetwork} meta-analyses, {cmd: a b c d} in matched({cmd:mpair/mcbnetwork}) studies, and {cmd: ab ac N} in {cmd:pcbnetwork} studies.{p_end}

{p 8 8 2}
{it:studyid} is a variable identifying each study. The identifiers should be {cmd:unique} in a {cmd:general} meta-analysis.{p_end}
	
{p 8 8 2}
{it:{indepvars}} must be {cmd:labeled numeric} or {cmd:string} for categorical variables and {cmd:numeric} for continuous variables. Depending on the design of the analysis, 
there are {cmd:required} and {cmd:optional} covariates. The {cmd:required} covariates are as follows;

{p 12 12 2}
The first covariate must be a binary variable in {cmd: comparative} analysis, and a multi-category variable (with at least 2 levels) in {cmd: abnetwork} meta-analysis. 
In {cmd:mcbnetwork} or {cmd:pcbnetwork} studies, the first two covariates must be; {it: index} variable (multi-category; with at least 2 levels) and the {it:comparator} variable.

{p 8 8 2}
{cmd:The variable names and the category names should not contain underscores}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:metapreg} is a routine for meta-analysis of proportions 
from binomial data in the frequentist and bayesian framework. 
The binomial distribution is used to model the within-study variability ({help metapreg##Hamza2008:Hamza et al. 2008}). 
The weighting is implicit and proportional to the study size and within-study variance. 

{pstd}
The program fits a fixed, random-effects, or a mixed-effects model 
assuming binomial, common-rho beta-binomial or binomial-normal distribution with a logit, loglog or the cloglog link to the data.

{pstd}
A random- or mixed-effects model accounts for and allows the quantification of heterogeneity between 
(and within) studies while a fixed-effects model assumes homogeneity between the studies. 
By default, the exact binomial distribution is used when there are less than {cmd:3} studies. 

{pstd}
When there are no covariates, heterogeneity is quantified using the I-squared measure({help metapreg##ZD2014:Zhou and Dendukuri 2014}). 

{pstd}
The command requires {cmd:Stata 14.1} or later versions. {cmd:Stata 16.1} or later versions is required to perform the bayesian analysis.

{marker options_table}{...}
{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synoptline}

{synopt :{opth des:ign(metapreg##designtype:type[, designopts])}}specifies the type of the studies or design of meta-analysis; 
default is {cmd:design(general)}. {help metapreg##design_options:designopts} are relevant in abnetwork and comparative meta-analysis.{p_end}

{synopt :{opth m:odel(metapreg##modeltype:type[, modelopts])}}specifies the type of model to fit; default is {cmd:model(random)}. {help metapreg##optimization_options:modelopts} control the control the optimization process{p_end}

{synopt :{opt infe:rence(frequentist|bayesian)}}specificies the inferential approach; the default is {cmd:inference(frequentist)}.

{synopt :{opt bwd(pathdir)}} specificies the working directory to save the bayesian MCMC estimates{p_end}

{synopt :{opth li:nk(metapreg##linkfunction:function)}} specifies the function to transform the probabilities to a continuous scale that is unbounded. By default, the {cmd:logit} link is employed.{p_end}

{synopt :{opt mc}}informs the program to perform {cmd:m}odel {cmd:c}omparison with likelihood-ratio tests comparison for the specified model with other simpler models{p_end}

{synopt :{opth by:(varname:byvar)}} specifies that the summary estimates be stratified/grouped according to the variable declared. 
This is useful in meta-regression with more than one covariate and the {cmd:byvar} is not one of the covariates or 
when there are interactions and the first covariate is not an ideal grouping variable. 
By default, results are grouped according to the levels of the first categorical variable in the regression equation.
This option is not the same as the Stata {help by} prefix which repeates the analysis for each group of observation for 
which the values of the prefixed variable are the same.

{synopt :{opt str:atify}}requests for a stratified sub-analyses by the {opth by:(varname:byvar)} variable. The results are 
presented in one table and one forest plot {p_end}

{synopt : {opt int:eraction}}directs the model to include interaction terms between the first covariate and each of the remaining covariates{p_end}

{synopt :{opt a:lphasort}}directs the program to sort the categorical variables alphabetically {p_end}

{synopt :{opt prog:ress}} directs the program show the {cmd:progress} of the model estimation process{p_end}

{syntab:General}
{synoptline}
{synopt :{opth dp:(int:#)}}sets decimal points to display in the table and graph; default is {cmd:dp(2)}{p_end}

{synopt :{opth l:evel(level)}}sets confidence level for confidence/credible intervals; default is {cmd: level(95)}

{synopt :{opth pow:er(int:#)}}sets the exponentiating power with base 10 i.e. the power of ten with which to multiply the estimates. 
The default is {cmd: power(0)}. Any real value is allowed. Usage example, {cmd: power(2)} would report percentages.
The x-axis labels should be adjusted accordingly when power(#) is specified.

{synopt :{opt sums:tat(label)}}specifies the label(name) for proportions/relative ratios in the forest plot and/or corresponding table{p_end}

{synopt :{opt stat(mean|median)}}specifies the summary statistic. The default is the median.
The mean can be easily influenced by a small number of extreme values, hence may not be the most approapriate summary statistic of a skewed distribution; 
the median may be more appropriate.{p_end}
	
{synopt :{opth sor:tby(varlist)}}requests to sort the data by variables in {it:varlist}{p_end}

{synopt :{opth ci:method(metapreg##icitype:icitype, scitype)}}specifies how the confidence intervals 
for the individuals studies i.e {it:icitype} and/or the confidence/credible intervals of the summaries i.e. {help metapreg##scitype:scitype}) are computed. 

{synopt :{opt noove:rall}}suppresses the overall estimate; by default the overall estimate is displayed{p_end}

{synopt :{opt nosub:group}}prevents the display of within-group summary estimates. By default both within-group and overall summaries are displayed{p_end}

{synopt : {opt nowt:}}suppresses the display of the weights from the tables and forest plots.{p_end}

{synopt :{opt summary:only}} requests to only show the summary estimates. Useful when there are many studies within the groups.

{synopt :{opt down:load(pathdir)}}specify the location where a copy of data used to plot the forest plot should be stored {p_end}

{synopt :{opt sm:ooth}}requests the display of study-specific model-based estimates {p_end}

{synoptline}
{syntab:Tables}
{synoptline}
{synopt :{opt noita:ble}}suppresses the table with the study-specific estimates{p_end}

{synopt :{opt gof}} requests for the display the goodfness of fit statistics; Akaike information, Bayesian information criterion, or the Deviance information criterion in the bayeisan framework.{p_end}
{pmore}

{synopt :{opth sumt:able(metapreg##sumtable:metric)}}specifies which metric tables to display. The {it:metric} table(s) to display is one or more of the following; {cmd:none}, {cmd:logit}, {cmd:abs}, {cmd:rd}, {cmd:rr}, {cmd:lrr}, {cmd:or}, {cmd:lor}, {cmd:all}. 
By default {cmd:all} the summary tables are displayed{p_end}

{synoptline}
{syntab:Forest|Catterpillar plot}
{synoptline}

{synopt :{opth outp:lot(metapreg##outplot:plotmetric)}} specifies which metrics to plot. The {it:plotmetric} is one or more of the following; 
{cmd:abs}, {cmd:rd}, {cmd:rr}, {cmd:lrr}, {cmd:or} and {cmd:lor}.

{synopt :{opth label:([namevar=varname], [yearvar=varname])}} specifies that date be labelled by its name and/or year. Either or both variables 
need not be specified. For the table display, the overall length of the
label is restricted to 20 characters. The {cmd:lcols()} option will override this when specified.

{synopt :{opt nogr:aph}} suppresses the forest and catterpillar plots; by default the forest plot is displayed{p_end}

{synopt :{opt nofp:lot}} suppresses the forest plot; by default the forestplot is displayed{p_end}

{synopt :{opt catp:plot}} requests for the catterpillar plot; by default the catterpillar plot is not displayed{p_end}

{synopt :{opt noov:line}} suppresses the overall line; by default the overall line is displayed{p_end}

{synopt :{opt sub:line}}displays the group line; by default the group lines is not displayed{p_end}

{synopt :{opt nob:ox}}suppresses the display of weight boxes; by default the boxes are displayed{p_end}

{synopt :{opt xla:bel(list)}}defines x-axis labels. No checks are made as to whether these points are sensible. 
So the user may define anything if the {cmd:force} option is used. The points in the list {cmd:must} be comma separated.{p_end}

{synopt :{opt xt:ick(list)}}adds the listed tick marks to the x-axis. The points in the list {cmd:must}
be comma separated.{p_end}

{synopt :{opt nost:ats}}suppresses the display of empirical and model-based statistics {p_end}

{synopt :{opt tex:ts(#)}} increases or decreases the text size of the
texts by specifying {it:#} to be more or less than unity. The default is
usually satisfactory but may need to be adjusted.

{synopt :{opth lc:ols(varlist)}} define columns of additional data to 
the left of the plot. The columns are labelled with the variable label, or the variable name 
if this is not defined.

{synopt :{opth rc:ols(varlist)}}specifies additional columns to the right of the plot. The columns are labelled with the variable label, or the variable name 
if this is not defined.{p_end}

{synopt :{opt as:text(percentage)}} specifies the percentage of the graph to be taken up by text; 
default is {cmd:astext(50)}. The percentage must be in the range 10-90.

{synopt :{opt double:}} allows variables specified in {cmd:lcols(varlist)} and {cmd:rcols(varlist)} to 
run over two lines in the plot. This may be of use if long strings are to be used.

{synopt :{opth diam:opts(scatter##connect_options:connect_options)}} controls the appearance of the diamonds. 
See {help scatter##connect_options:connect_options} for the relevant options. e.g {cmd: diamopt(lcolor(red))}
displays {cmd:red} red diamond(s).

{synopt :{opth box:opts(scatter##marker_options:marker_options)}} controls the weight boxes for the study estimates. 
See {help scatter##marker_options:marker_options} for the relevant options. e.g {cmd: boxopt(mcolor(green))}

{synopt :{opth point:opts(scatter##marker_options:marker_options)}} controls the points for the study estimates. 
See {help scatter##marker_options:marker_options} for the relevant options. e.g {cmd: pointopt(msymbol(x) msize(0))}

{synopt :{opth cio:pts(scatter##connect_options:connect_options)}}controls the appearance of confidence intervals for studies. 
See {help scatter##connect_options:connect_options} for the relevant options.

{synopt :{opth ol:ineopts(scatter##connect_options:connect_options)}} controls the overall estimates line. 
See {help scatter##connect_options:connect_options} for the relevant options.

{synopt :{opt log:scale}} requests the plot to be in the (natural)log scale{p_end}

{synopt :{help twoway_options}} specifies overall graph options that would appear at the end of a
when all the different plots are combined together. This allows the addition of titles, subtitles, captions,
etc., control of margins, plot regions, graph size, aspect ratio, and the use of schemes.

{synoptline}
{p2colreset}{...}

{marker options}{...}
{title:Options}

{marker design_type}{...}
{dlgtab:Design}
{synoptline}

{pmore}
{cmd:design(general)} notifies the program to perform a general/typical meta-analysis. 
The data are from independent studies; where each row contains data from a different observation. 
The program expects atleast {cmd: n N} to be specified {p_end}

{pmore}
{cmd:design(comparative)} notifies the program that the data is from comparative studies i.e. 
there are two rows of data per each {cmd: studyid}. The first row has the index/treatment data and the second row has the control data.
The required {it:{vars}} has the form {cmd: n N bicat} 
where {it:bicat} is the first covariate which should be a string or labelled numeric variable with two levels. 

{pmore}
{cmd:design(mpair)} notifies the program that the data is from paired-matched studies. 
The program expects atleast {cmd: a b c d} to be is supplied. 
In the dataset, each row contains data from each seperate cross-tabulation between the index and the control group. 

{pmore}
{cmd:design(mcbnetwork)} notifies the program that the data is from matched studies and instructs to perform contrast-based network meta-analysis. 
In the dataset, each row contains data from each seperate cross-tabulation between the index and the control group. 
There can be more than one row of data per each {cmd: studyid}. The required {it:{vars}} has the form {cmd: a b c d index comparator}. 
{cmd: index comparator} are the first two covariates and both should be string or labelled numeric variables. {cmd:index} should have atleast two levels.
When there are matched observations from each study, the proportions are correlated. The confidence intervals for the individual studies are computed accounting for this correlation. 

{pmore}
{cmd:design(pcbnetwork)} indicates that the data is from paired studies and instructs to perform contrast-based network meta-analysis. There can be more than one row of data per each {cmd: studyid}. The required {it:{vars}} has the form {cmd: ab ac N index comparator}.
{cmd: index comparator} are the first two covariates and both should be string or labelled numeric variables. {cmd:index} should have atleast two levels.
{cmd: pcbnetwork} data is actually aggregated {cmd: matched} data where {cmd: ab = a + b}, {cmd: ac = a + c} and 
{cmd: n = a + b + c + d}. Because the {cmd: a b c d} is not available, there is unfortunately no way to account 
for the correlation when computing the confidence intervals for the individual studies.

{pmore}
{cmd:design(abnetwork)} instructs the program to perform arm-based network meta-analysis. 
The rquired {it:{vars}} has the form {cmd: n N cat} where {it:cat} is the 
first covariate which should be a string or labelled numeric variable with atleast two levels. 
There should be atleast two rows of data per {cmd:studyid}. In this design we view the treatments assigned in a study as nested factors within a study. 
The fitted models assumes exchangeability of the treatments effects and that the missing treatments are missing at random (MAR). 

{marker design_options}{...}
{pmore2}
{it: designopts}: {cmd:baselevel(string)}, {cmd:cov(covtype)}. These options are relevant in comparative and abnetwork model. 

{pmore2}
{cmd: baselevel(string)} Speficies the label of the reference level of the covariate of interest. 
The default is the first category in the dataset. Usage example {cmd:design(abnetwork, baselevel(label))}.

{pmore2}
{cmd: cov(covtype)} specifies the parameterization of the variance-covariance structure of the random-effects. {it:covtype} is one of the following;
{cmd:independent}, {cmd:unstructured}, {cmd:commonint}, {cmd:commonslope} and {cmd:freeint}. 

{pmore3}
{com:cov(independent)} is the default and  
assumes that event probabilities in the control group and treatment effects are independently normally distributed.

{pmore3}
{com:cov(unstructured)} assumes that event probabilities in the control groups and treatment effects are dependently normally distributed

{pmore3}
{com:cov(commonint)} assumes that event probabilities in the control groups are homogeneous and treatment effects are normally distributed

{pmore3}
{com:cov(commonslope)} assumes that event probabilities in the control groups are normally distributed and the treatment effect is homogeneous.

{pmore3}
{com:cov(freeint)} assumption-free control group event probabilities and normally distributed treatment effects.

{marker Inference}{...}
{dlgtab:Inferential Approch}
{synoptline}
{pmore}
{cmd: inference(frequentist)} Frequentist statistics represent the frequency of outcomes under long sequences of hypothetical trials.
In this approach, maximum likelihood estimation is used to obtain the model parameters. 
{helpb meqrlogit} or {helpb melogit} is used for the random-effects model and {helpb binreg} for the fixed-effects model. 
After fitting a random-effects, the posterior distributions are simulated 
to propagate uncertainity about the estimates({help metapreg##GH2007:Gelman and Hill 2006}). 

{pmore}
{cmd: inference(bayesian)} Bayesian statistics offer both practical utility and arguably greater interpretability.

{pmore}
The Bayesian approach is particularly advantageous when handling small study sizes, zero-event studies, 
and between-study heterogeneity across few studies. The Bayesian framework enhances estimation by incorporating weakly informative prior distributions based on plausible assumptions 
and yielding full posterior distributions for model parameters.

{pmore}
When a correlation between random effects is modeled, the inverse Wishart prior is applied, 
otherwise, an inverse-gamma prior (shape and scale = 0.01) is used for variance parameters. 
The inverse-gamma prior is conditionally conjugate for the variance components. 
Conjugacy enhances computational efficiency and numerical stability.

{pmore}
The default priors for the mean components are normal distributions with mean 0 and variance 10 i.e. N(0,10).
This corresponds to an OR centered at 1, reflecting an assumption of no treatment effect, or proportion centered at 0.5, 
reflecting an assumption of equal probability of success of event and no-event.

{pmore}
{helpb bayesmh} is used.

{marker modeltype}{...}
{dlgtab:Model}
{synoptline}
{pmore}
{opt model(type, modelopts)} specifies the type of model to fit. {it:type} is either {cmd:fixed}, {cmd:random}, {cmd:mixed}, {cmd:hexact}, or {cmd:crbetabin}. 

{pmore}
{cmd:model(hexact)} uses the exact binomial distribution. The model assumes that the studies are homogeneous. In {cmd:comparative} studies, the option instructs the 
program to perform exact logistic regression. This option is only feasible in the {cmd:frequentist} estimation approach. 
In a meta-analysis of rare events with few studies, the exact logistic regression model may provide 
more accurate inferences than the standard maximum-likelihood-based logistic regression estimator. 

{pmore}
{cmd:model(fixed)} fits a fixed-effects regression model to the data. The model assumes absence of between-study variability.

{pmore}
{cmd:model(random)} fits a random-effects model e.g. the logistic-normal regression model be fitted to the data when logit (default) link is specified.  

{pmore}
{cmd:model(mixed)} is synonymous to {cmd:model(random)}.  

{pmore}
{cmd:model(crbetabin)} fits common-rho beta-binomial distribution to the data. This requires the installation of the {search betabin}
This option is only feasible in the {cmd:frequentist} estimation approach. 
 
{pmore}
{opt modelopts} specifies the options that give the user
more control on the optimization process. The appropriate options 
feed into the {cmd:binreg}(see {it:{help binreg##maximize_options:maximize_options}}) when {cmd:model(fixed)}, 
{cmd:meqrlogit} (see {it:{help meqrlogit##maximize_options:maximize_options}} and 
{it:{help meqrlogit##laplace:integration_options}}) or {cmd:melogit} (see {it:{help melogit##maximize_options:maximize_options}}) for stata version 16 or higher. 
when {cmd:model(mixed)}, {cmd:betabin}(see {it:{help betabin##betabin_maximize}} when {cmd:model(crbetabin)}), or {cmd:bayesmh} (see {it:{help bayesmh##options_table}})
when {cmd:inference(bayesian)}

{pmore}
In the frequentist approach, the fixed-effects model is maximized using Stata's {help ml} command. This implies that
{cmd: irls} is inadmissible option and {cmd: ml} is implicit. Examples, {cmd: model(random, intpoint(9))} to increase the integration points, 
{cmd: model(random, technique(bfgs))} to specify Stata's BFGS maximiztion algorithm.

{marker linkfunction}{...}
{dlgtab:Link functions}
{synoptline}
{pmore}
{cmd:link(link)} specifies the function to transform the probabilities to a continuous scale that is unbounded. {it:link} is one of the following: {cmd:logit}, {cmd:loglog} and {cmd:cloglog}.

{pmore}
{cmd:link(logit)} is the default link function resulting to the logistic regression i.e. {it: p = exp(xb)/(1 + exp(xb))}.

{pmore}
{cmd:link(loglog)} request the use of the log-log link i.e. {it:p = exp(-exp(xb))}.

{pmore}
{cmd:link(cloglog)} request the use of the complementary log-log link i.e. {it:p = 1 - exp(-exp(xb))}.

{pmore} 
The logit link is symmetric because the probabilities approach zero or one at the same rate. 
The log-log  and complementary log-log  links are asymmetric. Complementary log-log link approaches zero slowly and one quickly. Log-log link approaches zero quickly and one slowly. 
Either the log-log or complementary log-log link will tend to fit better than logistic and are frequently used when the probability of an event is small or large. The reason that logit is so prevalent is because logistic parameters can be interpreted as odds ratios.
When the complementary log-log model holds for the probability of a success, the log-log model holds for the probability
of a failure.

{dlgtab:Study specific confidence intervals}
{synoptline}
{phang}
{opt cimethod(icitype[, scitype])} {cmd:icitype} and {cmd:scitype} depends on the metric requested. 
By default, proportions are displayed, {it:icitype} is exact confidence intervals, and {scitype} is t-distribution confidence intervals.
With comparative and matched data, the Koopman score{help metapreg##koopman1984:Koopman (1984)} 
and constrained maximum likelihood(cml){help metapreg##NB2002:Nam, and Blackwelder (2002)} confidence intervals for ratios are respectively computed.

{dlgtab 10 4:abs}
{pmore2}
The {it:icitype} for proportions is one of the following; {cmd:exact}, {cmd:wald}, {cmd:wilson}, {cmd:agresti}, or {cmd:jeffreys}.

{pmore2}
{opt exact} is the default for proportions and requests exact/Clopper-Pearson binomial confidence intervals.
The intervals are based directly on the binomial distribution unlike the Wilson score or Agresti-Coull. Their actual
coverage probability can be more than nomial value. This conservative nature of the interval means that they are widest, especially with 
small sample size and/or extreme probilities.

{pmore2}
{opt wald} requests for the Wald confidence intervals based on the quantiles from a normal distribution. 

{pmore2}
{opt wilson} requests for Wilson confidence intervals. 
Compared to the Wald confidence intervals, Wilson score intervals; 
have the actual coverage probability close to the nominal value
and have good properties even with small sample size and/or extreme probilities.
However, the actual confidence level does not converge to the nominal level as {it:n}
increases.

{pmore2}
{opt agresti} requests the Agresti-Coull({help metapreg##AC1998:Agresti, A., and Coull, B. A. 1998}) confidence intervals
The intervals have better coverage with extreme probabilities
but slightly more conservation than the Wilson score intervals.

{pmore2}
{opt jeffreys} requests for the Jeffreys confidence intervals.

{pmore2}
See {help metapreg##BCD2001:Brown, Cai, and DasGupta (2001)} and {help metapreg##Newcombe1998:Newcombe (1998)} for a discussion and
comparison of the different binomial confidence intervals.

{dlgtab 10 4:rr|lrr}
{pmore}

{tab}{ul:Comparative/pcbnetwork data}

{pmore2}
The {it:icitype} for proportions ratios from independent proprtions is one of the following; 
{cmd:koopman}, {cmd:katz}, {cmd:wilson}, {cmd:adlog}, {cmd:asinh}, {cmd:noether} or {cmd:bailey}.

{pmore2}
{opt koopman} requests for the Koopman asymptotic score confidence intervals; the {cmd:default}. These intervals have better coverage even for small sample size{p_end}

{pmore2}
{opt katz} requests for the Wald/Katz-log confidence intervals. {help metapreg##KATZ1978:Katz et al(1978)} {p_end}

{pmore2}
{opt adlog} requests for CI's computed using the adjusted-log method. {help metapreg##AHO2015:Aho & Bowyer (2015)}{p_end}

{pmore2}
{opt bailey} requests for CI's computed using the Bailey method. {help metapreg##BAI1987:Bailey(1987)}{p_end}

{pmore2}
{opt asinh} requests for CI's computed using the inverse hyperbolic sine transformation. {help metapreg##AHO2015:Aho & Bowyer (2015)}{p_end}

{pmore2}
{opt noether} requests for CI's computed using the the Noether procedure. {help metapreg##AHO2015:Aho & Bowyer (2015)}{p_end}
 
{tab}{ul:mpair/mcbnetwork data}

{pmore2}
The only {it:icitype} for proportions ratios from dependent proprtions is {cmd:cml}.
The confidence intervals are computed using constrained maximum likelihood (cml). 
These intervals have better coverage even for small sample size{p_end}

{dlgtab 10 4:or|lor}

{tab}{ul:Comparative/pcbnetwork data}
{pmore2}
{opt e:xact} computes the exact CI of the study odds ratio by inverting two one-sided Fishers exact tests. These {cmd:default} intervals are overly convservative. {p_end}

{pmore2}
{opt w:oolf} use Woolf approximation to calculate CI of the study odds ratio.{p_end}

{pmore2}
{opt co:rnfield} use Cornfield approximation to calculate CI of the study odds ratio. These intervals have better coverage even for small sample size{p_end}


{tab}{ul:mpair/mcbnetwork data}

{pmore2}
The only {it:icitype} for odds ratios from dependent proprtions is {cmd:mcnemar}, it computes the Mcnemar odds ratios and their confidence interval; the {cmd:default} for matched data{p_end}


{dlgtab 10 4:rd}

{pmore2}
The only {it:icitype} for proportions differences is {cmd:wald}, it computes Wald confidence intervals for the difference in proportions{p_end}

{marker scitype}{...}
{dlgtab:Summaries confidence/credible intervals}
{synoptline}
{tab}{ul:frequentist estimation}
{pmore2}
{opt t} computes confidence intervals using quantiles from t-distribution; the default{p_end}
{pmore2}
{opt wald} computes confidence intervals using quantiles from the normal distribution{p_end}

{tab}{ul:Bayesian estimation}
{pmore2}
{opt eti} extracts the equal-tailed credible intervals; the default{p_end}
{pmore2}
{opt hpd} extracts the highest posterior density credible intervals{p_end}

{dlgtab:Summary Tables}
{synoptline}
{pmore}
{opt sumtable(rr)} requests that the summary proportion ratios in a table. This options is applicable whenever there are categorical covariates in the model.

{pmore}
{opt sumtable(lrr)} requests that the summary log proportion ratios in a table. This options is applicable whenever there are categorical covariates in the model.

{pmore}
{opt sumtable(or)} requests that the summary odds ratios in a table. This options is applicable whenever there are categorical covariates in the model.

{pmore}
{opt sumtable(lor)} requests that the summary log odds ratios in a table. This options is applicable whenever there are categorical covariates in the model.

{pmore}
{opt sumtable(logit)}requests the display of the marginal/conditional log-odds summary estimates in a table{p_end}

{pmore}
{opt sumtable(abs)}requests the display of the marginal/conditional and population-averaged ({help metapreg##Pavlou_etal2015: Pavlou et al.(2015)}) summary proportions in a table{p_end}

{pmore}
{opt sumtable(rr)}requests the display of the marginal/conditional and population-averaged ({help metapreg##Pavlou_etal2015: Pavlou et al.(2015)}) summary proportion ratios in a table. 
This options is relevant whenever there are categorical covariates in the model.{p_end}

{pmore}
{opt sumtable(rd)}requests the display of the marginal/conditional and population-averaged ({help metapreg##Pavlou_etal2015: Pavlou et al.(2015)}) summary proportion differences in a table.
This options is relevant whenever there are categorical covariates in the model.{p_end}

{pmore}
{opt sumtable(or)}requests the display of the marginal/conditional and population-averaged ({help metapreg##Pavlou_etal2015: Pavlou et al.(2015)}) summary odds ratios in a table. 
This options is relevant whenever there are categorical covariates in the model.{p_end}

{pmore}
{opt sumtable(none)}requests the suppression of the summary tables{p_end}

{pmore}
{opt sumtable(all)}requests for all summary tables{p_end}

{dlgtab:Plotted Metric}
{synoptline}
{pmore}
{opt outplot(abs)} requests the display of the study-specific and summary proportions, 
the default and only option when design({cmd:general}).

{pmore}
{opt outplot(rr)} requests the display of the study-specific and summary proportion ratios. 
This is default when ({cmd:comparative}), design({cmd:abnetwork}), 
design({cmd:mpair}), design({cmd:pcbnetwork}), or design({cmd:mcbnetwork}).{p_end}

{pmore}
{opt outplot(rd)} requests the display of the study-specific and summary proportion differences. 
This option is relevant when in design({cmd:comparative}), design({cmd:abnetwork}), 
design({cmd:mpair}), design({cmd:pcbnetwork}), or design({cmd:mcbnetwork}).{p_end}

{pmore}
{opt outplot(lrr)} requests the display of the study-specific and summary log proportion ratios. 
This option is relevant when in design({cmd:comparative}), design({cmd:abnetwork}), 
design({cmd:mpair}), design({cmd:pcbnetwork}), or design({cmd:mcbnetwork}).{p_end}

{pmore}
{opt outplot(or)} requests the display of the study-specific and summary odds ratios. 
This option is relevant when in design({cmd:comparative}), design({cmd:abnetwork}), 
design({cmd:mpair}), design({cmd:pcbnetwork}), or design({cmd:mcbnetwork}).{p_end}

{pmore}
{opt outplot(lor)} requests the display of the study-specific and summary log odds ratios. 
This option is relevant when in design({cmd:comparative}), design({cmd:abnetwork}), 
design({cmd:mpair}), design({cmd:pcbnetwork}), or design({cmd:mcbnetwork}).{p_end}


{marker examples}{...}
{title:Examples}

{marker example_one_one}{...}
{cmd : 1. Intercept-only model}
{synoptline}

{pmore}
{cmd : 1.1 Summary by triage group}

{pmore}
The dataset used in examples 1.1-1.2 was used previously to produce Figure 1 
in {help metapreg##MA_etal2009:Marc Arbyn et al.(2009)}.

{pmore}
Fit a single model to all data and report summary estimates grouped by triage group. 

{pmore2}
{stata "use http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta":. use http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta}
{p_end}

{pmore2}
{cmd :. #delimit ;}
{p_end}

{pmore2}
{cmd :. metapreg num denom, }
{p_end}
{pmore3}
{cmd : studyid(study) }
{p_end}
{pmore3}
{cmd :by(tgroup) }
{p_end}
{pmore3}
{cmd :cimethod(exact) }
{p_end}
{pmore3}
{cmd :label(namevar=author, yearvar=year) catpplot }
{p_end}
{pmore3}
{cmd :xlab(.25, 0.5, .75, 1) }
{p_end}
{pmore3}
{cmd :subti(Atypical cervical cytology, size(4)) }
{p_end}
{pmore3}
{cmd :texts(1.5)  smooth gof;}	
{p_end}

{pmore2}
{cmd:. #delimit cr}
{p_end}

{pmore}
{it:({stata "metapreg_examples metapreg_example_one_one":click to run})}

{synoptline}

{pmore}
{cmd: 1.2 Different models by triage group}

{pmore}
With the {cmd: by(tgroup)} option in {help metapreg##example_one_one:Example1.1} the conditional estimates in each group are identical. 
To fit different models and obtain seperate tables and graphs for each group, use instead the {help by} prefix instead i.e {cmd: bysort tgroup:} 
or {cmd: by tgroup:} if {cmd:tgroup} is already sorted. The option {cmd:rc0} ensures that the program runs in all groups even when there could
be errors encountered in one of the sub-group analysis. Without the option, the program stops running when the 
first error occurs in one of the groups.

{pmore}
Fit a logistic regression for each category in triage group with specified x-axis label, Wilson confidence intervals for the studies, e.t.c.

{pmore2}
{stata "use http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta":. use http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta}
{p_end}

{pmore2}
{cmd:. #delimit ;}
{p_end}

{pmore2}
{cmd:. bys tgroup, rc0: metapreg num denom, }
{p_end}
{pmore3}
{cmd:studyid(study) }
{p_end}
{pmore3}
{cmd:cimethod(wilson) }
{p_end}
{pmore3}
{cmd:label(namevar=author, yearvar=year) catpplot }
{p_end}
{pmore3}
{cmd:xlab(.25, 0.5, .75, 1) }
{p_end}
{pmore3}
{cmd:subti(Atypical cervical cytology, size(4)) }
{p_end}
{pmore3}
{cmd:texts(1.5)  smooth;}
{p_end}
{pmore3}

{pmore2}
{cmd:. #delimit cr}
{p_end}

{pmore2}
{it:({stata "metapreg_examples metapreg_example_one_two":click to run})}


{synoptline}
{pmore}
{cmd : 1.3 Proportions near 0}

{pmore}
Logistic regression correctly handles the extreme cases appropriately without need for transformation or continuity correction. 

{pmore}
The dataset used in this example produced the top-left graph in figure two in
{help metapreg##Ioanna_etal2009:Ioanna Tsoumpou et al. (2009)}.

{pmore2}
{stata "use http://fmwww.bc.edu/repec/bocode/t/tsoumpou2009cancertreatrevfig2WNL.dta":. use http://fmwww.bc.edu/repec/bocode/t/tsoumpou2009cancertreatrevfig2WNL.dta}
{p_end}

{pmore2}
{cmd:.	metapreg p16p p16tot, ///}
{p_end}
{pmore3}
{cmd: studyid(study) ///}
{p_end}
{pmore3}
{cmd: label(namevar=author, yearvar=year) catpplot ///}
{p_end}
{pmore3}
{cmd: sortby(year author) ///}
{p_end}
{pmore3}
{cmd: xlab(0, .1, .2, 0.3, 0.4, 0.5) ///}
{p_end}
{pmore3}
{cmd: xline(0, lcolor(black)) ///}
{p_end}
{pmore3}
{cmd: ti(Positivity of p16 immunostaining, size(4) color(blue)) ///}
{p_end}
{pmore3}
{cmd: subti("Cytology = WNL", size(4) color(blue)) ///}
{p_end}
{pmore3}
{cmd: pointopt(msymbol(X) msize(2)) ///}
{p_end}
{pmore3}
{cmd: texts(1.5) smooth gof}
{p_end}
{pmore}
{it:({stata "metapreg_examples metapreg_example_one_three":click to run})}

{synoptline}

{pmore}
{cmd : 1.4 Proportions near 0 - loglog link}

{pmore}
The loglog regression is an extension of the logistic regression model and is particularly useful when the probability of an event is very small. 

{pmore2}
{stata "use http://fmwww.bc.edu/repec/bocode/t/tsoumpou2009cancertreatrevfig2WNL.dta":. use http://fmwww.bc.edu/repec/bocode/t/tsoumpou2009cancertreatrevfig2WNL.dta}
{p_end}

{pmore2}
{cmd:.	metapreg p16p p16tot, link(loglog) ///}
{p_end}
{pmore3}
{cmd: studyid(study) ///}
{p_end}
{pmore3}
{cmd: label(namevar=author, yearvar=year) catpplot ///}
{p_end}
{pmore3}
{cmd: sortby(year author) ///}
{p_end}
{pmore3}
{cmd: xlab(0, .1, .2, 0.3, 0.4, 0.5) ///}
{p_end}
{pmore3}
{cmd: xline(0, lcolor(black)) ///}
{p_end}
{pmore3}
{cmd: ti(Positivity of p16 immunostaining, size(4) color(blue)) ///}
{p_end}
{pmore3}
{cmd: subti("Cytology = WNL", size(4) color(blue)) ///}
{p_end}
{pmore3}
{cmd: pointopt(msymbol(X) msize(2)) ///}
{p_end}
{pmore3}
{cmd: texts(1.5) smooth gof}
{p_end}
{pmore}
{it:({stata "metapreg_examples metapreg_example_one_four":click to run})}

{synoptline}

{cmd: 2. Meta-regression}
{synoptline}
{pmore}
{cmd: 2.1 Independent studies}

{pmore}
 The use of {cmd: by(tgroup)} in {help metapreg##example_one_one:Example 1.2} only allows informal testing of differences between the sub-groups.
 The formal testing is perfomed by fitting a logistic regression with triage used as a categorical covariate. 
 
{pmore2}
{stata "use http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta":. use http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta}
{p_end}

{pmore2}
{cmd:. metapreg num denom tgroup, ///}
{p_end}
{pmore3}
{cmd:studyid(study) ///}
{p_end}
{pmore3}
{cmd:sumtable(all) ///}
{p_end}
{pmore3}
{cmd:cimethod(exact) ///}
{p_end}
{pmore3}
{cmd:label(namevar=author, yearvar=year)  ///}
{p_end}
{pmore3}
{cmd:xlab(.25, 0.5, .75) ///}
{p_end}
{pmore3}
{cmd:subti(Atypical cervical cytology, size(4)) ///}
{p_end}
{pmore3}
{cmd:texts(1.5)  summaryonly }
{p_end}

{pmore2}		
{it:({stata "metapreg_examples metapreg_example_two_one":click to run})}

{synoptline}
{pmore}
{cmd : 2.2 Comparative studies}

{synoptline}

{pmore}
{cmd: Incorporating weakly informative prior distributions based on plausible assumptions;}

{pmore2}
{cmd : 2.2.1 To overcome non-convergence issues - proportions near 0}

{pmore2}
{help metapreg##HEMKENS2016:Hemkens et al. (2016)} investigated the risk of fatal stroke after long-term colchicine use. 
Three out of four studies contained double-zero events.

{pmore2}
Fit a mixed-effects logistic regression model assuming event probabilities (logit scale) in the control groups and 
treatment effects (log ORs) are independently normally distributed i.e.  {cmd :design(comparative, cov(independent))}

{pmore2}
{stata "use https://github.com/VNyaga/Metapreg/blob/master/Build/hemkens2016analysis110.dta?raw=1":. use https://github.com/VNyaga/Metapreg/blob/master/Build/hemkens2016analysis110.dta?raw=1}
{p_end}

{pmore2}
{cmd :. gsort study -treatment}	
{p_end}

{pmore2}
{cmd :. #delimit ;}
{p_end}

{pmore2}
{cmd :. metapreg event total treatment,} 
{p_end}
{pmore3}
{cmd :studyid(study)} 
{p_end}
{pmore3}
{cmd :{ul:design(comparative, cov(independent))}} 
{p_end}
{pmore3}
{cmd :smooth gof  catpplot nofplot} 
{p_end}
{pmore3}
{cmd :outplot(rr)  xline(1) sumstat(Risk Ratio)} 
{p_end}
{pmore3}
{cmd :xlab(0, 1, 30) logscale} 
{p_end}
{pmore3}
{cmd :texts(2.35)  astext(80);} 
{p_end}

{pmore2}
{cmd:. #delimit cr}
{p_end}

{pmore}
{it:({stata "metapreg_examples metapreg_example_two_two_one":click to run})}

{pmore2}
The model does not converge, the point estimates and standard errors 
are {cmd:excessively large} or {cmd:undefined}. This occurs because 
the event probabilities are/close to zero and therefore, 
the likelihood function is almost flat, indicating limited information from the 
data about the parameters of interest. Consequently, 
the maximum likelihood algorithms struggled to converge, 
as gradient values near a flat surface were close to zero. 

{pmore2}
To switch to Bayesian estimation, add the options {cmd:inference(bayesian)} and {cmd:bwd(path)} 
where {it:path} is a directory path specifying the location where the simulation results containing 
MCMC samples should be saved. 

{pmore2}
{cmd :. global wdir "C:\DATA\WIV\Projects\Stata\Metapreg\mcmcresults"}	
{p_end}

{pmore2}
{cmd :. #delimit ;}
{p_end}

{pmore2}
{cmd :. metapreg event total treatment,} 
{p_end}
{pmore3}
{cmd :studyid(study)} 
{p_end}
{pmore3}
{cmd :design(comparative, cov(independent))}
{p_end}
{pmore3}
{cmd:{ul :inference(bayesian) bwd($wdir)}}
{p_end}
{pmore3}
{cmd :smooth gof  catpplot nofplot} 
{p_end}
{pmore3}
{cmd :outplot(rr)  xline(1) sumstat(Risk Ratio)} 
{p_end}
{pmore3}
{cmd :xlab(0, 1, 30) logscale} 
{p_end}
{pmore3}
{cmd :texts(2.35)  astext(80);} 
{p_end} 

{pmore2}
{cmd:. #delimit cr}
{p_end}

{pmore2}
The Bayesian estimate of the between-study variance components 
are {cmd:0.81} (variance of control group event probabilities in the logit scale) 
and {cmd:1.17} (treatment-effects in log OR scale). 
The population-averaged summary RR is {cmd:2.52 [0.09, 482.71]}. 

{synoptline}
{pmore2}
{cmd : 2.2.2 To enhance estimation of the between-study variance - three studies }

{pmore2}
{help metapreg##BENDER2018:Bender et al. (2018)} conducted a meta-analysis of three studies evaluating the risk of fever following sipuleucel-T therapy 
in asymptomatic or minimally symptomatic metastatic castrate-resistant prostate cancer. 

{pmore2}
Fit a mixed-effects logistic regression model assuming event probabilities (logit scale) in the control groups and 
treatment effects (log ORs) are independently normally distributed i.e.  {cmd :design(comparative, cov(independent))}

{pmore2}
{stata "use https://github.com/VNyaga/Metapreg/blob/master/Build/bender2018fig2.dta?raw=1":. use https://github.com/VNyaga/Metapreg/blob/master/Build/bender2018fig2.dta?raw=1}
{p_end}

{pmore2}
{cmd :. #delimit ;}
{p_end}

{pmore2}
{cmd :. metapreg event total treatment,} 
{p_end}
{pmore3}
{cmd :studyid(study) {ul:design(comparative, cov(independent))}} 
{p_end}
{pmore3}
{cmd :smooth gof  catpplot nofplot cimethod(,wald)} 
{p_end}
{pmore3}
{cmd :outplot(rr) xline(1) sumstat(Risk Ratio) } 
{p_end}
{pmore3}
{cmd :xlab(1, 5, 30) logscale} 
{p_end}
{pmore3}
{cmd :texts(2) astext(70);} 
{p_end}

{pmore2}
{cmd:. #delimit cr}
{p_end}

{pmore}
{it:({stata "metapreg_examples metapreg_example_two_two_two":click to run})}

{pmore2}
The frequentist estimates for the between-study variance components are both very close to zero 
reducing the model to fixed-effects logistic regression. The population-averaged summary RR is {cmd:2.63 [1.83, 3.71]}. 

{pmore2}
Switch to Bayesian estimation by add the options {cmd:inference(bayesian)} and {cmd:bwd(path)} 
where {it:path} is a directory path specifying the location where the simulation results containing 
MCMC samples should be saved. 

{pmore2}
{cmd :. global wdir "C:\DATA\WIV\Projects\Stata\Metapreg\mcmcresults"}	
{p_end}

{pmore2}
{cmd :. #delimit ;}
{p_end}

{pmore2}
{cmd :. metapreg event total treatment,} 
{p_end}
{pmore3}
{cmd :studyid(study) design(comparative, cov(independent))} 
{p_end}
{pmore3}
{cmd:{ul :inference(bayesian) bwd($wdir)}}
{p_end}
{pmore3}
{cmd :smooth gof  catpplot nofplot} 
{p_end}
{pmore3}
{cmd :outplot(rr) xline(1) sumstat(Risk Ratio) } 
{p_end}
{pmore3}
{cmd :xlab(1, 5, 30) logscale} 
{p_end}
{pmore3}
{cmd :texts(2) astext(70);} 
{p_end}

{pmore2}
{cmd:. #delimit cr}
{p_end}

{pmore2}
The Bayesian estimate of the between-study variance components 
are {cmd:0.05} (variance of control group event probabilities in the logit scale) and {cmd:0.06} (treatment-effects in log OR scale). 
The population-averaged summary RR is {cmd:2.75 [1.90, 4.35]}. 

{synoptline}
{pmore2}
{cmd : 2.2.3 To enhance estimation of the between-study variance - meta-regression of sparse studies}

{pmore2}
{help metapreg##HEMKENS2016:Hemkens et al. (2016)} investigated the risk of cardiovascular mortality after long-term colchicine use. 
The meta-analysis included seven studies, two with double-zero events and three with single-zero events. 

{pmore2}
Fit a mixed-effects logistic regression model assuming event probabilities (logit scale) in the control groups are homogeneous and 
treatment effects (log ORs) are normally distributed i.e.  {cmd :design(comparative, cov(commonint))}

{pmore2}
{stata "use https://github.com/VNyaga/Metapreg/blob/master/Build/hemkens2016analysis18.dta?raw=1":. use https://github.com/VNyaga/Metapreg/blob/master/Build/hemkens2016analysis18.dta?raw=1}
{p_end}

{pmore2}
{cmd :. gsort study -treatment}	
{p_end}

{pmore2}
{cmd :. #delimit ;}
{p_end}

{pmore2}
{cmd :. metapreg event total treatment,} 
{p_end}
{pmore3}
{cmd :studyid(study)} 
{p_end}
{pmore3}
{cmd :{ul:design(comparative, cov(commonint))}}
{p_end}
{pmore3}
{cmd :smooth gof catpplot nofplot}  
{p_end}
{pmore3}
{cmd :outplot(rr) xline(1)  sumstat(Risk Ratio)}
{p_end}
{pmore3}
{cmd :xlab(0.01, 1, 100) logscale}
{p_end}
{pmore3}
{cmd :texts(1.75) astext(60);}
{p_end}

{pmore2}
{cmd:. #delimit cr}
{p_end}

{pmore}
{it:({stata "metapreg_examples metapreg_example_two_two_three":click to run})}

{pmore2}
The frequentist estimate of the treatment effect between-study variance is very close zero ({cmd:4.69e-33}) 
reducing the model to fixed-effects logistic regression. The population-averaged summary RR is {cmd:0.20 [0.06, 0.63]}. 

{pmore2}
To switch to Bayesian estimation, add the options {cmd:inference(bayesian)} and {cmd:bwd(path)} 
where {it:path} is a directory path specifying the location where the simulation results containing 
MCMC samples should be saved. 

{pmore2}
{cmd :. global wdir "C:\DATA\WIV\Projects\Stata\Metapreg\mcmcresults"}	
{p_end}

{pmore2}
{cmd :. #delimit ;}
{p_end}

{pmore2}
{cmd :. metapreg event total treatment,} 
{p_end}
{pmore3}
{cmd :studyid(study)} 
{p_end}
{pmore3}
{cmd :design(comparative, cov(commonint))}
{p_end}
{pmore3}
{cmd:{ul :inference(bayesian) bwd($wdir)}}
{p_end}
{pmore3}
{cmd :smooth gof catpplot nofplot}  
{p_end}
{pmore3}
{cmd :outplot(rr)  sumstat(Risk Ratio)}
{p_end}
{pmore3}
{cmd :xlab(0.01, 1, 100) logscale}
{p_end}
{pmore3}
{cmd :xline(1) texts(1.75) astext(60);}
{p_end}

{pmore2}
{cmd:. #delimit cr}
{p_end}

{pmore2}
The Bayesian estimate of the treatment effect between-study variance is {cmd:0.15}. 
The population-averaged summary RR was {cmd:0.22 [0.05, 0.71]}. 

{synoptline}

{pmore2}
{cmd : 2.2.4 BCG Vaccination - categorical covariate}

{pmore2}
The data used in examples 3.1-3.3 are as presented in table IV of {help metapreg##Berkey_etal1995:Berkey et al. (1995)}
By supplying the risk-ratios and their variability, {help metapreg##Sharp1998:Sharp (1998)} Sharp demonstrates meta-analysis of odds-ratios with the {help meta} command. 
He fitted a random and a fixed effects model to the data. 

{pmore2}
The logistic regression model appropriately accounts for both within- and between-study heterogeneity, with vaccination arm as a covariate. 
The options {cmd:comparative} indicates that the data is comparative. The first covariate {cmd:bcg}, identifies the first and the second observations of the pair. 
The risk-ratios are requested with the option {cmd:outplot(rr)}. 
   
{pmore2}
{stata `"use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta""':. use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta"}
{p_end}

{pmore2}
{cmd: .metapreg cases_tb population bcg,  /// }
{p_end}
{pmore3}
{cmd: studyid(study) model(mixed, intmethod(mv)) ///}
{p_end}
{pmore3}
{cmd: design(comparative, cov(commonslope))	///}
{p_end}
{pmore3}
{cmd: outplot(rr) ///}
{p_end}
{pmore3}
{cmd: sumstat(Risk ratio) ///}
{p_end}
{pmore3}
{cmd: xlab(0, 1, 2) /// }
{p_end}
{pmore3}
{cmd: xtick(0, 1, 2)  /// }
{p_end}
{pmore3}
{cmd: logscale smooth  gof ///} 
{p_end}
{pmore3}
{cmd: rcols(cases_tb population) /// }
{p_end}
{pmore3}
{cmd: astext(80) /// }
{p_end}
{pmore3}
{cmd: texts(1.5)}  
{p_end}

{pmore2} 
{it:({stata "metapreg_examples metapreg_example_two_two_four":click to run})}

{synoptline}

{pmore2}
{cmd : 2.2.5  BCG Vaccination - Continous covariate}

{pmore2}
We investigate whether altitude has an effect on the vaccination by including {cmd:alt} as a continous covariate.

{pmore2}
{stata `"use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta""':. use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta"}
{p_end}

{pmore2}
{cmd: .metapreg cases_tb population lat,  /// }
{p_end}
{pmore3}
{cmd: studyid(study) model(mixed, intmethod(mv)) ///}
{p_end}
{pmore3}
{cmd: sortby(lat) by(bcg)  ///}
{p_end}
{pmore3}
{cmd: sumstat(Proportion) ///}
{p_end}
{pmore3}
{cmd: xlab(0, 0.05, 0.15) /// }
{p_end}
{pmore3}
{cmd: xtick(0, 0.05, 0.15)  /// }
{p_end}
{pmore3}
{cmd: rcols(cases_tb population) /// }
{p_end}
{pmore3}
{cmd: astext(80) /// }
{p_end}
{pmore3}
{cmd: texts(1.5) smooth gof}
{p_end}

{pmore2} 
{it:({stata "metapreg_examples metapreg_example_two_two_five":click to run})}

{synoptline}
{pmore2}
{cmd :2.2.6 BCG Vaccination - Interaction between covariates}

{pmore2}
With {help metareg}, {help metapreg##Sharp1998:Sharp (1998)} investigaged the effect of latitude on BCG vaccination. 
The analysis suggested that BCG vaccination was more effective at higher absolute latitude.

{pmore2}
We now fit a logistic regression model with {cmd:bcg}, a categorical variable for the arm and {cmd:lat}, a continous variable with absolute latitude. 

{pmore2}
Activated by the option {cmd:interaction}, an interaction term allows to assess whether the log OR for arm vary by absolute latitude. 

{pmore2}
The interaction term from {cmd:metapreg} and the coefficient for lat using {cmd:metareg} as was done by {help metapreg##Sharp1998:Sharp (1998)} are equivalent. 

{pmore2}
{stata `"use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta""':. use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta"}
{p_end}

{pmore2}
{cmd:. metapreg cases_tb population bcg lat,  /// }
{p_end}
{pmore3}
{cmd:studyid(study) model(mixed, intmethod(mv)) ///}
{p_end}
{pmore3}
{cmd:sortby(lat) ///}
{p_end}
{pmore3}
{cmd:design(comparative, cov(commonslope))  ///}
{p_end}
{pmore3}
{cmd:outplot(rr) ///}
{p_end}
{pmore3}
{cmd:interaction ///}
{p_end}
{pmore3}
{cmd:xlab(0, 1, 2) ///} 
{p_end}
{pmore3}
{cmd:xtick(0, 1, 2)  /// }
{p_end}
{pmore3}
{cmd:rcols(cases_tb population) ///} 
{p_end}
{pmore3}
{cmd:astext(80) ///} 
{p_end}
{pmore3}
{cmd:texts(1.5) logscale smooth gof }  
{p_end}

{pmore2}
{it:({stata "metapreg_examples metapreg_example_two_two_six":click to run})}

{synoptline}

{pmore2}
{cmd : 2.2.7 Sparse data -  interaction between covariates}

{pmore2}
Using {help metan}, {help metapreg##Chaimani_etal2014:Chaimani et al. (2014)} informaly assessed the difference in treatment effect of haloperidol compared to placebo in treating schizophrenia.
{p_end}

{pmore2}
The analysis is more appropriately perfomed using {cmd:metapreg} by including {cmd:arm} and {cmd:missingdata} as covariates. 
{p_end}

{pmore2}
The {cmd:interaction} term allows to test whether the risk-ratios for arm differ between the group with and without missing data.
{p_end}

{pmore2}
{stata `"use "http://fmwww.bc.edu/repec/bocode/s/schizo.dta""':. use "http://fmwww.bc.edu/repec/bocode/s/schizo.dta"}
{p_end}

{pmore2}
{cmd:. sort firstauthor arm }
{p_end}

{pmore2}
{cmd:. metapreg response total arm missingdata,  ///}
{p_end}
{pmore3}
{cmd:studyid(firstauthor) ///}
{p_end}
{pmore3}
{cmd:sortby(year) ///}
{p_end}
{pmore3}
{cmd:design(comparative, cov(commonslope))  ///}
{p_end}
{pmore3}
{cmd:interaction ///}
{p_end}
{pmore3}
{cmd:xlab(0, 5, 15) ///}
{p_end}
{pmore3}
{cmd:xtick(0, 5, 15)  /// }
{p_end}
{pmore3}
{cmd:sumstat(Rel Ratio) ///}
{p_end}
{pmore3}
{cmd:lcols(response total year) /// }
{p_end}
{pmore3}
{cmd:astext(70) /// }
{p_end}
{pmore3}
{cmd:texts(1.5) logscale smooth gof}

{pmore2}		
{it:({stata "metapreg_examples metapreg_example_two_two_seven":click to run})}

{synoptline}
{pmore2}
{cmd : 2.3 matched Studies }

{synoptline}

{pmore2}
{cmd : 2.3.1 Comparison of two tests in reproducibility studies}

{pmore2}
We demonstrate the use of {cmd:mpair} option using data from reproducibility studies containing paired hrHPV test 
results in self-samples and clinician-collected samples.
The data in each study should be a from a 2x2 table as displayed below;

{p 24} {c |} Clinician sample {p_end}
{pmore2} 
Self sample {c |} Positive{space 5}Negative {c |} Total
{p_end}
{pmore2}
{c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -}{c -} {c -} {c -} {c -} {c -}
{p_end}
{p 16} 
Positive{c |} {space 3} pp {space 7}	pn {space 5 } {c |} pp + pn
{p_end}
{p 16} 
Negative{c |} {space 3} np {space 7}	nn {space 5} {c |}  np + nn
{p_end}
{pmore2}
{c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -}{c -} {c -} {c -} {c -} {c -}
{p_end}
{p 18}
Total {c |} pp + np {space 5} pn + nn  {space 4}{c |} pp + pn + np + nn
{p_end}

{pmore2}
The options {cmd:stratify by(type)} facilitate the estimation of the test positivity ratio for each {cmd:type}, but presented all results presented in a single plot.

{pmore2}
{stata `"use "https://github.com/VNyaga/Metapreg/blob/master/Build/repro.dta?raw=1""':. use "https://github.com/VNyaga/Metapreg/blob/master/Build/repro.dta?raw=1"}
{p_end}

{pmore2}
{cmd:. metapreg pp pn np nn,  ///}
{p_end}
{pmore3}
{cmd:{ul:design(mpair, cov(commonslope))}  ///}
{p_end}
{pmore3}
{cmd:studyid(paper) ///}
{p_end}
{pmore3}
{cmd:stratify by(type) ///}
{p_end}
{pmore3}
{cmd:xlab(0.5, 1, 2) ///}
{p_end}
{pmore3}
{cmd:sumstat(Positivity Ratio) ///}
{p_end}
{pmore3}
{cmd:lcols(test) ///}
{p_end}
{pmore3}
{cmd:boxopts(msize(0.1) mcolor(black)) pointopt(msymbol(none))///}
{p_end}
{pmore3}
{cmd:astext(50)  logscale  xline(1) smooth }
{p_end}

{pmore2}		
{it:({stata "metapreg_examples metapreg_example_two_three_one":click to run})}

{synoptline}

{pmore2}
{cmd : 2.3.2 Contrast-based network meta-analysis}

{pmore2}
We demonstrate the use of {cmd:mcbnetwork} option when matched data is available. The data should be a from a 2x2 table as displayed below;

{p 18} 
{c |} comparator
{p_end}
{pmore2} 
index {c |} Positive{space 5}Negative {c |} Total
{p_end}
{pmore2}
{c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -}
{p_end}
{p 10} 
Positive{c |} {space 3} a {space 7}	b {space 5 } {c |} a + b
{p_end}
{p 10} 
Negative{c |} {space 3} c {space 7}	d {space 5} {c |}  c + d
{p_end}
{pmore2}
{c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -} {c -}
{p_end}
{pmore2}
Total {c |} a + c {space 5} b + d  {space 4}{c |} a + b + c + d
{p_end}

{pmore2}
{stata `"use "http://fmwww.bc.edu/repec/bocode/m/matched.dta""':. use "http://fmwww.bc.edu/repec/bocode/m/matched.dta"}
{p_end}

{pmore2}
{cmd:. metapreg a b c d index comparator,  ///}
{p_end}
{pmore3}
{cmd:studyid(study) ///}
{p_end}
{pmore3}
{cmd:model(fixed)  ///}
{p_end}
{pmore3}
{cmd:design(mcbnetwork)  ///}
{p_end}
{pmore3}
{cmd:by(comparator) ///}
{p_end}
{pmore3}
{cmd:xlab(0.9, 1, 1.1) xtick(0.9, 1, 1.1) ///}
{p_end}
{pmore3}
{cmd:sumstat(Ratio) ///}
{p_end}
{pmore3}
{cmd:lcols(comparator index) ///}
{p_end}
{pmore3}
{cmd:astext(80) texts(1.2) logscale smooth }
{p_end}

{pmore2}		
{it:({stata "metapreg_examples metapreg_example_two_three_two":click to run})}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:metapreg} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(rawest)}}raw conditional summary estimates in the log-odds/log-log/complementary log-log scale depending on the link specified{p_end}
{synopt:{cmd:e(absout)}}conditional summary proportions{p_end}
{synopt:{cmd:e(exactabsout)}}Exact summary proportions{p_end}
{synopt:{cmd:e(rrout)}}conditional summary relative ratios when there categorical covariates{p_end}
{synopt:{cmd:e(rdout)}}conditional summary proportion differences when there categorical covariates{p_end}
{synopt:{cmd:e(orout)}}conditional summary odds ratios when there categorical covariates{p_end}
{synopt:{cmd:e(popabsout)}}population-averaged summary proportions{p_end}
{synopt:{cmd:e(poprrout)}}population-averaged summary relative ratios when there categorical covariates{p_end}
{synopt:{cmd:e(poplrrout)}}population-averaged summary log relative ratios when there categorical covariates{p_end}
{synopt:{cmd:e(poporout)}}population-averaged summary odds ratios when there categorical covariates{p_end}
{synopt:{cmd:e(poplorout)}}population-averaged summary log odds ratios when there categorical covariates{p_end}
{synopt:{cmd:e(poprdout)}}population-averaged summary proportion difference(s) when there categorical covariates{p_end}
{synopt:{cmd:e(covmat)}}Estimates of between-study variance components after a fitting a random-effects model{p_end}
{synopt:{cmd:e(hetout)}}between-study heterogeneity statistics after a fitting a random-effects model{p_end}
{synopt:{cmd:e(mctest)}}model compariston statistics after meta-regression{p_end}
{synopt:{cmd:e(nltest)}}hypothesis test statistics for equality of  relative ratio{p_end}
{synopt:{cmd:e(gof)}}goodness of fit information{p_end}
{p2colreset}{...}

{pstd}
Available model {cmd:estimates}:

{synoptset 24 tabbed}{...}
{synopt:{cmd:metapreg_modest}}estimates from the fitted model{p_end}

{title:Author}
{pmore}
Victoria N. Nyaga ({it:Victoria.NyawiraNyaga@sciensano.be}) {p_end}
{pmore}
Belgian Cancer Center/Unit of Cancer Epidemiology, {p_end}
{pmore}
Sciensano,{p_end}
{pmore} 
Juliette Wytsmanstraat 14, {p_end}
{pmore}
B1050 Brussels, {p_end}
{pmore}
Belgium.{p_end}


{title:References}

{marker AC1998}{...}
{phang}
Agresti, A., and Coull, B. A. 1998. Approximate is better than 'exact'
for interval estimation of binomial proportions. {it:The American Statistician.}
52:119-126. 

{marker GH2007}{...}
{phang}
Gelman A., and Hill J. 2006. Simulation of probability models and statistical inferences. In: Data analysis using regression and multilevel/hierachical models.
Cambridge university press.


{marker ZD2014}{...}
{phang}
Zhou, Y., and Dendukuri, N. 2014. Statistics for quantifying heterogeneity in univariate 
and bivariate meta-analyses of binary data: The case of meta-analyses of diagnostic accuracy.
{it:Statistics in Medicine} 33(16):2701-2717.

{marker BCD2001}{...}
{phang}
Brown, L. D., T. T. Cai, and A. DasGupta. 2001.  
Interval estimation for a binomial proportion. 
{it:Statistical Science} 16: 101-133.

{marker CP1934}{...}
{phang}
Clopper, C. J., and E. S. Pearson. 1934.  The
use of confidence or fiducial limits illustrated in the case of the binomial.  
{it:Biometrika} 26: 404-413.

{marker Hamza2008}{...}
{phang}
Hamza et al. 2008. The binomial distribution of meta-analysis was preferred to model within-study variability. 
{it:Journal of Clinical Epidemiology} 61: 41-51.

{marker HT2001}{...}
{phang}
Higgins, J. P. T., and S. G. Thompson.  2001. Presenting random-effects
meta-analyses: Where we are going wrong?  {it:9th International Cochrane
Colloquium, Lyon, France}.

{marker DL1986}{...}
{phang}
DerSimonian, R. and Laird, N. 1986. Meta-analysis in clinical trials. {it:Controlled Clinical Trials} 7(3):177-188. 

{marker Newcombe1998}{...}
{phang}
Newcombe, R. G. 1998. Two-sided confidence intervals for 
the single proportion: comparison of seven models. 
{it:Statistics in Medicine} 17: 857-872.

{marker Pavlou_etal2015}{...}
{phang}
Pavlou M. et. al. 2015.
A note on obtaining correct marginal predictions from a random intercepts model for binary outcomes.
{it:BMC Medical Research modelology} 15(1):1-6

{marker MA_etal2009}{...}
{phang}
Arbyn, M., et al. 2009. Triage of women with equivocal
or low-grade cervical cytology results.  A meta-analysis
of the HPV test positivity rate.
{it:Journal for Cellular and Molecular Medicine} 13(4):648-59.

{marker Ioanna_etal2009}{...}
{phang}
Tsoumpou, I., et al. 2009. p16INK4a immunostaining in 
cytological and histological specimens from the uterine 
cervix: a systematic review and meta-analysis. 
{it:Cancer Treatment Reviews} 35: 210-20.

{marker Sharp1998}{...}
{phang}
Stephen Sharp. 1998. sbe23. Meta-analysis regression. 
{it:Stata Technical Bulletin} 16-22.

{marker Berkey_etal1995}{...}
{phang}
Berkey, C., et al. 1995. A random-effects regression model for meta-analysis. 
{it:Statistics in Medicine} 14:395-411.

{marker Chaimani_etal2014}{...}
{phang}
Chaimani, A., Mavridis, D., & Salanti G. 2014. A hands-on practical tutorial on perfoming meta-analysis with Stata. 
{it:Evidence Based Mental Health} 17(4):111-116.

{marker koopman1984}{...}
{phang}
Koopman, P. 1984. Confidence Intervals for the Ratio of Two Binomial Proportions. 
{it:Biometrics} 40(2):513.

{marker NB2002}{...}
{phang}
Nam, J. & Blackwelder, W. 2002. Analysis of the ratio of marginal probabilities in a matched-pair setting. 
{it:Statistics in Medicine} 21(5):689-699.

{marker AHO2015}{...}
{phang}
Aho, K., & Bowyer, T. 2015. Confidence intervals for ratios of proportions: implications for selection ratios. {it:Methods in Ecology and Evolution} 6: 121-132.

{marker BAI1987}{...}
{phang}
Bailey, B.J.R. (1987) Confidence limits to the risk ratio. {it:Biometrics} 43(1): 201-205.

{marker KATZ1978}{...}
{phang}
Katz, D., Baptista, J., Azen, S. P., & Pike, M. C. (1978) Obtaining confidence intervals for the risk ratio in cohort studies. {it:Biometrics} 34: 469-474

{marker BENDER2018}{...}
{phang}
Bender, R., et al. (2018) Methods for evidence synthesis in the case of very few studies. {it:Res Syn Meth} 9:382-392

{marker HEMKENS2016}{...}
{phang}
Hemkens, L.G, et al. (2016) Colchicine for prevention of cardiovascular events. {it:Cochrane Database of Systematic Reviews} Issue 1. Art. No.: CD011047