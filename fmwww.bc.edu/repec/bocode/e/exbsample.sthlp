{smcl}
{hline}
help for {hi:exbsample}{right:P. Van Kerm (September 2022)}
{hline}


{title:Title}

{p 4 4 2}
{bf:exbsample}  {hline 2} Exchangeably weighted (or Bayesian) bootstraps


{title:Syntax}

{p 8 8 2} {bf:exbsample} {it:#}  [{it:if}] [{it:in}]  [{it:weight}]  [using {it:filename}] [, {it:options}]

{p 4 4 2}
{it:#} is the desired number of bootstrap replicates. 


{col 5}{it:option}{col 49}{it:Description}
{space 4}{hline}
{col 5}stub({it:name}){col 49}prefix of bootstrap weight variables generated
{col 5}{ul:d}istribution(poisson {it:or} exponential){col 49}choice of bootstrap weight distribution
{col 5}norescale{col 49}disable scaling of weights to unit mean
{col 5}{ul:bal}ance({it:#}){col 49}request balancing of bootstrap weights (in {it:#} iterations)
{col 5}seed({it:#}){col 49}set random-number seed to  {it:#}
{col 5}{ul:str}ata({it:varlist}){col 49}variables identifying strata
{col 5}{ul:cl}uster({it:varlist}){col 49}variables identifying clusters
{col 5}{ul:svy}setttings{col 49}reads strata and cluster identifiers from {bf:svyset}
{col 5}{ul:id}vars({it:varlist})	 	{col 49}variables uniquely identifying bootrapped units in new frame or data file
{col 5}{ul:fr}ame({it:name} [, {ul:link}varname({it:varname}) replace nofrlink])	
{col 5}	{col 49}save bootstrap weight variables in a separate frame {it:name} and links to the current frame using variable {it:varname}  (unless {it:nofrlink} is specified)
{col 5}replace{col 49}replace frame {it:name} or file {it:filename} or variables {it:stub*}  if they exist
{col 5}nodots{col 49}do not display dots
{space 4}{hline}
{p 4 4 2}
{bf:fweight}, {bf:pweight} or {bf:iweight} are allowed.


{title:Description}

{p 4 4 2}
{bf:exbsample} generates bootstrap replication weights for implementation of 
exchangeably weighted bootstrap schemes, also known as the Bayesian bootstrap. It can be used as an alternative to {bf:bsample}. 

{p 4 4 2}
Exchangeably weighted bootstrap schemes (or weighted, or exchangeable bootstraps) are 
alternatives to the traditional non-parametric (paired) bootstrap. Standard bootstrap 
replications involve generating bootstrap samples of size {it:N} by drawing with replacement 
from the original data. Such a bootstrap resample can be seen as a frequency weighted 
version of the original data, with integer weights representing the number of times each observation
is drawn in a resample. (See the {bf:weight} option of Stata{c 39}s bootstrap drawing command {bf:bsample}.)
Exchangeably weighted bootstrap schemes can be seen as extensions of this representation: 
bootstrap resamples are created by generating replication weights directly from appropriate distribution functions. 
See Praestgaard and Wellner (1993) for details. This technique is also known as the Bayesian bootstrap (Rubin, 1981).

{p 4 4 2}
{bf:exbsample} generates weights based on draws from a Poisson distribution or from an exponential distribution (both with unit mean).
Drawing from the Poisson distribution generates integer weights 0, 1, 2, ... the distribution of which approximates the multinomial 
distribution that standard resampling weights effectively follow. 
Drawing from the exponential distribution generates strictly positive, non-integer weights. Draws from the exponential distribution 
can be seen as continuous (smoothed) versions of the Poisson draws. The advantage of exponential draws is the absence of 
zero weights: all observations from the original data are kept in the bootstrap resamples, albeit with possibly small weights. 
This can have practical computational advantages. In both cases, replication weights are, by default, scaled to sum to the sample size {it:N}.

{p 4 4 2}
Once replication weight variables are generated, they can be used by {bf:svy bootstrap} for bootstrap inference. ({it:_svyset} {bf:,bsrweight(...)} needs to be set accordingly.) 
Also see J. Pitblado{c 39}s {bf:bs4rw}. 

{p 4 4 2}
Stratified and/or clustered sampling is handled by specifying strata and cluster
identifiers (as in {cmd:bsample}); samples of clusters are {c 96}drawn{c 39} independently
across strata -- observations from the same cluster all have the same weight and weights sum to the number of clusters.

{p 4 4 2}
Observations that do not meet the optional {it:if} and {it:in} criteria are excluded from the bootstrap replications. 

{p 4 4 2}
If an {bf:fweight}, {bf:pweight} or {bf:iweight} is given, the Poisson or exponential bootstrap replication weights are multiplied by the weight expression.

{p 4 4 2}
The replication weight variables generated are added to the data in memory by default. They can alternatively be saved in a separate file if {bf:using} {it:filename} is specified or in a separate frame with the option {bf:frame}.


{title:Options}

{phang}
{opth stub(name)} determines the name of the bootstrap weight variables generated. Replication weight variables are named {it:name1}, {it:name2}, etc. Default is {it:bootvar1}, bootvar2}, etc. 

{phang}
{opth distribution(name)} selects the bootstrap weight distribution; name is {bf:exponential} (the default) or {bf:poisson}.

{phang}
{opt norescale} disable scaling of replication weight variables to sum to the number of observations (or clusters). 

{phang}
{opth balance(#)} requests balancing of weights across all replications. Standard bootstrap balancing ensures that each observation in the data is drawn the same number of times in the overall set of resamples. Balancing is implemented here by scaling resampling weights {c 96}horizontally{c 39} (i.e., across replications for each observation) so that they sum to the number of bootstrap replications. To obtain both balancing (horizontal) and scaling (vertical), the two scaling steps are iterated {it:#} number of times. (Default is 0 which implies {it:no} balancing.)

{phang}
{opt seed(#)} sets the random number generator seed to {it:#} prior to generating replication weight draw. 

{phang}
{opth strata(varlist)} specifies the variables identifying strata. If {opt strata()} is specified, bootstrap replication weights are scaled to sum to the number of clusters in each stratum. 

{phang}
{opth cluster(varlist)} specifies the variables identifying resampling clusters (primary sampling units).  If {opt cluster()} is specified, one replication weight is drawn per cluster and is shared across all observations in the cluster.

{phang}
{opt svysettings} requests that strata and cluster information is read from the settings of the dataset, as determined by {bf:svyset}.

{phang}
{opth idvars(varlist)} identifies variables that uniquely identify the bootrapped units. This is required when replication weights are stored in a separate frame or data file: the variables in {bf:idvars} are saved alongside the replication weights to allow matching to the dataset in memory.

{phang}
{opth frame(name)}  requests that bootstrap replication weight variables are stored in a new, separate frame named {it:name} (and not in the current frame in memory). A frame linkage is created to the current frame unless the {it:nofrlink} sub-option is specified. The link variable is given in {cmd:linkvarname(}{it:varname}{cmd:)} (BOOTSTRAPLINK by default). 

{phang}
{opt replace} requests that frame {it:name} or file {it:filename} or variables {it:stubX}  are replaced if they already exist.

{phang}
{opt nodots} disables display of dots.


{title:Examples}

    Generate simple replication weights from exponential distribution:

        . sysuse auto 
        . exbsample 499 , stub(rw)
        . summarize rw1 rw2 rw499
        . svyset , bsrweight(rw1-rw499) 
        . svy bootstrap : regress price trunk i.foreign
		
    Select Poisson weights and save weights in separate dataset:

        . sysuse auto 
        . exbsample 499   using replications-weights.dta   , stub(rw)  distribution(poisson) idvars(make) 

    Select Poisson weights, disable weight scaling and save weights in separate frame:

        . sysuse auto 
        . exbsample 499  , stub(rw)  distribution(poisson) norescale frame(replications , link(bootvarlink))  idvars(make)
        . frget rw1, from(bootvarlink)
        . regress price trunk i.foreign [iw=rw1]
        . frame change replications 
        . summarize rw1 rw2 rw499 

{p 4 4 2}
See Van Kerm (2022) for more examples.		


{title:Citation suggestion}

{p 4 4 2}
Van Kerm, P. (2022). exbsample {c -} Stata module for exchangeably weighted (or Bayesian) bootstraps, Statistical Software Components, Boston College Department of Economics.


{title:Also see}

{psee}
Online:  {manhelp bsample R}, {helpb rhsbsample} (if installed), {helpb gsample} (if installed), {helpb bsweights} (if installed), {helpb bs4rw} (if installed)
{p_end}


{title:Author}

{p 4 4 2}
Philippe Van Kerm     {break}
Luxembourg Institute of Socio-Economic Research and University of Luxembourg


{title:References}

{p 4 4 2}
Praestgaard, J. and Wellner, J. A. (1993), Exchangeably weighted bootstraps of the general empirical process, The Annals of Probability 21(4), 2053–208

{p 4 4 2}
Rubin, D. (1981), The Bayesian bootstrap, The Annals of Probability 21(4), 2053–208

{p 4 4 2}
Van Kerm, P. (2022).  {browse "http://ideas.repec.org/p/boc/usug22/":Exchangeably weighted bootstrap schemes}. 2022 London Stata Users Group meeting, September 8-9 2022, University College London.


{space 4}{hline}

{p 4 4 2}
This help file was dynamically produced by 
{browse "http://www.haghish.com/markdoc/":MarkDoc Literate Programming package} 


