{smcl}
{* *! version 2.1  February 19, 2022}{...}
{cmd:help mces}
{cmd:help svysd}
{hline}
{viewerjumpto "Syntax" "mces##syntax"}{...}
{viewerjumpto "Options table" "mces##options_table"}{...}
{viewerjumpto "Description" "mces##description"}{...}
{viewerjumpto "Options" "mces##options"}{...}
{viewerjumpto "Examples" "mces##examples"}{...}
{viewerjumpto "Stored results" "mces##stored_results"}{...}
{viewerjumpto "References" "mces##references"}{...}

{title:Title}

{p2colset 4 9 12 2}{...}
{p2col:{bf: mces}}{hline 2} Standardized effect sizes for comparisons between
predicted values of continuous outcome variables after {cmd:margins} or
{cmd:mimrgns}{p_end}

{p2colset 3 9 12 2}{...}
{p2col:{bf: svysd}}{hline 2} Pooled standard deviations for continuous outcome
variables when data are {cmd:svyset} or {cmd:mi svyset}{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 8 2}
Syntax after {cmd:margins, pwcompare post} or {cmd:mimrgns, pwcompare post}:

{p 8 15 2}
{cmd:mces} [{it:options}]


{p 4 8 2}
To calculate the standard deviation only:

{p 8 15 2}
{cmd:svysd} {it:outcomevar}, sdbyvar({it:varname}) [{it:options}]


{marker options_table}{...}
{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt hed:gesg}}estimate Hedges's {it:g} instead of the default RMSE-based Delta [{cmd:mces} only]{p_end}
{synopt:{opt coh:ensd}}estimate Cohen's {it:d} instead of the default RMSE-based Delta [{cmd:mces} only]{p_end}
{synopt:{opt sdby:var(varname)}}dichotomous indicator variable defining 
comparison groups [used with {cmd:hedgesg}, {cmd:cohensd}, and {cmd:svysd}]{p_end}
{synopt:{opt unw:eighted}}calculate the unweighted standard deviation used for Cohen's {it:d} [{cmd:svysd} only]{p_end}
{synopt:{opt sdu:pdate}}force a re-calculation of the standard deviation [{cmd:mces} only]{p_end}
{synopt:{opt now:arning}}suppress warning messages{p_end}
{synopt:{opt f:orce}}do not check for continuous outcome variable{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mces} calculates one of three standardized effect size statistics for between-group 
contrasts of marginal effects obtained either from {cmd:margins} or 
{cmd:mimrgns} (Klein, 2016--type {cmd:ssc install mimrgns} to install). The available effect size measures are Delta figured using the RMSE, Hedges's {it:g} (Hedges, 1981), or Cohen's {it:d} (Cohen, 1988). Hedges's {it:g} is similar to Cohen's {it:d} but uses a pooled standard deviation (sd*) that is weighted by the sample sizes in each group, which is preferable in instances where the group sizes are unequal (see Ellis, 2010). Hedges's {it:g} reduces to be equivalent to Cohen's 
{it:d} when the group sizes are the same. The RMSE-based Delta that is estimated by default uses the error from the regression, rather than the raw standard deviation of the outcome variable, in the effect size calculation.

{pstd}
{cmd:mces} can process estimates when data are {cmd:svyset} or {cmd:mi svyset}. 
{cmd:mces} calls {cmd:svysd} with complex survey data when Hedges's {it:g} or Cohen's {it:d} are requested, but remembers the standard deviation if the outcome variable remains the same to reduce computation time. Note that the command uses the sampling weights to estimate population sample sizes, rather than the unweighted number of cases, when weighting the standard deviation. The {cmd:sdupdate} option forces {cmd:svysd} to update the standard deviation if necessary.
If only the survey-adjusted pooled weighted or unweighted standard deviation is desired, 
but not the effect size, then {cmd:svysd} can be used as a standalone command.

{pstd}
The {cmd:mces} command should work with most regression-type models followed by 
{cmd:margins, pwcompare post} or {cmd:mimrgns, pwcompare post} that store
their coefficients in {cmd:e(b_vs)}, such as {cmd:regress}, {cmd:truncreg}, {cmd:sem} and {cmd:gsem}, and {cmd:tobit}. {cmd:mces} is not appropriate for multilevel/hierarchical linear/mixed-effects models (see Lorah, 2018), nor for generalized linear models with categorical outcomes that do not have standard deviations or RMSEs. {cmd:svysd} is not a postestimation command and functions independently.

{marker options}{...}
{title:Options}

{it:{dlgtab:Options for Hedges's g and Cohen's d}}

{phang}
{opt sdbyvar(varname)} specifies the variable name that indicates assignment to 
one of the two groups whose marginal effects are contrasted (e.g., the treatment 
group and the control group). The {cmd:sdbyvar} must be dichotomous.
The program will return an error message if the variable has more than two 
values, even if options such as {cmd:at} or {cmd:subpop} mean 
that only two of the levels are used by {cmd:margins}. The 
{cmd:recode, generate()} command is useful for creating dichotomous grouping
variables to help ensure a valid estimate of the standard deviation. This option is required when Hedges's {it:g} and Cohen's {it:d} are requested, but not for the default RMSE-based Delta statistic.

{phang}
{opt cohensd} (for {cmd:mces}) requests estimates of Hedges's {it:g}. 

{phang}
{opt cohensd} (for {cmd:mces}) requests estimates of Cohen's {it:d}. 

{phang}
{opt unweighted} (for {cmd:svysd}) requests the unweighted pooled standard 
deviation used for Cohen's {it:d} instead of the weighted pooled standard deviation SD* used to calculate Hedges's {it:g}. 

{it:{dlgtab:Other options}}

{phang}
{opt sdupdate} requests the re-calculation of the pooled standard 
deviation. {cmd:mces} stores the standard deviation from the last estimation 
in a scalar, and typically does not re-estimate it if the outcome variable is 
the same. Use the {cmd:sdupdate} option to update the standard deviation if 
necessary (e.g., if the dataset has changed).

{phang}
If there are comparisons reported by {cmd:margins, pwcompare} (or {cmd:contrast})
for which the reported effect size might not be applicable, the program will return a
warning message. The {opt nowarning} option suppresses these messages.

{phang}
{opt force} bypasses the program's attempt to ensure that the outcome variable
is continuous. While these effect sizes measures are designed for 
continuous outcome variables, this option allows you to use the program (at your own 
risk!) for categorical outcomes if you are sure that the estimated standard 
deviation is correct and applicable, and that the coefficients from 
{cmd:margins} are comparable in this way. 

{marker examples}{...}
{title:Examples}

{pstd}Simple example{p_end}
{phang2}{stata "sysuse nlsw88"}{p_end}
{phang2}{stata "reg wage age hours i.union i.married i.union#i.married"}{p_end}
{phang2}{stata "margins union, pwcompare post"}{p_end}
{phang2}{stata "mces"}{p_end}

{pstd}Two comparison variables{p_end}
{phang2}{stata "reg wage age hours i.union i.married i.union#i.married"}{p_end}
{phang2}{stata "margins union, over(married) pwcompare post"}{p_end}
{phang2}{stata "mces"}{p_end}
{pstd}
Note the warning message: {cmd:mces} effect size apply to only "all else equal"
comparisons between {cmd:union=0} and {cmd:union=1}. Accordingly, {it:g} and {it:d} are only valid for rows 1 and 6 in these results. Because Delta is figured using the RMSE and is not variable-specific, other "all else equal" comparisons may also be in the results; in this case, rows 2 and 5 are "all else equal" comparisons, but between {cmd:married=0} and {cmd:married=1}. The program can't ensure that the results make sense--that's up to you!

{pstd}Hedges's {it:g}{p_end}
{phang2}{stata "reg wage age hours i.union i.married i.union#c.hours"}{p_end}
{phang2}{stata "margins union, at(hours=(20 40) married=1) pwcompare post"}{p_end}
{phang2}{stata "mces, sdby(union) hedgesg"}{p_end}

{pstd}Simple {cmd:svyset} example{p_end}
{phang2}{stata "webuse nmihs"}{p_end}
{phang2}{stata "svyset [pweight=finwgt], strata(stratan)"}{p_end}
{phang2}{stata "svy: regress birthwgt age i.race i.multiple i.race#i.multiple"}{p_end}
{phang2}{stata "margins multiple, pwcompare(effects) post"}{p_end}
{phang2}{stata "mces"}{p_end}

{pstd}Using {cmd:mimrgns}{p_end}
{phang2}{stata "webuse nhanes2"}{p_end}
{phang2}{stata "mi set mlong"}{p_end}
{phang2}{stata "mi register imputed diabetes"}{p_end}
{phang2}{stata "mi impute chained (logit) diabetes = bpsystol female race age bmi, rseed(1111) add(5)"}{p_end}
{phang2}{stata "mi svyset [pw=finalwgt], psu(psu) strata(strata) singleunit(centered)"}{p_end}
{phang2}{stata "mi estimate: svy: regress bpsystol i.female race age i.diabetes i.diabetes#i.female"}{p_end}
{phang2}{stata "mimrgns female, at(diabetes=(0 1) (median) age) pwcompare post"}{p_end}
{phang2}{stata "mces, cohensd sdbyvar(female)"}{p_end}

{pstd}{cmd:svysd} as a standalone command{p_end}
{phang2}{stata "webuse nmihs"}{p_end}
{phang2}{stata "svyset [pweight=finwgt], strata(stratan)"}{p_end}
{phang2}{stata "svysd birthwgt, sdby(multiple)"}{p_end}


{marker stored_results}{...}
{title:Stored results}

{pstd}
{cmd:mces} and {cmd:svysd} save the following in {cmd:r()}: 

{pstd}Scalars:{p_end}
{synoptset 24 tabbed}{...}

{synopt:{cmd:r(RMSE)}}the root mean square error of the regression (estimated by {cmd:mces} even if the regression does not report one){p_end}
       or
{synopt:{cmd:r(sdstar)}}sd*, the pooled weighted standard deviation for Hedges's {it:g}{p_end}
       or
{synopt:{cmd:r(pooledsd)}}the unweighted pooled weighted standard deviation for Cohen's {it:d}{p_end}

{synopt:{cmd:r(n_{sdbyvar}_at_#)}}the sample size in the group {cmd:sdbyvar=#}{p_end}
{synopt:{cmd:r(n_{sdbyvar}_at_#)}}the sample size in the group {cmd:sdbyvar=#}{p_end}
{synopt:{cmd:r(sd_{sdbyvar}_at_#)}}the standard deviation for the group {cmd:sdbyvar=#}{p_end}
{synopt:{cmd:r(sd_{sdbyvar}_at_#)}}the standard deviation for the group {cmd:sdbyvar=#}{p_end}

{pstd}Matrices ({cmd:mces} only):{p_end}
{synopt:{cmd:r(Delta)}}the estimated RMSE-based Delta values{p_end}
       or
{synopt:{cmd:r(g)}}the estimated Hedges's {it:g} values{p_end}
       or
{synopt:{cmd:r(d)}}the estimated Cohen's {it:d} values{p_end}

{pstd}Macros:{p_end}
{synopt:{cmd:r(depvar)}}the outcome variable{p_end}
{synopt:{cmd:r(sdbyvar)}}the margins variable{p_end}

{marker references}{...}
{title:References}

{pstd}Cohen, J. (1988). Statistical power analysis for the behavioral sciences. 
Lawrence Erlbaum Associates.

{pstd}Ellis, P. D. (2010). The essential guide to effect sizes: Statistical 
power, meta-analysis, and the interpretation of research results. Cambridge 
University Press.

{pstd}Hedges, L. V. (1981). Distribution theory for Glass’s estimator of effect 
size and related estimators. Journal of Educational Statistics, 6(2), 107–128. 
{browse "https://doi.org/10.3102/10769986006002107"}

{pstd}Klein, D. (2016). Marginal effects in multiply imputed datasets. 
14th German Stata Users Group Meeting, Cologne, Germany. 
{browse "https://www.stata.com/meeting/germany16/slides/de16_klein.pdf"}{p_end}

{pstd}Lorah, J. (2018). Effect size measures for multilevel models: definition, 
interpretation, and TIMSS example. Large-scale Assessments in Educucation, 6, 8. 
{browse "https://doi.org/10.1186/s40536-018-0061-2"}{p_end}

{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}
Miguel Dorta, Daniel Klein, and Chris Cheng contributed helpful advice during the development 
process.{p_end}

{marker author}{...}
{title:Author}

{pstd}Brian Shaw, Indiana University, USA{p_end}
{pstd}bpshaw@indiana.edu{p_end}
