{smcl}
{* *! version 1.1.0: 18apr2022}{...}
{vieweralsosee "[R] margins" "mansection R margins"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] marginsplot" "help marginsplot"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] predict" "help predict"}{...}
{viewerjumpto "Syntax" "rbiprobit tmeffects##syntax"}{...}
{viewerjumpto "Description" "rbiprobit tmeffects##description"}{...}
{viewerjumpto "Options" "rbiprobit tmeffects##options"}{...}
{viewerjumpto "Stores Results" "rbiprobit tmeffects##results"}{...}
{viewerjumpto "Examples" "rbiprobit tmeffects##examples"}{...}
{hline}
{hi:help rbiprobit tmeffects}{right:{browse "https://github.com/cobanomics/rbiprobit":github.com/cobanomics/rbiprobit}}
{hline}
{right:also see:  {help rbiprobit postestimation}}

{title:Title}

{p2colset 5 28 28 2}{...}
{p2col: {cmd:rbiprobit tmeffects} {hline 2}}Estimation of treatment effects of treatment variable {it:depvar_en} after {cmd:rbiprobit}
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:rbiprobit tmeffects} {ifin} [{it:{help rbiprobit tmeffects##weight:weight}}] [{cmd:,}
	{it:{help rbiprobit tmeffects##options_table:options}}] 


{marker options_table}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt tmeff:ect(effecttype)}}specify type of treatment effect;
	{it:effecttype} may be {cmd:ate}, {cmd:atet}, or {cmd:atec}; default is {cmd:ate}
	{p_end}
{syntab:SE}
{synopt:{cmd:vce(delta)}}estimate SEs using delta method; the default{p_end}
{synopt:{cmd:vce(unconditional)}}estimate SEs allowing for sampling of covariates{p_end}

{syntab:Advanced}
{synopt:{opt noweight:s}}ignore weights specified in estimation{p_end}
{synopt:{opt noe:sample}}do not restrict {cmd:rbiprobit tmeffects} to the estimation sample{p_end}
{synopt :{opt force}}estimate treatment effects despite potential problems{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt post}}post margins and their VCE as estimation results{p_end}
{synopt :{it:{help rbiprobit tmeffects##display_options:display_options}}}control
       columns and column formats, row spacing, line width, and
       factor-variable labeling
       {p_end}
{synoptline}
{p2colreset}{...}

{marker weight}{...}
{p 4 6 2}
	{opt pweight}s, {opt fweight}s, and {opt iweight}s are allowed; see {help weight}.
	{p_end}
	
{marker description}{...}
{title:Description}

{pstd}
{cmd: rbiprobit tmeffects} estimates the average treatment effect, average treatment
effect on the treated, and the average treatment effect on the conditional probability.



{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
	{opt tmeffect(effecttype)} specifies the type of the treatment effect of the
	treatment variable {it:depvar}_en on a specific response.

{phang2}
	{opt tmeffect(ate)}: {cmd:rbiprobit tmeffects} reports the average treatment effect,
	i.e. the finite difference between Pr({it:depvar}=1) given {it:depvar_en}=1 and 
	Pr({it:depvar}=1) given {it:depvar_en}=0. Thus, {it:ate} is the difference between the
	marginal probability of outcome success given treatment success and the marginal 
	probability of outcome success given treatment failure.
	
{phang2}
	{opt tmeffect(atet)}: {cmd:rbiprobit tmeffects} reports the average treatment effect
	on the treated, i.e. the finite difference between normal({it:depvar=1}|{it:depvar}_en=1)
	and normal({it:depvar=1}|{it:depvar}_en=0), computed and averaged only for the treated 
	observations. Thus, {it:atet} is the difference between the marginal probability of
	outcome success conditioned on treatment success and the marginal probability of
	outcome success conditioned on treatment failure.

{phang2}
	{opt tmeffect(atec)}: {cmd:rbiprobit tmeffects} reports the average treatment effect
	on the conditional probability, i.e. the finite difference between 
	Pr({it:depvar}=1|{it:depvar}_en=1) and Pr({it:depvar}=1|{it:depvar}_en=0). Thus,
	{it:atec} is the difference between the conditional (on treatment success) 
	probability of outcome success and the conditional (on treatment failure) 
	probability of outcome success.

{pmore}
    Multiple {opt tmeffect()} options are not allowed with {cmd:rbiprobit tmeffects}.

{dlgtab:SE}

{phang}
	{cmd:vce(delta)} and {cmd:vce(unconditional)} specify how the VCE and, correspondingly, 
	standard errors are calculated.

{phang2}
    {cmd:vce(delta)} is the default.  The delta method is applied to the formula 
	for the response and the VCE of the estimation command. This method assumes that 
	values of the covariates used to calculate the response are 
    given or that the data are given.

{phang2}
    {cmd:vce(unconditional)} specifies that the covariates that are not fixed
    be treated in a way that accounts for their having been sampled.  The VCE
    is estimated using the linearization method.  This method allows for
    heteroskedasticity or other violations of distributional assumptions and 
    allows for correlation among the observations in the same  manner as 
    {cmd:vce(robust)} and {cmd:vce(cluster }{it:...}{cmd:)}, which
    may have been specified with {cmd:rbiprobit}.
	
{pmore2}
	{cmd:tmeffect(atet)} and {cmd:vce(unconditional)} are mutually exclusive
	because the sample of treated observations used for estimation of the {opt atet} 
	differs from the original estimation sample. Using both options at
	the same time will give an error message. If you still want to estimate the {opt atet}
	you have to add {cmd:noesample}, but if you do, you should be sure that the data in 
	memory correspond to the original {cmd:e(sample)}. To show that you understand that, 
    you must also specify the {cmd:force} option.  Be aware that making 
    the {cmd:vce(unconditional)} calculation on a sample different from 
    the estimation sample would be equivalent to 
    estimating the coefficients on one set of data and computing the scores
    used by the linearization on another set; see {manlink P _robust}.
	
{dlgtab:Advanced}

{phang}
	{opt noweights} specifies that any weights specified on the previous estimation command 
	be ignored by {opt rbiprobit margdec}.  By default, {opt rbiprobit margdec} uses the 
	weights specified in {opt rbiprobit} to average responses and to compute summary
	statistics.  If weights are specified on the {opt rbiprobit margdec} command, 
	they override previously specified weights, making it unnecessary to specify {opt noweights}.  
	The {opt noweights} option is not allowed after {opt svy:} estimation when the 
	{cmd: vce(unconditional)} option is specified.
	
{phang}
	{opt noesample} specifies that {cmd:rbiprobit tmeffects} not restrict its computations to the
    estimation sample used by the previous estimation command. See 
	{it:{mansection R marginsRemarksandexamplesExample15Marginsevaluatedoutofsample:Example 15: Margins evaluated out of sample}} in {manlink R margins}.

{pmore}
    With the default delta-method VCE, {opt noesample} treatment effects may
    be estimated on samples other
    than the estimation sample; such results are valid under the
    assumption that the data used are treated as being given.

{pmore}
    You can specify {cmd:noesample} and {cmd:vce(unconditional)} together, but
    if you do, you should be sure that the data in memory correspond
    to the original {cmd:e(sample)}. To show that you understand that, 
    you must also specify the {cmd:force} option. Be aware that making 
    the {cmd:vce(unconditional)} calculation on a sample different from 
    the estimation sample would be equivalent to 
    estimating the coefficients on one set of data and computing the scores
    used by the linearization on another set; see {manlink P _robust}.
	
{phang} 
	{opt force} instructs {cmd:rbiprobit tmeffects} to proceed in some situations where it would
    otherwise issue an error message because of apparent violations of
    assumptions. Do not be casual about specifying {cmd:force}. You need to
    understand and fully evaluate the statistical issues. For an example
    of the use of {cmd:force}, see 
	{it:{mansection R marginsRemarksandexamplesUsingmarginsaftertheestimatesusecommand:Using margins after the estimates use command}} in {manlink R margins}.

	
{dlgtab:Reporting}

{phang}
	{opt level(#)}
	specifies the confidence level, as a percentage, for confidence intervals.
	The default is {cmd:level(95)} or as set by {helpb set level}.

{phang} 
	{opt post} 
	causes {cmd:rbiprobit tmeffects} to behave like a Stata estimation (e-class) command.
	{cmd:rbiprobit tmeffects} posts the vector of estimated margins along with the
	estimated variance-covariance matrix to {cmd:e()}, so you can treat the
	estimated margins just as you would results from any other estimation
	command.  For example, you could use {cmd:test} to perform simultaneous tests
	of hypotheses on the margins, or you could use {cmd:lincom} to create linear
	combinations.  See
	{it:{mansection R marginsRemarksandexamplesExample10Testingmargins---contrastsofmargins:Example 10: Testing margins -- contrasts of margins}} in {manlink R margins}.

{marker display_options}{...}
{phang}
{it:display_options}:
{opt noci},
{opt nopv:alues},
{opt vsquish},
{opt nofvlab:el},
{opt fvwrap(#)},
{opt fvwrapon(style)},
{opth cformat(%fmt)},
{opt pformat(%fmt)},
{opt sformat(%fmt)}, and
{opt nolstretch}.

{phang2}
{opt noci} 
suppresses confidence intervals from being reported in the coefficient table.

{phang2}
{opt nopvalues}
suppresses p-values and their test statistics from being reported in the
coefficient table.

{phang2}
{opt vsquish} 
specifies that the blank space separating factor-variable terms or
time-series-operated variables from other variables in the model be suppressed.

{phang2}
{opt nofvlabel} displays factor-variable level values rather than attached value
labels.  This option overrides the {cmd:fvlabel} setting; see 
{helpb set showbaselevels:[R] set showbaselevels}.

{phang2}
{opt fvwrap(#)} allows long value labels to wrap the first {it:#}
lines in the coefficient table.  This option overrides the
{cmd:fvwrap} setting; see {helpb set showbaselevels:[R] set showbaselevels}.

{phang2}
{opt fvwrapon(style)} specifies whether value labels that wrap will break
at word boundaries or break based on available space.

{phang3}
{cmd:fvwrapon(word)}, the default, specifies that value labels break at
word boundaries.

{phang3}
{cmd:fvwrapon(width)} specifies that value labels break based on available
space.

{pmore2}
This option overrides the {cmd:fvwrapon} setting; see
{helpb set showbaselevels:[R] set showbaselevels}.

{phang2}
{opt cformat(%fmt)} specifies how to format margins, standard errors, and
confidence limits in the table of estimated margins.

{phang2}
{opt pformat(%fmt)} specifies how to format p-values in the table of estimated margins.

{phang2}
{opt sformat(%fmt)} specifies how to format test statistics in the 
table of estimated margins.

{phang2}
{opt nolstretch} specifies that the width of the table of estimated margins
not be automatically widened to accommodate longer variable names. The default,
{cmd:lstretch}, is to automatically widen the table of estimated margins up to
the width of the Results window.  To change the default, use
{helpb lstretch:set lstretch off}.  {opt nolstretch} is not shown in the dialog
box.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse class10}{p_end}
{phang2}{cmd:. rbiprobit graduate = income i.roommate i.hsgpagrp,}
		{cmd: endog(program = i.campus i.scholar income i.hsgpagrp)}{p_end}

{pstd}Compute average treatment effects of {cmd:program}{p_end}
{phang2}{cmd:. rbiprobit tmeffects, tmeffect(ate)}{p_end}

{pstd}Compute average treatment effects on the treated of {cmd:program}{p_end}
{phang2}{cmd:. rbiprobit tmeffects, tmeffect(atet)}{p_end}

{pstd}Compute average treatment effects on the conditional probability of {cmd:program}{p_end}
{phang2}{cmd:. rbiprobit tmeffects, tmeffect(atec)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:rbiprobit tmeffects} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(k_predict)}}number of {opt predict()} options{p_end}
{synopt:{cmd:r(k_margins)}}number of terms in {it:marginlist}{p_end}
{synopt:{cmd:r(k_by)}}number of subpopulations{p_end}
{synopt:{cmd:r(k_at)}}number of {opt at()} options{p_end}
{synopt:{cmd:r(level)}}confidence level of confidence intervals{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:margins}{p_end}
{synopt:{cmd:r(cmdline)}}command as typed{p_end}
{synopt:{cmd:r(est_cmd)}}{cmd:e(cmd)} from original estimation results{p_end}
{synopt:{cmd:r(est_cmdline)}}{cmd:e(cmdline)} from original estimation results{p_end}
{synopt:{cmd:r(title)}}Treatment Effects{p_end}
{synopt:{cmd:r(model_vce)}}{it:vcetype} from estimation command{p_end}
{synopt:{cmd:r(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:r(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:r(predict}{it:#}{cmd:_opts)}}the {it:#}th {cmd:predict()} option{p_end}
{synopt:{cmd:r(predict}{it:#}{cmd:_label)}}label from the {it:#}th {cmd:predict()} option{p_end}
{synopt:{cmd:r(expression)}}response expression{p_end}
{synopt:{cmd:r(xvars)}}{it:effectype} from {cmd:tmeffect()}{p_end}
{synopt:{cmd:r(derivatives)}}"dy/dx"{p_end}
{synopt:{cmd:r(emptycells)}}{it:empspec} from {cmd:emptycells()}{p_end}
{synopt:{cmd:r(mcmethod)}}{it:method} from {opt mcompare()}{p_end}

{p2col 5 20 24 2:Matrices}{p_end}
{synopt:{cmd:r(b)}}estimates{p_end}
{synopt:{cmd:r(V)}}variance-covariance matrix of the estimates{p_end}
{synopt:{cmd:r(Jacobian)}}Jacobian matrix{p_end}
{synopt:{cmd:r(_N)}}sample size corresponding to each margin estimate{p_end}
{synopt:{cmd:r(chainrule)}}chain rule information from the fitted model{p_end}
{synopt:{cmd:r(error)}}margin estimability codes;{break}
        {cmd:0} means estimable,{break}
        {cmd:8} means not estimable{p_end}
{synopt:{cmd:r(table)}}matrix
        containing the margins with their standard errors, test statistics,
        p-values, and confidence intervals{p_end}
{p2colreset}{...}


{pstd}
{cmd:rbiprobit tmeffects} with the {cmd:post} option also stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k_predict)}}number of {opt predict()} options{p_end}
{synopt:{cmd:e(k_margins)}}number of terms in {it:marginlist}{p_end}
{synopt:{cmd:e(k_by)}}number of subpopulations{p_end}
{synopt:{cmd:e(k_at)}}number of {opt at()} options{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:margins}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(est_cmd)}}{cmd:e(cmd)} from original estimation results{p_end}
{synopt:{cmd:e(est_cmdline)}}{cmd:e(cmdline)} from original estimation results{p_end}
{synopt:{cmd:e(title)}}Treatment Effects{p_end}
{synopt:{cmd:e(model_vce)}}{it:vcetype} from estimation command{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}, or just {cmd:b} if {cmd:nose} is specified{p_end}
{synopt:{cmd:e(predict}{it:#}{cmd:_opts)}}the {it:#}th {cmd:predict()} option{p_end}
{synopt:{cmd:e(predict}{it:#}{cmd:_label)}}label from the {it:#}th {cmd:predict()} option{p_end}
{synopt:{cmd:e(expression)}}prediction expression{p_end}
{synopt:{cmd:e(xvars)}}{it:effectype} from {cmd:tmeffect()}{p_end}
{synopt:{cmd:e(derivatives)}}"dy/dx"{p_end}
{synopt:{cmd:e(emptycells)}}{it:empspec} from {cmd:emptycells()}{p_end}

{p2col 5 20 24 2:Matrices}{p_end}
{synopt:{cmd:e(b)}}estimates{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimates{p_end}
{synopt:{cmd:e(Jacobian)}}Jacobian matrix{p_end}
{synopt:{cmd:e(_N)}}sample size corresponding to each margin estimate{p_end}
{synopt:{cmd:e(error)}}error code corresponding to {cmd:e(b)}{p_end}
{synopt:{cmd:e(chainrule)}}chain rule information from the fitted model{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

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
    {helpb rbiprobit}, {helpb rbiprobit postestimation}, {helpb margins}
