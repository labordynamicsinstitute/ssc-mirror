{smcl}
{* *! version 0.0.7 06mar2024}{...}
{viewerjumpto "Syntax" "splitit##syntax"}{...}
{viewerjumpto "Description" "splitit##description"}{...}
{viewerjumpto "Options" "splitit##options"}{...}
{viewerjumpto "Examples" "splitit##examples"}{...}
{viewerjumpto "Returned Values" "splitit##retvals"}{...}
{viewerjumpto "Additional Information" "splitit##additional"}{...}
{viewerjumpto "Contact" "splitit##contact"}{...}
{title:Dataset Splitting and Folding for Cross-Validation in Stata}

{marker syntax}{...}
{title:Syntax}

{p 8 32 2}
{cmd:splitit} # [#] {ifin} [{cmd:,} {cmdab:u:id(}{it:varlist}{cmd:)} 
{cmdab:tp:oint(}{it:string asis}{cmd:)} {cmdab:k:fold(}{it:integer}{cmd:)} 
{cmdab:spl:it(}{it:string asis}{cmd:)} {cmd:loo}]{p_end}

{synoptset 15 tabbed}{...}
{synoptline}
{synopthdr}
{synoptline}
{syntab:Arguments}
{synopt :{opt #}}The proportion of the data set to allocate to the training set.{p_end}
{synopt :{it:{opt [#]}}}The proportion of the data set to allocate to the validation set.{p_end}
{syntab:Options}
{synopt :{opt u:id}}a variable list for clustered sampling/splitting{p_end}
{synopt :{opt tp:oint}}a numeric, td(), tc(), or tC() value{p_end}
{synopt :{opt k:fold}}the number of K-Folds to create in the training set; default is {cmd:kfold(1)}{p_end}
{synopt :{opt spl:it}}a new variable name; default is {cmd:split(_xvsplit)}{p_end}
{synopt :{opt loo}}is used only for Leave-One-Out cross-validation{p_end}
{synoptline}

{marker description}{...}
{title:Description}

INCLUDE help xvphase-split

{marker options}{...}
{title:Options}

{phang}
{opt u:id} accepts a variable list for clustered sampling/splitting.  When an 
argument is passed to this parameter entire clusters will be split into the 
respective training and validation and/or training sets.  When this option is 
used with {opt tp:oint} for {help xtset} data, the panel variable must be nested 
within the clusters defined by {opt u:id}. 

{phang}
{hi:IMPORTANT!!!} the order of the {help varlist} passed to {opt u:id} is 
assumed to follow the hierarchy of the nesting in the data.  Ensure that the 
{help varlist} passed to this option follows the same convention as used with 
commands like {help mixed}.

{phang}
{opt tpoint} a time point delimiting the training split from it's corresponding 
forecastting split.  This can also be accomplished by passing the appropriate if 
expression in your estimation command.  Use of this option will result in an 
additional variable with the suffix {it:xv4} being created to identify the 
forecasting set associated with each split/K-Fold.  This is to ensure that 
the forecasting period data will not affect the model training.

{phang}
{opt k:fold} is used to specify the number of K-Folds to create in the training 
set. 

{phang}
{opt spl:it} is used to specify the name of a new variable that will store the 
identifiers for the splits in the data.  If no argument is passed to this option 
{cmd splitit} will store the result in a variable named {it:_xvsplit}.

{phang}
{opt loo} is an option used to alter the underlying logic used to compute the 
validation metrics/monitors.  Since Leave-One-Out cross-validation is a special 
case of K-Fold CV the model fitting and predictions are generated in a manner 
consistent with all other K-Fold cases.  However, with only a single unit in 
each K-Fold in the LOO case computing validation metrics requires different 
treatment.  In the LOO case the validation metric/monitors are computed using 
the predicted and observed values for all of the training set units in aggregate.

{marker examples}{...}
{title:Examples}

{p 4 4 2}Load example dataset{p_end}
{p 8 4 2}{stata sysuse auto, clear}{p_end}

{p 4 4 2}Simple Random Sampling{p_end}
{p 6 4 2}Test/Train Split{p_end}
{p 8 4 2}{stata splitit .8, ret(splitvar)}{p_end}
{p 6 4 2}Train/Validation/Test Split{p_end}
{p 8 4 2}{stata splitit .6 .2, ret(splitvar)}{p_end}

{p 4 4 2}K-Fold Simple Random Sampling{p_end}
{p 6 4 2}Test/Train Split{p_end}
{p 8 4 2}{stata splitit .8, ret(splitvar) k(5)}{p_end}
{p 6 4 2}Train/Validation/Test Split{p_end}
{p 8 4 2}{stata splitit .6 .2, ret(splitvar) k(5)}{p_end}

{p 4 4 2}Clustered Random Sampling{p_end}
{p 6 4 2}Test/Train Split{p_end}
{p 8 4 2}{stata splitit .8, ret(splitvar) uid(foreign)}{p_end}
{p 6 4 2}Train/Validation/Test Split{p_end}
{p 8 4 2}{stata splitit .6 .2, ret(splitvar) uid(foreign)}{p_end}

{p 4 4 2}K-Fold Clustered Random Sampling{p_end}
{p 6 4 2}Test/Train Split{p_end}
{p 8 4 2}{stata splitit .8, ret(splitvar) k(5) uid(foreign)}{p_end}
{p 6 4 2}Train/Validation/Test Split{p_end}
{p 8 4 2}{stata splitit .6 .2, ret(splitvar) k(5) uid(foreign)}{p_end}


{marker retvals}{...}
{title:Returned Values}
{p 4 4 8}The following lists the names of the r-macros and their contents.{p_end}

{synoptset 25 tabbed}{...}
{synoptline}
{synopthdr}
{synoptline}
{synopt :{cmd:r(stype)}}the split method{p_end}
{synopt :{cmd:r(flavor)}}the sampling method{p_end}
{synopt :{cmd:r(splitter)}}the variable containing the sample split identifiers{p_end}
{synopt :{cmd:r(forecastset)}}the variable containing the sample split identifiers for the forecast sample{p_end}
{synopt :{cmd:r(training)}}the value(s) of the splitter variable that identify the training set(s){p_end}
{synopt :{cmd:r(validation)}}the value of the splitter variable that identifies the validation set{p_end}
{synopt :{cmd:r(testing)}}the value of the splitter variable that identifies the test set{p_end}
{synoptline}

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
