// Corresponds to the examples in Section 3 of the artbin Stata Journal 
// artbin v2.0.2
// Last updated: 23 May 2023

clear all
set more off
prog drop _all

version 16.1

cd C:\git\artbin\examples\


log using artbin_examples, replace text


which artbin
which art2bin



/***
\subsection{Binary outcome and comparison with published sample size}
We reproduce the sample size calculation in \citet{Pocock83} for a 2-arm superiority trial comparing the efficacy of therapeutic doses of anturan in patients after a myocardial infarction with the placebo standard treatment.  The primary outcome was death from any cause within one year of first treatment.  The control (placebo) arm was expected to have a 10\% probability of death within one year and the anturan treatment arm a 5\% probability, with the trial powered at 90\%.  The patient outcome was binary; either failure (death in a year) or success (survival).  The published sample size was 578 patients per arm (1156 patients in total).
In the below \texttt{artbin} example we do not specify in the syntax whether the outcome is favourable or unfavourable, rather we let the program infer it.  The aim of a clinical trial is always to improve patient outcome, therefore as the experimental arm anticipated probability ($\pi_2 = 0.05$) is $less$ $than$ the control arm anticipated probability ($\pi_1 = 0.1$) then the outcome is inferred to be unfavourable (i.e. the trial is aiming to $reduce$ the probability of the event occurring, in this case, death).
***/


artbin, pr(0.1 0.05) alpha(0.05) power(0.9) wald
local n=r(n)


/***
The \texttt{artbin} output table shows the trial set-up information including the study design, statistical tests and methods used.  The hypothesis tests are shown with the calculated sample size and events based on the selected power.  
A total sample size of 1156 participants is required, as per the published sample size given by Pocock.
The same result is achieved by the code \texttt{artbin, pr(0.9 0.95) alpha(0.05) power(0.9) wald} assuming a favourable outcome (survival) instead.
The Wald test is used instead of the default score test as Pocock used the sample estimate in the method of estimating the variance of the difference in proportions under the null hypothesis $H_{0}$.

\subsection{Binary outcome and comparison with \texttt{power}}
We compare the output of \texttt{artbin} to Stata's \texttt{power} command, which like \texttt{artbin} uses the score test as the default.
***/


power twoproportions 0.1 0.05, alpha(0.05) power(0.9)
local npower=r(N)

artbin, pr(0.1 0.05) alpha(0.05) power(0.9)
local nartbin=r(n)


/***
Both give a total sample size of `nartbin'.

\subsection{One-sided non-inferiority trial}
Next we show a one-sided non-inferiority trial with the 'onesided' option.  We assume a 90\% probability of survival in both the control and treatment arms, with the treatment arm being no more than 5\% less effective than the control.
***/

artbin, pr(0.9 0.9) margin(-0.05) onesided


/***

A sample size of 457 is required in each group.

\subsection{Superiority trial with multiple arms}
Next we demonstrate a superiority trial with more than 2 arms.  Instead of comparing each of the treatment arms to the control group, \texttt{artbin} uses a global test to assess if there is $any$ difference among the groups.
***/


artbin, pr(0.1 0.2 0.3 0.4) alpha(0.1) power(0.9) 


/***

A sample size of 44 is required in each of the four groups.

\subsection{Complex non-inferiority trial in a real-life setting} \label{sec:complexNIexample}
Finally, we demonstrate a more complex non-inferiority design from the STREAM trial.  The need for the STREAM trial arose from the increase of multi-drug resistant strains of Tuberculosis, especially in countries without robust health care systems unable to administer and follow up treatment over long periods of time.  The STREAM trial evaluated a shorter more intensive treatment for multi-drug resistant Tuberculosis compared to the lengthier treatment recommended by the World Health Organization. 
The trial used an expected 0.7 probability on control ($\pi_1$) and 0.75 on treatment ($\pi_2$), hence it was assumed that 70\% in the long-regimen group and 75\% of the participants in the short-regimen group would attain a favourable outcome.  A favourable outcome was defined as cultures negative for $Mycobacterium$ $tuberculosis$ at 132 weeks and at a previous occasion, with no intervening positive culture or previous unfavourable outcome \citep{Nunn2019}.  A 10 percentage-point non-inferiority margin was considered to be an acceptable difference in efficacy, given the shorter treatment duration ($m =$ -0.1 defined as $\pi_2$-$\pi_1$), with twice as many patients in treatment compared to control.  The \texttt{wald} test was applied as it is often used in non-inferiority trials. 
***/


artbin, pr(0.7 0.75) margin(-0.1) power(0.8) ar(1 2) wald ltfu(0.2)
local n=r(n)

/***
The non-inferiority trial required a total sample size of 399 (133 in control, 266 in intervention), assuming 20\% of patients were not accessible in primary analysis.  When the STREAM trial concluded, it estimated that a shorter more intensive treatment for multi-drug resistant Tuberculosis was only 1\% less effective than the lengthier treatment recommended by the World Health Organization, and demonstrated significant evidence of non-inferiority.


***/

log close
