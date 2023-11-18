{smcl}
{* *! version 1.0.0 12Oct2023}{...}

{title:Title}

{p2colset 5 16 17 2}{...}
{p2col:{hi:distill} {hline 2}} an analytical approach to assess heterogeneous treatment effects in randomized controlled trials {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:distill} {depvar} {ifin} 
{cmd:,} 
{cmdab:tr:eat(}{it:{helpb varname:varname}}{cmd:)}
{cmdab:ps:core(}{it:{helpb varname:varname}}{cmd:)}
[
{cmdab:nq:uantiles(#)}
{cmdab:le:vel(#)}
{opt fig:ure}[{cmd:(}{it:{helpb twoway_options:twoway_options}}{cmd:)}] 
{it:{helpb glm:glm_model_options}}
]



{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmdab:tr:eat(}{it:{helpb varname:varname}}{cmd:)}}{cmd:required} {opt treat()} must be binary and coded 0 for the control group and 1 for the treatment group{p_end}
{synopt:{cmdab:ps:core(}{it:{helpb varname:varname}}{cmd:)}}{cmd:required} The propensity score, indicating the probability of being in the treatment group{p_end}
{synopt:{cmdab:nq:uantiles(#)}}number of desired quantile categories of the propensity score; default is {cmd: 5}{p_end}
{synopt:{cmdab:le:vel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{cmdab:fig:ure}[({it:{helpb twoway_options}})]}produces a forest plot containing the model estimates for each strata. Specifying {opt figure} without options uses the default graph settings. {p_end}
{synopt:{it:glm_model_options}}allows all available {helpb glm:glm} options for the outcome model  {p_end}
{synoptline}
{p 4 6 2}
{opt by} is allowed with {cmd:distill}; see {manhelp by D}.{p_end}

{p 4 6 2}
{p2colreset}{...}				
	
{title:Description}

{pstd}
{cmd:distill} implements the "Distillation Method" (Adams et al. 2022) to estimate treatment effects within a desired number of strata (quantiles) 
of the propensity score to determine whether a randomized controlled trial (RCT) may have produced heterogeneous treatment effects. Adams et al. (2022)
found treatment effects in the higher strata, corresponding to subjects who were more likely to particate/engage in the intervention. 



{title:Remarks}

{pstd}
The "Distillation Method" capitalizes on the frequently observed correlation between the probability of subjects' participation or
engagement in the intervention and the magnitude of benefit they experience. The method involves three stages: first, it uses baseline 
covariates to generate predicted probabilities of participation. Next, these are used to produce nested subsamples of the randomized
intervention and control groups that are more concentrated with subjects who were likely to participate/engage. Finally, for the outcomes of interest, 
standard statistical methods are used to re-evaluate intervention effectiveness in these concentrated subsets (Adams et al. 2022).

{pstd}
{cmd:distill} performs the second and third stages of the "Distillation Method." The user performs the first stage (estimating the propensity score)
prior to implementing {cmd:distill} and then specifies the propensity score in {opt pscore()}. Next, {cmd:distill} performs the second stage by creating
propensity score strata (quantiles) as specified in {opt nquantiles()}. Finally, {cmd:distill} performs the third stage by estimating
treatment effects for each of those strata using {helpb glm:glm}. The user may choose from all available options in {helpb glm:glm} to adjust the 
specifications for the outcome model. 



{title:Options}

{p 4 8 2}
{cmd:treat}{cmd:(}{it:{helpb varname:varname}}{cmd:)} is a binary variable indicating the treatment status of each subject. {opt treat} must be coded 0 for the 
control group and 1 for the treatment group; {opt treat is required}.

{p 4 8 2}
{cmd:pscore}{cmd:(}{it:{helpb varname:varname}}{cmd:)} is the propensity score, indicating the probability of being in the treatment group; {opt pscore is required}.

{p 4 8 2}
{cmd:nquantiles(}{it:#}{cmd:)} desired number of quantile categories of the propensity score to be created. The variable created will be named "_xtile", and will be
replaced every time that {opt distill} is implemented; {opt The default is 5 quantiles}.  
		
{p 4 8 2}
{cmd:level(}{it:#}{cmd:)} specifies the confidence level, as a percentage, for confidence intervals. The default is {cmd:level(95)} or as set by {helpb set level:set level}.  
		
{p 4 8 2}
{cmd:figure}[{cmd:(}{it:{helpb twoway_options:twoway_options}}{cmd:)}] produces a forest plot containing the model estimates for each strata. 
Specifying {opt figure} without options uses the default graph settings. 

{p 4 8 2}
{cmd:{it:glm_model_options}} allows all available {helpb glm:glm} options for the outcome model.



{title:Examples}

{pstd}Setup{p_end}
{phang2}{bf:{stata "use distill_example.dta, clear":. use distill_example.dta, clear}}{p_end}

{pstd}
Estimate treatment effects for a binary outcome within 10 strata of the propensity score. We observe statistically significant effects in the highest strata (10).{p_end}
{phang2}{bf:{stata "distill y1, treat(treatment) pscore(_ps) nq(10) family(binomial) link(logit)":. distill y1, treat(treatment) pscore(_ps) nq(10) family(binomial) link(logit)}}{p_end}

{pstd}
Same as above but we specify "eform" to provide the results in exponentiated form, and request a figure.{p_end}
{phang2}{bf:{stata "distill y1, treat(treatment) pscore(_ps) nq(10) family(binomial) link(logit) eform fig":. distill y1, treat(treatment) pscore(_ps) nq(10) family(binomial) link(logit) eform fig}}{p_end}

{pstd}
In order to examine the effects in the 10th strata, we first rename the existing strata variable ("_xtile") and then rerun {opt distill} 
on only that strata (creating a new strata variable with only 5 quantiles). {p_end}
{phang2}{bf:{stata "rename _xtile orig_xtile":. rename _xtile orig_xtile}}{p_end}
{phang2}{bf:{stata "distill y1 if orig_xtile==10 , treat(treatment) pscore(_ps) nq(5) family(binomial) link(logit) eform fig":. distill y1 if orig_xtile==10 , treat(treatment) pscore(_ps) nq(5) family(binomial) link(logit) eform fig}}{p_end}

{pstd}
Estimate treatment effects for a count outcome within 10 strata of the propensity score.{p_end}
{phang2}{bf:{stata "distill y2 , treat(treatment) pscore(_ps) nq(10)  family(nbinomial) link(log) fig":. distill y2 , treat(treatment) pscore(_ps) nq(10) family(nbinomial) link(log) fig}}{p_end}

{pstd}
Same as above, but specify eform and a 99% confidence interval{p_end}
{phang2}{bf:{stata "distill y2 , treat(treatment) pscore(_ps) nq(10) family(nbinomial) link(log) fig eform level(99)":. distill y2 , treat(treatment) pscore(_ps) nq(10) family(nbinomial) link(log) fig eform level(99)}}{p_end}



{title:Stored results}

{pstd}
{cmd:distill} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(nq)}}number of quantiles of the propensity score{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}

{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}matrix containing the coefficients with their standard errors, test statistics, p-values, and confidence intervals
{p2colreset}{...}



{title:References}

{p 4 8 2}
Adams, J. L., Davis, A. C., Schneider, E. C., Hull, M. M. and E. A. McGlynn. (2022). The distillation method: 
A novel approach for analyzing randomized trials when exposure to the intervention is diluted. 
{it:Health Services Research} 57: 1361-1369. {p_end}



{marker citation}{title:Citation of {cmd:distill}}

{p 4 8 2}{cmd:distill} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, A. and J. L. Adams (2023). DISTILL: Stata module to assess heterogeneous treatment effects in randomized controlled trials {p_end}



{title:Authors}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}{browse "mailto:alinden@lindenconsulting.org":alinden@lindenconsulting.org}{p_end}

{p 4 8 2}	John L. Adams{p_end}
{p 4 8 2}	Center for Effectiveness and Safety Research, {p_end}
{p 4 8 2}	Kaiser Permanente, Pasadena, California, USA {p_end}


 
{title:Also see}

{p 4 8 2} Online: {helpb xtile}, {helpb glm} {p_end}

