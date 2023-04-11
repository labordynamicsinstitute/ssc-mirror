{smcl}
{* *! version 1.1.1}{...}
{title:Title}

{phang}
{bf:ecic} {hline 2} Executes estimation and inference for changes in changes at extreme quantiles.


{marker syntax}{...}
{title:Syntax}

{p 4 17 2}
{cmd:ecic}
{it:Y}
{it:G}
{it:T}
{ifin}
[{cmd:,} {bf:q}({it:real})]


{marker description}{...}
{title:Description}

{phang}
{cmd:ecic} estimates quantile treatment effects (QTE) at extreme quantiles via changes in changes (CIC) based on
{browse "https://doi.org/10.48550/arXiv.2211.14870":Sasaki and Wang (2022)}.
The designed setting requires that all the units are untreated in the first period ({cmd:T}=0), 
all the units in the control group ({cmd:G=0}) remain untreated in the second period ({cmd:T}=1), and
all the units in the treatment group ({cmd:G=1}) receive treatments in the second period ({cmd:T}=1).
The command assumes repeated cross sections.

{phang}
To accommodate covariates, one can run preliminary regression of the outcome {it:Y} on covariates {it:X}.
Replace {it:Y} by the residuals in the {cmd:ecic} command.
This residualized procedure is theoretically supported by
{browse "https://doi.org/10.48550/arXiv.2211.14870":Sasaki and Wang (2022; Sec. 6)}.


{marker options}{...}
{title:Option}

{phang}
{bf:q({it:real})} sets the quantile value. As an extremal quantile, it is natural to be set either below 0.05 or above 0.95. (A warning message shows up if q is set between 0.05 and 0.95.)
The default value is 
{bf: q(0.99)}.


{marker examples}{...}
{title:Example}

{phang}CIC estimation of the QTE at the 98th percentile with 
an outcome {cmd:Y},
a covariate {cmd:X}, 
control/treatment group indicator {cmd:G} = 0, 1, and
time variable {cmd:T} = 0, 1:

{phang}{cmd:. regress Y X}{p_end}
{phang}{cmd:. predict resid_Y, residuals}{p_end}
{phang}{cmd:. ecic resid_Y G T, q(0.98)}{p_end}


{marker stored}{...}
{title:Stored results}

{phang}
{bf:ecic} stores the following in {bf:e()}: 
{p_end}

{phang}
Scalars
{p_end}
{phang2}
{bf:e(N)} {space 10}observations
{p_end}
{phang2}
{bf:e(n00)} {space 8}observations with {cmd:G} = 0 and {cmd:T} = 0
{p_end}
{phang2}
{bf:e(n01)} {space 8}observations with {cmd:G} = 0 and {cmd:T} = 1
{p_end}
{phang2}
{bf:e(n10)} {space 8}observations with {cmd:G} = 1 and {cmd:T} = 0
{p_end}
{phang2}
{bf:e(n11)} {space 8}observations with {cmd:G} = 1 and {cmd:T} = 1
{p_end}
{phang2}
{bf:e(k00)} {space 8}order statistics for {cmd:G} = 0 and {cmd:T} = 0
{p_end}
{phang2}
{bf:e(k01)} {space 8}order statistics for {cmd:G} = 0 and {cmd:T} = 1
{p_end}
{phang2}
{bf:e(k10)} {space 8}order statistics for {cmd:G} = 1 and {cmd:T} = 0
{p_end}
{phang2}
{bf:e(k11)} {space 8}order statistics for {cmd:G} = 1 and {cmd:T} = 1
{p_end}
{phang2}
{bf:e(q)} {space 10}quantile value
{p_end}

{phang}
Macros
{p_end}
{phang2}
{bf:e(cmd)} {space 8}{bf:ecic}
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
{bf:e(V)} {space 10}variance-covariance matrix of the estimator
{p_end}

{phang}
Functions
{p_end}
{phang2}
{bf:e(sample)} {space 5}marks estimation sample
{p_end}


{title:Reference}

{p 4 8}Sasaki, Y. and Y. Wang 2022. Extreme Changes in Changes. arXiv:2211.14870 
{browse "https://doi.org/10.48550/arXiv.2211.14870":Link to Paper}.
{p_end}


{title:Authors}

{p 4 8}Yuya Sasaki, Vanderbilt University, Nashville, TN.{p_end}

{p 4 8}Yulong Wang, Syracuse University, Syracuse, NY.{p_end}
