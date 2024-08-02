{smcl}
{* *! version 0.0.1 22feb2024}{...}
{marker phases}
{title:Phases in the Cross-Validation Process}

{pstd}
The process of cross-validation follows a standard set of steps to quantify the 
out of sample properties of statistical models.  The information below describes 
this process, the connection to commands included in {help crossvalidate}, and 
provides some additional details about existing limitations in the commands 
included with {help crossvalidate}.

{marker split}
{dlgtab:Splitting the Data}
INCLUDE help xvphase-split

{marker fit}
{dlgtab:Fitting Models}
INCLUDE help xvphase-fit

{marker predict}
{dlgtab:Predicting Outcomes}
INCLUDE help xvphase-predict

{marker validate}
{dlgtab:Computing the Validation Metric and Monitors}
INCLUDE help xvphase-validate

{dlgtab:After the Phases are Completed}
{pstd}
Once the validation phase is completed the results can be used to support 
decisions about using the model to generate predictions (e.g., how well the 
model performs on new samples should inform this decision) or can be used for 
hyperparameter tuning of models.  Hyperparameters are the parameters of the 
model that are provided by the analyst/user.  For example, setting the tolerance 
to determine whether a model using {help ml:maximum likelihood} converges is a 
hyperparameter.  In other contexts, hyperparameters can include the optimization 
method/algorithm used, batch sizes (in the case of batched stochastic gradient 
descent), or parameters that determine aspects of the model that affect 
complexity/sensitivity (e.g., the number of quadrature points 
(see {help quadchk})).

{pstd}
For users interested in hyperparameter tuning, at this time, you will need to 
call the commands {help splitit}, {help fitit}, {help predictit}, and 
{help validateit} on your own to implement the updates to the model you are 
attempting to tune.  Since {help fitit} and {help predictit} both allow you to 
pass the estimation command (quoted appropriately), it should not require a 
tremendous amount of effort on your part.  However, it is possible that you may 
want to use a different strategy for the model fitting and predicting phases 
(e.g., if you want to adjust hyperparameters after fitting the model to each 
k-fold).  In those cases, you will need to do a bit more coding.  

{pstd}
If anyone using {help crossvalidate} is interested in implementing methods for 
hyperparameter tuning, please feel free to reach out to us.  We have already 
allowed for some option names to be used to define a grid of values, the 
parameters to be tuned, and tuning methods in the {opt cvparse} function of 
{help libxv}.  
