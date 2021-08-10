{smcl}
{* *!Paul C. Lambert 21Nov2016}{...}
{cmd:help stpm2_standsurv} 
{right:also see:  {helpb stpm2}{space 2}{helpb stpm2_postestimation}}
{hline}

{title:Title}


{p2colset 5 25 23 2}{...}
{p2col:{hi: stpm2_standsurv} {hline 2}}Post-estimation tool to estimate standardized survival curves and contrasts{p_end}
{p2colreset}{...}



{title:Syntax}
{phang2}
{cmd: stpm2_standsurv} [{cmd:,} {it:options}]

{synoptset 34}{...}
{synopthdr}
{synoptline}
{synopt:{opt at1()}{it:...}{opt atn()}}fix specific covariate values for each cause {p_end}
{synopt:{opt atvars()}}the new variable names (or stub) for each at{it:n}() option {p_end}
{synopt:{opt atreference()}}the reference at{it:n}() option (default 1){p_end}
{synopt:{opt ci}}calculates confidence intervals for each at{it:n}() option and contrasts{p_end}
{synopt:{opt contrast()}}perform contrast between covariate patterns defined by at{it:n}() options{p_end}
{synopt:{opt contrastvars()}}the new variable names (or stub) for each contrast{p_end}
{synopt:{opt failure}}calculate standardized failure function (1-S(t)){p_end}
{synopt:{opt timevar()}}time variable used for predictions (default _t){p_end}
{synopt:{opt trans()}}transormation to calculate standard error when obtaining confidence intervals{p_end}
{synopt:{opt level(#)}}sets confidence level (default 95){p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}{cmd:stpm2_standsurv} can be used after {helpb stpm2} to obtain standardized (average) survival curves and 
contrasts between standardized curves. It is similar to the {cmd:meansurv} option of {cmd:stpm2}'s {cmd:predict} command,
but allows multiple at options and constrasts (differences or ratios of standardized survival curves). It is 
substantially faster than the {cmd:meansurv} option when calculation confidence intervals as standard errors are estimated 
using M-estimation (Stefanski and Boos 2002).


{title:Options}

{dlgtab:Main}

{phang}
{opt at1(varname # [varname # ..])}{it:..}{opt atn(varname # [varname # ..])} specifies covariates to fix at specific values when averaging survival curves. 
For example, if {it:x} denotes a binary covariate and you want to standardise over all other variables in the model then using {bf:at1(x 0) at2(x 1)} will obtain give two standardized 
surviva functions, one where {bf:x=0} and one where {bf:x=1}.


{phang}
{opt atvars(stub or newvarnames)} gives the new variables to create. This can be specified as a varlist equal to the number of at() options or a {it:stub}
where new variables are named {it:stub}{bf:1} - {it:stub}{bf:n}. If this option is not specified, the names default to {bf:_at1} to {bf:_at}{it:n}{p_end}. 

{phang}
{opt atreference{#}} the {bf:atn()} option that defines the reference category. By defult this is {bf:at1()}{p_end}

{phang}
{opt ci} calculates a 95% confidence interval for each standardised survival function or contrast . The
confidence limits are stotred using the suffix {bf:_lci} and {bf:_uci}.{p_end}


{phang}
{opt contrast(contrastname)} calculate contrasts between standardized survival curves. Options are {bf:difference} and {bf:ratio}. There will be {it:n-1} 
new variables created, where {it:n} is the number of {bf:at()} options.

{phang}
{opt contrastvars(stub or newvarnames)} gives the new variables to create when using the {bf:contrast()} option. This can be specified 
as a varlist or a {it:stub} where new variables are named {it:stub}{bf:1} - {it:stub}{bf:n-1}. 
If this option is not specified, the names default to ....{p_end}. 

{phang}
{opt failure} calculate standardized failure function rather than survival function.{p_end}

{phang}
{opt timevar(varname)} defines the variable used as time in the predictions.  Default varname is _t. This option is useful for large datasets where for plotting purposes predictions are only
        needed for 200 observations for example.  Note prediction are averaged over the whole sample, not just those where {it:timevar} is not missing.
		It is recommneded that this options is used as otherwise an estimate of the survival function is obtained at each value of {bf:_t} for all subjects.{p_end}

{phang}
{opt trans(name)} Transformation to apply when calculation standard error to obtain confidence intervals for the standardised curves.
The default is log(-log S(t)). Othere options are {bf:none}, {bf:log}, {bf:logit}. {p_end}


{title:Example}

{pstd}


{pstd}Load example dataset:{p_end}
{phang}{stata "webuse brcancer, clear":. webuse brcancer, clear}{p_end}

{pstd}{cmd:stset} the data:{p_end}
{phang}{stata "stset rectime, f(censrec==1) scale(365.24)":. stset rectime, f(censrec==1) scale(365.24)}{p_end}

{pstd}Fit {cmd:stpm2} model:{p_end}
{phang}{stata "stpm2 hormon x5 x1 x3 x6 x7, scale(hazard) df(4) tvc(hormon x5 x3) dftvc(3)":. stpm2 hormon x5 x1 x3 x6 x7, scale(hazard) df(4) tvc(hormon x5 x3) dftvc(3)}{p_end}

{pstd}Generate variable that defines timepoints to predict at. The following creates 50 equally spaced time points between 0.05 and 5 years:{p_end}
{phang}{stata "range timevar 0 5 50":. range timevar 0 5 50}{p_end}

{pstd}Obtain standardarized curves for {bf:hormon=0} and {bf:hormon=1}. In each case the survival curves are the average of the 686
survival curves using the observed covariatiate values with the exception of {bf:hormon}.{p_end}
{phang}{stata "stpm2_standsurv , atvars(S0a S1a) at1(hormon 0) at2(hormon 1) timevar(timevar) ci":. stpm2_standsurv , atvars(S0a S1a) at1(hormon 0) at2(hormon 1) timevar(timevar) ci}{p_end}

{pstd}Plot standardized curves:{p_end}
{phang}{stata "line S0a S1a timevar":. line S0a S1a timevar}{p_end}

{pstd}Obtain standardarized curves for {bf:hormon=0} and {bf:hormon=1}, but apply the covariate distribution amongst those with {bf:hormon=1}.{p_end}
{phang}{stata "stpm2_standsurv if hormon==1, atvars(S0b S1b) at1(hormon 0) at2(hormon 1) timevar(timevar) ci":. stpm2_standsurv if hormon==1, atvars(S0b S1b) at1(hormon 0) at2(hormon 1) timevar(timevar) ci}{p_end}

{pstd}Plot standardized curves:{p_end}
{phang}{stata "line S0b S1b timevar":. line S0b S1b timevar}{p_end}

{pstd}Obtain standardarized curves for {bf:hormon=0} and {bf:hormon=1}, and calculate difference in standardized survival curves and 95 confidence interval.{p_end}

{phang}{stata "stpm2_standsurv, atvars(S0c S1c) at1(hormon 0) at2(hormon 1) timevar(timevar) ci contrast(difference) contrastvar(Sdiffc)":. stpm2_standsurv, atvars(S0c S1c) at1(hormon 0) at2(hormon 1) timevar(timevar) ci contrast(difference) contrastvar(Sdiffc)}

{pstd}Plot difference in standardized curves and 95% confidence interval:{p_end}
{phang}{stata "line Sdiffc* timevar":. line Sdiffc* timevar}{p_end}


{title:Also see}

{psee}
Online:  {manhelp stpm2 ST} {manhelp stpm2_postestimation ST}; 

{title:References}

{phang}Stefanski L.A. and Boos, DD. The calculus of M-estimation. {it: The American Statistician} 2002;{bf:56};29-38.
{p_end}



