{smcl}
{cmd:help kappaetc , ttest}
{hline}

{title:Title}

{p 5 25 2}
{cmd:kappaetc , ttest} {hline 2} Paired t tests of agreement coefficients


{title:Syntax}

{p 8 18 2}
{cmd:kappaetc}
{it:name1} {cmd:==} {it:name2}
[ {cmd:, } {it:{help kappaetc_ttest##opts:options}} ]


{p 5 8 2}
where {it:name1} and {it:name2} are results previously stored by 
{helpb kappaetc}


{synoptset 28 tabbed}{...}
{marker opts}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt ttest}}perform paired t tests of agreement coefficients
{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is 
{cmd:level({ccl level})}{p_end}
{synopt:{opt nohe:ader}}suppress output header{p_end}
{synopt:{opt notab:le}}suppress coefficient table{p_end}
{synopt:{opt replay}}replay results in {it:name1} and {it:name2}{p_end}
{synopt:{it:{help kappaetc##opt_di:format_options}}}control column formats
{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:kappaetc} with the {opt ttest} option performs paired t tests of the 
differences between correlated agreement coefficients. It implements the 
linearization method discussed in Gwet (2016).

{pstd}
The two sets of agreement coefficients are assumed to be based on the same 
subjects rated by different groups of raters or rated repeatedly by the 
same group of raters. The test statstics are based on differences of the 
subject-level agreement coefficients.


{title:Options}

{dlgtab:Main}

{phang}
{opt ttest} performs paired t tests of correlated agreement coefficients.

{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence 
intervals. The default is {cmd:level({ccl level})}.

{phang}
{opt noheader} suppresses the report about the number of subjects. Only the 
coefficient table is displayed.

{phang}
{opt notable} suppresses the display of the coefficient table.

{phang}
{opt replay} replays the two sets of agreement coefficients to be tested.


{title:Examples}

{pstd}
The example is drawn from {manlink R kappa}.

{pstd}
Test the difference of agreement among the first three and last two raters.

{phang2}{cmd:. webuse p615b}{p_end}
{phang2}{cmd:. kappaetc rater1-rater3 , store(group1)}{p_end}
{phang2}{cmd:. kappaetc rater4 rater5 , store(group2)}{p_end}
{phang2}{cmd:. kappaetc group1==group2}{p_end}


{title:Saved results}

{pstd}
{cmd:kappaetc} with the {opt ttest} option saves the following in {cmd:r()}:

{pstd}
Scalars{p_end}
{synoptset 24 tabbed}{...}
{synopt:{cmd:r(N)}}number of subjects{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}

{pstd}
Macros{p_end}
{synoptset 24 tabbed}{...}
{synopt:{cmd:r(cmd)}}{cmd:kappaetc}{p_end}
{synopt:{cmd:r(cmd2)}}{cmd:ttest}{p_end}
{synopt:{cmd:r(results1)}}{it:name1} of the first stored results{p_end}
{synopt:{cmd:r(results2)}}{it:name2} of the second stored results{p_end}

{pstd}
Matrices{p_end}
{synoptset 24 tabbed}{...}
{synopt:{cmd:r(table)}}information from the coefficient table{p_end}
{synopt:{cmd:r(b)}}differences{p_end}
{synopt:{cmd:r(se)}}standard errors of differences{p_end}
{synopt:{cmd:r(df)}}difference-specific degrees of freedom{p_end}


{title:References}

{pstd}
Gwet, K. L. (2016). Testing the Difference of Correlated Agreement Coefficients 
for Statistical Significance. {it:Educational and Psychological Measurement}, 
76, 609-637.


{title:Author}

{pstd}Daniel Klein, University of Kassel, klein.daniel.81@gmail.com


{title:Also see}

{psee}
Online: {helpb ttest}, {helpb kappa}, {helpb icc}
{p_end}

{psee}
if installed: {help kappa2}, {help kapci}, {help kappci}, {help kanom}, {help kalpha}, 
{help krippalpha}, {help concord}, {help entropyetc}
{p_end}
