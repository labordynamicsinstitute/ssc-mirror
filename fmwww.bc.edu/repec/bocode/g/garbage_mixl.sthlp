{smcl}
{* July 2023}{...}
{cmd:help garbage_mixl}
{hline}

{title:Title}

{p 4 8 2}
{hi:garbage_mixl} {hline 2} Bayesian garbage class mixed logit model estimation in Stata

{title:Syntax}

{p 4 8 2}
{cmd:garbage_mixl}
{depvar}
{ifin} {cmd:,}
{cmdab:rand:(}{varlist}{cmd:)}
{cmdab:id:(}{varname}{cmd:)}
{cmdab:group:(}{varname}{cmd:)}
[{opt burn(#)}
 {opt mcmc(#)}
 {opt bern:oulli(#)}
 {opt nogarbage}
 {opt diag}
 {opt invwishart}]

{title:Description}

{pstd}
{cmd:garbage_mixl} fits standard and garbage class mixed logit models using Bayesian MCMC methods via a C++ plugin for computational efficiency


{title:Options for garbage_mixl}

{phang}
{opth rand(varlist)} is required and specifies the independent variables. All independent variables’ coefficients are assumed to be random; fixed coefficients are not supported.

{phang}
{opth id(varname)} is required and specifies a numeric identifier variable for the decision
makers. 

{phang}
{opth group(varname)} is required and specifies a numeric identifier variable
for the choice occasions.

{phang}
{opt burn(#)} specifies the number of burn-in MCMC draws. The default and minimum value is {cmd:burn(50000)}.

{phang}
{opt mcmc(#)} specifies the number of MCMC draws used to approximate the posterior after the burn-in iterations. The default and minimum value is {cmd:mcmc(50000)}.   

{phang}
{opt bernoulli(#)} specifies the prior distribution for the individual-level MIXL class probabilities in the garbage class mixed logit model. The default is {cmd:bernoulli(0.5)}. Note
that the garbage class mixed logit results tend to be sensitive to the Bernoulli prior, particularly with limited observations per decision maker. Therefore, 
{cmd:garbage_mixl} requires at least as many observations per decision maker as the number of random parameters specified.  

{phang}
{opt nogarbage} specifies that {cmd:garbage_mixl} fits a standard mixed logit model.

{phang}
{opt diag} specifies that a diagonal (uncorrelated) mixed logit model is being fit, with half-Normal(10) priors on the standard deviations of the normal mixing distributions.

{phang}
{opt invwishart} replaces the default Huang and Wand (2013) scaled inverse Wishart prior with a conventional inverse Wishart prior on the variance-covariance matrix. The 
inverse Wishart prior is specified with a unit scale matrix and degrees of freedom equal to the number of random parameters. This prior
is more informative and restrictive than the default prior, and seldom recommended.


{title:Examples}

{pstd}
The following examples use traindata.dta, which is described in Hole (2007).

{p 4 8 2}
{cmd:Example 1:} The standard garbage class MIXL model

{phang2}{cmd:. use http://fmwww.bc.edu/repec/bocode/t/traindata.dta}{p_end}

{phang2}{cmd:. garbage_mixl y, rand (price contract local wknown tod seasonal) id(pid) group(gid)}{p_end}

{p 4 8 2}
{cmd:Example 2:} The garbage class MIXL model with user-specified Bernoulli priors

{phang2}{cmd:. garbage_mixl y, rand (price contract local wknown tod seasonal) id(pid) group(gid) bernoulli(0.8)}{p_end}

{pstd}
Note: the informative Bernoulli(0.8) prior specifies for each decision maker 0.8 prior probability of MIXL class membership, which corresponds to the prior expectation that the size of the garbage class is approximately 20%.
As shown, this changes the posterior mean garbage class estimate from roughly 10% in example 1 to 6.5% in example 2. 

{p 4 8 2}
{cmd:Example 3:} The standard MIXL model

{phang2}{cmd:. garbage_mixl y, rand (price contract local wknown tod seasonal) id(pid) group(gid) nogarbage}{p_end}

{p 4 8 2}
{cmd:Example 4:} Standard MIXL model with an inverse Wishart prior

{phang2}{cmd:. garbage_mixl y, rand (price contract local wknown tod seasonal) id(pid) group(gid) nogarbage invwishart}{p_end}

{pstd}
Note: this syntax provides close-to-identical estimates as the ssc -bayesmixedlogit- command of Matthew Baker.

{p 4 8 2}
{cmd:Example 5:} Standard (diagonal) MIXL model

{phang2}{cmd:. garbage_mixl y, rand (price contract local wknown tod seasonal) id(pid) group(gid) nogarbage diag}{p_end}


{title:References}

{phang}Hole AR. 2007. Fitting mixed logit models by using maximum simulated likelihood. {it:The Stata Journal} 7: 388-401.

{phang} Huang A and Wand MP. 2013. Simple marginally noninformative prior distributions for covariance matrices. {it:Bayesian Analysis} 8(2): 439-452.

{phang}Jonker MF. 2022. The garbage class mixed logit model. {it:Value in Health} 25(11): 1871-1877.

{title:Author}

{pstd}
Marcel F. Jonker (marcel@mfjonker.com), Erasmus University Rotterdam, The Netherlands. {p_end}
