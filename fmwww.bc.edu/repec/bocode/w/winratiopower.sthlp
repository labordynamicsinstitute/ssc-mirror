{smcl}
{* *! Version 1.0.3 August 30 2023 }{...}

{viewerjumpto "Syntax" "winratiopower##syntax"}{...}
{viewerjumpto "Description" "winratiopower##description"}{...}
{viewerjumpto "Options" "winratiopower##options"}{...}
{viewerjumpto "Examples" "winratiopower##examples"}{...}
{viewerjumpto "Saved results" "winratiopower##savedresults"}{...}
{viewerjumpto "References" "winratiopower##references"}{...}
{viewerjumpto "Authors" "winratiopower##authors"}{...}


{cmd: help winratiopower}
{hline}

{title:Title}

{phang}
{bf:winratiopower} {hline 2} calculates sample sizes for trials of fixed duration using the Win Ratio for prioritised outcomes.

{marker syntax}{...}
{title:Syntax}

{phang}
{opt winratiopow:er} {cmd:,} 
{opt outcome(outcome_type outcome_options)} [
{opt p:ower(number)} 
{opt n(number)} 
{opt a:lpha(number)} 
{opt nrat:io(number)} 
]


{marker description}{...}
{title:Description}

{pstd}
The win ratio was introduced in 2012 by Pocock {it:et al} {cmd:[1]} as a novel approach to the analysis of composite endpoints in randomised clinical trials. 
The approach motivated by the Finkelstein–Schoenfeld test {cmd:[2]} takes into account the order of importance of the component events and also allows the components to be different types of outcomes
e.g. time-to-event (failure or success), quantitative outcomes such as quality of life scores and vital signs, repeated events, and more. 

{pstd}
{bf:winratiopower} has been developed to enable sample size calculations  
without the need for complex and time-consuming simulations. The sample size calculations are based on the formula of Yu and Ganju {cmd:[3]}. A fixed trial duration is assumed. Independence between outcomes at different levels of the hierarchy is
assumed. 


{marker options}{...}
{title:Options}

{phang}
{bf: outcome({it:outcome_type outcome_options})} is a repeated option. It is used to specify the type of outcome along with information about the anticipated treatment effect at each level of the hierarchy, starting with the first
(most important) outcome through to the last (least important) outcome. {p_end}

{p 8 8 2}
{bf:outcome_type} will be: {bf:b} for binary outcomes, {bf:c} for continous outcomes, {bf:r} for repeat event outcomes, {bf:tf} for time to failure outcomes or {bf:ts} for time to success outcomes. 

{p 8 8 2}
{bf:outcome_options} differs depending on the type of outcome. This is explained in detail below:

{p 8 8 2}
{bf:binary} outcomes require {bf:proportions(p1 p2)} and {bf:win({it:winoption})}. {bf:p1} and {bf:p2} are the expected proportion with the event in the intervention and control groups respectively. {bf:winoption} will be either {bf:noevent} or
{bf:event} to indicate whether a win is represented by not having the event, or having the event, respectively. 

{p 8 8 2}
{bf:continuous} outcomes require {bf:means(m1 m2)} , {bf:sd(s1 s2)} and  {bf:win({it:winoption})}. 
{bf:m1} and {bf:m2} are the expected means in the intervention and control groups respectively. 
{bf:s1} and {bf:s2} are the expected standard deviations in the intervention and control groups respectively. 
{bf:winoption} will be either {bf:lower} or {bf:higher} to indicate whether a win is represented by lower values, or higher values, respectively. 
{bf:margin(#)} can be used to specify that a margin of success of size # will be required for a win. 
Caclulations are based on the assumption that the continuous outcome is normally distributed. The sample size calculator will not work as expected if this assumption is not (approximately) met.  

{p 8 8 2}
{bf:repeat event} outcomes require {bf:means(m1 m2)} and {bf:win({it:winoption})}.
{bf:dispersion(d)} is optional with a default value for {bf:d} of 0.
{bf:m1} and {bf:m2} are the expected mean event rates in the intervention and control groups respectively. 
{bf:winoption} will be either {bf:fewer} or {bf:more} to indicate whether a win is represented by having fewer, or more events, respectively. 
{bf:d} is the expected dispersion. Repeat events are assumed to follow a negative binomial model. The dispersion parameter represents the degree of over-dispersion.
The negative binomial model can be written as a Gamma-Poisson mixture, and dispersion represents the variance of the gamma distribution. Larger values imply a greater tendency for events to cluster in high-risk patients. The default value is 0, 
implying no overdispersion (i.e. events do not cluster at all
and follow a Poisson distribution) - whether or not this is realistic depends on the specific application. 

{p 8 8 2}
{bf:time-to-event} outcomes (whether ts or tf) require {bf:eventprob(p)} and {bf:hr(hr)}. 
{bf:p} is the expected event probability in the control group. 
{bf:hr} is the expected hazard ratio. For a treatment benefit we require hr<1 for {bf:tf} and hr>1 for {bf:ts}. 


{phang}
{bf: power} is the required power for the trial and must lie between 0 and 1. {bf:power(0.8)} i.e. 80% power, is the default. 

{phang}
{bf: n} is the total sample size; required when computing power for a given sample size. 

{phang}
{bf: alpha} is the required significance level for the trial, and must lie between 0 and 1. {bf:alpha(0.05)} i.e. 5% significance level, is the default. 

{phang}
{bf: nratio} is the ratio of sample sizes, N2/N1. {bf:nratio(1)} i.e. 1:1 randomisation, is the default. 


 
{marker examples}{...}
{title:Examples}

{p 4 4 2}
{bf:Example 1:}
Consider a trial with 3 prioritised outcomes, (i) time-to-death (ii) number of heart failure hospitalisation and (iii) change in KCCQ score (a continuous measure of quality of life). 

{pstd}
Suppose we expect: (i) 20% of patients in the control group will die, and that the hazard ratio for the experimental arm is 0.9. 
(ii) There will be an average of 0.5 heart failure hospitalisations per patient in the experimental arm and 0.7 in the control arm.
There will be moderate clustering of heart failure hospitalisations such that the dispersion parameter is set to 1. 
(iii) KCCQ score will improve by on average 15 in the experimental arm and 10 in the control arm.
The standard deviation of the change in KCCQ score will be 20 in both arms. 

{pstd}
If we wish to calculate the sample size required for 85% power in such a study at a 5% significance level, the command syntax would be:  

{pstd}
{cmd: winratiopower , outcome(tf eventprob(0.2) hr(0.9)) outcome(r mean(0.5 0.7) win(fewer) dispersion(1)) outcome(c mean(15 10) sd(20 20) win(higher)) power(0.85) } 

{marker savedresults}{...}
{title:Saved results}

{pstd}
{cmd:winratiopower} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(sigma^2)}} sigma^2 as defined in Yu and Ganju {cmd:[3]}. The variance of the log win ratio will be approximately equal to sigma^2/N{p_end}
{synopt:{cmd:r(N)}} Total number of patients required{p_end}
{synopt:{cmd:r(winratio)}} True win ratio under user-provided assumptions{p_end}
{synopt:{cmd:r(wins)}} Expected proportion of wins{p_end}
{synopt:{cmd:r(losses)}} Expected proportion of losses{p_end}
{synopt:{cmd:r(ties)}} Expected proportion of ties{p_end}
{synopt:{cmd:r(wins#)}} Expected proportion of wins at level #{p_end}
{synopt:{cmd:r(losses#)}} Expected proportion of losses at level #{p_end}
{synopt:{cmd:r(ties#)}} Expected proportion of ties at level #{p_end}
{synopt:{cmd:r(power)}} Estimated power for given sample size (if n is specified) {p_end}

{marker references}{...}
{title:References}

{phang}
1. Pocock SJ, Ariti CA, Collier TJ, Wang D. The win ratio: a new approach to the analysis of composite endpoints in clinical trials based on clinical priorities. {it:Eur Heart J} 2012;33:176–182.

{marker C1985}{...}
{phang}
2. Finkelstein DM, Schoenfeld DA. Combining mortality and longitudinal measures in clinical trials. {it:Stat Med} 1999;18:1341–1354.


{phang}
3. Yu RX, Ganju J. Sample size formula for a win ratio endpoint. {it:Stat Med} 2022 Mar 15;41(6):950-963.
{p_end}



{marker authors}{...}
{title:Authors}

{phang}Tim Collier, Medical Statistics Department, London School of Hygiene and Tropical Medicine, tim.collier@lshtm.ac.uk
{phang}John Gregson, Medical Statistics Department, London School of Hygiene and Tropical Medicine, john.gregson@lshtm.ac.uk

