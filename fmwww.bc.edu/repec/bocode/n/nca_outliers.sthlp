{smcl}
{* *! version 1.0 22 Aug 2025}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "nca_outliers##syntax"}{...}
{viewerjumpto "Description" "nca_outliers##description"}{...}
{viewerjumpto "Options" "nca_outliers##options"}{...}
{viewerjumpto "Remarks" "nca_outliers##remarks"}{...}
{viewerjumpto "Examples" "nca_outliers##examples"}{...}
{title:Title}
{phang}
{bf:nca_outliers} {hline 2} Detect necessary condition analysis (NCA) outliers on a dataset.

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:nca_outliers}
varlist
(numeric
min=2
max=2)
[{help if}]
[{help in}]
[{cmd:,}
{it:options}]

{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Required }
{synopt:{opt id:var(varname)}} an existing numeric identifier variable.

{syntab:Optional }
{synopt:{opt ceil:ing(string)}} name of the ceiling technique to be used. The default ceiling is {bf:ce_fdh}.

{synopt:{opt cor:ner(#)}} an integer indicating the corner to analyze. Default value is 1.

{synopt:{opt flipx}} reverse the direction of the condition variable.

{synopt:{opt flipy}} reverse the direction of the outcome variable.

{synopt:{opt k(#)}} use combinations of observations. Default value is 1.

{synopt:{opt mind:if(#)}} set the threshold for the minimum relative difference in the effect size to be considered as outlier. Default value is 0.01.

{synopt:{opt maxr:esults(#)}} maximum number of outliers to be shown. Default value is 25.

{synopt:{opt save(filename)}} saves the results in a data set whith the name given by filename. 

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd} Detect necessary condition analysis (NCA) outliers on a dataset. Leave-k-out analysis of observations on the ceiling line or on the scope is performed to evaluate their impact on the effect size. Potential outliers can be classified as {it:ceiling outliers} or {it:scope outliers}. For each point, the absolute variation on the effect size (dif_abs in the Stata output) and the relative variation on the effect size are considered (dif_rel in the Stata output).

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt id:var(varname)}  an existing numeric identifier variable.

{phang}
{opt ceil:ing(string)}  name of the ceiling technique to be used. The default ceiling is ce_fdh.

{phang}
{opt cor:ner(#)}  an integer indicating the corner to analyze. Default value is 1. Corner 1 is the upper-left corner and corner 2 is the upper-right corner. These two corners are used for an analysis of the necessity of the presence/high level if x (corner = 1 ) or the absence/low level if x (corner = 2) for the presence/high level of y, respectively.
Corner 3 is the lower-left corner and corner 4 is the lower-right corner. These two corners are used for an analysis of the necessity of the presence/high level of x ({opt corner}(3)) or the absence/low level if x ({opt corner}(4)) for the absence/low level of y, respectively.
By default the upper left corner is analysed for all independent variables and corner is not defined. If {opt corner} is defined, {opt flipx} and {opt flipy} are ignored.

{phang}
{opt flipx} reverse the direction of the condition variable.  

{phang}
{opt flipy} reverse the direction of the outcome variable.  

{phang}
{opt k(#)} use combinations of observations. Default value is 1. 

{phang}
{opt mind:if(#)} set the threshold for the minimum relative difference in the effect size to be considered as outlier. Default value is 0.01.  

{phang}
{opt maxr:esults(#)} maximum number of outliers to be shown. Default value is 25. 

{phang}
{opt save(string asis)} saves the results in a data set whith the name given by filename. 
  



{marker examples}{...}
{title:Examples}
{phang2}{cmd:. nca_outliers individualism innovationperformance, id(country) ceiling(ce_fdh)}{p_end}


{title:Author}
{pstd}Daniele Spinelli{p_end}
{pstd}Department of Statistics and Quantitative Methods {p_end}
{pstd}University of Milano-Bicocca{p_end}
{pstd}Milan, Italy{p_end}
{pstd}daniele.spinelli@unimib.it{p_end}

