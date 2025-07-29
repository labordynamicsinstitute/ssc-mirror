{smcl}
help for {cmd: veclmhet}                           (Version 1.0.0, 28 July 2025)

{title: White test for heteroscedasticity in time-series VEC model}

{p 8 16 2}    {cmd: veclmhet} {cmd:,} [{cmdab:n:ocross}] 


{cmd: veclmhet} is for use with time-series data, following use of {cmd: vec} and requiring 
prior use of {cmd: tsset}.


{title:Description}
-----------

{cmd: veclmhet} calculates the LM statistic for heteroscedasticity in the residuals of a 
time-series VEC model, following Doornik (1996).
 
{cmd: veclmhet} tests the null hypothesis that the error variances and covariances are constant 
through two versions of the White (1980) test: with cross-terms (default) and without 
cross-terms (when the {cmd: nocross} option is specified).

The test statistic, degrees of freedom and p-value are placed in the return array.

 

{title:Examples}

	
	{p 4 8 2} . webuse lutkepohl2, clear

	{p 4 8 2} . tsset
	
	{p 4 8 2} . gen t=_n
	
	{p 4 8 2} . vec ln_inv ln_inc ln_consump, lags(1/1)
	
	{p 4 8 2} . veclmhet
		
	{p 4 8 2} . veclmhet, nocross
	
	{p 4 8 2} . vec ln_inv ln_inc ln_consump, lags(1/2) exog(t)
		
	{p 4 8 2} . veclmhet
		
	{p 4 8 2} . veclmhet, nocross
	


{title:References}

Doornik, J. A. (1996). Testing vector error autocorrelation and heteroscedasticity. 



{title:Authors}

Manh Hoang Ba, Eureka Uni, VNM
hbmanh9492@gmail.com


{title:Also see}


Online:  help for {help varlmhet} {if installed}, {help vec}, {help veclmar}, {help vecnorm}, {help vecstable}.
