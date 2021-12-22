{smcl}
{* *! version 1.0.0 11Nov2021}{...}
{title:Title}

{p2colset 5 16 17 2}{...}
{p2col:{hi:rmclass} {hline 2}} Classification statistics for data with repeated measures {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:rmclass}
{it: refvar}
{it: classvar}
{ifin}
[,
{opt i:d}{cmd:(}{it:{help varname:varname}{cmd:})}
{opt gee}
{opt l:evel(#)}
{it:model_options}
]


{pstd}
{it:refvar} is the reference variable indicating the true state of the observation such as diseased and nondiseased or normal and abnormal, 
and {it:classvar} is the classification variable indicating the rating or outcome of the diagnostic test or test modality. Both {it:refvar} and {it:classvar}
must be coded as 0 and 1.



{synoptset 18 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt i:d(varname)}}subject identifier; must be specified when specifying {cmd:gee}{p_end}
{synopt :{opt gee}}specifies to fit a {helpb xtgee} model. If {cmd:gee} is
not specified, {cmd:rmclass} will use {helpb logit} as the default model; {cmd:id()} must be declared when specifying {cmd:gee} {p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:[{it:model_options}]}specify all available options for {helpb xtgee} when the
{cmd:gee} option is chosen; otherwise, all available options for {helpb logit} are specified.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{opt by} is allowed with {cmd:rmclass}; see {manhelp by D}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt rmclass} reports classification statistics and confidence intervals for data in which subjects have either been tested once (i.e. a single test compared to a reference standard), 
or have undergone repeated testing. For data with repeated measurements (ascertained by specifying {cmd: id()}), a {helpb logit} model is estimated with clustered standard errors by default.
Alternatively, the user may specify that a GEE model be used to estimate the classification statistics.   



{title:Options}

{p 4 8 2} 
{cmd:id(}{it:varname}{cmd:)} specifies the subjects' identifier; {cmd:id() is required}

{p 4 8 2} 
{cmd:level(}{it:#}{cmd:)} specifies the confidence level, as a percentage, for
confidence intervals.  The default is {cmd:level(95)} or whatever is set by
{helpb set level}.

{p 4 8 2} 
{cmd:gee} specifies to fit a {helpb xtgee} model. If {cmd:gee} is
not specified, {cmd:rmclass} will use {helpb logit} as the default model; {cmd:id()} must be declared when specifying {cmd:gee}.

{p 4 8 2} 
{it:model_options} specify all available options for {helpb xtgee} when the
{cmd:gee} option is chosen; otherwise, all available options for {helpb logit} are specified.
This is particularly useful for the GEE model where the user may want to specify a particular correlation structure. 



{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use example.dta}{p_end}

{pstd}Basic specification where observations are assumed independent. A logit model is estimated with default standard errors. {p_end}
{phang2}{cmd:. rmclass disease test}{p_end}

{pstd}Data with repeated measures. A logit model is estimated with clustered standard errors. {p_end}
{phang2}{cmd:. rmclass disease test, id(id)}{p_end}

{pstd}Data with repeated measures. A GEE model is estimated with default exchangeable correlation structure and robust standard errors. {p_end}
{phang2}{cmd:. rmclass disease test, id(id) gee}{p_end}

{pstd}Data with repeated measures. A GEE model is estimated with an AR1 correlation structure and robust standard errors. However, we first must
specify a time variable using {cmd:xtset}{p_end}
{phang2}{cmd:. xtset id order}{p_end}
{phang2}{cmd:. rmclass disease test, i(id) gee corr(ar 1)}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:rmcorr} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(sens)}}sensitivity{p_end}
{synopt:{cmd:r(spec)}}specificity{p_end}
{synopt:{cmd:r(ppv)}}positive predictive value{p_end}
{synopt:{cmd:r(npr)}}negative predictive value{p_end}
{synopt:{cmd:r(fpr)}}false positive rate{p_end}
{synopt:{cmd:r(fnr)}}false negative rate{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Genders, T.S., Spronk, S., Stijnen, T., Steyerberg, E. W., Lesaffre, E. and M. M. Hunink. 2012. 
Methods for calculating sensitivity and specificity of clustered data: a tutorial. {it:Radiology} 265: 910-916.{p_end}

{p 4 8 2}
Leisenring W., Pepe, M. S. and G. Longton. 1997. A marginal regression modelling framework for evaluating medical diagnostic tests. {it:Statistics in Medicine}
16: 1263-1281.{p_end} 

{p 4 8 2}
Lim, Y. 2020. A GEE approach to estimating accuracy and its confidence intervals for correlated data. {it:Pharmaceutical Statistics} 19: 59-70.{p_end}

{p 4 8 2}
Linden A. 2006. Measuring diagnostic and predictive accuracy in disease management: an introduction to receiver operating characteristic (ROC) analysis. 
{it:Journal of Evaluation in Clinical Practice} 12: 132-139.{p_end}

{p 4 8 2}
Smith, P. J. and A. Hadgu. 1992. Sensitivity and specificity for correlated observations. {it:Statistics in Medince} 11: 1503–1509.{p_end}



{marker citation}{title:Citation of {cmd:rmclass}}

{p 4 8 2}{cmd:rmclass} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2021). RMCLASS: Stata module to compute classification statistics for data with repeated measures.



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb estat classification}, {helpb classtabi} (if installed) {p_end}

