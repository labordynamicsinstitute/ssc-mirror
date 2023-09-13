{smcl}
{* *! version 5.0.0  02Apr2023}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "sotable##syntax"}{...}
{viewerjumpto "Description" "sotable##description"}{...}
{viewerjumpto "Options" "sotable##options"}{...}
{viewerjumpto "Remarks" "sotable##remarks"}{...}
{viewerjumpto "Examples" "sotable##examples"}{...}
{viewerjumpto "Stored results" "sotable##results"}{...}
{viewerjumpto "Reference" "sotable##reference"}{...}
{title:Title}

{phang}
{bf:sotable} {hline 2} simultaneous-inference output table 

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:sotable}
[{cmd:,}
{{cmd:pnames(}{it:pnames}{cmd:)}|{cmd:pelements(}{it:numlist}{cmd:)}}
{cmd:alternative(}{cmd:two}|{cmd:upper}|{cmd:lower}{cmd:)}
{cmd:normal}
{cmd:draws(}{it:#}{cmd:)} 
{cmd:level(}{it:#}{cmd:)} 
]

{marker description}{...}
{title:Description}

{pstd}
The postestimation command {cmd:sotable} displays an output
table for the parameters of interest that accounts for the multiple
tests and the multiple confidence intervals reported.
{cmd:sotable} can report tests and confidence bands for 
two-sided or one-sided tests hypotheses. 
{p_end}

{pstd}
{cmd:sotable} works after all frequentist estimation commands
that store their results in {cmd:e(b)} and {cmd:e(V)}.
{p_end}

{pstd}
You can use the {cmd:post} option on {help nlcom:nlcom} to perform tests
against values other than zero, as discussed in the examples below.
You can also use the {cmd:post} option on {help margins:margins} and some
other postestimation commands to peform tests about other parameters
of interest, as discussed in the examples below.
{p_end}

{pstd}
{cmd:sotable} uses the max-t method to calculate
adjusted p-values for the individual tests that
each parameter is zero and it uses the max-t method
to calculate a confidence band for all the parameters.
{cmd:sotable} also displays a critical value and p-value
for the overall test that all of the parameters of interest are zero.  
{p_end}

{pstd}
Drukker (2023) provides details and examples for two-sided tests.
Drukker, Henning, and Rashke (2023) provide details and examples for
one-sided tests.
{p_end}

{pstd}
{cmd:sotable} works after any frequentist estimation command whose t statistics
have an asymptotic normal distribution or a t distribution.  It also works
with results created by the {cmd:post} option on {help nlcom:nlcom}, {help margins:margins}, 
{help pwcompare:pwcompare}, and some other postestimation commands.
{p_end}

{marker options}
{title:Options}

{phang}
{cmd:pnames(}{it:pnames}{cmd:)}|{cmd:pelements(}{it:numlist}{cmd:)}}
specifies which parameters will be in the output table. 
Only {cmd:pnames(}{it:pnames}{cmd:)} or {cmd:pelements(}{it:numlist}{cmd:)}
may be specified.  
{p_end}

{p 8 8 2}
{cmd:pnames(}{it:pnames}{cmd:)} specifies a list of parameter names to
include. 
{p_end}

{p 8 8 2}
{cmd:pelements(}{it:numlist}{cmd:)} specifies a numlist of which elements in the
parameter vector to include.
{p_end}

{phang} {cmd:alternative(two|lower|upper)} specifies the alternative hypothesis for each test. The
default of {cmd:alternative(two)} specifies that each test has a two-sided alternative.
{cmd:alternative(lower)} specifies that each test has a lower-tail alternative.
{cmd:alternative(upper)} specifies that each test has a upper-tail alternative.  You can use {help
nlcom:nlcom} with the {cmd:post} option to handle tests that have a mixture of lower-tail and
upper-tail alternatives.

{phang}
{cmd:normal} specifies to use a multivariate-normal distribution to 
calculate the adjusted p-values, the overall critical value, and the   
overall p-value.

{p 8 8 2}
By default, {cmd:sotable} uses the distribution 
used by the command that produced the estimates and the VCE.
{cmd:normal} specifies that {cmd:sotable} use a multivariate 
normal distribution instead of a multivariate t distribution after 
estimators that use a multivariate t distribution.
{p_end}

{phang}
{cmd:draws()} specifies the number of Monte Carlo draws to use in estimating
the sup- Wald critical value. The default is 1,000,000 draws. More draws will
reduce the variance of the estimated adjusted p-values, the overall 
critical value, and the overall p-value.


{phang}
{cmd:level(}{it:#}{cmd:)} specifies the level, a, for the confidence band. The
family-wise error rate is 1 − a/100. The default level is 95. The default
family-wise error rate is .05 = 1 − 95/100. !! fix this!

{marker examples}{...}
{title:Examples}

{pstd}We begin by clearing Stata and setting the seed.  We set the seed
because {cmd:sotable} uses random numbers to approximate probabilities by simulation. {p_end}

{asis}
. clear all

. set seed 1234
{smcl}

{pstd}
For our first example, we use {cmd:regress} to estimate three treatment parameters
using the cattaneo2 dataset used in the manual entry for {help teffects ra:teffects ra}.
We set level 1 (smoking 1-5 daily) as the base level so that we can test the 
hypotheses discussed below.
{p_end}

{asis}
. webuse cattaneo2
(Excerpt from Cattaneo (2010) Journal of Econometrics 155: 138–154)

. regress bweight ib1.msmoke mmarried mage nprenatal fbaby , vce(robust) 

Linear regression                               Number of obs     =      4,642
                                                F(7, 4634)        =      57.87
                                                Prob > F          =     0.0000
                                                R-squared         =     0.0930
                                                Root MSE          =     551.68

------------------------------------------------------------------------------
             |               Robust
     bweight | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
      msmoke |
    0 daily  |   138.1694    35.9219     3.85   0.000     67.74537    208.5934
 6–10 daily  |  -75.77648    46.0649    -1.64   0.100    -166.0856    14.53264
  11+ daily  |  -128.3936   46.51312    -2.76   0.006    -219.5815   -37.20576
             |
    mmarried |   115.0638   21.70724     5.30   0.000     72.50729    157.6203
        mage |  -.5512881   1.811949    -0.30   0.761    -4.103571    3.000995
   nprenatal |   31.17951   2.906257    10.73   0.000     25.48186    36.87716
       fbaby |  -79.34223   17.51574    -4.53   0.000    -113.6814   -45.00304
       _cons |   2897.192   58.14317    49.83   0.000     2783.204     3011.18
------------------------------------------------------------------------------
{smcl}

{pstd}
We want to perform more than one individual hypothesis, so we cannot use
the p-values or the confidence intervals reported.
We need to know the parameter names to use {cmd:sotable}, so
we specify the option {cmd:coeflegend}.
{p_end}

{asis}
. regress bweight ib1.msmoke mmarried mage nprenatal fbaby , vce(robust) coeflegend

Linear regression                               Number of obs     =      4,642
                                                F(7, 4634)        =      57.87
                                                Prob > F          =     0.0000
                                                R-squared         =     0.0930
                                                Root MSE          =     551.68

------------------------------------------------------------------------------
     bweight | Coefficient  Legend
-------------+----------------------------------------------------------------
      msmoke |
    0 daily  |   138.1694  _b[0.msmoke]
 6–10 daily  |  -75.77648  _b[2.msmoke]
  11+ daily  |  -128.3936  _b[3.msmoke]
             |
    mmarried |   115.0638  _b[mmarried]
        mage |  -.5512881  _b[mage]
   nprenatal |   31.17951  _b[nprenatal]
       fbaby |  -79.34223  _b[fbaby]
       _cons |   2897.192  _b[_cons]
------------------------------------------------------------------------------
{smcl}

{pstd}
Now that we know the parameter names, we can use {cmd:sotable} to peform
simultaneous inference on the 3 treatment coefficients. For illustration
purposes, we show how we could use {cmd:sotable} to 
simultaneously test each of the following individual hypotheses:
{p_end}

{asis}
H_{0,1}: b_{0.msmoke}=0 versus H_{a,1}: b_{0.msmoke}!=0
H_{0,2}: b_{2.msmoke}=0 versus H_{a,2}: b_{2.msmoke}!=0
H_{0,3}: b_{3.msmoke}=0 versus H_{a,3}: b_{3.msmoke}!=0
{smcl}

{asis}
. sotable , pnames(0.msmoke 2.msmoke 3.msmoke)

Max-t results
       p-value = 0.000
Critical value = 2.314  
-----------------------------------------------------------------------------
     bweight |      Coef.   Std. Err.      t    P>|t|        [95% Conf. Band]
-------------+---------------------------------------------------------------
  0bn.msmoke |   138.1694    35.9219     3.846  0.000    55.05775   221.2811
    2.msmoke |  -75.77648    46.0649    -1.645  0.214   -182.3557   30.80277
    3.msmoke |  -128.3936   46.51312    -2.760  0.015   -236.0099  -20.77732
-----------------------------------------------------------------------------
{smcl}

{pstd}
We can reject H_{0,1} and H_{0,3} at the .05 level, because their adjusted
p-values are less than .05.  We cannot reject H_{0,2}, because it's adjusted
p-values is greater than .05.  The overall null hypothesis is that all three
of the coefficients are zero versus the alternative that at least one of them
is not zero.  We reject the overall null hypothesis at the .05 level, because 
the p-value for the overall test is less than .05.
{p_end}

{pstd}
Insteading of testing against zero, the following hypotheses are more interesting
in this case.
{p_end}

{asis}
HH_{0,1}: b_{0.msmoke}<=0 versus HH_{a,1}: b_{0.msmoke}>=0
HH_{0,2}: -b_{2.msmoke}<=0 versus HH_{a,2}: -b_{2.msmoke}>=0
HH_{0,3}: -b_{3.msmoke}<=0 versus HH_{a,3}: -b_{3.msmoke}>=0
{smcl}

{pstd}
HH_{0,1} specifies that the effect of going from 1-5 cigarettes  to 0 cigarettes
is not greater than zero.
HH_{0,2} specifies that the effect of going from 1-5 cigarettes  to 6-10 cigarettes
is not less than zero.
HH_{0,3} specifies that the effect of going from 1-5 cigarettes  to 11+ cigarettes
is not less than zero.  We begin by using {help nlcom:nlcom} with the post option
to put the transformed parameters and their VCE into e(b) and e(V).
{p_end}

{asis}
. nlcom (_b[0.msmoke]) (-1*_b[2.msmoke]) (-1*_b[3.msmoke]) , post

       _nl_1: _b[0.msmoke]
       _nl_2: -1*_b[2.msmoke]
       _nl_3: -1*_b[3.msmoke]

------------------------------------------------------------------------------
     bweight | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       _nl_1 |   138.1694    35.9219     3.85   0.000     67.76377     208.575
       _nl_2 |   75.77648    46.0649     1.64   0.100    -14.50906     166.062
       _nl_3 |   128.3936   46.51312     2.76   0.006     37.22957    219.5577
------------------------------------------------------------------------------
{smcl}

{pstd}
We can now use {cmd:sotable} with the option {cmd:alternative(upper)} to test
the multiple null hypotheses.
{p_end}

{asis}
. sotable , alternative(upper)

Max-t results
       p-value = 0.000
Critical value = 2.381  
-----------------------------------------------------------------------------
     bweight |      Coef.   Std. Err.      z    P>|z|      [97.5% Conf. Band]
-------------+---------------------------------------------------------------
       _nl_1 |   138.1694    35.9219     3.846  0.000    52.64597          .
       _nl_2 |   75.77648    46.0649     1.645  0.137   -33.89555          .
       _nl_3 |   128.3936   46.51312     2.760  0.008    17.65444          .
-----------------------------------------------------------------------------
{smcl}

{pstd}
Because each test is upper-tailed, we use a significance level of .025 instead
of .05.  See Drukker, Henning, and Rashke (2023) for a discussion of this 
point.  Using the adjusted p-values computed by {cmd:sotable}, we can reject
HH_{0,1} and HH_{0,3}, but we cannot reject HH_{0,2}.
{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:sotable} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt: {cmd: r(df_r)}} degrees of freedom for t distribution{p_end}
{synopt:  } (when Wald stats have t distribution){p_end}
{synopt: {cmd: r(draws)}}  number of draws used in simulation{p_end}
{synopt: {cmd: r(c)}}  critical value{p_end}
{synopt: {cmd: r(p)}}  p-value of overall test{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt: {cmd:r(alternative)}} {cmd:two} | {cmd:upper} | {cmd:lower}{p_end}
{synopt: {cmd:r(level)}} level{p_end}
{synopt: {cmd:r(dist)}} {cmd:t} or {cmd:z} {p_end}
{synopt: {cmd:r(nmethod)}} {cmd:simulation}{p_end}
{synopt: {cmd:r(method)}} {cmd:maxt} | {cmd:scomparison}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt: {cmd:r(results)}} adjusted p-values, t statistics {p_end}
{synopt: } and confidence band{p_end}
{p2colreset}{...}


{marker reference}{...}
{title:Reference}
{phang}
David M. Drukker. 2023. Simultaneous confidence bands for Stata
estimation commands. Forthcoming in the Stata Journal. 
https://www.researchgate.net/publication/355165242_Simultaneous_tests_and_confidence_bands_for_Stata_estimation_commands
{p_end}

{phang}
Drukker, David M. and Kevin Henning and Christian Rashke 2023.
Tests and confidence bands for multiple one-sided comparisons.
Submitted to the Stata Journal. 
https://www.researchgate.net/publication/369619321_Tests_and_confidence_bands_for_multiple_one-sided_comparisons
{p_end}
