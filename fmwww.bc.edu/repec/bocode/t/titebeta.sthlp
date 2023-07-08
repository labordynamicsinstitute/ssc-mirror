{smcl}
{* *! version 1.0  June 27, 2023}{...}
{cmd:help titebeta} 
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:titebeta} {hline 2}}Bayesian toxicity monitoring with Beta prior and censored event data{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 15 2}
{cmdab:titebeta}
{toxicity variable 0/1}
{elapsed time variable} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required, but the routine will run with default values}
{synopt :{opt maxt:ime}}Maximum Time, end of observation period{p_end}
{synopt :{opt tox:rate}}Target toxicity rate{p_end}
{synopt :{opt a}}Parameter "a" for the beta prior{p_end}
{synopt :{opt b}}Parameter "b" for the beta prior{p_end}
{synopt :{opt pprb:ound}}Posterior probability bound/limit{p_end}

{syntab:Truly Optional: alternate specification of weights}
{synopt :{opt userwt(varname)}}User supplied weights from data{p_end}
{synopt :{opt wtpwr(real>0)}}Power applied to weight, skews importance early or late{p_end}
{synoptline}




{title:Description}

{pstd}
{opt titebeta} is a routine for safety monitoring of late onset toxicities in phase 2 (and 3) clinical 
trials.  It calculates the posterior probability that the toxicity event rate exceeds a limit, 
based on censored data for toxicities and a beta prior.  Data are entered as a list of two variables, 
with the first {depvar} being a 0/1 toxicity outcome, and the second {indepvar} being an elapsed 
time variable. The calculation uses the weighting scheme described by Cheung & Thall (2002), for the simple 
case that considers only toxicity monitoring, and not complex trial outcomes.{p_end}  

{pstd}
The routine requires several pre-defined values in order to run.  These may be user supplied, but the routine 
will run based on default values.  Weights are generally thought of as a proportion of information on 
toxicity for a given patient based on time elapsed, and are, by default, calculated as time/maxtime, with a 
maximum value of 1.0.  Weighting can accommodate other patterns of information accrued over time, either 
by user-supplied weights, or by a parameter that skews toxicity events later or earlier within the observation 
window.{p_end}

{pstd}
The routine imports the data into MATA, and uses the quadrature function in MATA to integrate the PDF (from 
the beta prior and Cheung & Thall's Likelihood. The routine reports the posterior probability that the true 
toxicity rate exceeds the target rate, and by referencing the specified upper limit, makes a recommendation 
to either continue accrual or stop.{p_end}




{title:Options}

{dlgtab:Required Parameter Values}

{phang}
{opt maxtime(real)}: This is the length of the observation time window for recording toxicity 
events.  It is used for calculating the simple weight proportional to time elapsed.  It can take on any 
positive value, to match whatever time scale is used.  The default value is 180, implying 6 months of 
daily observation.  Make sure that this value matches the scale of the elapsed time variable entered.

{phang}
{opt toxrate(real)}: This is the maximum allowable true toxicity rate.  This may be a value that comes from 
phase 1 trials.  It can fall between 0 and 1, although values above 0.4 and below 0.1 will be of little use or 
meaning.  The default value is 0.3, a common default toxicity rate from phase 1 trials.

{phang}
{opt a(real)} and {opt b(real)}: The parameters "a" and "b" define the beta(a,b) prior distribution.  Both are 
real numbers greater than zero, and our defaults are a=1 and b=2, which is a common start for toxicity monitoring.  
The mean value for the prior is a/(a+b). You can get to the desired mean in infinte ways, but making a and b 
smaller will tend to put more weight in the tails, and making them larger will add more weight towards the mean value.

{phang}
{opt pprbound(real)}: The routine titebeta returns the posterior probability that the true toxicity rate exceeds 
the target value (toxrate).  The parameter pprbound is the maximum allowable value for that posterior probability 
before haltinng the trial.  The range can be 0 to 1, but numbers in the range of 0.75 to 0.95 make sense and are 
in common use.  The default is 0.9.

{dlgtab:Alternate Weighting (Use only one of these)}

{phang}
{opt userwt(varname)}: This is a variable name for user supplied weights from data set.  If a variable name is 
entered, the routine will use the user supplied weights rather than calculating them.  This will be useful if there
is a known time pattern to the occurrence of toxicity events for the trial agent. There is no default.  If not supplied, 
the routine will calculate weights.  

{phang}
{opt wtpwr(real)}: This provides a simple way to skew the weighting to earlier or later in the observation window, by 
taking the calculated weight and applying wtpwr as an exponent.  The default value is 1.0, meaning no change.  It 
can take on any value greater than zero; values below 1.0 provide more information earlier in the observation window, 
while values above 1.0 delay the information to the later part of the window.


{title:Examples}

{pstd}Setup{p_end}

{phang2}{cmd:. list}{p_end}

     +----------------------+
     | pid   toxicity   tte |
     |----------------------|
  1. |   1          0   181 |
  2. |   2          0   181 |
  3. |   3          1   168 |
  4. |   4          0   181 |
  5. |   5          1    98 |
     |----------------------|
  6. |   6          0   181 |
  7. |   7          1   141 |
  8. |   8          0   179 |
  9. |   9          0   102 |
 10. |  10          0    42 |
     |----------------------|
 11. |  11          0    24 |
 12. |  12          0     3 |
     +----------------------+

{pstd}Entering varlist: toxicity tte, and setting the observation window to 181 days.{p_end}

{phang2}{cmd:. titebeta toxicity tte, maxt(181)}

{pstd}Also changing target toxicity rate to 0.25.{p_end}

{phang2}{cmd:. titebeta toxicity tte, maxt(181) tox(.25)}

{pstd}Also changing the maximum permissible posterior probability of exceeding toxrate to 0.85 from default 0.9.{p_end}

{phang2}{cmd:. titebeta toxicity tte, maxt(181) tox(.25) pprb(.85)}

{pstd}Also changing the maximum permissible posterior probability of exceeding toxrate to 0.7 from default 0.9.{p_end}

{phang2}{cmd:. titebeta toxicity tte, maxt(181) tox(.25) pprb(.7)}



{title:Saved results}

{pstd}
{cmd:titebeta} saves the following r-class results.{p_end}

{pstd}scalars:{p_end}
              r(pprob): "Posterior probability that toxicity rate exceeds limit"
       r(weight_power): "Power (exponent) on time elapsed / maxtime user weight"
            r(max_ppr): "Maximum value for the posterior probability before stopping the study"
             r(toxmax): "Target upper limit for toxicity rate"
            r(maxtime): "Time limit- End of the toxicity observation window"
             r(beta_b): "Beta prior, parameter a"
             r(beta_a): "Beta prior, parameter b"

{pstd}macros:{p_end}
            r(timevar): "Variable name- time elapsed"
             r(toxvar): "Variable name- toxicity event (0/1)"
             r(toxvar): "Variable name- User provided weights"
           r(decision): "Decision to continue or halt"


{title:Author}

{pstd}
E. Paul Wileyto{p_end}
{pstd} epw@pennmedicine.upenn.edu{p_end}

{title:Also see}
{psee}
Cheung, Y.K. and Thall, P.F. (2002), Monitoring the Rates of Composite Events with Censored Data in Phase II Clinical Trials. Biometrics, 58: 89-97. {browse "https://doi.org/10.1111/j.0006-341X.2002.00089.x": article}



{p_end}
