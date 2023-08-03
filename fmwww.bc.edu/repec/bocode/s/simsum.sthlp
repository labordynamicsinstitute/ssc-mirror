{smcl}
{* updated 12jun2023  Ian White}{...}
{* v2.0  13jan2023  Ian White}{...}
{viewerjumpto "Syntax" "simsum##syntax"}{...}
{viewerjumpto "Main options" "simsum##main_options"}{...}
{viewerjumpto "Data checking options" "simsum##check_options"}{...}
{viewerjumpto "Calculation options" "simsum##calc_options"}{...}
{viewerjumpto "Options specifying degrees of freedom" "simsum##df_options"}{...}
{viewerjumpto "Performance measure options" "simsum##pm_options"}{...}
{viewerjumpto "Display options" "simsum##display_options"}{...}
{viewerjumpto "Output data set options" "simsum##output_options"}{...}
{viewerjumpto "Example" "simsum##example"}{...}
{viewerjumpto "Errata" "simsum##errata"}{...}
{viewerjumpto "References" "simsum##refs"}{...}
{viewerjumpto "Citation" "simsum##citation"}{...}
{viewerjumpto "Author and updates" "simsum##updates"}{...}
{title:Title}

{phang}{hi:simsum} - Analyses of simulation studies including Monte Carlo error


{title:Introduction}

{p 4 4 2}
The program {cmd:simsum} computes performance measures for 
simulation studies in which each simulated data set yields point estimates by one or more analysis 
methods. 
Bias, empirical standard error, precision relative to a reference method and mean squared error can be computed for each method.
If, in addition, model-based standard errors are available then {cmd:simsum} can compute 
the average model-based standard error, 
the relative error in the model-based standard error, the coverage of nominal confidence intervals, 
and the power to reject a null hypothesis. 
Monte Carlo errors are available for all estimated quantities.

{p 4 4 2}
This is a user-written command: please cite {help simsum##citation:our paper}, which also gives more details of the methods.
Please also see our {help simsum##Morris++19:tutorial} on simulation studies.


{title:Syntax}{marker syntax}

{p 4 4 2}
Data may be in a wide or long format. 

{p 4 4 2}
In the wide format, the data contain one record per simulated data set. 
The appropriate syntax is:

{p 8 17 2}
{cmd:simsum} {it:estvarlist} {ifin}, [{cmd:true(}{it:expression}{cmd:)} {it:options}]

{p 4 4 2}
where {it:estvarlist} is a {it:varlist} containing point estimates from one or more analysis methods.

{p 4 4 2}
In the long format, the data contain one record per method per simulated data set, and the appropriate syntax is:

{p 8 17 2}
{cmd:simsum} {it:estvarname} {ifin}, [{cmd:true(}{it:expression}{cmd:)} {cmdab:meth:odvar(}{it:varname}{cmd:)} {cmd:id(}{it:varlist}{cmd:)}  {it:options}]

{p 4 4 2}
where {it:estvarname} is a variable containing the point estimates, 
{cmdab:meth:odvar(}{it:varname}{cmd:)} identifies the method and {cmd:id(}{it:varlist}{cmd:)} identifies the simulated data set. 
The {it:options} are described below.


{title:Main options}{marker main_options}

{phang} {cmd:true(}{it:expression}{cmd:)} gives the true value of the parameter. 
This is used in calculations of bias and coverage and is required whenever these performance measures are requested.

{phang} {cmdab:meth:odvar(}{it:varname}{cmd:)} specifies that the data are in long format, 
with each record representing one analysis of one simulated data set using the method identified by {it:varname}. 
Option {cmd:id({it:varlist})} must be specified.
If {cmdab:meth:odvar()} is not specified, the data must be in wide format, with each record representing all analyses of one simulated data set.

{phang} {cmd:id(}{it:varlist}{cmd:)} is required with option {cmdab:meth:odvar()}. 
{it:varlist} must uniquely identify the data set used for each record, within levels of the by-variables.

{phang} {cmd:se(}{it:varlist}{cmd:)} lists the names of the variables containing the standard errors of the point estimates. 
For data in long format, this is a single variable.

{phang} {cmdab:sep:refix(}{it:string}{cmd:)} specifies that the names of the variables containing the standard errors of the point estimates 
are formed by adding the given prefix to the names of the variables containing the point estimates. 
It may be combined with {cmdab:ses:uffix(}{cmd:)} but not with {cmd:se(}{cmd:)}.

{phang} {cmdab:ses:uffix(}{it:string}{cmd:)} specifies that the names of the variables containing the standard errors of the point estimates 
are formed by adding the given suffix to the names of the variables containing the point estimates. 
It may be combined with {cmdab:sep:refix(}{cmd:)} but not with {cmd:se(}{cmd:)}.


{title:Data checking options}{marker check_options}

{phang} {cmd:graph} requests a descriptive graph of standard errors against point estimates.

{phang} {cmdab:nomem:check} turns off checking that adequate memory is free. 
This check aims to avoid spending calculation time when {cmd:simsum} is likely to fail due to lack of memory.

{phang} {cmd:max(}#{cmd:)} specifies the maximum acceptable absolute value of the point estimates, standardised to mean 0 and SD 1. 
The default value is 10.

{phang} {cmd:semax(}#{cmd:)} specifies the maximum acceptable value of the standard error, as a multiple of the mean standard error. 
The default value is 100.

{phang} {cmd:dropbig} specifies that point estimates or standard errors beyond the maximum acceptable values should be dropped. 
Otherwise the program halts with an error. (Missing values are always dropped.)

{phang} {cmd:nolistbig} suppresses listing of point estimates and standard errors that lie outside the acceptable limits.

{phang} {cmd:listmiss} lists observations with missing point estimates and/or standard errors.


{title:Calculation options}{marker calc_options}

{phang} {cmd:level(}#{cmd:)} specifies the confidence level for coverages and powers. Default is {cmd:$level}.

{phang} {cmd:by(}{it:varlist}{cmd:)} computes performance measures by {it:varlist}.

{phang} {cmd:mcse} reports Monte Carlo standard errors for all performance measures.

{phang} {cmd:robust} is only useful if {cmd:mcse} is also specified. 
It requests robust Monte Carlo standard errors for the performance measures {cmd:empse}, {cmd:relprec} and {cmd:relerror}, 
instead of those based on an assumption of normally distributed point estimates.

{phang} {cmdab:modelsem:ethod(rmse|mean)} specifies whether the model standard error should be computed
as the root mean squared value (the default) or as the arithmetic mean.

{phang} {cmd:ref(}{it:string}{cmd:)} specifies the reference method against which relative precisions will be calculated. 
With data in wide format, {it:string} must be a variable name. 
With data in long format, {it:string} must be a value of the method variable; if the value is labelled then the label must be used.

{phang} {cmd:null(}#{cmd:)} specifies the null value against which power will be calculated. 


{title:Options specifying degrees of freedom}{marker df_options}

{phang} Degrees of freedom are used in calculating coverages and powers.

{phang} {cmd:df(}{it:string}{cmd:)} specifies the degrees of freedom. 
It may contain a variable name or a number (to apply to all estimators), or a list of variables containing the degrees of freedom for each estimator.

{phang} {cmdab:dfp:refix(}{it:string}{cmd:)} specifies that the names of the variables containing the degrees of freedom are formed 
by adding the given prefix to the names of the variables containing the point estimates. 
It may be combined with {cmd:dfsuffix()} but not with {cmd:df()}.

{phang} {cmdab:dfs:uffix(}{it:string}{cmd:)} specifies that the names of the variables containing the degrees of freedom are formed 
by adding the given suffix to the names of the variables containing the point estimates. 
It may be combined with {cmd:dfprefix()} but not with {cmd:df()}.


{title:Performance measure options}{marker pm_options}

{phang}If none of the following options is specified, then all available performance measures are computed.

{phang} {cmd:bsims} reports the number of simulations with non-missing point estimates.

{phang} {cmd:sesims} reports the number of simulations with non-missing standard errors.

{phang} {cmd:bias} estimates the bias in the point estimates.

{phang} {cmd:mean} estimates the mean of the point estimates.

{phang} {cmd:empse} estimates the empirical standard error -- the standard deviation of the point estimates.

{phang} {cmd:relprec} estimates the relative precision 
-- the inverse squared ratio of the empirical standard error of this method to the empirical standard error of the reference method.
This calculation is slow: omitting it can reduce run time by up to 90%.

{phang} {cmd:mse} estimates the mean squared error.

{phang} {cmd:rmse} estimates the root mean squared error.

{phang} {cmd:modelse} estimates the model-based standard error. See {cmd:modelsemethod()} above.

{phang} {cmd:ciwidth} estimates the mean confidence interval width. 

{phang} {cmd:relerror} estimates the proportional error in the model-based standard error, using the empirical standard error as gold standard.

{phang} {cmd:cover} estimates the coverage of nominal confidence intervals at the specified level.

{phang} {cmd:power} estimates the power to reject the null hypothesis at the specified level.
The null hypothesis is that the true parameter is the value specified by the {cmd:null()} option, or zero if this is not specified.

{phang}The table below shows which performance measures require the true value specified by {cmd:true()} and which require the standard error specified by {cmd:se()}, {cmd:seprefix()} or {cmd:sesuffix()}:

{col 8} {col 23} true {col 39} se
{col 8} bsims {col 25}  {col 40} 
{col 8} sesims {col 25}  {col 40} x
{col 8} bias {col 25} x {col 40} 
{col 8} mean {col 25}  {col 40} 
{col 8} empse {col 25}  {col 40}
{col 8} relprec {col 25}  {col 40} 
{col 8} mse {col 25} x {col 40} 
{col 8} rmse {col 25} x {col 40} 
{col 8} modelse {col 25}  {col 40} x
{col 8} ciwidth {col 25}  {col 40} x
{col 8} relerror {col 25}  {col 40} x
{col 8} cover {col 25} x {col 40} x
{col 8} power {col 25}  {col 40} x


{title:Display options}{marker display_options}

{phang} {cmd:nolist} suppresses listing of the results, and is only allowed when {cmd:clear} or {cmd:saving()} is specified.

{phang} {cmd:listsep} lists the results using one table per performance measure, giving narrower & better formatted output.
The default is to list the results as a single table.

{phang} {cmd:format(}{it:string}{cmd:)} specifes the format for printing the results and saving the 
performance measure data.
If {cmd:listsep} is also specified then up to three formats may be specified: 
(1) for results on the scale of the original estimates (bias, empse, modelse);
(2) for percentages (relprec, relerror, cover, power);
(3) for integers (bsims, sesims).
Defaults are the existing format of the [first] estimate variable for (1) and (2), and %7.0f for (3).

{phang} {cmd:sepby(}{it:varlist}{cmd:)} invokes this {cmd:list} option when printing the results.

{phang} {cmdab:ab:breviate(}#{cmd:)} invokes this {cmd:list} option when printing the results.


{title:Output data set options}{marker output_options}

{phang} {cmd:clear} loads the performance measure data into memory.

{phang} {cmd:saving(}{it:filename}{cmd:)} saves the performance measure data into {it:filename}.

{phang} {cmd:gen(}{it:string}{cmd:)} 
specifies the prefix for new variables identifying the different performance measures in the output data set 
(only useful with {cmd:clear} or {cmd:saving()}).

{phang} {cmdab:trans:pose}
transposes the output data set so that performance measures are columns and methods are rows
(only useful with {cmd:clear} or {cmd:saving()}).


{title:Example}{marker example}

{phang}This example uses data in long format stored in MIsim.dta:

{phang}{cmd:. simsum b, se(se) methodvar(method) id(dataset) true(0.5) mcse format(%7.0g)}

{phang}Alternatively, the data could first be reshaped to wide format:

{phang}{cmd:. reshape wide b se, i(dataset) j(method) string}

{phang}{cmd:. simsum b*, se(se*) true(0.5) mcse format(%7.0g)}


{title:Errata}{marker errata}

{phang} One formula is written wrongly in the Stata Journal article, but the correct formula is used in the program. 
This is in the fourth equation on page 378, giving the MC error for the model-based standard error under the {cmd:modelsemethod(mean)} option.
The denominator n in this formula should be n(n-1).

{phang} Until v0.18, the formula for the MCSE of the relative precision used (n-2) in the denominator. This is now (n-1) as in the Stata Journal article. The difference is unlikely to have any practical importance.


{title:References}{marker refs}

{phang}{marker White++10}
White IR. 
simsum: Analyses of simulation studies including Monte Carlo error. 
Stata J. 2010;10:369-385. 
{browse "http://www.stata-journal.com/article.html?article=st0200"}

{phang}{marker Morris++19}
Morris TP, White IR, Crowther MJ. 
Using simulation studies to evaluate statistical methods. 
Stat Med. 2019;38(11):2074-2102. 
{browse "http://doi.wiley.com/10.1002/sim.8086"}


{title:Citation}{marker citation}

{phang}If you find this command useful, please cite it as below (and please check for updates): 

{phang}White IR. 
simsum: Analyses of simulation studies including Monte Carlo error. 
Stata J. 2010; 10: 369-385. 
{browse "http://www.stata-journal.com/article.html?article=st0200"}


{title:Author and updates}{marker updates}

{phang}Ian White, MRC Clinical  Trials Unit at UCL, London, UK. 
Email {browse "mailto:ian.white@ucl.ac.uk":ian.white@ucl.ac.uk}.

{phang}You can get the latest version of this package by visiting {browse "https://github.com/UCL/simsum"}
or within Stata by running 
{stata "net from https://raw.githubusercontent.com/UCL/simsum/main/package/"}.

{phang}You can browse my other Stata software using 
{stata "net from http://www.homepages.ucl.ac.uk/~rmjwiww/stata/"}.


