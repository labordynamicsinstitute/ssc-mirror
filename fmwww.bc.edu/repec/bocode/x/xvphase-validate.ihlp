{smcl}
{* *! version 0.0.1 22feb2024}{...}
{pstd}
The last phase of the cross-validation process when the performance of the 
model is evaluated using held-out, or out-of-sample, data.  Like the other 
phases, this process is dependent on the folds used in the training set.  
Additionally, the {opt loo} option also plays a significant role in the behavior 
of the validation phase of cross-validation. 

{pstd}
When a single fold is used in the training set, the model is evaluated using 
the validation set if a train/validation/test (TVT) split is used.  The model 
will be evaluated on the test set only in the case where a train/test (TT) 
split is used.  The behavior changes a bit when the number of folds is greater 
than one, and changes yet again when the number of folds is equal to the number 
of sampling units in the data (when using leave-one-out (LOO) cross-validation).  
If you are using LOO cross-validation we recommend using the {help xvloo} prefix 
which handles everything for you.  However, if you need to use the lower-level 
commands there is a distinct difference.  When the {opt loo} option is passed to 
the {help validateit} command, the model is evaluated using the predictions made 
on the training set first.  If the {opt noall} option is passed, that is the 
extent of the evaluation.  If the {opt noall} option is not passed, a second 
evaluation is performed based on the fit of the model to the entire training 
split and subsequent prediction for the validation or test split, where the 
choice between validation and test split follows the same logic above.  

{pstd}
When the number of folds used in the training set is greater than one and less 
than the number of sampling units, the performance is evaluated for each fold in 
the training set separately.  If the {opt noall} option is not passed, the model 
is evaluated again based on the fit of the model to the entire training set and 
the predictions from that model made on the validation or test set, where the 
choice between validation and test split follows the same logic above.  

{pstd}
In all cases, a {opt metric} must be passed to the {opt metric} option.  Only a 
single metric can be passed to this option and it must be unique, as in it 
cannot also be passed as an argument to the {opt monitors} option.  If you are 
interested in tuning hyperparameters or adjusting the model, the {opt metric} 
should be the value that you are attempting to minimize or maximize.  While the 
{help crossvalidate} package does not currently support automated hyperparameter 
tuning, we imposed this restriction for that reason.  On the other hand, you can 
pass multiple arguments to the {opt monitors} option.  These should be viewed as 
supplemental information about the performance of your model, although if you 
wanted to write a multivariable optimization function you could use these values 
for hyperparameter tuning in theory.

{pstd}
Lastly, while weights may be supported by estimation commands, we do not 
currently support the use of weights in the evaluation metrics.  However, we may 
support the use of weights for evaluation metrics in the future.
