{smcl}
{* *! version 1 21mar2023}{...}
{cmd:help pinocchio}
{hline}

{title:Title}

{p 4 17 2}
{bf:pinocchio} {hline 2} Stata command that randomly generates false econometric statements.

{title:Syntax}

{p 4 17 2}
{cmdab:pinocchio}

{title:Description}

{pstd}
Pinocchio functions as a stochastic producer of spurious econometric assertions, while the accurate statements are itemized below. Its purpose is conceived as both a revision aid and a repository of key concepts to retain. 
It is recommended to set a random seed every time Stata is initiated.

{title:True Statements}

{pstd}
1. In a univariate regression model (i.e., a model without explanatory variables) the constant or intercept is the overall mean of Y.  

{pstd}
2. In a bivariate regression the constant (or intercept) is calculated as the mean of the dependent variable (Y) minus the product of the coefficient and mean of the independent variable (X), thus the constant (alpha) = Y_bar - Beta_hat*X_bar. 

{pstd}
3. In a bivariate regression the R-squared is equal to the squared correlation coefficient. 

{pstd}
4. In a bivariate regression the square root of the R-squared is equal to the correlation coefficient. 

{pstd}
5. In a bivariate regression the R-squared will always be less than the absolute value of the correlation coefficient unless X and Y are perfectly linearly associated in which case they are equal. 

{pstd}
6. In a bivariate regression the p-values of an F-test and t-test are identical. 

{pstd}
7. In a bivariate linear regression the beta coefficient is calculated as the covariance between X and Y divided by the variance of X 

{pstd}
8. Regression residuals are calculated by substracting predicted values from observed values (i.e., Y_obs - Y_hat), therefore positive residuals indicate underpredictions while negative residuals indicate overpredictions. 

{pstd}
9. A bivariate regression is a model that uses one explanatory variable (X) to predict or explain the variation in another variable (Y).  

{pstd}
10. In a simple linear regression the error or residuals of the estimation are calculated as e = Y_obs - (alpha_hat + B1_hat*X1_obs + B2_hat*X2_obs), i.e. the difference between observed and predicted values.  

{pstd}
11. In a regression the Root Mean Square Error (RMSE) is equal to the square root of the Residual Mean Squares (RMS) or the square root of the quotient of the Residual Sum of Squares (RSS) and the Residual degrees of freedom (n-k-1).  

{pstd}
12. In a regression the F-statistic is equal to the Model Mean Squares (Model MS) divided by the Residual Mean Squares (Residual MS). 

{pstd}
13. The Mean Squares (MS) are the Sum of Squares (SS) divided by their respective degrees of freedom (df).  

{pstd}
14. In a regression, the t-statistic of any variable is equal to its beta coefficient divided by its standard error, i.e., t=beta/se.  

{pstd}
15. The R-squared of a regression ranges from 0 to 1. 

{pstd}
16. The Adjusted R-squared can be positive or negative, while the R-squared is always positive.  

{pstd}
17. The Adjusted R-squared adjusts for the number of predictors in the model. In practice, it is a corrected R-squared which balances the explained variability against the number of predictors.  

{pstd}
18. The R-squared is equal to the Total Sum of Squares minus the Residual Sum of Squares divided by the Total Sum of Squares, i.e., (TSS-RSS)/TSS = TSS/TSS - RSS/TSS = 1 - RSS/TSS. 

{pstd}
19. The F-test of a regression evaluates whether at least one explanatory variable (beta_hat) is non-zero. The null hypothesis states that all coefficients are zero while the alternative hypothesis that some are not zero. 
As long as one variable coefficient is statistically significant the alternative hypothesis is accepted.  

{pstd}
20. An F-test in a regression model, tests whether a model with predictors is better than an intercept-only model. Effectively, the F-test of a regression is testing against an intercept-only model. 

{pstd}
21. Regressions use one-tail F-tests because we assume that more parameters improve a model. 

{pstd}
22. The Total Sum of Squares (TSS) is equal to the sum of the Residual Sum of Squares (RSS) and the Model Sum of Squares (MSS), TSS = RSS + MSS. 

{pstd}
23. The Total Sum of Squares (TSS) is equal to the sum of the squared differences between the observed and the mean value of Y, i.e., TSS = SUM(Y_obs - Y_bar)^2. 

{pstd}
24. The Residual Sum of Squares (RSS), also known as the Sum of Squared Errors (SSE), is the sum of the squared residuals or the sum of the squared differences between the observed Y and the predicted Y, i.e., RSS = SUM(Y_obs - Y_hat)^2. 

{pstd}
25. The Model Sum of Squares (MSS), also known as the Explained Sum of Squares (ESS) or the Regression Sum of Squares (SSR), is the sum of the squared differences between the predicted and the mean value of Y, i.e., MSS = SUM(Y_hat - Y_bar)^2. 

{pstd}
26. The Model Sum of Squares (MSS) is also known as the Explained Sum of Squares (ESS) and the Regression Sum of Squares (SSR). 

{pstd}
27. The Sum of Squares can be expressed as TSS=RSS+MSS or SUM(Y_obs - Y_bar)^2 = SUM(Y_obs - Y_hat)^2 - SUM(Y_hat - Y_bar)^2 

{pstd}
28. In a regression model, Y and X are the dependent and independent variables, respectively. 

{pstd}
29. In a regression model, Y and X are the regressand and the regressor, respectively. 

{pstd}
30. Depending on the context, the independent variable X is sometimes also called regressor, covariate, predictor variable, exposure variable, control variable, manipulated variable, explanatory variable, and input variable.  

{pstd}
31. Depending on the context, the dependent variable Y is sometimes also called regressand, outcome, predicted variable, explained variable, response variable, measured variable, observed variable, responding variable, and output variable.  

{pstd}
32. In econometrics, the error term is also called the disturbance term.  

{pstd}
33. In regression analysis, there is a subtle difference between errors and residuals. The error of an observation is the deviation of the observed value from the true value of a quantity of interest (for example, a population mean). 
The residual is the difference between the observed value and the estimated value of the quantity of interest (for example, a sample mean).  

{pstd}
34. The error term and the residuals are different. The error term is a theoretical construct of all the variables and random factors affecting Y. Residuals are observed deviations of the fitted values from the observed values.  

{pstd}
35. In a regression fitted values and predicted values are the same.  

{pstd}
36. In a regression, the Residual degrees of freedom (df) is equal to N-k-1 where N is the number of observations, k the number of explanatory variables, and 1 df is used by the constant or intercept. In a bivariate model df = N-2.  

{pstd}
37. Residual degrees of freedom (df) represent the number of unused explanatory variables by the regression model and is equal to N-k-1. 

{pstd}
38. Model degrees of freedom (df) are the number of explanatory variables used by the regression model excluding the intercept (constant or alpha term).  

{pstd}
39. In a log-linear or log-level regression model, a beta of 0.05 indicates that a 1 unit change in X causes approximately a 0.05*100=5 percent (%) change in Y. 

{pstd}
40. In a linear-log or level-log regression model, a beta of 250 indicates that a 1% change in X causes approximately a 250/100 = 2.5 unit increase in Y.  

{pstd}
41. In a log-log regression model, a beta of 3 indicates that a 1 percent (%) change in X causes approximately a 3 percent (%) increase in Y.  

{pstd}
42. To interpret a model with only a log-transformed dependent variable (Y) exponentiate the coefficient, subtract one from this number, and multiply by 100. 
This gives the percent (%) change in Y from a one-unit increase in X. For example, if the coefficient is 0.251 then exp(0.251) – 1) * 100 = 28.53. For every one-unit increase in X, the Y variable increases by 28.53%.  

{pstd}
43. To interpret a model with only a log-transformed independent variable (X) multiply the coefficient by log(1.x) where x is the percent increase. 
This gives the unit change in Y from an x percent change in X. For example, if the coefficient is 0.251 then a 10% increase in X causes a change in Y by 0.251*log(1.10)=0.0239 units. 

{pstd}
44. To interpret a model where both dependent (Y) and independent (X) variables are log-transformed calculate 1.x to the power of the coefficient, subtract 1, and multiply by 100, where x is the percent change in X. 
For example, if the coefficient is 0.251 a 10% increase in X will change Y by (1.10^0.251 - 1)*100=2.421.  

{pstd}
45. In a log-transformed dependent variable (Y) model (i.e., log-linear) a larger beta quickly worsens our approximation interpretation of the effect of X on Y. 

{pstd}
46. In a log-transformed dependent variable (Y) model (i.e., log-linear) the true effect of a positive beta is larger than its approximation and smaller than its approximation for a negative beta.  

{pstd}
47. The root mean square error (Root MSE) can be loosly interpreted as the average error of the model.  

{pstd}
48. The Durbin–Wu–Hausman test (often referred to as the Hausman test) is used to determine whether a fixed effects or a random effects model in panel analysis should be used. 
It does so by determining the consistency of the RE when compared to the FE which is less efficient but alreayd known to be consistent. 

{pstd}
49. The Durbin–Watson and the Breusch–Godfrey tests are detect autocorrelation (or serial correlation) in the errors of a regression model. 
Autocorrelation occurs when the errors are correlated with each other over time or across observations. 

{pstd}
50. The Ramsey Regression Equation Specification Error Test (RESET) is a general test for functional form mispecification of linear regression models and uses the polynomial of fitted values (Y_hat) 
as explanatory variables to test whether the original equation missed important nonlinearities. 

{pstd}
51. The Variance Inflation Factor (VIF) is a way to quantify the severity of multicollinearity in regression analysis.  

{pstd}
52.The Jarque-Bera test is a test for normality. It is used to test whether sample data have the skewness and kurtosis matching a normal distribution which is an important assumption of many statistical tests and models.

{pstd}
53.The Granger causality test is used for determining whether one time series variable is useful in forecasting changes in another time series variable. Rather than testing whether X causes Y, the Granger causality tests whether X forecasts Y (i.e., whether they are temporally related). 

{pstd}
54. The Breusch–Pagan and the White Test are used to test for heteroskedasticity in the errors of a regression analysis. Heteroskedasticity occurs when the variance of the errors is not constant across observations. 

{pstd}
55. Heteroskedasticity tests check whether the variance of the errors in a regression model is constant (i.e., homoskedasticity).  

{pstd}
56. The Interquartile Range (IQR) is a measure of statistical dispersion and is defined as the difference between the 75th (upper quartile) and 25th (lower quartile) percentiles of the data, IQR = Q3-Q1.  

{pstd}
57. A boxplot is a standardized way of displaying the distribution of data based on the minimum (0th percentile), the first quartile (25th percentile), 
the median (50th percentile), the third quartile (75th percentile), and the maximum (100th percentile). 

{pstd}
58. The mean, median, and mode are three common measures of central tendency used to describe a set of data. The mean is calculated by adding up all the values in a dataset and dividing by the 
number of values. The median is the middle value in a dataset when the values are arranged in numerical order. The mode is the value that occurs most frequently in a dataset. 

{pstd}
59. In mathematics, there exist three classical Pythagorean means, namely the arithmetic mean, the geometric mean, and the harmonic mean.  

{pstd}
60. The Pythagorean arithmetic mean is a type of average that takes the sum of all measurements and divides by the number of observations in the data set. 
For example, for data set 4, 7, 3, 9 the AM is (4+7+3+9)/4=5.75. 

{pstd}
61. The Pythagorean geometric mean is a type of average that is calculated by taking the nth root of the product of n numbers. For example, for data set 4, 7, 3, 9 the GM is (4*7*3*9)^(1/4)=5.243.  

{pstd}
62. The Pythagorean harmonic mean is a type of average that takes the reciprocal of the arithmetic mean of the reciprocal terms in that data set. 
For example, for data set 4, 7, 3, 9 the HM is 4/(1/4+1/7+1/3+1/9)=4.77. 

{pstd}
63. Central tendency is a statistical concept that summarizes a data set through a single value that reflects the typical or central value of a distribution of data; these measures include the mean, median, and mode.  

{pstd}
64. The truncated mean (also known as the trimmed mean) is a type of average that is calculated by removing a certain percentage of the highest and lowest values in a dataset and then taking the mean of the remaining values. 
This is done to limit the influence of extreme values or outliers in a dataset. 

{pstd}
65. The Winsorized mean is a type of average that replaces extreme values or outliers with less extreme values, typically the next highest and lowest values, 
and then calculates the mean rather than completely removing extreme values (i.e., truncated mean).  

{pstd}
66. In mathematics, the mode represents the value that appears most frequently in a set of data. It is possible for a dataset to be bimodal or multimodal. 

{pstd}
67. Chebyshev's inequality, also known as Chebyshev's theorem, states that no more than 1/k^2 of a distribution's values can be more than k standard deviations away from the mean.  

{pstd}
68. Chebyshev's inequality states that over 1 − 1/k^2 of a distribution's values are less than k standard deviations away from the mean.  

{pstd}
69. The 68–95–99.7 rule, also known as the empirical rule, is a rule of thumn that applies only to normal distributions. 

{pstd}
70. In a normal distribution, approximately 68% of the data falls within one standard deviation (SD) of the mean, approximately 95% falls within two SD, and approximately 99.7% falls within three SD. 

{pstd}
71. The three-sigma rule of thumb only applies to normal distributions and expresses a conventional heuristic that for normally distributed data nearly all values (99.7%) lie within three standard deviations of the mean.  

{pstd}
72. According to Chebyshev's theorem at least 88.8% of data values should fall within three standard deviations of the mean, i.e., 1 − 1/3^2 = 0.8888 

{pstd}
73. In a normal distribution, approximately 99.7% of the data lies in a range of 6 standard deviations (+/- 3 SD from the mean).  

{pstd}
74. A skewed to the right distribution (right-skewed or postive-skew distribution) is a distribution where the right-tail of the distribution is longer than the left-fail. 

{pstd}
75. In a right-skewed distribution, the majority of the data is concentrated on the left side of the distribution. 

{pstd}
76. As the degrees of freedom increase (approach infinity), the t-distribution approaches the standard normal distribution. 

{pstd}
77. The Gaussian distribution, also known as the Normal distribution or bell curve, is a continuous probability distribution that describes many real-world situations.  

{pstd}
78. A uniform distribution is a continuous probability distribution where every value is equally likely to occur. 

{pstd}
79. A rectangular distribution is a uniform distribution with finite support; i.e., a continuous probability distribution that has a constant probability density function over a specified range of value.  

{pstd}
80. The critical value for an upper one-tailed test at the 95% confidence level assuming a normal distribution (5% significance level) is approximately 1.645. 

{pstd}
81. The critical value for a two-tailed test at the 95% confidence level assuming a normal distribution (5% significance level) is approximately +/- 1.96.  

{pstd}
82. The critical value for a two-tailed test at the 99% confidence level assuming a normal distribution (1% significance level) is approximately +/- 2.576.  

{pstd}
83. For any given significance or confidence level, one-tailed tests lower the critical value necessary to reject the null hypothesis and therefore increase the probability of finding an effect. 
For example, at the 95% confidence level (5% significance level) the critival values for one-tail and two-tail test are 1.645 and 1.96, respectively. 

{pstd}
84. A standard normal distribution is a specific type of probability distribution that has a mean of zero and a standard deviation of one. 

{pstd}
85. A sampling distribution is a theoretical distribution that describes the possible values of a statistic that we might observe from random samples drawn from a population. For example, 
if we took repeated random samples of 100 students and compute the mean student height of each sample, the distribution of these sample means would be the sampling distribution of the mean, 
and it would help us understand the range of values we might expect the true population mean to fall within. 

{pstd}
86. A discrete distribution is a probability distribution that describes the occurrence of discrete (individually countable) outcomes, for example as 1, 2, and 3, or yes and no, or true and false. 

{pstd}
87. The roll of a die generates a discrete distribution with p = 1/6 for each outcome.  

{pstd}
88. Percentage points (pp) and percent (%) are not the same thing, for example the difference between 5% and 7% is 2 percentage points or 40 percent.  

{pstd}
89. The covariance between two variables can be both positive or negative, while the variance is always positive.  

{pstd}
90. Logarithmic transformations can only be done on positive values.

{pstd}
91. To standardize a variable subtract the mean of the variable from each observation and divide by its standard deviation; i.e., z = (x-mu)/sd. 

{pstd}
92. Panel data is also known as longitudinal data, while repeated cross-sectional data administers a survey to a new sample of interviewees at successive time points. 

{pstd}
93. A random sample is a subset of a larger population that is selected in a way that every unit of observation has an equal chance of being included in the sample. 

{pstd}
94. A confounder (Z) is a missing variable that is related to both the explanatory (X) and the dependent (Y) variables. 
In other words, it is associated with both the exposure and the outcome, and can create a spurious association between them when not controlled for. 

{pstd}
95. A mediator (M) is a variable that lies in between the casual chain (X --> M --> Y), so that M is the mechanism that causes the association between X into Y or in other words X affects Y through M.  

{pstd}
96. In multilevel modelling, the grand mean refers to the average (i.e., the mean) of the cluster or group-level averages.  

{pstd}
97. In multilevel analysis, the model's constant is the grand mean.  

{pstd}
98. In panel data analysis, fixed effects models are often preferred because they are always consistent.  

{pstd}
99. In panel data analysis, a random effects model is more efficient than a fixed effects model but could be an inconsistent estimator. 

{pstd}
100. In a fixed effects model, all time-invariant or cluster-invariant (i.e., constants) variables are dropped. 

{pstd}
101. It is possible to estimate the effect of constants, such as time- or cluster-invariant variables, when using a model that estimates within-unit effects by estimating a within-between model, 
such as the Mundlak (1978) or the Hybrid (Allison 2009) model. 

{pstd}
102. In a random effects model, only some unobserved heterogeneity is removed. In a fixed effects regression, all unobserved heterogeneity is removed.

{pstd}
103. Multilevel, hierarchical, nested, and panel analysis are terms that are often used interchangeably and refer to the same data structure. 

{pstd}
104. A variance components analysis decomposes the overall variance of an outcome (Y) into the variance due to cluster-level (between) and individual-level (within) variance. 

{pstd}
105. The intraclass correlation is the ratio of the between-cluster variance to the total variance. 

{pstd}
106. The intraclass correlation can explain whether most variability in an outcome occurs between clusters or within clusters; 
a high ICC means most variance is between groups, while a low ICC means most variance is within groups. 

{pstd}
107. Odds refer to the likelihood of an event occurring compared to the likelihood of it not occurring.

{pstd}
108. Odds ratio compares the odds of an event occurring in one group to the odds of it occurring in another group. 

{pstd}
109. If the odds ratio (OR) is > 1 this means that the odds are higher in numerator group A than in denominator group B.

{pstd}
110. The probability is bounded between 0 and 1 while the odds ranges from 0 to infinity. 

{pstd}
111. Permutations refer to the arrangements of objects in a specific order, while combinations refer to the selection of objects without considering the order.

{pstd}
112. Permutations and combinations are different concepts in mathematics. Permutations refer to the order or number of ways in which a set of objects can be ordered. For example, 
for set {A, B, C} the number of permutations taking two objects at a time is 6 (AB, AC, BA, BC, CA, CB). Combinations, on the other hand, 
don't refer to the order but the number of ways to select a number of objects. For example, for set {A, B, C} the number of combinations taking two objects at a time is 3 (AB, AC, BC).

{pstd}
113. The second order condition of a function at a critical point identifies whether an inflexion point is a maxima or minima.  

{pstd}
114. If the second order condition (second derivative) of the function evaluated at the critical point is positive, then the critical point is a local minimum.  

{pstd}
115. If the second order condition (second derivative) of the function evaluated at the critical point is negative, the critical point is a local maximum.  

{pstd}
116. An open interval does not include its endpoints, and is indicated with parentheses. For example, (0,1) means greater than 0 and less than 1. 

{pstd}
117. A closed interval includes its limit points, and is denoted with square brackets. For example, [0,1] means greater than or equal to 0 and less than or equal to 1. 

{pstd}
118. A half-open interval includes only one of its endpoints, and is denoted by mixing the notations for open and closed intervals. 
For example, (0,1] means greater than 0 and less than or equal to 1, while [0,1) means greater than or equal to 0 and less than 1.  

{pstd}
119. A correlation measures a linear dependence, therefore non-linear associations can have a very small correlation even though they may be highly dependent. 

{pstd}
120. Hazard ratios (HR) and the relative risk ratios (RR) are similar; however, HR care about the timing of an event, while RR measure the occurrence of an event at the end of the study.   

{pstd}
121. The terms relative risk ratio and risk ratio are often used interchangeably to describe the same statistical measure.  

{pstd}
122. Risk ratios measure the number of positive events in relation to the number of trials. 
Odd ratios measure the number of positive events in relation to the number of negative events (i.e. non-events).  

{pstd}
123. The risk ratio of flipping a head is 0.5 (or 1:2), while the odds ratio of flipping a head is 1:1.  

{pstd}
124. Risk is another term for probability.  

{pstd}
125. The null hypothesis is the hypothesis that there is no significant difference between two groups or variables, 
and the alternative hypothesis is the hypothesis that there is a significant difference between two groups or variables. 

{pstd}
126. If the effect size is larger, it will become easier to detect, requiring a smaller sample. 

{pstd}
127. Larger samples result in a greater chance of rejecting the null hypothesis, which means an increase in the power of the hypothesis test. 

{pstd}
128. Power is the probability of correctly rejecting a null hypothesis (H0) when it is false.  

{pstd}
129. Power is the probability of finding a true positive.  

{pstd}
130. A Type 1 Error is the mistaken rejection of the null hypothesis (H0), for example the conviction of an innocent person (False Positive). 

{pstd}
131. A Type 1 Error is a False Positive (rejecting a true null hypothesis). 

{pstd}
132. A Type 1 Error rejects H0 when it is true. 

{pstd}
133. A Type 2 Error is the mistaken acceptance of the null hypothesis (H0), for example a guilty person is not convicted (False Negative). 

{pstd}
134. A Type 2 Error is a False Negative (failing to reject a false null hypothesis). 

{pstd}
135. A Type 2 Error fails to reject H0 when it is false. 

{pstd}
136. The probability of correctly failing to reject a true null hypothesis (H0) is equal to 1 minus alpha. 

{pstd}
137. The probability of correctly rejecting a false null hypothesis (H0) is equal to 1 minus beta. 

{pstd}
138. The probability of making a Type 1 Error is equal to alpha. 

{pstd}
139. The probability of making a Type 2 Error is equal to beta. 

{pstd}
140. A large p-value does not mean that there is no effect, simply that we don't have enough evidence to reject the possibility of a null effect.  

{pstd}
141. A confidence interval is calculated as the sample mean +/- the product of the chosen critical value (for example, 1.96) and the standard error.  

{pstd}
142. The standard error is calculated by dividing the standard deviation by the square root of the sample size.      

{title:Contact}

{pstd}
For corrections, suggestions, and contributions feel free to contact me at marco.santacroce@eui.eu.

{phang}


                              WWWWWWWWWWWWWW
                       :::::WWWWWWWWWWWWWWWWWWWWWWW
                    :::::::::::WWWWWWWWWWWWWWWWWWWWWWW
           /WWWWWWWWWWWWW:::::::::::WWWWWWWWWWWWWWWWWWW    >>>>>>>>>
           WWCCWWWWWWWWWWWWW:::::::::WWWWWWWWWWWWWW >>>>>>>>>>>>>>
             CCCCCCCWWWWWWWWWW:::::::::WWWWWWWWW/>>>>>     >>>>>>>>>
           CCCCCCCCCCCCWWWWWWWWW:::::::::>>WWWWW  >>>>>>>>    >>>>>
          CCCCCCCCCCCCCCCCCWWWWWWWW::::::::>WWWWWW>>>>>>>   >>>>
         CCCCCCCCCCCC            CCCWW:::::::::::>>>>>>>>>>
        CCCCCCCCC          /\       CCCW::::::WWWWWWWWWWWWWW
        CCCCCC \         /`  `\      CCCCW:::::WWWWWWWWWWWWW
         CCCC                          CCCCC::::WWWWWWWWWWW
            CC |~~|                      CCCCCCCCCCCWWWWWW
             | |~||    |~~~~|            CCCCCCCCCCCCCCCC
             |_|*||    |~~| ~|          CCCCCCCCCCCCCCCCCCC
               |_||    |* |  |            CCCCCCCCCCCCCCCC
               |  |    |__| _|                \ CCCCCCCC
    o~~~~|~~~~~~~~~\   |   |              ~~~|  CCCCCCC
    ``````\  @      `\ ~~~~  ooo          ^ /` CCCCCC	        
           /\________/      oooooo         ` CCCCCC		 
          |                  oooo            |			FRIENDS
          `\     ____                       /`			LET
            `\   |**|___                  /`			FRIENDS
              `\ ~~|___|                /`			USE
                 `\         /    ______/` MMM			RANDOM EFFECTS
                  `\__\__/`____/    |   MMMM			
                        MMM|   /::::|MMMMMMM
                        MMMM oooo::::MMMMMMMM
                   :::::MMMMoooooMMMMMMMMMMMM:::::
                 :::::MMMMoooooooMMMMMMMMMM:::::::
                :::::MMMMMooooooMMMMMMMMMM:::::::::
               :::::MMMMMM::oooMMMMMMMMMM::::::::::::
              ::::::MMMMM:::::::MMMMMMMMM:::::::::::::
                    MMMM         MMMMMMMM
                     W            MMMMMM
                                