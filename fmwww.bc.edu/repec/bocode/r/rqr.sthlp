{smcl}
{* *! version 1.0.2  Nicolai T. Borgen 15june2022}{...}
{cmd:help rqr}
{hline}

{title:Title}

{p2colset 5 12 19 20}{...}
{p2col :{hi:rqr} {hline 2}}Residualized quantile regression (RQR){p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 13 2}
{cmd:rqr} {depvar} {indepvars} {ifin} [{it:{help rqr##weights:weight}}]{cmd:,} 
        [{opth q:uantile(numlist)} {opth c:ontrols(varlist)} {opth absorb(varlist)}
		{opth step1:command(string)} {opth step2:command(string)} 
		{opth options_step1(string)} {opth options_qreg(string)} 
		{opth options_qrprocess(string)} {opth options_predict(string)}
		{opth generate_r(varname)} {opt smoothing(a,b)} {opt print1step}
		{it:{help rqr##options:options}}]

{marker options}{...}
{synoptset 27 tabbed}{...}
{synopthdr :options}
{synoptline}
{p2coldent : {opth q:uantile(numlist)}}specifies the quantile and can be either one 
	quantile or a range of quantiles. The  default is {cmd:quantile}(.5). {p_end}
{p2coldent : {opth c:ontrols(varlist)}}lists the control variables to be included in the 
first-step regression. High-dimensional fixed effects should be included in the 
absorb() option.{p_end}
{p2coldent : {opth absorb(varlist)}}lists the fixed effects to be included in the 
first-step regression. The default estimator is {helpb areg} when one fixed 
effects is listed and the user-written {helpb reghdfe} when more than one 
fixed effects are included.{p_end}
{p2coldent : {opth step1:command(string)}}decides the first-step estimator. 
The default is {helpb regress} when no fixed effects are included, {helpb areg} 
when one fixed effects is included, and the user-written {helpb reghdfe} when 
more than one fixed effects are included. {p_end}
{p2coldent : {opth step2:command(string)}}decides the second-step quantile regression 
model. {helpb qreg} is the default when one quantile is specified in the 
{opth quantile(numlist)} and the user-written {helpb qrprocess} is default when 
more than one quantile is specified. {p_end}
{p2coldent : {opth options_step1(string)}}passes options along to the first-step 
regression model.{p_end}
{p2coldent : {opth options_qreg(string)}}passes options along to the second-step 
{helpb qreg} command.{p_end}
{p2coldent : {opth options_qrprocess(string)}}passes options along to the second-step 
{helpb qrprocess} command.{p_end}
{p2coldent : {opth options_predict(string)}}passes options along to the {helpb predict}
command that is carried out after the first-step regression. The default is 
{opt residuals}.{p_end}
{p2coldent : {opth generate_r(varname)}}saves a variable containing the residuals from 
the first-step regression.{p_end}
{p2coldent : {opt smoothing(a,b)}}adds uniformly distributed noise over the interval 
[a,b] to the outcome variable.{p_end}
{p2coldent : {opt print1step}}displays the first-step regression.{p_end}
{synoptline}
{p2colreset}{...}
{marker weights}{...}
{pstd}
{cmd:pweight}s, {cmd:fweight}s, and {cmd:iweight}s are allowed; see {help weight}.


{title:Description}

{pstd}
{cmd:rqr} fits the residualized quantile regression (RQR) model developed by
{browse "https://osf.io/preprints/socarxiv/42gcb/": Borgen, Haput, and Wiborg (2021a)}, 
which estimates unconditional quantile treatment effects. This RQR model is a 
flexible and fast approach that can easily handle all types of control variables, 
including high-dimensional fixed effects. The treatment variable (or independent 
variable of interest) should be placed in {indepvars}, control variables 
(if any) in the {opth controls(varlist)} option, and fixed effects (if any) 
in the {opth absorb(varlist)} option.  

{pstd} 
The {helpb rqrplot} postestimation command can be used to plot the coefficients and 
confidence interval effortless. 

{pstd}
See {browse "https://osf.io/preprints/socarxiv/4vquh": Borgen, Haput, and Wiborg (2021b)}
for descriptions and examples of the 
{cmd:rqr} and {helpb rqrplot} commands. 


{title:Options}

{phang}
{opth quantile(numlist)} specifies the quantile and can be either one quantile or a 
	range of quantiles. The specified quantile(s) should be number(s) between 0 
	and 1. All shorthands described in {helpb numlist} are allowed, including 
	{cmd:quantile}(.03(.02).97). The default quantile is {cmd:quantile}(.5).
	
{phang}	
{opth controls(varlist)} lists the control variables to be included in the 
first-step regression. Factor-variable operators are allowed ({helpb fvvarlist}). 
Including (high-dimensional) fixed effects in the {opth controls(varlist)} 
option is inefficient and fixed effects should instead be included in the 
{opth absorb(varlist)} option.

{phang}
{opth absorb(varlist)} lists the fixed effects to be included in the 
first-step regression. The default estimator is {helpb areg} when one fixed 
effects is listed and the user-written {helpb reghdfe} when more than one 
fixed effects are included. 

{phang}
{opth step1:command(string)} decides the first-step estimator. 
The default is {helpb regress} when no fixed effects are included, {helpb areg} 
when one fixed effects is included, and the user-written {helpb reghdfe} when 
more than one fixed effects are included. 

{phang}
{opth step2:command(string)} decides the second-step quantile regression 
model. The default when one quantile is specified in the {opth quantile(numlist)} 
option is {helpb qreg}. When more than one quantile is specified, the 
user-written {helpb qrprocess} command is the default, and the user cannot 
choose the {helpb qreg} option. To get the {helpb qreg} estimator with more than
one quantile, add option {opt options_qrprocess(method(qreg))}. 

{phang}
{opth options_step1(string)} passes options along to the first-step 
regression model. See {it:regress {help regress##options:options}}, 
{it:areg {help areg##options:options}}, and 
{it:reghdfe {help reghdfe##options:options}} for list of available options 
in the different first-step regressions. First-step options are rarely needed. 
One exception is if the user wants to include singleton groups in the {helpb reghdfe}
command, which can be achieved by adding the option {opt options_1step(keepsingletons)}.

{phang}
{opth options_qreg(string)} passes options along to the second-step 
{helpb qreg} command. See {it:qreg {help qreg##options:options}} for list of 
available options.

{phang}
{opth options_qrprocess(string)} passes options along to the second-step 
{helpb qrprocess} command. See {it:qrprocess {help qrprocess##options:options}} 
for list of available options.

{phang}
{opth options_predict(string)} passes options along to the {helpb predict}
command that is carried out after the first-step regression. The default is 
{opt residuals}.

{phang}
{opth generate_r(varname)} saves a variable containing the residuals from 
the first-step regression. 

{phang}
{opt smoothing(a,b)} adds uniformly distributed noise over the interval 
[a,b] to the outcome variable.

{phang}
{opt print1step} displays the first-step regression.


{title:Examples}

{pstd}
Setup{p_end}
{phang2}{cmd:. webuse nlswork}

{pstd}
Union wage effects on single quantile with control variables. {p_end}
{phang2}{cmd:. rqr ln_wage union, quantile(.90) controls(year c.grade##c.grade south i.ind_code)}

{pstd}
Union wage effects on multiple quantiles with control variables. {p_end}
{phang2}{cmd:. rqr ln_wage union, quantile(.03(.02).97) controls(year c.grade##c.grade south i.ind_code)}

{pstd}
Union wage effects on multiple quantiles with one fixed effects variable. {p_end}
{phang2}{cmd:. rqr ln_wage union, quantile(.03(.02).97) controls(year c.grade##c.grade south i.ind_code) absorb(idcode)}

{pstd}
Union wage effects on multiple quantiles with multiple fixed effects variables. {p_end}
{phang2}{cmd:. rqr ln_wage union, quantile(.03(.02).97) controls(year c.grade##c.grade south i.ind_code) absorb(idcode occ_code)}

{pstd}
Bootstrapping standard errors. {p_end}
{phang2}{cmd:. bootstrap, reps(200): rqr ln_wage union, quantile(.03(.02).97) controls(year c.grade##c.grade south i.ind_code) absorb(idcode occ_code)}

{pstd}
Plotting coefficients after {cmd:rqr}; see {helpb rqrplot} for more details. {p_end}
{phang2}{cmd:. rqrplot}

{title:Stored results}

{cmd:rqr} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(first_step_r2)}}first-step R-squared{p_end}
{synopt:{cmd:e(first_step_re_a)}}first-step adjusted R-squared{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(f_r)}}density estimate{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(sum_w)}}sum of weights{p_end}
{synopt:{cmd:e(q_v)}}value of quantile{p_end}
{synopt:{cmd:e(q)}}quantile requested{p_end}
{synopt:{cmd:e(sum_rdev)}}sum of raw deviations{p_end}
{synopt:{cmd:e(sum_adev)}}sum of absolute deviations{p_end}
{synopt:{cmd:e(convcode)}}0 if converged; otherwise, return code for why nonconvergence{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}Second-step QR model{p_end}
{synopt:{cmd:e(cmdname)}}rqr{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(treatment)}}treatment variable{p_end}
{synopt:{cmd:e(controls)}}control variables{p_end}
{synopt:{cmd:e(properties)}}b V{p_end}
{synopt:{cmd:e(estat_cmd)}}program used to implement estat{p_end}
{synopt:{cmd:e(predict)}}program used to implement predict{p_end}
{synopt:{cmd:e(bwmethod)}}bandwidth method; hsheather, bofinger, or chamberlain{p_end}
{synopt:{cmd:e(vce)}}vcetype specified in vce(){p_end}
{synopt:{cmd:e(method)}}algorithmic method{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(title)}}Quantile regressions{p_end}
{synopt:{cmd:e(marginsnotok)}}predictions disallowed by margins{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(coefmat)}}coefficient matrix{p_end}
{synopt:{cmd:e(quantiles)}}estimated quantiles{p_end}
{synopt:{cmd:e(sum_rdev)}}sum of absolute deviations{p_end}
{synopt:{cmd:e(sum_mdev)}}sum of raw deviations{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

In addition to the above, the following is stored in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}matrix containing the coefficients with their standard 
	errors, test statistics, p-values, and confidence intervals{p_end}
{p2colreset}{...}

{title:Version requirements}

The {cmd:rqr} command requires Stata 12.0 or later. 

{title:Package dependencies}

{pstd}
To use all the functionalities of the {cmd:rqr} command, you should download 
the {helpb qrprocess} (Chernozhukov et al. 2020) and {helpb reghdfe} 
(Correia 2016) commands. To install these commands, type: 

{phang2}
{cmd:. ssc install qrprocess}

{phang2}
{cmd:. ssc install reghdfe}


{title:Reference}

{p 4 8 2}
{browse "https://osf.io/preprints/socarxiv/42gcb/": Borgen, Haupt, and Wiborg (2021a)}
A New Framework for Estimation of Unconditional Quantile Treatment Effects: 
The Residualized Quantile Regression (RQR) Model. {it:SocArXiv}. 
doi:10.31235/osf.io/42gcb{p_end}

{p 4 8 2}
{browse "https://osf.io/preprints/socarxiv/4vquh": Borgen, Haupt, and Wiborg (2021b)}
Flexible and fast estimation of quantile treatment effects: The rqr and rqrplot
commands {it:SocArXiv}. doi:10.31235/osf.io/4vquh{p_end}

{p 4 8 2}
{browse "https://rdcu.be/cxW6l": Chernozhukov, V., I. Fernández-Val, and B. Melly (2020).} Fast algorithms for the
quantile regression process. {it: Empirical economics} 1–27.

{p 4 8 2}
{browse "http://scorreia.com/research/hdfe.pdf": Correia, S. (2016).} Linear Models with High-Dimensional Fixed Effects: An Efficient and
Feasible Estimator. Technical report. Working Paper.


{title:Authors}

{p 4 4 2} Nicolai T. Borgen, University of Oslo{break}
n.t.borgen@isp.uio.no{p_end}

{p 4 4 2} Andreas Haupt, Karlsruhe Institute of Technology{break}
andreas.haupt@kit.edu{p_end}

{p 4 4 2} Øyvind Wiborg, University of Oslo{break}
o.n.wiborg@sosge.uio.no{p_end}

{p 4 4 2} 
Thanks for citing this software in one of the following ways:
{p_end}

{p 8 8 2}
{browse "https://osf.io/preprints/socarxiv/42gcb/": Borgen, NT., A. Haupt, and ØN. Wiborg (2021).}
A New Framework for Estimation of Unconditional Quantile Treatment Effects: 
The Residualized Quantile Regression (RQR) Model. {it:SocArXiv}. 
doi:10.31235/osf.io/42gcb{p_end}

{p 8 8 2}
{browse "https://osf.io/preprints/socarxiv/4vquh": Borgen, Haput, and Wiborg (2021b)}
Flexible and fast estimation of quantile treatment effects: The rqr and rqrplot
commands {it:SocArXiv}. doi:10.31235/osf.io/4vquh{p_end}

