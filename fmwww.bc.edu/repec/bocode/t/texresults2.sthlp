{smcl}
{* *! version 10.0 29aug2023}{...}
{viewerdialog texresults2 "dialog texresults2"}{...}
{viewerjumpto "Syntax" "texresults2##syntax"}{...}
{viewerjumpto "Description" "texresults2##description"}{...}
{viewerjumpto "Options" "texresults2##options"}{...}
{viewerjumpto "Examples" "texresults2##examples"}{...}

{p2col:{bf:texresults2}} Improved version of texresults to create external file of LaTex macros with results

{marker syntax}{...}
{title:Syntax}
{p}
{cmd:texresults2 using} {filename}{cmd:,} {opt textmacro(macroname)} [{options}]

{hline}
{marker description}{...}
{title:Description}
{pstd}
{cmd:texresults2} The original Texresults command was created by Alvaro Carril to store results computed in Stata as  Latex macros in a text file. The external text file can be used in LaTeX to to reference results by their macro. 


{pstd}
As noted by Carril "One of the main advantages of a Stata/Latex workflow is the automatic updating of tables and figures. For instance, if we add a new control variable to a regression, we can correct the do-file that produces a table of coefficients and compile the latex document again to see the updates table. However, that advantage doesn’t extend to in-text mentions of coefficients (or other results). This leads to documents that contain inconsistent results, which have to be manually checked every time a preliminary result changes. This situation can be remedied by creating an external file with LaTeX macros that store all cited results of an analysis. Using these macros instead of manually copying results in the text is much less error prone, and we can be certain that results are consistent throughout the document."


{pstd}
While the original texresults was very helpful, tesresults2 improves upon some bugs and adds functionality. First, due to the use of the round command in the original texresults program, occasionally an error is produced where stata is unable to correctly hold and format certain decimal results. Texresults2 fixes this error by converting results to a string format and using associated stata formatting rules before exporting. 

{pstd}
The original texresults only had functionality to export p-values when estimation commands relied on a t-distribution to calculate said p-values (IE Ordinary Least Squares regression). Texresults2 builds out this functionality to include exporting pvalues calculate with a z-distribution (IE Logit or Probit regressions). Texresults2 also includes the ability to directly export the upper and lower bound values for a 95% confidence interval around an estimation. 


{hline}
{marker options}{...}
{title:Options}

{cmd:Result} - options mutually exclusive 
{phang}{opt result(real)} specify any result to be stored in macroname; see Result below

{phang}{opt coef(varname)} coefficient to be stored in macroname

{phang}{opt se(varname)} standard error to be stored in macroname

{phang}{opt tstat(varname)} t-stat to be stored in macroname

{phang}{opt pvalue(varname)} p-value (calculated using a t-stat)  to be stored in macroname

{phang}{opt pvaluez(varname)} p-value (calculated using a z-stat)  to be stored in macroname

{phang}{opt lb(varname)} lower bound of a 95% confidence interval (calculated using a t-stat to)  be stored in macro name 

{phang}{opt ub(varname)} upper bound of a 95% confidence interval (calculated using a t-stat to)  be stored in macro name 

{phang}{opt lbz(varname)} lower bound of a 95% confidence interval (calculated using a z-stat to)  be stored in macro name 

{phang}{opt ubz(varname)} upper bound of a 95% confidence interval (calculated using a z-stat to)  be stored in macro name 

{cmd:File} 

{phang}{opt textmacro(macroname)} name of new LaTeX macro (without backslash) - required

{phang}{opt replace} Replace filename

{phang}{opt append} Append filename

{cmd:Formatting}

{phang}{opt round(real)} round to the number of decimal places specified by the given integer.

{hline}
{marker examples}{...}
{title:Examples}

{pstd}Setup (OLS) 

{phang2}{cmd:. sysuse auto}

{phang2}{cmd:. regress mpg trunk weight foreign}

{pstd} Store root MSE of model in "results.txt", rounded by default to 2 decimal digits (default), with macroname "\rmse":

{phang2}{cmd:. texresults2 using results.txt, texmacro(rmse) result(e(rmse))}

{pstd} Append foreign coefficient macro to "results.txt", rounded to 1 decimal digit. The created macro is "\forgiencoef":

{phang2}{cmd:. texresults2 using results.txt, texmacro(forgiencoef) coef(foreign) round(1) append}

{pstd} Append the values of the lower bound of the 95% confidence interval for the foreign coefficient macro to "results.txt", rounded to 3 decimal digits. The created macro is "\lbforgien":

{phang2}{cmd:. texresults2 using results.txt, texmacro(lbforgien) lb(foreign) round(3) append}

{pstd}Setup (Logit) 

{phang2}{cmd:. Logit foreign trunk weight mpg}

{pstd} Append trunk coefficient macro to "results.txt", rounded to 1 decimal digit. The created macro is "\forgiencoef":

{phang2}{cmd:. texresults2 using results.txt, texmacro(trunkcoef) coef(trunk) round(1) append}

{pstd} Append the values of the lower bound of the 95% confidence interval for the foreign coefficient macro to "results.txt", rounded to 3 decimal digits. The created macro is "\lbtrunk:" Note the use of the lbz option because inference with logit regressions operates using a z distribution. 

{phang2}{cmd:. texresults2 using results.txt, texmacro(lbtrunk) lbz(trunk) round(3) append}


{phang2}Text Document Produced 

\newcommand{\rmse}{$3.42$}
\newcommand{\forgiencoef}{$-1.6$}
\newcommand{\lbforgien}{$-3.762$}
\newcommand{\trunkcoef}{$0.0$}
\newcommand{\lbtrunk}{$-0.195$}


{hline}
