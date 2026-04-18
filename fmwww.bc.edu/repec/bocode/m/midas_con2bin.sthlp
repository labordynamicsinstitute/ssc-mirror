{smcl}
{* version 1.00  27nov2025}{...}
{cmd:help midas con2bin}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas con2bin} {hline 2} Convert continuous test data to 2x2 tables

{title:Syntax}

{p 8 18 2}
{cmd:midas con2bin}
{it:n1 x1 sd1 n0 x0 sd0}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
{cmd:,}
{cmd:id(}{it:string}{cmd:)}
[{cmd:savedata(}{it:filename}{cmd:)}]

{title:Description}

{pstd}
{cmd:midas con2bin} converts continuous test result data (means and
standard deviations in diseased and non-diseased groups) to 2x2
diagnostic accuracy tables, assuming a binormal model.

{pstd}
The six required variables, in order, are:

{p2colset 9 16 16 2}
{p2col:{it:n1}}number of diseased subjects{p_end}
{p2col:{it:x1}}mean test value in diseased{p_end}
{p2col:{it:sd1}}standard deviation in diseased{p_end}
{p2col:{it:n0}}number of non-diseased subjects{p_end}
{p2col:{it:x0}}mean test value in non-diseased{p_end}
{p2col:{it:sd0}}standard deviation in non-diseased{p_end}

{pstd}
The optimal threshold is derived under the binormal model and used to
compute implied sensitivity and specificity, from which integer counts
{cmd:tp}, {cmd:fp}, {cmd:fn}, {cmd:tn} are generated.

{title:Options}

{phang}
{cmd:id(}{it:string}{cmd:)} study identifier label. Required.

{phang}
{cmd:savedata(}{it:filename}{cmd:)} saves the resulting dataset with the
2x2 counts to {it:filename}.

{title:Example}

{pstd}Setup: Load example dataset{p_end}
{phang2}{cmd:. use http://fmwww.bc.edu/repec/bocode/m/con2bindata.dta, clear}{p_end}


{phang2}{cmd:. midas con2bin n1 x1 sd1 n0 x0 sd0, id(study) savedata(binary.dta)}{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas ord2bin}, {helpb midas ipd2ad}
