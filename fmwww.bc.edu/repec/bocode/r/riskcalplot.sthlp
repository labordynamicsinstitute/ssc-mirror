{smcl}
{* *! version 1.0.1 02aug2026}{...}

{viewerjumpto "Syntax" "riskcalplot##syntax"}{...}
{viewerjumpto "Description" "riskcalplot##description"}{...}
{viewerjumpto "Options" "riskcalplot##options"}{...}
{viewerjumpto "Performance statistics" "riskcalplot##statistics"}{...}
{viewerjumpto "Examples" "riskcalplot##examples"}{...}
{viewerjumpto "Stored results" "riskcalplot##results"}{...}
{viewerjumpto "Authors" "riskcalplot##authors"}{...}

{vieweralsosee "logistic" "help logistic"}{...}
{vieweralsosee "glm" "help glm"}{...}
{vieweralsosee "cii proportions" "help cii proportions"}{...}
{vieweralsosee "roctab" "help roctab"}{...}
{vieweralsosee "twoway" "help twoway"}{...}


{title:Title}

{phang}
{bf:riskcalplot} {hline 2} Plot observed and model-predicted risks across values of discrete clinical scores


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:riskcalplot}
{it:endpoint score1}
[{it:score2 score3 score4 score5}]
{ifin}
{cmd:,}
{opt model(model_list)}
[{it:options}]

{pstd}
{it:endpoint} must be a numeric binary variable coded 0 and 1.
Each score must be numeric. One endpoint and one to five score variables
may be specified.

{synoptset 34 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Model}
{synopt:{opt model(model_list)}}specify {cmd:logit} or {cmd:log} for each score; required{p_end}

{syntab:Confidence intervals}
{synopt:{opt noci}}suppress confidence intervals for observed risks{p_end}
{synopt:{opt level(#)}}set the confidence level; default is the current {cmd:set level}{p_end}

{syntab:Markers}
{synopt:{opt marker(msymbol)}}use the specified marker symbol for every score{p_end}

{syntab:Fitted-risk lines}
{synopt:{opt plot1opts(line_options)}}modify the fitted-risk line for score 1{p_end}
{synopt:{opt plot2opts(line_options)}}modify the fitted-risk line for score 2{p_end}
{synopt:{opt plot3opts(line_options)}}modify the fitted-risk line for score 3{p_end}
{synopt:{opt plot4opts(line_options)}}modify the fitted-risk line for score 4{p_end}
{synopt:{opt plot5opts(line_options)}}modify the fitted-risk line for score 5{p_end}

{syntab:Confidence-interval layers}
{synopt:{opt ci1opts(rcap_options)}}modify confidence intervals for score 1{p_end}
{synopt:{opt ci2opts(rcap_options)}}modify confidence intervals for score 2{p_end}
{synopt:{opt ci3opts(rcap_options)}}modify confidence intervals for score 3{p_end}
{synopt:{opt ci4opts(rcap_options)}}modify confidence intervals for score 4{p_end}
{synopt:{opt ci5opts(rcap_options)}}modify confidence intervals for score 5{p_end}

{syntab:Observed-risk markers}
{synopt:{opt scatter1opts(scatter_options)}}modify observed-risk markers for score 1{p_end}
{synopt:{opt scatter2opts(scatter_options)}}modify observed-risk markers for score 2{p_end}
{synopt:{opt scatter3opts(scatter_options)}}modify observed-risk markers for score 3{p_end}
{synopt:{opt scatter4opts(scatter_options)}}modify observed-risk markers for score 4{p_end}
{synopt:{opt scatter5opts(scatter_options)}}modify observed-risk markers for score 5{p_end}

{syntab:Statistics}
{synopt:{opt nostat}}suppress displayed performance statistics{p_end}
{synopt:{opt statopts(note_options)}}modify the graph note containing statistics for score 1{p_end}

{syntab:Graph}
{synopt:{it:twoway_options}}specify standard {cmd:twoway} graph options{p_end}

{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:riskcalplot} displays observed event risks and model-predicted risks
across the distinct values of one to five discrete clinical scores.

{pstd}
For each score value, the observed risk is the proportion of observations
with {it:endpoint}=1. Marker size is proportional to the number of
observations at that score value.

{pstd}
Unless {cmd:noci} is specified, each observed risk is accompanied by an
exact Clopper-Pearson binomial confidence interval. The confidence level is
controlled by {cmd:level()}.

{pstd}
A separate regression model is fitted for each score. {cmd:model(logit)}
fits a logistic risk function. {cmd:model(log)} fits a modified Poisson
model with a log link and robust standard errors.

{pstd}
The command uses a common complete-case analysis sample containing
nonmissing values for the endpoint and every score specified in the
command.

{pstd}
By default, the legend is placed in the upper-left corner within the plot
region and is arranged vertically. For each score, legend entries are
ordered as follows:

{p 12 16 2}
Observed risk{break}
Confidence interval{break}
Fitted risk

{pstd}
When {cmd:noci} is specified, the confidence-interval entry is omitted.

{pstd}
By default, apparent performance statistics are displayed in the Results
window. Statistics for the first score are also placed in a graph note.
Statistics for every score are stored in {cmd:r(stats)}.


{marker options}{...}
{title:Options}


{dlgtab:Model}

{phang}
{opt model(model_list)} specifies the model used to estimate predicted
risks. This option is required. The permitted model names are {cmd:logit}
and {cmd:log}.

{pmore}
If one model is specified, that model is applied to every score.

{pmore}
If more than one model is specified, the number and order of models must
match the number and order of score variables.

{phang2}
{cmd:model(logit)}

{phang2}
{cmd:model(logit logit)}

{phang2}
{cmd:model(logit log)}

{pmore}
{cmd:logit} fits

{phang3}
{cmd:logistic endpoint c.score}

{pmore}
and obtains predicted risks using {cmd:predict, pr}.

{pmore}
{cmd:log} fits modified Poisson regression using

{phang3}
{cmd:glm endpoint c.score, family(poisson) link(log) vce(robust)}

{pmore}
and obtains predicted risks using {cmd:predict, mu}. Predicted values below
0 or above 1 are confined to the interval from 0 to 1 before performance
statistics are calculated.


{dlgtab:Confidence intervals}

{phang}
{opt noci} suppresses the exact confidence intervals around observed risks.
Observed-risk markers and fitted-risk lines remain displayed.

{phang}
{opt level(#)} specifies the confidence level for the exact
Clopper-Pearson binomial confidence intervals. The default is the current
value of {cmd:set level}, usually 95. This option has no visible effect when
{cmd:noci} is specified.


{dlgtab:Markers}

{phang}
{opt marker(msymbol)} specifies one marker symbol for the observed risks of
all scores. When this option is omitted, scores 1 through 5 use
{cmd:Oh}, {cmd:Dh}, {cmd:Th}, {cmd:Sh}, and {cmd:oh}, respectively.


{dlgtab:Fitted-risk lines}

{phang}
{opt plot1opts(line_options)} through
{opt plot5opts(line_options)} pass line options to the fitted-risk line for
the corresponding score. Examples include {cmd:lpattern()},
{cmd:lwidth()}, and {cmd:lcolor()}.

{pmore}
For example,

{phang2}
{cmd:plot1opts(lpattern(solid) lwidth(medthick))}

{phang2}
{cmd:plot2opts(lpattern(dash) lwidth(medthick))}


{dlgtab:Confidence-interval layers}

{phang}
{opt ci1opts(rcap_options)} through
{opt ci5opts(rcap_options)} pass {cmd:rcap} options to the exact confidence
intervals for the corresponding score. Examples include {cmd:lpattern()},
{cmd:lwidth()}, and {cmd:lcolor()}.

{pmore}
For example,

{phang2}
{cmd:ci1opts(lwidth(thin))}

{phang2}
{cmd:ci2opts(lpattern(dash) lwidth(thin))}


{dlgtab:Observed-risk markers}

{phang}
{opt scatter1opts(scatter_options)} through
{opt scatter5opts(scatter_options)} pass scatter options to the
observed-risk markers for the corresponding score. Examples include
{cmd:msymbol()}, {cmd:msize()}, {cmd:mcolor()}, {cmd:mfcolor()}, and
{cmd:mlcolor()}.

{pmore}
For example,

{phang2}
{cmd:scatter1opts(msymbol(Oh) mlwidth(medthin))}

{phang2}
{cmd:scatter2opts(msymbol(Dh) mlwidth(medthin))}


{dlgtab:Statistics}

{phang}
{opt nostat} suppresses the performance-statistics matrix in the Results
window and suppresses the statistics note on the graph. It does not remove
the statistics stored in {cmd:r(stats)}.

{phang}
{opt statopts(note_options)} passes graph-note options to the statistics
note for score 1. Examples include {cmd:size()}, {cmd:color()},
{cmd:position()}, {cmd:ring()}, and {cmd:justification()}.

{pmore}
Only statistics for score 1 are placed in the graph note. Statistics for
all scores remain available in {cmd:r(stats)}.


{dlgtab:Graph}

{phang}
{it:twoway_options} are standard options accepted by {cmd:twoway}. They
may be used to modify the graph title, axis titles, labels, legend, graph
scheme, graph name, and other overall graph properties.

{pmore}
The default legend uses one column and is placed at
{cmd:position(11) ring(0)}. A user-specified {cmd:legend()} option may be
used to modify these defaults.


{marker statistics}{...}
{title:Performance statistics}

{phang}
{bf:Expected-to-observed ratio (E:O)} is calculated as the sum of predicted
risks divided by the observed number of events. A value of 1 indicates
equality between the expected and observed event counts.

{phang}
{bf:Calibration-in-the-large (CITL)} is the intercept from logistic
regression of the endpoint with the logit of predicted risk included as an
offset. The target value is 0.

{phang}
{bf:Calibration slope} is the coefficient from logistic regression of the
endpoint on the logit of predicted risk. The target value is 1.

{phang}
{bf:Adjusted R-squared} is obtained from weighted linear regression of the
observed risks on the predicted risks across distinct score values. The
number of observations at each score value is used as the analytic weight.
The statistic may be missing when there are too few distinct score values
or when the weighted regression cannot be fitted.

{phang}
{bf:Root mean squared error (RMSE)} is calculated across distinct score
values as

{p 12 16 2}
{it:RMSE} = sqrt[sum n_g(O_g-P_g)^2 / sum n_g],

{pmore}
where {it:n_g} is the number of observations, {it:O_g} is the observed risk,
and {it:P_g} is the predicted risk at score value {it:g}.

{phang}
{bf:AUROC} is the area under the receiver operating characteristic curve,
calculated from the individual-level predicted risks.

{pstd}
Adjusted R-squared and RMSE are grouped agreement measures. They are not
the scaled Brier score, and the reported RMSE is not the square root of the
individual-level Brier score.


{title:Interpretation}

{pstd}
The reported statistics describe apparent performance because the same
analysis sample is used to fit and evaluate each model. They should not be
interpreted as internal validation or external validation.

{pstd}
When a logistic model is fitted and evaluated in the same data,
calibration-in-the-large and calibration slope may be close to their target
values by construction. Resampling or evaluation in independent data is
required to assess optimism and generalizability.

{pstd}
Exact confidence intervals can be wide when few observations are available
at a score value. Their width represents uncertainty in the observed event
proportion and not uncertainty in the fitted-risk line.


{marker examples}{...}
{title:Examples}

{pstd}
Load the diabetic ketoacidosis demonstration dataset:

{phang2}
{stata "use https://raw.githubusercontent.com/Suppachai-Lawanaskol/riskcalplot/main/dka_score.dta, clear":download}

{pstd}
Install {cmd:bta2score} if it is not available:

{phang2}
{stata ssc install bta2score, replace}

{pstd}
Develop the prediction model using logistic regression:

{phang2}
{stata logit dka i.dtx400 i.dm012 insulin low_compli dyspnea infection, cformat(%9.2f) baselevels}

{pstd}
Round the coefficients and generate the point-based additive score:

{phang2}
{stata bta2score, tab cstat name(dka_score) replace}

{pstd}
Plot the receiver operating characteristic curve:

{phang2}
{stata roctab dka dka_score, graph noref note("AuROC 0.87 (0.82, 0.92)", justification(center) ring(0) position(5) margin(large) size(large)) plotopts(msymbol(none) lwidth(thick) lcolor(black)) yscale(noline) xscale(noline)}

{pstd}
Plot the observed and model-predicted risks:

{phang2}
{stata riskcalplot dka dka_score, model(logit) ytitle("Risk of DKA") xtitle("1-DKA score") scheme(stcolor) xlabel(0(3)12)}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:riskcalplot} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}

{p2col 5 20 24 2:Macros}{p_end}

{synopt:{cmd:r(models)}}models corresponding to the score variables{p_end}
{synopt:{cmd:r(scores)}}names of the score variables{p_end}
{synopt:{cmd:r(endpoint)}}name of the binary endpoint variable{p_end}

{p2col 5 20 24 2:Matrix}{p_end}

{synopt:{cmd:r(stats)}}performance statistics for all scores{p_end}

{p2colreset}{...}

{pstd}
Rows of {cmd:r(stats)} correspond to score variables. Columns are
{cmd:E_O}, {cmd:CITL}, {cmd:Cal_slope}, {cmd:Adj_R2}, {cmd:RMSE}, and
{cmd:AUROC}.


{title:Installation}

{pstd}
Install the current version from GitHub:

{phang2}
{cmd:net install riskcalplot, from("https://raw.githubusercontent.com/suppachai-lawanaskol/riskcalplot/main/") replace}


{marker authors}{...}
{title:Authors}

{pstd}
Suppachai Lawanaskol, MD{break}
Chaiprakarn Hospital{break}
Chiang Mai, Thailand

{pstd}
Jayanton Patumanond, MD, MPH, MSc, DSc{break}
Clinical Epidemiology Unit, Faculty of Medicine{break}
Naresuan University{break}
Phitsanulok, Thailand

{pstd}
Repository:
{browse "https://github.com/suppachai-lawanaskol/riskcalplot":riskcalplot on GitHub}


{title:Suggested citation}

{pstd}
Lawanaskol S, Patumanond J. {it:riskcalplot}: Stata module for plotting
observed and model-predicted risks across values of discrete clinical
scores. Version 1.0.1, 2026.

{title:Acknowledgments}

{pstd}
We gratefully acknowledge Peamyao et al. for providing the dataset and Thanin Lokeskrawee, the corresponding author of our study on the 1-DKA score, for his insightful comments.


{title:References}

{phang}
Clopper CJ, Pearson ES. The use of confidence or fiducial limits illustrated
in the case of the binomial. {it:Biometrika}. 1934;26:404-413.

{phang}
Peamyao W, Lokeskrawee T, Lawanaskol S, Patumanond J, Chanlaor S, Bumrungpagdee W, et al. Predictive factors for diagnosing diabetic ketoacidosis or simple hyperglycemia in adults with high blood glucose: the “1-DKA Alert” study. J Clin Med Res. 2025;17(3):164–173. doi:10.14740/jocmr6180.

{phang}
Steyerberg EW. {it:Clinical Prediction Models}. 2nd ed. Cham:
Springer; 2019.

{phang}
Zou G. A modified Poisson regression approach to prospective studies with
binary data. {it:American Journal of Epidemiology}. 2004;159:702-706.
