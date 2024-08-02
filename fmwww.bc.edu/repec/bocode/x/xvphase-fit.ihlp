{smcl}
{* *! version 0.0.2 23feb2024}{...}
{pstd}
In this phase, your estimation command is implemented to fit the model you 
specified to one or more folds of the data in the training set.  The commands in 
the {help crossvalidate} package determine whether your estimation command 
includes any {ifin} expressions.  If your estimation command includes an in 
expression, this command create a temporary variable indicating the cases 
that satisfy your in expression.  The in expression is then replaced by an if 
expression using that temporary variable indicator and an additional constraint 
to ensure that the model is fitted to the correct fold of the training set.  
If your estimation command includes an if expression, we add the additional 
constraint to fit the model to the correct fold to the expression.  If your 
estimation command does not include an {ifin} expression, we inject an if 
expression to ensure that the model is fitted to the correct fold of the 
training set. 

{pstd}
The model is then fitted to all of the training folds sequentially based on the 
value provided to the {opt kfold} option.  This option defaults to a value of 1.  
If you are using one of the prefix commands ({help xv} or {help xvloo}), you 
{bf:do not} need to specify the {opt kfold} option more than once.  The 
estimation results are stored for each iteration and you are required to provide 
a {it:stubname} for the estimation results; {bf:Note:} {it:if you are using one} 
{it:of the prefix commands ({help xv} or {help xvloo}), a default name is} 
{it:provided as a convenience}.  The name you use for the estimation results 
{bf:CAN NOT} end with a number.  When predicting the outcomes from the models, 
a scenario can arise where it is no longer possible to identify the correct 
estimation result using the fold identifier if the name supplied ends with a 
number.  

{pstd} 
In the case where you are attempting to tune the hyperparameters or select 
among competing models, you may want to use results from the validation set of 
a TVT split.  The {opt noall} option can be useful in this scenario.  By default 
the command will fit the model to each fold of the training set and then will 
fit the model to the entire training set, when {opt kfold} is > 1.  When you 
plan on testing multiple models or performing hyperparameter tuning, use the 
{opt noall} option while engaged in this preliminary work.  Once you have a 
candidate model, call the command again without the {opt noall} option.  This 
will fit the model on the entire training set and that model fit will be used to 
generate the predicted values on the validation set.
