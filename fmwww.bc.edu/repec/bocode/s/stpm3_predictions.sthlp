{smcl}
{* *! version 1.0.0}{...}
{vieweralsosee "stpm3 postestimation" "help stpm3_postestimation"}{...}
{vieweralsosee "stpm3 extended varlist" "help stpm3_extfunctions"}{...}
{vieweralsosee "stpm3" "help stpm3"}{...}

{title:A guide to predictions for {cmd:stpm3}}

{pstd}
{cmd:stpm3} has a range of useful post-estimation utilities. 
This help file shows how to obtain various types of predictions conditional on covariate patterns.

{pstd}
For more examples see 
{bf:{browse "https://pclambert.net/software/stpm3/":https://pclambert.net/software/stpm3/}}.

{dlgtab:Load data}

{pstd}
It is easier to show through examples, so the best way to use this help file is to start without
a dataset in memory and load the data and then click through the different examples.

{pstd}{cmd:use https://www.pclambert.net/data/rott2b}{p_end}
{pstd}{cmd:stset os, failure(osi = 1) scale(12) exit(time 120)}{p_end}
{pstd}{it:({stata "stpm3_predictions_eg 0":click to load data (clear current data first)})}{p_end}

{dlgtab:Example 1 - simple model with a single covariate}

{pstd}
The model will include one binary covariate, {bf:hormon}.
Predictions of the survival will be made at each level of {bf:hormon}.
This can be done through the use of two {cmd:at()} options. 

{pstd}{cmd:stpm3 i.hormon, scale(lncumhazard) df(5) eform}{p_end}
{pstd}{cmd:predict S0 S1, surv ci at1(hormon 0) at2(hormon 1) timevar(0 10)}{p_end}
{pstd}{bf:frame stpm3_pred {c -(}}{p_end}
{p 6}{bf:line S0 S1 tt}{p_end}
{p 6}{bf:list in 1/10}{p_end}
{pstd}{bf:{c )-}}{p_end}
{pstd}{it:({stata "stpm3_predictions_eg 1a":click to run.})}{p_end}

{pstd}
This has saved predictions to a new frame named {it:stpm3_pred}.
If you try running the command again, you will get an error as the frame now exists.
You could use {cmd:frame(,replace)}} or write to a different frame.

{pstd}{cmd:predict S0 S1, surv ci at1(hormon 0) at2(hormon 1) timevar(0 10) frame(p, replace)}{p_end}
{pstd}{bf:frame p: describe}{p_end}
{pstd}{it:({stata "stpm3_predictions_eg 1b":click to run.})}{p_end}

{pstd}
If you look at what has been created in frame {cmd:p} it contains a time variable {bf:tt} that has
100 equally spaced observations between 0 and 10. The predictions and lower and upper bounds
of the 95% confidence intervals are for each value of time.

{pstd}
Instead of using {bf:timevar(0 10)} we could have created a time variable and then used
the {bf:timevar}({it:varname}) option.

{pstd}{cmd:range tt 0 10 100}{p_end}
{pstd}{cmd:predict S0 S1, surv ci at1(hormon 0) at2(hormon 1) timevar(tt) frame(p, replace)}{p_end}
{pstd}{bf:frame p: list in 1/10}{p_end}
{pstd}{it:({stata "stpm3_predictions_eg 1c":click to run.})}{p_end}

{pstd}
It can be useful to have nicer spaced intervals. You can use the {bf:step()} suboption to define the gap between
the time points. Below we use {cmd:step(0.1)}, this enable us to list times at specific years.

{pstd}{cmd:predict S0 S1, surv ci at1(hormon 0) at2(hormon 1) timevar(0 10, step(0.1)) frame(p, replace)}{p_end}
{pstd}{bf:frame p: list if inlist(tt,1,5,10), noobs}{p_end}
{pstd}{it:({stata "stpm3_predictions_eg 1d":click to run.})}{p_end}

{pstd}
The same could have been achieved by using the option {bf:n(101)}. This is shown below where we also 
change the name of the time variable using the {bf:gen()} suboption. 

{pstd}{cmd:predict S0 S1, surv ci at1(hormon 0) at2(hormon 1) timevar(0 10, n(101) gen(time)) frame(p, replace)}{p_end}
{pstd}{bf:frame p: list in 1/10 }{p_end}
{pstd}{it:({stata "stpm3_predictions_eg 1e":click to run.})}{p_end}

{pstd}
You do not have to save data to a frame. If you use the {bf:merge} option 
the predictions will be merged with the current dataset.

{pstd}{cmd:predict S0 S1, surv ci at1(hormon 0) at2(hormon 1) timevar(0 10, step(0.1) gen(t)) merge}{p_end}
{pstd}{bf:list t S0* S1* in 1/10}{p_end}
{pstd}{it:({stata "stpm3_predictions_eg 1f":click to run.})}{p_end}

{dlgtab:Example 2 - Including more covariates}

{pstd}
Now we will fit a model with more (3) covariates. 
This will include the binary covariate {bf:hormon} and the continuous covariates {bf:age} and {bf:nodes}.
Both {bf:age} and {bf:nodes}. will be modelled using natural splines with 3df (4 knots) 
using {helpb stpm3_extfunctions:stpm3 extendend functions}.
We will also include an interaction between {bf:hormon} and {bf:age}.

{pstd}{cmd:stpm3 i.hormon##@ns(age,df(3)) i.size, scale(lncumhazard) df(5) eform}{p_end}
{pstd}{cmd:predict S0 S1, surv ci at1(hormon 0 age 60 size 3) at2(hormon 1 age 60 size 3) timevar(0 10, step(0.1)) frame(p, replace)}{p_end}
{pstd}{bf:frame p {c -(}}{p_end}
{p 6}{bf:line S0 S1 tt}{p_end}
{p 6}{bf:list in 1/10}{p_end}
{pstd}{bf:{c )-}}{p_end}
{pstd}{it:({stata "stpm3_predictions_eg 2a":click to run.})}{p_end}

{pstd}
Although the model is complex containing non-linear effects and interaction terms,
the prediction syntax is relatively easy. The only covariates in the model
are {cmd:age}, {cmd:size} and {cmd:hormon}. so all the {cmd:predict} command needs is the
age and the levels of {cmd:size} and {cmd:hormon} you want a prediction for.

{pstd}
If your model contains time-dependent effects using the {cmd:tvc()} option,
then the prediction command stays the same.

{pstd}{cmd:stpm3 i.hormon##@ns(age,df(3)) i.size, scale(lncumhazard) df(5) tvc(@ns(age,df(3))) dftvc(3)}{p_end}
{pstd}{cmd:predict S0 S1, surv ci at1(hormon 0 age 60 size 3) at2(hormon 1 age 60 size 3) timevar(0 10, step(0.1)) frame(p, replace)}{p_end}
{pstd}{bf:frame p {c -(}}{p_end}
{p 6}{bf:line S0 S1 tt}{p_end}
{p 6}{bf:list in 1/10}{p_end}
{pstd}{bf:{c )-}}{p_end}
{pstd}{it:({stata "stpm3_predictions_eg 2b":click to run.})}{p_end}

