{smcl}
{* *! version 3.1 March 2023}{...}
{help logitjack:logitjack}
{hline}{...}

{title:Title}

{pstd}
Cluster robust inference for logit models.{p_end}

{title:Syntax}

{phang}
{cmd:logitjack} {it:varlist}, {it:cluster(varname)}  [  {it:options}]

{phang}
{it:varlist} the dependent variable, the independent variable of
interest, and other (binary or continuous) independent variables,

{phang}
{it:cluster} the clustering variable. 

{synoptset 45 tabbed}{...}
{synopthdr}
{synoptline}

{synopt:{opt fevar(varlist)}}creates fixed effects for the included
variables, similar to {cmd:i.varname}.{p_end}

{synopt:{opt jack:knife}}calculates the jackknife variance estimator
CV3 in addition to CV3L.{p_end}

{synopt:{opt sam:ple}}allows for sample restrictions. For instance,
in order to restrict the analysis to individuals 25 years of age or
older based on a variable "age", sample(age>=25) should be added to
the list of options. {p_end}


{synopt:{opt BOOTstrap}} calculates WCL(U/R) p-values. When 
{cmd: nonull} is also specified WCLU p-values and confidence 
intervals are calculated and displayed.  When {cmd: nonull} is not
specified WCLR p-values are calculated and displayed.  The default number of
bootstrap replications is 999.  This can be changed using the {cmd: reps} option. 
The weight distribution used depends on the number of clusters.  When there are
13 or more clusters, then Rademacher weights used.  When there are 12 or fewer clusters, 
then Webb weights are used.{p_end}

{synopt:{opt reps(scalar)}} changes the number of bootstrap replications.  When this option
is not used, and bootstrap values are calculated, 999 replications are used.


{synopt:{opt no:null}} specifies that the unrestricted versions of 
the wild cluster linearized bootstrap be specified. This option can be used with 
or without the  {cmd: bootstrap} option.  The default number of
bootstrap replications is 999.  This can be changed using the {cmd: reps} option. {p_end}

{marker description}{...}
{title:Description}

{pstd}{cmd:logitjack} is a stand-alone command that calculates a linearized
version of the wild cluster bootstrap for logit models. It will calculate
a CV1 variance estimate, with p-values calculated using the t(G-1) distribution
for the t-statistics.  Native Stata uses the t(N-k) distribution which usually
results in over-rejection of the null hypothesis. {cmd:logitjack} calculates a jackknife
variance for the linearized model, CV3L, which in practice is very similar to the 
computationally demandind CV3 variance. {cmd:logitjack} also optionally 
calculates the brute-force cluster jackknife  CV3 variance estimator for logit models.
MacKinnon, Nielsen, and Webb (2024) documents it more fully
than this help file.  

{pstd}{cmd:logitjack} assumes that all omit-one-cluster subsamples are
estimatable. However, in practice some of the omit-one-cluster subsamples 
may be singular. {cmd:logitjack} calculates standard errors using a generalized
inverse.  Conversely, native Stata will drop the singular subsamples
{cmd: jackknife: reg y x, cluster(group)}.  Accordingly, the {cmd: jackknife} 
option within {cmd:logitjack} can give a different standard error than
native Stata will.  The generalized inverse is often desirable as things like 
cluster level fixed effects will cause all subsamples to be omitted by Stata.


{title:Stored results}

All of the matrices displayed on screen are available in memory after {cmd:logitjack}
runs.

{synopt:{cmd:matrix list cvtable}} shows the various CV standard errors, p-values and confidence intervals.

 
{synopt:{cmd:matrix list clustsum}} shows the various cluster specific statistics.

 
{synopt:{cmd:matrix list bootstuff}} shows the various bootstrap p-values. Only available when at least one of the options {cmd:bootstrap}, {cmd:nonull}, or {cmd:reps} are used.

{synopt:{cmd:matrix list bootci}} shows the various bootstrap confidence intervals. Only available when the option {cmd:nonull} is used.

{title:Examples}

{hline}

{pstd} nlswork -- using {cmd:logit}

{phang2}{cmd:. webuse nlswork, clear}

{phang2}{cmd:. gen age2 = age*age}

{phang2}{cmd:. drop if race==3}

{phang2}{cmd:. drop if inlist(ind,41,54)}

{phang2}{cmd:. gen white = race==1}

{phang2}{cmd:. logit collgrad south msp white union ln_wage  age age2 i.ind, cluster(ind)}

{pstd} nlswork -- using {cmd:logitjack}

{phang2}{cmd:. logitjack collgrad south msp white union ln_wage  age age2 , cluster(ind) fevar(ind) }

{pstd} adding brute force jackknife (CV3)

{phang2}{cmd:. logitjack collgrad south msp white union ln_wage  age age2 , cluster(ind) fevar(ind) jack}

{pstd} restricted bootstraps using {cmd:bootstrap} or {cmd:reps}.

{phang2}{cmd:. logitjack collgrad south msp white union ln_wage  age age2 , cluster(ind) fevar(ind) boots}

{phang2}{cmd:. logitjack collgrad south msp white union ln_wage  age age2 , cluster(ind) fevar(ind) reps(1999)}

{pstd} unrestricted bootstraps using {cmd:nonull} .

{phang2}{cmd:. logitjack collgrad south msp white union ln_wage  age age2 , cluster(ind) fevar(ind)  nonull
}

{pstd} sample restrictions - using {cmd:sample}

{phang2}{cmd:. gen rndsample = runiform()}

{phang2}{cmd:. logitjack collgrad south msp white union ln_wage  age age2 , cluster(ind) fevar(ind)sample(rndsample<=0.5) }



{title:Author}

{p 4}Matthew D. Webb{p_end}
{p 4}matt.webb@carleton.ca{p_end}

{title:Citation}

{p 4 8 2}{cmd:logitjack} is not an official Stata command. It is a
free contribution to the research community.

Please cite:
{p 8 8 2} James G. MacKinnon,  Morten Ø. Nielsen, and Matthew D. Webb.
2024. Cluster-Robust Jackknife and Bootstrap Inference for Binary
Response Models.{p_end}



***************************************************************