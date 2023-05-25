{smcl}
{* *! version 1.13 23may2023}{...}
{* 23dec2014}{...}
{vieweralsosee "sampsi (if installed)" "sampsi"}{...}
{viewerjumpto "Definitions and usage" "artbindlg##def"}{...}
{viewerjumpto "Combination of options" "artbindlg##combinationsofoptions"}{...}
{viewerjumpto "Examples" "artbindlg##examples"}{...}
{viewerjumpto "References" "artbindlg##refs"}{...}
{viewerjumpto "Citation" "artbindlg##citation"}{...}
{viewerjumpto "Authors" "artbindlg##authors"}{...}
{viewerjumpto "Also see" "artbindlg##alsosee"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:artbindlg} {hline 2}}ART (Binary Outcomes) - Sample Size and Power dialog{p_end}
{p2colreset}{...}

{marker def}{...}
{title:Definitions and usage}

{p 0 4}
{cmd:Anticipated probabilities} specifies the anticipated probabilities to be compared. {it: pi1^a} is the anticipated probability in the control
group and {it: pi2^a}, {it:pi3^a}, ... are the anticipated probabilities in the
treatment groups.
{p_end}

{p 0 4}
{cmd:Margin (NI/SS only)} is used with two-group trials and must be specified if a non-inferiority or
substantial-superiority trial is being designed. The default margin is {it:# = 0},
denoting a superiority trial.  If the event of interest is unfavourable, the null hypothesis
for all these designs is {it:pi2 – pi1 >= m}, where {it:m} is the
pre-specified margin. The alternative hypothesis is {it:pi2 – pi1 < m}.
{it:m > 0} denotes a non-inferiority trial, whereas {it:m < 0} denotes
a substantial-superiority trial.  If on the other hand the event of interest is favourable, the above
inequalities are reversed. The null hypothesis for all these designs
is then {it:pi2 – pi1 <= m} and the alternative hypothesis is
{it:pi2 – pi1 > m}. {it:m < 0} denotes a non-inferiority trial,
while {it:m > 0} denotes a substantial-superiority trial.
The hypothesised margin for the difference in anticipated probabilities, {it:#}, must lie
between -1 and 1. 
{p_end}

{p 0 4}
{cmd:Favourable or Unfavourable} are used with two-group trials
to specify whether the outcome is {opt favourable} or {opt unfavourable}.
If either option is used, {cmd:artbin} checks the assumptions;
otherwise, it infers the favourability status.  Both American and 
English spellings are allowed.
{p_end}

{p 0 4}
{cmd:Power or N} Power is the power of the trial, N is the total sample size 
(all groups combined). When using Menu, the radio buttons allow you to choose 
whether the program will display the power for given N or the N for specified 
power.
{p_end}

{p 0 4}
{cmd:Allocation ratios} By default, all groups are assumed of equal size, so
			the allocation ratios (more precisely, weights) are
			all equal to 1. You can very this, e.g. 1 2 2 would
			specify that groups 2 and 3 should have twice as many
			patients allocated as group 1.
{p_end}

{p 0 4}
{cmd:Trend} Allows a linear trend test across the groups, with
			scores 1, 2, 3,... attached to the groups. A trend
			test may be more powerful than a general comparison
			between the groups. See also {opt dose}.
{p_end}

{p 0 4}
{cmd:Dose} A quantity assigned to each group which represents the 
dose of some medication or other measure of the level of the treatment 
received by the subjects in that group. If you specify a dose level for any 
group, you must specify a level for every group. A {opt trend} test is assumed with 
score proportional to the dose levels.
{p_end}

{p 0 4}
{cmd:Loss to follow-up} Adjusts for the total percentage of patients lost to follow-up, 
expressed as a decimal number between 0 and 1.  For example if the total anticipated loss 
to follow-up is 20%, then 0.2 should be inputted.
{p_end}

{p 0 4}
{cmd:Alpha} (default 0.05 two-sided test) Alpha is the significance level 
(an upper bound for type I error probability).
{p_end}

{p 0 4}
{cmd:One-sided test} is used for two-group trials and for trend tests in multi-group trials. 
It specifies that the significance level given by {opt alpha()} is one-sided. 
Otherwise, the value of {opt alpha()} is halved to give a one-sided significance level. 
Thus for example {opt alpha(0.05)} is exactly the same as {opt alpha(0.025)} {opt onesided}.
{p_end}

{p 0 4}
{cmd:Conditional test (Peto)} specifies that the trial will be analysed using Peto's conditional test. 
This test conditions on the total number of events observed and is based on Peto's local approximation 
to the log odds ratio.  This option is also likely to be a good approximation
with other conditional tests.  The default is the usual Pearson chisquare test. 
{p_end}

{p 0 4}
{cmd:Continuity correction} specifies that the trial will be analysed using a continuity correction. The default is no continuity correction.
{p_end}

{p 0 4}
{cmd:Score test (default)} This is the default test used.  Alternatively the {opt wald} test can be used.
{p_end}

{p 0 4}
{cmd:Wald} specifies that the trial will be analysed using the Wald test.
The default is the usual Pearson chisquare test.
{p_end}

{p 0 4}
{cmd:Local alternatives} specifies that the calculation should use the variance of the difference in proportions only under the null.
This approximation is valid when the treatment effect is small. 
The default uses the variance of the difference in proportions both under the null and under the alternative hypothesis.  
The local method is not recommended and is only included to allow comparisons with other software.
{p_end}

{p 0 4}
{cmd:Do not round} prevents rounding of the calculated sample size in each arm
up to the nearest integer. The default is to round.
{p_end}

{marker combinationsofoptions}{...}
{title:Combinations of options not allowed/uncoded which will result in error/warning messages}

{p 0 4}
Non-inferiority/substantial-superiority design with conditional test or trend.
{p_end}
{p 0 4}
Conditional test and non-local alternatives.
{p_end}
{p 0 4}
Conditional test and wald test.
{p_end}
{p 0 4}
Wald test and local alternatives.
{p_end}
{p 0 4}
Continuity correction and the conditional case.
{p_end}
{p 0 4}
Also an error message will be produced for > 2 groups if the user specifies less numbers
in {opt aratios()} than in {opt pr()}.

{marker examples}{...}
{title:Examples}

{hi:Example 1}

Anticipated probabilities  0.2 0.3      Margin (NI/SS only)     0
Favourable                 Yes          Allocation ratios	[Default]
Specify power		   Yes          Power or N		0.8	
Alpha			   0.05         One-sided test	        No 
Trend		           No           Dose                    Ltfu   

    
Score test (default)  Yes   Wald test No   Local alternatives No   Conditional test No  
Continuity Correction No    Do not round No
             
{hi:Result}

. artbin, pr(0.2 0.3) alpha(0.05) power(0.8) fav

ART - ANALYSIS OF RESOURCES FOR TRIALS (binary version 2.0.2 23may2023)
------------------------------------------------------------------------------
A sample size program by Abdel Babiker, Patrick Royston, Friederike Barthel, 
Ella Marley-Zagar and Ian White
MRC Clinical Trials Unit at UCL, London WC1V 6LJ, UK.
------------------------------------------------------------------------------
Type of trial                          superiority
Number of groups                       2
Favourable/unfavourable outcome        favourable
Allocation ratio                       equal group sizes
Statistical test assumed               unconditional comparison of 2
                                        binomial proportions
                                        using the score test
Local or distant                       distant
Continuity correction                  no

Anticipated event probabilities        0.200  0.300 

Alpha                                  0.050 (two-sided)
                                       (taken as .025 one-sided)
Power (designed)                       0.800

Total sample size (calculated)         588

Sample size per group (calculated)     294 294
Expected total number of events        147.00   
------------------------------------------------------------------------------


Machin et. al. 2008 (Table 3.1, p. 38) gives n = 294 per group.


{hi:Example 2}

Anticipated probabilities  0.1 0.2 0.3 0.4  Margin (NI/SS only)  [Default]
Favourable                 n/a              Allocation ratios	 [Default]
Specify power		   Yes              Power or N		 0.9	
Alpha			   0.05             One-sided test	 No 
Trend		           No               Dose                 Ltfu    

    
Score test (default)  Yes   Wald test No   Local alternatives Yes   Conditional test No  
Continuity Correction No    Do not round No

{hi:Result}

. artbin, pr(0.1 0.2 0.3 0.4) local alpha(0.05) power(0.9)

ART - ANALYSIS OF RESOURCES FOR TRIALS (binary version 2.0.2 23may2023)
------------------------------------------------------------------------------
A sample size program by Abdel Babiker, Patrick Royston, Friederike Barthel, 
Ella Marley-Zagar and Ian White
MRC Clinical Trials Unit at UCL, London WC1V 6LJ, UK.
------------------------------------------------------------------------------
Type of trial                          superiority
Number of groups                       4
Favourable/unfavourable outcome        not determined
Allocation ratio                       equal group sizes
Statistical test assumed               unconditional comparison of 4
                                        binomial proportions
                                        using the score test
Local or distant                       local
Continuity correction                  no

Anticipated event probabilities        0.100 0.200 0.300 0.400

Alpha                                  0.050 (two-sided)
Power (designed)                       0.900

Total sample size (calculated)         216

Sample size per group (calculated)     54 54 54 54
Expected total number of events        54.00    
------------------------------------------------------------------------------


{hi:Example 3}

As Example 2 but with Trend checked (doses unspecified)

. artbin, pr(0.1 0.2 0.3 0.4) local alpha(0.05) power(0.9) trend

ART - ANALYSIS OF RESOURCES FOR TRIALS (binary version 2.0.2 23may2023)
------------------------------------------------------------------------------
A sample size program by Abdel Babiker, Patrick Royston, Friederike Barthel, 
Ella Marley-Zagar and Ian White
MRC Clinical Trials Unit at UCL, London WC1V 6LJ, UK.
------------------------------------------------------------------------------
Type of trial                          superiority
Number of groups                       4
Favourable/unfavourable outcome        not determined
Allocation ratio                       equal group sizes
Statistical test assumed               unconditional comparison of 4
                                        binomial proportions
                                        using the score test
Local or distant                       local
Continuity correction                  no
Linear trend test: doses are           1, 2, 3, 4

Anticipated event probabilities        0.100 0.200 0.300 0.400

Alpha                                  0.050 (two-sided)
Power (designed)                       0.900

Total sample size (calculated)         160

Sample size per group (calculated)     40 40 40 40
Expected total number of events        40.00    
------------------------------------------------------------------------------


{hi:Example 4}

As Example 1 but assuming a non-inferiority design and wald test

Anticipated probabilities  0.2 0.2      Margin (NI/SS only)     0.1
Unfavourable               Yes          Allocation ratios	[Default]
Specify power		   Yes          Power or N		0.8	
Alpha			   0.05         One-sided test	        No 
Trend		           No           Dose                    Ltfu   

    
Score test (default)  No   Wald test Yes   Local alternatives No   Conditional test No  
Continuity Correction No    Do not round No

. artbin, pr(0.2 0.2) margin(0.1) alpha(0.05) power(0.8) unf wald

ART - ANALYSIS OF RESOURCES FOR TRIALS (binary version 2.0.2 23may2023)
------------------------------------------------------------------------------
A sample size program by Abdel Babiker, Patrick Royston, Friederike Barthel, 
Ella Marley-Zagar and Ian White
MRC Clinical Trials Unit at UCL, London WC1V 6LJ, UK.
------------------------------------------------------------------------------
Type of trial                          non-inferiority
Number of groups                       2
Favourable/unfavourable outcome        unfavourable
Allocation ratio                       equal group sizes
Statistical test assumed               unconditional comparison of 2
                                        binomial proportions
                                        using the wald test
Local or distant                       distant
Continuity correction                  no
Null hypothesis H0:                    H0: pi2 - pi1 >= .1
Alternative hypothesis H1:             H1: pi2 - pi1 < .1

Anticipated event probabilities        0.200  0.200 

Alpha                                  0.050 (two-sided)
                                       (taken as .025 one-sided)
Power (designed)                       0.800

Total sample size (calculated)         504

Sample size per group (calculated)     252 252
Expected total number of events        100.80   
------------------------------------------------------------------------------


{marker refs}{...}
{title:References}

{phang}
Machin, D., Campbell, M.J., Tan S.B. and Tan S.H. 2008. Sample Size Tables for Clinical Studies, Third Edition. Wiley.

{marker citation}{...}
{title:Citation}

{phang}If you find this command useful, please cite it as below: 

{phang}Ella Marley-Zagar, Ian R. White, Patrick Royston, Friederike M.-S. Barthel, Mahesh K B Parmar, Abdel G. Babiker. artbin: Extended sample size for randomised trials with binary outcomes. Stata J 2023:1;24-52.
{browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X231161971"}

{marker authors}{...}
{title:Authors and Updates}

{pstd}Abdel Babiker, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:a.babiker@ucl.ac.uk":Ab Babiker}

{pstd}Friederike Maria-Sophie Barthel, formerly MRC Clinical Trials Unit{break}
{browse "mailto:sophie@fm-sbarthel.de":Sophie Barthel}

{pstd}Babak Choodari-Oskooei, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:b.choodari-oskooei@ucl.ac.uk":Babak Oskooei}

{pstd}Patrick Royston, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:j.royston@ucl.ac.uk":Patrick Royston}

{pstd}Ella Marley-Zagar, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:e.marley-zagar@ucl.ac.uk":Ella Marley-Zagar}

{pstd}Ian White, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:ian.white@ucl.ac.uk":Ian White}

{marker alsosee}{...}
{title:Also see}

{psee}
Manual:  {hi:[R] sampsi}

{psee}
Online:  help for {help artmenu}, {help artbin}
