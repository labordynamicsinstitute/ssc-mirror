{smcl}
{* *! version 1.0.0  27feb2026}{...}
{vieweralsosee "xtfifevd" "help xtfifevd"}{...}
{viewerjumpto "Syntax" "xtfifevd_graph##syntax"}{...}
{viewerjumpto "Description" "xtfifevd_graph##description"}{...}
{viewerjumpto "Options" "xtfifevd_graph##options"}{...}
{viewerjumpto "Examples" "xtfifevd_graph##examples"}{...}
{viewerjumpto "Author" "xtfifevd_graph##author"}{...}

{title:Title}

{p2colset 5 25 27 2}{...}
{p2col:{bf:xtfifevd_graph} {hline 2}}Post-estimation graphs for 
    {helpb xtfifevd}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:xtfifevd_graph}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Graph Type}
{synopt:{opt coef:plot}}coefficient plot with confidence intervals 
    (default){p_end}
{synopt:{opt sec:ompare}}SE comparison: Pesaran-Zhou vs FEVD raw 
    (FEVD method only){p_end}
{synopt:{opt comb:ined}}both graphs side by side 
    (FEVD method only){p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level for CIs; default is 
    {cmd:level(95)}{p_end}
{synopt:{opt ti:tle(string)}}custom graph title{p_end}
{synopt:{opt sa:ving(string)}}export graph as PNG (without extension){p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
{cmd:xtfifevd_graph} is a post-estimation command. You must run 
{helpb xtfifevd} before calling this command.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtfifevd_graph} produces publication-quality graphs after estimation 
with {helpb xtfifevd}. It reads from the stored {cmd:e()} results and works 
with any dataset or variable specification {hline 1} no hardcoded variable 
names.

{pstd}
Three graph types are available:

{phang}
{bf:coefplot} (default): A horizontal coefficient plot showing all estimated 
parameters with confidence intervals. Time-varying coefficients (FE stage) 
are shown in blue, time-invariant coefficients in green, and the intercept 
in grey. The reference line at zero allows quick assessment of significance.
{p_end}

{phang}
{bf:secompare}: A bar chart comparing the Pesaran-Zhou corrected standard 
errors with the inconsistent FEVD stage-3 raw standard errors. This graph 
is only available after FEVD estimation. The SE ratio is displayed to 
quantify the size distortion.
{p_end}

{phang}
{bf:combined}: Both graphs displayed side by side.
{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Graph Type}

{phang}
{opt coefplot} displays a coefficient plot with confidence intervals.
This is the default if no graph type is specified. The plot color-codes 
coefficients by type: blue for time-varying (FE), green for 
time-invariant (FEF/FEVD), grey for the intercept.{p_end}

{phang}
{opt secompare} displays a bar chart comparing Pesaran-Zhou standard errors 
with FEVD raw standard errors for each time-invariant coefficient. This 
option is only available when {cmd:e(method)} is {cmd:FEVD}. For FEF and 
FEF-IV, only Pesaran-Zhou SEs are computed (there are no "raw" SEs to 
compare against).{p_end}

{phang}
{opt combined} displays both the coefficient plot and the SE comparison 
side by side. Only available for FEVD.{p_end}

{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level for the coefficient plot 
CIs. The default is {cmd:level(95)}.{p_end}

{phang}
{opt title(string)} specifies a custom title for the graph. If omitted, 
a default title based on the estimation method is used.{p_end}

{phang}
{opt saving(string)} exports the graph as a PNG file. Specify the filename 
without the {cmd:.png} extension.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup}{p_end}
{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}

{pstd}{bf:Example 1}: FEVD + default coefficient plot{p_end}
{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr)}{p_end}
{phang2}{cmd:. xtfifevd_graph}{p_end}

{pstd}{bf:Example 2}: FEF with robust + coefficient plot{p_end}
{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr) fef robust}{p_end}
{phang2}{cmd:. xtfifevd_graph, level(90)}{p_end}

{pstd}{bf:Example 3}: SE comparison (FEVD only){p_end}
{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr)}{p_end}
{phang2}{cmd:. xtfifevd_graph, secompare}{p_end}

{pstd}{bf:Example 4}: Combined plot, saved to file{p_end}
{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr)}{p_end}
{phang2}{cmd:. xtfifevd_graph, combined saving(fevd_results)}{p_end}

{pstd}{bf:Example 5}: Custom title{p_end}
{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr) fef robust}{p_end}
{phang2}{cmd:. xtfifevd_graph, title("Wage Equation: FEF Estimates")}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
merwanroudane920@gmail.com{break}
Independent Researcher
{p_end}
