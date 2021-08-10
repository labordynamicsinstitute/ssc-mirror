{smcl}
{* *! version 1.02  10 Jul 2020}{...}
{viewerdialog sgpower "dialog sgpower"}
{vieweralsosee "" "--"}{...}
{vieweralsosee "SGPV (Main Command)" "help sgpv"}{...}
{vieweralsosee "SGPV Value Calculations" "help sgpvalue"}{...}
{vieweralsosee "SGPV False Confirmation/Discovery Risk" "help fdrisk"}{...}
{vieweralsosee "SGPV Plot Interval Estimates" "help plotsgpv"}{...}
{viewerjumpto "Syntax" "sgpower##syntax"}{...}
{viewerjumpto "Description" "sgpower##description"}{...}
{viewerjumpto "Options" "sgpower##options"}{...}
{* viewerjumpto "Remarks" "sgpower##remarks"}{...}
{viewerjumpto "Examples" "sgpower##examples"}{...}
{viewerjumpto "Stored Results" "sgpower##stored"}{...}
{title:Title}
{phang}
{bf:sgpower} {hline 2} Power functions for Second-Generation P-Values

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:sgpower}
{cmd:,} {opt true(#)} {opt nulllo(#)} {opt nullhi(#)} {opt l:evel(#)} {opt lik:elihood(#)}
[{opt std:err(#)} {opt b:onus}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt true(#)}}  the true value for the parameter of interest at which to calculate power. 			
{p_end}
{synopt:{opt nulllo(#)}}  the lower bound of the indifference zone (null interval) upon which the second-generation {it:p}-value is based.
{p_end}
{synopt:{opt nullhi(#)}}  the upper bound for the indifference zone (null interval) upon which the second-generation {it:p}-value is based.
{p_end}
{synopt:{opt l:evel(#)}}  confidence interval with the specified level was used to calculated the SGPV; default is {cmd:level(95)}.
{p_end}
{synopt:{opt lik:elihood(#)}} likelihood support interval with level 1/k was used to calculate the SGPV.
{p_end}

{syntab:Further options}
{synopt:{opt std:err(#)}}  standard error for the distribution of the estimator for the parameter of interest. 
{p_end}
{synopt:{opt b:onus}}  display the additional diagnostics for the type I error.
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
Compute power/type I error for Second-Generation P-Values approach. See {help sgpvalue##description:here} for more information about the Second-Generation P-Values.{p_end}

{pstd}
An additional {stata db sgpower:GUI} makes using this command easier.
To make the GUI available from the User-menubar, you have to run {stata sgpv menu}.{p_end}

{pstd}
The power functions are the following based on the equations (S4), (S6), (S8) and (S9) 
from {browse "https://journals.plos.org/plosone/article/file?id=10.1371/journal.pone.0188299.s001&type=supplementary":the supplementary material} to Blume et al.(2018): {p_end}
		P_θ(p_δ = 0) 	   = ϕ[(θ_0 - δ) /SE - θ/SE + Z_α/2 ] + ϕ[ -(θ_0 + δ) /SE + θ/SE - Z_α/2 ] 
		P_θ(p_δ = 1) 	   = ϕ[(θ_0 + δ) /SE - θ/SE - Z_α/2 ] - ϕ[  (θ_0 - δ) /SE - θ/SE + Z_α/2 ] 
		P_θ(0 < p_δ < 1) = 1 - ϕ[ (θ_0 - δ) /SE - θ/SE - Z_α/2 ] + ϕ[ -(θ_0 + δ) /SE + θ/SE - Z_α/2 ]
				     - ϕ[ (θ_0 + δ) /SE - θ/SE - Z_α/2 ] - ϕ[  (θ_0 - δ) /SE - θ/SE + Z_α/2 ] 
							when δ > Z_α/2 * SE 				 
		P_θ(0 < p_δ < 1) = 1 - ϕ[ (θ_0 - δ) /SE - θ/SE - Z_α/2 ] + ϕ[ -(θ_0 + δ) /SE + θ/SE - Z_α/2 ] 
					 when δ <= Z_α/2 * SE					 

		{pstd} SE denotes the standard error, (θ_0 - δ) and (θ_0 + δ) denote the lower and upper bound of the null interval.


{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt true(#)}     the true value for the parameter of interest at which to calculate power. 
			Note that this is on the absolute scale of the parameter, and not the standard deviation or standard error scale.
			
{phang}
{opt nulllo(#)}     the lower bound of the indifference zone (null interval) upon which the second-generation {it:p}-value is based.

{phang}
{opt nullhi(#)}     the upper bound for the indifference zone (null interval) upon which the second-generation {it:p}-value is based.

{phang}
{opt l:evel(#)} confidence interval with level (1-α)100% was used to calculated the SGPV. The default is {cmd:level(95)} or as set by {helpb set level} if option {cmd:likelihood} or another confidence level is not set. 

{phang}
{opt lik:elihood(#)} likelihood support interval with level 1/k was used to calculate the SGPV. 
				
{pstd}
{p_end}

{dlgtab:Further options}
{phang}
{opt std:err(#)}     standard error for the distribution of the estimator for the parameter of interest. 
			Note that this is the standard deviation for the estimator, not the standard deviation parameter for the data itself. 
			This will be a function of the sample size(s).
			
{pstd}
{p_end}
{phang}
{opt b:onus}     display the additional diagnostics for type I error. These are different ways the type I error may be summarized for an interval null hypothesis.

{pstd}
{p_end}

{marker examples}{...}
{title:Examples}
{pstd}
{stata . sgpower,true(2) nulllo(-1) nullhi(1) stderr(1)} {break}
{stata . sgpower,true(0) nulllo(-1) nullhi(1) stderr(1)}

{pstd}Plot the power curve examples: Click {view sgpower-plot-example.do:here} to view the code which is part of the ancillary files of the {cmd:sgpv-package}.
To download the file together with the rest of the examples click {net "get sgpv.pkg, replace":here}.{break}
{stata . do sgpower-plot-example.do}

{marker stored}{...}
{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(poweralt)}}  probability of SGPV = 0 calculated assuming the parameter is equal to {cmd:true}.	 That is, {cmd:poweralt} = P(SGPV = 0 | θ = {cmd:true}).  {p_end}
{synopt:{cmd:r(powernull)}}  probability of SGPV = 1 calculated assuming the parameter is equal to {cmd:true}. 	That is, {cmd:powernull} = P(SGPV = 1 | θ = {cmd:true}). {p_end}
{synopt:{cmd:r(powerinc)}}  probability of 0 < SGPV < 1 calculated assuming the parameter is equal to {cmd:true}. 	That is, {cmd:powerinc} = P(0 < SGPV < 1 | θ = {cmd:true}). {p_end}

{pstd}The next three scalars are only returned if the bonus-option was used.{p_end}
{synopt:{cmd:r(minI)}}  is the minimum type I error over the range ({cmd:nulllo}, {cmd:nullhi}), which occurs at the midpoint of ({cmd:nulllo}, {cmd:nullhi}). {p_end}
{synopt:{cmd:r(maxI)}}  is the maximum type I error over the range ({cmd:nulllo}, {cmd:nullhi}), which occurs at the boundaries of the null hypothesis, {cmd:nulllo} and {cmd:nullhi}.  {p_end}
{synopt:{cmd:r(avgI)}}  is the average type I error (unweighted) over the range ({cmd:nulllo}, {cmd:nullhi}). {p_end}

{pstd}If 0 is included in the null hypothesis region, then "type I error summaries" also contains "at 0":{p_end}
{synopt:{cmd:r(pow0)}}  is the type I error assuming the true parameter value θ is equal to 0. {p_end}


{title:References}
{pstd}
 Blume JD, D’Agostino McGowan L, Dupont WD, Greevy RA Jr. (2018). Second-generation {it:p}-values: Improved rigor, reproducibility, & transparency in statistical analyses. {it:PLoS ONE} 13(3): e0188299. 
 {browse "https://doi.org/10.1371/journal.pone.0188299"}

{pstd}
Blume JD, Greevy RA Jr., Welty VF, Smith JR, Dupont WD (2019). An Introduction to Second-generation {it:p}-values. {it:The American Statistician}. In press. {browse "https://doi.org/10.1080/00031305.2018.1537893"} 


{title:Author}
{pstd}
Sven-Kristjan Bormann, School of Economics and Business Administration, University of Tartu.

{title:Bug Reporting}
{psee}
Please submit bugs, comments and suggestions via email to:	{browse "mailto:sven-kristjan@gmx.de":sven-kristjan@gmx.de}{p_end}
{psee}
Further Stata programs and development versions can be found under {browse "https://github.com/skbormann/stata-tools":https://github.com/skbormann/stata-tools}{p_end}



{title:See Also}
{pstd}
Related commands:{break}
 {help fdrisk}, {help plotsgpv}, {help sgpvalue}, {help sgpv}

