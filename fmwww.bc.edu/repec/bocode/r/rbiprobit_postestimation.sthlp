{smcl}
{* *! version 1.1.0: 18apr2022}{...}
{vieweralsosee "rbiprobit" "help rbiprobit"}{...}
{viewerjumpto "Postestimation commands" "rbiprobit postestimation##description"}{...}
{viewerjumpto "Syntax for predict" "rbiprobit postestimation##syntax_predict"}{...}
{viewerjumpto "Examples" "rbiprobit postestimation##examples"}{...}
{hline}
{hi:help rbiprobit postestimation}{right:{browse "https://github.com/cobanomics/rbiprobit":github.com/cobanomics/rbiprobit}}
{hline}
{right:also see:  {help rbiprobit: help rbiprobit}}

{marker description}{...}
{title:Postestimation commands}

{pstd}
The following postestimation commands are of special interest after {cmd:rbiprobit}:

{synoptset 19}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{synopt :{helpb rbiprobit_margdec:rbiprobit margdec}}marginal means, predictive margins, 
	marginal effects, and average marginal effects of {it:indepvars} and {it:indepvars}_en
	{p_end}
{synopt :{helpb rbiprobit_tmeffects:rbiprobit tmeffects}}treatment effects of treatment
	variable {it:depvar}_en
	{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The following postestimation commands are available after {cmd:rbiprobit}:

{synoptset 17 tabbed}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
INCLUDE help post_contrast
INCLUDE help post_estatic
INCLUDE help post_estatsum
INCLUDE help post_estatvce
INCLUDE help post_svy_estat
INCLUDE help post_estimates
INCLUDE help post_hausman_star
INCLUDE help post_lincom
INCLUDE help post_lrtest_star
INCLUDE help post_nlcom
{synopt :{helpb rbiprobit postestimation##predict:predict}}predictions, residuals, influence statistics, and other diagnostic measures{p_end}
INCLUDE help post_predictnl
INCLUDE help post_pwcompare
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {cmd:hausman} and {cmd:lrtest} are not appropriate with {cmd:svy} estimation results.
{p_end}


{marker syntax_predict}{...}
{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} 
{dtype}
{newvar} 
{ifin}
[{cmd:,} {it:statistic} {opt nooff:set}]

{p 8 16 2}
{cmd:predict}
{dtype}
{c -(}{it:stub*}{c |}{it:{help newvar:newvar_eq1}} {it:{help newvar:newvar_eq2}}
                     {it:{help newvar:newvar_atanrho}}{c )-}
{ifin}
{cmd:,}
{opt sc:ores}

{synoptset 17 tabbed}{...}
{synopthdr :statistic}
{synoptline}
{syntab :Main}
{synopt :{opt p11}}Pr({it:depvar}=1, {it:depvar}_en=1); the default{p_end}
{synopt :{opt p10}}Pr({it:depvar}=1, {it:depvar}_en=0){p_end}
{synopt :{opt p01}}Pr({it:depvar}=0, {it:depvar}_en=1){p_end}
{synopt :{opt p00}}Pr({it:depvar}=0, {it:depvar}_en=0){p_end}
{synopt :{opt pmarg1}}Pr({it:depvar}=1); marginal success probability for outcome equation{p_end}
{synopt :{opt pmarg2}}Pr({it:depvar}_en=1); marginal success probability for treatment equation{p_end}
{synopt :{opt pcond1}}Pr({it:depvar}=1 | {it:depvar}_en=1){p_end}
{synopt :{opt pcond2}}Pr({it:depvar}_en=1 | {it:depvar}=1){p_end}
{synopt :{opt xb1}}linear prediction for outcome equation {p_end}
{synopt :{opt xb2}}linear prediction for treatment equation {p_end}
{synopt :{opt stdp1}}standard error of the linear prediction for outcome equation{p_end}
{synopt :{opt stdp2}}standard error of the linear prediction for treatment equation{p_end}
{synoptline}
{p2colreset}{...}
INCLUDE help esample


{marker des_predict}{...}
{title:Description for predict}

{pstd}
{cmd:predict} creates a new variable containing predictions such as
probabilities, linear predictions, and standard errors.


{marker options_predict}{...}
{title:Options for predict}

{phang}
{opt p11}, the default, calculates the joint predicted probability
Pr({it:depvar}=1, {it:depvar}_en=1).

{phang}
{opt p10} calculates the joint predicted probability 
Pr({it:depvar}=1,{it:depvar}_en=0).

{phang}
{opt p01} calculates the joint predicted probability 
Pr({it:depvar}=0,{it:depvar}_en=1).

{phang}
{opt p00} calculates the joint predicted probability 
Pr({it:depvar}=0,{it:depvar}_en=0).

{phang}
{opt pmarg1} calculates the univariate (marginal) predicted probability
of success Pr({it:depvar}=1).

{phang}
{opt pmarg2} calculates the univariate (marginal) predicted probability
of success Pr({it:depvar}_en=1).

{phang}
{opt pcond1} calculates the conditional (on success in treatment equation)
predicted probability of success Pr({it:depvar}=1 | {it:depvar}_en=1).

{phang}
{opt pcond2} calculates the conditional (on success in outcome equation)
predicted probability of success Pr({it:depvar}_en=1 | {it:depvar}=1).

{phang}
{opt xb1} calculates the probit linear prediction for the outcome equation.

{phang}
{opt xb2} calculates the probit linear prediction for the treatment equation.

{phang}
{opt stdp1} calculates the standard error of the linear prediction of the outcome equation.

{phang}
	{opt stdp2} calculates the standard error of the linear prediction of the treatment equation.

{phang}
	{opt nooffset} is relevant only if you specified {opth offset(varname)} for the
	outcome equation and/or treatment equation for {cmd:rbiprobit}. It modifies the 
	calculations made by {opt predict} so that they ignore the offset variables; 
	the linear predictions are treated as {opt xb1} rather than as {opt xb1} + {it:offset1} 
	and {opt xb2} rather than as {opt xb2} + {it:offset2} 

{phang}
	{opt scores} calculates equation-level score variables.

{pmore}
	The first new variable will contain the derivative of the log likelihood with
	respect to the first regression equation.

{pmore}
	The second new variable will contain the derivative of the log likelihood with
	respect to the second regression equation.

{pmore}
	The third new variable will contain the derivative of the log likelihood with
	respect to the third equation ({hi:atanrho}).


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse class10}{p_end}
{phang2}{cmd:. rbiprobit graduate = income i.roommate i.hsgpagrp,}
		{cmd: endog(program = i.campus i.scholar income i.hsgpagrp)}{p_end}

{pstd}Predicted probability {cmd:graduate} = 1 and {cmd:program} = 1{p_end}
{phang2}{cmd:. predict prob11}{p_end}

{pstd}Predicted probability {cmd:graduate} = 1 and {cmd:program} = 0{p_end}
{phang2}{cmd:. predict prob10, p10}{p_end}

{pstd}Predicted probability {cmd:graduate} = 1 given {cmd:program} = 1{p_end}
{phang2}{cmd:. predict grad_given_prog, pcond1}{p_end}

{pstd}Test whether the coefficients of {cmd:income} are equal across equations{p_end}
{phang2}{cmd:. test [graduate=program]: income}{p_end}

{pstd}Test whether the coefficients on the highest category of {cmd:hsgpagrp} are 
		jointly 0 across equations{p_end}
{phang2}{cmd:. test [graduate]: 35.hsgpagrp = 0, notest}{p_end}
{phang2}{cmd:. test [program]: 35.hsgpagrp = 0, accumulate}{p_end}

{marker author}{...}
{title:Author}

{phang}Mustafa Coban{p_end}
{phang}Institute for Employment Research (Germany){p_end}

{p2col 5 20 29 2:email:}mustafa.coban@iab.de{p_end}
{p2col 5 20 29 2:github:}{browse "https://github.com/cobanomics":github.com/cobanomics}{p_end}
{p2col 5 20 29 2:webpage:}{browse "https://www.mustafacoban.de":mustafacoban.de}{p_end}


{marker also_see}{...}
{title:Also see}

{psee}
    Online: help for
    {helpb rbiprobit}
