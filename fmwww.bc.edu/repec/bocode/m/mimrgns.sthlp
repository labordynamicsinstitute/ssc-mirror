{smcl}
{cmd:help mimrgns}
{hline}

{title:Title}

{p 5}
{cmd:mimrgns} {hline 2} {helpb margins} after {helpb mi estimate}


{title:Syntax}

{p 5 5 2}
Use after {cmd:mi estimate}

{p 8 16 2}
{cmd:mimrgns} 
[{help fvvarlist:{it:marginlist}}] 
{ifin} 
{weight} 
[{cmd:,}
{it:{help mimrgns##opts:options}}
{it:{help mimrgns##marg_opts:margins_options}}
{it:{help mimrgns##mi_opts:mi_options}} 
]


{p 5 5 2}
Use after {cmd:mi estimate , saving() esample()}

{p 8 16 2}
{cmd:mimrgns} [{help fvvarlist:{it:marginlist}}] 
{ifin} {weight}
{helpb using} {it:{help filename:miestfile}} 
{cmd:, esample(}{it:{help varname}}{cmd:)} 
[ {it:{help mimrgns##opts:options}}
{it:{help mimrgns##marg_opts:margins_options}}
{it:{help mimrgns##mi_opts:mi_options}} ] 


{p 5 8 2}
where {it:miestfile}{cmd:.ster} contains estimation results 
previously saved by {cmd:mi estimate , saving(}{it:miestfile}{cmd:)} 
{cmd:esample(}{it:newvarname}{cmd:)}


{title:Description}

{pstd}
{cmd:mimrgns} runs {cmd:margins} after {cmd:mi estimate} to obtain margins 
of responses in multiply imputed datasets. The command generalizes the 
approach suggest by 
{browse "http://www.stata.com/statalist/archive/2010-03/msg01021.html":Isabel Canette and Yulia Marchenko} 
and later adopted by the 
{browse "http://www.ats.ucla.edu/stat/stata/faq/ologit_mi_marginsplot.htm":UCLA Statistical Consulting Group}. See 
{help mimrgns##remarks:Remarks below}.

{pstd}
The second syntax is preferred because it executes a bit faster. Used like 
the regular {cmd:margins} command, {cmd:mimrgns} runs both, the estimation 
command and {cmd:margins}, on the imputed datasets. Specifying {cmd:using} 
{it:miestfile} with the second syntax causes estimation results to be 
retrieved from {it:miestfile} and only {cmd:margins} needs to be run on the 
imputed datasets.


{title:Remarks}

{pstd}
There might be good reasons why Stata's {cmd:margins} command does not work 
after {cmd:mi estimate}. If you have not read 
{mansection MI miestimatepostestimationRemarksUsingthecommand-specificpostestimationtools:{it:Using the command-specific postestimation tools}}
in {manhelp mi_estimate_postestimation MI:mi estimate postestimation}, please 
do so.

{pstd}
Rather than merely applying {cmd:margins} to the (final) MI estimates, 
{cmd:mimrgns} treats {cmd:margins} itself as an estimation command, 
applying Rubin's rules to its results. 

{marker par3}{...}
{pstd}
Applying Rubin's rules to the results obtained from {cmd:margins} assumes 
asymptotic normality. This might well be appropriate for linear predictions 
or for average marginal effects (White, Royston and Wood 2011), but might not 
be appropriate otherwise (also see {mansection MI mipredictRemarks:{it:Example 3: Obtain MI estimates of probabilities}} 
in {manhelp mi_predict MI:mi predict}). By default {cmd:mimrgns} uses linear 
predictions, regardless of the default prediction for the estimation command.

{marker par4}{...}
{pstd}
Note that while in principle {helpb marginsplot} works after {cmd:mimrgns}, 
there are two issues that need to be considered. First, the plotted 
confidence intervals will be based on inappropriate degrees of freedom 
({help mimrgns##df:more}). Although the differences will typically be 
too small to notice in a graph, you may want to use an alternative to 
{cmd:marginsplot} that allows specifying the degrees of freedom used to 
calculate confidence intervals (e.g. 
Jann's {stata findit coefplot:{bf:coefplot}}). {cmd:mimrgns} returns the 
correct degrees of freedom in {cmd:r(df)} (or {cmd:r(df_vs)} with the 
{opt pwcompare} option). Second, graphs might be based on imputed values 
that vary across complete datasets ({help mimrgns##at:more}). {cmd:mimrgns} 
applies Rubin's rules to any requested summary statisic in the {helpb at()} 
option. 

{pstd}
Concerning {cmd:margins}' {help margins_contrast:{bf:contrast}} 
option, (joint) hypothesis tests are not supported by {cmd:mimrgns}.

{pstd}
Finally, {cmd:mimrgns} does not save all results that {cmd:margins} 
saves. This might lead to error messages when running post estimation 
commands, e.g. {helpb mi test}. Even if no error messages appear, such 
results might not be appropriate.


{title:Options}

{phang}
{opt esample(varnme)} specifies the observations to be used in the 
estimation. Here, {it:varname} refers to the variable previously created by 
{helpb mi estimate:mi estimate , esample({it:newvarname})}. The option is 
required with the second syntax and not allowed otherwise.

{phang}
{cmd:{ul:pr}edict(default)} specifies that instead of {cmd:mimrgns} default 
{cmd:predict(xb)}, the default predciton of the {cmd:margins} command be 
used. This option will usually result in nonlinear predictions for which 
Rubin's rules might not be appropriate; See 
{help mimrgns##par3:paragraph 3 in Remarks}).

{phang}
{opt eform} displays (final) coefficients in exponentiated form.

{phang}
{opt cmdmargins} sets {cmd:r(cmd)} (or {cmd:e(cmd)} with {opt post}) to 
{cmd:margins} (or {cmd:pwcompare} or {cmd:contrast}). This is a technical 
option and it is required if {cmd:marginsplot} (Stata 12 or higher) is to 
be used subsequently - but see {help mimrgns##par4:paragraph 4 in Remarks} 
above.

{marker marg_opts}{...}
{it:{dlgtab:margins_options}}

{phang}
{it:{help margins##options:margins_options}} are (most) options allowed with 
the {cmd:margins} command. Not allowed are most {it:contrast_options} and  
option {opt nose}. 

{it:{dlgtab:mi_options}}

{phang}
{opt nosmall} does not use the small-sample correction for the degrees of 
freedom. See the corresponding {help mi estimate##options:mi estimate option} 
for more details.

{phang}
{opt dots}, {opt noi:sily} and {opt trace} are the corresponding 
{help mi estimate: mi estimate {it:reporting_options}}.

{phang}
{opt errorok} and {opt esampvaryok} are the respective 
{help mi estimate##options:mi estimate options}. With the first syntax these 
options must be repeated if used with {cmd:mi estimate} before.


{title:Examples}

{pstd}
Setup

{phang2}{stata webuse mheart1s20:. webuse mheart1s20}{p_end}
{phang2}{stata mi convert flong:. mi convert flong}{p_end}

{pstd}
Estimate a logistic regression model and save the results

{phang2}
{stata "mi estimate , saving(miestfile) esample(esample) : logit attack smokes age bmi hsgrad female":. mi estimate , saving(miestfile) esample(esample) : logit attack smokes age bmi hsgrad female}
{p_end}

{pstd}
Obtain average marginal effects (linear predictions)

{phang2}
{stata mimrgns using miestfile , esample(esample) dydx(*):. mimrgns using miestfile , esample(esample) dydx(*)}
{p_end}

{pstd}
Obtain average marginal effects in terms of predicted probabilities 
(but see {help mimrgns##par3:paragraph 3 in Remarks}).

{phang2}
{stata mimrgns using miestfile , esample(esample) predict(pr) dydx(*):. mimrgns using miestfile , esample(esample) predict(pr) dydx(*)}
{p_end}

{pstd}
Create age categories and re-run the logistic regression

{phang2}{stata "mi xeq : generate ageg = irecode(age, 20, 40 ,60, 80)":. mi xeq : generate ageg = irecode(age, 20, 40 ,60, 80)}{p_end}
{phang2}{stata "mi estimate : logit attack smokes i.ageg bmi hsgrad female":. mi estimate : logit attack smokes i.ageg bmi hsgrad female}{p_end}

{pstd}
Obtain pairwise comparisons of predicive margins

{phang2}{stata mimrgns ageg , pwcompare:. mimrgns ageg , pwcompare}{p_end}

{pstd}
Contrasts of predictive margins

{phang2}{stata mimrgns ar.ageg:. mimrgns ar.ageg}{p_end}


{pstd}
Erase {cmd:miestfile.ster}, created above.

{phang2}{stata erase miestfile.ster:. erase miestfile.ster}{p_end}


{title:Saved results}

{pstd}
{cmd:mimrgns} saves in {cmd:r()} some of the results that  
{help margins##saved_results:{bf:margins}} saves without the 
{cmd:post} option.

{pstd}
{cmd:mimrgns} additionally saves the following in {cmd:r()}:

{pstd}
Macros{p_end}
{synoptset 24 tabbed}{...}
{synopt:{cmd:r(cmd)}}{cmd:mimrgns} (not with {opt cmdmargins}){p_end}
{synopt:{cmd:r(est_cmdline_mi)}}{cmd:e(cmdline_mi)} from {cmd:mi estimate}{p_end}
{synopt:{cmd:r(est_cmdline_margins)}}{cmd:margins} command{p_end}


{title:Addendum:}

{marker df}{...}
{pstd}
{bf:Confidence intervals with marginsplot after mimrgns}

{pstd}
Why are the confidence intervals wrong? {cmd:marginsplot} internally replays 
results from the last  {cmd:margins} command to recalculate confidence 
intervals (but not point estimates or standard errors). The last {cmd:margins} 
results are those obtained in the last imputed dataset - not the ones reported 
by {cmd:mimrgns}. Thus, instead of the degrees of freedom provided by Stata's 
{cmd:mi} suit and reported by {cmd:mimrgns}, {cmd:marginsplot} uses the 
(default) degrees of freedom form the specified estimation command in the last 
imputed dataset. There is no way of passing the appropriate degrees of freedom 
to {cmd:marginsplot}. This means there is no way to get correct confidence 
intervals from {cmd:marginsplot} after {cmd:mimrgns}.

{marker at}{...}
{pstd}
{bf:Varying values and summary statistics in at() options with mimrgns}

{pstd}
{cmd:mimrgns} allows covariates to be fixed at specified values, just 
like the {cmd:margins} command, by specifying one or more {opt at()} 
options. These values include summary statistics like the mean, minimum or 
maximum of a covariate. Since covariates might be multiply imputed, there 
is no longer one mean (minimum, maximum, ...) of this covariate, but {it:M} 
of them. {cmd:mimrgns} fixes covariates at the imputed dataset-specific 
statistic and reports the MI point estimate as a single value. A note is 
issued below the results table as a reminder of this fact.


{title:References}

{pstd}
Jann, B. 2013. Plotting regression coefficients and other estimates in 
Stata. {it:University of Bern Social Sciences Working Papers Nr. 1}.  Available 
from {browse "http://ideas.repec.org/p/bss/wpaper/1.html"}

{pstd}
White, I. R., Royston, P., Wood, M. A. 2011. Multiple imputation using 
chained equations: Issues and guidance for practice. {it:Statistics in Medicine} 
30:377-399.

{pstd}
Stata FAQ. How can I get margins and marginsplot with multiply 
imputated data? UCLA: Statistical Consulting Group. from 
{browse "http://www.ats.ucla.edu/stat/stata/faq/ologit_mi_marginsplot.htm"}


{title:Acknowledgments}

{pstd}
Xiao Yang (StataCorp) tracked down a bug that had gone 
unnoticed under Windows, but prevented {cmd:mimrgns} 
from running under Linux.

{pstd}
Jesper Wulff reported a bug with 
{it:contrast-options} and {it:pwcompare-options} in 
Stata 13 (or higher).

{pstd}
Part of the code is borrowed from StataCorp's 
{cmd:_marg_report} routine. 

{pstd}
Evan Kontopantelis suggested support for 
{help contrast##operators:contrast operators} and 
reporting the {opt at} legend. 

{pstd}
Timothy Mak identified a bug with mixed models. 

	
{title:Author}

{pstd}Daniel Klein, University of Kassel, klein.daniel.81@gmail.com


{title:Also see}

{psee}
Online: {helpb mi}, {helpb margins}{p_end}

{psee}
if installed: {help coefplot}{p_end}
