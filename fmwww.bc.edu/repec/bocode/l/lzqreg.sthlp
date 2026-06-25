{smcl}
{* *! version 1.0.0  25apr2026}{...}
{vieweralsosee "qreg" "help qreg"}{...}
{vieweralsosee "qreg postestimation" "help qreg postestimation"}{...}
{viewerjumpto "Syntax" "lzqreg##syntax"}{...}
{viewerjumpto "Description" "lzqreg##description"}{...}
{viewerjumpto "Options" "lzqreg##options"}{...}
{viewerjumpto "Stored results" "lzqreg##results"}{...}
{viewerjumpto "Examples" "lzqreg##examples"}{...}
{viewerjumpto "Author" "lzqreg##author"}{...}
{viewerjumpto "References" "lzqreg##references"}{...}
{title:Title}

{phang}
{bf:lzqreg} {hline 2} Quantile regression to analyze logarithmic relationships with non-positive values in the outcome variable{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:lzqreg}
{depvar}
[{indepvars}]
{ifin}
{weight}
[{cmd:,} {help qreg##qreg_options:{it:qreg_options}}]{p_end}

{p 4 6 2}
{opt fweight}s, {opt iweight}s, and {opt pweight}s are allowed; see
{help weight}.{p_end}

{p 4 6 2}
See {helpb qreg postestimation} for features available after estimation.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:lzqreg} fits a quantile regression model where the raw dependent variable,
specified in {depvar}, is transformed with a calibrated extensive margin (CEM)
transformation of the form{p_end}

{phang2}
{it:y*} = ln({depvar}) {space 6} if {depvar} > 0{break}
{it:y*} = {bf:-psi} {space 2} if {depvar} {ul:<}= 0.{p_end}

{pstd}
{cmd:lzqreg} is essentially a wrapper for {helpb qreg}.
If the fitted values of a quantile regression on this CEM-transformed outcome
are all greater than -psi, then results are displayed. The resulting coefficients can be meaningfully interpreted as logarithmic intensive-margin relationships between the outcome variable and
the independent variables, even with non-positive values in the outcome
variable. If the condition does not hold for the specified quantile, then the command iteratively makes psi larger and checks again. After ten iterations where the condition does not hold,  {cmd:lzqreg} returns an error and suppresses results. This implementation is an automated adaptation of the algorithm described
by Liu & Kaplan (2025).{p_end}

{pstd}
All estimation options, weight types, and postestimation features supported
by {helpb qreg} are available with {cmd:lzqreg}.{p_end}


{marker options}{...}
{title:Options}

{pstd}
See {help qreg##qreg_options:qreg_options}.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:lzqreg} stores the same results in {cmd:e()} as {helpb qreg}, with the
following differences:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:lzqreg}{p_end}
{synopt:{cmd:e(depvar)}}name of the original (untransformed) dependent variable, displayed as {cmd:ln(}{it:depvar}{cmd:)} in output{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{p2colreset}{...}

{pstd}
All other {cmd:e()} scalars, matrices, and macros are as documented in
{helpb qreg}.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Consider the NLSW88 dataset.{p_end}

{phang2}{cmd:. sysuse nlsw88, clear}{p_end}

{pstd}Variable {bf:tenure} is equal to zero for just over 2% of observations.{p_end}

{phang2}{cmd:. tab tenure}{p_end}

{pstd}Because the median of {bf:tenure}, conditional on {bf:collgrad}, is above
zero for all values of {bf:collgrad}, the log difference between {bf:tenure}'s
conditional medians is defined. {cmd:lzqreg} thus returns results at quantile
0.5.{p_end}

{phang2}{cmd:. lzqreg tenure collgrad, quantile(0.5)}{p_end}

{pstd}However, the first percentile of {bf:tenure}, conditional on {bf:collgrad},
is not above zero for all values of {bf:collgrad}, so {cmd:lzqreg} suppresses
results and returns an error at quantile 0.01.{p_end}

{phang2}{cmd:. lzqreg tenure collgrad, quantile(0.01)}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Written by Jack Fitzgerald ({browse "mailto:jackfitzgeraldresearch@gmail.com":jackfitzgeraldresearch@gmail.com})
with assistance from Claude. Based on {bf:qreg} (StataCorp).{p_end}


{marker references}{...}
{title:References}

{phang}
Fitzgerald, J., Adema, J., Fiala, L., Kujansuu, E., & Valenta, D. (2026).
"Non-Robustness in Log-Like Specifications." MetaArXiv.
{browse "https://doi.org/10.31222/osf.io/juda7_v1"}{p_end}

{phang}
Liu, X., & Kaplan, D. M. (2025). "Quantile Regression with Log(0) Outcomes."
{browse "https://drive.google.com/file/d/1F3dnhm8MrlO5aRrGt48rBWAEaBqdCBH-/view"}{p_end}


{title:Also see}

{psee}
Manual: {bf:[R] qreg}{p_end}

{psee}
Online: {helpb qreg}, {helpb qreg postestimation}{p_end}
