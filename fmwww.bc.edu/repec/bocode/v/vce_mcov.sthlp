{smcl}
{* *! version 1.0  5 Dec 2023}{...}
{viewerjumpto "Syntax" "vce_mcov##syntax"}{...}
{viewerjumpto "Description" "vce_mcov##description"}{...}
{viewerjumpto "References" "vce_mcov##references"}{...}
{viewerjumpto "Examples" "vce_mcov##examples"}{...}
{viewerjumpto "Authors" "vce_mcov##authors"}{...}
{title:Title}
{phang}
{bf:vce_mcov} {hline 2} computes the Leave-Cluster-Out-Crossfit (LCOC)  variance estimates for user-chosen coefficients in a linear regression model.

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmd:vce_mcov}
{ifin}
[{cmd:,} {it:numvars} ...]

{synoptset 24}{...}
{synopthdr:}
{synoptline}
{synopt :{it:numvars}} Specify an integer k (default is 1). The first k independent variables from {cmd: reg} will have their variance estimates replaced. {p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}
{pstd}{cmd:vce_mcov} is an eclass command that can be used after running {cmd: reg}. It replaces the entries of the variance matrix (stored in {cmd:e(V)}) relating to user-chosen parameter(s) of inferential interest with the Leave-Cluster-Out-Crossfit (LCOC) estimates (see Anatolyev and Ng, 2024). All postestimation commands will work as usual. 

{marker references}{...}
{title:References}
{pstd}
Stanislav Anatolyev and Cheuk Fai Ng (2024), Cluster Robust Inference in Linear Regression Models with Many Covariates.

{pstd}
Stanislav Anatolyev (2019), Many instruments and/or regressors: a friendly guide, Journal of Economic Surveys, vol. 33, no. 2, pp. 689-726

{marker examples}{...}
{title:Examples}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse nlsw88}{p_end}
{phang2}{cmd:. sort idcode}{p_end}
{pstd}Regress wages on multiple covariates using {cmd: reg}. Note that vce(cluster clusvar) option must be speficied.{p_end}
{phang2}{cmd:. reg wage c.tenure##c.ttl_exp i.collgrad i.union, vce(cluster idcode)}{p_end}
{pstd}Replace the default robust estimates relating to the first three coefficients with the LCOC estimates.{p_end}
{phang2}{cmd:. vce_mcov if idcode != ., numvars(3)}{p_end}
    {hline}


{marker authors}{...}
{title:Authors}
{p}
{p_end}
{pstd}
Stanislav Anatolyev, CERGE-EI, Prague, Czechia.

{pstd}
Email: {browse "Stanislav Anatolyev:stanislav.anatolyev@cerge-ei.cz ":stanislav.anatolyev@cerge-ei.cz }

{pstd}
Cheuk Fai Ng, University of Cambridge, Cambridge, UK.

{pstd}
Email: {browse "Cheuk Fai Ng:cfn24@cam.ac.uk":cfn24@cam.ac.uk}



