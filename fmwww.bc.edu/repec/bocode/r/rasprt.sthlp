{smcl}
{* *!1.0.0  Brent Mcsharry brent@focused-light.net 14Jan2014}{...}
{cmd:help rasprt}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:rasprt} {hline 2}}Plot a Risk adjusted sequential probability ratio test chart +/- Risk Adjusted Cumulative Sum chart{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab:rasprt}
{outcomevar sequencevar}
{ifin}
, {Predicted(varname)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Options}
{synopt:{opt OR(#)}} the odds ratio for the alternative hypothesis. Default is 2{p_end}
{synopt:{opt A1(#)}} alpha1 - upper outer threshold line. Default is 0.01{p_end}
{synopt:{opth A2(#)}} alpha2 - upper inner threshold line. Default is 0.05 {p_end}
{synopt:{opt B1(#)}} beta1 - lower outer threshold line. Default is 0.01 {p_end}
{synopt:{opth B2(#)}} beta2 - lower inner threshold line. Default is 0.05  {p_end}
{synopt:{opt noSPRT}} do not display the sequential probability ratio (displays only the cusum) {p_end}
{synopt:{opt noCUSUM}} do not display risk adjusted CUSUM. {p_end}
{synopt:{opt noRESET}} do not reset the plot to 0 when the outer threshold is crossed. {p_end}
{synopt:{opt XLABEL(rule_or_values)}} major ticks plus labels. see {help axis_label_options}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{title:Description}

{pstd}
{cmd:rasprt} Plots the cumulative-log likelihood over sequential records.
{p_end}

{pstd}
{cmd:outcomevar} The actual outcome being benchmarked. Must be binary.
{p_end}
{pstd}
{cmd:sequencevar} A variable denoting in what order each subject has entered the analysis.
{p_end}
{pstd}
{cmd:Predicted} The predicted value for the outcome under investigation.
{p_end}

{title:Options}

{dlgtab:Main}

{phang}
{opt noCUSUM} A Risk Adjusted Cumulative Sum imposes a lower absorbing barier at the zero line.
{p_end}

{phang}
{opt noRESET} continue the plot outside the outer threshold line, rather than reset to 0.
{p_end}

{title:Authors}

{p 4 4 2}Brent McSharry, Starship Children's Hospital, Auckland New Zealand -
brentm@adhb.govt.nz
{p_end}

{title:Examples}
{hline}
{pstd}Setup{p_end}
{phang2}. {stata webuse cancer}{p_end}
{phang2}. {stata gen int study_entry_sequence=_n}{p_end}
{phang2} assuming co-efficients from a (fictional) validated benchmarking model - intercept -3.6, age 0.12 per year, coeficient for drug2 -3.5 and drug 3 -3.2 {p_end}
{phang2}. {stata gen double predicted_death=invlogit(-3.6+ 0.12*age -3.5*(drug==2) -3.2*(drug==3))}{p_end}
{phang2} Creating another fictional benchmarking model - in this case more outcomes are occuring than would be predicted {p_end}
{phang2}. {stata gen double xs_pred_death=invlogit(-5.6+ 0.12*age -5*(drug==2) -3.2*(drug==3))}{p_end}
{pstd}Plot{p_end}
{phang2}. {stata rasprt died study_entry_sequence, pr(predicted_death) }{p_end}
{phang2}. {stata rasprt died study_entry_sequence, pr(predicted_death) nocusum }{p_end}
{phang2}. {stata rasprt died study_entry_sequence, pr(predicted_death) nosprt }{p_end}
{phang2}. {stata rasprt died study_entry_sequence, pr(xs_pred_death) }{p_end}
{phang2}. {stata rasprt died study_entry_sequence, pr(xs_pred_death) noreset }{p_end}
{hline}
{title:Also see}
{psee} Aticle: {it:International Journal for Quality in Health Care} 2003; Volume 15, Number 1: pp. 7–13 
{browse "http://intqhc.oxfordjournals.org/content/15/1/7.full.pdf":Risk-adjusted sequential probability ratio tests and longitudinal surveillance methods}
{p_end}
{psee} Aticle: {it:Critical Care and Resuscitation} 2008; Volume 10, Number 3: pp. 239-251 
{browse "http://cicm.org.au/journal/2008/september/ccr_10_3_010908_239_Cook.pdf":Review of the application of risk-adjusted charts to analyse mortality outcomes in critical care}{p_end}
