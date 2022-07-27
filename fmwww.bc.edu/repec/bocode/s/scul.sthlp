{smcl}
{* June27,2022}{...}
{cmd:help scul} 
{hline}

{cmd:Beta version 0.0.1} - Release date:June 31, 2022.

{p}

{title:Description}


{p 4 4 2}
{hi:scul} is adapted from the R code by Hollingsworth and Wing (2021). It uses LASSO estimators to impute counterfactuals as described by Abadie (2003,2010,2021), that is, a framework of comparative case studies. It uses LASSO to learn the
underlying data generating process of the treated unit using the donor pool's outcomes, and then projects the counterfactual. {cmd:scul} has syntaxes for single-treatments and staggered implementation. {p_end}
{p2colreset}{...}

{title:Prerequisites}
{cmd:scul} demands an {cmd:xtset} panel dataset before it can be used. Also, one needs the {cmd:distinct} (ssc inst {cmd:distinct}, replace), {cmd:greshape} (ssc inst {cmd:gtools}, replace), {cmd:coefplot} (ssc inst {cmd:coefplot}, replace), and {cmd:cvlasso} commands to use {cmd:scul}. Quintessential to estimation is the {cmd:cvlasso} commmand from the {cmd:lassopack}

 
{marker syntax}{...}

{title:Syntax, Single Unit}

{p}
Note that by default, this command generates real vs. synthetic plots, as well as gap plots.

{cmd:scul} {depvar}{cmd:,} {opt trunit(integer)} {opt trdate(integer)}  {opt ahead(number)} [{opt pla:cebos}] {opt lamb:da(string)} [{opt cov:s(varlist)}] [{opt cv(string)}] [{opt scheme(string)}]  [{opt intname(string)}] [{opt rellab(numlist)}] [{opt obscol(string)}] [{opt cfcol(string)}] [{opt conf(string)}] [{opt legpos(integer)}] [{opt trans:form(string)}] [{opt q(real)}]

{title:Syntax, Staggered Implementation}

Note that {cmd:multi} must be specified here.

{cmd:scul} {depvar}{cmd:,} {opt tr:eated(varname)} {opt ahead(number)} {opt lamb:da(string)} {opt before(integer)} {opt after(integer)} [{opt cov:s(varlist)}] {opt multi} [{opt cv(string)}] [{opt scheme(string)}]

{marker options}{...}

{title:Requirements, Single Treated Case}

{phang}{depvar} specifies the outcome. This variable may not have missing observations.

{phang}{opt ahead} specifies the number of periods ahead the user wishes to predict in the training dataset. See the options for {cmd:cvlasso} for details on this procedure.

{phang}{opt trdate} is also required. Users can use local macros for more complicated dates. For example, loc int_time: di tm(2010m4) would be 603.

{phang}{opt trunit} The user enters the unique panel number used to identify their treated unit.

{phang}{opt lambda} is also required. The user may specify {opt lopt} (optimal lambda) or {opt lse} (standard error rule), following the discussion from chapter two of Hastie et al. (2019).

{title:Optional Options, Single Treated Case}

{phang}{opt placebos} is optional. Iteratively, the treatment is reassigned to the entire donor pool of units, using the original model specified by the user. This produces a plot of these estimates, as well as 95% CIs of placebos.


{phang}{opt covs} is optional. The counterfactual is estimated with these covariates.

{phang}{opt scheme} is optional. The user may specify the graph scheme they want here.

{phang}{opt placebos} is optional. The user estimates in-space placebos.

{phang}{opt intname} is optional. The user specifies a string that denotes the name of the intervention in question. For example, if the user is studying a tax, the event-time graph generated would have an x-axis titled ``t-1 relative to tax''.

{phang}{opt legpos} is optional. The user specifies where they'd like their legend to appear on the graph in Stata's o'clock notation.

{phang}{opt squerr} is required, if {opt placebos} are specified. This option drops placebo units whose pre-intervention RMSPE is a given order of magnitude times greater than the RMSPE of the treated unit in the same period.

{phang}{opt obscol} and {opt cfcol} are optional. The user specifies the colors they'd like for their treated and untreated units lines to be.

{phang}{opt q} is optional. The user specifies the regularizer they'd like to use. When {opt q}=0, we have the Ridge penalty, and when {opt q}=1, we have the LASSO. By default, the LASSO is specified.

{phang}{opt conf} is optional. The user specifies "ci". The user graphs the confidence intervals from the t-test. Note that the confidence intervals are still calculated and present in the saved datasets, they just are not graphed if the user does not specify this option.

{phang}{opt transform} is optional. The outcome variable is normalized to the time before the intervention takes place at. See (Wiltshire, 2022) for details.

{title:Required Options, Staggered Adoption}

{phang}{opt treated} specifies the treatment variable. This variable may have no missing values, must be either 0 or 1, and must always be 1 after the treatment turns on.


{phang}{opt donoradj} is required. The user specifies how they would like to adjust their donor pool by inputting {opt et} or {opt nt} as options. Specifying {opt et} means that the user wishes to use the units that were ever-treated as donors,
while {opt nt} means using only units which were never treated as donors.

{phang}{opt before} and {opt after} are required. The user specifies how many relative event-time periods the treatment effect will be averaged over. Note that this keeps only the treated units that are within the range of these numbers. Suppose a user has one year of monthly data on three treated units, one treated in January (period 1), another treated in March (period 3) and another treated unit in August (period 8). If the user specifies {opt before}(2) and {opt after}(2), then the first treated unit will be dropped because it doesn't have 2 periods of pre-intervention data.

{title:Optional Options, Staggered Adoption}
{phang}{opt rellab} is optional. The user specifies how many periods the event-time axis will be labeled from and to. For example, if the user were to specify (-5(5)5), the graph will show the average treatment effect from 5 periods before the intervention to 5 periods after the intervention. Note that this does NOT change the period over which the effects are calculated, only about how the treatment effect graph is displayed.


{marker examples}{...}

{title:Examples}

{hline}

{pstd}Single Treated Cases

{title:Basque Country}

u scul_basque, clear

scul gdpcap, ahead(3) trdate(1975) ///
trunit(5) lamb(lopt) ///
scheme(white_tableau) ///
obscol(black) cfcol(red) legpos(4)
{hline}

{title:Proposition 99- Divisional Analysis}

u scul_p99_region, clear

scul cigsale, ///
	ahead(3)  ///
	trdate(`int_time') ///
	trunit(3) ///
	lamb(lopt) ///
	scheme(white_tableau) ///
	obscol(black) ///
	cfcol(blue) ///
	legpos(7) cv(adaptive)
{hline}
{title:BP Analysis}
loc dv score

loc covs index_score buzz_score ///
impression_score ///
quality_score ///
value_score satisfaction_score ///
recommend_score

loc int_time: di tm(2010m4)

u scul_bp, clear

keep if date <= tm(2012m6)


scul score, ///
	ahead(6) ///
	trdate(`int_time') ///
	trunit(779) ///
	lamb(lopt) ///
	scheme(white_tableau) ///
	obscol(black) ///
	cfcol(red) ///
	legpos(5) ///
	cv(adaptive)


{title:West Germany}
u scul_Reunification, clear

scul gdp, ///
	ahead(5) ///
	trdate(1990) ///
	trunit(7) ///
	scheme(white_cividis) ///
	lambda(lopt) ///
	obscol(black) cfcol(blue) intname(Reunification)
{hline}
{title:Kansas Tax Cuts}

u scul_Taxes, clear
loc int_time: disp tq(2012q1)
cls

scul gdp, ahead(4) trunit(20) trdate(`int_time') ///
lambda(lopt) obscol(black) cfcol(blue) q(.5)



{hline}
{title:Ukraine Invasion Effect on GDP}

u Invasion, clear

cls

scul gdp, ///
        ahead(3) ///
        trdate(2014) ///
        trunit(18) ///
        lambda(lopt) ///
	intname(Invasion) ///
	cv(adaptive) ///
	trans(norm) ///
	q(.5) legpos(11) ///
	obscol("28 87 152") ///
	cfcol("227 168 103")
{hline}
{title:Effect of Stadium on Housing Prices}	
u scul_Stadium, clear
cls

scul realgrossvpa, ///
        ahead(4) ///
        trdate(2017) ///
        trunit(7) ///
        lambda(lopt) ///
	intname("Stadium") ///
	cv(adaptive) ///
	q(1) legpos(6) ///
	obscol("28 87 152") ///
	cfcol("227 168 103")

{pstd} Multiple Treated Cases

{title: Gas Holiday Studies}

u Gas_Holiday, clear

loc int_time = td(24mar2022)

// td(18mar2022)  MD // td(24mar2022) GA // td(02apr2022) CT 

scul regular, ///
	ahead(28)  ///
	trdate(`int_time') ///
	trunit(11) ///
	lamb(lopt) ///
	scheme(white_tableau) ///
	obscol(black) ///
	cfcol(red) ///
	legpos(7) ///
	before(28) after(28) ///
	multi tr(treat) ///
	donadj(et) ///
	intname("Gas Holiday") ///
	rellab(-28(7)28)

{hline}

{title:References}
{p 4 4 2}
Abadie, A. (2021). Using synthetic controls: Feasibility, data requirements, and methodological aspects. J. Econ. Lit, 59(2), 391-425. https://doi.org/10.1257/jel.20191450

Abadie, A., Diamond, A., & Hainmueller, J. (2010). Synthetic control methods for comparative case studies: Estimating the effect of california’s tobacco control program. J. Am. Stat. Assoc., 105(490), 493-505. https://doi.org/10.1198/jasa.2009.ap08746 

Abadie, A., Diamond, A., & Hainmueller, J. (2015). Comparative politics and the synthetic control method. Am. J. Pol. Sci., 59(2), 495-510. https://doi.org/10.1111/ajps.12116
 
Abadie, A., & Jeremy, L. H. (2021). A penalized synthetic control estimator for disaggregated data. J. Am. Stat. Assoc., 116(536), 1817-1834. https://doi.org/10.1080/01621459.2021.1971535
 
Amjad, M., Shah, D., & Shen, D. (2018). Robust synthetic control. The Journal of Machine Learning Research, 19(1), 802-852. 

Botosaru, I., & Ferman, B. (2019). On the role of covariates in the synthetic control method. Economet J, 22(2), 117-130. https://doi.org/10.1093/ectj/utz001 

Bouttell, J., Craig, P., Lewsey, J., Robinson, M., & Popham, F. (2018). Synthetic control methodology as a tool for evaluating population-level health interventions. J. Epidemiol. Community Health, 72(8), 673-678. https://doi.org/10.1136/jech-2017-210106

Bradbury, J. C. 2022. Does hosting a professional sports team benefit the local community? Evidence from property assessments. Economics of Governance 1–34. https://doi.org/10.1007/s10101-022-00268-z.

Hastie, T., Tibshirani, R., & Wainwright, M. (2019). Statistical learning with sparsity: The lasso and generalizations. Chapman and Hall/CRC.

Hollingsworth, A., & Wing, C. (2021). Tactics for design and inference in synthetic control studies: An applied example using high-dimensional data [working paper]. 

Li, K. T., & Bell, D. R. (2017). Estimation of average treatment effects with panel data: Asymptotic theory and implementation. J. Econom., 197(1), 65-75. https://doi.org/10.1016/j.jeconom.2016.01.011

Shi, Z., & Huang, J. (2021). Forward-selected panel data approach for program evaluation. J. Econom. https://doi.org/https://doi.org/10.1016/j.jeconom.2021.04.009 

Wiltshire, J. C. (2022). Allsynth: (stacked) synthetic control bias-correction utilities for stata [working paper]. https://tinyurl.com/2qmtqk9q {p_end}
{p2colreset}{...}

{title:Contact}

Jared Greathouse, Georgia State University
Emails--
Student: jgreathouse3@student.gsu.edu
Personal: j.greathouse200@gmail.com

Email me with questions, comments, suggestions or bug reports.
 

{hline}