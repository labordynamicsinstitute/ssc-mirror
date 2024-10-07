{smcl}
{* *! version 1.0.0 26Sep2024}{...}
{title:Title}

{p2colset 5 18 19 2}{...}
{p2col:{hi:csumchart} {hline 2}} Cumulative sum (CUSUM) charts for monitoring clinical performance {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Non-risk-adjusted CUSUM

{p 8 14 2}
{cmd:csum}
{it:{help varname:yvar}} 
{it:{help varname:xvar}}
{ifin}
,
{opt blp:rob(#)}
[
{opt odds(#)}
{opt lim:it(#)}
{opt r:eps(#)}
{opt seed(#)}
{opt cen:tile(#)}
{opt w:t}{cmd:(}{it:{help varname:varname}{cmd:})}
{opt repl:ace} 
{opt no:graph} 
{it:{help twoway_options:twoway_options}}
]

{pstd}
Compute control limit for risk-adjusted CUSUM

{p 8 14 2}
{cmd:csumralimit}
{it:{help varname:riskscore}} 
{ifin}
[, 
{opt odds(#)}
{opt r:eps(#)}
{opt seed(#)}
{opt cen:tile(#)}
{opt l:ocal(macname)} 
]

{pstd}
Risk-adjusted CUSUM

{p 8 14 2}
{cmd:csumra}
{it:{help varname:yvar}} 
{it:{help varname:xvar}}
{ifin}
,
{opt risk(varname)}
{opt lim:it(#)}
[ 
{opt odds(#)}
{opt w:t}{cmd:(}{it:{help varname:varname}{cmd:})}
{opt repl:ace} 
{opt no:graph} 
{it:{help twoway_options:twoway_options}}
]

{pstd}
{it:yvar} variable must be binary{p_end}
{pstd}
{it:riskscore} variable must contain values between 0 and 1 {p_end}


{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:csum}
{synopt :{opt blp:rob(#)}}baseline probability of failure (e.g. death, hospitalization); {cmd:blprob() is required}{p_end}
{synopt :{opt odds(#)}}odds of failure; default is to detect a doubling of the odds of failure {cmd:odds(2)}{p_end}
{synopt :{opt lim:it(#)}}control limit for signaling a change in performance; default is for {cmd:csum} to compute the limit using simulation{p_end}
{synopt :{opt r:eps(#)}}number of replications to be performed when computing {opt limit()}; default is {cmd:reps(50)}{p_end}
{synopt :{opt seed(#)}}set random-number seed to # when computing {opt limit()} using simulation {p_end}
{synopt :{opt cen:tile(#)}}set centile level for computing {opt limit()} using simulation; default is {cmd:centile(95)} {p_end}
{synopt :{opt w:t(varname)}}weights used for computing {opt CUSUM}; default is for {cmd:csum} to compute the weights{p_end}
{synopt :{opt repl:ace}}replace variables created by {cmd:csum}{p_end}
{synopt :{opt no:graph}}suppresses the plot {p_end}
{synopt :{it:{help twoway_options:twoway_options}}}any options documented in {manhelpi twoway_options G-3}{p_end}

{syntab:csumralimit}
{synopt :{opt odds(#)}}odds of failure; default is to detect a doubling of the odds of failure {cmd:odds(2)}{p_end}
{synopt :{opt r:eps(#)}}number of replications to be performed when computing {opt limit()}; default is {cmd:reps(50)}{p_end}
{synopt :{opt seed(#)}}set random-number seed to # when computing {opt limit()} using simulation {p_end}
{synopt :{opt cen:tile(#)}}set centile level for computing {opt limit()} using simulation; default is {cmd:centile(95)} {p_end}
{synopt:{opt l:ocal(macname)}}stores the control limit in local macro {it:macname}, making it accessible for later use.{p_end}

{syntab:csumra}
{synopt :{opt risk(varname)}}variable containing the risk-adjusted predictions of the {it:yvar}; {cmd:risk() is required}{p_end}
{synopt :{opt lim:it(#)}}control limit for signaling a change in performance; the {opt limit(#)} can be computed using 
{opt csumralimit}; {cmd:limit(#) is required}{p_end}
{synopt :{opt odds(#)}}odds of failure; default is to detect a doubling of the odds of failure {cmd:odds(2)}{p_end}
{synopt :{opt w:t(varname)}}weights used for computing {opt CUSUM}; default is for {cmd:csumra} to compute the weights{p_end}
{synopt :{opt repl:ace}}replace variables created by {cmd:csumra}{p_end}
{synopt :{opt no:graph}}suppresses the plot {p_end}
{synopt :{it:{help twoway_options:twoway_options}}}any options documented in {manhelpi twoway_options G-3}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{marker description}{...}
{title:Description}

{pstd}
The {opt csumchart} package produces risk-adjusted and non-risk-adjusted cumulative sum (CUSUM) charts for monitoring clinical 
performance over time, by signaling if sufficient evidence has accumulated to detect a change in the failure rate of 
the outcome (Steiner et al. 2000). The CUSUM procedure requires a binary {it:yvar} (where a value of 1 indicates failure 
and 0 indicates success), and a sequential {it:xvar} which typically represents sequential patient numbers or the passage 
of time. In the case of risk-adjusted outcomes, an additional variable containing the riskscores is required. 
Process deterioration is detected when the CUSUM exceeds the {it:a priori} control limit in the positive direction. 
Similarly, process improvement is detected when the CUSUM exceeds the {it:a priori} control limit in the negative direction. See 
Steiner et al. (2000) for a comprehensive discussion about how CUSUM charts are produced and interpreted.

 

{title:Options}

{p 4 8 2} 
{cmd:blprob(#)} specifies the baseline rate of failure; {cmd:blprob() is required for {cmd:csum}}. 

{p 4 8 2} 
{cmd:risk(varname)} specifies the risk-adjusted predictions of the {it:yvar}; {cmd:risk(varname) is required for {cmd:csumra}}. 

{p 4 8 2} 
{cmd:odds(#)} specifies the odds ratio used to detect a change in the outcome (e.g. death). For example, {cmd:odds(2)} is designed to detect
a doubling in the odds of failure (process deterioration), whereas {cmd:odds(.50)} is designed to detect halving the odds of failure 
(process improvement).

{p 4 8 2} 
{cmd:limit(#)} specifies the control limit. The point on the {it:xvar} where the CUSUM first exceeds the control limit is the start of 
the process being "out of control". The control limit may be guided by external expectations or regulatory requirements, or it can be
determined empirically using simulation. When {cmd:limit(#)} is not specified in {cmd:csum}, or when implementing {cmd:csumralimit} to
compute the limit for risk-adjusted data (to be used in {cmd:csumra}), random data are generated based on existing sample
size, specified odds ratio, and baseline probability of failure (or riskscores). The CUSUM is computed and the maximum CUSUM value is stored. This
process is repeated the number of times specified in {cmd:reps()}. Finally, the value corresponding to the specified {cmd:centile()} 
is computed. This value serves as the control limit. While a positive control limit is used to detect an increase in the failure rate, 
a negative control limit is used to detect a decrease in the failure rate (a negative control limit is used in congunction 
with a {cmd:odds()} below 1.0). 

{p 4 8 2} 
{cmd:reps(#)} the number of replications to be performed when computing {opt limit()} or {opt csumralimit()}; default is {cmd:reps(50)}.

{p 4 8 2} 
{cmd:seed(#)} set random-number seed to # when computing {opt limit()} or {opt csumralimit()} using simulation.

{p 4 8 2} 
{cmd:centile(#)} set centile level for computing {opt limit()} or {opt csumralimit()} using simulation. The default is {cmd:centile(95)} 
for assessing process deterioration and {cmd:centile(5)} for assessing process improvement.

{p 4 8 2}
{cmd:local(}{it:macname}{cmd:)} stores the control limit computed by {cmd:csumralimit} in local macro {it:macname} within the calling program's space, 
thereby making the control limit accessible after {cmd:csumralimit} has finished. This is helpful for later use with {cmd:csumra}.

{p 4 8 2} 
{cmd:wt(varname)} specifies the weights used for computing {opt CUSUM}. The default is for {cmd:csum} and {cmd:csumra} to compute the weights.

{p 4 8 2} 
{cmd:replace} replaces the variables in the file created by {cmd:csum} and {cmd:csumra}. Three variables are created: {cmd:_wt} which is the
weight generated by {cmd:csum} and {cmd:csumra} or a replicate of those specified by the user in {cmd:wt()}; {cmd:_ct} which is the CUSUM; and
{cmd:_signal} which indicates at which point on the {it:xvar} the CUSUM exceeds the control limit.  

{p 4 8 2} 
{cmd:nograph} suppresses the plot.

{p 4 8 2} 
{it:{help twoway_options:twoway_options}} any options documented in {manhelpi twoway_options G-3}


{title:Examples}

{pstd}
{opt (1) Unadjusted CUSUM:}{p_end}

{pstd}{opt Detecting process deterioration (increase in failure rate)}: {p_end}

{pmore} create synthetic data {p_end}
{pmore2}{cmd:. clear}{p_end}
{pmore2}{cmd:. set obs 1000}{p_end}
{pmore2}{cmd:. gen ptid = _n}{p_end}
{pmore2}{cmd:. label var ptid "Patient number"}{p_end}
{pmore2}{cmd:. set seed 1234}{p_end}
{pmore2}{cmd:. gen y = rbinomial(1,.40)}{p_end}
{pmore2}{cmd:. label var y "Deaths"}{p_end}

{pmore} We generate a CUSUM chart to assess whether there was an increased failure 
rate over a sequential number of observations. We set the baseline failure rate
to 0.20 and we set the odds ratio to 2 in order to detect a doubling in the odds of 
failure. We allow {opt csum} to estimate the control limit at the 95th centile using 100 
repetitions. We see that the failure rate exceeds the control limit at patient number 42. {p_end}
{phang2}{cmd:. csum y ptid, blp(0.20) seed(1234) reps(100) centile(95) replace odds(2)}{p_end}


{pstd}{opt Detecting process improvement (decrease in failure rate)}: {p_end}

{pmore} create synthetic data {p_end}
{pmore2}{cmd:. clear}{p_end}
{pmore2}{cmd:. set obs 1000}{p_end}
{pmore2}{cmd:. gen ptid = _n}{p_end}
{pmore2}{cmd:. label var ptid "Patient number"}{p_end}
{pmore2}{cmd:. set seed 1234}{p_end}
{pmore2}{cmd:. gen y = rbinomial(1,.20)}{p_end}
{pmore2}{cmd:. label var y "Deaths"}{p_end}

{pmore} We generate a CUSUM chart to assess whether there was an decreased failure 
rate over a sequential number of observations. We set the baseline failure rate
to 0.40 and we set the odds ratio to 0.50 in order to detect a halving in the odds of 
failure. We allow {opt csum} to estimate the control limit at the 95th centile using 100 
repetitions. We see that the failure rate decreases beyond the control limit at patient 
number 81. {p_end}
{phang2}{cmd:. csum y ptid, blp(0.40) seed(1234) reps(100) centile(95) replace odds(0.50)}{p_end}

{pmore} Here we manually set the limt to -20. {p_end}
{phang2}{cmd:. csum y ptid, blp(0.40) limit(-20) replace odds(.5)}{p_end}


{pstd}
{opt (2) Adjusted CUSUM:}{p_end}

{pstd}{opt Compute control limit using csumralimit on baseline data for assessing process deterioration (increase in failure rate)}: {p_end}

{pmore} create synthetic baseline data {p_end}
{pmore2}{cmd:. clear}{p_end}
{pmore2}{cmd:. set obs 1000}{p_end}
{pmore2}{cmd:. set seed 1234}{p_end}
{pmore2}{cmd:. gen ptid = _n}{p_end}
{pmore2}{cmd:. label var ptid "Patient number"}{p_end}
{pmore2}{cmd:. gen y = rbinomial(1,0.40)}{p_end}
{pmore2}{cmd:. label var y "Deaths"}{p_end}
{pmore2}{cmd:. gen riskscore = cond(y,runiform(0.51,1),runiform(0,0.50))}{p_end}
{pmore2}{cmd:. label var riskscore "Risk-adjusted probability of death"}{p_end}


{pmore} we compute the control limit for a doubling of the odds of death on these baseline data (this 
produces a control limit of 6.260). We save the control limit as a local macro named {cmd:{it:limit1}} so
that it can be used afterwards in {cmd:csumra}. {p_end}
{phang2}{cmd:. csumralimit riskscore , seed(1234) odds(2) reps(1000) local(limit1)} {p_end}
 

{pstd}{cmd:Detecting process deterioration (increase in failure rate) on followup data}: {p_end}

{pmore} create synthetic followup data {p_end}
{pmore2}{cmd:. clear}{p_end}
{pmore2}{cmd:. set obs 1000}{p_end}
{pmore2}{cmd:. set seed 1234}{p_end}
{pmore2}{cmd:. gen ptid = _n}{p_end}
{pmore2}{cmd:. label var ptid "Patient number"}{p_end}
{pmore2}{cmd:. gen y = rbinomial(1,.70)}{p_end}
{pmore2}{cmd:. gen riskscore = cond(y,runiform(0.51,1),runiform(0,0.50))}{p_end}

{pmore} We generate a CUSUM chart to assess whether there was an increased failure 
rate over a sequential number of observations. We set the odds ratio to 2 in order 
to detect a doubling in the odds of failure. We specify the control limit using the
local macro (named {cmd:{it:limit1}}) that was computed in the previous step. We see 
that the failure rate exceeds the control limit at patient 249. {p_end}
{phang2}{cmd:. csumra y ptid , risk(riskscore) limit(`limit1') odds(2) replace} {p_end}


{pstd}{opt Compute control limit using csumralimit on baseline data for assessing process improvement (decrease in failure rate)}: {p_end}

{pmore} create synthetic followup data {p_end}
{pmore2}{cmd:. clear}{p_end}
{pmore2}{cmd:. set obs 1000}{p_end}
{pmore2}{cmd:. set seed 1234}{p_end}
{pmore2}{cmd:. gen ptid = _n}{p_end}
{pmore2}{cmd:. label var ptid "Patient number"}{p_end}
{pmore2}{cmd:. gen y = rbinomial(1,.60)}{p_end}
{pmore2}{cmd:. gen riskscore = cond(y,runiform(0.51,1),runiform(0,0.50))}{p_end}

{pmore} we compute the control limit for a halving of the odds of death on these baseline data which 
produces a control limit of -6.300. We save this value as a local macro named {cmd:{it:limit2}} {p_end}
{phang2}{cmd:. csumralimit riskscore , seed(1234) odds(0.50) reps(1000) local(limit2)} {p_end}


{pstd}{cmd:Detecting process improvement (decrease in failure rate) on followup data}: {p_end}

{pmore} create synthetic followup data {p_end}
{pmore2}{cmd:. clear}{p_end}
{pmore2}{cmd:. set obs 1000}{p_end}
{pmore2}{cmd:. set seed 1234}{p_end}
{pmore2}{cmd:. gen ptid = _n}{p_end}
{pmore2}{cmd:. label var ptid "Patient number"}{p_end}
{pmore2}{cmd:. gen y = rbinomial(1,.30)}{p_end}
{pmore2}{cmd:. gen riskscore = cond(y,runiform(0.51,1),runiform(0,0.50))}{p_end}

{pmore} We generate a CUSUM chart to assess whether there was a decreased failure 
rate over a sequential number of observations. We set the odds ratio to 0.50 in order 
to detect a halving in the odds of failure. We specify the control limit using the 
local macro named {cmd:{it:limit2}}, which was computed in the previous step. 
We see that the failure rate exceeds the control limit at patient 164. {p_end}
{phang2}{cmd:. csumra y ptid , risk(riskscore) limit(`limit2') odds(0.50) replace} {p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:csum}, {cmd:csumra} and {cmd:csumralimit} store the following in {cmd:r()}:

{synoptset 10 tabbed}{...}
{p2col 5 10 14 2: Scalars}{p_end}
{synopt:{cmd:r(limit)}}the control limit{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Steiner, S. H., Cook, R. J., Farewell, V. T. & T. Treasure. 2000. Monitoring surgical performance using risk-adjusted cumulative sum charts. 
{it:Biostatistics} 1: 441-452.{p_end}



{marker citation}{title:Citation of {cmd:csumchart}}

{p 4 8 2}{cmd:csumchart} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2024). CSUMCHART: Stata module to compute cumulative sum (CUSUM) charts for monitoring clinical performance.



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb cusum}{p_end}

