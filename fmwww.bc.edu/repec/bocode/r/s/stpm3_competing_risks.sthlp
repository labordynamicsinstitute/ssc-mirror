{smcl}
{* *! version 1.0.0}{...}
{vieweralsosee "stpm3 postestimation" "help stpm3_postestimation"}{...}
{vieweralsosee "stpm3 extended varlist" "help stpm3_extfunctions"}{...}
{vieweralsosee "stpm3" "help stpm3"}{...}

{title:A guide to competing risks models in {cmd:stpm3}}

{pstd}
In {cmd:stpm3} it is possible to fit cause-specific competing risks models.
These models can then be combined to predict a variety of useful competing 
risks based measures.

{pstd}
The best way to use this help file is to start without
a dataset in memory and load the data and then click through the different 
sections of code.




{pstd}{cmd:use https://www.pclambert.net/data/rott2b}{p_end}
{pstd}({it:{stata "stpm3_competing_risks_eg 0":click to load data (clear current data first)}}){p_end}

{dlgtab:Model 1 - cause-specific model (cancer)}

{pstd}
The model will include one binary covariate, {bf:hormon},
and a continous covariate, {bf:age}, modelled using natural splines,
using the extended function, {cmd:@ns()}.

{pstd}
When using {cmd:stset} we need to use the option {cmd:failure(cause = 1)}
so that deaths due to cancer are considered as events. 

{pstd}
Predictions of cause-specific survival will be made at each level of {bf:hormon}
for a 60 year old.
This can be done through the use of two {cmd:at()} options in the 
{cmd:predict} command. 

{pstd}
The predictions are saved to a frame and then plotted.


{pstd}{cmd:stset os, failure(cause = 1) scale(12) exit(time 120)}{p_end}
{pstd}{cmd:stpm3 @ns(age,df(3)) i.hormon, scale(lncumhazard) df(5)}{p_end}
{pstd}{cmd:estimates store cancer}{p_end}
{pstd}{cmd:predict S0_age60 S1_age60, surv ci at1(age 60 hormon 0) at2(age 60 hormon 1) timevar(0 10) frame(cancer, replace)}{p_end}
{pstd}{cmd:frame cancer: frame cancer: line S0_age60 S1_age60 tt}{p_end}
{pstd}({it:{stata "stpm3_competing_risks_eg 1":click to run.}}){p_end}

{pstd}
Note that {cmd:estimate store cancer} has been used as this will be needed
when calculating the cause-specific cumulative incidence function later.


{dlgtab:Model 2 - cause-specific model (other causes)}

{pstd}
The same covariates as above will be used, i.e.  {bf:hormon}
and {bf:age}, modelled using natural splines.

{pstd}
We need to use {cmd:stset} again, but now use the option {cmd:failure(cause = 2)}
so that deaths due to other causes are considered as events. 

{pstd}
The predict statement is the same as above, but predictions
will be saved to a different frame. 

{pstd}{cmd:stset os, failure(cause = 2) scale(12) exit(time 120)}{p_end}
{pstd}{cmd:stpm3 @ns(age,df(3)) i.hormon, scale(lncumhazard) df(5)}{p_end}
{pstd}{cmd:estimates store other}{p_end}
{pstd}{cmd:predict S0_age60 S1_age60, surv ci at1(age 60 hormon 0) at2(age 60 hormon 1) timevar(0 10) frame(other, replace)}{p_end}
{pstd}{cmd:frame other: line S0_age60 S1_age60 tt}{p_end}
{pstd}({it:{stata "stpm3_competing_risks_eg 2":click to run.}}){p_end}


{dlgtab:Predicting cause-specific cumulative incidence functions}

{pstd}
The cause specific survival-hazard functions are predictions from a single model.
However, these do not give "real world" probabilities of survival/death.
The cause-specific cumulative incidence function (CIF) gives the probability of death
accouting for competing risks, which means that predictions will depend upon 
more tham one model. In the Roterdam example, there are two competing risks and
so predictions depend upon the cause-specific cancer model and the
cause-specific other causes model. These can be passed to the {cmd:predict}
command using the {cmd:crmodels()} option.

{pstd}{cmd:predict CIF0_age60 CIF1_age60, cif crmodels(cancer other) ci timevar(0 10) at1(age 60 hormon 0) at2(age 60 hormon 1) frame(cif, replace)}{p_end}
{pstd}{cmd:frame cif: line CIF0_age60_cancer CIF0_age60_other tt}{p_end}
{pstd}({it:{stata "stpm3_competing_risks_eg 3":click to run.}}){p_end}

{dlgtab:Predicting all-cause functions}

{pstd}
It is also possible to predict the all cause survival or hazard functions.
This can be useful, for example, when producing stacked plots.

{pstd}{cmd:predict F0_age60 F1_age60, failure ci crmodels(cancer other) at1(age 60 hormon 0) at2(age 60 hormon 1) frame(cif, merge)}{p_end}
{pstd}{cmd:frame cif: twoway (area CIF0_age60_cancer tt) (rarea CIF0_age60_cancer F0_age60 tt), legend(order(1 "cancer" 2 "other"))}{p_end}
{pstd}({it:{stata "stpm3_competing_risks_eg 4":click to run.}}){p_end}

    
     
    



