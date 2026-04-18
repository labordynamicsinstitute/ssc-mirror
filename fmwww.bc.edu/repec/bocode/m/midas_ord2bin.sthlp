{smcl}
{* version 1.00  23mar2026}{...}
{cmd:help midas ord2bin}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas ord2bin} {hline 2} Convert ordinal test data to 2x2 tables at optimal threshold

{title:Syntax}

{p 8 18 2}
{cmd:midas ord2bin}
{it:score dis_n nondis_n total_dis total_nondis}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
{cmd:,}
{cmd:idvar(}{it:varname}{cmd:)}
{cmd:savedata(}{it:filename}{cmd:)}
[{cmd:threshold(}{it:string}{cmd:)}
{cmd:replace}
{cmd:detail}
{cmd:noisily}]

{title:Description}

{pstd}
{cmd:midas ord2bin} converts ordinal or multi-threshold diagnostic test
data to a single 2x2 table by selecting the optimal threshold (maximising
the Youden index) for each study. The five required variables are:

{p2colset 9 22 22 2}
{p2col:{it:score}}ordinal test score or threshold value{p_end}
{p2col:{it:dis_n}}number of diseased at this score{p_end}
{p2col:{it:nondis_n}}number of non-diseased at this score{p_end}
{p2col:{it:total_dis}}total diseased in study{p_end}
{p2col:{it:total_nondis}}total non-diseased in study{p_end}

{title:Options}

{phang}
{cmd:idvar(}{it:varname}{cmd:)} study identifier variable. Required.

{phang}
{cmd:savedata(}{it:filename}{cmd:)} output dataset with 2x2 counts. Required.

{phang}
{cmd:threshold(}{it:string}{cmd:)} manually specify the threshold rather
than using the optimal Youden index.

{phang}
{cmd:replace} overwrites an existing output file.

{phang}
{cmd:detail} displays intermediate threshold calculations.

{phang}
{cmd:noisily} shows all computation steps.

{title:Example}

{pstd}Setup: Load example dataset{p_end}
{phang2}{cmd:. use http://fmwww.bc.edu/repec/bocode/m/ord2bindata.dta, clear}{p_end}


{phang2}{cmd:. midas ord2bin score dis nondis totaldis totalnondis, idvar(study) savedata(binary.dta, replace)}{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas con2bin}, {helpb midas ipd2ad}
