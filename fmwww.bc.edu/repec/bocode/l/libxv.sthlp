{smcl}
{* *! version 0.0.5 01mar2024}{...}
{vieweralsosee "[R] predict" "mansection R predict"}{...}
{vieweralsosee "[R] estat classification" "mansection R estat_classification"}{...}
{vieweralsosee "[P] creturn" "mansection P creturn"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "libxv##syntax"}{...}
{viewerjumpto "Description" "libxv##description"}{...}
{viewerjumpto "Options" "libxv##options"}{...}
{viewerjumpto "Overview" "libxv##overview"}{...}
{viewerjumpto "Utility Functions" "libxv##utilities"}{...}
{viewerjumpto "Classification Metrics" "libxv##classification"}{...}
{viewerjumpto "Binary Metrics" "libxv##binary"}{...}
{viewerjumpto "Multiclass Metrics" "libxv##multiclass"}{...}
{viewerjumpto "Regression Metrics" "libxv##regression"}{...}
{viewerjumpto "Custom Metrics" "libxv##custom"}{...}
{viewerjumpto "Additional Information" "libxv##additional"}{...}
{viewerjumpto "Contact" "libxv##contact"}{...}
{title:}

{marker syntax}{...}
{title:Syntax}

{p 8 32 2}
{cmd:libxv} [{cmd:,} {cmdab:dis:play} ]{p_end}

{synoptset 15 tabbed}{...}
{synoptline}
{synopthdr}
{synoptline}
{synopt :{opt dis:play}}display this helpfile at the completion of the ado; default is {cmd:off}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
The {cmd:libxv} command is used to compile, or recompile, the Mata sourcecode 
for the Mata library included with the {help crossvalidate} package.  This 
provides end users of {help crossvalidate} with an easy to use interface to keep 
the compiled mata library up to date, while being able to take advantage of any 
improvements or optimizations made to Mata since Stata 15.  Additionally, it 
makes it easier for the authors to distribute the package by providing a way to 
compile the library on the user's machine instead of compiling the library 
ahead of time.

{pstd}
{bf:IMPORTANT!!!} This command will clear the contents of Mata prior to running 
the {it:crossvalidata.mata} file and adding the functions to the Mata library 
named libxv.  {help xv} and {help xvloo} will call this command automatically 
if the compiled Mata library is not found.  If the compiled library does not 
exist and you are attempting to use a custom defined metric, you should call 
this command first, then define your custom defined metric, and then use either 
of the {help xv} or {help xvloo} prefix commands.   

{pstd}
This will only recompile the library if it is necessary to do so.  As updates 
are made to the source code, the command will check a date embedded in the 
script and compare it to a hardcoded date to determine if the source code is 
has been updated since the previous release.  Following recompilation, the 
program will also trigger Mata to rebuild the library index to make sure it can 
find this library and all of the other Mata libraries on your system.  

{pstd}
Additional information is provided below on the contents of the Mata library.  
We've categorized the functions and struct definition based on their role in 
the {help crossvalidation} package.  There are a small number of utility 
functions and a much larger number of functions defined for model validation 
purposes.

{marker options}{...}
{title:Options}

{phang}
{opt dis:play} is an option to display this help file at completion of the ado.

{marker overview}{...}
{title:Overview of Libxv}

{pstd}
{cmd:libxv} is the Mata library that enables the {help xv}, {help xvloo}, and 
other commands in the {help crossvalidate} package to do what they do.  All of 
the validation/test metrics are defined as Mata {help m2_declarations:functions}.  
There are also functions that are used for the 
{browse "https://wbuchanan.github.io/stataConference2023/":metaprogramming} 
techniques that allow the user to specify their model fitting commands the same 
way they would any other time they are using Stata.  However, the bulk of this 
Mata library is comprised of validation/test metrics.  All metrics used by the 
command {help validateit} follow the same function signature:

{pstd}
real scalar {it:functionName}(string scalar pred, string scalar obs, string scalar touse)

{pstd}
This standardized function signature makes it possible for users to write and 
call their own validation metrics without having to do any of the heavy lifting 
associated with any other part of the cross-validation process.  However, it 
also imposes some restrictions on what and/or how things can be done.  For 
example, metrics for multiclass methods that would return a value for each of 
the classes being predicted cannot be handled.  Functions that might otherwise 
allow the specification of a parameter to adjust the computation are also 
unable to be accommodated.  If you find the need to use that type of a 
validation/test metric, you could still avoid having to write an entire 
cross-validation pipeline by using {help splitit} and {help fitit} to do that 
work for you.  Then, predict the values of interest and compute your metric.  If 
what we've provided in this package already meets your needs, feel free to use 
the {help xv} prefix instead to let the computer do the work.

{marker utilities}{...}
{title:Utility Functions}

{pstd}
{cmd:getifin} is a utility function used to extract {ifin} expressions from the 
estimation command used by the user.  The returned string then allows the 
commands in {help crossvalidate} to modify these expressions to ensure that the 
model is fitted on the appropriate subset of data and the predictions are made 
on the correct subset of data.

{pstd}
{cmd:getnoifin} in the case where the user does not pass an estimation command 
with {ifin} expressions, this function is used to extract the estimation command 
string up to the comma used to delimit options to the command. The returned 
string then allows the commands in {help crossvalidate} to modify the estimation 
command to include an if expression to ensure that the model is fitted on the 
appropriate subset of data and the predictions are made on the correct subset of 
data.

{pstd}
{cmd:hasoptions} is a convenience function used to determine if the estimation 
command passed by the user contains options.

{pstd}
{cmd:cvparse} is a function used by the {help xv} and {help xvloo} prefix 
commands to parse options passed to the command.  It returns valid options in 
local macros using the name of the option.  In effect, this makes all of the 
options for {help xv} and {help xvloo} operate as {it:passthru} type options 
(see {help syntax} for additional information about passthru).  

{pstd}
{cmd:getarg} is a function used by the {help xv} and {help xvloo} prefix 
commands to extract the arguments passed to the options of those commands. 
Additionally, it is used to parse arguments that will be passed to the functions 
specified in the {opt monitors} and {opt metric} options of {help xv}, 
{help xvloo}, and/or {help validateit}.  For additional information, see the 
{help validateit##custom:Custom Metrics and Monitors} section of the 
{cmd:validateit} help file. 

{pstd}
{cmd:getname} is a function used internally by the {it:getstats} subroutine of 
the {help validateit} command.  In order to provide users the flexibility to 
define their own customized metric/monitor functions (see 
{help validateit##custom:Custom Metrics and Monitors} for additional info) and 
to provide a method to pass optional arguments to these functions, we need to 
parse the function name reference from the string that includes any possible 
optional arguments.  This function enables that functionality.

{pstd}
{cmd:struct Crosstab} is a struct defined in {opt libxv}.  It stores the 
following results in the corresponding members:

{synoptset 15 tabbed}{...}
{synoptline}
{synopthdr:Member Name}
{synoptline}
{synopt :{opt conf}}The confusion matrix{p_end}
{synopt :{opt rowm}}A column vector containing the row margins from the confusion matrix{p_end}
{synopt :{opt correct}}A column vector containing the diagonal of the confusion matrix{p_end}
{synopt :{opt values}}A column vector containing the unique values of the dependent variable.{p_end}
{synopt :{opt colm}}A row vector containing the column margins from the confusion matrix{p_end}
{synopt :{opt n}}A scalar containing the total sample size.{p_end}
{synopt :{opt tp}}A scalar containing the total number of correctly predicted outcomes.{p_end}
{synopt :{opt levs}}A scalar containing the number of distict levels of the dependent variable.{p_end}
{synoptline}

{pstd}
{cmd:xtab} is a function that returns a scalar instance of the 
{cmd:Crosstab struct}.  It is used internally by the binary and multiclass 
metrics to obtain the confusion matrix and other pre-computed statistics that 
are used regularly by the metrics.

{pstd}
{cmd:isnested} is a function used to test whether variables are nested within 
one another.  It takes a {help varlist} containing the variables that are nested 
ordered from the highest to lowest level of the hierarchy and a {help varname} 
that is used to identify which observations to include in the test.  A value of 
1 is returned if the data are nested and a value of 0 is returned otherwise. 

{pstd}
{cmd:distdate} is a function used to retrieve the distribution/version date from 
files distributed with {help crossvalidate}.  This is used to test whether it is 
necessary to recompile the source code for the Mata library so users can have a 
copy of the library compiled for their version of Stata.

{pstd}
{cmd:dpois} is a porting of the {it:dpois} function from R which implements the 
Poisson density function.

{marker classification}{...}
{title:Classification Metrics}

{pstd}
In addition to reiterating what was said above about multiclass metrics, there 
also needs to be a discussion about methods related to probabilities only 
such as ROC/AUC type metrics and how those are not currently handled, but could 
potentially be in the future.  There should also be a mention about noting that 
some of the binary metrics that generalize naturally to the multiclass context 
are used under the hood by the multiclass functions and can be used in both 
scenarios (with the specifics being reserved to the sections below).

{marker binary}{...}
{title:Binary Metrics}

{synoptset 15 tabbed}{...}
{synoptline}
{synopthdr:Name}
{synoptline}
INCLUDE help xvbintab
{synoptline}

INCLUDE help xvbinmtrx

{marker multiclass}{...}
{title:Multiclass Metrics}

{synoptset 15 tabbed}{...}
{synoptline}
{synopthdr:Name}
{synoptline}
INCLUDE help xvmctab
{synoptline}
{synopt :{opt ***}  {it:Note this requires installation of {search polychoric}}}

INCLUDE help xvmcmtrx

{marker regression}{...}
{title:Regression Metrics}

{synoptset 15 tabbed}{...}
{synoptline}
{synopthdr:Name}
{synoptline}
INCLUDE help xvconttab
{synoptline}

INCLUDE help xvcontmtrx

{marker custom}{...}
{title:Custom Metrics}
{* * Not sure what additional information might be useful here.}
{pstd}
Users may define their own validation metrics to be used by {cmd:validateit}.  
All metrics and monitors are required to use the same function signature:

{pstd}
real scalar {it:functionName}(string scalar pred, string scalar obs, string scalar touse)

{pstd}
The first argument passed to your function will be the name of the variable 
containing the predicted values.  The second argument passed to your function 
will be the name of the variable containing the observed outcomes.  The last 
argument in the signature is a variable that identifies the validation/test set, 
or the K-Fold with the out-of-sample predicted values, to compute the validation 
metric on.

{pstd}
In your function, you can easily define the vectors that will store the data you 
need for your computations:

{p 12 12 2}{cmd:{it:real colvector y, yhat}}{p_end}
{p 12 12 2}{cmd:{it:y = st_data(., obs, touse)}}{p_end}
{p 12 12 2}{cmd:{it:yhat = st_data(., pred, touse)}}{p_end}

{pstd}
With your custom metric function defined in Mata with the signature above, you 
can use it as a metric or monitor with {cmd:validateit} by passing the function 
name to the metric or monitors options.  {it:Note, you will need to make sure 
that the function is defined in Mata prior to using it or ensure that it is 
defined in a library that Mata will search automatically}.

{marker additional}{...}
{title:Additional Information}
{p 4 4 8}If you have questions, comments, or find bugs, please submit an issue in the {browse "https://github.com/wbuchanan/crossvalidate":crossvalidate GitHub repository}.{p_end}

{marker contact}{...}
{title:Contact}
{p 4 4 8}William R. Buchanan, Ph.D.{p_end}
{p 4 4 8}Sr. Research Scientist, SAG Corporation{p_end}
{p 4 4 8}{browse "https://www.sagcorp.com":SAG Corporation}{p_end}
{p 4 4 8}wbuchanan at sagcorp [dot] com{p_end}

{p 4 4 8}Steven D. Brownell, Ph.D.{p_end}
{p 4 4 8}Economist, SAG Corporation{p_end}
{p 4 4 8}{browse "https://www.sagcorp.com":SAG Corporation}{p_end}
{p 4 4 8}sbrownell at sagcorp [dot] com{p_end}
