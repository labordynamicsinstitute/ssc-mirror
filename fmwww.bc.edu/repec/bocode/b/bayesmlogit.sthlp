{smcl}
{* 2Feb2013}{...}
{cmd:help bayesmlogit}
{hline}

{title:Title}

{p2colset 5 20 29 2}{...}
{p2col :{hi:bayesmlogit} {hline 2}}Bayesian mixed logit model{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 15 2}
{cmd:bayesmlogit}
{depvar}
[{indepvars}] {ifin} {cmd:,}
{cmdab:gr:oup(}{varname}{cmd:)}
{cmdab:id:entifier(}{varname}{cmd:)}
{cmdab:rand:(}{varlist}{cmd:)}
[{opt draws(#)}
 {opt drawsr:andom(#)}
 {opt drawsf:ixed(#)}
 {opt burn(#)}
 {opt thin(#)}
 {opt arater:andom(#)}
 {opt aratef:ixed(#)}
 {opt samplerf:ixed(string)}
 {opt samplerr:andom(string)}
 {opt dampparmf:ixed(#)}
 {opt dampparmr:andom(#)} 
 {opt from(rowvector)}
 {opt fromv:ariance(matrix)}
 {opt jumble}
 {opt noisy}
 {opt saving(filename)}
 {opt replace}
 ]

{title:Description}

{pstd}
{cmd:bayesmlogit} can be used to "fit" mixed logit models using Bayesian methods - more precisely {cmd:bayesmlogit} 
produces draws from the posterior parameter distribution, and then presents summary and other statistics describing the 
results of the drawing. Detailed analysis of the draws is by and large left to the discretion of the user. 

{pstd}
Implementation of {cmd: bayesmlogit} 
follows Train (2009, chapter 12), and details of how the algorithm works are described in Baker (2013). 
A diffuse prior for the mean values of the random coefficients is assumed, 
and the prior distribution on the covariance matrix of random coefficients is taken to be an identity inverse Wishart.
{cmd: bayesmlogit} employs the Mata routines {help mf_amcmc:amcmc} (if not installed {net search amcmc:search} online)
for adaptive Markov chain Monte Carlo sampling
from the posterior distribution of individual level coefficients and fixed coefficients. The data setup for {cmd:bayesmlogit} 
is the same as for {cmd:clogit}. Much of the syntax follows that used by Hole(2008) in development of the command {cmd:mixlogit}. 

{title:Syntax}

{phang}
{opth gr:oup(varname)} is required and specifies a numeric identifier variable
for choice occasions.

{phang}
{opth id:entifier(varname)} is required and identifies coefficient sets; those observations for which a set of coefficients apply.
Thus, in a situation in which a person is observed
making choices over multiple occasions, one would use {opth gr:oup(varname)} to specify the choice occasions, while 
{opth id:entifier(varname)} would identify the person. 

{phang}
{opth rand(varlist)} is required and specifies independent variables with random coefficients. The
variables immediately following the dependent variable in the syntax are
considered to have fixed coefficients (see the examples below). While a model can be run without any independent variables with
fixed coefficients, at least one random-coefficient independent variable is required for {cmd:bayesmlogit} to work.

{title:Options}

{phang}
{opt draws(#)} specifies the number of draws that are to be taken from the posterior distribution of the parameters. The default is 1000.

{phang}
{opt drawsr:andom(#)} is an advanced option. The drawing algorithm treats each set of random coefficients as a Gibbs step in sampling from the joint posterior
distribution of parameters, and in difficult, large-dimensional problems 
it might be desirable to let individual Gibbs steps run for more than one draw to achieve better mixing and convergence of the
algorithm. 

{phang}
{opt drawsf:ixed(#)} is a more advanced option. The drawing algorithm treats fixed coefficients as a Gibbs step in sampling from the joint posterior
distribution of parameters, and in difficult, large-dimensional problems it might be desirable to let this step in Gibbs sampling run for more than
a single draw. The default is 1.

{phang}
{opt burn(#)} specifies the length of the burn-in period; the first # draws are discarded upon completion 
of the algorithm and before further results
are computed. 

{phang}
{opt thin(#)} specifies that only every #th draw is to be retained, so if {cmd:thin(3)} is specified, only every third draw is retained.
This option is designed to help ease autocorrelation in the resulting draws, as is the option {opt jumble}, which randomly mixes draws. 
Both options may be applied.

{phang}
{opt arater:andom(#)} specifies the desired acceptance rate for random coefficients, and should be a number between zero and one. 
As an adaptive 
acceptance-rejection method is used to 
sample random coefficients, by specifying the desired acceptance rate, the user has some control over adaptation 
of the algorithm to the problem. The default is .234. 

{phang}
{opt aratef:ixed(#)} specifies the desired acceptance rate for fixed coefficients, and works in the same fashion as {opt arater:random(#)}. 

{phang}
{opth samplerr:andom(string)} specifies the type of sampler that is to be used when random parameters are drawn. It may be set to either
{it:global} or {it:mwg}. The default is {it:global}, which means that proposed changes
to random parameters are drawn all at once; if {it:mwg} - an acronym for "metropolis within Gibbs" - is instead chosen, 
each random parameter is drawn separately as an independent
step conditional on other random parameters in a nested Gibbs step. The default is {it:global}, but 
{it:mwg} might be useful in situations in which initial values are poorly scaled. The workings of these options are described in greater detail
in Baker (2013).

{phang}
{opth samplerf:ixed(string)} specifies the type of sampler that is used when fixed parameters are drawn. Options are exactly as those
described under {opth samplerr:andom(string)}. 

{phang}
{opt dampparmr:andom(#)} is a parameter that controls how aggressively the proposal distribution(s) for random parameters is adapted
as drawing continues. If set close to one, adaptation is agressive in its early phases in trying to achieve the acceptance rate specified
in {opt arater:andom(#)}. If set closer to zero, adaptation is more gradual. 

{phang}
{opt dampparmf:ixed(#)} works exactly as option {opt dampparmr:andom(#)} but applied to drawing fixed parameters. 

{phang}
{opth from(string)} specifies a row vector of starting values for all parameters in order. 
In the even that these are not specified, starting
values are obtained via estimation of a conditional logit model via {help clogit}. 

{phang}
{opth fromV:ariance(string)} specifies a matrix of starting values for the random parameters. 

{phang}
{opth saving(string)} specifies a location to store the draws from the distribution. The file will contain just the draws after any burn in period
or thinning of values is applied. {opt replace} specifies that an existing file is to be overwritten, while {opt append} specifies that
an existing file is to be appended, which might be useful if multiple runs need to be combined. 

{phang}
{opt noisy} specifies that a dot be produced every time a complete pass through the algorithm is finished. After 50 iterations, a "function value"
{it:ln_fc(p)} will be produced, which gives the joint log of the value of the posterior choice probabilities evaluated at the latest parameters. While
not an objective function per se, the author has found that drift in the value of this function indicates that the algorithm has not yet converged
or other problems.

{title:Examples}

{phang}
A single random coefficient, one decision per group. The random parameter rate is set to .4 and a total of 4000 draws are taken. 
The first 1000 draws are dropped, and then every fifth draw is retained. Draws are saved as {bf: choice_draws.dta}:{p_end}

     {cmd}. webuse choice, clear
     {res}{txt}
     {cmd}. bayesmlogit choice, rand(dealer) group(id) id(id) draws(4000) burn(1000) thin(5) arater(.4) saving(choice_draws) replace{txt}

{phang}	 
Estimating a mixed logit model using {cmd: bayesmlogit}, using the methods as described in Long and Freese (2006, sec. 7.2.4). The data must first be
rendered into the correct format, which can be done using the command {com: case2alt}, which is part of the package {bf: spost9_ado}; if not installed,
type {cmd:net describe spost9_ado} from the Stata prompt, or found online by {net search spost9_ado:{bf:clicking here}}. The example first arranges the
data, and then generates and summarizes posterior draws from a mixed logit model. The model uses {bf:bangladesh.dta}, which has information on 
contraceptive choice by a series of families. Coefficients of explanatory variables vary at the district level. 

	{cmd}. webuse bangladesh, clear
	{res}{txt}(Bangladesh Fertility Survey, 1989)
	{res}
	{cmd}. case2alt, casevars(urban age) choice(c_use) gen(choice)
	{res}{txt}(note: variable {bf:_id} used since case() not specified)
	{res}{txt}(note: variable {bf:_altnum} used since altnum() not specified)
	{res}
	{res}{txt}choice indicated by: {bf:choice}
	{res}{txt}case identifier: {bf:_id}
	{res}{txt}case-specific interactions: {bf:no* yes*}
	{res}
	{cmd}. bayesmlogit choice, rand(yesXurban yesXage yes) group(_id) id(district) draws(10000) burn(5000) saving(bdesh_draws) replace{txt}

{title:Saved results}

{pstd}
{cmd:bayesmlogit} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(df_r)}}Degrees of freedom for summarizing draws (equal to number of retained draws){p_end}
{synopt:{cmd:e(krnd)}}Number of random parameters{p_end}
{synopt:{cmd:e(kfix)}}Number of fixed parameters{p_end}
{synopt:{cmd:e(draws)}}Number of draws{p_end}
{synopt:{cmd:e(burn)}}Burn-in observations{p_end}
{synopt:{cmd:e(thin)}}Thinning parameter{p_end}
{synopt:{cmd:e(random_draws)}}Number of draws of each set of random parameters per pass{p_end}
{synopt:{cmd:e(fixed_draws)}}Number of draws of fixed paramaters per pass{p_end}
{synopt:{cmd:e(damper_fixed)}}Damping parameter - fixed parameters{p_end}
{synopt:{cmd:e(damper_random)}}Damping parameter - random parameters{p_end}
{synopt:{cmd:e(opt_arate_fixed)}}Desired acceptance rate - fixed parameters{p_end}
{synopt:{cmd:e(opt_arate_random)}}Desired acceptance rate - random parameters{p_end}
{synopt:{cmd:e(N_groups)}}Number of groups{p_end}
{synopt:{cmd:e(N_choices)}}Number of choice occasions{p_end}
{synopt:{cmd:e(arates_fa)}}Acceptance rate - fixed parameters{p_end}
{synopt:{cmd:e(arates_ra)}}Ave. acceptance rate - random parameters{p_end}
{synopt:{cmd:e(arates_rmax)}}Max. acceptance rate - random parameters{p_end}
{synopt:{cmd:e(arates_rmin)}}Min. acceptance rate - random parameters{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(saving)}}File containing results{p_end}
{synopt:{cmd:e(fixed_sampler)}}Sampler type for fixed parameters{p_end}
{synopt:{cmd:e(random_sampler)}}Sampler type for random parameters{p_end}
{synopt:{cmd:e(random)}}Random parameter names{p_end}
{synopt:{cmd:e(fixed)}}Fixed parameter names{p_end}
{synopt:{cmd:e(identifier)}}Identifer for individuals{p_end}
{synopt:{cmd:e(group)}}Identifier for choice occasions{p_end}
{synopt:{cmd:e(depvar)}}Dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}Independent variables{p_end}
{synopt:{cmd:e(cmd)}}{cmd:"bayesmlogit"}{p_end}
{synopt:{cmd:e(title)}}{cmd:"Bayesian Mixed Logit Model"}{p_end}
{synopt:{cmd:e(properties)}}{cmd:"b V"}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}mean parameter values{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of parameters{p_end}
{synopt:{cmd:e(V_init)}}Initial variance covariance matrix of random parameters{p_end}
{synopt:{cmd:e(b_init)}}Initial mean vector of random parameters{p_end}
{synopt:{cmd:e(arates_fixed)}}Row vector of acceptance rates of fixed parameters{p_end}
{synopt:{cmd:e(arates_rand)}}Vector/Matrix of acceptance rates of random parameters{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}
	
	
{title:Comments}

{pstd}
The basic algorithms used in drawing are described in some detail in Baker (2013). The user might gain a fuller understanding of the options
{opt aratefixed}, {opt arater:andom}, {opt damperf:ixed}, {opt damperr:andom}, and other options controlling adaptation of the proposal distribution
from a reading of this document. 

{cmd:bayesmlogit} requires that the package of Mata functions {cmd:amcmc} be installed, and also requires installation of Ben Jann's {cmd:moremata}
set of extended Mata functions. 

{pstd}
{bf:{it:Caution!!!}} - While summary statistics of the results of a drawing are presented in the usual Stata format, 
{cmd:bayesmlogit}  provides no guidance as to how one should actually go about selecting the number of draws, how draws should be processed,
monitoring convergence of the algorithm, or presenting and interpreting results. One would do well to consult Train (2009), and 
a good source on Bayesian methods such as Gelman et. al. (2009). Fortunately, Stata provides a wealth of tools for summarizing and plotting
the results of a drawing. 

{title:Reference}

{phang}Baker, M. J. 2013. {it:Adaptive Markov chain Monte Carlo sampling and estimation in Mata}. {browse " http://EconPapers.repec.org/RePEc:htr:hcecon:440":Hunter College working paper 440}.

{phang}Gelman, A., J. B. Carlin, H. S. Stern, and D. B. Rubin. 2009. {it:Bayesian data analysis, 2nd. ed.} Boca Raton: Chapman and Hall. 

{phang}Hole, A. R. 2007. {it:Fitting mixed logit models by using maximum simulated likelihood}. Stata Journal: 7:388-401, 1-14.

{phang}Long, J. S., and J. Freese. 2006. {it:Regression models for categorical dependent variables using Stata}. College Station: Stata Press. 

{phang}Train, K. E. 2009. {it:Discrete Choice Methods with Simulation}.
Cambridge: Cambridge University Press.

{title:Author} 

{phang}This command was written by Matthew J. Baker (matthew.baker@hunter.cuny.edu),
Hunter College and The Graduate Center, CUNY. Comments, criticisms, and suggestions for improvement are welcome. {p_end}

{title:Also see}

{psee}
Manual:  {bf:[R] clogit}

{psee}
Online: {net search spost9_ado:{bf:spost9_ado}}, {net install amcmc:{bf:amcmc}}, {net search moremata:{bf:moremata}}

{psee}
Other: (if installed)
{help mf_amcmc:{bf: mf_amcmc}}, {help moremata:{bf:moremata}}
