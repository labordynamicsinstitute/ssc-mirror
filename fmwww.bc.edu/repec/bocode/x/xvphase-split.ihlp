{smcl}
{* *! version 0.0.1 22feb2024}{...}
{pstd}
The first phase in all cross-validation work is splitting the data into either: 
(1) Training and Test sets; or (2) Training, Validation, and Test sets.  However, 
not all train/test (TT) or train/validation/test (TVT) splits are the same.  In 
the training set, the number of folds created with further affect the number of 
times and the sample size used when fitting the data.  This may seem like an odd 
description, but all data splitting is a form of K-Fold cross-validation.  The 
difference is determined by the number of folds.  In the traditional TT split 
case that we may be familiar with, there is a single K-Fold created for the 
training set.  If you want to use 5- or 10-fold cross-validation, the training 
set would be split into 5 or 10 approximately equal sized groups.  In the other 
extreme, leave-one-out (LOO) cross-validation generates as many folds as the 
number of sampling units in the training set.  So, the data splitting begins 
by first determining whether you want two or three sets of data to work with and 
then moves into determining how many pieces you want the training set to have. 

{pstd} 
You can control whether to use TT or TVT splits based on the number of arguments 
you initially pass to the command.  If you pass a single proportion, a TT split 
will result and if you include two proportions a TVT split will result.  To 
define how many folds the training set will have, use the {opt kfold} option.  
By default, the {opt kfold} option is set to 1.  {bf:CAUTION:} if you want to 
use LOO cross-validation, the number of folds must be equal to to number of 
sampling units in the training set.  Additionally, you need to use the {opt loo} 
option for {help splitit}; however, the {help xvloo} prefix will manage all of 
this for you.  See the note at the end of this section for more information.

{pstd}
Next, the splitting process needs to determine how the units will be allocated 
among these sets: simple random sampling w/o replacement (SRS) or clustered 
random sampling w/o replacement (CRS).  By default, the splitting process will 
use SRS.  If you pass a value to the {opt uid} parameter, CRS will be used.  
The {opt tpoint} option, although documented and available, should likely not be 
used at this time for most use cases.  It will implement CRS for panel data if 
the data are {help xtset} but creates an additional variable based on the time 
point passed to {opt tpoint} to define the records that should be used for 
forecasting.  At this time, forecasting methods are not supported by the 
{help crossvalidate} package, but the option exists for users who wish to handle 
those use cases on their own.

{pstd}
{bf:General Advise:} we suggest users opt for TVT splits over TT splits.  A test 
set should only be used to evaluate the model's performance a single time after 
all "training" and hyperparameter tuning is completed.  Using the evaluation 
results from your test set while still adjusting the model and/or its parameters 
will likely lead to tuning the model to the test set.  In that case, the 
evaluation metrics will be overly optimistic compared to what should be 
reasonably expected for completely new data.

{pstd}
{bf:Leave-one-out cross-valiation} should generally only be used when you have a 
small to moderately sized dataset.  With large datasets, the model is fitted to 
the data n - 1 times, with a sample size of n - 1, where n is the number of 
sampling units in the training set; this is analogous to using {help jackknife}.  
The amount of time it will take to get results can rapidly increase.  
Additionally, we encourage you to use the {opt difficult} option for models that 
use {help ml:maximum likelihood}, as well as specifying the number of iterations 
and/or convergence criterion in your estimation command.  This can mitigate the 
risk of encountering a flat region or saddle point in the likelihood that may 
stall or halt progress in your model fitting otherwise.

{pstd}
The {opt loo} option is required to implement LOO splitting of the training set 
due to the manner in which the folds are created.  For all other instances where 
the number of folds, k, is greater than one, we use {help xtile} to generate 
approximately equal sized folds in the training set.  However, LOO requires 
exactly one sampling unit to be omitted from each fold.  In this case, ties that 
may result from {help xtile} can lead to the incorrect number of sampling units 
being omitted from each fold.  The {opt loo} option is used to implement 
alternative logic that ensures a single sampling unit will be omitted from each 
fold.
