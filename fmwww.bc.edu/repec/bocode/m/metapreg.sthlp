{smcl}
{* *! version 3.0.2 14Nov2023}{...}
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
{viewerjumpto "Syntax" "metapreg##syntax"}{...}
{viewerjumpto "Menu" "metapreg##menu"}{...}
{viewerjumpto "Description" "metapreg##description"}{...}
{viewerjumpto "Options" "metapreg##options"}{...}
{viewerjumpto "Remarks" "metapreg##remarks"}{...}
{viewerjumpto "Examples" "metapreg##examples"}{...}
{viewerjumpto "Stored results" "metapreg##results"}{...}

{title:Title}
{p2colset 5 18 25 2}{...}
{p2col :{opt metapreg} {hline 2}} Fixed-effects, random-effects and mixed-effects meta-analysis, meta-regression and network meta-analysis
of proportions with binomial distribution and logit, loglog and cloglog links{p_end}
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
{it:{depvars}} has the form {cmd: n N} in a {cmd: basic/comparative/abnetwork} meta-analysis, {cmd: a b c d} in matched({cmd:mcbnetwork}) studies, and {cmd: ab ac N} in {cmd:pcbnetwork} studies.{p_end}

{p 8 8 2}
{it:studyid} is a variable identifying each study.{p_end}
	
{p 8 8 2}
{it:{indepvars}} must be {cmd:string} for categorical variables and {cmd:numeric} for continuous variables. Depending on the design of the analysis, 
there are {cmd:required} and {cmd:optional} covariates. The {cmd:required} covariates must be string variables. The {cmd:required} covariates are as follows;

{p 12 12 2}
The first covariate must be a binary variable in {cmd: comparative} analysis, and a multi-category variable (with at least 2 levels) in {cmd: abnetwork} meta-analysis. 
In {cmd:mcbnetwork} or {cmd:pcbnetwork} studies, two first string covariates required are; {it: index} variable (multi-category; with at least 2 levels) and the {it:comparator} variable.

{p 8 8 2}
{cmd:The variable names and the group names in the string variables should not contain underscores}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:metapreg} is a routine for meta-analysis of proportions 
from binomial data; the exact binomial distrubtion or a generalized linear model for the binomial family with a logit, loglog or the cloglog link is fitted. 

{pstd}
The program fits fixed or a random-effects model. The data can be from independent studies; where each row contains data from seperate studies, 
comparative studies; where each study has two rows of data. The first row has the index data and the second row has the control data. The data can also be matched, 
where each row contains data from each seperate cross-tabulation between the index and the control test. When only the marginal data from the cross-tabulation is available, 
then we refer this as paired data. 

{pstd}
In {cmd:abnetwork} meta-analysis, each study contributes atleast two rows of data from different treatments/tests. In this setting we view the treatments assigned in a study as nested factors within a study. 
The fitted models assumes exchangeability of the treatments effects and that the missing treatments are missing at random (MAR). 

{pstd}
A random-effects model accounts for and allows the quantification of heterogeneity between (and within) studies while a fixed-effects model assumes homogeneity in studies. 
By default, the exact binomial distribution is used when there are less than {cmd:3} studies.

{pstd}
In a comparative/mcbnetwork/pcbnetwork meta-analysis, the study-specific proportion ratios or odds ratios can be tabulated and/or plotted.

{pstd}
When there are no covariates, heterogeneity is also quantified using the I-squared measure({help metapreg##ZD2014:Zhou and Dendukuri 2014}).
In abnetwork meta-analysis, we quantify the proportion of unexplained variation due to within and between study variability.

{pstd}
The command requires Stata 14.1 or later versions.

{marker options_table}{...}
{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synoptline}

{synopt :{opth m:odel(metapreg##modeltype:type[, modelopts])}}specifies the type of model to fit; default is {cmd:model(random)}. 
{help metapreg##optimization_options:modelopts} control the control the optimization process{p_end}
{synopt :{opt li:nk(logit|loglog|cloglog)}} specifies the function to transform the probabilities to a continuous scale that is unbounded. By default, the {cmd:logit} link is employed.{p_end}
{synopt :{opth des:ign(metapreg##designtype:design[, designopts])}}specifies the type of the studies or design of meta-analysis; default is {cmd:design(basic)}. 
{help metapreg##design_options:designopts} are relevant in abnetwork and comparative meta-analysis.{p_end}
{synopt :{opt nomc}}informs the program not to perform {cmd:m}odel {cmd:c}omparison with likelihood-ratio tests comparison for the specified model with other simpler models{p_end}
{synopt :{opth by:(varname:byvar)}}specificies the stratifying variable for which the margins are estimated {p_end}
{synopt : {opt int:eraction}}directs the model to include interaction terms between the first covariate and each of the remaining covariates{p_end}
{synopt :{opt a:lphasort}}sort the categorical variables alphabetically {p_end}
{synopt :{opt prog:ress}}show the {cmd:progress} of the model estimation process{p_end}

{synoptline}
{syntab:General}
{synoptline}
{synopt :{opt str:atify}}requests for a consolidated sub-analyses by the {opth by:(varname:byvar)} variable{p_end}
{synopt :{opth dp:(int:#)}}sets decimal points to display; default is {cmd:dp(2)}{p_end}
{synopt :{opth l:evel(level)}}sets confidence level; default is {cmd: level(95)}{p_end}
{synopt :{opth pow:er(int:#)}}sets the exponentiating power; default is {cmd: power(0)}. {cmd:#} is any real value {p_end}
{synopt :{opt sums:tat(label)}}specifies the label(name) for proportions/relative ratios in the graph {p_end}
{synopt :{opth sor:tby(varlist)}}requests to sort the data by variables in {it:varlist}{p_end}
{synopt :{opth ci:method(metapreg##citype:icitype,ocitype)}}specifies how the confidence intervals 
for the individuals({it:icytpe}) studies or the overall({it:ociytpe}) summaries are computed; default {it:icytpe} is {cmd:cimethod(exact)} for proportions and {cmd:cimethod(koopman)} for relative ratios{p_end}
{synopt :{opt noove:rall}}suppresses the overall estimate; by default the overall estimate is displayed{p_end}
{synopt :{opt nosub:group}}prevents the display of within-group summary estimates. By default both within-group and overall summaries are displayed{p_end}
{synopt : {opt nowt:}}suppresses the display of the weights from the tables and forest plots.{p_end}
{synopt :{opt summary:only}}requests to show only the summary estimates{p_end}
{synopt :{opth outp:lot(metapreg##outplot:abs|rr|or)}}specifies to display/plot absolute/relative measures; default is {cmd:outplot(abs)}{p_end}
{synopt :{opth down:load(path)}}specify the location where a copy of data used to plot the forest plot should be stored {p_end}
{synopt :{opt sm:ooth}}requests the study-specific smooth estimates {p_end}

{synoptline}
{syntab:Table}
{synoptline}
{synopt :{opt noita:ble}}suppresses the table with the study-specific estimates{p_end}
{synopt :{opt gof}}display the Akaike information and Bayesian information criterion{p_end}
{synopt :{opth sumt:able(metapreg##sumtable:none|logit|abs|rr|or|all)}}specifies to display the which tables to display {cmd:logits}, 
{cmd:proportions} and/or the {cmd:ratios} of proportions or odds; by default all the summary tables are displayed{p_end}


{synoptline}
{syntab:Forest plot}
{synoptline}
{synopt :{opth label:(varname:[namevar=varname], [yearvar=varname])}}specifies that date be labelled by its name and/or year{p_end}
{synopt :{opt predi:ction}}compute and display the predictive intervals(proportions only){p_end}
{synopt :{opt nogr:aph}}suppresses the forest plot; by default the forestplot is displayed{p_end}
{synopt :{opt noov:line}}suppresses the overall line; by default the overall line is displayed{p_end}
{synopt :{opt nob:ox}}suppresses the display of weight boxes; by default the boxes are displayed{p_end}
{synopt :{opt sub:line}}displays the group line; by default the group lines is not displayed{p_end}
{synopt :{opt xla:bel(list)}}defines x-axis labels. No checks are made as to whether these points are sensible. 
So the user may define anything if the {cmd:force} option is used. The points in the list {cmd:must} be comma separated.{p_end}
{synopt :{opt xt:ick(list)}}adds the listed tick marks to the x-axis. The points in the list {cmd:must}
be comma separated.{p_end}
{synopt :{opt nost:ats}}suppresses the display of study specific proportions(or the relative ratios) and the confidence intervals{p_end}
{synopt :{opt tex:ts(#)}}indicates the text size of the labels and texts. Default is 1 {p_end}
{synopt :{opth lc:ols(varlist)}}specifies additional columns to the left of the plot{p_end}
{synopt :{opth rc:ols(varlist)}}specifies additional columns to the right of the plot{p_end}
{synopt :{opt as:text(percentage)}}specifies the percentage of the graph to be taken up by text; default is {cmd:astext(50)}{p_end}
{synopt :{opt double:}}allows variables specified in {cmd:lcols(varlist)} and {cmd:rcols(varlist)} to run over two lines in the plot{p_end}
{synopt :{opth diam:opts(scatter##connect_options:connect_options)}}controls the diamonds{p_end}
{synopt :{opth box:opts(scatter##marker_options:marker_options)}}controls the weight boxes{p_end}
{synopt :{opth point:opts(scatter##marker_options:marker_options)}}controls the points for the study estimates{p_end}
{synopt :{opth cio:pts(scatter##connect_options:connect_options)}}controls the appearance of confidence intervals for studies{p_end}
{synopt :{opth pred:ciopts(scatter##connect_options:connect_options)}}controls the appearance of the prediction intervals for studies{p_end}
{synopt :{opth ol:ineopts(scatter##connect_options:connect_options)}}controls the overall and subgroup estimates line{p_end}
{synopt :{opt log:scale}}requests the plot to be in the (natural)log scale{p_end}
{synopt :{help twoway_options}}specifies other overall graph options{p_end}


{synoptline}
{marker designtype}{...}
{synoptline}
{synopthdr :design}
{synoptline}

{synopt :{opt general}} notifies the program to perform a general/typical meta-analysis. The program expects atleast {cmd: n N} to be specified {p_end}
{synopt :{opt comparative}} notifies the program that the data is from comparative studies. The program expects atleast {cmd: n N bicat} to be specified {p_end}
{synopt :{opt pcbnetwork}} notifies the program that the data is from paired studies. The program expects atleast {cmd: a b c d index comparator} to be is supplied{p_end}
{synopt :{opt mcbnetwork}} notifies the program that the data is from matched studies. The program expects atleast {cmd: ab ac n index comparator} to be is supplied{p_end}
{synopt :{opt abnetwork}} instructs the program to perform abnetwork meta-analysis. The program expects atleast {cmd: n N cat} to be specified {p_end}

{synoptline}
{marker modeltype}{...}
{synoptline}
{synopthdr :model type}
{synoptline}

{synopt :{opt random|mixed}}fits a {cmd:random}-effects or {cmd:mixed}-effects logistic-normal model{p_end}
{synopt :{opt fixed}}fits a {cmd:fixed}-effects logistic regression model{p_end}
{synopt :{opt hexact}}uses the exact binomial distribution{p_end}

{synoptline}

{marker citype}{...}
{synopthdr :citype}
{synoptline}
{dlgtab:abs}

{synopt :{opt exact}}computes exact confidence intervals; the default{p_end}
{synopt :{opt wald}}computes Wald confidence intervals{p_end}
{synopt :{opt wilson}}computes Wilson confidence intervals{p_end}
{synopt :{opt agres:ti}}computes Agresti-Coull confidence intervals{p_end}
{synopt :{opt jeff:reys}}computes Jeffreys confidence intervals{p_end}

{dlgtab:rr}

{synopt :{opt koopman}}computes Koopman asymptotic score confidence intervals; the {cmd:default} for comparative/paired studies. These intervals have better coverage even for small sample size{p_end}
{synopt :{opt cml}}computes constrained maximum likelihood (cml) confidence intervals; the {cmd:default} for matched data. These intervals have better coverage even for small sample size{p_end}

{dlgtab:or}

{synopt :{opt e:xact}}computes the exact CI of the study odds ratio by inverting two one-sided Fishers exact tests. These {cmd:default} intervals are overly convservative. {p_end}
{synopt :{opt w:oolf}}use Woolf approximation to calculate CI of the study odds ratio.{p_end}
{synopt :{opt co:rnfield}} use Cornfield approximation to calculate CI of the study odds ratio. These intervals have better coverage even for small sample size{p_end}


{synoptline}
{marker sumtable}{...}
{synopthdr :sumtable}
{synoptline}
{synopt :{opt abs}}requests the display of the conditional and population-averaged proportions in a table{p_end}
{synopt :{opt rr}}requests the display of the conditional and population-averaged risk ratios in a table{p_end}
{synopt :{opt or}}requests the display of the conditional and population-averaged odds ratios in a table{p_end}
{synopt :{opt logit}}requests the display of the conditional log-odds estimates of the fitted model in a table{p_end}
{synopt :{opt none}}requests the suppression of the summary tables{p_end}

{synoptline}
{marker outplot}{...}
{synopthdr :outplot}
{synoptline}
{synopt :{opt abs}}requests the display of the study-specific and overall absolute measures in a table and /or a graph; the default{p_end} 
{synopt :{opt rr}}requests the display of the study-specific and summary risk ratios in a table and /or a graph. This is an option when studies are comparative, abnetwork or cbnetwork analysis{p_end}
{synopt :{opt or}}requests the display of the study-specific and summary odds ratios in a table and /or a graph. This is an option when studies are comparative, abnetwork or cbnetwork analysis{p_end}


{synoptline}
{p2colreset}{...}

{marker options}{...}
{title:Options}

{marker design_options}{...}
{dlgtab:Design options}

{phang}
{opt design(type, designopts)} specifies the type of the studies or design of the meta-analysis to perform. 
{it:design} is one of the following {cmd:basic},
{cmd:comparative}, {cmd:mcbnetwork}, {cmd:pcbnetwork} and {cmd:abnetwork}. {opt designopts} specifies the options that give the user
more control parameterization of the comparative and abnetwork model. 

{pmore}
{cmd:design(basic)} requests for a basic meta-analysis. The required {it:{vars}} has the form {cmd: n N}.

{pmore}
{cmd:design(comparative)} indicates that the data is from comparative studies i.e there are two rows of data per each {cmd: studyid}. The required {it:{vars}} has the form {cmd: n N bicat} 
where {it:bicat} is the first covariate which should be a string variable with two levels. When there are two random effects in the model, their covariance structure can be
specified as {it:independent} with {cmd:design(comparative,cov(independent))} or {it:unstructured} {cmd:design(comparative,cov(unstructured))}

{pmore}
{cmd:design(mcbnetwork)} indicates that the data is from matched studies and instructs to perform contrast-based network meta-analysis. There can be more than one row of data per each {cmd: studyid}. The required {it:{vars}} has the form {cmd: a b c d index comparator}. 
{cmd: index comparator} are the first two covariates and both should be string variables. {cmd:index} should have atleast two levels.
When there are matched observations from each study, the proportions are correlated. 
The confidence intervals for the individual studies are computed accounting for this correlation. 

{pmore}
{cmd:design(pcbnetwork)} indicates that the data is from paired studies and instructs to perform contrast-based network meta-analysis. There can be more than one row of data per each {cmd: studyid}. The required {it:{vars}} has the form {cmd: ab ac N index comparator}.
{cmd: index comparator} are the first two covariates and both should be string variables. {cmd:index} should have atleast two levels.
{cmd: pcbnetwork} data is actually aggregated {cmd: matched} data where {cmd: ab = a + b}, {cmd: ac = a + c} and 
{cmd: n = a + b + c + d}. Because the {cmd: a b c d} is not available, there is unfortunately no way to account 
for the correlation when computing the confidence intervals for the individual studies.

{pmore}
{cmd:design(abnetwork)} instructs to perform arm-based network meta-analysis. The rquired {it:{vars}} has the form {cmd: n N cat} where {it:cat} is the 
first covariate which should be a string with atleast two levels. 
There should be atleast two rows of data per {cmd:studyid}. {cmd:baselevel(label)} is relevant in abnetwork meta-analysis 
and indicates the label of the reference level of the covariate of interest. The correct use is {cmd:design(abnetwork, baselevel(label))} 

{dlgtab:Model}

{phang}
{opt model(type, modelopts)} specifies the type of model to fit. {it:type} is either {cmd:fixed},  {cmd:random}, {cmd:mixed} or {cmd:hexact}. 

{pmore}
{cmd:model(hexact)} uses the exact binomial distribution. The model assumes that the studies are homogeneous.

{pmore}
{cmd:model(fixed)} fits a fixed-effects logistic regression model to the data. The model assumes that the studies are homogeneous.


{pmore}
{cmd:model(random)} fits a random-effects (also called mixed-effects) model i.e. logistic-normal regression model be fitted to the data.  

{pmore}
{opt modelopts} specifies the options that give the user
more control on the optimization process. The appropriate options 
feed into the {cmd:binreg}(see {it:{help binreg##maximize_options:maximize_options}}) 
or {cmd:meqrlogit} (see {it:{help meqrlogit##maximize_options:maximize_options}} and 
{it:{help meqrlogit##laplace:integration_options}}) or {cmd:melogit} (see {it:{help melogit##maximize_options:maximize_options}}) for stata version 16 or higher. 

{pmore}
The fixed-effects model is maximized using Stata's {help ml} command. This implies that
{cmd: irls} is inadmissible option and {cmd: ml} is implicit. 

{pmore}
Examples, {cmd: model(random, intpoint(9))} to increase the integration points, 
{cmd: model(random, technique(bfgs))} to specify Stata's BFGS maximiztion algorithm.

{phang}
{cmd:link(link)} specifies the function to transform the probabilities to a continuous scale that is unbounded. {it:link} is one of the following: {cmd:logit}, {cmd:loglog} and {cmd:cloglog}.

{pmore}{cmd:link(logit)} is the default link function resulting to the logistic regression i.e. {it: p = exp(xb)/(1 + exp(xb))}.

{pmore}{cmd:link(loglog)} request the use of the log-log link i.e. {it:p = exp(-exp(xb))}.

{pmore}{cmd:link(cloglog)} request the use of the complementary log-log link i.e. {it:p = 1 - exp(-exp(xb))}.

{pmore} The logit link is symmetric because the probabilities approach zero or one at the same rate. 
The log-log  and complementary log-log  links are asymmetric. Complementary log-log link approaches zero slowly and one quickly. Log-log link approaches zero quickly and one slowly. 
Either the log-log or complementary log-log link will tend to fit better than logistic and are frequently used when the probability of an event is small or large. The reason that logit is so prevalent is because logistic parameters can be interpreted as odds ratios.
When the complementary log-log model holds for the probability of a success, the log-log model holds for the probability
of a failure.

{phang}
{cmd:by(byvar)} specifies that the summary etsimates be stratified/grouped according to the variable declared. This is useful in meta-regression with more than one covariate,
and the {cmd:byvar} is not one of the covariates or when there are interactions and the first covariate is not an ideal grouping variable. By default, results are grouped according to the 
levels of the first categorical variable in the regression equation.


{pmore}
This option is not the same as the Stata {help by} prefix which repeates the analysis for each group of observation for which the values of the prefixed variable are the same.

{dlgtab:General}

{phang}
{opt stratify} requests for a consolidated sub-analyses by the {opth by:(varname:byvar)} variable. The results are 
presented in one table and one forest plot 

{phang}
{opt dp(#)} sets decimal points to display in the table and graph; default is {cmd:dp(2)}{p_end}

{phang}
{opth level(level)} sets confidence level for confidence and prediction intervals; default is {cmd: level(95)}

{phang}
{opt power(#)} sets the exponentiating power with base 10; default is {cmd: power(0)}. Any real value is allowed. 
indicates the power of ten with which to multiply the estimates. 
{cmd: power(2)} would report percentages.
The x-axis labels should be adjusted accordingly when power(#) is adjusted.

{phang}
{opt sumstat(label)} specifies the label(name) for proportions/relative ratios in the forest plot and/or corresponding table{p_end}
 
{phang}
{opth sortby(varlist)} requests to sort the data by variables in {it:varlist}{p_end}

{phang}
{opt cimethod(icitype, ocitype)} specifies how the confidence intervals of the proportions are computed
for the individuals ({it:icitype}) studies or the summaries({it:ocitype}) when the exact binomial distribution is used. 

{pmore}
{opt cimethod(exact)} is the default for proportions and specifies exact/Clopper-Pearson binomial confidence intervals.
The intervals are based directly
on the binomial distribution unlike the Wilson score or Agresti-Coull. Their actual
coverage probability can be more than nomial value. This conservative nature
of the interval means that they are widest, especially with 
small sample size and/or extreme probilities.

{pmore}
{opt cimethod(wald)} specifies the Wald confidence intervals. 

{pmore}
{opt cimethod(wilson)} specifies Wilson confidence intervals. 
Compared to the Wald confidence intervals, Wilson score intervals; 
have the actual coverage probability close to the nominal value
and have good properties even with small sample size and/or extreme probilities.
However, the actual confidence level does not converge to the nominal level as {it:n}
increases.

{pmore}
{opt cimethod(agresti)} specifies the Agresti-Coull({help metapreg##AC1998:Agresti, A., and Coull, B. A. 1998}) confidence intervals
The intervals have better coverage with extreme probabilities
but slightly more conservation than the Wilson score intervals.

{pmore}
{opt cimethod(jeffreys)} specifies the Jeffreys confidence intervals

{pmore}
See {help metapreg##BCD2001:Brown, Cai, and DasGupta (2001)} and {help metapreg##Newcombe1998:Newcombe (1998)} for a discussion and
comparison of the different binomial confidence intervals.

{pmore}
With comparative and matched data, the Koopman score{help metapreg##koopman1984:Koopman (1984)} 
and constrained maximum likelihood(cml){help metapreg##NB2002:Nam, and Blackwelder (2002)} confidence intervals for ratios are respectively computed.

{phang}
{opt nooverall} suppresses the overall estimate; by default the overall estimate is displayed. This automatically
enforces the {cmd: nowt} option.

{phang}
{opt nowt} suppresses the display of the weight{p_end}

{phang}
{opt nosubgroup} prevents the display of within-group summary estimates. By default both within-group and overall summaries are displayed{p_end}

{phang}
{opt outplot(abs|rr|or)} specifies to plot absolute/relative proportions; default is {cmd:outplot(abs)}. 

{pmore} 
{opt outplot(abs)} is the default and specifies that the proportions be presented in the table and/or in the graph. 

{pmore}
{opt outplot(rr)} requests that the proportion ratios be presented in the table and/or in the graph. This options is relevant with abnetwork, matched, pcbnetwork or comparative data. 

{pmore}
{opt outplot(or)} requests that the odds ratios be presented in the table and/or in the graph. This options is relevant with abnetwork, matched, pcbnetwork or comparative data. 

{phang}
{opt summaryonly} requests to show only the summary estimates. Useful when there are many studies in the groups.

{phang}
{opt smooth} requests for the model-based study-specific estimates.


{dlgtab:Table}
{phang}
{opt sumtable(none|logit|abs|rr|or|all)} requests no summary table, summary log odds, summary proportions, summary proportion ratios, and summary odds ratios from the the fitted model be presented in a table. 

{pmore}
{opt sumtable(rr)} requests that the summary proportion ratios be presented in the table. This options is whenever there are categorical covariates in the model.

{pmore}
{opt sumtable(or)} requests that the summary odds ratios be presented in the table. This options is whenever there are categorical covariates in the model.

{pmore}
{opt gof} display the goodfness of fit statistics; Akaike information and Bayesian information criterion.{p_end}

{dlgtab:Forest plot}
{phang}
{cmd:prediction}
displays the confidence interval of the approximate predictive
distribution of a future study, based on the extent of heterogeneity in the random-effects model.

{pmore}
Uncertainty on the spread of the random-
effects distribution using the formula {cmd: t(N-k) x sqrt(se2 + tau2)}
where t is the t-distribution with N-k degrees of freedom (N is the number of studies, k is the number of the model parameters), se2 is the
squared standard error and tau2 the heterogeneity statistic.
Note that with <3 studies the distribution is inestimable and effectively infinite, while heterogeneity is zero there is still
a slight extension as the t-statistic is always greater than the corresponding
normal deviate. For further information, see {help metapreg##HT2001:Higgins and Thompson 2001}.

{phang}
{opt label([namevar=varname] [yearvar=varname])}specifies that date be labelled by its name and/or year. Either or both variables 
need not be specified. For the table display, the overall length of the
label is restricted to 20 characters. The {cmd:lcols()} option will override this when specified.

{phang}
{opt noovline} suppresses the overall line; by default the overall line is displayed{p_end}

{phang}
{opt subline} displays the group line; by default the group lines is not displayed{p_end}

{phang}
{opt xlabel(list)} defines x-axis labels. No checks are made as to whether these points are sensible. 
So the user may define anything if the {cmd:force} option is used. The points in the list {cmd:must} be comma separated.{p_end}

{phang}
{opt xtick(list)} adds the listed tick marks to the x-axis. The points in the list {cmd:must}
be comma separated.{p_end}

{phang}
{opt nostats} suppresses the display of study specific proportions(or the relative ratios) and the confidence intervals{p_end}

{phang}
{opt nobox} suppresses the display of weight boxes{p_end}

{phang}
{opt texts(#)} increases or decreases the text size of the
label by specifying {it:#} to be more or less than unity. The default is
usually satisfactory but may need to be adjusted.

{phang}
{cmd:lcols(}{it:varlist}{cmd:)}, {cmd:rcols(}{it:varlist}{cmd:)} 
define columns of additional data to 
the left or right of the plot. The first column on the right is 
automatically set to the estimate, unless suppressed using 
the options {cmd:nostats}. {cmd:texts()} can be used to fine-tune 
the size of the text in order to achieve a satisfactory appearance. 
The columns are labelled with the variable label, or the variable name 
if this is not defined. The first variable specified in {cmd:lcols()} is assumed to be
the study identifier and this is used in the table output. 

{phang}
{opt astext(percentage)} specifies the percentage of the graph to be taken up by text; 
default is {cmd:astext(50)}. The percentage must be in the range 10-90.

{phang}
{opt double} allows variables specified in {cmd:lcols(varlist)} and {cmd:rcols(varlist)} to 
run over two lines in the plot. This may be of use if long strings are to be used.

{phang}
{opth diamopt(options)} controls the appearance of the diamonds. 
See {help scatter##connect_options:connect_options} for the relevant options. e.g {cmd: diamopt(lcolor(red))}
displays {cmd:red} red diamond(s).

{phang}
{opt boxopts(options)} controls the weight boxes for the study estimates. 
See {help scatter##marker_options:marker_options} for the relevant options. e.g {cmd: boxopt(mcolor(green))}

{phang}
{opt pointopt(options)} controls the points for the study estimates. 
See {help scatter##marker_options:marker_options} for the relevant options. e.g {cmd: pointopt(msymbol(x) msize(0))}

{phang}
{opt ciopt(options)} ontrols the appearance of confidence intervals for studies. 
See {help scatter##connect_options:connect_options} for the relevant options.

{phang}
{opt logscale} requests the plot to be in the (natural)log scale{p_end}

{phang}
{opt predciopt(options)} controls the appearance of the prediction intervals for studies.
See {help scatter##connect_options:connect_options} for the relevant options.

{phang}
{opt olineopt(options)} controls the overall and subgroup estimates line. 
See {help scatter##connect_options:connect_options} for the relevant options.
	
{phang}
{help twoway_options} specifies overall graph options that would appear at the end of a
when all the different plots are combined together. This allows the addition of titles, subtitles, captions,
etc., control of margins, plot regions, graph size, aspect ratio, and the use of schemes.

{marker remarks}{...}
{title:Remarks}
{pstd}
{helpb meqrlogit} or {helpb melogit} is used for the random-effects model and {helpb binreg} for the fixed-effects model. 
The binomial distribution is used to model the within-study variability ({help metapreg##Hamza2008:Hamza et al. 2008}).
The weighting is implicit and proportional to the study size and within-study variance. The estimation of the model parameters is an iterative procedure. 
The parameters are maximum likelihood estimates. 


{marker examples}{...}
{title:Examples}
{marker example_one}{...}
{cmd : 1.1 Intercept-only model and summary by triage group}

{pmore}
The dataset used in examples 1.1-1.3 was used previously to produce Figure 1 
in {help metapreg##MA_etal2009:Marc Arbyn et al. (2009)}.

{pmore}
Intercept-only model and summary estimates grouped by triage group,
with specified x-axis label, e.t.c. 

{pmore2}
{stata "use http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta":. use http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta}
{p_end}

{pmore2}
{cmd :. decode tgroup, g(STRtgroup)}
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
{cmd :by(STRtgroup) }
{p_end}
{pmore3}
{cmd :cimethod(exact) }
{p_end}
{pmore3}
{cmd :label(namevar=author, yearvar=year) }
{p_end}
{pmore3}
{cmd :xlab(.25, 0.5, .75, 1) }
{p_end}
{pmore3}
{cmd :subti(Atypical cervical cytology, size(4)) }
{p_end}
{pmore3}
{cmd :graphregion(color(white)) }
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
{cmd: 1.2 Seperate intercept-only model by triage group}

{pmore}
With the {cmd: by(STRtgroup)} option in {help metapreg##example_one:Example1.1} the estimates in each group are similar. 
To obtain seperate tables and graphs, use instead the {help by} prefix instead i.e {cmd: bysort tgroup:} 
or {cmd: by tgroup:} if {cmd:tgroup} is already sorted. The option {cmd:rc0} ensures that the program runs in all groups even when there could
be errors encountered in one of the sub-group analysis. Without the option, the program stops running when the 
first error occurs in one of the groups.

{pmore}
Fitting logistic regression for each category in triage group,
with specified x-axis label, Wilson confidence intervals for the studies, e.t.c.

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
{cmd:label(namevar=author, yearvar=year) }
{p_end}
{pmore3}
{cmd:xlab(.25, 0.5, .75, 1) }
{p_end}
{pmore3}
{cmd:graphregion(color(white)) }
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
{cmd: 1.3 Meta-regression with tgroup as a covariate}

{pmore}
 The use of {cmd: by(tgroup)} in {help metapreg##example_one:Example1.1} only allows informal testing of heterogeneity between the sub-groups.
 The formal testing is perfomed by fitting a logistic regression with triage used as a categorical variable and {cmd:entered in string format}. 
 Since {cmd:tgroup} is a factor variable, the {help decode} function creates the new string variable based on the existing numerical variable and its value labels.

{pmore}
Triage group as a covariate, display all summary tables, e.t.c.

{pmore2}
{stata "use http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta":. use http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta}
{p_end}

{pmore2}
{cmd:. decode tgroup, g(STRtgroup)}
{p_end}

{pmore2}
{cmd:. metapreg num denom STRtgroup, ///}
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
{cmd:label(namevar=author, yearvar=year) ///}
{p_end}
{pmore3}
{cmd:xlab(.25,0.5,.75,1) ///}
{p_end}
{pmore3}
{cmd:subti(Atypical cervical cytology, size(4)) ///}
{p_end}
{pmore3}
{cmd:graphregion(color(white))  ///}
{p_end}
{pmore3}
{cmd:texts(1.5)  summaryonly }
{p_end}

{pmore2}		
{it:({stata "metapreg_examples metapreg_example_one_three":click to run})}

{synoptline}
{marker example_two_one}{...}
{cmd : 2.1 Proportions near 0 - Intercept-only model - Logit link}

{pmore}
Logistic regression correctly handles the extreme cases appropriately without need for transformation. Options for the forest plot; specified x-axis label, ticks on x-axis added,
suppressed weights, increased text size, a black diamond for the confidence intervals of the pooled estimate, a black vertical line at zero, a red dashed line, for the pooled estimate, e.t.c.

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
{cmd: label(namevar=author, yearvar=year) ///}
{p_end}
{pmore3}
{cmd: sortby(year author) ///}
{p_end}
{pmore3}
{cmd: xlab(0, .2, 0.4, 0.6, 0.8, 1) ///}
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
{cmd: graphregion(color(white))  ///}
{p_end}
{pmore3}
{cmd: texts(1.5) smooth gof}
{p_end}
{pmore}
{it:({stata "metapreg_examples metapreg_example_two_one":click to run})}

{synoptline}
{marker example_two_two}{...}
{cmd : 2.2 Proportions near 0 - Intercept-only model - loglog link}

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
{cmd: label(namevar=author, yearvar=year) ///}
{p_end}
{pmore3}
{cmd: sortby(year author) ///}
{p_end}
{pmore3}
{cmd: xlab(0, .2, 0.4, 0.6, 0.8, 1) ///}
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
{cmd: graphregion(color(white))  ///}
{p_end}
{pmore3}
{cmd: texts(1.5) smooth gof}
{p_end}
{pmore}
{it:({stata "metapreg_examples metapreg_example_two_two":click to run})}


{synoptline}
{marker example_three_one}{...}
{cmd : 3.1 Risk-ratios: Comparative studies}

{pmore}
The data used in examples 3.1-3.3 are as presented in table IV of {help metapreg##Berkey_etal1995:Berkey et al. (1995)}
By supplying the risk-ratios and their variability, {help metapreg##Sharp1998:Sharp (1998)} Sharp demonstrates meta-analysis of odds-ratios with the {help meta} command. He fitted a random and a fixed effects model to the data. 

{pmore}
The logistic regression model appropriately accounts for both within- and between-study heterogeneity, with vaccination arm as a covariate. 
The options {cmd:comparative} indicates that the data is comparative. The first covariate {cmd:bcg}, identifies the first and the second observations of the pair. 
The risk-ratios are requested with the option {cmd:outplot(rr)}. All output tables are requested with the option {cmd:sumtable(all)}. 
   
{pmore2}
{stata `"use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta""':. use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta"}
{p_end}

{pmore2}
{cmd: .metapreg cases_tb population bcg,  /// }
{p_end}
{pmore3}
{cmd: studyid(study) ///}
{p_end}
{pmore3}
{cmd: sumtable(all)  ///}
{p_end}
{pmore3}
{cmd: design(comparative)	///}
{p_end}
{pmore3}
{cmd: outplot(rr) ///}
{p_end}
{pmore3}
{cmd: sumstat(Risk ratio) ///}
{p_end}
{pmore3}
{cmd: graphregion(color(white)) /// }
{p_end}
{pmore3}
{cmd: xlab(0, 1, 2) /// }
{p_end}
{pmore3}
{cmd: xtick(0, 1, 2)  /// }
{p_end}
{pmore3}
{cmd: logscale smooth ///} 
{p_end}
{pmore3}
{cmd: xtitle(Relative Ratio,size(2)) /// }
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
{it:({stata "metapreg_examples metapreg_example_three_one":click to run})}

{synoptline}
{marker example_three_two}{...}
{cmd : 3.2 Continous covariate}

{pmore}
We investigate whether altitude has an effect on the vaccination by including {cmd:alt} as a continous covariate.

{pmore2}
{stata `"use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta""':. use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta"}
{p_end}

{pmore2}
{cmd: .metapreg cases_tb population lat,  /// }
{p_end}
{pmore3}
{cmd: studyid(study) ///}
{p_end}
{pmore3}
{cmd: sumtable(all) by(bcg)  ///}
{p_end}
{pmore3}
{cmd: sortby(lat)  ///}
{p_end}
{pmore3}
{cmd: sumstat(Proportion) ///}
{p_end}
{pmore3}
{cmd: graphregion(color(white)) /// }
{p_end}
{pmore3}
{cmd: xlab(0, 0.05, 0.1) /// }
{p_end}
{pmore3}
{cmd: xtick(0, 0.05, 0.1)  /// }
{p_end}
{pmore3}
{cmd: rcols(cases_tb population) /// }
{p_end}
{pmore3}
{cmd: astext(80) /// }
{p_end}
{pmore3}
{cmd: texts(1.5)  smooth}
{p_end}

{pmore2} 
{it:({stata "metapreg_examples metapreg_example_three_two":click to run})}


{synoptline}
{cmd :3.3 Risk-ratios: Comparative studies and a continous covariate}

{pmore}
With {help metareg}, {help metapreg##Sharp1998:Sharp (1998)} investigaged the effect of latitude on BCG vaccination. 
The analysis suggested that BCG vaccination was more effective at higher absolute latitude.

{pmore}
We now fit a logistic regression model with {cmd:bcg}, a categorical variable for the arm and {cmd:lat}, a continous variable with absolute latitude. 

{pmore}
Activated by the option {cmd:interaction}, an interaction term allows to assess whether the log OR for arm vary by absolute latitude. 

{pmore}
The interaction term from {cmd:metapreg} and the coefficient for lat using {cmd:metareg} as was done by {help metapreg##Sharp1998:Sharp (1998)} are equivalent. 

{pmore2}
{stata `"use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta""':. use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta"}
{p_end}

{pmore2}
{cmd:. metapreg cases_tb population bcg lat,  /// }
{p_end}
{pmore3}
{cmd:studyid(study) ///}
{p_end}
{pmore3}
{cmd:sortby(lat) ///}
{p_end}
{pmore3}
{cmd:sumtable(all) ///}
{p_end}
{pmore3}
{cmd:design(comparative)  ///}
{p_end}
{pmore3}
{cmd:outplot(rr) ///}
{p_end}
{pmore3}
{cmd:interaction ///}
{p_end}
{pmore3}
{cmd:graphregion(color(white)) /// }
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
{cmd:texts(1.5) logscale smooth }  
{p_end}

{pmore2}
{it:({stata "metapreg_examples metapreg_example_three_three":click to run})}

{synoptline}
{marker example_four_one}{...}
{cmd : 4.1 Meta-regression - Comparative studies - Sparse data}
{pmore}
Using {help metan}, {help metapreg##Chaimani_etal2014:Chaimani et al. (2014)} informaly assessed the difference in treatment effect of haloperidol compared to placebo in treating schizophrenia.
{p_end}

{pmore}
The analysis is more appropriately perfomed using {cmd:metapreg} by including {cmd:arm} and {cmd:missingdata} as covariates. 
{p_end}

{pmore}
The interaction term allows to test whether the risk-ratios for arm differ between the group with and without missing data.
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
{cmd:studyid(firstauthor) link(loglog) ///}
{p_end}
{pmore3}
{cmd:sortby(year) ///}
{p_end}
{pmore3}
{cmd:sumtable(all) ///}
{p_end}
{pmore3}
{cmd:design(comparative)  ///}
{p_end}
{pmore3}
{cmd:outplot(rr) ///}
{p_end}
{pmore3}
{cmd:interaction ///}
{p_end}
{pmore3}
{cmd:graphregion(color(white)) ///}
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
{cmd:texts(1.5) logscale smooth}


{pmore2}		
{it:({stata "metapreg_examples metapreg_example_four_one":click to run})}

{synoptline}
{marker example_five_one}{...}
{cmd : 5.1 Meta-regression - matched Studies - sparse data }
{pmore}
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
Total {c |} a + c {space 5} b + d  {space 4}{c |} a + b + c+ d
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
{cmd:model(fixed) sumtable(all) ///}
{p_end}
{pmore3}
{cmd:design(mcbnetwork)  ///}
{p_end}
{pmore3}
{cmd:by(comparator) ///}
{p_end}
{pmore3}
{cmd:graphregion(color(white))  ///}
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
{it:({stata "metapreg_examples metapreg_example_five_one":click to run})}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:metapreg} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(rrout)}}summary relative ratios when there categorical covariates{p_end}
{synopt:{cmd:e(poprrout)}}population-averaged summary relative ratios when there categorical covariates{p_end}
{synopt:{cmd:e(orout)}}summary odds ratios when there categorical covariates{p_end}
{synopt:{cmd:e(poporout)}}population-averaged summary odds ratios when there categorical covariates{p_end}
{synopt:{cmd:e(absout)}}summary proportions{p_end}
{synopt:{cmd:e(popabsout)}}population-averaged summary proportions{p_end}
{synopt:{cmd:e(hetout)}}heterogeneity test statistics after a fitting a random-effects model{p_end}
{synopt:{cmd:e(absoutp)}}summary proportions predictive intervals{p_end}
{synopt:{cmd:e(logodds)}}summary log-odds{p_end}
{synopt:{cmd:e(mctest)}}model compariston statistics after meta-regression{p_end}
{synopt:{cmd:e(nltest)}}hypothesis test statistics for equality of  relative ratio{p_end}
{p2colreset}{...}

{pstd}
Available model {cmd:estimates}:

{synoptset 24 tabbed}{...}
{synopt:{cmd:metapreg_modest}}estimates from the fitted model{p_end}


{title:Technical note}
{pstd}
When prefix {cmd:by} is used, only the results from the last group or the first model will be stored respectively.

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
