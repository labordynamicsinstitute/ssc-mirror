{smcl}


{p 8 17 2} 
{bf:xtbcfe} {hline 2}  Bootstrap Corrected Fixed Effects (BCFE) estimation and inference in dynamic panel data models
 




{p 8 17 2}
{depvar}
   
   
{synopt:{opt bci:ters(#)}}select the number of bootstrap samples used for bias-correction; default is {cmd:bciters(250)}{p_end}
{synopt:{opt crit:erion(#)}}specify the convergence criterion; default is {cmd:crit(0.005)}{p_end}
{synopt:{opt te}}include time dummies{p_end}

{syntab:Resampling}
{synopt :{cmdab:res:ampling(}{it:{help xtbcfe##resampling:scheme}}{cmd:)}}select the error (re)sampling pattern; default is {cmd:res(mcho)}{p_end}
{synopt :{cmdab:ini:tialization(}{it:{help xtbcfe##initialization:initial}}{cmd:)}}select the method used for generating initial conditions; default is {cmd:ini(det)}{p_end}

{syntab:Inference}
{synopt:{cmdab:infer:ence(}{it:{help xtbcfe##inference:option}}{cmd:)}}choose a method for standard errors and confidence intervals; default is no inference{p_end}
{synopt:{cmdab:dist:ribution(}{it:{help xtbcfe##distribution:histogram}}{cmd:)}}save the {cmd:bcfe} bootstrap distribution in {cmd:e(dist_bcfe)} and select a histogram option{p_end}
{synopt:{opt infit:ers(#)}}select the number of bootstrap samples used for inference{p_end}
{synopt:{opt level(#)}}select the confidence level for confidence intervals; default is {cmd:level(95)}{p_end}
{synopt:{opt param}}request parametric bootstapping for inference instead of the non-parametric default{p_end}
{p 4 6 2}{hline 1} The {helpb estout}, {helpb moremata} and {helpb distinct} packages must be installed before the {cmd:xtbcfe} routine can be applied {p_end}
{p 4 6 2}{hline 1} Lags of {depvar} should not be included in {it:varlist} but specified through the {cmd:lags(#)} option. Also, time series operators are not allowed in {it:varlist} {p_end}
{p 4 6 2}{hline 1} Time dummies in {it:varlist} will be removed; include time effects with the {cmd:te} option {p_end}
   
   
{synoptset 20}{...}
{synopt :{opt thet_r}}resampling error terms: randomized temporal heteroscedasticity{p_end}
{synopt :{opt wboot}}resampling error terms: wild bootstrap{p_end}
{synopt :{opt wboot_r}}resampling error terms: randomized wild bootstrap (balanced panels only) {p_end}
{synopt :{opt csd}}resampling error terms: contemporaneous cross-sectional dependence (balanced panels only) {p_end}

{synoptset 20}{...}
   
{synoptset 20}{...}
{synopt :{opt all}}Save the {cmd:bcfe} distribution in {cmd:e(dist_bcfe)} and display histograms for all AR coefficients and their sum {p_end}
{synoptline}
{p 4 6 2}{hline 1} Omit the {cmd:distribution} option entirely to delete the bootstrap distribution after estimation{p_end}

{title:Postestimation syntax}

   Syntax for {cmd:predict} after {cmd:xtbcfe} estimation 

{p 8 17 2}
   [type]
   
   where y[i,t] =  y[i,t-1]a[1] + ... + y[i,t-p]a[p] + x[i,t]b + u[i] + e[i,t]


{synoptset 20}{...}
{synopt :{opt xbu (*)}} a[1]y[i,t-1] + ... + a[p]y[i,t-p] + x[i,t]b + a[i] ; fitted values, including the fixed effect {p_end}
{synopt :{opt u   (*)}} u[i] ; the fixed effect {p_end}
{synopt :{opt e   (*)}} e[i,t] ; the observation-specific error component {p_end}

{p 2 2 2}
Unstarred statistics are available both in and out of sample; type "{cmd:predict ... if e(sample) ...}" to calculate the statistic only for the
estimation sample. Starred statistics can only be calculated for the estimation sample, even when "{cmd:if e(sample)}" is not specified. 



{p 8 17 2} y[i,t] =  y[i,t-1]a[1] + ... + y[i,t-p]a[p] + x[i,t]b + u[i] + e[i,t]

	where - a[1] to a[p] are the autoregressive coefficients (coefficients for lags of the dependent variable)
	      - b is the coefficient vector for the strictly exogenous predictors x
	      - u[i] is the fixed effect corresponding to cross-section i
	      - e[i,t] is the error specific to cross-section i at time t

{pstd}
{cmd: xtbcfe} estimates the specified model with the fixed effects estimator and corrects its small T bias (see Nickell, 1981) using a simplified but extended version of the approach presented in Everaert and Pozzi (2007). 
The algorithm evaluates the bias of fixed effects in a numerical way to avoid the use of analytical correction formulas. {cmd:xtbcfe} is 
therefore also applicable to higher order (more than one lag of the dependent variable) models with a potential non-standard error structure. With an appropriate choice of the resampling scheme, {cmd:xtbcfe} can take into account 
several heteroscedasticity and cross-sectional dependence patterns which would invalidate the standard correction methods.
   

{phang}

{phang}
{opt bci:ters(#)} specifies the number of bootstrap samples used to evaluate the bias of the fixed effects estimator. As we evaluate the bias numerically, more samples implies a higher degree of accuracy and less remaining bias. 
However, as the algorithm works with estimated means, the number of samples does not need to be very large to provide reliable results. The default is 250 samples. 

{phang}
{opt crit:erion(#)} indicates the criterion that needs to be satisfied before the algorithm is terminated. The default is {cmd:crit(0.005)}. This number is multiplied by the number of lags of the dependent variable ({cmd:lags(#)}) 
as it will be more difficult to satisfy in larger models. Convergence of the algorithm is evaluated by taking the (absolute) difference between estimates of two consecutive iterations of the bootstrap estimator. If this difference is smaller 
than the number supplied, the algorithm stops and estimates from the final iteration are the {cmd:bcfe} coefficient estimates. If convergence has not been achieved after a few iterations, we compare the difference between the average 
over the last 4 iterations and the average 4 iterations before with the criterion. This avoids that the algorithm alternates indefinitely within a small band. 
Note that computation time will be influenced by the size of this number as a small criterion implies that we are strict before accepting convergence and hence require more iterations.

{phang}
time indicator specified by the {cmd:xtset} command. Variables in the active dataset with identical names will be overwritten. Time dummies in the variable list will be deleted.  

{dlgtab:Resampling} 

{phang}
the resampling process is as random as possible while preserving the error structure (e.g. heteroscedasticity, cross-section dependence,...). Below we describe the resampling options. We denote e_b[i,t] as the sampled error term in 
period t for cross section i and call e[i,t] the original estimated error term.

{p 10 17 2} 
{opt mcho}: {it:Monte Carlo homoscedastic}: sample error terms from the normal distribution with homoscedastic variance. 

{p 10 17 2}  
{opt mche}: {it:Monte Carlo heteroscedastic}: sample error terms from the normal distribution with cross-section specific variance.

{p 10 17 2}  
{opt mcthe}: {it:Monte Carlo temporal heteroscedasticity}: sample error terms from the normal distribution with period-specific (t-specific) variance.

{p 10 17 2} 
{opt iid}: resample error terms independently, i.e. set e_b[i,t] = e[j,s] with j and s drawn completely at random from 1,...,N and 1,...,T respectively.

{p 10 17 2} 
{opt cshet}: {it:cross-sectional heteroscedasticity}: resample error terms within cross-sections, i.e. for every t=1,...,T we set e_b[i,t] = e[i,s] where s is drawn with replacement from 1,...,T.

{p 10 17 2}  
{opt cshet_r}: {it:randomized cross-sectional heteroscedasticity}: similar to {cmd:cshet} we resample error terms within cross-sections but then reshuffle cross-section indices. Hence, error term vectors are no longer bound 
to their respective cross-sections but randomly reassigned, i.e. for every cross-section i=1,...,N we draw a j with replacement from 1,...,N (assign a fixed j to every i) and for every t=1,...,T set e_b[i,t] = e[j,s] with 
s drawn with replacement from 1,...,T.

{p 10 17 2} 
{opt thet}: {it:temporal heteroscedasticity}: resample error terms within time periods; i.e. for every t=1,...,T we set e_b[i,t] = e[j,t] where j is drawn with replacement from j = 1,...,N.

{p 10 17 2} 
{opt thet_r}: {it:randomized temporal heteroscedasticity}: resample whole time periods and then resample error terms within time periods (see above); i.e. for every t=1,...,T we draw 
a time index s with replacement from 1,...,T (assign a fixed s to every t) and set e_b[i,t] = e[j,s] where j is drawn with replacement from j = 1,...,N.

{p 10 17 2} 
{opt wboot}: {it:wild bootstrap}: multiply the error term with a factor -1 with 0.5 probability, i.e. for every i=1,...,N and t=1,...,T we set e_b[i,t] = e[i,t]*g, where g a random variable that equals 1 or -1
 each with 0.5 probility.

{p 10 17 2} 
{opt wboot_r}: {it:randomized wild bootstrap}: resample cross-section indices (sample a random cross-section's error terms as those for cross-section i), 
then multiply the error term with -1 with 0.5 probability (balanced panels only!); i.e. for every i=1,...,N draw a cross-section index j with replacement from 1,...,N 
(assign a fixed j to every i) and set e_b[i,t] = e[j,t]*g 

{p 10 17 2} 
{opt csd}: {it:cross-sectional dependence}: resample time indices (identically for all cross-sections) but keep error terms cross-section specific (balanced panels only!); 
i.e. for every t=1,...,T we draw a time index s with replacement from 1,...,T (assign a fixed s to every t) and set e_b[i,t] = e[i,s]. For example, for t=1 we randomly draw t=5.
 Then we assign the t=5 error term to t=1 for every cross-section i, i.e. for i=1,...,N we set e_b[i,1] = e[i,5].

{dlgtab:Initialization}
The following options are available

{p 10 17 2} 
{opt det}: {it:deterministic initialization}: initial observations are kept fixed, i.e. we initiate data generation with initial conditions observed in the original sample.

{p 10 17 2} 
{opt bi}: {it:burn-in initialization}: the series for the dependent variable is initiated at zero and data are generated using the
currently estimated model parameters and selected resampling scheme. After a burn-in period we take the generated conditions as the initial values
for the bootstrap sample. Note that this is the most general initialization scheme that also takes the specified resampling process into account.

{p 10 17 2} 
{opt aho}: {it:analytical homogeneous initiation}: initial conditions are sampled from the multivariate normal distribution with cross-section specific mean but a homogeneous variance-covariance matrix 
(estimated variance-covariance matrices are averaged over cross-sections). 

{p 10 17 2} 
{opt ahe}: {it:analytical heterogeneous initiation}: initial conditions are sampled from the multivariate normal distribution with cross-section specific means and variance-covariance matrices. 

{dlgtab:Inference}

{phang}
the bootstrap bias-correction to the fixed effects estimates in each of the constructed samples. From this simulated distribution we can then calculate standard deviations and percentile intervals. 
Alternatively, we may roughly approximate the distribution of {cmd:xtbcfe} from the distribution of the fixed effects estimates in the constructed samples. The available options are listed below

{p 10 17 2} 
{opt inf_appr}: approximate the standard error of {cmd:xtbcfe} using the bootstrapped distribution of the fixed effects estimator and calculate confidence intervals using the t-distribution. 
This is the fastest option for standard error estimation but is known to be biased downwards. Use only as a fast and rough indication. 

{p 10 17 2} 
{opt inf_se}: estimate the {cmd:xtbcfe} variance covariance matrix using the bootstrap and calculate the corresponding confidence intervals from the t-distribution.  

{p 10 17 2} 
{opt inf_ci}: estimate the {cmd:xtbcfe} variance covariance matrix using the bootstrap. Confidence intervals are bootstrap percentile intervals. Percentile intervals may be more appropriate 
in small datasets where the {cmd:bcfe} estimator may have a non-normal or skewed distribution.    

{phang}
the bootstrap distribution and calculate additional statistics. If the {cmd:distribution} option is not specified the bootstrap matrix will be deleted after estimation. Note that these 
options will be ignored if the estimation algorithm failed to converge.

{p 10 17 2} 
{opt dist:ribution(none)}: saves the obtained coefficient matrix after estimation without further action. 

{p 10 17 2} 
{opt dist:ribution(sum)}: saves the coefficient matrix and displays a histogram for the sum of the coefficients on the lagged dependent variable(s). This may be informative to assess stationarity. 

{p 10 17 2} 
{opt dist:ribution(all)}: saves the coefficient matrix and displays histograms for all autoregressive coefficients separately as well as their sum.

{phang}
We recommend 50 or greater for the {cmd:inf_appr} or {cmd:inf_se} options and 1000 for the {cmd:inf_ci} option.

{phang}

{phang}
small sample distribution of the BCFE estimator is exactly the same as the resampling of the data used to bias-correct the FE estimator. 
As such, each of the above mentioned resampling and initialization schemes is available. In the non-parametric case (the default setting), we resample the original data for cross-sectional 
units as a whole with replacement. The advantage of this resampling scheme is that it preserves the dynamic panel structure without the need to make parametric assumptions. 


{hline 1} The computation time of the algorithm is mainly determined by the {opt bci:ters(#)}, {opt infit:ers(#)} and {opt crit:erion(#)} options. However, computation time will also 
(to a lesser degree) be dependent on the chosen resampling scheme and properties of the data (non-stationarity, noise,...).
{hline 1} As gaps in the observed time series will result in inconsistency for dynamic models (see Millimet and McDonough, 2013), {cmd:xtbcfe} will adjust the estimation sample to avoid this issue. 
Observations are removed so that the data is free of gaps but the estimation sample is still as large as possible.

{phang}
{hline 1} {cmd:xtbcfe} will not attempt inference in case the algorithm failed to converge. Estimates would not be reliable and are unsuitable for the inference algorithm. Convergence can often 
be achieved without altering the convergence criterion by selecting the deterministic initiation {cmd:ini(det)}.



    
load the Arellano-Bond dataset
{phang}{cmd:. webuse abdata}

Estimate a second order model (two lags of n) with iid resampling and burn-in initialization

Add time dummies to the model

Take temporal heteroscedasticity into account by adjusting the resampling scheme
{phang}{cmd:. xtbcfe n w wL1 k kL1 kL2 ys ysL1 ysL2, bciters(250) res(thet) ini(bi) lags(2) te}

Relax the convergence criterion from 0.005 to 0.01

Perform inference on the model with confidence intervals based on the t-distribution
{phang}{cmd:. xtbcfe n w wL1 k kL1 kL2 ys ysL1 ysL2, bciters(250) res(thet) ini(bi) lags(2) infer(inf_se) infit(50) te}

Perform inference with percentile intervals
{phang}{cmd:. xtbcfe n w wL1 k kL1 kL2 ys ysL1 ysL2, bciters(250) res(thet) ini(bi) lags(2) infer(inf_ci) infit(1000) te}

Perform inference with percentile intervals and save the bootstrapped distribution of {cmd:bcfe}
{phang}{cmd:. xtbcfe n w wL1 k kL1 kL2 ys ysL1 ysL2, bciters(250) res(thet) ini(bi) lags(2) infer(inf_ci) infit(1000) te dist(none)}
{synopt:{cmd:e(df_r)}}degrees of freedom{p_end}
{synopt:{cmd:e(predict)}}{cmd:xtbcfe_p}{p_end}
{synopt:{cmd:e(res_bcfe)}}observation-specific error terms{p_end}
{synopt:{cmd:e(dist_bcfe)}}bootstrap distribution for {cmd:bcfe} (only if the {opt dist:ribution} option is selected) {p_end}


{title:References}  
  
{phang}
Everaert, G. and Pozzi, L. (2007). Bootstrap-based bias correction for dynamic panels. Journal of Economic Dynamics & Control, 31, pp.1160-1184.

{phang}
Millimet, D.L. & McDonough, I.K., (2013). Dynamic Panel Data Models with Irregular Spacing: With Applications to Early Childhood Development, IZA Discussion Papers 7359, Institute for the Study of Labor (IZA).

{phang}
Nickell, S. (1981). Biases in dynamic models with fixed effects. Econometrica 49 (6), pp. 1417-1426.



{title:Authors}    
{pstd}
    
Ignace De Vos
Ignace.DeVos@UGent.be
SHERPPA, Ghent University
Faculty of Economics and Business Administration 
Department of Social Economics     
Sint-Pietersplein 6, 9000 Ghent, Belgium
    
Ilse Ruyssen
Ilse.Ruyssen@UGent.be
SHERPPA, Ghent University
Faculty of Economics and Business Administration 
Department of General Economics     
Tweekerkenstraat 2, 9000 Ghent, Belgium   
    

     