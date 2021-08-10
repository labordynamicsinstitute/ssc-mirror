{smcl}
{* *! version 3.0.0 29sep2014}{...}
{cmd:help nstage}
{hline}


{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:nstage} {hline 2}}Multi-arm, multi-stage (MAMS) trial designs for time-to-event outcomes{p_end}
{p2colreset}{...}


{title:Syntax}

{phang2}
{cmd:nstage,}
{it:required_options optional_options}


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :{it:required}}
{synopt :{opt ac:crue(numlist)}}overall accrual rate per unit time in each stage{p_end}
{synopt :{opt al:pha(numlist)}}one-sided alpha (type 1 error probability) for each stage{p_end}
{synopt :{opt ar:ms(numlist)}}number of arms recruiting at each stage (including control arm){p_end}
{synopt :{opt hr0(# [#])}}target hazard ratio under H0 for the I-outcome and D-outcome{p_end}
{synopt :{opt hr1(# [#])}}target hazard ratio under H1 for the I-outcome and D-outcome{p_end}
{synopt :{opt n:stage(#)}}{it:#} = {it:J}, the number of trial stages{p_end}
{synopt :{opt o:mega(numlist)}}power (one minus type 2 error probability) for each stage{p_end}
{synopt :{opt t(# [#])}}time corresponding to survival probability in {opt s()} for an I-event and a D-event{p_end}

{syntab :{it:optional}}
{synopt :{opt ara:tio(#)}}allocation ratio (number of patients allocated to each experimental arm per control arm patient){p_end}
{synopt :{opt corr(#)}}correlation between treatment effects on I- and D-outcome at a fixed time point or, if {opt simcorr()} is specified, the correlation between survival times on the I-
(excluding D) and D-outcome{p_end}
{synopt :{opt nof:wer}}suppress the calculation of the familywise error rate{p_end}
{synopt :{opt pr:obs}}reports probabilities of the number of arms passing each stage under the global null hypothesis{p_end}
{synopt :{opt s(# [#])}}survival probability for an I-event and a D-event corresponding to survival time in {opt t()}{p_end}
{synopt :{opt sim:corr(#)}}number of replicates in the simulations to estimate the correlation structure.{p_end}
{synopt :{opt ts:top(#)}}time at which recruitment is to cease{p_end}
{synopt :{opt tu:nit(#)}}code for units of trial time{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nstage} is intended to help one specify the design (sample size, duration, 
overall operating characteristics) of a multi-arm, multi-stage (MAMS)
trial utilizing an intermediate outcome (I-outcome) at the intermediate stages
and a definitive or primary outcome (D-outcome) at the final stage.
See Royston, Barthel, Parmar & Oskooei (2011) for details of the design and
some examples, and Barthel, Royston & Parmar (2009) and
Bratton, Choodari-Oskooei & Royston (2014) for further explanations of 
Stata-related aspects and details of algorithms used.


{title:Options}

{dlgtab:Required}

{phang}
{opt accrue(numlist)} specifies the rate per unit time (see {opt tunit()}) 
at which patients enter the trial during each stage. The patients are assumed
to be allocated in the ratio (control arm:experimental arm: ...) of
1:{it:A}:...:{it:A}, where {it:A} is the allocation ratio defined by
{opt aratio()}.

{phang}
{opt alpha(numlist)} specifies the one-sided significance level at each
stage. For the first {it:J} - 1 stages the arms are compared pairwise with
control on the intermediate outcome, whereas at the {it:J}th stage the 
comparison is on the primary outcome. Usually the alpha value at the
{it:J}th stage is half the usual two-sided alpha, to give the equivalent
of a conventional two-sided type 1 error probability.
 
{phang}
{opt arms(numlist)} specifies the number of arms assumed to be 
actively recruiting patients at each stage. The number at stage 2 and
subsequently cannot exceed the number at stage 1, since arms can only
be 'dropped' not added. For example, {cmd:arms(4 3 2)} would say that
in a 3-stage trial of 4 arms only 3 survived to the second stage and
2 to the final stage.

{phang}
{opt hr0(# [#])} specifies the hazard ratios under the null hypothesis
for the I-outcome and D-outcome, respectively. Typically these values
are both 1.

{phang}
{opt hr1(# [#])} specifies the hazard ratios under the alternative hypothesis
for the I-outcome and D-outcome, respectively. Typically these values are equal.

{phang}
{opt nstage(#)} specifies {it:J}, the number of trial stages.

{phang}
{opt omega(numlist)} specifies the power (one minus the type 2 error
probability) for each pairwise comparison at each stage.
See also {opt alpha()}.

{phang}
{opt t(# [#])} defines the times corresponding to the survival probabilities
in {opt s()} for an I-event and a D-event. If the default values of 0.5 for
{opt s()} are used then the required values of {opt t()} are the median
survival times for each type of outcome. Note that the survival distribution
for both types of event is assumed to be exponential. 


{dlgtab:Optional}

{phang}
{opt aratio(#)} specifies the allocation ratio (number of patients allocated
to each experimental arm per control arm patient). Default {it:#} is 1 (equal
allocation to all arms).

{phang}
{opt corr(#)} specifies either (a) the correlation between treatment effects on the I-
and D-outcomes at a fixed timepoint, such as the end of the trial, or (b) if 
{opt simcorr()} is specified, the correlation between survival times on the I-
(excluding D) and D-outcomes. If (a), the value of {it:#} can be estimated 
by a bootstrap analysis of relevant previous trial data.  
In both cases the default value of {it:#} = 0.6 is based on
I = time to progression or death and D = time to death in cancer. Such a
value is not necessarily appropriate in other settings. In the absence
of knowledge, we suggest a sensitivity analysis for {it:#} in the range
[0.4, 0.8]. Note that the only outputs affected by this option are the
overall type I error rate and power of the design. This option does not
need to be specified if the I- and D-outcomes are identical.

{phang}
{opt nofwer} suppresses the calculation of the maximum familywise error rate
of the trial (probability of making any type I error at the end of the trial
under the global null hypothesis).

{phang}
{opt probs} reports the probabilities of the numbers of arms passing each stage
of the trial under the global null hypothesis.

{phang}
{opt s(# [#])} defines the survival probability for an I-event and a
D-event, respectively, i.e.
the probability of no event in intervals defined by {opt t()}. For example,
{cmd:s(0.5 0.75)} would say that the survival probability in the relevant
interval was 0.5 for I-outcomes and 0.75 for D-outcomes. Default {it:# [#]}
is 0.5 [0.5].

{phang}
{opt simcorr(#)} defines the number of replicates in the simulations to estimate 
the between-stage correlation structure. The estimated correlation structure is used to 
compute the overall type I error rate and power of the design. At least 1000 replicates
are recommended. If {opt simcorr()} is not specified, the program uses the 
default correlation structure described by Royston et al (2011). This option does 
not need to be specified if the I- and D-outcomes are identical.

{phang}
{opt tstop(#)} defines the time at which recruitment is to cease. To be valid
and to make sense in the context of the MAMS design,
{it:#} must be a time that falls within the final stage. If this is not the
case an error will be reported. Default {it:#} is 0, meaning no ceasing
of recruitment before the end of the final stage.

{phang}
{opt tunit(#)} defines the code for units of trial time. The codes are
1 = one year, 2 = 6 months, 3 = one quarter (3 months), 4 = one month,
5 = one week, 6 = one day, and 7 = unspecified. {opt tunit()} has no
influence on the computations and is for information only. Default {it:#}
is 1 (one year).


{title:Remarks}

{pstd}
Note that a dialog (see {help nstagemenu}) is provided to make specifying
a MAMS trial easier. Use of the dialog creates the necessary options
and arguments for {cmd:nstage}.

{pstd}
{cmd:nstage} reports the cumulative number of events in all the
remaining experimental arms at each stage. The events are I-events for
the first {it:J} - 1 stages and D-events for the final stage.
When arms are 'dropped', as determined by the {opt arms()} option,
their events occurring after the stage in which
they were dropped are not counted in the
number reported in the columns headed 'Overall' and 'Exper.'.
Thus the number of D-events reported at the final stage
is relevant to the treatment comparisons available with the control
arm only for the arms still active at this stage. Arms that
have been dropped earlier do not contribute events. A consequence
if arms are dropped is that the number of I-events may decrease over
time. The total numbers of patients reported at each stage
still take into account those recruited to dropped experimental arms,
since such patients remain part of the trial (e.g. consume
resources and must be followed up
in the same way as patients on still-active arms).


{title:Examples}

{pstd}
3-arm, 2-stage design with identical I- and D-outcomes:

{phang}. {stata nstage, accrue(100 100 100) arms(3 3 2) alpha(0.4 0.2 0.025) hr0(1 1) hr1(0.75 0.75) omega(0.95 0.95 0.90) t(2 2) s(0.5 0.5) aratio(1) nstage(3) tunit(1)}{p_end}

{pstd}
6-arm, 5-stage design with different I- and D-outcomes:

{phang}. {stata nstage, accrue(87 87 87 87 87) arms(6 6 5 4 3) alpha(0.5 0.25 0.1 0.05 0.025) hr0(1 1) hr1(0.75 0.75) omega(0.95 0.95 0.95 0.95 0.90) t(8 16) s(0.5 0.5) aratio(0.5) corr(0.5) nstage(5) tstop(27) tunit(3) simcorr(1000)}{p_end}


{title:Authors}

{pstd}
Patrick Royston, Daniel Bratton, Babak Choodari-Oskooei {break}
MRC Clinical Trials Unit at UCL, London.{break}
j.royston@ucl.ac.uk, d.bratton@ucl.ac.uk, b.choodari-oskooei@ucl.ac.uk

{pstd}
Frederike Maria-Sophie (Sophie) Barthel, consultant.{break}
sophie@fm-sbarthel.de


{title:References}

{phang}
Royston P, Barthel FM-S, Parmar MKB, Choodari-Oskooei B, V Isham 2011. Designs for clinical trials
with time-to-event outcomes based on stopping guidelines for lack of benefit. Trials, 12:81.

{phang}
Barthel FM-S, Royston P, Parmar MKB. 2009. A menu-driven facility for sample size
calculation in novel multi-arm, multi-stage randomised controlled trials with a
survival-time outcome. Stata Journal, 9(4): 505-523.

{phang}
Bratton DJ, Choodari-Oskooei B, Royston P. 2014. A menu-driven facility for sample-size
calculation in multi-arm multi-stage randomised controlled trials with time-to-event outcomes: 
Update. Stata Journal (in press).


{title:Also see}

{psee}
Online:  help for {help nstagemenu}, {help nstagedlg}
{p_end}
