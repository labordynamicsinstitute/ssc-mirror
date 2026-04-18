{smcl}
{* version 1.00  23mar2026}{...}
{cmd:help midas ipd2ad}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas ipd2ad} {hline 2} Aggregate individual participant data to study-level 2x2 tables

{title:Syntax}

{p 8 18 2}
{cmd:midas ipd2ad}
{it:test_result reference}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
{cmd:,}
{cmd:by(}{it:varname}{cmd:)}
[{cmd:saving(}{it:filename}{cmd:)}
{cmd:replace}
{cmd:studylabel(}{it:varname}{cmd:)}
{cmd:designvar(}{it:varname}{cmd:)}
{cmd:keepvars(}{it:varlist}{cmd:)}
{cmd:noisily}]

{title:Description}

{pstd}
{cmd:midas ipd2ad} converts individual participant data (IPD) to
aggregate 2x2 diagnostic accuracy tables suitable for meta-analysis
with {helpb midas}. One row per participant is expected, with binary
variables for the index test result and the reference standard.

{title:Arguments}

{p2colset 9 22 22 2}
{p2col:{it:test_result}}binary variable: 1 = test positive, 0 = test negative{p_end}
{p2col:{it:reference}}binary variable: 1 = disease positive, 0 = disease negative{p_end}

{title:Options}

{phang}
{cmd:by(}{it:varname}{cmd:)} study identifier variable. Required.

{phang}
{cmd:saving(}{it:filename}{cmd:)} saves the aggregated dataset to {it:filename}.

{phang}
{cmd:replace} overwrites an existing saved file.

{phang}
{cmd:studylabel(}{it:varname}{cmd:)} variable containing study label text.

{phang}
{cmd:designvar(}{it:varname}{cmd:)} variable identifying study design subgroups.

{phang}
{cmd:keepvars(}{it:varlist}{cmd:)} additional variables to carry forward to the aggregate dataset.

{phang}
{cmd:noisily} displays the crosstabulation for each study.

{title:Example}

{pstd}Setup: Load example dataset{p_end}
{phang2}{cmd:. use http://fmwww.bc.edu/repec/bocode/m/ipd2addata.dta, clear}{p_end}


{phang2}{cmd:. midas ipd2ad testpos disease, by(studyid) saving(aggregate.dta, replace)}{p_end}
{phang2}{cmd:. use aggregate, clear}{p_end}
{phang2}{cmd:. midas mle tp fp fn tn, id(studyid)}{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas con2bin}, {helpb midas ord2bin}
