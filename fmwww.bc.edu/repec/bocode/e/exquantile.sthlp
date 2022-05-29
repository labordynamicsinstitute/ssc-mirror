{smcl}
{* *! version 1.1.1}{...}
{title:Title}

{phang}
{bf:exquantile} {hline 2} Executes estimation and inference for (conditional) extremal quantiles.


{marker syntax}{...}
{title:Syntax}

{p 4 17 2}
{cmd:exquantile}
{it:depvar}
[{it:indepvar}]
{ifin}
[{cmd:,} {bf:q}({it:real}) {bf:k}({it:real}) {bf:xval}({it:real})]


{marker description}{...}
{title:Description}

{phang}
{cmd:exquantile} estimates (conditional) extremal quantiles based on the nearest neighbor method for Hill's estimator of the tail index in the increasing-{it:k} framework, cf. Appendix A.5 of
{browse "https://www.tandfonline.com/doi/abs/10.1080/07350015.2020.1870985?journalCode=ubes20":Sasaki and Wang (2022)} 
(The fixed-{it:k} framework does not provide an estimate or a standard error, and hence it is not implemented in the current Stata command. 
Interested researchers can find a MATLAB code
{browse "https://www.tandfonline.com/doi/suppl/10.1080/07350015.2020.1870985?scroll=top":here}
for constructing fixed-{it:k} confidence intervals.)
If {it:indepvar} is absent in the command line, then the unconditional extremal quantile is computed.
If {it:indepvar} is present in the command line, then the conditional extremal quantile is computed given the value of {it:indepvar} specified by the {bf:xval} option.
To compute conditional extremal quantiles given a continuous {it:indepvar}, the data have to be either panel or repeated cross-sectional data.
For unconditional extremal quantiles (or conditional extremal quantiles given a discrete variable), on the other hand, data can be cross-sectional or repeated cross-sectional.


{marker options}{...}
{title:Options}

{phang}
{bf:q({it:real})} sets the quantile value. As an extremal quantile, it is natural to be set either below 0.05 or above 0.95. (A warning message shows up if q is set betwen 0.05 and 0.95.)
The default value is 
{bf: q(0.99)}.

{phang}
{bf:k({it:real})} sets the number of tail observations to be used. If this option is not called, then
{bf:k}
is automatically set to be an integer that is smaller than 5% of the sample size by default.

{phang}
{bf:xval({it:real})} sets the value of 
{it:indepvar}
{bf:x}
at which the conditional extremal quantile is estimated. If
{it:indepvar}
is included and this option is not called, then 
{bf:xval} 
is automatically set to the sample average of 
{it:indepvar}
by default.


{marker examples}{...}
{title:Examples}

{phang}Estimation of the 0.1-th percentile of the infant birthweight:

{phang}{cmd:. use "natl_random.dta"}{p_end}
{phang}{cmd:. exquantile birwt, q(0.001)}{p_end}

{phang}Estimation of the first percentile of the infant birthweight for non-smoking and smoking mothers:

{phang}{cmd:. use "natl_random.dta"}{p_end}
{phang}{cmd:. exquantile birwt if nosmoke, q(0.01)}{p_end}
{phang}{cmd:. exquantile birwt if !nosmoke, q(0.01)}{p_end}

{phang}Estimation of the first percentile of the infant birthweight for non-smoking and smoking mothers of age 40:

{phang}{cmd:. use "natl_random.dta"}{p_end}
{phang}{cmd:. xtset id time}{p_end}
{phang}{cmd:. exquantile birwt age if nosmoke, q(0.01) xval(40)}{p_end}
{phang}{cmd:. exquantile birwt age if !nosmoke, q(0.01) xval(40)}{p_end}

{phang}Note that conditioning on a continuous variable requires to use either panel or repeated cross-sectional data. The panel or repeated cross-sectional structure can be first set by the {bf:xtset} command before running {bf:exquantile}.


{marker stored}{...}
{title:Stored results}

{phang}
{bf:exquantile} stores the following in {bf:e()}: 
{p_end}

{phang}
Scalars
{p_end}
{phang2}
{bf:e(N)} {space 10}observations
{p_end}
{phang2}
{bf:e(q)} {space 10}quantile value
{p_end}
{phang2}
{bf:e(k)} {space 10}tail observations
{p_end}

{phang}
Macros
{p_end}
{phang2}
{bf:e(cmd)} {space 8}{bf:exquantile}
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

{p 4 8}Sasaki, Y. and Y. Wang 2022. Fixed-{it:k} Inference for Conditional Extremal Quantiles. {it:Journal of Business & Economic Statistics}, 40 (2): 829-837.
{browse "https://www.tandfonline.com/doi/abs/10.1080/07350015.2020.1870985?journalCode=ubes20":Link to Paper}.
{p_end}


{title:Authors}

{p 4 8}Yuya Sasaki, Vanderbilt University, Nashville, TN.{p_end}

{p 4 8}Yulong Wang, Syracuse University, Syracuse, NY.{p_end}
