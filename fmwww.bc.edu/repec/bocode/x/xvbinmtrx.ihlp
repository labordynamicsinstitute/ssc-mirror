{phang}
{opt sens} is used to calculate the sensitivity of a predicted outcome variable 
relative to an observed outcome variable. Sensitivity is the 
ratio of all true positive values in the predicted variable relative to all 
positive values in the observed variable. To compute sensitivity for the 
opposite class, pass a 1 x 1 matrix with the value 1 when referencing this 
function.  For example, to compute sensitivity for the opposite class as a 
metric code {opt metric(sens((1)))}.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/sens.html":Sensitivity}. 

{phang}
{opt prec} is used to calculate the precision of a predicted outcome variable 
relative to an observed outcome variable.  Precision is the 
ratio of all true posivie values in the predicted variable relative to all 
positive values in the predicted variable.  To compute precision for the 
opposite class, pass a 1 x 1 matrix with the value 1 when referencing this 
function.  For example, to compute precision for the opposite class as a 
metric code {opt metric(prec((1)))}.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/precision.html":Precision}. 

{phang}
{opt recall} is used to calculate the recall of a predicted outcome variable 
relative to an observed outcome variable.  Recall is a synonym for sensitivity 
and is calculated by calling identically.  To compute recall for the 
opposite class, pass a 1 x 1 matrix with the value 1 when referencing this 
function.  For example, to compute recall for the opposite class as a 
metric code {opt metric(recall((1)))}.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/recall.html":Recall}. 

{phang}
{opt spec} is used to calculate the specificity of a predicted outcome variable 
relative to an observed outcome variable.  Specificity is the 
ratio of all true negative values in the predicted variable relative to all 
negative values in the observed variable. To compute specificity for the 
opposite class, pass a 1 x 1 matrix with the value 1 when referencing this 
function.  For example, to compute specificity for the opposite class as a 
metric code {opt metric(spec((1)))}.  For more details see  
{browse "https://yardstick.tidymodels.org/reference/spec.html":Specificity}. 

{phang}
{opt prev} is used to calculate the prevalence of an event in an observed 
outcome variable relative to all outcomes.  Prevalence is proportion of positive 
cases in the data.  To compute prevalence for the 
opposite class, pass a 1 x 1 matrix with the value 1 when referencing this 
function.  For example, to compute prevalence for the opposite class as a 
metric code {opt metric(prev((1)))}.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/spec.html":Prevalence}. 

{phang}
{opt ppv} is used to calcuate the positive predicted value (PPV) of a predicted 
outcome variable relative to an observed outcome variable. PPV is the share of 
predicted positives that are actually positive.  To compute PPV for the 
opposite class, pass a 1 x 1 matrix with the value 1 when referencing this 
function.  For example, to compute PPV for the opposite class as a 
metric code {opt metric(ppv((1)))}.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/ppv.html":PPV}.

{phang}
{opt npv} is used to calcuate the negative predicted value (NPV) of a predicted 
outcome variable relative to an observed outcome variable. NPV is the share of 
predicted negatives that are actually negative.  In the binary context, negative 
is not positive (i.e., a value of 0 for a variable coded as 0 or 1).  To compute 
npv for the opposite class, pass a 1 x 1 matrix with the value 1 when 
referencing this function.  For example, to compute npv for the opposite class 
as a metric code {opt metric(npv((1)))}.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/npv.html":NPV}.

{phang}
{opt acc} is used to calculate the accuracy of a predicted outcome variable 
relative to an observed outcome variable.  Accuracy is the proportion of all 
cases predicted correctly.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/accuracy.html":Accuracy}.

{phang}
{opt bacc} is used to calcuate the balanced accuracy of a predicted outcome 
variable relative to an observed outcome variable.  Balanced accuracy is the 
unweighted mean of sensitivity and specificity.  To compute balanced accuracy 
for the opposite class, pass a 1 x 1 matrix with the value 1 when referencing 
this function.  For example, to compute balanced accuracy for the opposite class 
as a metric code {opt metric(bacc((1)))}.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/bal_accuracy.html":Balanced Accuracy}.

{phang}
{opt mcc} is used to calculate Matthews correlation coefficient (MCC).  The MCC 
is a correlation coefficient between the observed and predicted binary variables 
that range from [−1, 1].  For more details see 
{browse "https://yardstick.tidymodels.org/reference/mcc.html":MCC}.

{phang}
{opt f1} is used to calculate the F1 score. The F1 score is an alternate measure 
of a model's accuracy.  F1 score is calculated as the harmonic mean of the model 
precision and recall metrics, with an optional parameter beta that defaults to 
1.  To compute f1 for the opposite class, pass a 1 x 1 matrix with the value 1 
when referencing this function.  For example, to compute f1 for the opposite 
class as a metric code {opt metric(f1((1)))}.  You can also specify a value of 
beta to use by passing a 1 x 2 real matrix as an optional argument to this 
function.  For example, to specify a value of 1.5 for beta when using {opt f1} 
as a metric for the positive class, the option would look like this: 
{opt metric(f1((0, 1.5)))}.  To specify the same value for beta while computing 
f1 for the opposite class you would code {opt metric(f1((1, 1.5)))}. For more 
details see {browse "https://yardstick.tidymodels.org/reference/f_meas.html":F1}.

{phang}
{opt jindex} is used to calculate Youden's J statistic (J-index). The J 
statistic is defined as the sum of the model's Sensitivity and Specificity minus 
one and ranges from [0, 1].  For more details see the 
{browse "https://yardstick.tidymodels.org/reference/j_index.html":Youden's J}. 

{phang}
{opt binr2} is used to calculate the noniterative Edwards estimtor of the 
tetrachoric correlation coefficient (i.e., binary R^2).  For more details see 
{help tetrachoric}. 
