{smcl}
{* *! version 1.0  6 Apr 2018}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "network_compare##syntax"}{...}
{viewerjumpto "Description" "network_compare##description"}{...}
{viewerjumpto "Examples" "network_compare##examples"}{...}
{title:Title}

{phang}
{bf:network compare} {hline 2} Tabulate all comparisons estimated in  a network meta-analysis


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:network compare}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Display}
{synopt:{opt ef:orm}}The estimated contrasts are exponentiated and reported with confidence intervals. Default is estimated contrasts and standard errors.{p_end}
{synopt:{opt l:evel(cilevel)}}Specify confidence level (used with {cmd:eform}).{p_end}
{synopt:{opt f:ormat(string)}}Specify display {help format} of estimates. Default is %6.3f.{p_end}
{synopt:{it:tabdisp_options}}Any other options for {help tabdisp}.{p_end}
{syntab:Storage}
{synopt:{opt sa:ving(string)}}The estimated contrasts are saved in the named file.{p_end}
{synopt:{opt r:eplace}}The file named in saving() may be overwritten.{p_end}
{synopt:{opt cl:ear}}The estimated contrasts are loaded into  memory.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}
{cmd:network_compare} follows fitting a consistency model using {help network meta}.
It estimates the treatment effect between all pairs of treatments and displays them in a table.

{marker examples}{...}
{title:Examples}

{pstd}Load the smoking data:

{pin}. {stata "use http://www.homepages.ucl.ac.uk/~rmjwiww/stata/meta/smoking, clear"}

{pin}. {stata "network setup d n, studyvar(stud) trtvar(trt)"}

{pstd}Fit the consistency model:

{pin}. {stata "network meta c"}

{pstd}Tabulate comparisons as odds ratios to 2 decimal places:

{pin}. {stata "network compare, eform format(%5.2f)"}


{p}{helpb network: Return to main help page for network}

