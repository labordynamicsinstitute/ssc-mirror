{smcl}
{* *! version 3.0.0 26sep2014}{...}
{cmd:help nstagedlg}
{hline}


{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{hi:nstage.dlg} {hline 2}}Dialog for multi-arm, multi-stage (MAMS) clinical trial design{p_end}
{p2colreset}{...}


{title:Overview}

{p 0 0}
The dialog is intended to help you to specify the design (sample size, rate of
patient accrual and duration of accrual) of a multi-arm, multi-stage (MAMS)
trial utilising an intermediate outcome (I-outcome) at the intermediate stages
and a definitive or primary outcome (D-outcome) at the final stage.
See Royston, Parmar & Qian (2003) and Royston et al (2011)
for details of the design and some examples, and 
Bratton, Choodari-Oskooei & Royston (2014) for further explanations of Stata-related
aspects and details of algorithms used.

{p 0 0}
Additionally, the program can help you design a conventional (one-stage,
parallel-group) randomised clinical trial with a survival time outcome. To do
this, you specify the option {cmd:Design for one stage only}.

{p 0 0}
The program can handle unequal allocation of patients to control and
experimental arms (but is limited to equal allocation to all experimental arms).
The allocation ratio must be the same at all stages.

{p 0 0}
You can specify the time at which accrual is to cease. If this time is not
specified, accrual is assumed to continue until enough events have accumulated
for the analysis to be carried out. Otherwise, accrual ceases at the indicated
time and the trial continues while the required events are awaited in
the patients already recruited.

{p 0 0}
Note that if the accrual period is too short, the design is infeasible
and an error message is issued.

{p 0 0}
The outputs from the program include {p_end}

{p 4 7}
1. The numbers of patients and events in the control arm, accumulated across
the experimental arms and overall, at all stages.

{p 4 7}
2. The durations of each stage individually and overall, that is the times
from randomisation to the times expected to accrue the requisite numbers of events.

{p 0 0}
In what follows, most of the defaults are provided for the purpose of
illustration. They are not necessarily appropriate for your trial.


{title:Design parameter panel}

{p 0 4}
{cmd:Total number of stages} (default 1) The number of stages in the trial. If you enter 1, the
trial will be treated as a conventional (one-stage) design, and the parameters regarding intermediate stages 
will be ignored. 

{p 0 4}
{cmd: Allocation ratio} (default 1) The number of patients allocated to each experimental
arm per patient allocated to the control arm. Can be fractional. Example: 0.5 means that
each experimental arm would receive half as many patients as the control arm.

{p 0 4}
{cmd: Time unit} (default 1 year) The units of trial time. 

{p 0 4}
{cmd:Time of stopping accrual} Time that patient accrual is to cease, in the
same units as used in the accrual rate. If this time is not specified, accrual
is assumed to continue until enough events have accumulated for the analysis to
be carried out.

{p 0 4}
{cmd:Show probabilities} Checking this box displays a table of estimated
probabilities of 0, 1, ... experimental arms passing from one stage to the next,
under the null and alternative hypothesis. To pass, an arm must have an HR for
I-events less than the critical HR. The latter quantity is reported by the program
as {it:Crit. HR}. For example, the chance of at least one arm passing under H0
is one minus the reported probability for 0 arms.

{title:Operating characteristics panel}

{p 0 4}
{cmd:Total accrual rate} (default 200/time unit) Rates at which patients
are entered into the control arm and all experimental arms at each stage. A uniform
rate of accrual is assumed at each stage. Note that the time units used here are arbitrary,
but typically will be years. Make sure you specify the other parameters involving time
in the same units. The default values are for illustration only.

{p 0 4}
{cmd:Number of recruiting arms} (default 5) The number of arms in the trial, i.e. one control
arm plus the number of experimental arms, at each stage. Arms may be dropped at each
intermediate stage, but may not be added. If you enter 0 for the Stage 2 arms, the
trial will be treated as a conventional (one-stage) design, and the other parameters
will be ignored. Otherwise, parameter values are required for each stage. The
default setting is for illustration only.

{p 0 4}
{cmd:Significance level (one-sided)} (default .2) One-sided Type 1 error probability.
Specify alpha/2 if a two-sided error probability is required (e.g. 0.025 for
two-sided alpha of 0.05). The values at each intermediate stage should differ, and
should be reduced with each successive stage.

{p 0 4}
{cmd:Power} (default .95) Required power for test of HR for
I-events at the intermediate stages and test for D-events at the final stage,
considered independently. Values at each intermediate stage may differ.

{title:Intermediate outcome and Primary outcome panels}

{p 0 4}
{cmd:Survival probability} (default 0.5) The probability of no I-event in (0,t1]
and the probability of no D-event in (0,t2] respectively, where t1 and t2 are the
times specified in the {cmd:Survival time} edit box.
 
{p 0 4}
{cmd:Survival time} (default 1.5) The time to I-event and to D-event with
corresponding probabilities specified in the {cmd:Survival probability} edit box.
The default values are for illustration only.

{p 0 4}
{cmd:Hazard ratio under H0} (default 1) Hazard ratio (HR) for experimental arm(s) to
control arm under the null hypothesis. Value for the intermediate stages is HR for
I-events, that for the final stage is HR for D-events. Usually 1, may be less than 1.

{p 0 4}
{cmd:Hazard ratio under H1} (default 0.75, 0.75) Hazard ratio for experimental group
to control group under the alternative (alternate) hypothesis. Value for the
intermediate stages is HR for I-events, that for the final stage is HR for D-events.
Must be less than 1.

{p 0 4}
{cmd:Correlation between hazard ratios on I and D outcomes} This measures the strength
of association between the treatment effects on the I and D outcomes at a fixed
time-point (e.g. the end of follow-up). The correlation can be estimated by applying
bootstrap analysis to trial data similar to that expected in the new trial. We suggest
a default value of 0.6 for this parameter. If you have no idea of the value, we
suggest a sensitivity analysis in the range [0.4, 0.8]. The correlation value affects
only the overall significance level and power of the design. If you have only a single
outcome type, the correlation is not required since the program knows how to 
calculate the necessary correlation structure.


{title:References}

{p 0 4}
Bratton DJ, Choodari-Oskooei B, Royston P. 2014. A menu-driven facility
for sample-size calculation in multi-arm multi-stage randomised controlled
trials with time-to-event outcomes: Update. Stata Journal (in press).

{p 0 4}
Barthel FM-S, Royston P, Parmar MKB. 2009. A menu-driven facility
for sample size calculation in novel multi-arm, multi-stage randomised
controlled trials with a survival-time outcome. Stata Journal, 9(4): 505-523.

{p 0 4}
Royston P, Barthel FM-S, Parmar MKB, Choodari-Oskooei B., V Isham 2011.
Designs for clinical trials with time-to-event outcomes based on
stopping guidelines for lack of efficacy. Trials, 12:81.

{p 0 4}
Royston P, Parmar MKB and W Qian. 2003. Novel designs for multi-arm clinical
trials with survival outcomes, with an application in ovarian
cancer. Statistics in Medicine, 22: 2239-2256.


{title:Also see}

{psee}
Online:  help for {help nstage}
{p_end}
