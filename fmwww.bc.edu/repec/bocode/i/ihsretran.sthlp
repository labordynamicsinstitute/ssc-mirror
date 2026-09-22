{smcl}
{* *! version 1.1.0  19sep2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[R] margins" "help margins"}{...}
{viewerjumpto "Syntax" "ihsretran##syntax"}{...}
{viewerjumpto "Description" "ihsretran##description"}{...}
{viewerjumpto "Options" "ihsretran##options"}{...}
{viewerjumpto "Remarks" "ihsretran##remarks"}{...}
{viewerjumpto "Examples" "ihsretran##examples"}{...}
{viewerjumpto "Stored results" "ihsretran##results"}{...}
{viewerjumpto "References" "ihsretran##references"}{...}
{viewerjumpto "Author" "ihsretran##author"}{...}

{title:Title}

{phang}
{bf:ihsretran} {hline 2} Marginal effects on the original scale for linear regression with an inverse hyperbolic sine (IHS) transformed dependent variable using Duan's smearing estimate.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ihsretran}
{depvar}
{indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt sc:ale(#)}}scaling factor multiplier for the dependent variable; default is {cmd:scale(1.0)}{p_end}
{synopt:{opt gen:erate(newvar)}}generate a new variable containing retransformed predicted values on the original scale{p_end}
{synopt:{opt lev:el(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{cmd:fweights}, {cmd:iweights}, and {cmd:pweights} are not allowed. Robust standard errors are automatically applied via {cmd:vce(robust)}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:ihsretran} calculates consistent marginal effects on the original scale of the outcome variable after estimating a linear regression where the dependent variable has been transformed using the inverse hyperbolic sine function [{cmd:asinh()}]. 

{pstd}
The command implements Duan's (1983) nonparametric smearing estimate to handle the retransformation problem from the logarithmic components of the hyperbolic sine function, as detailed by Edward C. Norton (2022). This allows researchers to accurately interpret marginal effects when the dependent variable contains zeros or negative values and exhibits a right-skewed distribution.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt scale(#)} specifies a scaling factor multiplier for the dependent variable prior to taking the inverse hyperbolic sine transformation. Because the IHS transformation is not scale-invariant (Aihounton & Henningsen, 2021), this option allows researchers to test sensitivity or replicate specific scaling setups. The default is {cmd:scale(1.0)}.

{phang}
{opt generate(newvar)} creates a new variable containing the retransformed predicted values on the original scale of the dependent variable, adjusted using Duan's smearing factor.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence intervals. The default is {cmd:level(95)}.


{marker remarks}{...}
{title:Remarks}

{pstd}
When the dependent variable is transformed using {cmd:asinh(scale * y)}, regression coefficients cannot be interpreted directly as marginal effects or elasticities. {cmd:ihsretran} solves this by applying Duan's smearing retransformation analytically through Stata's {cmd:margins} command, yielding accurate population-averaged marginal effects on the natural data scale.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}Calculate IHS marginal effects for price on weight and length{p_end}
{phang2}{cmd:. ihsretran price weight length}{p_end}

{pstd}Calculate with a scaling factor and save retransformed predictions{p_end}
{phang2}{cmd:. ihsretran price weight length, scale(0.001) generate(price_pred)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:ihsretran} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(r2)}}R-squared from the IHS regression{p_end}
{synopt:{cmd:r(duan)}}Duan's smearing factor ({it:D}){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:ihsretran}{p_end}


{marker references}{...}
{title:References}

{phang}
Aihounton, G. B. D., and A. Henningsen. 2021. Units of measurement and the inverse hyperbolic sine transformation. {it:Econometric Journal} 24(2): 334–351.

{phang}
Duan, N. 1983. Smearing estimate: A nonparametric retransformation method. {it:Journal of the American Statistical Association} 78(383): 605–610.

{phang}
Norton, E. C. 2022. The inverse hyperbolic sine transformation and retransformed marginal effects. {it:The Stata Journal} 22(3): 702–712.


{marker author}{...}
{title:Author}

{pstd}
{bf:Dereje Fedasa}{break}
Department of Economics{break}
Dire Dawa University, Ethiopia{break}
Email:derejefedasaa@gmail.com{break}
{break}
Based on the methodology by Edward C. Norton (2022).
{p_end}
