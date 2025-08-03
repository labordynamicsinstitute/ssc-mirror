{smcl}

help for {hi:varlmhet}                            (Version 1.0.1, 01 Aug 2025)


{title: White test for heteroscedasticity in time-series VAR model}

{p 8 16 2}    {cmd: varlmhet} {cmd:,} [{cmdab:n:ocross}] 


{cmd:varlmhet} is for use with time-series data, following use of  {cmd:var} and requiring 
prior use of {cmd:tsset}.


{title:Description}

{cmd:varlmhet} calculates the White statistic for heteroscedasticity in the residuals of a 
time-series VAR model, following Doornik (1996).
 
A fundamental assumption of time series VAR models is that the error variances and 
covariances are constant or homogeneous. When this assumption is violated, statistical 
inferences  for parameters, response functions, and forecast error variance decompositions 
may be misleading and a standard error adjustment is necessary.

{cmd:varlmhet} tests the null hypothesis that the error variances and covariances are constant 
through two versions of the White (1980) test: with cross-terms (default) and without 
cross-terms (when the {cmdab:n:ocross} option is specified).

The test statistic, degrees of freedom and p-value are placed in the return array.

 

{title:Examples}
	
	{p 4 8 2} . webuse lutkepohl2, clear

	{p 4 8 2} . tsset

	{p 4 8 2} . gen t=_n

	{p 4 8 2} . var dln_inv dln_inc dln_consump, lags(1/1)

	{p 4 8 2} . varlmhet

	{p 4 8 2} . varlmhet, nocross

	{p 4 8 2} . var dln_inv dln_inc dln_consump, lags(1/2) exog(l(0/1).t)	

	{p 4 8 2} . varlmhet
	
	{p 4 8 2} . varlmhet, nocross



{title:References}

{p 4 8 2} Doornik, J. A. (1996). Testing vector error autocorrelation and heteroscedasticity. 


{title:Authors}

Manh Hoang Ba, Eureka Uni Team, VNM
hbmanh9492@gmail.com


{title:Also see}

Online:  help for {help veclmhet} {if installed}, {help var}, {help varlmar}, {help vargranger}, {help varnorm}, {help varsoc}, {help varstable}.
