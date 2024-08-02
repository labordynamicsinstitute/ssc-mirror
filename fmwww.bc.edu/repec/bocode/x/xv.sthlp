{smcl}
{* *! version 0.0.8 25mar2024}{...}
{vieweralsosee "[R] predict" "mansection R predict"}{...}
{vieweralsosee "[R] estat classification" "mansection R estat_classification"}{...}
{vieweralsosee "[P] creturn" "mansection P creturn"}{...}
{vieweralsosee "crossvalidate package" "help crossvalidate"}{...}
{vieweralsosee "crossvalidate splitting" "help splitit"}{...}
{vieweralsosee "crossvalidate fitting" "help fitit"}{...}
{vieweralsosee "crossvalidate predicting" "help predictit"}{...}
{vieweralsosee "crossvalidate validating" "help validateit"}{...}
{vieweralsosee "crossvalidate libxv" "help libxv"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "xv##syntax"}{...}
{viewerjumpto "Description" "xv##description"}{...}
{viewerjumpto "Options" "xv##options"}{...}
{viewerjumpto "Examples" "xv##examples"}{...}
{viewerjumpto "Returned Values" "xv##retvals"}{...}
{viewerjumpto "Additional Information" "xv##additional"}{...}
{viewerjumpto "Contact" "xv##contact"}{...}
{title:Cross-Validation in Stata}

{marker syntax}{...}
{title:Syntax}

{p 4 15 8}
{cmd:xv} {it:# [#]} {cmd:,} {cmdab:me:tric(}{it:string asis}{cmd:)} 
[{cmd:seed(}{it:integer}{cmd:)}
{cmdab:u:id(}{it:varlist}{cmd:)} 
{cmdab:tp:oint(}{it:string asis}{cmd:)} {cmdab:kf:old(}{it:integer}{cmd:)} 
{cmdab:spl:it(}{it:string asis}{cmd:)}
{cmdab:res:ults(}{it:string asis}{cmd:)}
{cmdab:fit:nm(}{it:string asis}{cmd:)} 
{cmdab:c:lasses(}{it:integer}{cmd:)} {cmdab:thr:eshold(}{it:real}{cmd:)} 
{cmdab:ps:tub(}{it:string asis}{cmd:)} 
{cmdab:pm:ethod(}{it:string asis}{cmd:)}
{cmdab:po:pts(}{it:string asis}{cmd:)}
{cmd:noall} {cmdab:mo:nitors(}{it:string asis}{cmd:)} 
{cmdab:dis:play} {cmdab:ret:ain}
{cmdab:val:nm(}{it:string asis}{cmd:)} 
] {cmd::} {cmd:{it:estimation command}}{p_end}


{synoptset 15 tabbed}{...}
{synoptline}
{synopthdr}
{synoptline}
{syntab:Arguments}
{synopt :{opt #}}The proportion of the data set to allocate to the training set.{p_end}
{synopt :{it:{opt [#]}}}The proportion of the data set to allocate to the validation set.{p_end}
{syntab:Required}
{synopt :{opt me:tric}}the name of a function from {help libxv} or a user-defined function{p_end}
{syntab:Split}
{synopt :{opt seed}}to set the pseudo-random number generator seed{p_end}
{synopt :{opt u:id}}a variable list for clustered sampling/splitting{p_end}
{synopt :{opt tp:oint}}a numeric, td(), tc(), or tC() value{p_end}
{synopt :{opt kf:old}}the number of K-Folds to create in the training set; default is {cmd:kfold(1)}{p_end}
{synopt :{opt spl:it}}a new variable name; default is {cmd:split(_xvsplit)}{p_end}
{syntab:Fit}
{synopt :{opt res:ults}}a stub for storing estimation results; default is {cmd:results(xvres)}{p_end}
{synopt :{opt noall}}suppresses fitting the model to the entire training set{p_end}
{synopt :{opt fitnm}}is used to name the collection storing the results; default is {cmd:fitnm(xvfit)}.{p_end}
{syntab:Predict}
{synopt :{opt ps:tub}}a new variable name for predicted values; default is {cmd:pstub(_xvpred)}{p_end}
{synopt :{opt c:lasses}}is used to specify the number of classes for classification models; default is {cmd:classes(0)}.{p_end}
{synopt :{opt thr:eshold}}positive outcome threshold; default is {cmd:threshold(0.5)}{p_end}
{synopt :{opt pm:ethod}}predicted statistic from {help predict}{p_end}
{synopt :{opt po:pts}}options passed to {help predict} in addition to the method{p_end}
{synopt :{opt noall}}suppresses prediction on entire training set for K-Fold cases; default is on{p_end}
{syntab:Validate}
{synopt :{opt mo:nitors}}zero or more function names from {help libxv} or user-defined functions; default is {cmd monitors()}{p_end}
{synopt :{opt valnm}}is used to name the collection storing the results; default is {cmd:valnm(xvval)}.{p_end}
{syntab:General}
{synopt :{opt dis:play}}display results in window; default is off{p_end}
{synopt :{opt ret:ain}}is an option used to preserve the stored estimation results, split variable, and predicted outcomes; default is off{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xv} is a prefix command from the {help crossvalidate} suite of tools to 
implement cross-validation methods with Stata estimation commands. The {cmd:xv} 
prefix can be used with arbitrary estimation commands that return results using 
{help ereturn}.  It handles all four phases of cross-validation work: splitting 
the data into training, validation, and/or test splits (see {help splitit}); 
fitting the model you specify with your estimation command (see {help fitit}); 
generating out-of-sample/held-out predicted values (see {help predictit}); and 
computing validation metrics and monitors (see {help validateit}).  {cmd:xv} is 
a prefix that wraps the individual commands provided in the {help crossvalidate} 
suite intended to make the process of using cross-validation seemless and easy 
for Stata users.

{pstd}
{cmd:xv} can be used to generate simple random sampling based train/test splits 
or training/validation/test splits, K-Fold simple random samples, and Clustered 
simple random sampling (panel data is a special case).  A large number of 
validation metrics are implemented in {help libxv} and users are also free to 
define their own {help mata} functions that can be used by {cmd:xv} (see 
{help libxv} for additional information).  

{pstd}
{cmd:IMPORTANT:} immediately following the {cmd:xv} command, you must specify 
the proportion of the dataset to allocate to the training set.  For k > 1, the 
training proportion can be 1.  If you specify a training set proportion of 1, 
the {opt noall} option will be turned on automatically.

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt me:tric} the name of a {help libxv} or user-defined function, with the 
function signature described in {help libxv:help libxv} used to evaluate the fit 
of the model on the held-out data.  Only a single metric can be specified.  For 
user's who may be interested in hyperparameter tuning, this would be the value 
that you would optimize with your hyperparameter tuning algorithm.

{dlgtab:Splitting the Data}

{phang}
{opt seed} accepts integer values used to set the pseudo-random number 
generator seed value.

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
{opt tp:oint} a time point delimiting the training split from it's corresponding 
forecastting split.  This can also be accomplished by passing the appropriate if 
expression in your estimation command.  Use of this option will result in an 
additional variable with the suffix {it:xv4} being created to identify the 
forecasting set associated with each split/K-Fold.  This is to ensure that 
the forecasting period data will not affect the model training.

{phang}
{opt kf:old} is used to specify the number of K-Folds to create in the training 
set. If the value is > 1, the training split proportion can be set to 1; if you 
use a training set proportion of 1 with k > 1, the {opt noall} option will be 
turned on for you automatically.  For k == 1, or in the context of leave-one-out 
cross-validation (see {help xvloo}), you must provide a training set 
proportion < 1.  

{phang}
{opt spl:it} is used to specify the name of a new variable that will store the 
identifiers for the splits in the data.  If a value is passed to the {opt spl:it}, 
{opt ps:tub}, or {opt res:ults} options it will trigger the {opt ret:ain} option 
to be turned on. The default value in the case where the {opt ret:ain} option is 
on and no value is passed to {opt spl:it} is _xvsplit.

{dlgtab:Model Fitting}

{phang}
{opt res:ults} is used to {help estimates_store:estimates store} the estimation 
results from fitting the model on each fold in the dataset.  When {opt kf:old} is 
> 1 and the {opt noall} option is omitted, an additional result will be stored 
from fitting the model to the entire training split.  Additionally, if a value 
is passed to the {opt spl:it}, {opt ps:tub}, or {opt res:ults} options it will 
trigger the {opt ret:ain} option to be turned on. The default value in the case 
where the {opt ret:ain} option is on and no value is passed to {opt res:ults} is 
xvres.

{phang}
{opt fitnm} is an option to pass a name to the collection created to store the 
results.  When {cmd fitit} is executed, it will initialize a new collection 
or replace the existing collection with the same name.  If you want to retain 
the validation results from multiple executions, pass an argument to this 
option.  {it:Note:} this only affects users using Stata 17 or later.

{phang}
{opt noall} is an option to prevent fitting, predicting, and validating a model 
that is fitted to the entire training set when using K-Fold cross-validation 
with a train/test or train/validation/test split. If the training set proportion 
is set to 1, this option will be automatically enabled.

{dlgtab:Predicting Out-of-Sample Results}

{phang}
{opt ps:tub} is used to define a new variable stub name for the predicted values
generated during the cross-validation process.  When {opt kf:old} > 1 and the 
option {opt noall} is omitted, an additional variable is generated based on the 
fit of the model to the entire training set, with the predictions made on the 
validation set, if present, or the test set.  Additionally, if a value 
is passed to the {opt spl:it}, {opt ps:tub}, or {opt res:ults} options it will 
trigger the {opt ret:ain} option to be turned on. The default value in the case 
where the {opt ret:ain} option is on and no value is passed to {opt ps:tub} is 
_xvpred.  If this variable already exists, a suffix based on the timestamp when 
the command is executed is added as a suffix.

{phang}
{opt c:lasses} is used to distinguish between models of non-categorical data (
{opt c:lasses(0)}), binary data ({opt c:lasses(2)}), and multinomial/ordinal 
data ({opt c:lasses(>= 3)}).  You will only need to pass an argument to this 
parameter if you are using some form of a classification model.  Internally, it 
is used to determine whether to call {help predict} (in the case of 
{opt c:lasses(0)}) or {help classify} (in all other cases).

{phang}
{opt thr:eshold} defines the probability cutoff used to determine a positive 
classification for binary response models.  This value functions the same way 
as it does in the case of {help estat_classification:estat classification}.

{phang}
{opt pm:ethod} is passed internally to Stata's {help predict} command to 
generate the predicted values of the outcome for the out-of-sample data. When 
the value of the {opt c:lasses} option is 0, {opt pm:ethod} will default to xb.  
If the value of {opt c:lasses} is >= 2, {opt pm:ethod} will default to pr.

{phang}
{opt po:pts} is passed internally to Stata's {help predict} command to 
generate the predicted values of the outcome for the out-of-sample data. For 
multivariate outcome models, like {help sureg}, this option can be used to 
specify which of the equations should be used to predict the outcome of interest.  
It can also be used to specify the {opt nooff:set} option in single or 
multi-equation models.  Consult the {help predict} documentation for the model 
you are fitting for more details.

{phang}
{opt noall} is an option to prevent fitting, predicting, and validating a model 
that is fitted to the entire training set when using K-Fold cross-validation 
with a train/test or train/validation/test split. If the training set proportion 
is set to 1, this option will be automatically enabled.

{dlgtab:Validating the Model}

{phang}
{opt mo:nitors} the name of zero or more {help libxv} or user-defined functions, 
with the function signature described in {help libxv:help libxv} used to 
evaluate the fit of the model on the held-out data.  These should not be used 
when attempting to tune hyper parameters, but can still provide useful 
information regarding the model fit characteristics.

{phang}
{opt valnm} is an option to pass a name to the collection created to store the 
results.  When {cmd validateit} is executed, it will initialize a new collection 
or replace the existing collection with the same name.  If you want to retain 
the validation results from multiple executions, pass an argument to this 
option.  {it:Note:} this only affects users using Stata 17 or later.

{dlgtab:General Options}

{phang}
{opt dis:play} an option to display the metric and monitor values in the results 
window.

{phang}
{opt ret:ain} is used to retain the variables created, stored estimation results, 
and dataset characteristics that are generated by {cmd:xv}.  If an argument is 
passed to either the {opt spl:it}, {opt ps:tub}, or {opt res:ults} options, retain 
is automatically turned on and default names will be used for the split 
variable, predicted outcome variable, and/or estimation results names if they 
are not provided by the user.

{marker examples}{...}
{title:Examples}

{dlgtab:Linear Regression Example}
{pstd}
sysuse auto.dta, clear{break}
xv 0.8, metric(msle) pstub(p) display retain monitors(mse rmse mae bias mbe  ///{break}
r2 mape smape rmsle rpd iic ccc huber phl rpiq r2ss) split(ivsplit):         ///{break}   
reg price mpg i.foreign, vce(rob)

{dlgtab:Poisson Example}
{pstd}
webuse epilepsy.dta, clear{break}
xv 0.6, metric(pll) pstub(p) display retain monitors(mse rmse mae bias mbe   ///{break}   
r2 mape smape msle rmsle rpd iic ccc huber phl rpiq r2ss) split(poisplit) 	 ///{break}   
pmethod(n): poisson seizures treat lbas lbas_trt lage v4

{dlgtab:Instrumental Variables Example}
{pstd}
webuse hsng2.dta, clear{break}
xv 0.8, metric(msle) pstub(p) display retain monitors(mse rmse mae bias mbe  ///{break}  
r2 mape smape rmsle rpd iic ccc huber phl rpiq r2ss) split(ivsplit):         ///{break}   
ivregress 2sls rent pcturban (hsngval = faminc i.region), small

{dlgtab:Mixed Effects Example}
{pstd}
webuse nlswork.dta, clear{break}
xv 0.8, metric(msle) pstub(p) uid(id) display retain split(mixsplit):		 ///{break}
mixed ln_w grade age c.age#c.age ttl_exp tenure c.tenure#c.tenure || id:

{dlgtab:Logit Example}
{pstd}
webuse lbw.dta, clear{break}
xv 0.6, metric(acc) pstub(p) display retain split(logsplit2)				 ///{break}   
monitors(sens recall spec prev ppv npv bacc mcc f1 jindex) classes(2):		 ///{break}   
logit low age lwt i.race smoke ptl ht ui

{dlgtab:Multinomial Logit Example}
{pstd}
webuse sysdsn1.dta, clear{break}
xv 0.6, metric(mcacc) pstub(p) display classes(3) retain split(	csplit)		 ///{break}   
monitors(mcsens mcprec mcspec mcppv mcnpv mcbacc mcmcc mcf1 mcjindex 		 ///{break}   
mcdetect mckappa): mlogit insure age male nonwhite i.site

{dlgtab:Ordinal Logit Example}
{pstd}
webuse fullauto.dta, clear{break}
xv 0.6, metric(mcacc) pstub(p) display classes(5) retain split(mcsplit)		 ///{break}   
monitors(mcsens mcprec mcspec mcppv mcnpv mcbacc mcmcc mcf1 mcjindex		 ///{break}   
mcdetect mckappa): ologit rep77 foreign length mpg

{marker retvals}{...}
{title:Returned Values}

{pstd}
The table below provides information about the macros returned by {cmd:xv} in 
addition to the macros that are returned by the estimation command you specify.  

{synoptset 25 tabbed}{...}
{synoptline}
{synopthdr:Name}
{synoptline}
{syntab:State Macros}
{synopt :{cmd:e(rng)}}the current set rng setting{p_end}
{synopt :{cmd:e(rngcurrent)}}the current RNG in effect{p_end}
{synopt :{cmd:e(rngstate)}}the current state of the runiform() generator{p_end}
{synopt :{cmd:e(rngseed)}}the seed last set for the stream RNG{p_end}
{synopt :{cmd:e(rngstream)}}the current stream of the stream RNG{p_end}
{synopt :{cmd:e(filename)}}the name of the file loaded in memory{p_end}
{synopt :{cmd:e(filedate)}}the last saved date of the file in memory{p_end}
{synopt :{cmd:e(version)}}the current Stata version{p_end}
{synopt :{cmd:e(currentdate)}}the current date{p_end}
{synopt :{cmd:e(currenttime)}}the current time{p_end}
{synopt :{cmd:e(stflavor)}}the flavor of Stata currently in use (i.e., BE, SE, MP){p_end}
{synopt :{cmd:e(processors)}}the number of processors currently set for use{p_end}
{synopt :{cmd:e(hostname)}}the name of the host machine{p_end}
{synopt :{cmd:e(machinetype)}}description of the hardware platform{p_end}
{syntab:Splitting Macros}
{synopt :{cmd:r(stype)}}the split method{p_end}
{synopt :{cmd:r(flavor)}}the sampling method{p_end}
{synopt :{cmd:r(splitter)}}the variable containing the sample split identifiers{p_end}
{synopt :{cmd:r(forecastset)}}the variable containing the sample split identifiers for the forecast sample{p_end}
{synopt :{cmd:r(training)}}the value(s) of the splitter variable that identify the training set(s){p_end}
{synopt :{cmd:r(validation)}}the value of the splitter variable that identifies the validation set{p_end}
{synopt :{cmd:r(testing)}}the value of the splitter variable that identifies the test set{p_end}
{syntab:Fitting Macros}
{synopt :{cmd:e(estres#)}}the name to store the estimation results on the #th fold.{p_end}
{synopt :{cmd:e(estresnames)}}the names of all the estimation results{p_end}
{synopt :{cmd:e(estresall)}}the name used to store the estimation results for the entire training set when K-Fold cross-validation is used.{p_end}
{synopt :{cmd:e(predifin)}}the if expression to use when predicting on validation/test split.{p_end}
{synopt :{cmd:e(kfpredifin)}}the if expression to use when predicting on the K-Fold hold out set.{p_end}
{syntab:Validation Scalars}
{synopt :{cmd:r(metric#)}}contains the metric value for the corresponding K-Fold{p_end}
{synopt :{cmd:r(`monitors'#)}}one scalar for each monitor passed to the monitors option, named by the monitor function with a numeric value to identify the corresponding K-Fold{p_end}
{synopt :{cmd:r(metricall)}}contains the metric value for K-Fold CV fitted to all of the K-Folds{p_end}
{synopt :{cmd:r(`monitors'all)}}contains the monitor values for K-Fold CV fitted to all of the K-Folds{p_end}
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
