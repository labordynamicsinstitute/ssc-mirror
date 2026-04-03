{smcl}
{* version 1.00  23mar2026}{...}
{cmd:help midas quadas}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas quadas} {hline 2} QUADAS-2 methodological quality assessment

{title:Syntax}

{p 8 18 2}
{cmd:midas quadas}{cmd:,}
{cmd:id(}{it:varname}{cmd:)}
{cmd:robvars(}{it:varlist}{cmd:)}
{cmd:acvars(}{it:varlist}{cmd:)}
{cmd:plot(}{it:string}{cmd:)}
[{cmd:color}
{cmd:scheme(}{it:schemename}{cmd:)}
{cmd:saving(}{it:string}{cmd:)}
{it:graph_options}]

{title:Description}

{pstd}
{cmd:midas quadas} displays a QUADAS-2 (Quality Assessment of Diagnostic
Accuracy Studies) summary chart. QUADAS-2 assesses methodological quality
of primary diagnostic accuracy studies across four domains: patient
selection, index test, reference standard, and flow and timing.

{pstd}
Each domain is assessed for risk of bias and (for the first three domains)
applicability concerns. The assessment variables should be coded as
1 = low risk/concern, 2 = high risk/concern, 3 = unclear.

{title:Options}

{phang}
{cmd:id(}{it:varname}{cmd:)} study identifier variable.

{phang}
{cmd:robvars(}{it:varlist}{cmd:)} variables encoding risk-of-bias judgements,
one per QUADAS-2 domain.

{phang}
{cmd:acvars(}{it:varlist}{cmd:)} variables encoding applicability concern
judgements.

{phang}
{cmd:plot(}{it:string}{cmd:)} plot type: {cmd:bar} for a bar chart of
proportions, or {cmd:sum} for a study-level summary chart.

{phang}
{cmd:color} uses color coding (green/red/yellow for low/high/unclear).

{phang}
{cmd:saving(}{it:filename}{cmd:)} saves the graph to {it:filename}.

{title:Example}

{phang2}{cmd:. midas quadas, id(study) robvars(rob1 rob2 rob3 rob4) acvars(ac1 ac2 ac3) plot(bar)}{p_end}

{title:References}

{phang}
Whiting PF, et al. QUADAS-2: A revised tool for the quality assessment
of diagnostic accuracy studies. {it:Ann Intern Med} 2011;155:529-536.

{title:Also see}

{psee}
{helpb midas}
