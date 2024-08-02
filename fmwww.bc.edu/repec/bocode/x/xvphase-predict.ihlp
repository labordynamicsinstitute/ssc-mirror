{smcl}
{* *! version 0.0.1 23feb2024}{...}
{pstd}
After the model is fitted to the data, predicted values of the outcome are 
generated using the estimation results corresponding with the appropriate fold 
of the training set.  The {help predictit} command allows users to provide the 
necessary information to predict the values using the appropriate estimation 
results.  If the quoted estimation command is passed as an argument to 
{help predictit} it is processed by {help cmdmod}, which returns if expressions 
that are used with the {help predict} commands used to generate the predicted 
values.  You can also pass the appropriate if expressions to the {opt modifin} 
and {opt kfifin} options (see below for details).  If {help fitit} was called 
prior to this phase of the cross-validation process, you don't need to pass 
anything to this command.  {help fitit} calls {help cmdmod} internally which 
stores the necessary if expressions in {help char:dataset characteristics} and 
these will be retrieved if no other information is passed to the command. The 
order of precedence for the needed if expressions is: (1) estimation command 
passed to {help predictit}; (2) arguments passed to the {opt modifin} and 
{opt kfifin} options; and (3) dataset characteristics created by a previous call 
to {help fitit}.

{pstd}
When using train/test (TT) splits with a single fold, predictions are made using 
the test set.  When train/validation/test (TVT) splits with a single fold are 
used, the predictions are made using the validation split.  We strongly urge 
users to avoid using TT splits with a single fold when building and evaluating 
competing models, since subsequent evaluation metrics are likely to overstate 
the out of sample performance due to adjustments made in response to evaluations 
on the test set.

{pstd}
In all other cases where the number of folds is greater than one, predictions 
correspond to the held-out fold in the training set.  The held out fold will be 
equal to the fold identifier, so the kth fold is excluded in the estimation 
results for the kth fold.  If the {opt noall} option is not passed to the 
command, the prediction phase will generate predicted values on the validation 
or test set, depending on what type of split is used.  If you are using TVT 
splits, the evaluation metrics on the validation set are reasonable to use for 
hyperparameter tuning provided no other modifications are made to the model (
e.g., changing the specification, adding/dropping variables, etc.).

{pstd}
{bf:modifin and kfifin} these options provide and alternative method to provide 
the {help predictit} command with the information it needs to generate the 
predicted outcomes correctly.  However, if you wish to pass your own arguments 
to these commands these are the basic requirements:

{pstd}
For {opt modifin} the value should be "if !e(sample) & \`split' == 2" in the 
case of TT and TVT splits that use a single fold for the training set.  For all 
other cases it should include "if !e(sample) & \`split' == \`k'".  Note the use 
of the {bf:\} character prior to the left single quote.  This will prevent the 
macros from being evaluated immediately which will allow them to be evaluated 
correctly inside {help predictit}.

{pstd}
For {opt kfifin} the value passed should be 
"if !e(sample) & \`split' == \`= \`kfold' + 1'" which ensures that the predicted 
values generated when the {opt noall} option is omitted are based on the 
validation/test set.
