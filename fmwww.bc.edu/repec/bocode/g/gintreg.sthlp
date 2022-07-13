{smcl}
{* *! version 2.0  21jun2022}{...}
{viewerjumpto "Syntax" "examplehelpfile##syntax"}{...}
{viewerjumpto "Description" "examplehelpfile##description"}{...}
{viewerjumpto "Options" "examplehelpfile##options"}{...}
{viewerjumpto "Remarks" "examplehelpfile##remarks"}{...}
{viewerjumpto "Examples" "examplehelpfile##examples"}{...}
{viewerjumpto "References" "references##references"}{...}

{title:Title}

{phang}
{bf:gintreg} {hline 2} Generalized Interval Regression


{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmdab:gintreg}
{it:{help depvar:depvar1}}
{it:{help depvar:depvar2}}
[{indepvars}]
[{it:if}]
[{it:in}]
[{cmd:,} {it:options}]

{pstd}
{it:depvar1} and {it:depvar2} should have the following form:

             Type of data {space 16} {it:depvar1}  {it:depvar2}
             {hline 46}
             point data{space 10}{it:a} = [{it:a},{it:a}]{space 4}{it:a}{space 8 }{it:a} 
             interval data{space 11}[{it:a},{it:b}]{space 4}{it:a}{space 8}{it:b }
             left-censored data{space 3}(-inf,{it:b}]{space 4}{cmd:.}{space 8}{it:b}
             right-censored data{space 3}[{it:a},inf){space 4}{it:a}{space 8}{cmd:.} 
             {hline 46}
			 
{pstd}
If using grouped data then the form will be similar:

	     Type of data {space 16} {it:depvar1}  {it:depvar2} {space 1} {it: frequency}
             {hline 59}
             point data{space 10}{it:a} = [{it:a},{it:a}]{space 4}{it:a}{space 8 }{it:a} {space 8} {it:n}
             interval data{space 11}[{it:a},{it:b}]{space 4}{it:a}{space 8}{it:b } {space 7} {it:n}
             left-censored data{space 3}(-inf,{it:b}]{space 4}{cmd:.}{space 8}{it:b} {space 8} {it:n}
             right-censored data{space 3}[{it:a},inf){space 4}{it:a}{space 8}{cmd:.}  {space 7} {it:n}
             {hline 59}


{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt dist:ribution(dist_type)}} Supported distributions come from the Skewed Generalized t and Generlized Beta of the Second Kind families of distributions, namely:

				Distribution{space 25}{it:dist_type}
				{hline 46}
				Normal{space 31}normal
				Skewed Normal{space 24}snormal
				Laplace{space 30}laplace
				Skewed Laplace{space 23}slaplace
				Generalized Error{space 20}ged
				Skewed Generalized Error{space 13}sged
				t{space 36}t
				Generalized t{space 24}gt
				Skewed t{space 29}st
				Skewed Generalized t{space 17}sgt
				Lognormal{space 28}lnormal
				Weibull{space 30}weibull
				Gamma{space 32}gamma
				Generalized Gamma{space 20}ggamma
				Burr type 3{space 26}br3
				Burr type 12{space 25}br12
				Generalized Beta of the Second Kind{space 2}gb2
				{hline 46}
{synopt:{opth const:raints(numlist)}} specified linear constraints by number to be applied. Can use this option along with {opt dist:ribution} to allow for any distribution in the SGT or GB2 family trees.{p_end}
{synopt:{opth freq:uency(varlist)}} if using group data specify variable that denotes frequency. {p_end}

{syntab: Model}
{synopt:{opth sigma(varlist)}} allows the {opt log of sigma} to vary as a linear function of independent variables; can use with any {it:dist_type} except gamma. {p_end}
{synopt:{opth lambda(varlist)}} allows lambda to vary as a function of independent variables; can use with {it:dist_type} snormal, slaplace, sged, st or sgt.{p_end}
{synopt:{opth p(varlist)}} allows p to vary as a linear function of independent variables; can use with {it:dist_type} ged, sged, gt, sgt, gamma, ggamma, br3 or gb2. {p_end}
{synopt:{opth q(varlist)}} allows q to vary as a linear function of independent variables; can use with {it:dist_type} t, gt, st, sgt, br12 or gb2. {p_end}

{syntab: SE/Robust}
{synopt :{opth vce(vcetype)}} {it:vcetype} may be {opt oim}, {opt r:obust}, {opt cl:uster} {it:clustvar}, {opt opg}, {opt boot:strap} or {opt jack:knife}. {p_end}
{synopt:{opt robust}} use robust standard errors. {p_end}
{synopt: {opth cluster(varlist)}} cluster standard errors with respect to sampling
unit {varlist}. {p_end}

{syntab: Estimation}
{synopt:{opth init:ial(numlist)}} initial values for p,q and lambda in that order. if the distribution does not have p, q or lambda, key in initial values for mu and lnsigma in that order. 
Because of the construction of {bf:gintreg}, redundant values are sometimes required, e.g. three values are required for the t distribution (corresponding to p, q, lambda) despite p and lambda being constrained to 2 and 0.

				Distribution{space 25}{it:initial values}
				{hline 51}
				Normal{space 31}{it:none}
				Skewed Normal{space 24}2, lambda
				Laplace{space 30}{it:none}
				Skewed Laplace{space 23}1, lambda
				Generalized Error{space 20}p, 0
				Skewed Generalized Error{space 13}p, lambda
				t{space 36}2, q, 0
				Generalized t{space 24}p, q, 0
				Skewed t{space 29}2, q, lambda
				Skewed Generalized t{space 17}p, q, lambda
				Lognormal{space 28}{it:none}
				Weibull{space 30}{it:none}
				Gamma{space 32}p
				Generalized Gamma{space 20}p
				Burr type 3{space 26}p, 1
				Burr type 12{space 25}1, q
				Generalized Beta of the Second Kind{space 2}p, q
				{hline 51}
{synopt:{it:{help ml##noninteractive_maxopts:maximize_options}}}control the
maximization process{p_end}

{syntab: Display}
{synopt: {opth eyx(stat)}} shows the expected value of {depvar} conditional on {indepvars} at indicated level of {it:stat}; default is mean. {p_end}
{synopt: {opth plot(numlist)}} plots the probability density function over chosen range. {p_end}
{synopt: {opt gini}} prints the gini coefficient. Only operational with Weibull, Gamma, Burr type 3 and Burr type 12. {p_end}
{synopt: {opt aicbic}} prints AIC and BIC values of the estimated model. Operational with non-grouped data. {p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gintreg} fits a model of {depvar} on {indepvars} using maximum likelihood
where the dependent variable can be point data, interval data, right-censored data,
 left-censored data or grouped data with different error distributions. This is a generalization of the built in STATA command {cmd: intreg} and will yield identical estimates if the normal distribution option is used. Unlike {cmd: intreg}, {cmd: gintreg} allows the underlying variable of interest to be distributed according to a more general distribution including all distributions in the Skewed Generalized t (SGT) family and Generalized Beta of the Second Kind (GB2) family. {cmd:gintreg} can also be used to fit different distributions to variables of interest. Finally, {cmd: gintreg} allows the distributional parameters in the SGT and GB2 to be functions of designated explanatory variables.

{pstd}
The assumed model for interval regression is {it:y = Xb + u} for the SGT family and {it:ln(y) = Xb + u} for the GB2 family, where only the thresholds containing the latent variable y are observed, X is a vector of explanatory variables with a corresponding coefficient vector b and the random disturbance u is assumed to be independently and identically distributed according to the selected distribution. The upper and lower thresholds for y can be denoted by U and L respectively.

{pstd}
The conditional probability that y is in the interval (L,U) is: Pr(L <= y <= U)
= F(eps = U - XB: theta) - F(eps: L-XB: theta), where F denotes the cdf of the
random disturbances and theta denotes a vector of distributional parameters. 
{cmd:gintreg} uses MLE on the corresponding log-likelihood function to estimate
beta (displayed as mu or delta in the output) and the distributional parameters 
theta.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt dist:ribution(dist_type)} specifies the type of distribution used in the interval regressions.
{cmd: gintreg} will use a log-likelihood function composed of the pdf and cdf of this distribution
(pdf for point data and cdf for intervals and censored observations). dist_type may be normal, snormal, 
laplace, slaplace, ged, sged, t, gt, st, sgt, lnormal, weibull, gamma, ggamma, br3, br12, gb2; the default is normal.

{phang}
{opth constraints(numlist)} specified linear constraints by number to be applied. Can use this option along with {opt dist:ribution} to allow for any distribution in the SGT or GB2 family trees. Constraints are defined using the {cmd:constraint} command; see {manhelp constraint R}. Examples using this option are also provided below.
{cmd:gintreg} natively uses constraints for many distributions; when applying your own, be careful not to define with same number identifier as one already used. The list of constraints are printed right above the output table or are returnable with {cmd:. constraint list} after estimation. Or, simply use an integer >=3 as the identifier, eg {cmd:. constraint define 3 sigma[_cons]=1}.

{phang} 
{opth freq:uency(varlist)} if using grouped data, specify the variable 
that denotes the frequency of the observation. Can be in percentage terms or 
levels as {cmd: gintreg} will normalize by summing the value of 
frequency for all observations. E.g. {cmd:. gintreg depvar1 depvar2 indepvars, freq(freqvar)}

{dlgtab: Model}

{phang}
The {indepvars} specified will allow the location parameter (mu, delta or b) to vary
as a function of the independent variables. The other parameters in the distribution
can also be a function of explanatory variables by using the commands below.

{phang}
{opth sigma(varlist)} allows the {bf:log of sigma} to be a linear function of {varlist} and can 
model heteroskedasticity.

{phang}
{opth lambda(varlist)} allows lambda to be a nonlinear function of {varlist} that bounds lambda to be 
between -1 and 1 and can model skewness. In order to accomplish this, {cmd:gintreg} first estimates an intermediary "alpha" 
as a linear combination of {it:{help varlist}}. In instances where {opt lambda(varlist)} is not used and only a constant is esitmated, alpha is transformed into lambda, nonlinearly as to be bounded 
between -1 and 1, using the following equations:
		
		lambda[_cons] = (exp(alpha[_cons]-1)) / (exp(alpha[_cons]+1))
		lambda[_se] = (alpha[_se]*2*exp(alpha[_cons])) / (exp(alpha[_cons]+1)^2)

{phang}{space 4}When {opt lambda(varlist)} is used, however, only the intermediary alpha is reported; this is done to avoid imposing a nonlinear functional form that maps the transformation from a vector of alpha's coefficients to lambda's. Therefore, using this option is useful in determining significance of {indepvars} on skewness, {bf:but the coefficients should not be taken literally}.

{phang}
{opth p(varlist)} allows p to be a linear function of {varlist}. A shape parameter
that impacts the tail thickness and peakedness of the distribution.

{phang}
{opth q(varlist)} allows q to be a linear function of {varlist}. A shape parameter
that impacts the tail thickness and peakedness of the distribution.


{dlgtab: Standard Errors}

{phang}
{opt vce(vcetype)} specifies the type of standard error reported, which includes
        types that are robust to some kinds of misspecification (robust), that
        allow for intragroup correlation (cluster clustvar), and that are
        derived from asymptotic theory (oim, opg); see {manhelp vce_option R}.

{phang}
{opt robust} use robust standard errors.

{phang}
{opth cluster(varlist)} cluster standard errors with respect to sampling
unit {varlist}.

{dlgtab: Estimation}
		
{phang}
{opth initial(numlist)} 
list of numbers that specifies the initial values of the parameters in the constant
only model. This must be equal to the number of distributional parameters, which are presented in {bf:initial} under {bf:Syntax}. 

{phang}{marker noninteractive_maxopts}
{it:maximize_options}:
{opt dif:ficult},
{opt tech:nique(algorithm_spec)},
{opt iter:ate(#)},
[{cmdab:no:}]{opt lo:g},
{opt tr:ace},
{opt grad:ient},
{opt showstep},
{opt hess:ian},
{opt showtol:erance},
{opt tol:erance(#)},
{opt ltol:erance(#)},
{opt nrtol:erance(#)}; see {manhelp maximize R}. Allowed techniques include Newton-Raphson (nr), Berndt-Hall-Hausman (bhhh), Davidon
-Fletcher-Powell (dfp), and Broyden-Fletcher-Goldfarb-Shanno (bfgs). The default
 algorithm is Newton-Raphson.
 

{dlgtab: Display}

{phang}
{opt eyx(stat)} This option helps with inference in models with a positive distribution
(gb2, gg, lnormal). At the end of the STATA printout, it displays the estimated conditional value of the dependent variable
with respect to the independent variables being at the level of stat. This result is returned and is accessible after estimation
by e(eyx).

If stat is not specified then the independent variables will be taken at their mean levels:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: stat}{p_end}
{synopt:{cmd:mean}}mean values of independent variables{p_end}
{synopt:{cmd:min}}minimum values of independent variables{p_end}
{synopt:{cmd:max}}maximum values of independent variables{p_end}
{synopt:{cmd: p1}}1st percentile of independent variables{p_end}
{synopt:{cmd: p5}}5th percentile of independent variables {p_end}
{synopt:{cmd: p10}}10th percentile of independent variables{p_end}
{synopt:{cmd: p25}}25th percentile of independent variables{p_end}
{synopt:{cmd: p50}}50th percentile of independent variables{p_end}
{synopt:{cmd: p75}}75th percentile of independent variables{p_end}
{synopt:{cmd: p90}}90th percentile of independent variables{p_end}
{synopt:{cmd: p95}}95th percentile of independent variables{p_end}
{synopt:{cmd: p99}}99th percentile of independent variables{p_end}
{p2colreset}{...}

{phang}
{opth plot(numlist)} Uses twoway_function to plot the selected distribution with the estimated parameters over a range of the 
user's choice; {it: numlist} takes a lower and upper bound in the same way {opt range(numlist)} does in {bf:{help twoway_function}}, ie {cmd:plot(0 1)}. 
To flexibly plot PDFs, see {cmd:gintreg}'s companion program, {bf:{help pdfplot}}.

{phang}
{opt gini} Calculates and displays the gini coefficient if the selected distribution is Weibull, Gamma, Burr type 3 or Burr type 12. To find the gini of a Generalized Beta of the Second Kind distribution, see {bf:{help gb2dist}}. 

{pstd}To install gb2dist:{p_end}
{phang2}{cmd:. net from "http://coin.wne.uw.edu.pl/mbrzezinski/software"}{p_end}
{phang2}{cmd:. net describe gb2dist}{p_end}

{phang}
{opt aicbic} Calculates and displays the Akaike Information Criterion and Bayesian Information Criterion. 
These are returnable values with "e(aic)" and "e(bic)". 
The equations are given, where {it:k} denotes the number of estimated parameters in the model, 
{it:lnL} is the maximized log-likelihood value for the model, and {it:N} denotes the sample size:

		AIC = 2*{it:k}-2*{it:lnL}
		BIC = {it:k}*{it:ln(N)}-2*{it:lnL}


{marker remarks}{...}
{title:Remarks}

{pstd}
If the optimization is not working, try using the {opt dif:ficult} option. You can also use the option {cmd: technique(bfgs)}, or the other two {cmd: technique} options,
 which are often more robust than the default {cmd: technique(nr)}.
 
{pstd}
Several parameterizations for the GB2 are found in the literature. One of the most common involves the parameters {it:a,b,p,q}. {cmd:gintreg} uses a different parameterization with {it:sigma,delta,p,q} where the two parameterizations are related as follows: {it:b=exp(delta)} and {it:a=1/exp(sigma)}. This version of {cmd:gintreg} reports both sets of estimates. See {bf:Wikipedia} for additional details about the definitions and interrelationships for the Generalized Beta Distribution and for the Skewed Generalized t Distribution.


{marker examples}{...}
{title:Examples}

{pstd}Load the example dataset{p_end}
{phang2}{cmd:. webuse intregxmpl}{p_end}

{pstd}This file has data on wages reported in intervals ({it:wage1, wage2}) as well as point data measured in $1,000's ({it:wage)}, age in current year ({it:age}), if never married ({it:nev_mar}), rural status ie 1 if not SMSA ({it:rural}), lastest grade completed ({it:school}) and job tenure in years ({it:tenure}).{p_end}

        wage1    wage2
{p 8 27 2}20{space 7}25{space 6} meaning  20000 <= wage <= 25000{p_end}
{p 8 27 2}50{space 8}.{space 6} meaning 50000 <= wage{p_end}

{pstd}Fitting Normal pdf using interval data{p_end}
{phang2}{cmd:. gintreg wage1 wage2}

{pstd}Interval regression with a normal distribution{p_end}
{phang2}{cmd:. gintreg wage1 wage2 age nev_mar rural school tenure}

{pstd}Regular regression with a normal distribution{p_end}
{phang2}{cmd:. gintreg wage wage age nev_mar rural school tenure}

{pstd}Interval regression with a gb2 distribution using difficult option{p_end}
{phang2}{cmd:. gintreg wage1 wage2 age nev_mar rural school, distribution(gb2) diff}

{pstd}Interval regression with a gb2 distribution with the expected value of the 
dependent variable evaluated when the independent variables are at the 25 percentile (E[Y|X] appears 
at the end of the printout{p_end}
{phang2}{cmd:. gintreg wage1 wage2 age, distribution(gb2) eyx(p25)}

{pstd}The following two regressions both fit a Burr type 3{p_end}
{phang2}{cmd:. gintreg wage1 wage2 age nev_mar rural school tenure, dist(br3)}

{phang2}{cmd:. constraint define 1 [q]_cons=1}{p_end}
{phang2}{cmd:. gintreg wage1 wage2 age nev_mar rural school tenure, dist(gb2) constr(1)}

{pstd}Fitting a Burr type 3 to interval data for wages, plotting the fitted pdf and printing the Gini coefficient{p_end}
{phang2}{cmd:. gintreg wage1 wage2, dist(br3) plot(0 150) gini}

{pstd}Interval regression with a sgt distribution allowing log(sigma) to vary as a function of independent variables [heteroskedasticity]{p_end}
{phang2}{cmd:. gintreg wage1 wage2 age nev_mar rural school tenure, distribution(sgt) sigma(age nev_mar rural school tenure)}

{pstd}FItting a Generalized Beta of the Second Kind from an estimated Burr type 3{p_end}
{phang2}{cmd:. gintreg wage1 wage2, dist(gb2) init(.965 1)}


{marker author}{...}
{title:Author}

{phang}
Originally authored in 2016 by James McDonald and Jacob Orchard at Brigham Young University. 
Will Cockriel, Bryan Chia, Jonny Jensen and Jacob Triplett have joined James McDonald as additional collaborators over the years. 
The program reached version 2.0 in 2022. Jacob Triplett can be contacted for support at "jacobwtriplett@icloud.com".


{marker references}{...}
{title:References}

{phang}
James B. McDonald, Olga Stoddard, and Daniel Walton. 2018.
{it:On using interval response data in experimental economics},
Behavioral and Experimental Economics, 72:9-16.

{phang}
James B. McDonald, Daniel Walton and Bryan Chia. 2020.
{it: Distributional Assumptions and the Estimation of Contingent Valuation Models},
Computational Economics, 52:431-460.

{phang}
Michal Brzezinki. 2012. {cmd:gb2dist} Stata command. "http://coin.wne.uw.edu.pl/mbrzezinski/software".

{phang}
Skewed Generalized t Distribution, Wikipedia, "https://en.wikipedia.org/wiki/Skewed_generalized_t_distribution".{p_end}

{phang}
Generalized Beta of the Second Kind Distribution, Wikipedia, "https://en.wikipedia.org/wiki/Generalized_beta_distribution#Generalized_beta_of_the_second_kind_(GB2)".{p_end}