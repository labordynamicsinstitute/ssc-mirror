{smcl}
{* *! version 1.1.1}{...}
{title:Title}

{phang}
{bf:robustate} {hline 2} Executes estimation and inference for the average treatment effect (ATE) robustly against the limited overlap.

{marker syntax}{...}
{title:Syntax}

{p 4 17 2}
{cmd:robustate}
{it:outcome}
{it:treatment}
{it:controls}
{ifin}
[{cmd:,} {bf:probit} {bf:h}({it:real}) {bf:k}({it:real})]

{marker description}{...}
{title:Description}

{phang}
{cmd:robustate} executes estimation and inference for the average treatment effect (ATE) robustly against the limited overlap based on
{browse "https://www.cambridge.org/core/journals/econometric-theory/article/abs/estimation-and-inference-for-moments-of-ratios-with-robustness-against-large-trimming-bias/6505FD01751EE01FEFFD34071C873FB6":Sasaki and Ura (2022)} -- Section 7. 
Under the limited overlap, the naive inverse propensity score estimation method suffers from large variances (if not a lack of the consistency or the asymptotic normality).
Hence, it is a common practice to trim observations whose propensity scores are close to 0 or 1, but such a practice biases the estimator of the ATE.
This command, {cmd:robustate}, corrects the bias from the trimming and computes a valid standard error accounting for the bias correction.
The command accepts an outcome variable, a binary treatment variable, and a list of control variables.
It returns both the naive inverse propensity score weighted estimate and the robust inverse propensity score weighted estimate.
The robust estimator in general yields a smaller standard error than the naive estimator.

{marker options}{...}
{title:Options}

{phang}
{bf:probit} sets an indicator for the method of estimating the propensity score. Not calling this option leads to the logit propensity score estimation by default. 
Calling this option leads to the probit propensity score estimation.

{phang}
{bf:h({it:real})} sets the trimming threshold. The default value is {bf: h(0.1)}. It has to be a real number in (0,1). Larger values induce larger biases of the naive estimator.

{phang}
{bf:k({it:real})} sets the sieve dimension for bias correction. The default value is {bf: k(4)}. It has to be an integer which is no smaller than 4.

{marker example}{...}
{title:Example}

{phang}
Average treatment effect of catheterization on 30-day survival.
{p_end}

{phang}{cmd:. use "catheterization_small.dta"}{p_end}
{phang}{cmd:. robustate outcome treat {it:controls}}{p_end}

{phang}where the {cmd:{it:controls}} in the last command line above include: 
{bf:age}, 
{bf:alb1}, 
{bf:amihx}, 
{bf:aps1}, 
{bf:bili1}, 
{bf:ca_meta}, 
{bf:ca_yes}, 
{bf:card}, 
{bf:cardiohx}, 
{bf:cat1_chf}, 
{bf:cat1_cirr}, 
{bf:cat1_colon}, 
{bf:cat1_coma}, 
{bf:cat1_copd}, 
{bf:cat1_lung}, 
{bf:cat1_mosfmal}, 
{bf:cat1_mosfsep}, 
{bf:cat2_cirr}, 
{bf:cat2_colon}, 
{bf:cat2_coma}, 
{bf:cat2_lung}, 
{bf:cat2_mosfmal}, 
{bf:cat2_mosfsep}, 
{bf:chfhx}, 
{bf:chrpulhx}, 
{bf:crea1}, 
{bf:das2d3pc}, and 
{bf:dementhx}.{p_end}

{marker stored}{...}
{title:Stored results}

{phang}
{bf:robustate} stores the following in {bf:e()}: 
{p_end}

{phang}
Scalars
{p_end}
{phang2}
{bf:e(N)} {space 10}observations
{p_end}
{phang2}
{bf:e(h)} {space 10}trimming threshold
{p_end}
{phang2}
{bf:e(k)} {space 10}order of orthonormal basis
{p_end}

{phang}
Macros
{p_end}
{phang2}
{bf:e(pscore)} {space 5}{bf:logit} or {bf:probit}
{p_end}
{phang2}
{bf:e(cmd)} {space 8}{bf:robustate}
{p_end}
{phang2}
{bf:e(properties)} {space 1}{bf:b V}
{p_end}

{phang}
Matrices
{p_end}
{phang2}
{bf:e(b)} {space 10}coefficient vector
{p_end}
{phang2}
{bf:e(V)} {space 10}variance-covariance matrix of the estimators
{p_end}

{phang}
Functions
{p_end}
{phang2}
{bf:e(sample)} {space 5}marks estimation sample
{p_end}

{title:Reference}

{p 4 8}Sasaki, Y. and T. Ura 2022. Estimation and Inference for Moments of Ratios with Robustness against Large Trimming Bias. {it:Econometric Theory}, 38 (1), pp. 66-112.
{browse "https://www.cambridge.org/core/journals/econometric-theory/article/abs/estimation-and-inference-for-moments-of-ratios-with-robustness-against-large-trimming-bias/6505FD01751EE01FEFFD34071C873FB6":Link to Paper}.
{p_end}

{title:Authors}

{p 4 8}Yuya Sasaki, Vanderbilt University, Nashville, TN.{p_end}

{p 4 8}Takuya Ura, University of California, Davis, CA.{p_end}



