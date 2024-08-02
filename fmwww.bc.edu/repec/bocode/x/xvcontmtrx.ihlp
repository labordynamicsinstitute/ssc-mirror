{phang}
{opt mse} is used to calculate mean squared error (MSE). MSE is calculated as 
the sum of squared differences between a predicted outcome variable and an 
observed outcome variable, divided by the total number of observations. For more 
details see 
{browse "https://yardstick.tidymodels.org/reference/rmse.html":MSE}.

{phang}
{opt rmse} is used to calculate root mean squared error (RMSE). RMSE is 
calculated as the square root of mean square error. For more details see 
{browse "https://yardstick.tidymodels.org/reference/rmse.html":RMSE}.

{phang}
{opt mae} is used to calculate mean absolute error (MAE). MAE is calculated as 
the sum of absolute differences between a predicted outcome variable and an 
observed outcome variable, divided by the total number of observations. For more 
details see {browse "https://yardstick.tidymodels.org/reference/mae.html":MAE}.

{phang}
{opt bias} is used to calculate bias. Bias is calcuated as the sum of 
differences between a predicted outcome variable and an observed outcome 
variable. For more details see the {browse "https://developer.nvidia.com/blog/a-comprehensive-overview-of-regression-evaluation-metrics/":nvidia developer blog}. 

{phang}
{opt mbe} is used to calculate mean bias error. Bias is calcuated as the sum of 
differences between a predicted outcome variable and an observed outcome 
variable, divided by the total number of observations. For more details see the 
{browse "https://developer.nvidia.com/blog/a-comprehensive-overview-of-regression-evaluation-metrics/":nvidia developer blog}. 

{phang}
{opt r2} is used to calculate R-squared. R-squared is calculated as the squared 
correlation between predicted and observed variables. For more details see 
{browse "https://yardstick.tidymodels.org/reference/rsq.html":R^2}.

{phang}
{opt mape} is used to calculate mean absolute percentage error (MAPE).  MAPE is 
calculated as the sum of the average of absolute differences between predicted 
and observed outcomes (residuals) divided by observed value.  For more details 
see 
{browse "https://yardstick.tidymodels.org/reference/mape.html":MAPE}. 

{phang}
{opt smape} is used to calculate symmetric mean absolute percentage error 
(SMAPE).  SMAPE is calculated as the sum of the ratio of absolute residuals to 
the average value of the predicted and estimated values, divided by the total 
number of observations.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/smape.html":SMAPE}.

{phang}
{opt msle} is used to calculate mean sqaured log error (MSLE). MSLE is 
calculated identically to MSE, but uses the logged values of both the observed 
and predicted variables.  For more details see the 
{browse "https://developer.nvidia.com/blog/a-comprehensive-overview-of-regression-evaluation-metrics/":nvidia developer blog}.  

{phang}
{opt rmsle} is used to calculate root mean squared log error (RMSLE). RMSLE is 
calculated as the sqaure root of MSLE.  For more details see the
{browse "https://developer.nvidia.com/blog/a-comprehensive-overview-of-regression-evaluation-metrics/":nvidia developer blog}. 

{phang}
{opt rpd} is used to calculate the ratio of performance to deviation (RPD). RPD 
is calculated as the standard deviation of the observed variable divided by 
RMSE of observed and predicted variables.  For more details see the 
{browse "https://yardstick.tidymodels.org/reference/rpd.html":RPD}.

{phang}
{opt iic} is used to calculate the index of ideality of correlation (IIC).  IIC 
is calculated as the correlation between observed and predicted values 
multiplied by an adjustment factor. The correlation is calculated using 
{opt rsq}.  The adjustment factor is the a ratio between the mean absolute 
negative differences and mean absolute positive differences. This metric is 
typically only used as a criterion for predictive potential of certain models.  
For more details see 
{browse "https://yardstick.tidymodels.org/reference/iic.html":IIC}.

{phang}
{opt ccc} is used to calculate the concordance correlation coefficient (CCC).  
CCC is calculated as the covariance between observed and predicted variables 
divided by the sum of variance of observed, variance of predicted, and the 
squared difference between average observed value and averaged predicted value.  
Users can also request a bias adjusted version of this metric by passing a 1 x 1 
matrix with the value 1 as an argument to the ccc function.  For example, to use 
{opt ccc} as a metric with the bias option you would code: 
{opt metric(ccc((1)))}.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/ccc.html":CCC}.

{phang}
{opt huber} is used to calculate Huber loss. Huber loss is calculated from 
residuals and a delta term, which defaults to 1.  You can pass a value for delta 
as an option to this function as a 1 x 1 matrix.  For example, to use 
{opt huber} as a metric with a delta value of 1.5 you would code: 
{opt metric(huber((1.5)))}.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/huber_loss.html":Huber loss}.

{phang}
{opt phl} is used to calculate Pseudo-Huber loss. Pseudo-Huber loss is a smooth 
approximation of Huber loss.  Pseudo-Huber loss is calcuated from residuals and 
a delta term, which defaults to 1.  You can pass a value for delta 
as an option to this function as a 1 x 1 matrix.  For example, to use 
{opt phl} as a metric with a delta value of 1.5 you would code: 
{opt metric(phl((1.5)))}.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/huber_loss_pseudo.html":Pseudo-Huber}.

{phang}
{opt pll} is used to calculate the Poisson log loss (PLL). Poisson log loss is 
the loss function for the Poisson function. It is calculated as the mean of the 
negative log poisson joint density function for the observed and predicted 
variables.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/poisson_log_loss.html":PLL}.

{phang}
{opt rpiq} is used to calculate the ratio of performance to interquartile range 
(RPIQ). RPIQ is calculated as the interquartile range divided by RMSE.  For more 
details see {browse "https://yardstick.tidymodels.org/reference/rpiq.html":RPIQ}.

{phang}
{opt r2ss} is used to calculate the traditional R-squared. R-squared is 
calculated as 1 minus the ratio of residual sum of squares to total sum of 
squares.  For more details see 
{browse "https://yardstick.tidymodels.org/reference/rsq_trad.html":Traditional R^2}.
