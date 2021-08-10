{smcl}
{* *! version 1.1  24 Dec 2020}{...}
{viewerdialog fdrisk "dialog fdrisk"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "SGPV (Main Command)" "help sgpv"}{...}
{vieweralsosee "SGPV Value Calculations" "help sgpvalue"}{...}
{vieweralsosee "SGPV Power Calculations" "help sgpower"}{...}
{vieweralsosee "SGPV Plot Interval Estimates" "help plotsgpv"}{...}
{viewerjumpto "Syntax" "fdrisk##syntax"}{...}
{viewerjumpto "Description" "fdrisk##description"}{...}
{viewerjumpto "Options" "fdrisk##options"}{...}
{* viewerjumpto "Remarks" "fdrisk##remarks"}{...}
{viewerjumpto "Examples" "fdrisk##examples"}{...}
{viewerjumpto "Stored Results" "fdrisk##stored"}{...}
{title:Title}
{phang}
{bf:fdrisk} {hline 2} False Discovery or Confirmation Risk for Second-Generation P-Values (SGPV)

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{opt fdrisk}{cmd:,} {opt nulllo(string)} {opt nullhi(string)} {opt std:err(#)}  {opt nulls:pace(string)}  {opt alts:pace(string)} 
[{opt fcr} {opt l:evel(#)} {opt lik:elihood(#)} {opt nullt:runcnormal} {opt altt:runcnormal} {opt p:i0(#)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt fcr}} calculate the false confirmation risk instead of the default false discovery risk. {p_end}
{synopt:{opt nulllo(lower_bound)}}  the lower bound of the indifference zone (null interval) upon which the second-generation {it:p}-value was based.{p_end}
{synopt:{opt nullhi(upper_bound)}}  the upper bound of the indifference zone (null interval) upon which the second-generation {it:p}-value was based.{p_end}
{synopt:{opt std:err(#)}}  standard error of the point estimate.{p_end}
{synopt:{opt l:evel(#)}} confidence interval with the specified level was used to calculated the SGPV; default is {cmd:level(95)}.{p_end}
{synopt:{opt lik:elihood(#)}} likelihood support interval with level 1/k was used to calculate the SGPV.{p_end}
{synopt:{opt nulls:pace(# #)}}  support of the null probability distribution.{p_end}
{synopt:{opt nullt:runcnormal}} use Truncated-Normal-distribution as the probability distribution for the null parameter space.{p_end}
{synopt:{opt alts:pace(# #)}}  support for the alternative probability distribution.{p_end}
{synopt:{opt altt:runcnormal}} use Truncated-Normal-distribution as the probability distribution for the alternative parameter space.{p_end}
{synopt:{opt p:i0(#)}}  prior probability of the null hypothesis.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
This command computes the false discovery risk (sometimes called the "empirical bayes FDR") for a second-generation {it:p}-value of 0, or the false confirmation risk (FCR) for a second-generation {it:p}-value of 1. 
The default is to calculate the FDR. The calculation of the FCR needs to be requested by setting the option {cmd:fcr}.
This command should be used mostly for single calculations. 
For calculations after estimation commands use the {help sgpv} command.
A {dialog fdrisk:dialog box} for easier usage of this command is available.{p_end} 		
		{pstd}{space 8}The false discovery risk is defined as:{space 4} 	P(H_0|p_δ=0) = (1 + P(p_δ = 0| H_1)/P(p_δ=0|H_0) * r)^(-1){break}
		{space 8}The false confirmation risk is defined as: 	P(H_1|p_δ=1) = (1 + P(p_δ = 1| H_0)/P(p_δ=1|H_1) * 1/r )^(-1){break}
		{space 8}with r = P(H_1)/P(H_0) being the ratio of the prior probabilities for the alternative and null hypothesis
				and {it:p_δ} being the calculated SGPV.	{break}
		{space 8}See equation(4) in Blume et.al.(2018){p_end}

{pstd}
When possible, one should compute the second-generation {it:p}-value and FDR/FCR on a scale that is symmetric about the null hypothesis. 
For example, if the parameter of interest is an odds ratio, inputs  {it:"stderr"}, {it:"nulllo"},  {it:"nullhi"}, {it:"nullspace"}, and {it:"altspace"} are typically on the log scale.{p_end}

{pstd}
If option {cmd: {it:"nulltruncnormal"}} is used, then the distribution used is a truncated Normal distribution with mean equal to the midpoint of {it:"nullspace"}, 
and standard deviation equal to {it:"stderr"}, truncated to the support of {it:"nullspace"}. 
If option {cmd: {it:"alttruncnormal"}} is used, then the distribution used is a truncated Normal distribution with mean equal to the midpoint of {it:"altspace"}, 
and standard deviation equal to {it:"stderr"}, truncated to the support of {it:"altspace"}. 
Further customization of these parameters for the truncated Normal distribution are not possible, 
although they may be implemented in future versions.{p_end}

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt fcr} calculate the false confirmation risk, when the observed second-generation p-value is 1.  
The default is to calculate the false discovery risk, when the observed second-generation p-value is 0.

{phang}
{opt nulllo(lower_bound)}     the lower bound of the indifference zone (null interval) upon which the second-generation {it:p}-value was based.

{phang}
{opt nullhi(upper_bound)}     the upper bound of the indifference zone (null interval) upon which the second-generation {it:p}-value was based.

{phang}
{opt std:err(#)}     standard error of the point estimate.

{phang}
{opt l:evel(#)} confidence interval with level (1-α)100% was used to calculate the SGPV. The default is {cmd:level(95)} if option {cmd:likelihood} or no other confidence level is not set. 

{phang}
{opt lik:elihood(#)} likelihood support interval with level 1/k was used to calculated the SGPV. 

{phang}
{opt nulls:pace(lower_bound upper_bound)}  support of the null probability distribution.
The "nullspace" can contain either one or two numbers. These numbers can be also formulas which must enclosed in " ".
If "nullspace" is one number, then no distribution for the null parameter space is used. 
If "nullspace" contains two numbers separated by a space, then the distribution for the null parameter space are either the Uniform-distribution or the Truncated-Normal-distribution (option {cmd:nulltruncnormal}).
The Uniform-distribution is used as the default.

{phang}
{opt nullt:runcnormal} use the Truncated-Normal-distribution as the probability distribution for the null parameter space with the mean being the middlepoint of the nullspace and standard deviation given by option {cmd:stderr}.

{phang}
{opt alts:pace(lower_bound upper_bound)}  support for the alternative probability distribution. 
The "altspace" can contain either one or two numbers. These numbers can be also formulas which must enclosed in " ".
If "altspace" is one number, then no distribution for the alternative parameter space is used. 
If "altspace" contains two numbers separated by a space, then the distribution for the alternative parameter space are either the Uniform-distribution  or the Truncated-Normal-distribution (option {cmd:alttruncnormal}).
The Uniform-distribution is used as the default. 
 
{phang}
{opt altt:runcnormal} use Truncated-Normal-distribution as the probability distribution for the alternative parameter space with the mean being the middlepoint of the altspace and the standard deviation given by option {cmd:stderr}.

{phang}
{opt p:i0(#)}     prior probability of the null hypothesis. Default is 0.5. 
This value can be only between 0 and 1 (exclusive). 
A prior probability outside of this interval is not sensible. 
The default value assumes that both hypotheses are equally likely.

{marker examples}{...}
{title:Examples}
 {pstd}To run the examples copy the lines into a Stata or use the file {view fdrisk-examples.do} which is part of the ancillary files of the {cmd:sgpv-package}.
To download the file together with the rest of the examples {net "get sgpv.pkg, replace":click here}. {p_end}
 
{pstd}{bf:False discovery risk with 95% confidence level:} (Click to {stata run fdrisk-examples.do example1:run} the example.){break}
	. fdrisk,  nulllo(log(1/1.1)) nullhi(log(1.1)) stderr(0.8)   nullspace(log(1/1.1) log(1.1))  
		   altspace("2-1*invnorm(1-0.05/2)*0.8" "2+1*invnorm(1-0.05/2)*0.8") level(95)
		  
	{pstd}{bf:False discovery risk with 1/8 likelihood support level:}(Click to {stata run fdrisk-examples.do example2a:run} the example.){break}
	. fdrisk, nulllo(log(1/1.1)) nullhi(log(1.1)) stderr(0.8) nullspace(0) 
		 altspace("2-1*invnorm(1-0.041/2)*0.8" "2+1*invnorm(1-0.041/2)*0.8")  likelihood(0.125)
	
	{pstd}{bf:with truncated normal weighting distribution:}(Click to {stata run fdrisk-examples.do example2b:run} the example.){break}
	. fdrisk, nulllo(log(1/1.1)) nullhi(log(1.1))  stderr(0.8)  nullspace(0)  alttruncnormal 
		altspace("2-1*invnorm(1-0.041/2)*0.8" "2+1*invnorm(1-0.041/2)*0.8")  likelihood(0.125)
			  
	{pstd}{bf:False discovery risk with LSI and wider null hypothesis:}(Click to {stata run fdrisk-examples.do example3:run} the example.){break}
	. fdrisk, nulllo(log(1/1.5)) nullhi(log(1.5))  stderr(0.8)  nullspace(0) altspace("2.5-1*invnorm(1-0.041/2)*0.8" "2.5+1*invnorm(1-0.041/2)*0.8")  likelihood(0.125) 
 
	{pstd}{bf:False confirmation risk example:}(Click to {stata run fdrisk-examples.do example4:run} the example.){break}
	. fdrisk, fcr nulllo(log(1/1.5)) nullhi(log(1.5)) stderr(0.15) nullspace("0.01-1*invnorm(1-0.041/2)*0.15" "0.01+1*invnorm(1-0.041/2)*0.15")  altspace(log(1.5) 1.25*log(1.5)) likelihood(0.125) 
 
 {marker stored}{...}
{title:Stored results}
{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(fdr)}}  false discovery risk {p_end}
{synopt:{cmd:r(fcr)}}  false confirmation risk  {p_end}

{title:References}
{pstd}
 Blume JD, D’Agostino McGowan L, Dupont WD, Greevy RA Jr. (2018). Second-generation {it:p}-values: Improved rigor, reproducibility, & transparency in statistical analyses. {it:PLoS ONE} 13(3): e0188299. 
{browse "https://doi.org/10.1371/journal.pone.0188299"}

{pstd}
Blume JD, Greevy RA Jr., Welty VF, Smith JR, Dupont WD (2019). An Introduction to Second-generation {it:p}-values. {it:The American Statistician}. In press. {browse "https://doi.org/10.1080/00031305.2018.1537893"} 


{title:Author}
{p}
Sven-Kristjan Bormann, School of Economics and Business Administration, University of Tartu.

{title:Bug Reporting}
{psee}
Please submit bugs, comments and suggestions via email to: {browse "mailto:sven-kristjan@gmx.de":sven-kristjan@gmx.de}{p_end}
{psee}
Further Stata programs and development versions can be found under {browse "https://github.com/skbormann/stata-tools":https://github.com/skbormann/stata-tools}{p_end}

{title:See Also}
{pstd}
Related commands:{break}
 {help plotsgpv}, {help sgpvalue}, {help sgpower}, {help sgpv}  

