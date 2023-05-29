{smcl}
{* *! version 1.0.1  2023-03-23}{...}
{vieweralsosee "stpm3" "help stpm3"}{...}
{vieweralsosee "stpm3 extended varlist" "help stpm3_extfunctions"}{...}
{vieweralsosee "stpm3 predictions guide" "help stpm3_predictions"}{...}
{vieweralsosee "standsurv" "help standsurv"}{...}
{viewerjumpto "Syntax" "stpm3km##syntax"}{...}
{viewerjumpto "Description" "stpm3km##description"}{...}
{viewerjumpto "Options" "stpm3km##options"}{...}
{viewerjumpto "Remarks" "stpm3km##remarks"}{...}
{viewerjumpto "Examples" "stpm3km##examples"}{...}

{marker syntax}{...}
{title:Syntax for stpm3km}

{pstd}
Compare marginal survival predictions to Kaplan-Meier estimates 
after fitting a {helpb stpm3:stpm3} model.

{pstd}
By default only data included in the model is used. If you 
want to include data not in the model then use then
{cmd:noesample} option. This can be useful for external validation.


{p 8 16 2}
{cmd:stpm3km}
[{it:varname}]
{ifin} [,{it: options,}]

{synoptset 25 tabbed}{...}
{syntab:{bf: Options}}
{synoptline}
{synopthdr:option}
{synoptline}
{synopt :{opt cut(options)}}the breaks for the groups {p_end}
{synopt :{opt noesamp:le}}predict out of sample{p_end}
{synopt :{opt fac:tor}}states {it:varname} is a factor{p_end}
{synopt :{opt failure}}calculate failure rather than survival{p_end}
{synopt :{opt fr:ame(framename)}}predictions will be saved to frame {it:framename}{p_end}
{synopt :{opt nogr:aph}}do not plot graph{p_end}
{synopt :{opt gr:oups(#)}}Number of groups for continuous covariates{p_end}
{synopt :{opt nokm}}Do not include Kaplan-Meier estimates on graph{p_end}
{synopt :{opt maxt(#)}}maximum follow-up time{p_end}
{synopt :{opt ntime:var(#)}}Number of timepoints for standsurv{p_end}
{synopt :{opt pit:ime(#)}}Time for prognostic index when time-dependent effects{p_end}

{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:stpm3km} can be used after fitting a {cmd:stpm3} model. 
Continous covariates are categorized into groups and the 
marginal survival function is calculated within each group level 
and compared to the corresponding Kaplan-Meier estimate.

{phang}
If {it:varname} is not specified then the prognostic index is categorized.

{phang}
The default number of groups is 5. This can be changed with the {cmd:groups(#)} option.
The groups will be of roughly equal frequencies. You can define your own groups using
the {cmd:cut()} option.


{marker options}{...}
{title:Options}

{phang}
{opt cut(numlist)} a numlist in ascending order giving the breaks for the groups
of {it:varname} or the prognostic index. 

{phang}
{opt noesample} allows data not included in the model to be used. This is
useful for external validation.

{phang}
{opt factor} specifies that {it:varname} is a factor (categorical) variable.

{phang}
{opt frame(framename)} saves the Kaplan-Meier and model based standardized
estimates to a frame.

{phang}
{opt nograph} suppresses plotting of the graph. It only makes sense to use
this option in conjunction with the {cmd:frame()} option.

{phang}
{opt groups(#)} specifies how many groups to create. The default is 5.
If there are many ties in {it:varname} there may be less groups then specified.

{phang}
{opt maxt(#)} specifies the maxiumum follow-up time for survival predictions and for plotting
the Kaplan-Meier curve.

{phang}
{opt ntimevar(#)} specifeis the number of timepoints to calculate the predicted survival curve
at. The default is 100.

{phang}
{opt pitime(#)} is for use when the {cmd:stpm3} model has time-dependent effects
and the user wants to use a prognostic index to define the groups.
The prognostic index will be time-dependent, so this option specifies which time
the prognostic index is calculated at.

{marker remarks}{...}
{title:Remarks}

Some remarks

{marker examples}{...}
{title:Examples}

{pstd}
All examples use the Roterdam data available on my website.
First load and {cmd:stset} the data and then all examples are clickable.
You will need to clear data in memory before running. 

{pmore}
{stata "use https://pclambert.net/data/rott2b.dta":. use "https://pclambert.net/data/rott2b.dta"}{p_end}
{pmore}
{stata "stset os, failure(osi=1) scale(12) exit(time 120)":. stset os, failure(osi=1) scale(12) exit(time 120)}{p_end}



{title:Example 1:}

{pmore}
Fit {cmd:stpm3} model

{pmore}
{stata "stpm3 @ns(age,df(3)) i.hormon enodes, scale(lncumhazard) df(4)":. stpm3 @ns(age,df(3)) i.hormon enodes, scale(lncumhazard) df(4)}{p_end}

{pmore}
Compare marginal predictions in 5 groups (the default) based on prognostic index

{pmore}
{stata "stpm3km":. stpm3km}{p_end}

{pmore}
Compare marginal predictions in 4 groups based on distribution of age

{pmore}
{stata "stpm3km age, groups(4)":. stpm3km age, groups(4)}{p_end}

{pmore}
Compare marginal predictions in based on factor variable {cmd:hormon}

{pmore}
{stata "stpm3km hormon, factor":. stpm3km hormon, factor}{p_end}


{title:Author}
{pstd}Paul C. Lambert{p_end}
{pstd}Biostatistics Research Group{p_end}
{pstd}Department of Health Sciences{p_end}
{pstd}University of Leicester{p_end}
{pstd}{it: and}{p_end}
{pstd}Department of Medical Epidemiology and Biostatistics{p_end}
{pstd}Karolinska Institutet{p_end}
{pstd}E-mail: {browse "mailto:paul.lambert@le.ac.uk":paul.lambert@le.ac.uk}{p_end}



