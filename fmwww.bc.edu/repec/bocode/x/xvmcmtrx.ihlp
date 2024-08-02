{phang}
{opt mcsens} is used to calculate the multiclass sensitivity of a predicted 
outcome variable relative to an observed outcome variable.  Multiclass 
sensitivity is calculated as the total number of true postive predicted outcomes 
of each class divided by total observed outcomes.  For more details see  
{browse "https://yardstick.tidymodels.org/reference/sens.html":Sensitivity}. 

{phang}
{opt mcprec} is used to calculate the multiclass precision of a predicted 
outcome variable relative to an observed outcome variable.  Multiclass precision 
is calculated as the total number of true postive predicted outcomes of each 
class divided by total predicted outcomes. For more details see 
{browse "https://yardstick.tidymodels.org/reference/precision.html":Precision}. 

{phang}
{opt mcrecall} is used to calculate the multiclass recall of a predicted outcome 
variable relative to an observed outcome variable. Multiclass recall is a 
synonym for multiclass sensitivity.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/recall.html":Recall}. 

{phang}
{opt mcspec} is used to calculate the multiclass specificity of a predicted 
outcome variable relative to an observed outcome variable.  Multiclass 
specificity is calculated as the total number of true negative predicted 
outcomes of each class divided by the total of true negative and false positive 
outcomes of each class.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/spec.html":Specificity}.

{phang}
{opt mcppv} is used to calculate multiclass positive predicted values (PPV). As 
in the binary case, multiclass PPV can be understood as the share of predicted 
positives that are actually positive. Multiclass PPV is defined identically to 
multiclass precision.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/ppv.html":PPV}. 

{phang}
{opt mcnpv} is used to calculate multiclass negative predicted values (NPV). As 
in the binary case, multiclass NPV can be understood as the share of predicted 
negatives that are actually negative.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/npv.html":NPV}. 

{phang}
{opt mcacc} is used to calculate the multiclass accuracy of a predicted outcome 
variable relative to an observed outcome variable.  In both binary and 
multiclass cases, accuracy can be understood as the share of the data predicted 
correctly and is the ratio of true positives plus true negatives relative to all 
predicted outcomes.  This option is identical to the binary accuracy option, 
acc.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/accuracy.html":Accuracy}. 

{phang}
{opt mcbacc} is used to calcuate the multiclass balanced accuracy of a predicted 
outcome variable relative to an observed outcome variable. Multiclass balanced 
accuracy can be understood as the unweighted mean of multiclass sensitivity and 
multiclass specificity.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/bal_accuracy.html":Balanced Accuracy}. 

{phang}
{opt mcmcc} is used to calculate Matthew's correlation coefficient (MCC).  The 
MCC is a correlation coefficient between the observed and predicted binary 
variables that range from [−1, 1].  This option is identical to the binary 
Matthews correlation coefficient option, mcc.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/mcc.html":Matthew's Correlation Coefficient}. 

{phang}
{opt mcf1} is used to calculate the multiclass F1 score. The F1 score is an 
alternate measure of a model's accuracy.  F1 score is calculated as the harmonic 
mean of the multiclass precision and recall metrics, with an optional parameter 
beta that defaults to 1.  You can specify a value of beta to use by passing a 
1 x 1 real matrix as an optional argument to this function.  For example, to 
specify a value of 1.5 for beta when using {opt mcf1} as a metric, the option 
would look like this: {opt metric(mcf1((1.5)))}.  For more details 
see {browse "https://yardstick.tidymodels.org/reference/f_meas.html":F1}. 

{phang}
{opt mcjindex} is used to calculate multiclass Youden's J statistic (J-index). 
The J statistic is defined as the sum of the multiclass sensitivity and 
specificity minus one and ranges from [0, 1].  For more details see 
{browse "https://yardstick.tidymodels.org/reference/j_index.html":Youden's J}.

{phang}
{opt mcordr2} is used to calculate the polychoric correlation of two ordinal 
variables.  This option requires the installation of {search polychoric} 
developed by Stas Kolenikov. If you already have {opt polychoric} installed 
see {help polychoric} for additional details.

{phang}
{opt mcdetect} is used to calculate the multiclass detection prevalence. 
Multiclass detection prevalence is defined as the sum of true posttive and false 
positive predicted outcomes for each class divided by the total number of 
predicted outcomes.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/detection_prevalence.html":Detection Prevalence}. 

{phang}
{opt mckappa} is used to calculate the multiclass Kappa. Kappa is similar to 
multiclass accuracy but is normalized by the accuracy expected by random chance. 
Additionally, users may alter the weighting matrix used in the calculation by 
passing an argument to this function, where the value specified in the option is 
the power to which the alternate weighting matrix is raised.  For example, if 
you wanted to use {opt mckappa} as a metric with a quadratic weighting matrix 
you would code: {opt metric(mckappa((2)))}.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/kap.html":Kappa}.
