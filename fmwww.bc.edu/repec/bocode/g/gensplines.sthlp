{smcl}
{* *! version 0.1 2022-03-16}{...}
{vieweralsosee "rcsgen" "help rcsgen"}{...}
{hline}
{title:Title}

{p2colset 5 18 10 2}{...}
{p2col :{hi:gensplines} {hline 1}}generate various types of spline basis functions{p_end}
{p2colreset}{...}

{title:Syntax}
{p 8 16 2}{cmd:gensplines}  {varname | #} {ifin}, 
[{it:options}]


{marker options}{...}
{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Options}
{synopt :{opt allk:nots(numlist)}}full list of knots{p_end}
{synopt :{opt bk:knots}}boundary knots{p_end}
{synopt :{opt center}}center splines at mean{p_end}
{synopt :{opt center(#)}}center at #{p_end}
{synopt :{opt deg:ree(#)}}degree of spline function{p_end}
{synopt :{opt dgen(stub)}}generate derivatives of splines{p_end}
{synopt :{opt df(#)}}df for splines{p_end}
{synopt :{opt fw(varname)}}frequency weights{p_end}
{synopt :{opt gen(stub)}}generate spline variables{p_end}
{synopt :{opt int:ercept}}return all basis functions{p_end}
{synopt :{opt kn:ots(numlist)}}internal knots{p_end}
{synopt :{opt type(splinetype)}}type of spline function{p_end}
{synopt :{opt subc:entile(exp)}}knot positions based on expression{p_end}
{synopt :{opt win:sor(numlist)}}winsorise before calculation of spline variables{p_end}

{p2colreset}{...}
{p 4 6 2}

{title:Description}

{pstd}
{cmd:genplines} calculates various types of spline basis functions. This includes
splines based on truncated powers, restricted cubic splines, B-splines, M-splines, I-splines and, natural splines. 
Note that natural splines and restricted splines are two different ways to impose linearity constraints beyond the 
boundary knots and will result in the same fitted values in a regression model.

{pstd}
For B-splines, M-splines, I-splines and, natural splines the methods follow those of Wang 2021,
and implemented in R in the {cmd:splines2} package.

{pstd}
It is also possible to generate integrated B-splines and integrated natural splines.

{pstd}
If using {cmd: gensplines} {it:varname} then new variables are created.

{pstd}
If using {cmd: gensplines} {it:#} then new scalars are created.


{title:Options}

{phang}
{opt allknots(numlist, [options])} a list of the location of the knots. The boundary knots are included in the numlist.
If you use the {cmd:percentiles} option then knots are calculated at the list of percentiles.

{phang}
{opt bknots(numlist)} a numlist of length 2 giving the boundary knots. 
The default boundary knots are at the minimum and maxiumum of {varname}.

{phang}
{opt center(#)} will center the spline variables around a single value {it:#}.  The created spline variables will be zero at this value.

{phang}
{opt center} will center the spline variables around the mean of x.  

{phang}
{opt degree(#)} the degree for truncated powers, B-splines, M-splines and I-Splines.

{phang}
{opt dgen(stub)} gives a stubname for the derivatives of the spline variables.
For example, {cmd:dgen(dbs)} will create variables {bf:dbs1}, {bf:dbs2}, ....

{phang}
{opt df(#)} sets the desired degrees of freedom (df), i.e. the number of spline variables that are created. 
For B-splines, M-Splines and I-splines the number of internal knots is {it:df} - {it:degree} + 1.
For natural and restricted cubic splines the number of internal knots is {it:df} - 1.
Knots are placed at equally spaced centiles of the distribution of {it:varname}.  
For example, {cmd:df(5)} places internal knots at the 20th, 40th, 60th, 80th centiles 
of the distribution of {it:varname}. 

{phang}
{opt fw(varname)} gives the name of the variable containing frequency weights when 
generating knots using {cmd:df()} option.
This option may be useful for aggregated (collapsed) data.

{phang}
{opt gen(stub)} gives a stubname for the splines variables.
For example, {cmd:gen(bs)} will create variable {bf:bs1}, {bf:bs2}, ....

{phang}
{opt intercept} generates all splines basis variables. 
By default the first basis variable is not generated.

{phang}
{opt knots(numlist)} a list of the location of the internal knots.

{phang}
{opt type(splinetype)} The type of spline function. 
The different types of splines are listed below.

{synoptset 30 tabbed}{...}
{synoptline}
{synopt :{opt bs}}B-splines{p_end}
{synopt :{opt ns}}natural cubic splines{p_end}
{synopt :{opt rcs}}restricted cubic splines{p_end}
{synopt :{opt ms}}M-splines{p_end}
{synopt :{opt is}}I-splines{p_end}
{synopt :{opt tp}}truncated powers{p_end}
{synopt :{opt ibs}}integrated B-splines{p_end}
{synopt :{opt ins}}integrated natural cubic splines{p_end}
{synoptline}

{phang}
{opt subcentile(exp)} gives an expression to calculate the knots based on a subset 
of the data.  For example in survival (time-to-event) data when using splines 
for the time scale it is common to calculate the knot locations based on the
distribution of uncensored event times.

{phang}
{opt winsor(#1 #2)} gives 2 centiles to winsorise {it:varname}. 
When calculating the spline variables values < than the value defined by the {#1 th} centile will 
be replaced by that value and values > than the value defined by the {#2 th} centile will 
be replaced by that value. If the suboption {cmd:values} is specified then the actual 
values, rather than the centiles are used.


{title:Examples}

{pstd}Natural (cubic) splines{p_end}
{phang2}{cmd:. webuse mksp1}{p_end}
{phang2}{cmd:. gensplines age, df(3) type(ns) gen(age_ns)}{p_end}
{phang2}{cmd:. regress lninc age_ns*}{p_end}


{pstd}Quadratic bsplines - user defined knots{p_end}
{phang2}{cmd:. webuse mksp1}{p_end}
{phang2}{cmd:. gensplines age, knots(25 45 60) degree(2) type(bs) gen(age_bs)}{p_end}
{phang2}{cmd:. regress lninc age_bs*}{p_end}


{pstd}Restricted cubic splines - knots based on user defined centiles{p_end}
{phang2}{cmd:. webuse mksp1}{p_end}
{phang2}{cmd:. gensplines age, allknots(5 33 67 95, percentile) type(rcs) gen(age_rcs)}{p_end}
{phang2}{cmd:. regress lninc age_rcs*}{p_end}

{pstd}Natural (cubic) splines with winsorizing at 2nd and 98th percentiles{p_end}
{phang2}{cmd:. webuse mksp1}{p_end}
{phang2}{cmd:. gensplines age, df(3) type(ns) gen(age_ns) winsor(2 98)}{p_end}
{phang2}{cmd:. regress lninc age_ns*}{p_end}

{title:Author}

{p 5 12 2}{bf:Paul C. Lambert}{p_end}        
{p 5 12 2}Biostatistics Research Group{p_end}
{p 5 12 2}Department of Population Health Sciences{p_end}
{p 5 12 2}University of Leicester{p_end}
{p 5 12 2}Leicester, UK{p_end}
{p 5 12 2}{it: and}{p_end}
{p 5 12 2}Department of Medical Epidemiology and Biostatistics{p_end}
{p 5 12 2}Karolinska Institutet{p_end}
{p 5 12 2}Stockholm, Sweden{p_end}
{p 5 12 2}paul.lambert@le.ac.uk{p_end}


{title:References}
Wang W. Yan J. Shape-Restricted Regression Splines with R Package splines2." 
{it:Journal of Data Science} 2021;{bf:19};498–517.
