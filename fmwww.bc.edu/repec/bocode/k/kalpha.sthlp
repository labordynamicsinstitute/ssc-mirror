{smcl}
{cmd:help kalpha}
{hline}

{phang}
{cmd:kalpha} has largely been superseded by {helpb kappaetc} available from 
the {help ssc:SSC} archives. {cmd:kalpha} will continue to work but there will 
not be any further updates to the software.


{title:Title}

{p 5}
{cmd:kalpha} {hline 2} Krippendorff's Alpha-Reliability


{title:Syntax}

{p 5}
Calculate Krippendorff's alpha coefficient

{p 8}
{cmd:kalpha} {varlist} {ifin} [ {cmd:,} {it:options} ]


{p 5}
Create a variable containing Krippendorff's alpha

{p 8}
{cmd:egen} {dtype} {newvar} {cmd:= kalpha(}{varlist}{cmd:)}
{ifin} [{cmd:,} {it:options}]


{p 5}
{helpb by} is allowed


{title:Description}

{pstd}
{cmd:kalpha} calculates Krippendorff's alpha reliability coefficient 
(Hayes and Krippendorff 2007; Krippendorff 2004, 2011, 2013a).

{pstd}
{cmd:kalpha} identifies observers (coders, judges, raters, ...) by 
observations while units of analysis are identified by variables.

{pstd}
Note that the {helpb bootstrap} prefix is not appropriate with 
{cmd:kalpha}. The {opt bootstrap} option implements the algorithm 
described in Krippendorff (2013b).


{title:Options}

{phang}
{opt sc:ale(metric)} specifies the data's metric or level of 
measurement. Default {it:metric} is {opt i:nterval} for numeric 
variables and {opt n:ominal} for string variables. {cmd:kalpha} 
also supports {opt o:rdinal}, {opt r:atio}, {opt c:ircular} and 
{opt p:olar} data. 

{p 8 8 8}
For circular data {it:metric} may be specified as 
{opt c:ircular}[{cmd:(}{it:U}{cmd:)}], where {it:U} specifies the 
fixed circumference (i.e. number of equal intervals) of the circle. 
If {it:U} is not specified it defaults to 
{cmd:{it:max} - {it:min} + 1}, where {it:max} and {it:min} are 
the observed maximum and minimum values in the data. Differences are 
calculated in radiance. To calculate differences in degrees, specify 
{opt circulard:eg}[{cmd:(}{it:U}{cmd:)}].

{p 8 8 8}
For polar data {it:metric} may be specified as 
{opt p:olar}[{cmd:(}{it:min max}{cmd:)}], where {it:min} and {it:max} 
specify the minimum and maximum value of the scale and default to their 
observed counterparts if not specified.

{phang}
{opt transpose} specifies that observers (coders, judges, raters, ...) 
be identified by variables and units by observations. This option does 
not affect the dataset itself. The {cmd:by} prefix, {cmd:if} and 
{cmd:in} qualifiers apply to the original structure of the dataset.
See {helpb xpose} to interchange observations and variables in the 
dataset.

{phang}
{opt boot:strap}[{cmd:(}{it:boot_opts}{cmd:)}] bootstraps the 
distribution of Krippendorff's alpha to obtain confidence intervals 
and probabilities to fail to reach a required minimum alpha. 
{it:boot_opts} are

{p 12 12 12}
{opt r:eps(#)} specifies the number of bootstrap replications and 
defaults  to 20,000.

{p 12 12 12}
{opt l:evel(#)} sets the confidence level. Default is 
{cmd:level({ccl level})}.

{p 12 12 12}
{opt mina:lpha(numlist)} bootstraps the probabilities to fail to 
reach a minimum alpha of {it:numlist}.

{p 12 12 12}
{opt seed(#)} sets the random-number seed. May not be combined 
with {cmd:by}. If {cmd:by} is specified use {helpb set seed} 
instead.

{p 12 12 12}
[{cmd:no}]{cmd:dots}[{cmd:(}{it:#}{cmd:)}] prints a dot each {it:#} 
replication, where {it:#} defaults to 1 if {opt dots} is specified.


{title:Example}

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. inp u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12}{p_end}
{p 10}{cmd:1 2 3 3 2 1 4 1 2 . . .}{p_end}
{p 10}{cmd:1 2 3 3 2 2 4 1 2 5 . 3}{p_end}
{p 10}{cmd:. 3 3 3 2 3 4 2 2 5 1 .}{p_end}
{p 10}{cmd:1 2 3 3 2 4 4 1 2 5 1 .}{p_end}
{phang2}{cmd:end}{p_end}

{phang2}{cmd:. kalpha u1-u12}{p_end}

{phang2}{cmd:. kalpha u1-u12 ,scale(ordinal)}{p_end}

{phang2}{cmd:. kalpha u1-u12 ,scale(nominal) bootstrap(reps(5000) minalpha(.8) dots(10))}
{p_end}


{title:Saved results}

{pstd}
{cmd:kalpha} saves the following in {cmd:r()}:

{pstd}
Scalars{p_end}
{synoptset 15 tabbed}{...}
{synopt:{cmd:r(kalpha)}}Krippendorff's alpha coefficient{p_end}
{synopt:{cmd:r(observers)}}number of observers (coders, judges, raters, ...){p_end}
{synopt:{cmd:r(units)}}number of units (with pairable values){p_end}
{synopt:{cmd:r(n)}}number of pairable values (n_..){p_end}

{pstd}
Macros{p_end}
{synoptset 15 tabbed}{...}
{synopt:{cmd:r(metric)}}{it:metric} (level of measurement){p_end}

{pstd}
Matrices{p_end}
{synoptset 15 tabbed}{...}
{synopt:{cmd:r(vbu)}}values-by-units matrix{p_end}
{synopt:{cmd:r(delta2)}}delta matrix{p_end}
{synopt:{cmd:r(rsum)}}row sums (n_.c){p_end}
{synopt:{cmd:r(csum)}}column sums (n_u.){p_end}
{synopt:{cmd:r(rel)}}reliability data matrix 
(numeric variables only){p_end}
{synopt:{cmd:r(uniqv)}}distinct values (numeric variables only)
{p_end}


{pstd}
With the {opt bootstrap} option {cmd:kalpha} additionally returns

{pstd}
Scalars{p_end}
{synoptset 15 tabbed}{...}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(reps)}}number of replications{p_end}
{synopt:{cmd:r(ci_lb)}}lower bound of confidence interval{p_end}
{synopt:{cmd:r(ci_ub)}}upper bound of confidence interval{p_end}

{pstd}
Matrices{p_end}
{synoptset 15 tabbed}{...}
{synopt:{cmd:r(coin)}}coincidence matrix{p_end}
{synopt:{cmd:r(q)}}probabilities to fail to reach minimum alpha{p_end}


{title:References}

{pstd}
Hayes, Andrew F., Krippendorff, Klaus (2007). Answering the call 
for a standard reliability measure for coding data. 
{it:Communication Methods and Measures}, 1, 77-89.

{pstd}
Krippendorff, Klaus (2013a). Computing Krippendorff's 
Alpha-Reliability. 
{browse "http://www.asc.upenn.edu/usr/krippendorff/mwebreliability5.pdf"}

{pstd}
Krippendorff, Klaus (2013b). Algorithm for bootstrapping a 
distribution of c_a. 
{browse "http://www.asc.upenn.edu/usr/krippendorff/Bootstrapping%20Revised(5).pdf"}

{pstd}
Krippendorff, Klaus (2011). Agreement and Information in the Reliability 
of Coding. {it:Communication Methods and Measures}, 5(2), 93-112. 
{browse "http://dx.doi.org/10.1080/19312458.2011.568376"}

{pstd}
Krippendorff, Klaus (2004). Reliability in Content Analysis: Some 
common Misconceptions and Recommendations. 
{it:Human Communication Research 30}, 3, 411-433.


{title:Acknowledgments}

{pstd}
We are grateful to Klaus Krippendorff and Andrew Hayes for 
clarifying questions about the computation of reliability for only 
one unit of analysis.


{title:Authors}

{pstd}Daniel Klein, University of Kassel, klein.daniel.81@gmail.com

{pstd}Rafael Reckmann, University of Kassel, rafael.reckmann@hotmail.com


{title:Also see}

{psee}
Online: {helpb kappa}, {helpb icc}, {helpb spearman}, {helpb egen}
{p_end}

{psee}
if installed: {help krippalpha}
{p_end}
