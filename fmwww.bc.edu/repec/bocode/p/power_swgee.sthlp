{smcl}
{* *! version 1.0.0 15Feb2021}
{cmd:help power swgee}
{hline}

{title:Title}

{p2colset 10 17 17 2}{...}
{p2col :{hi:power swgee} {hline 2}}Computes power (under both a Z and t distribution) for cluster randomized stepped wedge designs assuming analysis is performed using a generalized estimating equations (GEE) model

{marker syntax}{...}
{title:Syntax}


{p 8 17 5}
{cmd:power swgee, } {cmd:es({it:real}) {cmdab:nclust:ers(}{it:{help integer}}) {cmdab:nper:iods(}{it:integer})  {cmdab:n(}{it:integer}) [{it:other options} *]}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{cmdab:es(}{it:real})}Specify the effect size. Note that this is not the standardized effect size but the effect size on the scale of the outcome. Specifically, specify a difference for identity link, 
an odds ratio for logit link and a risk or rate ratio for log link (for binary or count outcomes, respectively).{p_end}
{synopt:{cmdab:nclust:ers(}{it:integer})}Specify the number of clusters in the stepped wedge design. Note that if only the
required options are specified, then the number of clusters must be a multiple of {cmdab:nper:iods}-1{p_end}
{synopt:{cmdab:nper:iods(}{it:integer})}Number of time periods in the study{p_end}
{synopt:{cmdab:n(}{it:integer})}Number of individuals in each cluster at each time period. Depednign on the design 
(cross sectional or cohort) these may be the same individuals within the same cluster in different time periods, or 
these may be different people in each cluster in each time period{p_end}

If only the required options are specified, a complete design is assumed and all clusters start in the control condition 
so that the number of steps is {cmdab:nper:iods}-1.

{syntab:Optional}
{synopt:{cmdab:mu0(}{it:{help numlist}})}Mean/probability/rate of outcome in control at baseline (time period 0). Must specify a 
probability/rate between 0 and 1 (but not including 0 or 1), which is then converted to the link function scale.  Defaults 
to 0.1. {p_end}
{synopt:{cmdab:muT(}{it:{help numlist}})}Mean/probability/rate of outcome in control at final time period (time T), even if no 
clusters are in the control condition at the final time period. Must specify a probability/rate between 0 and 1 (but not 
including 0 or 1), which is then converted to the link function scale.  Defaults to be equal to {cmd:mu0}.  See description 
section for more details on period effects.{p_end}
{synopt:{cmdab:mus(}{it:{help numlist}})}A list of numbers indicating the control outcome probabilities/rates across 
time (the time trend).  If not supplied, then defaults to period effects being specified by {cmd:mu0} and {cmd:muT}.  
Otherwise, if {cmd:mus} is specified, {cmd:mu0} and {cmd:muT} will be overridden if they are also specified.{p_end}
{synopt:{cmdab:design(}{it:{help varlist}})}The design option allows the user to insert a list of variables corresponding 
to the design, where those variables are from a data set that is currently loaded in Stata.  

{synopt:{cmdab:alpha(}{it:real})}Two-tailed type I error rate; defaults to 0.05{p_end}
{synopt:{cmdab:working_ind(}{it:integer})}specifes whether to use the robust sandwich variance assuming
working independence (1) or the model based variance with true working correlation
(0) to estimate standard errors of the mean model parameters. The default is the
model based variance with true working correlation.{p_end}
{synopt:{cmdab:corstr(}{it:{help string}})}gives the structure of the true correlation matrix, which is also the
working correlation matrix if working_ind=0. The following options are available
for corstr in the context of SW-CRTs. The default is nested exchangeable.{p_end}

{center:{opt corstr} options}
             {center:{hline 63}}
{center:              Option                Design Type       Correlation Parameters}
             {center:{hline 63}}
{center:nested exchangeable   Cross-sectional   tau0, tau1}
{center:     block exchangeable    Cohort            tau0, tau1, tau2}	
{center:exponential decay     Cross-sectional   tau0, rho1}
{center:      proportional decay    Cohort            tau0, rho1, rho2}
             {center:{hline 63}}

{synopt:{cmdab:family(}{it:string})}Specifies the distribution family; default is binomial.{p_end}
{synopt:{cmdab:link(}{it:string})}Specifies the link function.  The default is logit for binomial family; log for Poisson family; and identity for Gaussian family. The following options are available for {cmdab:family} and {cmdab:link}.{p_end}

{center:Family     Link    }
{center:{hline 20}}
{center:binomial   logit   }
{center:binomial   log     }
{center:binomial   identity}
{center:poisson    log     }
{center:poisson    identity}
{center:gaussian   log     }
{center:gaussian   identity}
{center:{hline 20}}

{synopt:{cmdab:phi(}{it:real})}Dispersion parameter; defaults to 1{p_end}
{synopt:{cmdab:df(}{it:real})}Degrees of freedom for the t-test; defaults to {cmdab:nclust:ers} - 2{p_end}
{synopt:{cmdab:tau0(}{it:real})}Within-period ICC (required for all four correlation structures); must be specified by user{p_end}

{synopt:{cmdab:tau1(}{it:real})}Constant between-period ICC (for nested and block exchangeable correlation structures); defaults to be equal to {cmdab:tau0}{p_end}
{synopt:{cmdab:tau2(}{it:real})}Constant repeated-measures ICC (for block exchangeable correlation structure); defaults to be equal to {cmdab:tau1}{p_end}

{synopt:{cmdab:rho1(}{it:real})}Between-period ICC decay parameter (for exponential and proportional decay correlation structures); defaults to be equal to 1, indicating no decay{p_end}
{synopt:{cmdab:rho2(}{it:real})}Repeated-measures ICC decay parameter (for proportional decay correlation structure); defaults to be equal to {cmdab:rho1}{p_end}

The * indicates that other options are passed to the power command.  For example, the option {cmd:table} requests an output table, and {cmd:graph()} can be used to specify parameters to graph.
However, certain options, such as {cmd:onesided}, have no effect on this custom power program.

{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:power swgee} computes power calculations for stepped wedge designs in the generalized estimating equations (GEE) framework.  The theory and background behind the methods are published in {help power_cmd_powersw##Li2018:Li et al. (2018)} and {help power_cmd_powersw##Li2019:Li (2020)}.  Further description can be found in an article currently under review at Stata Journal.  The submitted article can be downloaded {browse "https://sites.duke.edu/johngallis/stata-packages/":here}.


{marker options}{...}
{title:Options}

If the {cmdab:design} option is not specified, then the design defaults to a complete design defined by {cmdab:nclust:ers} and {cmdab:nper:iods}.  For example, if {cmdab:nclust:ers}=5 and {cmdab:nper:iods}=6, then there are 5 steps 
with 1 cluster per step (because all clusters are assumed to start in the control condition and end in the treatment condition and an equal number of clusters is assumed in each step). The design is given by:

		{center:{txt}1   2   3   4   5   6}
            {center:{c TLC}{hline 25}{c TRC}}
          {center:1 {c |}  {res}0   1   1   1   1   1{txt}  {c |}}
          {center:2 {c |}  {res}0   0   1   1   1   1{txt}  {c |}}
          {center:3 {c |}  {res}0   0   0   1   1   1{txt}  {c |}}
          {center:4 {c |}  {res}0   0   0   0   1   1{txt}  {c |}}
          {center:5 {c |}  {res}0   0   0   0   0   1{txt}  {c |}}
            {center:{c BLC}{hline 25}{c BRC}{txt}}

Period effects are specified using either the {cmd:mu0} and {cmd:muT} options, or the {cmd:mus} option.  The {cmd:mu0} and {cmd:muT} options are used by default, and will be overridden if the {cmd:mus} option is specified.

If using the {cmd:mu0} and {cmd:muT} options, you specify the prevalence/rate of outcome in control at baseline and final time period.  (Note that for continuous outcomes with identity link, these will
be undefined.  If you enter values anyway, they are ignored in the calculation.)  (If muT is not specified, it will default to be equal to mu0, which is equivalent to stating that there is no time 
trend in the outcome.)  Then the program will create a linear trend on the link function scale based on these prevalences/rates and the number of time periods.  For example, suppose you specify 0.1 as {cmd:mu0} and 0.2 as {cmd:muT}, 
with four time periods and using a log link.  First, the program will convert the endpoints on the link function scale (log(0.1)=-2.30 and log(0.2)=-1.61), then create period effects for the other two time periods in equally spaced 
intervals between these two periods (in this case, -2.07 and -1.84).

For researchers who want even more fine-tuned control, the {cmd:mus} option will allow you to enter a set of probabilities/rates equal to the number of periods, which will then be
converted to the link function scale for the power function.

{marker example}{...}
{title:Examples}

{pstd}

	Create dataset corresponding to the design
{phang2}{cmd:.  clear}{p_end}
{phang2}{cmd:.  qui set obs 15}{p_end}
{phang2}{cmd:.  forvalues i=1/4 {c -(}}{p_end}
{phang2}{cmd:.      gen var`i'=0}{p_end}
{phang2}{cmd:.  {c )-}}{p_end}
{phang2}{cmd:.  replace var4 = 1}{p_end}
{phang2}{cmd:.  replace var3 = 1 in 1/10}{p_end}
{phang2}{cmd:.  replace var2 = 1 in 1/5}{p_end}

	Run power command with proportional decay correlation structure, varying tau0
{phang2}{cmd:. power swgee, mu0(0.1) muT(0.2) es(2) design(var1-var4) nclust(15) nper(4) n(100) family(poisson) link(log)} 
{cmd:corstr(proportional decay) tau0(0.04(0.01)0.06) rho1(0.02) rho2(0.7) alpha(0.05) table graph(xdimension(tau0)}
{cmd:ydimension(t_power))}{p_end}
	{it:({stata "power_swgee_examples power_swgee_examples_1":click to run})}

	Example without design matrix
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. power swgee, mu0(0.1) muT(0.2) es(2) nclust(15) nper(4) n(100) family(binomial) link(logit)}
{cmd:corstr(exponential decay) tau0(0.04(0.01)0.06) rho1(0.02) alpha(0.05) table graph(xdimension(tau0) ydimension(t_power))}{p_end}
	{it:({stata "power_swgee_examples power_swgee_examples_2":click to run})}

	

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:power swgee} stores the following in {cmd:r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:r(onesided)}}1 for a one-sided test, 0 otherwise; {cmd:defunct; not used in the program}{p_end}
{synopt:{cmd:r(N)}}number of individuals; {cmd:defunct; not used in the program} {p_end}
{synopt:{cmd:r(separator)}}number of lines between separator lines in the table{p_end}
{synopt:{cmd:r(divider)}}1 if divider is requested in the table, 0 otherwise{p_end}
{synopt:{cmd:r(alpha)}}significance level (type I error); {cmd:defunct; not used in the program, see r(size)}{p_end}
{synopt:{cmd:r(beta)}}probability of a type II error {cmd:defunct; not used in the program}{p_end}
{synopt:{cmd:r(power)}}power {cmd:defunct; not used in the program; see power_t and power_z in the output table.}{p_end}
{synopt:{cmd:r(working_ind)}}1 if working_ind option set to 1; 0 otherwise{p_end}

{phang2}Other items in the return scalars are for the last iteration of the power program (last row of the output table).  All {p_end}
{phang2}items for all iterations can be extracted from the table matrix ({cmd:r(pss_table)}){p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:r(corstr)}}Correlation structure chosen{p_end}

{phang2}Other macros are common to the power command.  See {it:{help power}} for more information.{p_end}


{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:r(pss_table)}}table of results{p_end}
{synopt:{cmd:r(design)}}design matrix; if user-entered and varied, this is the design matrix of the last iteration of the program
(i.e., the last row in the table){p_end}
{synopt:{cmd:r(mus)}}Matrix of probabilities/rates entered in the {cmd:mus} option or the {cmd:mu0} and {cmd:muT} option;
will be missing if outcome is continuous{p_end}
{synopt:{cmd:r(betas)}}Matrix of period effects on the link function scale{p_end}

{p2colreset}{...}

{marker reference}{...}
{title:References}

{marker Li2018}{...}
{phang}
Li, F., Forbes, A. B., Turner, E. L., & Preisser, J.S. (2018). Sample size determination for GEE analyses of stepped wedge cluster randomized trials. {it:Biometrics}, 74(4), 1450-1458.
{p_end}

{marker Li2019}{...}
{phang}
Li, F. (2020). Design and analysis considerations for cohort stepped wedge cluster randomized trials with a decay correlation structure. {it:Statistics in Medicine}, 39(4), 438-455. 
{p_end}

{marker author}{...}
{title:Authors}
 John A. Gallis
 Duke University Department of Biostatistics and Bioinformatics
 Duke Global Health Institute
 Durham, NC
 john.gallis@duke.edu
 
 Xueqi Wang 
 Duke University Department of Biostatistics and Bioinformatics
 Duke Global Health Institute
 Durham, NC
 xueqi.wang@duke.edu
 
 Paul J. Rathouz
 Department of Population Health
 University of Texas at Austin
 Dell Medical School
 Austin, TX
 paul.rathouz@austin.utexas.edu
  
 John S. Preisser
 Department of Biosttistics
 University of North Carolina at Chapel Hill
 Gillings School of Global Public Health
 Chapel Hill, NC
 jpreisse@bios.unc.edu
  
 Fan Li
 Yale School of Public Health
 Center for Methods in Implementation and Prevention Science
 New Haven, CT
 fan.f.li@yale.edu  

 Elizabeth L. Turner
 Duke University Department of Biostatistics and Bioinformatics
 Duke Global Health Institute
 Durham, NC
 liz.turner@duke.edu
 
{marker acknowledgements}{...}
{title:Acknowledgements}

The authors would like to thank Alyssa Platt of the Duke Global Health Institute
Research Design and Analysis Core for testing and providing feedback on the programs.
