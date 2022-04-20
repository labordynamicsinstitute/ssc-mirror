{smcl}
{* *! version 1.1.0: 18apr2022}{...}
{vieweralsosee "[R] margins" "mansection R margins"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] marginsplot" "help marginsplot"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] lincom" "help lincom"}{...}
{vieweralsosee "[R] nlcom" "help nlcom"}{...}
{vieweralsosee "[R] predict" "help predict"}{...}
{vieweralsosee "[R] predictnl" "help predictnl"}{...}
{viewerjumpto "Syntax" "rbiprobit margdec##syntax"}{...}
{viewerjumpto "Description" "rbiprobit margdec##description"}{...}
{viewerjumpto "Links to PDF documentation" "rbiprobit margdec##linkspdf"}{...}
{viewerjumpto "Options" "rbiprobit margdec##options"}{...}
{viewerjumpto "Stores Results" "rbiprobit margdec##results"}{...}
{viewerjumpto "Examples" "rbiprobit margdec##examples"}{...}
{hline}
{hi:help rbiprobit margdec}{right:{browse "https://github.com/cobanomics/rbiprobit":github.com/cobanomics/rbiprobit}}
{hline}
{right:also see:  {help rbiprobit postestimation}}

{title:Title}

{p2colset 5 26 26 2}{...}
{p2col: {cmd:rbiprobit margdec} {hline 2}}Marginal means, predictive margins, and marginal effects after {cmd:rbiprobit}
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:rbiprobit margdec} {ifin} [{it:{help rbiprobit margdec##weight:weight}}] [{cmd:,} 
	{it:{help rbiprobit margdec##response_options:response_options}}
	{it:{help rbiprobit margdec##options_table:options}}] 


{marker response_options}{...}
{synoptset 22 tabbed}{...}
{synopthdr:response_options}
{synoptline}
{syntab :Main}
{synopt:{opt eff:ect(effecttype)}}specify type of effect for margins;
	{it:effecttype} may be {cmd:total}, {cmd:direct}, or {cmd:indirect}; default is {cmd:total}
	{p_end}
{synopt:{opt pr:edict(pred_opt)}}estimate
	margins for {cmd:predict,} {it:pred_opt}{p_end}
{synopt:{opth dydx(varlist)}}estimate
	marginal effect of variables in {it:varlist}{p_end}
{synopt:{opth eyex(varlist)}}estimate
	elasticities of variables in {it:varlist}{p_end}
{synopt:{opth dyex(varlist)}}estimate
	semielasticity -- d({it:y})/d(ln{it:x}){p_end}
{synopt:{opth eydx(varlist)}}estimate
	semielasticity -- d(ln{it:y})/d({it:x}){p_end}
{synoptline}

{marker options_table}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:SE}
{synopt:{cmd:vce(delta)}}estimate SEs using delta method; the default{p_end}
{synopt:{cmd:vce(unconditional)}}estimate SEs allowing for sampling of covariates{p_end}

{syntab:Advanced}
{synopt:{opt noweight:s}}ignore weights specified in estimation{p_end}
{synopt:{opt noe:sample}}do not restrict {cmd:rbiprobit margdec} to the estimation sample{p_end}
{synopt :{opt force}}estimate margins despite potential problems{p_end}
	
{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt post}}post margins and their VCE as estimation results{p_end}
{synopt :{it:{help rbiprobit margdec##display_options:display_options}}}control
       columns and column formats, row spacing, line width, and
       factor-variable labeling
       {p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
	Time-series operators are allowed if they were used in the estimation.
	{p_end}
{marker weight}{...}
{p 4 6 2}
	{opt pweight}s, {opt fweight}s, and {opt iweight}s are allowed; see {help weight}.
	{p_end}
	
{marker description}{...}
{title:Description}

{pstd}
Margins are statistics calculated from predictions of a previously fit
model by {cmd:rbiprobit} at fixed values of some covariates and averaging or otherwise
integrating over the remaining covariates.

{pstd}
The {cmd:rbiprobit margdec} command estimates margins of responses for
specified values of independent variables in {it:indepvars} and {it:indepvars}_en and 
presents the results as a table.

{pstd}
Capabilities include estimated marginal means, least-squares means, average
and conditional marginal and partial effects (which may be reported as
derivatives or as elasticities), average and conditional adjusted
predictions, and predictive margins.

{pstd}
For estimation of margins of responses for specified values of the treatment 
variable {it:depvar}_en, please use {helpb rbiprobit tmeffects}. {cmd:rbiprobit margdec}
won't deliver results in this case.


{marker linkspdf}{...}
{title:Links to PDF documentation of Stata's {help margins} command}

        {mansection R marginsQuickstart:Quick start}

        {mansection R marginsRemarksandexamples:Remarks and examples}

        {mansection R marginsMethodsandformulas:Methods and formulas}

{pstd}
The above sections are not included in this help file.



{marker options}{...}
{title:Options}

{pstd}
{it:Warning:} {it:The option descriptions are brief and use jargon.} {it:Skip to} 
{bf:{mansection R marginsRemarksandexamples:Remarks and examples}} in {bf:[R] margins}
{it:if you are} {it:reading about} {cmd:margins}  {it:for the first time.}

{dlgtab:Main}

{phang}
	{opt effect(effecttype)} specifies the effecttype for the margins. Once independent
	variables are parts of {it:indepvars} and {it:indepvars}_en, marginal effects can be 
	splitted into a {it:direct} and an {it:indirect} marginal effect.

{phang2}
	{opt effect(total)}: {cmd:rbiprobit margdec} reports derivatives of the response with
	respect to {it:varlist} in {opth dydx(varlist)}, {opt eyex(varlist)}, 
	{opt dyex(varlist)}, or {opt eydx(varlist)}, considering the incorporation of {it:varlist}
	in {it:indepvars} and/or {it:indepvars}_en.
	
{phang2}
	{opt effect(direct)}: {cmd:rbiprobit margdec} reports derivatives of the response with
	respect to {it:varlist} from {opth dydx(varlist)}, {opt eyex(varlist)}, 
	{opt dyex(varlist)}, or {opt eydx(varlist)}, considering only the incorporation of 
	{it:varlist} in {it:indepvars} and not taking into account the appearance of 
	{it:varlist} in {it:indepvars}_en.

{phang2}
	{opt effect(indirect)}: {cmd:rbiprobit margdec} reports derivatives of the response with
	respect to {it:varlist} from {opth dydx(varlist)}, {opt eyex(varlist)}, 
	{opt dyex(varlist)}, or {opt eydx(varlist)}, considering only the incorporation of 
	{it:varlist} in {it:indepvars}_en and not taking into account the appearance of 
	{it:varlist} in {it:indepvars}.
	
{pmore}
	Differentiation between effectypes is not approriate for predictions {bf:pmarg1},
	{bf:pmarg2}, {bf:xb1} and {bf:xb2}. These predictions can't combined with
	{opt effect(direct)} or {opt effect(indirect)}.
	
{phang} 
	{opt predict(pred_opt)} specifies the response. If {cmd:predict()} is not specified, 
	the response will be the default prediction that would be produced by {cmd:predict} 
	after {cmd:rbiprobit}. {opt predict(pred_opt)} specifies the option to be specified 
	with the {cmd:predict} command to produce the variable that will be used as the
	response. For example, after estimation by {cmd:rbiprobit}, you could specify 
	{cmd:predict(pmarg1)} to obtain the marginal probability rather than the 
	{cmd:predict} command's default, the joint predicted probability {cmd:p11}.

{pmore}
    In contrast to {cmd:margins} command, multiple {opt predict()} options are not 
	allowed with {cmd:rbiprobit margdec}.

{phang}
	{opth dydx(varlist)}, {opt eyex(varlist)}, {opt dyex(varlist)}, and {opt eydx(varlist)} 
	request that {cmd:rbiprobit margdec} report derivatives of the response with respect 
	to {it:varlist} rather than on the response itself. {cmd:eyex()}, {cmd:dyex()}, and 
	{cmd:eydx()} report derivatives as elasticities; see 
	{it:{mansection R marginsRemarksandexamplesExpressingderivativesaselasticities:Expressing derivatives as elasticities}} in {manlink R margins}.

{pmore}
    In contrast to {cmd:margins} command, multiple {opt dydx()}, {opt eyex()}, {opt dyex()}, 
	or {opt eydx()} options are not  allowed with {cmd:rbiprobit margdec}.

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
	{opt noesample} specifies that {cmd:rbiprobit margdec} not restrict its computations to the
    estimation sample used by the previous estimation command. See 
	{it:{mansection R marginsRemarksandexamplesExample15Marginsevaluatedoutofsample:Example 15: Margins evaluated out of sample}} in {manlink R margins}.

{pmore}
    With the default delta-method VCE, {opt noesample} margins may
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
	{opt force} instructs {cmd:rbiprobit margdec} to proceed in some situations where it would
    otherwise issue an error message because of apparent violations of
    assumptions.  Do not be casual about specifying {cmd:force}. You need to
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
	causes {cmd:rbiprobit margdec} to behave like a Stata estimation (e-class) command.
	{cmd:rbiprobit margdec} posts the vector of estimated margins along with the
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

{pstd}Compute total, direct, and indirect average marginal effects of {cmd:income} 
		on the joint probability Pr({it:depvar}=1, {it:depvar}_en=1){p_end}
{phang2}{cmd:. rbiprobit margdec, dydx(income) predict(p11) effect(total)}{p_end}
{phang2}{cmd:. rbiprobit margdec, dydx(income) predict(p11) effect(direct)}{p_end}
{phang2}{cmd:. rbiprobit margdec, dydx(income) predict(p11) effect(indirect)}{p_end}

{pstd}Compute indirect average marginal effects of {it:all} independent variables 
		on the joint probability Pr({it:depvar}=1, {it:depvar}_en=0) and plot the results{p_end}
{phang2}{cmd:. rbiprobit margdec, dydx(*) predict(p10) effect(direct)}{p_end}
{phang2}{cmd:. marginsplot}{p_end}

{pstd}Compute average marginal effects of {cmd:hsgpagrp} on the marginal probabilities{p_end}
{phang2}{cmd:. rbiprobit margdec, dydx(hsgpagrp) predict(pmarg1)}{p_end}
{phang2}{cmd:. rbiprobit margdec, dydx(hsgpagrp) predict(pmarg2)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:rbiprobit margdec} stores the following in {cmd:r()}:

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
{synopt:{cmd:r(title)}}title in output{p_end}
{synopt:{cmd:r(model_vce)}}{it:vcetype} from estimation command{p_end}
{synopt:{cmd:r(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:r(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:r(predict}{it:#}{cmd:_opts)}}the {it:#}th {cmd:predict()} option{p_end}
{synopt:{cmd:r(predict}{it:#}{cmd:_label)}}label from the {it:#}th {cmd:predict()} option{p_end}
{synopt:{cmd:r(expression)}}response expression{p_end}
{synopt:{cmd:r(xvars)}}{it:varlist} from {cmd:dydx()}, {cmd:dyex()},
					{cmd:eydx()}, or {cmd:eyex()}{p_end}
{synopt:{cmd:r(derivatives)}}"", "dy/dx", "dy/ex", "ey/dx", "ey/ex"{p_end}
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
{cmd:rbiprobit margdec} with the {cmd:post} option also stores the following in {cmd:e()}:

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
{synopt:{cmd:e(est_cmdline)}}{cmd:e(cmdline)}
	from original estimation results{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(model_vce)}}{it:vcetype} from estimation command{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}, or just {cmd:b} if {cmd:nose} is specified{p_end}
{synopt:{cmd:e(predict}{it:#}{cmd:_opts)}}the {it:#}th {cmd:predict()} option{p_end}
{synopt:{cmd:e(predict}{it:#}{cmd:_label)}}label from the {it:#}th {cmd:predict()} option{p_end}
{synopt:{cmd:e(expression)}}prediction expression{p_end}
{synopt:{cmd:e(xvars)}}{it:varlist} from {cmd:dydx()}, {cmd:dyex()},
					{cmd:eydx()}, or {cmd:eyex()}{p_end}
{synopt:{cmd:e(derivatives)}}"", "dy/dx", "dy/ex", "ey/dx", "ey/ex"{p_end}
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
