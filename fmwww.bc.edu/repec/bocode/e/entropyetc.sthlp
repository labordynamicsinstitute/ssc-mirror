{smcl}
{* *! NJC 20nov2016/15jun2020/29jun2021/11jan2024/19jun2024}{...}
{cmd:help entropyetc}
{hline}

{title:Title}

{p 8 8 2}Entropy and related measures for categories 


{title:Syntax}
 
{p 8 12 2}
{cmd:entropyetc} 
{varname} 
{ifin} 
{weight}  
[
{cmd:,}
{opt list}
{opt gen:erate(newvar_spec)} 
{opt by(byvarlist)}
{it:list_options} 
]

{p 4 6 2}
{cmd:aweight}s and {cmd:fweight}s are allowed; see {help weight}.


{title:Description} 

{pstd}
{cmd:entropyetc} treats {it:varname}, which may be numeric or string, as
a categorical variable, so that distinct values define distinct
categories, and calculates 

{pmore}
(1) the number of distinct categories observed

{pmore}
(2) Shannon entropy {it:H} 

{pmore}
(3) exp {it:H}

{pmore}
(4) Simpson's sum of squared probabilities {it:R} 

{pmore}
(5) 1/{it:R}. 

{pstd}Optionally, results may be listed. Optionally,
new variables may be generated containing results. 
Hence the syntax supports those who want a listing, but not 
new variables, and conversely.  

{pstd}Hence you should ask for at least one of those options. 
Otherwise, there is nothing to do. 


{title:Remarks} 

{pstd} 
Given {it:S} categories of {it:varname}, calculate their relative
frequencies, applying any weights specified, as proportions {it:p} with
sum 1. In ecology at least, {it:S} is conventional for "number of
species". Then

{pstd} 
Shannon entropy is SUM {it:p} ln 1/{it:p} =: {it:H}, say. It is often
written more concisely but more cryptically as - SUM {it:p} ln {it:p}.
If one value of {it:p} is 1, this index takes on a minimum value of 0.
If all {it:p} are equal at 1/{it:S}, it takes on a maximum value of ln
{it:S}. This behaviour motivates looking at exp {it:H} as a "numbers
equivalent". 

{pstd}
Those preferring to use logarithms to base 2 or 10 should divide results
by ln 2 or ln 10 respectively. 

{pstd} 
Simpson's index is SUM {it:p}^2 =: {it:R}, say. If one value of {it:p} is
1, and the others thus all 0, this index takes on a maximum value of 1.
If all {it:p} are equal at 1/{it:S}, it takes on a minimum value of 
1/{it:S}. This behaviour motivates looking at 1/{it:R} as a "numbers
equivalent". 

{pstd}
Simpson's index has been discovered or invented many times, sometimes in
the form of its complement or its reciprocal. It is also named repeat
rate and match probability. In particular circumstances it measures
homozygosity or purity of classifications, so its complement measures
heterozygosity or impurity. It is also associated directly or indirectly 
with (this is far from a complete list) Gini, W.F. Friedman, Turing, 
Hirschman, Herfindahl and Blau.  


{title:Options}

{phang}{opt list} calls for listing of results. 

{phang} 
{opt generate()} specifies the creation of between one and five new
variables from results. The syntax
is exemplified by {cmd:generate(2=H 4=R)}. The elements of the
specification are {it:#}{cmd:=}{it:newvar}, where {it:#} is an integer
between 1 and 5 and {it:newvar} is a legal new variable name.  Elements
must not contain spaces and are separated by spaces. In this example,
values corresponding to the second result are saved
as {cmd:H} and values corresponding to the fourth result as {cmd:R}. Values of 
new variables are copied to all observations used in their calculation. 

{phang} 
{opt by()} specifies that calculations should be performed separately
for groups defined by {it:byvarlist}.

{phang}
{it:list_options} are options of {help list} controlling the
display of results. 
The default display format is {cmd:%1.0f} for the number of distinct 
categories and {cmd:%4.3f} otherwise. The latter may be changed 
using the {cmd:format()} option. 


{title:Examples} 

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. entropyetc rep78, list}{p_end}
{phang2}{cmd:. entropyetc rep78, list by(foreign)}

{phang2}{cmd:. webuse nlsw88}{p_end}
{phang2}{cmd:. entropyetc occupation, list by(industry) gen(3=numeq)}{p_end}
{phang2}{cmd:. egen tag = tag(industry)}{p_end}
{phang2}{cmd:. graph dot (asis) numeq if tag, over(industry, sort(1) descending) ysc(alt) linetype(line) lines(lc(gs8) lw(vthin))}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. entropyetc company [w=invest], list by(year)}


{title:Author}

{pstd}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:Acknowledgments}

{pstd}Paris Rira reported a problem if 5 variables were named in {cmd:generate()}. 


{title:Also see}

{pstd}{help divcat} (SSC; if installed);{p_end}
{pstd}{help distinct} ({it:Stata Journal}; if installed) 
