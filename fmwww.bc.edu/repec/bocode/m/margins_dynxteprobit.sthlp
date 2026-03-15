{smcl}
{* *! version 1.0.0  march2026}{...}
{vieweralsosee "[R] xteprobit" "help xteprobit"}{...}
{vieweralsosee "[R] margins" "help margins"}{...}
{viewerjumpto "Syntax" "margins_dynxteprobit##syntax"}{...}
{viewerjumpto "Description" "margins_dynxteprobit##description"}{...}
{viewerjumpto "Options" "margins_dynxteprobit##options"}{...}
{viewerjumpto "Stored results" "margins_dynxteprobit##results"}{...}
{viewerjumpto "Examples" "margins_dynxteprobit##examples"}{...}
{viewerjumpto "Author" "margins_dynxteprobit##author"}{...}
{viewerjumpto "References" "margins_dynxteprobit##references"}{...}
{title:Title}

{phang}
{* phang is short for p 4 8 2}
{bf:margins_dynxteprobit} {hline 2}  Marginal effects for a dynamic xteprobit with attrition.


{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:margins_dynxteprobit}
{ifin}
{cmd:,}
[{it:options}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{bf:dydx(}{it:{help varname:var}}{bf:)}}estimates continuous marginal effect of variable in {it:var}{p_end}

{p2col:{bf:diff(}{it:{help varname:var}}{bf: = } {it:num1 num2}{bf:)}}estimates marginal effect of discrete variable in {it:var} from {it:num1} to {it:num2}{p_end}

{p2col:{bf:at(}{it:{help atlist:atlist}}{bf:)}}estimates marginal effects at specified values of the covariates*{p_end}

{syntab:Reporting}
{p2col:{bf:post}}post margins and their VCE as estimation results{p_end}

{synoptline}
{pstd} *{it:{help atlist:atlist}} can only specify at most one value for each specified covariate.


{marker description}{...}
{title:Description}

{pstd}
{cmd:margins_dynxteprobit} is a post-estimation command that produces marginal effects estimates following a dynamic xteprobit model with endogenous attrition as proposed and studied by Carlson and Semykina (2026). It fits regression models with selection by using Heckman's two-step consistent estimator.

{pstd}
In using the {helpb xteprobit} command for a dynamic xteprobit model with endogenous attrition, estimation occurs on a subset of the data, the time periods that are observed and only the first time period of attrition. The {helpb margins} command is confined to compute marginal effects on this subset sample. The {cmd:margins_dynxteprobit} command computes unconditional marginal effects (not conditional on non-attrition) averaged over the entire sample. 

{pstd}
The default is calculating marginal effects with respect to the binary lagged dependent variable in the dynamic model. Other capabilities include estimating marginal effects of other continuous variables (evaluated at fixed values of the lagged binary dependent variable); estimating marginal effects of discrete variables as specified differences (evaluated at fixed values of the lagged biinary dependent variable); and estimating marginal effects at specified values of the covariates. 

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt dydx(var)} requests that the marginal effects be computed as a derivative with respect to {it:var} rather than the lagged dependent variable. Marginal effects are evaluated for the lagged dependent variable equal to 0 and 1. At most, either {bf:dydx()} or {bf:diff()} option may be specified but not both. 

{phang}
{opt diff(var = (num1 num2))} requests that the marginal effects be computed as a difference with respect to {it:var} from {it:num1} to {it:num2} rather than the lagged dependent variable. Marginal effects are evaluated for the lagged dependent variable equal to 0 and 1. At most, either {bf:dydx()} or {bf:diff()} option may be specified but not both. 

{phang}
{opt at(atlist)} specifies values for covariates to be treated as fixed. By default, margins are calculated by averaging over observed values of covariates. 

{phang2}
{opt at(age = 20)} fixes covariate {bf:age} to the value specified. 

{phang2}
{opt at(age = 20 sex = 1)} fixes covariate {bf:age} and {bf:sex} to the values specified. 

{phang2} 
Current version of the command can only accomodate a single specified value for each covariate (not a {help numlist:numlist}).

{dlgtab:Reporting}

{phang}
{opt post} causes {cmd:margins_dynxteprobit} to behave like a Stata estimation (e-class) command. {cmd:margins_dynxteprobit} posts the  vector of estimated margins along with the estimated variance-covariance matrix to {bf:e()}, so you can treat the estimated margins just as you would results from any other estimation command.  For example, you could use {cmd:test} to perform simultaneous tests of hypotheses on the margins, or you could use {cmd:lincom} to create linear combinations. 

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse womenhlthre, clear}{p_end}
{phang2}{cmd:. xtset personid year}{p_end}
{phang2}{cmd:. bysort personid: replace select = 0 if select[_n-1] == 0} // Generates selection indicator as attrition so the first time an individual is unobserved for a time period, they leave the sample.{p_end}
{phang2}{cmd:. generate goodhlth = health>3 if select == 1} // Generate the outcome variable with attrition.{p_end}
{phang2}{cmd:. bysort personid: generate attrit = select[_n-1] != 0} // Generate an attrition indicator that is a binary variable equal to 1 if the outcome is observed or it is the first instance of attrition.{p_end}


{pstd}Obtain marginal effects estimates when restricted to the attrition sample using {cmd:margins} command. (Note: {cmd:xteprobit} is more likely to converge when extra data is dropped rather than using {bf:if} condition.){p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. keep if attrit == 1}{p_end}
{phang2}{cmd:. xteprobit goodhlth l.i.goodhlth exercise grade, select(select = exercise grade regcheck)}{p_end}
{phang2}{cmd:. margins, dydx(1L.goodhlth)}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}Obtain marginal effects with respect to lagged dependent variable over the entire sample. Note that the lagged dependent variable must be specified with factor notation (l.i.{it:dependvar}) and must be listed as first independent variable in the preceding {cmd:xteprobit} command. {p_end}
{phang2}{cmd:. margins_dynxteprobit}{p_end}

{pstd}Obtain marginal effects estimates when restricted to the attrition sample using {cmd:margins_dynxteprobit} command.{p_end}
{phang2}{cmd:. margins_dynxteprobit if attrit == 1}{p_end}

{pstd}Obtain marginal effects with respsect to continuous covariate.{p_end}
{phang2}{cmd:. margins_dynxteprobit, dydx(grade)}{p_end}

{pstd}Obtain marginal effects with respect to discrete covariate from one value in the support to another.{p_end}
{phang2}{cmd:. margins_dynxteprobit, diff(exercise = (0 1))}{p_end}

{pstd}Obtain marginal effects with respect to lagged dependent variable at specific covariate values.{p_end}
{phang2}{cmd:. margins_dynxteprobit, at(exercise = 0 grade = 12)}{p_end}

{pstd}Obtain marginal effects with estimates stored in {bf:e()}, then testing with the estimates.{p_end}
{phang2}{cmd:. margins_dynxteprobit, dydx(grade) post}{p_end}
{phang2}{cmd:. test 1._at = 2._at}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:margins_dynxteprobit} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:margins_dynxteprobit}{p_end}
{synopt:{cmd:e(estimator)}}{cmd:xteprobit}{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}estimates{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimates{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}

{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}
Alyssa H. Carlson{break}Department of Economics, University of Missouri{break}
carlsonah@missouri.edu{break}{browse "https://carlsonah.mufaculty.umsystem.edu/"}

{marker references}
{title:References}

{phang}
Carlson, A. H., and Semykina, A. 2026.
Addressing Attrition in Nonlinear Dynamic Panel Data Models with an Application to Health. 
Working Paper. 
URL: {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5190611"}

