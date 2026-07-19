{smcl}
{* *! version 1.0.0  18jul2026}{...}
{vieweralsosee "xtvsom" "help xtvsom"}{...}
{vieweralsosee "xtrobust" "help xtrobust"}{...}
{vieweralsosee "xtlossf" "help xtlossf"}{...}
{vieweralsosee "xtoutliers methods" "help xtoutliers_methods"}{...}
{viewerjumpto "Commands" "xtoutliers##commands"}{...}
{viewerjumpto "Description" "xtoutliers##description"}{...}
{viewerjumpto "Examples" "xtoutliers##examples"}{...}
{viewerjumpto "References" "xtoutliers##references"}{...}
{viewerjumpto "Author" "xtoutliers##author"}{...}
{title:Title}

{phang}
{bf:xtoutliers} {hline 2} Outlier detection and robust estimation for panel data

{marker description}{...}
{title:Description}

{pshalf}
{cmd:xtoutliers} is a suite of three complementary tools for handling outliers
in linear panel-data models. Each addresses a different response to outliers:
{it:detect}, {it:accommodate}, and {it:robustify}. Typing {cmd:xtoutliers}
prints this overview.{p_end}

{marker commands}{...}
{title:Commands}

{synoptset 14 tabbed}{...}
{synopt:{helpb xtvsom}}Variance Shift Outlier Model (VSOM): detects and
accommodates outliers by shifting (down-weighting) their variance. Runs as a
{help xtvsom_postestimation:postestimation} companion to {helpb xtreg} (fixed
effects), {helpb regress} (pooled) and {helpb ivregress} (2SLS / simultaneous),
or standalone.{p_end}
{synopt:{helpb xtrobust}}Robust estimation of fixed- and random-effects panels
with the S-estimator and the Weighted Likelihood Estimator (WLE), compared with
OLS.{p_end}
{synopt:{helpb xtlossf}}Distribution-free outlier detection via loss functions,
for nonnegative (Part I) and mixed-sign (Part II) data.{p_end}
{synopt:{helpb xtoutliers_methods:xtoutliers methods}}Equation-by-equation
methods and the code{c 174}paper compatibility map.{p_end}
{synoptline}

{marker examples}{...}
{title:Examples}

{pstd}Detect and accommodate outliers after a fixed-effects fit:{p_end}
{phang2}{cmd:. webuse nlswork}{p_end}
{phang2}{cmd:. xtreg ln_wage age tenure hours, fe}{p_end}
{phang2}{cmd:. xtvsom, graph}{p_end}

{pstd}Robust fixed-effects estimation:{p_end}
{phang2}{cmd:. xtrobust ln_wage age tenure hours, fe method(all) graph}{p_end}

{pstd}Loss-function detection comparing two data versions:{p_end}
{phang2}{cmd:. xtlossf pop2010 pop2020 , q(-0.5) graph}{p_end}

{marker references}{...}
{title:References}

{phang}Ismadyaliana, S., Setiawan, and J.D.T. Purnomo. 2024. Panel data
modeling: Identifying and handling outliers with the VSOM approach.
{it:MethodsX} 13: 102900.{p_end}

{phang}Jaseem, H.N., and L.A. Mohammad. 2024. Detecting Outliers and Using
Robust Methods in Linear Panel Data Model. {it:Al-Nahrain Journal of Science}
27(4): 40{c 45}46.{p_end}

{phang}Coleman, C.D., and T. Bryan. 2025. Loss Functions for Detecting Outliers
in Panel Data. arXiv:2509.07014v2.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
